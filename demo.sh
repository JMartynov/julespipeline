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
AUTOMATION_MODE=$(grep "^  automation_mode:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
MERGE_STRATEGY=$(grep "^  merge_strategy:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
API_URL=$(grep "^  api_url:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
POLLING_INTERVAL=$(grep "^  polling_interval_seconds:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
SOURCE_PREFIX=$(grep "^  source_prefix:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
SOURCE="${SOURCE_PREFIX}${REPO}"

log_status "All validations passed. Starting pipeline..."

# --- Helper Functions ---

report_session_info() {
    local json="$1"
    local type="$2"
    local pr_url=$(echo "$json" | jq -r '.. | .pullRequest? .url? // "N/A"')
    local commit_msg=$(echo "$json" | jq -r '.. | .changeSet? .suggestedCommitMessage? // "N/A"' | tr '\n' ' ' | cut -c1-50)
    local files=$(echo "$json" | jq -r '.. | .gitPatch? .unidiffPatch? // empty' | grep "^+++" | awk '{print $2}' | sed 's|^b/||' | sort -u | xargs || echo "None")
    log_status "SUMMARY[$type]: PR: $pr_url | Commit: $commit_msg... | Files: $files"
}

wait_for_session() {
    local session_id=$1
    local type=$2
    local last_state=""
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
        fi
        sleep "$POLLING_INTERVAL"
    done
}

get_pr_url() {
    curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$1" | jq -r '.. | .pullRequest? .url? // empty'
}

jules_api_call() {
    local prompt=$1
    local start_branch=$2
    local mode=$3
    
    local payload=$(jq -n \
        --arg p "$prompt" \
        --arg s "$SOURCE" \
        --arg b "$start_branch" \
        --arg m "$mode" \
        '{prompt: $p, sourceContext: {source: $s, githubRepoContext: {startingBranch: $b}}, automationMode: $m}')
    
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

    # 1. Feature Implementation Session
    log_status "SESSION[Feature]: CREATING for $TASK_NAME..."
    
    # Extract task_start template
    START_TEMPLATE=$(sed -n '/task_start: |/,/review: |/p' "$PIPELINE_FILE" | grep -v "task_start: |" | grep -v "review: |" | sed 's/^    //')
    
    # Template substitution
    START_PROMPT="${START_TEMPLATE//"{base_branch}"/"$BASE_BRANCH"}"
    START_PROMPT="${START_PROMPT//"{task_name}"/"$TASK_NAME"}"
    START_PROMPT="${START_PROMPT//"{task_content}"/"$TASK_CONTENT"}"

    SESSION_ID=$(jules_api_call "$START_PROMPT" "$BASE_BRANCH" "$AUTOMATION_MODE")
    
    if [ -z "$SESSION_ID" ]; then 
        log_status "ERROR: Failed to create session for $TASK_NAME"
        exit 1
    fi
    
    wait_for_session "$SESSION_ID" "Feature"
    
    PR_URL=$(get_pr_url "$SESSION_ID")
    if [ -z "$PR_URL" ]; then log_status "ERROR: No PR URL found for $SESSION_ID"; exit 1; fi
    
    PR_BRANCH=$(gh pr view "$PR_URL" --json headRefName -q .headRefName)

    # 2. Review and Refine Session
    log_status "SESSION[Review]: CREATING for $PR_BRANCH..."
    
    # Extract prompt template
    REVIEW_TEMPLATE=$(sed -n '/review: |/,/merge_resolve: |/p' "$PIPELINE_FILE" | grep -v "review: |" | grep -v "merge_resolve: |" | sed 's/^    //')
    
    # Simple template substitution
    REVIEW_PROMPT="${REVIEW_TEMPLATE//"{branch_name}"/"$PR_BRANCH"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_name}"/"$TASK_NAME"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_content}"/"$TASK_CONTENT"}"
    
    REVIEW_SESSION_ID=$(jules_api_call "$REVIEW_PROMPT" "$PR_BRANCH" "$AUTOMATION_MODE")
    if [ -z "$REVIEW_SESSION_ID" ]; then log_status "ERROR: Failed to create review session"; exit 1; fi
    
    wait_for_session "$REVIEW_SESSION_ID" "Review"
    
    REVIEW_PR_URL=$(get_pr_url "$REVIEW_SESSION_ID")
    if [ -z "$REVIEW_PR_URL" ]; then log_status "ERROR: No PR URL found for review $REVIEW_SESSION_ID"; exit 1; fi
    
    # 3. Merge Strategy
    log_status "STRATEGY[$MERGE_STRATEGY]: MERGING $PR_BRANCH..."
    
    if [[ "$MERGE_STRATEGY" == "jules" ]]; then
        # Merge Review -> Feature using Jules to handle conflicts
        MERGE_PROMPT_TEMPLATE=$(sed -n '/merge_resolve: |/,/tasks:/p' "$PIPELINE_FILE" | grep -v "merge_resolve: |" | grep -v "tasks:" | sed 's/^    //')
        
        # Get Review Head Branch
        REVIEW_BRANCH=$(gh pr view "$REVIEW_PR_URL" --json headRefName -q .headRefName)
        
        MERGE_PROMPT="${MERGE_PROMPT_TEMPLATE//"{head_branch}"/"$REVIEW_BRANCH"}"
        MERGE_PROMPT="${MERGE_PROMPT//"{base_branch}"/"$PR_BRANCH"}"
        
        log_status "SESSION[Merge]: CREATING ($REVIEW_BRANCH -> $PR_BRANCH)..."
        MERGE_SESSION_ID=$(jules_api_call "$MERGE_PROMPT" "$PR_BRANCH" "$AUTOMATION_MODE")
        if [ -z "$MERGE_SESSION_ID" ]; then log_status "ERROR: Failed to create merge session"; exit 1; fi
        
        wait_for_session "$MERGE_SESSION_ID" "Merge-Resolve"
        
        FINAL_PR_URL=$(get_pr_url "$MERGE_SESSION_ID")
        if [ -z "$FINAL_PR_URL" ]; then log_status "ERROR: No PR URL found for final merge"; exit 1; fi
        
        log_status "Final Integrated PR: $FINAL_PR_URL"
        
        # Merge the final Integrated PR into main
        log_status "Merging integrated changes into $BASE_BRANCH..."
        gh pr merge "$FINAL_PR_URL" --squash --auto
    else
        # Fallback to standard merge
        log_status "Merging via GitHub CLI..."
        gh pr merge "$REVIEW_PR_URL" --merge --auto
        gh pr merge "$PR_URL" --squash --auto
    fi

    log_status "Updating local repository..."
    git checkout "$BASE_BRANCH"
    git pull origin "$BASE_BRANCH"
    
    log_status "<<< COMPLETED TASK: $TASK_FILE"
done

log_status "=== PIPELINE SUCCESSFUL ==="
