#!/usr/bin/env bash
set -euo pipefail

# --- Configuration & Initialization ---
PIPELINE_FILE="${1:-pipeline.yaml}"

log_status() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log_check() {
    echo "  [✓] $1"
}

log_fail() {
    echo "  [✗] $1"
    exit 1
}

# --- Validation Section ---
log_status "Validating environment and configuration..."

# 1. Configuration File
if [ -f "$PIPELINE_FILE" ]; then
    log_check "Configuration file found: $PIPELINE_FILE"
else
    log_fail "Configuration file NOT found: $PIPELINE_FILE"
fi

# 2. Required Tools
MISSING_TOOLS=()
for tool in gh jq curl jules git; do
    if command -v "$tool" &> /dev/null; then
        log_check "Tool found: $tool"
    else
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    log_fail "Missing required tools: ${MISSING_TOOLS[*]}"
fi

# 3. API Credentials
if [ -n "${JULES_API_KEY:-}" ]; then
    log_check "JULES_API_KEY is set"
else
    log_fail "JULES_API_KEY is NOT set"
fi

# 4. GitHub Auth
if gh auth status &>/dev/null; then
    log_check "GitHub CLI is authenticated"
else
    log_fail "GitHub CLI is NOT authenticated. Run 'gh auth login'"
fi

# --- Load Configuration ---
REPO=$(grep "^  repo:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
BASE_BRANCH=$(grep "^  base_branch:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
AUTOMATION_MODE=$(grep "^  automation_mode:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
MERGE_STRATEGY=$(grep "^  merge_strategy:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
API_URL=$(grep "^  api_url:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
POLLING_INTERVAL=$(grep "^  polling_interval_seconds:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
SOURCE_PREFIX=$(grep "^  source_prefix:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
SOURCE="${SOURCE_PREFIX}${REPO}"

log_check "Repository: $REPO"
log_check "Base Branch: $BASE_BRANCH"
log_check "Merge Strategy: $MERGE_STRATEGY"
log_check "API Endpoint: $API_URL"

log_status "All validations passed. Starting pipeline..."

# --- Helper Functions ---

wait_for_session() {
    local session_id=$1
    local type=$2
    log_status "Waiting for $type session $session_id to complete..."
    while true; do
        local state=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "$API_URL/$session_id" | jq -r '.state // "UNKNOWN"')
        if [[ "$state" == "COMPLETED" ]]; then
            log_status "$type session completed successfully."
            break
        elif [[ "$state" == "FAILED" ]]; then
            log_status "ERROR: $type session $session_id failed."
            exit 1
        elif [[ "$state" == "UNKNOWN" ]]; then
            log_status "WARNING: Could not retrieve state for $session_id. Retrying..."
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
    log_status ">>> STARTING TASK: $TASK_FILE"
    
    if [ ! -f "$TASK_FILE" ]; then
        log_status "WARNING: Task file $TASK_FILE not found. Skipping."
        continue
    fi

    TASK_CONTENT=$(cat "$TASK_FILE")
    TASK_NAME=$(basename "$TASK_FILE" .md)

    # 1. Feature Implementation Session
    log_status "Creating Feature Implementation Session for: $TASK_NAME"
    SESSION_ID=$(jules_api_call "$TASK_CONTENT" "$BASE_BRANCH" "$AUTOMATION_MODE")
    
    if [ -z "$SESSION_ID" ]; then 
        log_status "ERROR: Failed to create session for $TASK_NAME"
        exit 1
    fi
    
    wait_for_session "$SESSION_ID" "Feature"
    
    PR_URL=$(get_pr_url "$SESSION_ID")
    if [ -z "$PR_URL" ]; then log_status "ERROR: No PR URL found for $SESSION_ID"; exit 1; fi
    
    PR_BRANCH=$(gh pr view "$PR_URL" --json headRefName -q .headRefName)
    log_status "Feature PR Created: $PR_URL (Branch: $PR_BRANCH)"

    # 2. Review and Refine Session
    log_status "Initiating Code Review and Verification for: $PR_BRANCH"
    
    # Extract prompt template
    REVIEW_TEMPLATE=$(sed -n '/review: |/,/tasks:/p' "$PIPELINE_FILE" | grep -v "review: |" | grep -v "tasks:" | sed 's/^    //')
    
    # Simple template substitution
    REVIEW_PROMPT="${REVIEW_TEMPLATE//"{branch_name}"/"$PR_BRANCH"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_name}"/"$TASK_NAME"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_content}"/"$TASK_CONTENT"}"
    
    REVIEW_SESSION_ID=$(jules_api_call "$REVIEW_PROMPT" "$PR_BRANCH" "$AUTOMATION_MODE")
    if [ -z "$REVIEW_SESSION_ID" ]; then log_status "ERROR: Failed to create review session"; exit 1; fi
    
    wait_for_session "$REVIEW_SESSION_ID" "Review"
    
    REVIEW_PR_URL=$(get_pr_url "$REVIEW_SESSION_ID")
    if [ -z "$REVIEW_PR_URL" ]; then log_status "ERROR: No PR URL found for review $REVIEW_SESSION_ID"; exit 1; fi
    
    log_status "Review/Fix PR Created: $REVIEW_PR_URL"

    # 3. Merge Strategy
    log_status "Applying Merge Strategy: $MERGE_STRATEGY"
    
    if [[ "$MERGE_STRATEGY" == "jules" ]]; then
        # Merge Review -> Feature using Jules to handle conflicts
        MERGE_PROMPT_TEMPLATE=$(sed -n '/merge_resolve: |/,/tasks:/p' "$PIPELINE_FILE" | grep -v "merge_resolve: |" | grep -v "tasks:" | sed 's/^    //')
        
        # Get Review Head Branch
        REVIEW_BRANCH=$(gh pr view "$REVIEW_PR_URL" --json headRefName -q .headRefName)
        
        MERGE_PROMPT="${MERGE_PROMPT_TEMPLATE//"{head_branch}"/"$REVIEW_BRANCH"}"
        MERGE_PROMPT="${MERGE_PROMPT//"{base_branch}"/"$PR_BRANCH"}"
        
        log_status "Creating Merge/Resolve Session ($REVIEW_BRANCH -> $PR_BRANCH)..."
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
