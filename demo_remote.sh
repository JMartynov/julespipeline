#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Configuration & Initialization ---
PIPELINE_FILE="${1:-pipeline.yaml}"

log_status() {
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}[OK]${NC} $2"
    else
        echo -e "${RED}[FAIL]${NC} $2"
        exit 1
    fi
}

# --- Validation Section ---
log_status "${BLUE}Validating environment...${NC}"

ERROR=""
[ -f "$PIPELINE_FILE" ]; check_result $? "Config file $PIPELINE_FILE found"
for tool in gh jq curl; do 
    command -v "$tool" &>/dev/null; check_result $? "Tool found: $tool"
done
[ -n "${JULES_API_KEY:-}" ]; check_result $? "JULES_API_KEY is set"
gh auth status &>/dev/null; check_result $? "GitHub CLI authenticated"

log_status "${GREEN}VALIDATION SUCCESS: Working FULLY REMOTE via GitHub API.${NC}"

# --- Load Configuration ---
REPO=$(grep "^  repo:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
BASE_BRANCH=$(grep "^  base_branch:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
API_URL=$(grep "^  api_url:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
POLLING_INTERVAL=$(grep "^  polling_interval_seconds:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
SOURCE_PREFIX=$(grep "^  source_prefix:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
SOURCE="${SOURCE_PREFIX}${REPO}"

# --- Helper Functions ---

get_session_branch() {
    local session_id=$1
    local branch=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$session_id" | jq -r '.. | .headRef? // empty' | head -n 1)
    echo "$branch"
}

wait_for_session() {
    local session_id=$1
    local type=$2
    local last_state=""
    local action_count=0
    local max_actions=10

    while true; do
        local response=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$session_id")
        local state=$(echo "$response" | jq -r '.state // "UNKNOWN"')
        
        if [[ "$state" != "$last_state" ]]; then
            log_status "SESSION[$type]: ID: $session_id | State: ${YELLOW}$state${NC}"
            last_state="$state"
        fi

        case "$state" in
            "COMPLETED")
                log_status "SESSION[$type]: ${GREEN}SUCCESS${NC}"
                break
                ;;
            "FAILED")
                log_status "${RED}ERROR: $type session failed.${NC}"
                echo "$response" | jq -c .
                exit 1
                ;;
            "AWAITING_PLAN_APPROVAL"|"AWAITING_USER_FEEDBACK"|"PAUSED")
                action_count=$((action_count + 1))
                if [ $action_count -gt $max_actions ]; then
                    log_status "${RED}ERROR: session stuck after $max_actions resolution attempts.${NC}"
                    exit 1
                fi

                if [[ "$state" == "AWAITING_PLAN_APPROVAL" ]]; then
                    log_status "SESSION[$type]: ${BLUE}AUTO-APPROVING PLAN${NC} (Attempt $action_count)..."
                    curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" "$API_URL/$session_id:approvePlan" > /dev/null
                else
                    log_status "SESSION[$type]: ${BLUE}NUDGING AGENT${NC} (State: $state, Attempt $action_count)..."
                    curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
                        -d '{"prompt": "Please proceed with your best judgment."}' \
                        "$API_URL/$session_id:sendMessage" > /dev/null
                fi
                ;;
        esac
        sleep "$POLLING_INTERVAL"
    done
}

jules_api_call() {
    local prompt=$1
    local start_branch=$2
    local payload=$(jq -n --arg p "$prompt" --arg s "$SOURCE" --arg b "$start_branch" \
        '{prompt: $p, automationMode: "AUTO_CREATE_PR", sourceContext: {source: $s, githubRepoContext: {startingBranch: $b}}}')
    
    local sid=$(curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
        -d "$payload" "$API_URL/sessions" | jq -r '.name // empty')
    echo "$sid"
}

# --- Main Pipeline Logic ---

TASKS=($(grep '  - tasks/' "$PIPELINE_FILE" | awk '{print $2}'))

for TASK_FILE in "${TASKS[@]}"; do
    log_status "${BLUE}>>> TASK START: $TASK_FILE${NC}"
    
    [ -f "$TASK_FILE" ]; check_result $? "Task file found"
    TASK_CONTENT=$(cat "$TASK_FILE")
    TASK_NAME=$(basename "$TASK_FILE" .md)

    # 1. Implementation
    log_status "SESSION[Feature]: CREATING for $TASK_NAME..."
    START_TEMPLATE=$(sed -n '/task_start: |/,/review: |/p' "$PIPELINE_FILE" | grep -v "task_start: |" | grep -v "review: |" | sed 's/^    //')
    START_PROMPT="${START_TEMPLATE//"{base_branch}"/"$BASE_BRANCH"}"; START_PROMPT="${START_PROMPT//"{task_name}"/"$TASK_NAME"}"; START_PROMPT="${START_PROMPT//"{task_content}"/"$TASK_CONTENT"}"

    SESSION_ID=$(jules_api_call "$START_PROMPT" "$BASE_BRANCH")
    [ -n "$SESSION_ID" ]; check_result $? "Session creation"
    wait_for_session "$SESSION_ID" "Feature"
    
    BRANCH_NAME=$(get_session_branch "$SESSION_ID")
    [ -n "$BRANCH_NAME" ]; check_result $? "Extract feature branch: $BRANCH_NAME"

    # 2. Review
    log_status "SESSION[Review]: CREATING for $BRANCH_NAME..."
    REVIEW_TEMPLATE=$(sed -n '/review: |/,/merge_resolve: |/p' "$PIPELINE_FILE" | grep -v "review: |" | grep -v "merge_resolve: |" | sed 's/^    //')
    REVIEW_PROMPT="${REVIEW_TEMPLATE//"{branch_name}"/"$BRANCH_NAME"}"; REVIEW_PROMPT="${REVIEW_PROMPT//"{task_name}"/"$TASK_NAME"}"; REVIEW_PROMPT="${REVIEW_PROMPT//"{task_content}"/"$TASK_CONTENT"}"
    
    REVIEW_SESSION_ID=$(jules_api_call "$REVIEW_PROMPT" "$BRANCH_NAME")
    [ -n "$REVIEW_SESSION_ID" ]; check_result $? "Review session creation"
    wait_for_session "$REVIEW_SESSION_ID" "Review"
    
    REVIEW_BRANCH=$(get_session_branch "$REVIEW_SESSION_ID")
    [ -n "$REVIEW_BRANCH" ]; check_result $? "Extract review branch: $REVIEW_BRANCH"
    
    log_status "INTEGRATING: Review fixes into $BRANCH_NAME..."
    gh api -X POST /repos/$REPO/merges -f base="$BRANCH_NAME" -f head="$REVIEW_BRANCH" -f commit_message="Apply review fixes" &>/dev/null; check_result $? "Remote merge (Review -> Feature)"
    gh api -X DELETE /repos/$REPO/git/refs/heads/"$REVIEW_BRANCH" &>/dev/null; check_result $? "Delete review branch"

    # 3. Final Integration
    log_status "INTEGRATING: $BRANCH_NAME into $BASE_BRANCH..."
    gh api -X POST /repos/$REPO/merges -f base="$BASE_BRANCH" -f head="$BRANCH_NAME" -f commit_message="Integrated $TASK_NAME" &>/dev/null; check_result $? "Remote merge (Feature -> Base)"
    
    gh api -X DELETE /repos/$REPO/git/refs/heads/"$BRANCH_NAME" &>/dev/null; check_result $? "Delete feature branch"
    
    log_status "${GREEN}<<< TASK COMPLETE: $TASK_FILE (Server-Side)${NC}"
done

log_status "${GREEN}=== PIPELINE SUCCESSFUL (FULL REMOTE) ===${NC}"
