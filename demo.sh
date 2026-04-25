#!/usr/bin/env bash
set -euo pipefail

PIPELINE_FILE="${1:-pipeline.yaml}"

if [ ! -f "$PIPELINE_FILE" ]; then
    echo "$PIPELINE_FILE not found!"
    exit 1
fi

# Simple parser tailored for our generated pipeline.yaml
REPO=$(grep 'repo:' "$PIPELINE_FILE" | awk -F '"' '{print $2}')
BASE_BRANCH=$(grep 'base_branch:' "$PIPELINE_FILE" | awk -F '"' '{print $2}')
AUTOMATION_MODE=$(grep 'automation_mode:' "$PIPELINE_FILE" | awk -F '"' '{print $2}')
REVIEW_PROMPT=$(grep 'review:' "$PIPELINE_FILE" | awk -F '"' '{print $2}')
SOURCE="sources/github/$REPO"

echo "=== Jules Pipeline Orchestrator ==="
echo "Repository: $REPO"
echo "Base Branch: $BASE_BRANCH"
echo "Automation Mode: $AUTOMATION_MODE"

# Extract tasks array explicitly matching '- tasks/' paths
TASKS=($(grep '  - tasks/' "$PIPELINE_FILE" | awk '{print $2}'))

for TASK_FILE in "${TASKS[@]}"; do
  if [ ! -f "$TASK_FILE" ]; then
    echo "Task file $TASK_FILE not found, skipping..."
    continue
  fi
  
  TASK_CONTENT=$(cat "$TASK_FILE")
  # Use jq to securely escape the prompt string for the JSON payload
  TASK_JSON_PROMPT=$(jq -n --arg pt "$TASK_CONTENT" '$pt')

  echo "=== Executing Task from: $TASK_FILE ==="
  
  # 1. create session
  SESSION_JSON=$(curl -s -X POST \
    -H "x-goog-api-key: ${JULES_API_KEY:-}" \
    -H "Content-Type: application/json" \
    -d "{
      \"prompt\": $TASK_JSON_PROMPT,
      \"sourceContext\": {
        \"source\": \"$SOURCE\",
        \"githubRepoContext\": {
          \"startingBranch\": \"$BASE_BRANCH\"
        }
      },
      \"automationMode\": \"$AUTOMATION_MODE\"
    }" \
    https://jules.googleapis.com/v1alpha/sessions)

  SESSION_ID=$(echo "$SESSION_JSON" | jq -r '.name // empty')
  
  if [ -z "$SESSION_ID" ]; then
    echo "Failed to create session. Response:"
    echo "$SESSION_JSON"
    exit 1
  fi

  echo "Session Created: $SESSION_ID"

  # 2. wait for completion
  echo "Waiting for session completion..."
  while true; do
    STATE=$(curl -s \
      -H "x-goog-api-key: ${JULES_API_KEY:-}" \
      "https://jules.googleapis.com/v1alpha/$SESSION_ID" \
      | jq -r '.state')

    if [[ "$STATE" == "COMPLETED" ]]; then
      echo "Session Completed."
      break
    elif [[ "$STATE" == "FAILED" ]]; then
      echo "Task failed: $SESSION_ID"
      exit 1
    fi
    sleep 10
  done

  # 3. get PR info
  PR_URL=$(curl -s \
    -H "x-goog-api-key: ${JULES_API_KEY:-}" \
    "https://jules.googleapis.com/v1alpha/$SESSION_ID" \
    | jq -r '.. | .pullRequest? .url? // empty')

  echo "PR Created: $PR_URL"

  # 4. extract branch
  PR_BRANCH=$(gh pr view "$PR_URL" --json headRefName -q .headRefName)
  echo "Extracted PR Branch: $PR_BRANCH"
  
  git fetch origin "$PR_BRANCH"
  git checkout "$PR_BRANCH"

  echo "Initiating Code Review Session..."
  # 5. run review
  REVIEW_JSON_PROMPT=$(jq -n --arg rp "$REVIEW_PROMPT" '$rp')
  
  REVIEW_JSON=$(curl -s -X POST \
    -H "x-goog-api-key: ${JULES_API_KEY:-}" \
    -H "Content-Type: application/json" \
    -d "{
      \"prompt\": $REVIEW_JSON_PROMPT,
      \"sourceContext\": {
        \"source\": \"$SOURCE\",
        \"githubRepoContext\": {
          \"startingBranch\": \"$PR_BRANCH\"
        }
      },
      \"automationMode\": \"$AUTOMATION_MODE\"
    }" \
    https://jules.googleapis.com/v1alpha/sessions)

  REVIEW_ID=$(echo "$REVIEW_JSON" | jq -r '.name // empty')
  
  if [ -z "$REVIEW_ID" ]; then
    echo "Failed to create review session. Response:"
    echo "$REVIEW_JSON"
    exit 1
  fi
  
  echo "Review Session Created: $REVIEW_ID"
  
  while true; do
    STATE=$(curl -s \
      -H "x-goog-api-key: ${JULES_API_KEY:-}" \
      "https://jules.googleapis.com/v1alpha/$REVIEW_ID" \
      | jq -r '.state')
    if [[ "$STATE" == "COMPLETED" ]]; then 
      echo "Review Session Completed."
      break
    elif [[ "$STATE" == "FAILED" ]]; then
      echo "Review task failed: $REVIEW_ID"
      exit 1
    fi
    sleep 10
  done

  REVIEW_PR=$(curl -s \
    -H "x-goog-api-key: ${JULES_API_KEY:-}" \
    "https://jules.googleapis.com/v1alpha/$REVIEW_ID" \
    | jq -r '.. | .pullRequest? .url? // empty')

  echo "Review PR Created: $REVIEW_PR"

  echo "Merging Review PR..."
  gh pr merge "$REVIEW_PR" --squash --auto
  
  echo "Updating base branch..."
  git checkout "$BASE_BRANCH"
  git pull origin "$BASE_BRANCH"
  
  echo "=== Task finished successfully ==="
done

echo "=== All Pipeline Tasks Completed! ==="
