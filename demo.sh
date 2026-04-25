#!/usr/bin/env bash
set -euo pipefail

# --- Configuration & Initialization ---
PIPELINE_FILE="${1:-pipeline.yaml}"

log_status() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# --- Validation Section ---
log_status "Validating environment and configuration..."

# Check config, tools, and auth in a concise way
ERROR=""
[ ! -f "$PIPELINE_FILE" ] && ERROR+="Config NOT found. "
for tool in gh jq curl jules git; do command -v "$tool" &>/dev/null || ERROR+="Missing $tool. "; done
[ -z "${JULES_API_KEY:-}" ] && ERROR+="JULES_API_KEY NOT set. "
gh auth status &>/dev/null || ERROR+="GitHub NOT authenticated. "

if [ -n "$ERROR" ]; then log_status "VALIDATION FAILED: $ERROR"; exit 1; fi

log_status "VALIDATION SUCCESS: Config: $PIPELINE_FILE | Auth: JULES_API_KEY & GitHub | Tools: gh, jq, curl, jules, git"

# --- Load Configuration ---
REPO=$(grep "^  repo:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
BASE_BRANCH=$(grep "^  base_branch:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
MERGE_STRATEGY=$(grep "^  merge_strategy:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
API_URL=$(grep "^  api_url:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
POLLING_INTERVAL=$(grep "^  polling_interval_seconds:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
SOURCE_PREFIX=$(grep "^  source_prefix:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
SOURCE="${SOURCE_PREFIX}${REPO}"

log_status "All validations passed. Starting branch-only pipeline..."

# --- Helper Functions ---

report_session_info() {
    local json="$1"
    local type="$2"
    local commit_msg=$(echo "$json" | jq -r '.. | .changeSet? .suggestedCommitMessage? // "N/A"' | tr '\n' ' ' | cut -c1-50)
    local files=$(echo "$json" | jq -r '.. | .gitPatch? .unidiffPatch? // empty' | grep "^+++" | awk '{print $2}' | sed 's|^b/||' | sort -u | xargs || echo "None")
    log_status "SUMMARY[$type]: Commit: $commit_msg... | Files: $files"
}

wait_for_session() {
    local session_id=$1
    local type=$2
    local last_state=""
    local feedback_count=0
    while true; do
        local response=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$session_id")
        local state=$(echo "$response" | jq -r '.state // "UNKNOWN"')
        if [[ "$state" != "$last_state" ]]; then
            log_status "SESSION[$type]: ID: $session_id | State: $state"
            last_state="$state"
        fi
        if [[ "$state" == "COMPLETED" ]]; then
            report_session_info "$response" "$type"
            break
        elif [[ "$state" == "FAILED" ]]; then
            log_status "ERROR: $type session $session_id failed."
            echo "$response" | jq -c .
            exit 1
        elif [[ "$state" == "AWAITING_USER_FEEDBACK" ]]; then
            feedback_count=$((feedback_count + 1))
            if [ $feedback_count -le 3 ]; then
                log_status "SESSION[$type]: AUTO-APPROVING PLAN (Attempt $feedback_count)..."
                curl -s -X POST -H "x-goog-api-key: $JULES_API_KEY" -H "Content-Type: application/json" "$API_URL/$session_id:approvePlan" > /dev/null
            else
                log_status "ERROR: $type session stuck in AWAITING_USER_FEEDBACK after multiple approvals."
                echo "$response" | jq -c .
                exit 1
            fi
        fi
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
        '{prompt: $p, sourceContext: {source: $s, githubRepoContext: {startingBranch: $b}}}')
    
    curl -s -X POST \
        -H "x-goog-api-key: $JULES_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "$API_URL/sessions" | jq -r '.name // empty'
}

# --- Main Pipeline Logic ---

# Extract tasks list correctly handling indentation
TASKS=($(grep '  - tasks/' "$PIPELINE_FILE" | awk '{print $2}'))

for TASK_FILE in "${TASKS[@]}"; do
    log_status ">>> TASK START: $TASK_FILE"
    
    if [ ! -f "$TASK_FILE" ]; then
        log_status "WARNING: Task file $TASK_FILE not found. Skipping."
        continue
    fi

    TASK_CONTENT=$(cat "$TASK_FILE")
    TASK_NAME=$(basename "$TASK_FILE" .md)
    BRANCH_NAME="jules/$TASK_NAME-$(date +%s)"

    # Ensure local base branch is fresh
    git checkout "$BASE_BRANCH"
    git pull origin "$BASE_BRANCH"
    
    # Create feature branch
    git checkout -b "$BRANCH_NAME"

    # 1. Feature Implementation Session
    log_status "SESSION[Feature]: CREATING for $TASK_NAME..."
    
    # Extract task_start template
    START_TEMPLATE=$(sed -n '/task_start: |/,/review: |/p' "$PIPELINE_FILE" | grep -v "task_start: |" | grep -v "review: |" | sed 's/^    //')
    
    # Template substitution
    START_PROMPT="${START_TEMPLATE//"{base_branch}"/"$BASE_BRANCH"}"
    START_PROMPT="${START_PROMPT//"{task_name}"/"$TASK_NAME"}"
    START_PROMPT="${START_PROMPT//"{task_content}"/"$TASK_CONTENT"}"

    SESSION_ID=$(jules_api_call "$START_PROMPT" "$BASE_BRANCH")
    
    if [ -z "$SESSION_ID" ]; then log_status "ERROR: Failed to create session"; exit 1; fi
    wait_for_session "$SESSION_ID" "Feature"
    
    # Apply changes locally
    log_status "APPLYING: Pulling changes from $SESSION_ID..."
    jules remote pull --session "${SESSION_ID#sessions/}" --apply
    
    # Commit and Push branch
    git add .
    git commit -m "feat: implement $TASK_NAME"
    git push origin "$BRANCH_NAME"
    log_status "BRANCH[Feature]: Pushed to origin/$BRANCH_NAME"

    # 2. Review and Refine Session
    log_status "SESSION[Review]: CREATING for $BRANCH_NAME..."
    
    # Extract prompt template
    REVIEW_TEMPLATE=$(sed -n '/review: |/,/merge_resolve: |/p' "$PIPELINE_FILE" | grep -v "review: |" | grep -v "merge_resolve: |" | sed 's/^    //')
    
    # Simple template substitution
    REVIEW_PROMPT="${REVIEW_TEMPLATE//"{branch_name}"/"$BRANCH_NAME"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_name}"/"$TASK_NAME"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_content}"/"$TASK_CONTENT"}"
    
    REVIEW_SESSION_ID=$(jules_api_call "$REVIEW_PROMPT" "$BRANCH_NAME")
    if [ -z "$REVIEW_SESSION_ID" ]; then log_status "ERROR: Failed to create review session"; exit 1; fi
    
    wait_for_session "$REVIEW_SESSION_ID" "Review"
    
    # Apply review changes
    log_status "APPLYING: Pulling review fixes from $REVIEW_SESSION_ID..."
    jules remote pull --session "${REVIEW_SESSION_ID#sessions/}" --apply
    
    git add .
    git commit -m "fix: code review improvements for $TASK_NAME"
    git push origin "$BRANCH_NAME"
    log_status "BRANCH[Review]: Pushed updates to origin/$BRANCH_NAME"

    # 3. Merge Strategy
    log_status "STRATEGY[$MERGE_STRATEGY]: MERGING $BRANCH_NAME..."
    
    if [[ "$MERGE_STRATEGY" == "jules" ]]; then
        # Use Jules to merge/resolve on top of the feature branch
        MERGE_PROMPT_TEMPLATE=$(sed -n '/merge_resolve: |/,/tasks:/p' "$PIPELINE_FILE" | grep -v "merge_resolve: |" | grep -v "tasks:" | sed 's/^    //')
        
        MERGE_PROMPT="${MERGE_PROMPT_TEMPLATE//"{head_branch}"/"$BRANCH_NAME"}"
        MERGE_PROMPT="${MERGE_PROMPT//"{base_branch}"/"$BASE_BRANCH"}"
        
        log_status "SESSION[Merge]: CREATING ($BRANCH_NAME -> $BASE_BRANCH)..."
        MERGE_SESSION_ID=$(jules_api_call "$MERGE_PROMPT" "$BRANCH_NAME")
        if [ -z "$MERGE_SESSION_ID" ]; then log_status "ERROR: Failed to create merge session"; exit 1; fi
        
        wait_for_session "$MERGE_SESSION_ID" "Merge-Resolve"
        
        log_status "APPLYING: Pulling merged/resolved changes..."
        jules remote pull --session "${MERGE_SESSION_ID#sessions/}" --apply
        git commit -m "merge: integrate $BRANCH_NAME into $BASE_BRANCH" --allow-empty
    fi

    # Final integration merge to base branch
    log_status "INTEGRATING: Merging $BRANCH_NAME into $BASE_BRANCH..."
    git checkout "$BASE_BRANCH"
    git merge "$BRANCH_NAME" --no-ff -m "Merge branch '$BRANCH_NAME' into $BASE_BRANCH"
    git push origin "$BASE_BRANCH"
    
    log_status "<<< TASK COMPLETE: $TASK_FILE"
done

log_status "=== PIPELINE SUCCESSFUL ==="
