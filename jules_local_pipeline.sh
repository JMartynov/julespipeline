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
log_status "${BLUE}Validating environment and configuration...${NC}"

# Check config, tools, and auth
RC=0; [ -f "$PIPELINE_FILE" ] || RC=$?; check_result $RC "Config file $PIPELINE_FILE found"
for tool in gh jq curl jules git; do
    RC=0; command -v "$tool" &>/dev/null || RC=$?; check_result $RC "Tool found: $tool"
done
RC=0; [ -n "${JULES_API_KEY:-}" ] || RC=$?; check_result $RC "JULES_API_KEY is set"
RC=0; gh auth status &>/dev/null || RC=$?; check_result $RC "GitHub CLI authenticated"

log_status "${GREEN}VALIDATION SUCCESS: Starting branch-only pipeline...${NC}"

# --- Load Configuration ---
REPO=$(grep "^  repo:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
BASE_BRANCH=$(grep "^  base_branch:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
MERGE_STRATEGY=$(grep "^  merge_strategy:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" || true)
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

cleanup_and_skip() {
    log_status "${RED}[FAIL] $1. Cleaning up git state and skipping task...${NC}"
    git reset --hard HEAD &>/dev/null || true
    git clean -fd &>/dev/null || true
    git checkout "$BASE_BRANCH" &>/dev/null || true
    continue
}

report_session_info() {
    local json="$1"
    local type="$2"
    local commit_msg=$(echo "$json" | jq -r '.. | .changeSet? .suggestedCommitMessage? // "N/A"' | tr '\n' ' ' | cut -c1-50)
    local files=$(echo "$json" | jq -r '.. | .gitPatch? .unidiffPatch? // empty' | grep "^+++" | awk '{print $2}' | sed 's|^b/||' | sort -u | xargs || echo "None")
    log_status "${BLUE}SUMMARY[$type]: Commit: $commit_msg... | Files: $files${NC}"
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
                report_session_info "$response" "$type"
                break
                ;;
            "FAILED")
                fail_count=$((fail_count + 1))
                if [ $fail_count -gt $max_fails ]; then
                    log_status "${RED}ERROR: $type session failed after $max_fails retries.${NC}"
                    echo "$response" | jq -c . >&2
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
                    curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
                        -d '{"prompt": "Please proceed with your best judgment."}' \
                        "$API_URL/$session_id:sendMessage" > /dev/null
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
        '{prompt: $p, sourceContext: {source: $s, githubRepoContext: {startingBranch: $b}}}')
    
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

TASKS=()
if [ -n "$TASKS_MANIFEST" ]; then
    log_status "Fetching task manifest from $REPO ($TASKS_BRANCH)..."
    MANIFEST_CONTENT=$(retry_command gh api -X GET "repos/$REPO/contents/$TASKS_MANIFEST" \
        --header "Accept: application/vnd.github.raw+json" \
        -f ref="$TASKS_BRANCH" 2>/dev/null || true)
    if [ -z "$MANIFEST_CONTENT" ]; then
        log_status "${RED}[FAIL] Fetch manifest: $TASKS_MANIFEST${NC}"
        exit 1
    fi
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        TASKS+=("$line")
    done <<< "$MANIFEST_CONTENT"
else
    log_status "TASKS_MANIFEST not specified. Reading inline tasks from $PIPELINE_FILE..."
    INLINE_TASKS=$(awk '/^tasks:/{flag=1; next} /^[^ -]/{if(flag) flag=0} flag {print}' "$PIPELINE_FILE" | grep "^  - " | sed 's/^  - //' | tr -d '"' | tr -d "'" || true)
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        TASKS+=("$line")
    done <<< "$INLINE_TASKS"
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
        cleanup_and_skip "Fetch task: $TASK_FILE"
    fi
    TASK_NAME=$(basename "$TASK_FILE" .md)
    BRANCH_NAME="jules/$TASK_NAME-$(date +%s)"

    # Git setup
    git checkout "$BASE_BRANCH" &>/dev/null || cleanup_and_skip "Checkout $BASE_BRANCH"
    retry_command git pull origin "$BASE_BRANCH" &>/dev/null || cleanup_and_skip "Pull latest $BASE_BRANCH"
    git branch -D "$BRANCH_NAME" &>/dev/null || true
    git checkout -b "$BRANCH_NAME" &>/dev/null || cleanup_and_skip "Create branch $BRANCH_NAME"

    # 1. Feature Implementation
    log_status "SESSION[Feature]: CREATING for $TASK_NAME..."
    START_TEMPLATE=$(sed -n '/task_start: |/,/review: |/p' "$PIPELINE_FILE" | grep -v "task_start: |" | grep -v "review: |" | sed 's/^    //' || true)
    START_PROMPT="${START_TEMPLATE//"{base_branch}"/"$BASE_BRANCH"}"; START_PROMPT="${START_PROMPT//"{task_name}"/"$TASK_NAME"}"; START_PROMPT="${START_PROMPT//"{task_content}"/"$TASK_CONTENT"}"

    SESSION_ID=$(retry_command jules_api_call "$START_PROMPT" "$BASE_BRANCH" || true)
    if [ -z "$SESSION_ID" ]; then cleanup_and_skip "Session creation"; fi
    
    wait_for_session "$SESSION_ID" "Feature" || cleanup_and_skip "Wait for Feature session"

    log_status "APPLYING: Pulling changes from $SESSION_ID..."
    retry_command jules remote pull --session "${SESSION_ID#sessions/}" --apply &>/dev/null || cleanup_and_skip "Apply Jules changes"

    { git add . && git commit -m "feat: implement $TASK_NAME"; } &>/dev/null || cleanup_and_skip "Commit changes"
    retry_command git push origin "$BRANCH_NAME" &>/dev/null || cleanup_and_skip "Push branch $BRANCH_NAME"

    # 2. Review
    log_status "SESSION[Review]: CREATING for $BRANCH_NAME..."
    REVIEW_TEMPLATE=$(sed -n '/review: |/,/merge_resolve: |/p' "$PIPELINE_FILE" | grep -v "review: |" | grep -v "merge_resolve: |" | sed 's/^    //' || true)
    REVIEW_PROMPT="${REVIEW_TEMPLATE//"{branch_name}"/"$BRANCH_NAME"}"; REVIEW_PROMPT="${REVIEW_PROMPT//"{task_name}"/"$TASK_NAME"}"; REVIEW_PROMPT="${REVIEW_PROMPT//"{task_content}"/"$TASK_CONTENT"}"
    
    REVIEW_SESSION_ID=$(retry_command jules_api_call "$REVIEW_PROMPT" "$BRANCH_NAME" || true)
    if [ -z "$REVIEW_SESSION_ID" ]; then cleanup_and_skip "Review session creation"; fi
    
    wait_for_session "$REVIEW_SESSION_ID" "Review" || cleanup_and_skip "Wait for Review session"

    log_status "APPLYING: Pulling review fixes from $REVIEW_SESSION_ID..."
    retry_command jules remote pull --session "${REVIEW_SESSION_ID#sessions/}" --apply &>/dev/null || cleanup_and_skip "Apply review fixes"

    { git add . && git commit -m "fix: review fixes for $TASK_NAME"; } &>/dev/null || cleanup_and_skip "Commit review fixes"
    retry_command git push origin "$BRANCH_NAME" &>/dev/null || cleanup_and_skip "Push review updates"

    # 3. Merge
    log_status "INTEGRATING: Merging $BRANCH_NAME into $BASE_BRANCH..."
    git checkout "$BASE_BRANCH" &>/dev/null || cleanup_and_skip "Checkout $BASE_BRANCH for merge"
    git merge "$BRANCH_NAME" --no-ff -m "Merge $BRANCH_NAME" &>/dev/null || cleanup_and_skip "Local merge"
    retry_command git push origin "$BASE_BRANCH" &>/dev/null || cleanup_and_skip "Push merged $BASE_BRANCH"
    
    log_status "${GREEN}<<< TASK COMPLETE: $TASK_FILE${NC}"
done

log_status "${GREEN}=== PIPELINE SUCCESSFUL ===${NC}"
