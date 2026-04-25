#!/usr/bin/env bash
set -euo pipefail

# --- Configuration & Initialization ---
PIPELINE_FILE="${1:-pipeline.yaml}"

log_status() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# --- Validation Section ---
log_status "Validating environment and configuration..."

if [ ! -f "$PIPELINE_FILE" ]; then
    echo "ERROR: $PIPELINE_FILE not found!"
    exit 1
fi

# Check for required tools
MISSING_TOOLS=()
for tool in gh jq curl jules git; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "ERROR: Missing required tools: ${MISSING_TOOLS[*]}"
    exit 1
fi

if [ -z "${JULES_API_KEY:-}" ]; then
    echo "ERROR: JULES_API_KEY is not set."
    exit 1
fi

# Parse pipeline.yaml using yq (if available) or fallback to basic awk/grep
# Since we might not have yq, using a slightly more robust python-based parser if possible, 
# but sticking to awk for maximum compatibility with the user's current environment.
get_yaml_val() {
    # Usage: get_yaml_val key [file]
    grep "^  $1:" "${2:-$PIPELINE_FILE}" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'" | xargs || echo ""
}

REPO=$(grep "^  repo:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
BASE_BRANCH=$(grep "^  base_branch:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
AUTOMATION_MODE=$(grep "^  automation_mode:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
MERGE_STRATEGY=$(grep "^  merge_strategy:" "$PIPELINE_FILE" | awk -F ': ' '{print $2}' | tr -d '"' | tr -d "'")
SOURCE="sources/github/$REPO"

log_status "Configuration validated. Repository: $REPO"

# --- Helper Functions ---

wait_for_session() {
    local session_id=$1
    local type=$2
    log_status "Waiting for $type session $session_id to complete..."
    while true; do
        local state=$(curl -s -H "x-goog-api-key: $JULES_API_KEY" "https://jules.googleapis.com/v1alpha/$session_id" | jq -r '.state')
        if [[ "$state" == "COMPLETED" ]]; then
            log_status "$type session completed."
            break
        elif [[ "$state" == "FAILED" ]]; then
            log_status "ERROR: $type session failed."
            exit 1
        fi
        sleep 15
    done
}

get_pr_url() {
    curl -s -H "x-goog-api-key: $JULES_API_KEY" "https://jules.googleapis.com/v1alpha/$1" | jq -r '.. | .pullRequest? .url? // empty'
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
        https://jules.googleapis.com/v1alpha/sessions | jq -r '.name // empty'
}

# --- Main Pipeline Logic ---

# Extract tasks
TASKS=($(grep '  - tasks/' "$PIPELINE_FILE" | awk '{print $2}'))

for TASK_FILE in "${TASKS[@]}"; do
    log_status ">>> STARTING TASK: $TASK_FILE"
    
    TASK_CONTENT=$(cat "$TASK_FILE")
    TASK_NAME=$(basename "$TASK_FILE" .md)

    # 1. Feature Implementation Session
    log_status "Creating Feature Implementation Session..."
    SESSION_ID=$(jules_api_call "$TASK_CONTENT" "$BASE_BRANCH" "$AUTOMATION_MODE")
    
    if [ -z "$SESSION_ID" ]; then log_status "ERROR: Failed to create session"; exit 1; fi
    wait_for_session "$SESSION_ID" "Feature"
    
    PR_URL=$(get_pr_url "$SESSION_ID")
    PR_BRANCH=$(gh pr view "$PR_URL" --json headRefName -q .headRefName)
    log_status "Feature PR Created: $PR_URL (Branch: $PR_BRANCH)"

    # 2. Review and Refine Session
    log_status "Initiating Code Review and Verification..."
    
    # Extract prompt and inject context
    # Note: This is a simplified multiline grep for the demo
    REVIEW_TEMPLATE=$(sed -n '/review: |/,/tasks:/p' "$PIPELINE_FILE" | grep -v "review: |" | grep -v "tasks:" | sed 's/^    //')
    
    # Simple template substitution
    REVIEW_PROMPT="${REVIEW_TEMPLATE//"{branch_name}"/"$PR_BRANCH"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_name}"/"$TASK_NAME"}"
    REVIEW_PROMPT="${REVIEW_PROMPT//"{task_content}"/"$TASK_CONTENT"}"
    
    REVIEW_SESSION_ID=$(jules_api_call "$REVIEW_PROMPT" "$PR_BRANCH" "$AUTOMATION_MODE")
    wait_for_session "$REVIEW_SESSION_ID" "Review"
    
    REVIEW_PR_URL=$(get_pr_url "$REVIEW_SESSION_ID")
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
        
        log_status "Creating Merge/Resolve Session..."
        MERGE_SESSION_ID=$(jules_api_call "$MERGE_PROMPT" "$PR_BRANCH" "$AUTOMATION_MODE")
        wait_for_session "$MERGE_SESSION_ID" "Merge-Resolve"
        
        FINAL_PR_URL=$(get_pr_url "$MERGE_SESSION_ID")
        log_status "Final Integrated PR: $FINAL_PR_URL"
        
        # Merge the final Integrated PR into main
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
