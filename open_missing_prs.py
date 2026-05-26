#!/usr/bin/env python3
"""
open_missing_prs.py — Find completed, unmerged tasks and open missing PRs for them.

Many Jules tasks push a branch but fail to create a PR. This script:
1. Fetches all COMPLETED tasks that are AWAITING_REVIEW (not merged)
2. Filters to a specific repository
3. Extracts the branch name
4. Checks if an open PR already exists using `gh pr list`
5. If not, runs `gh pr create` to open a PR for that branch.
"""
import base64
import json
import re
import subprocess
import urllib.request
import ssl
import sys
import os
import argparse
import time
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Auth helpers
# ---------------------------------------------------------------------------
def get_oauth_token():
    """Retrieve OAuth token from macOS Keychain (written by the jules CLI)."""
    try:
        res = subprocess.run(
            ["security", "find-generic-password", "-s", "jules-cli", "-a", "default", "-w"],
            capture_output=True, text=True, check=True
        )
        b64_str = res.stdout.strip()
        if b64_str.startswith("go-keyring-base64:"):
            b64_str = b64_str[len("go-keyring-base64:"):]
        token_data = json.loads(base64.b64decode(b64_str).decode("utf-8"))
        return token_data.get("access_token")
    except Exception as e:
        print(f"Error: Could not retrieve OAuth token from macOS Keychain: {e}", file=sys.stderr)
        sys.exit(1)


def _ssl_ctx():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx


def make_request(url, token, method="GET", data=None):
    """Aida tasks API via OAuth token."""
    ctx = _ssl_ctx()
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, headers=headers, method=method, data=body)
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except Exception as e:
        print(f"  HTTP error {url}: {e}", file=sys.stderr)
        return None

def make_request_jules(url, jules_auth, method="GET", data=None):
    """Jules sessions API via jules_auth tuple."""
    if not jules_auth:
        return None
    ctx = _ssl_ctx()
    header_name, header_value = jules_auth
    headers = {"Content-Type": "application/json", header_name: header_value}
    body = json.dumps(data).encode() if data is not None else None
    req = urllib.request.Request(url, headers=headers, method=method, data=body)
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except Exception as e:
        print(f"  HTTP error {url}: {e}", file=sys.stderr)
        return None


# ---------------------------------------------------------------------------
# GitHub helpers
# ---------------------------------------------------------------------------
def check_pr_exists(branch, repo_path):
    """Check if a PR exists for a given head branch."""
    res = subprocess.run(
        ["gh", "pr", "list", "--state", "open", "--head", branch, "--json", "url"],
        cwd=repo_path, capture_output=True, text=True
    )
    if res.returncode != 0:
        return False
    try:
        prs = json.loads(res.stdout)
        return len(prs) > 0
    except:
        return False


def create_pr_or_archive(branch, title, task_id, repo_path, jules_auth):
    """Create a PR for the given branch. If it fails due to branch missing or no diffs, archive it."""
    if not title:
        title = f"Automated Jules PR for task {task_id}"
    body = f"Automated PR created from Jules task: {task_id}\n\nBranch: `{branch}`"
    
    print(f"    Creating PR for branch {branch}...")
    res = subprocess.run(
        ["gh", "pr", "create", "--head", branch, "--title", title, "--body", body],
        cwd=repo_path, capture_output=True, text=True
    )
    if res.returncode == 0:
        return res.stdout.strip(), "created"
    else:
        err = res.stderr.strip()
        print(f"    Error creating PR: {err}", file=sys.stderr)
        
        # Check if error indicates the branch is already merged/deleted
        if "No commits between" in err or "Head sha can't be blank" in err or "Head ref must be a branch" in err:
            print("    -> Branch is deleted or has no diffs. NOT archiving per instructions.")
            return None, "stale_not_archived"
            
        return None, "error"


def get_task_branch(task):
    """Extract branch from task outputs."""
    for out in task.get("outputs", []):
        gc = out.get("gitCommit", {})
        if "gitBranchName" in gc:
            return gc["gitBranchName"]
    return None

def pr_title(task):
    outputs = task.get("outputs", [])
    for out in outputs:
        gc = out.get("gitCommit", {})
        t = gc.get("title", "")
        if t:
            return t
    return ""

def get_jules_auth():
    api_key = os.environ.get("JULES_API_KEY")
    if api_key:
        return ("x-goog-api-key", api_key)
    return None

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Find completed, unmerged tasks and open missing PRs.")
    parser.add_argument("--repo", default="JMartynov/llm-mongo-optimizer", help="Repository to filter by.")
    parser.add_argument("--repo-path", required=True, help="Local path to the repository for running 'gh pr create'.")
    parser.add_argument("-d", "--dry-run", action="store_true", help="Don't actually create PRs, just list them.")
    args = parser.parse_args()

    print(f"Repository: {args.repo}")
    print(f"Local Path: {args.repo_path}")
    print(f"Dry Run:    {args.dry_run}")
    print("-" * 60)

    token = get_oauth_token()
    
    print("Fetching task list...")
    tasks_data = make_request("https://aida.googleapis.com/v1/swebot/tasks", token)
    if not tasks_data or "tasks" not in tasks_data:
        print("Error: Could not fetch tasks.", file=sys.stderr)
        sys.exit(1)

    all_tasks = tasks_data["tasks"]
    
    # 1. COMPLETED
    # 2. isAwaitingReview = True (not merged, open PR state)
    # 3. repo match
    target_tasks = [
        t for t in all_tasks 
        if t.get("taskStatus") == "COMPLETED" 
        and t.get("isAwaitingReview", False)
        and args.repo.lower() in t.get("sourceId", "").lower()
    ]
    
    print(f"Found {len(target_tasks)} COMPLETED tasks awaiting review for {args.repo}.")
    print()

    prs_needed = []

    for idx, task in enumerate(target_tasks, 1):
        task_id = task["id"]
        branch = get_task_branch(task)
        title = (pr_title(task) or task.get("suggestedTitle", "Untitled"))[:60]
        
        print(f"[{idx:02d}] Task: {task_id}")
        print(f"     Title:  {title}")
        print(f"     Branch: {branch}")
        
        if not branch:
            print("     -> No branch found in outputs. Skipping.")
            print()
            continue

        # Check local/remote PR
        has_pr = check_pr_exists(branch, args.repo_path)
        if has_pr:
            print("     -> PR already exists.")
        else:
            print("     -> ⚠️  NO PR EXISTS for this branch.")
            prs_needed.append({
                "task_id": task_id,
                "branch": branch,
                "title": title
            })
        print()

    print("-" * 60)
    print(f"Summary: {len(prs_needed)} missing PRs found out of {len(target_tasks)} tasks.")
    
    if args.dry_run:
        print("DRY RUN: Exiting without creating PRs.")
        sys.exit(0)
        
    if not prs_needed:
        print("No PRs need to be created. Exiting.")
        sys.exit(0)

    print("\nProcessing missing PRs...")
    created = 0
    archived = 0
    jules_auth = get_jules_auth()
    
    for item in prs_needed:
        url, action = create_pr_or_archive(item["branch"], item["title"], item["task_id"], args.repo_path, jules_auth)
        if action == "created":
            print(f"    ✅ Created: {url}")
            created += 1
            
    print(f"\nDone. Successfully created {created} PRs.")

if __name__ == "__main__":
    main()
