#!/usr/bin/env bash
set -euo pipefail

# --- Configuration & Initialization ---
PIPELINE_FILE="${1:-pipeline.yaml}"

log_status() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# --- Validation Section ---
log_status "Validating environment..."

ERROR=""
[ ! -f "$PIPELINE_FILE" ] && ERROR+="Config NOT found. "
for tool in gh jq curl; do command -v "$tool" &>/dev/null || ERROR+="Missing $tool. "; done
[ -z "${JULES_API_KEY:-}" ] && ERROR+="JULES_API_KEY NOT set. "
gh auth status &>/dev/null || ERROR+="GitHub NOT authenticated. "
if [ -n "$ERROR" ]; then log_status "VALIDATION FAILED: $ERROR"; exit 1; fi

log_status "VALIDATION SUCCESS: Working FULLY REMOTE via GitHub API."

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
    # Extract branch name from session outputs (Jules API uses headRef for the branch name)
    local branch=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$session_id" | jq -r '.. | .headRef? // empty' | head -n 1)
    echo "$branch"
}

wait_for_session() {
    local session_id=$1
    local type=$2
    local last_state=""
    local action_count=0

    while true; do
        local response=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$session_id")
        local state=$(echo "$response" | jq -r '.state // "UNKNOWN"')
        
        if [[ "$state" != "$last_state" ]]; then
            log_status "SESSION[$type]: ID: $session_id | State: $state"
            last_state="$state"
        fi

        case "$state" in
            "COMPLETED")
                log_status "SESSION[$type]: SUCCESS"
                break
                ;;
            "FAILED")
                log_status "ERROR: $type session failed."
                echo "$response" | jq -c .
                exit 1
                ;;
            "AWAITING_PLAN_APPROVAL"|"AWAITING_USER_FEEDBACK"|"PAUSED")
                action_count=$((action_count + 1))
                if [[ "$state" == "AWAITING_PLAN_APPROVAL" ]]; then
                    curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" "$API_URL/$session_id:approvePlan" > /dev/null
                else
                    curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
                        -d '{"prompt": "Proceed autonomously."}' "$API_URL/$session_id:sendMessage" > /dev/null
                fi
                ;;
        esac
        sleep "$POLLING_INTERVAL"
    done
}

jules_api_call() {
    local prompt=$1
    local start_branch=$2
    
    local payload=$(jq -n \
        --arg p "$prompt" \
        --arg s "$SOURCE" \
        --arg b "$start_branch" \
        '{prompt: $p, automationMode: "AUTO_CREATE_PR", sourceContext: {source: $s, githubRepoContext: {startingBranch: $b}}}')
    
    curl -s -X POST \
        -H "x-goog-api-key: $JULES_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$API_URL/sessions" | jq -r '.name // empty'
}

# --- Main Pipeline Logic ---

TASKS=($(grep '  - tasks/' "$PIPELINE_FILE" | awk '{print $2}'))

for TASK_FILE in "${TASKS[@]}"; do
    log_status ">>> TASK START: $TASK_FILE"
    TASK_CONTENT=$(cat "$TASK_FILE")
    TASK_NAME=$(basename "$TASK_FILE" .md)

    # 1. Implementation
    START_TEMPLATE=$(sed -n '/task_start: |/,/review: |/p' "$PIPELINE_FILE" | grep -v "task_start: |" | grep -v "review: |" | sed 's/^    //')
    START_PROMPT="${START_TEMPLATE//"{base_branch}"/"$BASE_BRANCH"}"
    START_PROMPT="${START_PROMPT//"{task_name}"/"$TASK_NAME"}"
    START_PROMPT="${START_PROMPT//"{task_content}"/"$TASK_CONTENT"}"

    SESSION_ID=$(jules_api_call "$START_PROMPT" "$BASE_BRANCH")
    wait_for_session "$SESSION_ID" "Feature"
    BRANCH_NAME=$(get_session_branch "$SESSION_ID")
    log_status "REMOTE: Feature Branch Created: $BRANCH_NAME"

    # 2. Review
    REVIEW_TEMPLATE=$(sed -n '/review: |/,/merge_resolve: |/p' "$PIPELINE_FILE" | grep -v "review: |" | grep -v "merge_resolve: |" | sed 's/^    //')
    REVIEW_PROMPT="${REVIEW_TEMPLATE//"{branch_name}"/"$BRANCH_NAME"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_name}"/"$TASK_NAME"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_content}"/"$TASK_CONTENT"}"
    
    REVIEW_SESSION_ID=$(jules_api_call "$REVIEW_PROMPT" "$BRANCH_NAME")
    wait_for_session "$REVIEW_SESSION_ID" "Review"
    REVIEW_BRANCH=$(get_session_branch "$REVIEW_SESSION_ID")
    
    # Remote integration of Review into Feature Branch
    log_status "INTEGRATING: Review fixes into $BRANCH_NAME..."
    gh api -X POST /repos/$REPO/merges -f base="$BRANCH_NAME" -f head="$REVIEW_BRANCH" -f commit_message="Apply review fixes" > /dev/null
    gh api -X DELETE /repos/$REPO/git/refs/heads/"$REVIEW_BRANCH" > /dev/null

    # 3. Final Integration into Base Branch
    log_status "INTEGRATING: $BRANCH_NAME into $BASE_BRANCH..."
    gh api -X POST /repos/$REPO/merges -f base="$BASE_BRANCH" -f head="$BRANCH_NAME" -f commit_message="Integrated $TASK_NAME" > /dev/null
    
    # Cleanup remote branch
    gh api -X DELETE /repos/$REPO/git/refs/heads/"$BRANCH_NAME" > /dev/null
    
    log_status "<<< TASK COMPLETE: $TASK_FILE (Server-Side)"
done
log_status "=== PIPELINE SUCCESSFUL (FULL REMOTE) ==="
