#!/usr/bin/env bash
set -euo pipefail

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Configuration & Initialization ---
PIPELINE_FILE="${1:-pipeline_parallel.yaml}"

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

log_status "${BLUE}--- Parsed Configuration ---${NC}"
log_status "REPO:             $REPO"
log_status "BASE_BRANCH:      $BASE_BRANCH"
log_status "API_URL:          $API_URL"
log_status "POLLING_INTERVAL: $POLLING_INTERVAL sec"
log_status "SOURCE:           $SOURCE"
log_status "TASKS_BRANCH:     $TASKS_BRANCH"
log_status "MAX_RETRIES:      $MAX_RETRIES"
log_status "RETRY_DELAY:      $RETRY_DELAY sec"
log_status "${BLUE}----------------------------${NC}"

# Parse prompts once in the main process
START_TEMPLATE=$(sed -n '/task_start: |/,/review: |/p' "$PIPELINE_FILE" | grep -v "task_start: |" | grep -v "review: |" | sed 's/^    //' || true)
REVIEW_TEMPLATE=$(sed -n '/review: |/,/merge_resolve: |/p' "$PIPELINE_FILE" | grep -v "review: |" | grep -v "merge_resolve: |" | sed 's/^    //' || true)

# Export config so background tasks can read them
export JULES_API_KEY REPO BASE_BRANCH API_URL POLLING_INTERVAL MAX_RETRIES RETRY_DELAY SOURCE TASKS_BRANCH START_TEMPLATE REVIEW_TEMPLATE PIPELINE_FILE

# Create logs directory
mkdir -p logs

# Duplicate stdout descriptor to fd 3 for parent console output
exec 3>&1

