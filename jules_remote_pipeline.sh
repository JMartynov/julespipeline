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
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >&2
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

RC=0; [ -f "$PIPELINE_FILE" ] || RC=$?; check_result $RC "Config file $PIPELINE_FILE found"
for tool in gh jq curl; do
    RC=0; command -v "$tool" &>/dev/null || RC=$?; check_result $RC "Tool found: $tool"
done
RC=0; [ -n "${JULES_API_KEY:-}" ] || RC=$?; check_result $RC "JULES_API_KEY is set"
RC=0; gh auth status &>/dev/null || RC=$?; check_result $RC "GitHub CLI authenticated (gh)"

log_status "${GREEN}VALIDATION SUCCESS: Working FULLY REMOTE via GitHub API.${NC}"

# --- Load Configuration ---
REPO=$(grep "^  repo:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
BASE_BRANCH=$(grep "^  base_branch:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
API_URL=$(grep "^  api_url:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
POLLING_INTERVAL=$(grep "^  polling_interval_seconds:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
MAX_RETRIES=$(grep "^  max_retries:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
if [ -z "$MAX_RETRIES" ]; then MAX_RETRIES=3; fi
RETRY_DELAY=$(grep "^  retry_delay_seconds:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
if [ -z "$RETRY_DELAY" ]; then RETRY_DELAY=5; fi
SOURCE_PREFIX=$(grep "^  source_prefix:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
SOURCE="${SOURCE_PREFIX}${REPO}"

TASKS_BRANCH=$(grep "^  tasks_branch:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
if [ -z "$TASKS_BRANCH" ]; then
    TASKS_BRANCH="$BASE_BRANCH"
fi
TASKS_MANIFEST=$(grep "^  tasks_manifest:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)

log_status "${BLUE}--- Parsed Configuration ---${NC}"
log_status "REPO:             $REPO"
log_status "BASE_BRANCH:      $BASE_BRANCH"
log_status "API_URL:          $API_URL"
log_status "POLLING_INTERVAL: $POLLING_INTERVAL sec"
log_status "SOURCE:           $SOURCE"
log_status "TASKS_BRANCH:     $TASKS_BRANCH"
log_status "TASKS_MANIFEST:   ${TASKS_MANIFEST:-<None (using inline tasks)>}"
log_status "MAX_RETRIES:      $MAX_RETRIES"
log_status "RETRY_DELAY:      $RETRY_DELAY sec"
log_status "${BLUE}----------------------------${NC}"

# --- Helper Functions ---

retry_command() {
    local max_attempts=$MAX_RETRIES
    local attempt=1
    local delay=$RETRY_DELAY
    local cmd=("$@")
    
    while true; do
        if "${cmd[@]}"; then
            return 0
        else
            if [ $attempt -ge $max_attempts ]; then
                log_status "${RED}Command failed after $max_attempts attempts.${NC}"
                return 1
            fi
            log_status "${YELLOW}Command failed. Retrying ($attempt/$max_attempts) in $delay seconds...${NC}"
            sleep $delay
            attempt=$((attempt + 1))
        fi
    done
}

get_session_branch() {
    local session_id=$1
    local branch=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$session_id" | jq -r '.. | .headRef? // empty' | head -n 1)
    if [ -z "$branch" ]; then return 1; fi
    echo "$branch"
}

wait_for_session() {
    local session_id=$1
    local type=$2
    local last_state=""
    local last_nudge_time=0
    local nudge_interval=600
    local fail_count=0
    local max_fails=3

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
                fail_count=$((fail_count + 1))
                if [ $fail_count -gt $max_fails ]; then
                    log_status "${RED}ERROR: $type session failed after $max_fails retries.${NC}"
                    echo "$response" | jq -c .
                    return 1
                fi
                log_status "${YELLOW}WARN: $type session failed (attempt $fail_count/$max_fails). Retrying...${NC}"
                curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
                    -d '{"prompt": "Find root cause. Fix. Retry again."}' \
                    "$API_URL/$session_id:sendMessage" > /dev/null
                last_state=""
                ;;
            "AWAITING_PLAN_APPROVAL")
                log_status "SESSION[$type]: ${BLUE}AUTO-APPROVING PLAN${NC}..."
                curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" "$API_URL/$session_id:approvePlan" > /dev/null
                ;;
            "AWAITING_USER_FEEDBACK"|"PAUSED")
                local now=$(date +%s)
                if (( now - last_nudge_time >= nudge_interval )); then
                    log_status "SESSION[$type]: ${BLUE}NUDGING AGENT${NC} (State: $state)..."
                    local nudge_resp=$(curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
                        -d '{"prompt": "Please proceed with your best judgment."}' \
                        "$API_URL/$session_id:sendMessage")
                    log_status "SESSION[$type]: Nudge Response: $(echo "$nudge_resp" | jq -c '{name, state}' 2>/dev/null || echo "$nudge_resp")"
                    last_nudge_time=$now
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
    
    log_status "${BLUE}>> Sending POST request to create Jules Session...${NC}"
    local response=$(curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
        -d "$payload" "$API_URL/sessions")
    
    local sid=$(echo "$response" | jq -r '.name // empty')
    if [ -n "$sid" ]; then
        log_status "${GREEN}>> Session created successfully:${NC} $sid"
    else
        log_status "${RED}>> Failed to create session. Raw API Response:${NC}"
        echo "$response" >&2
        return 1
    fi
    echo "$sid"
}

# --- Main Pipeline Logic ---

if [ -n "$TASKS_MANIFEST" ]; then
    log_status "Fetching task manifest from $REPO ($TASKS_BRANCH)..."
    MANIFEST_CONTENT=$(retry_command gh api -X GET "repos/$REPO/contents/$TASKS_MANIFEST" \
        --header "Accept: application/vnd.github.raw+json" \
        -f ref="$TASKS_BRANCH" 2>/dev/null || true)
    if [ -z "$MANIFEST_CONTENT" ]; then
        log_status "${RED}[FAIL] Fetch manifest: $TASKS_MANIFEST${NC}"
        exit 1
    fi

    TASKS=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        TASKS+=("$line")
    done <<< "$MANIFEST_CONTENT"
else
    log_status "TASKS_MANIFEST not specified. Reading inline tasks from $PIPELINE_FILE..."
    INLINE_TASKS=$(awk '/^tasks:/{flag=1; next} /^[^ -]/{if(flag) flag=0} flag {print}' "$PIPELINE_FILE" | grep "^  - " | sed 's/^  - //' | tr -d '"' | tr -d "'")
    TASKS=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        TASKS+=("$line")
    done <<< "$INLINE_TASKS"
    RC=0; [ ${#TASKS[@]} -gt 0 ] || RC=$?; check_result $RC "Extract inline tasks from config"
fi

log_status "${GREEN}Found ${#TASKS[@]} task(s) to process:${NC}"
for t in "${TASKS[@]}"; do
    log_status "  - $t"
done

for TASK_FILE in "${TASKS[@]}"; do
    log_status "${BLUE}>>> TASK START: $TASK_FILE${NC}"

    if ! TASK_CONTENT=$(retry_command gh api -X GET "repos/$REPO/contents/$TASK_FILE" \
        --header "Accept: application/vnd.github.raw+json" \
        -f ref="$TASKS_BRANCH" 2>/dev/null); then
        log_status "${RED}[FAIL] Fetch task: $TASK_FILE from remote $TASKS_BRANCH. Skipping task...${NC}"
        continue
    fi
    
    log_status "${GREEN}[OK] Fetch task: $TASK_FILE${NC}"
    
    TASK_NAME=$(basename "$TASK_FILE" .md)

    # 1. Implementation
    log_status "SESSION[Feature]: CREATING for $TASK_NAME..."
    START_TEMPLATE=$(sed -n '/task_start: |/,/review: |/p' "$PIPELINE_FILE" | grep -v "task_start: |" | grep -v "review: |" | sed 's/^    //' || true)
    START_PROMPT="${START_TEMPLATE//"{base_branch}"/"$BASE_BRANCH"}"; START_PROMPT="${START_PROMPT//"{task_name}"/"$TASK_NAME"}"; START_PROMPT="${START_PROMPT//"{task_content}"/"$TASK_CONTENT"}"

    SESSION_ID=$(retry_command jules_api_call "$START_PROMPT" "$BASE_BRANCH" || true)
    if [ -z "$SESSION_ID" ]; then
        log_status "${RED}[FAIL] Session creation. Skipping task...${NC}"
        continue
    fi
    
    wait_for_session "$SESSION_ID" "Feature" || continue
    
    BRANCH_NAME=$(retry_command get_session_branch "$SESSION_ID" || true)
    if [ -z "$BRANCH_NAME" ]; then
        log_status "${RED}[FAIL] Extract feature branch: $BRANCH_NAME. Skipping task...${NC}"
        continue
    fi

    # 2. Review
    log_status "SESSION[Review]: CREATING for $BRANCH_NAME..."
    REVIEW_TEMPLATE=$(sed -n '/review: |/,/merge_resolve: |/p' "$PIPELINE_FILE" | grep -v "review: |" | grep -v "merge_resolve: |" | sed 's/^    //' || true)
    REVIEW_PROMPT="${REVIEW_TEMPLATE//"{branch_name}"/"$BRANCH_NAME"}"; REVIEW_PROMPT="${REVIEW_PROMPT//"{task_name}"/"$TASK_NAME"}"; REVIEW_PROMPT="${REVIEW_PROMPT//"{task_content}"/"$TASK_CONTENT"}"
    
    REVIEW_SESSION_ID=$(retry_command jules_api_call "$REVIEW_PROMPT" "$BRANCH_NAME" || true)
    if [ -z "$REVIEW_SESSION_ID" ]; then
        log_status "${RED}[FAIL] Review session creation. Skipping task...${NC}"
        continue
    fi
    
    wait_for_session "$REVIEW_SESSION_ID" "Review" || continue
    
    REVIEW_BRANCH=$(retry_command get_session_branch "$REVIEW_SESSION_ID" || true)
    if [ -z "$REVIEW_BRANCH" ]; then
        log_status "${RED}[FAIL] Extract review branch. Skipping task...${NC}"
        continue
    fi
    
    log_status "INTEGRATING: Review fixes into $BRANCH_NAME..."
    local merge_res=$(retry_command gh api -X POST /repos/$REPO/merges -f base="$BRANCH_NAME" -f head="$REVIEW_BRANCH" -f commit_message="Apply review fixes" 2>&1 || true)
    log_status "Merge Response (Review -> Feature): $merge_res"
    if ! echo "$merge_res" | grep -q '"sha"'; then
        log_status "${RED}[FAIL] Remote merge (Review -> Feature). Skipping task...${NC}"
        continue
    fi
    
    local del_res=$(retry_command gh api -X DELETE /repos/$REPO/git/refs/heads/"$REVIEW_BRANCH" 2>&1 || true)
    log_status "Delete Branch Response: $del_res"
    RC=0; [ -z "$del_res" ] || RC=$?; check_result $RC "Delete review branch"

    # 3. Final Integration
    log_status "INTEGRATING: $BRANCH_NAME into $BASE_BRANCH..."
    local final_merge_res=$(retry_command gh api -X POST /repos/$REPO/merges -f base="$BASE_BRANCH" -f head="$BRANCH_NAME" -f commit_message="Integrated $TASK_NAME" 2>&1 || true)
    log_status "Merge Response (Feature -> Base): $final_merge_res"
    if ! echo "$final_merge_res" | grep -q '"sha"'; then
        log_status "${RED}[FAIL] Remote merge (Feature -> Base). Skipping task...${NC}"
        continue
    fi
    
    local final_del_res=$(retry_command gh api -X DELETE /repos/$REPO/git/refs/heads/"$BRANCH_NAME" 2>&1 || true)
    log_status "Delete Branch Response: $final_del_res"
    RC=0; [ -z "$final_del_res" ] || RC=$?; check_result $RC "Delete feature branch"
    
    log_status "${GREEN}<<< TASK COMPLETE: $TASK_FILE (Server-Side)${NC}"
done

log_status "${GREEN}=== PIPELINE SUCCESSFUL (FULL REMOTE) ===${NC}"