# --- Task Execution Function ---
run_task_pipeline() {
    local TASK_FILE=$1
    local TASK_NAME=$(basename "$TASK_FILE" .md)

    console_log() {
        echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] [${BLUE}$TASK_NAME${NC}] $1" >&3
    }

    log_status() {
        echo -e "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
    }

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
                    log_status "Command failed after $max_attempts attempts."
                    return 1
                fi
                log_status "Command failed. Retrying ($attempt/$max_attempts) in $delay seconds..."
                sleep $delay
                attempt=$((attempt + 1))
            fi
        done
    }

    perform_remote_merge() {
        local base=$1
        local head=$2
        local msg=$3
        local merge_res=$(retry_command gh api -X POST /repos/$REPO/merges -f base="$base" -f head="$head" -f commit_message="$msg" 2>&1 || true)
        log_status "Merge Response ($head -> $base): $merge_res"
        echo "$merge_res" | grep -q '"sha"'
    }

    get_oauth_token() {
        local b64_str=$(security find-generic-password -s jules-cli -a default -w 2>/dev/null | tr -d '\n')
        if [ -z "$b64_str" ]; then
            return 1
        fi
        if [[ "$b64_str" == go-keyring-base64:* ]]; then
            b64_str="${b64_str#go-keyring-base64:}"
        fi
        echo "$b64_str" | base64 -d | jq -r '.access_token // empty'
    }

    is_aida_task() {
        [[ "$1" =~ ^[0-9]+$ ]]
    }

    get_session_branch() {
        local session_id=$1
        local branch=""
        if is_aida_task "$session_id"; then
            local token=$(get_oauth_token || echo "")
            branch=$(curl -s -H "Authorization: Bearer $token" "https://aida.googleapis.com/v1/swebot/tasks/$session_id" | jq -r '.task.outputs[] | select(.gitCommit.gitBranchName != null) | .gitCommit.gitBranchName' | head -n 1)
            if [ -z "$branch" ]; then
                branch=$(curl -s -H "Authorization: Bearer $token" "https://aida.googleapis.com/v1/swebot/tasks/$session_id" | jq -r '.task.outputs[] | select(.pullRequest.head.ref != null) | .pullRequest.head.ref' | head -n 1)
            fi
        else
            branch=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$session_id" | jq -r '.. | .headRef? // empty' | head -n 1)
        fi
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
            local response=""
            local state=""
            if is_aida_task "$session_id"; then
                local token=$(get_oauth_token || echo "")
                response=$(curl -s -H "Authorization: Bearer $token" "https://aida.googleapis.com/v1/swebot/tasks/$session_id")
                state=$(echo "$response" | jq -r '.task.taskStatus // "UNKNOWN"')
            else
                response=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$session_id")
                state=$(echo "$response" | jq -r '.state // "UNKNOWN"')
            fi

            if [[ "$state" != "$last_state" ]]; then
                log_status "SESSION[$type]: ID: $session_id | State: $state"
                console_log "Session [$type] state changed to: ${YELLOW}$state${NC}"
                last_state="$state"
            fi

            case "$state" in
                "COMPLETED")
                    log_status "SESSION[$type]: SUCCESS"
                    break
                    ;;
                "FAILED")
                    fail_count=$((fail_count + 1))
                    if [ $fail_count -gt $max_fails ]; then
                        log_status "ERROR: $type session failed."
                        echo "$response" | jq -c .
                        return 1
                    fi
                    log_status "WARN: $type session failed (attempt $fail_count/$max_fails). Retrying..."
                    if is_aida_task "$session_id"; then
                        local token=$(get_oauth_token || echo "")
                        curl -s -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" \
                            -d '{"userActivity": {"feedbackGiven": {"feedback": "Find root cause. Fix. Retry again."}}}' \
                            "https://aida.googleapis.com/v1/swebot/tasks/${session_id}:interact" > /dev/null
                    else
                        curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
                            -d '{"prompt": "Find root cause. Fix. Retry again."}' \
                            "$API_URL/$session_id:sendMessage" > /dev/null
                    fi
                    last_state=""
                    ;;
                "AWAITING_PLAN_APPROVAL")
                    log_status "SESSION[$type]: AUTO-APPROVING PLAN..."
                    if is_aida_task "$session_id"; then
                        local token=$(get_oauth_token || echo "")
                        curl -s -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" \
                            -d '{"userActivity": {"feedbackGiven": {"feedback": "Approve plan, continue task execution"}}}' \
                            "https://aida.googleapis.com/v1/swebot/tasks/${session_id}:interact" > /dev/null
                    else
                        curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" "$API_URL/$session_id:approvePlan" > /dev/null
                    fi
                    ;;
                "AWAITING_USER_FEEDBACK"|"PAUSED")
                    local now=$(date +%s)
                    if (( now - last_nudge_time >= nudge_interval )); then
                        log_status "SESSION[$type]: NUDGING AGENT (State: $state)..."
                        if is_aida_task "$session_id"; then
                            local token=$(get_oauth_token || echo "")
                            local nudge_resp=$(curl -s -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" \
                                -d '{"userActivity": {"feedbackGiven": {"feedback": "Please proceed with your best judgment."}}}' \
                                "https://aida.googleapis.com/v1/swebot/tasks/${session_id}:interact")
                            log_status "SESSION[$type]: Nudge Response: $(echo "$nudge_resp" | jq -c . 2>/dev/null || echo "$nudge_resp")"
                        else
                            local nudge_resp=$(curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
                                -d '{"prompt": "Please proceed with your best judgment."}' \
                                "$API_URL/$session_id:sendMessage")
                            log_status "SESSION[$type]: Nudge Response: $(echo "$nudge_resp" | jq -c '{name, state}' 2>/dev/null || echo "$nudge_resp")"
                        fi
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
        
        if [ -n "${JULES_API_KEY:-}" ]; then
            local payload=$(jq -n --arg p "$prompt" --arg s "$SOURCE" --arg b "$start_branch" \
                '{prompt: $p, automationMode: "AUTO_CREATE_PR", sourceContext: {source: $s, githubRepoContext: {startingBranch: $b}}}')
            
            log_status ">> Sending POST request to create Jules Session (API Key)..."
            local response=$(curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" \
                -d "$payload" "$API_URL/sessions" || true)
            
            local sid=$(echo "$response" | jq -r '.name // empty')
            if [ -n "$sid" ]; then
                log_status ">> Session created successfully via API: $sid"
                echo "$sid"
                return 0
            else
                log_status ">> API Key creation failed. Response:"
                echo "$response" >&2
                log_status ">> Falling back to local jules CLI..."
            fi
        fi
        
        local task_run_dir="/tmp/jules_parallel_runs/task_${TASK_NAME}_$(date +%s)_$RANDOM/llm-mongo-optimizer"
        mkdir -p "$(dirname "$task_run_dir")"
        
        log_status ">> Cloning repository to $task_run_dir..."
        git clone -s /Users/ivan/Project/3t.tools.intellij/mongo/llm-mongo-optimizer "$task_run_dir" >/dev/null 2>&1
        
        cd "$task_run_dir"
        local old_url=$(git remote get-url origin)
        git remote set-url origin https://github.com/JMartynov/llm-mongo-optimizer.git
        
        if [ "$start_branch" != "main" ]; then
            git remote set-url origin "$old_url"
            git fetch origin "$start_branch" >/dev/null 2>&1
            git checkout "$start_branch" >/dev/null 2>&1
            git remote set-url origin https://github.com/JMartynov/llm-mongo-optimizer.git
        else
            git checkout main >/dev/null 2>&1
        fi
        
        log_status ">> Creating remote Jules session via CLI..."
        local jules_out=$(echo "$prompt" | jules remote new 2>&1 || true)
        local sid=$(echo "$jules_out" | grep -E "^ID: " | awk '{print $2}' || true)
        
        rm -rf "$(dirname "$task_run_dir")"
        
        if [ -n "$sid" ]; then
            log_status ">> Session created successfully via CLI: $sid"
            echo "$sid"
            return 0
        else
            log_status ">> Failed to create session via CLI. Output:"
            echo "$jules_out" >&2
            return 1
        fi
    }

    console_log "Starting task pipeline"

    # Fetch task content
    if ! TASK_CONTENT=$(retry_command gh api -X GET "repos/$REPO/contents/$TASK_FILE" \
        --header "Accept: application/vnd.github.raw+json" \
        -f ref="$TASKS_BRANCH" 2>/dev/null); then
        console_log "${RED}[FAIL] Fetch task: $TASK_FILE from remote $TASKS_BRANCH. Skipping task...${NC}"
        return 1
    fi
    console_log "Fetched task content successfully"

    # 1. Implementation
    console_log "Creating Feature Session..."
    START_PROMPT="${START_TEMPLATE//"{base_branch}"/"$BASE_BRANCH"}"
    START_PROMPT="${START_PROMPT//"{task_name}"/"$TASK_NAME"}"
    START_PROMPT="${START_PROMPT//"{task_content}"/"$TASK_CONTENT"}"

    SESSION_ID=$(retry_command jules_api_call "$START_PROMPT" "$BASE_BRANCH" || true)
    if [ -z "$SESSION_ID" ]; then
        console_log "${RED}[FAIL] Feature session creation failed. Skipping task.${NC}"
        return 1
    fi
    console_log "Feature Session created: ${GREEN}$SESSION_ID${NC}. Polling..."
    
    if ! wait_for_session "$SESSION_ID" "Feature"; then
        console_log "${RED}[FAIL] Feature session failed. Skipping task.${NC}"
        return 1
    fi
    
    BRANCH_NAME=$(retry_command get_session_branch "$SESSION_ID" || true)
    if [ -z "$BRANCH_NAME" ]; then
        console_log "${RED}[FAIL] Extract feature branch: $BRANCH_NAME. Skipping task...${NC}"
        return 1
    fi
    console_log "Feature branch generated: ${GREEN}$BRANCH_NAME${NC}"

    # 2. Review
    console_log "Creating Review Session..."
    REVIEW_PROMPT="${REVIEW_TEMPLATE//"{branch_name}"/"$BRANCH_NAME"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_name}"/"$TASK_NAME"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_content}"/"$TASK_CONTENT"}"
    
    REVIEW_SESSION_ID=$(retry_command jules_api_call "$REVIEW_PROMPT" "$BRANCH_NAME" || true)
    if [ -z "$REVIEW_SESSION_ID" ]; then
        console_log "${RED}[FAIL] Review session creation failed. Skipping task.${NC}"
        return 1
    fi
    console_log "Review Session created: ${GREEN}$REVIEW_SESSION_ID${NC}. Polling..."
    
    if ! wait_for_session "$REVIEW_SESSION_ID" "Review"; then
        console_log "${RED}[FAIL] Review session failed. Skipping task.${NC}"
        return 1
    fi
    
    REVIEW_BRANCH=$(retry_command get_session_branch "$REVIEW_SESSION_ID" || true)
    if [ -z "$REVIEW_BRANCH" ]; then
        console_log "${RED}[FAIL] Extract review branch. Skipping task.${NC}"
        return 1
    fi
    console_log "Review branch generated: ${GREEN}$REVIEW_BRANCH${NC}"
    
    console_log "Merging review branch into feature branch..."
    if ! perform_remote_merge "$BRANCH_NAME" "$REVIEW_BRANCH" "Apply review fixes"; then
        console_log "${RED}[FAIL] Remote merge (Review -> Feature) failed. Skipping task.${NC}"
        return 1
    fi
    
    # Delete review branch
    del_res=$(retry_command gh api -X DELETE /repos/$REPO/git/refs/heads/"$REVIEW_BRANCH" 2>&1 || true)
    console_log "Deleted remote review branch: $REVIEW_BRANCH"

    # 3. Final Integration
    console_log "Merging feature branch into main..."
    if ! perform_remote_merge "$BASE_BRANCH" "$BRANCH_NAME" "Integrated $TASK_NAME"; then
        console_log "${RED}[FAIL] Remote merge (Feature -> Base) failed. Skipping task.${NC}"
        return 1
    fi
    
    # Delete feature branch
    final_del_res=$(retry_command gh api -X DELETE /repos/$REPO/git/refs/heads/"$BRANCH_NAME" 2>&1 || true)
    console_log "Deleted remote feature branch: $BRANCH_NAME"
    
    console_log "${GREEN}<<< TASK COMPLETE (Server-Side) >>>${NC}"
    return 0
}

# --- Read inline tasks from pipeline_parallel.yaml ---
INLINE_TASKS=$(awk '/^tasks:/{flag=1; next} /^[^ -]/{if(flag) flag=0} flag {print}' "$PIPELINE_FILE" | grep "^  - " | sed 's/^  - //' | tr -d '"' | tr -d "'")
TASKS=()
while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    TASKS+=("$line")
done <<< "$INLINE_TASKS"
RC=0; [ ${#TASKS[@]} -gt 0 ] || RC=$?; check_result $RC "Extract inline tasks from config"

log_status "${GREEN}Found ${#TASKS[@]} task(s) to process in parallel:${NC}"
for t in "${TASKS[@]}"; do
    log_status "  - $t"
done

pids=()

# Launch each task pipeline in the background
for TASK_FILE in "${TASKS[@]}"; do
    TASK_NAME=$(basename "$TASK_FILE" .md)
    run_task_pipeline "$TASK_FILE" > "logs/task_${TASK_NAME}.log" 2>&1 &
    pids+=($!)
    log_status "Started parallel pipeline for $TASK_NAME (PID: $!)"
done

log_status "${BLUE}All task pipelines running in parallel. Waiting for them to complete...${NC}"
for pid in "${pids[@]}"; do
    wait "$pid"
done

log_status "${GREEN}=== PARALLEL PIPELINE COMPLETED ===${NC}"
