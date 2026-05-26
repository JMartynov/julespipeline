#!/usr/bin/env python3
import base64
import json
import subprocess
import urllib.request
import ssl
import sys

def get_oauth_token():
    try:
        res = subprocess.run(
            ["security", "find-generic-password", "-s", "jules-cli", "-a", "default", "-w"],
            capture_output=True,
            text=True,
            check=True
        )
        b64_str = res.stdout.strip()
        if b64_str.startswith("go-keyring-base64:"):
            b64_str = b64_str[len("go-keyring-base64:"):]
        
        token_data = json.loads(base64.b64decode(b64_str).decode('utf-8'))
        return token_data.get("access_token")
    except Exception as e:
        print(f"Error: Could not retrieve token from macOS Keychain: {e}", file=sys.stderr)
        print("Please make sure you are logged in by running: jules login", file=sys.stderr)
        sys.exit(1)

def fetch_tasks(token):
    url = "https://aida.googleapis.com/v1/swebot/tasks"
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    req = urllib.request.Request(url, headers=headers, method='GET')
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            res_data = response.read().decode('utf-8')
            return json.loads(res_data) if res_data else {}
    except Exception as e:
        print(f"Error calling Jules API: {e}", file=sys.stderr)
        return None

def main():
    token = get_oauth_token()
    tasks_data = fetch_tasks(token)
    
    if not tasks_data or "tasks" not in tasks_data:
        print("No tasks found or failed to fetch tasks.")
        return
        
    tasks = tasks_data["tasks"]
    unmerged_tasks = []
    
    for task in tasks:
        status = task.get("taskStatus", "UNKNOWN")
        
        # 1. Ignore failed or unknown/empty tasks
        if status in ("FAILED", "UNKNOWN"):
            continue
            
        # 2. Check for PR activity steps or pull request field
        pr_list = task.get("pullRequestActivity", [])
        if not pr_list and "pullRequest" in task:
            pr_list = [{"pullRequest": task["pullRequest"]}]
            
        pr_info = None
        is_merged = False
        if pr_list:
            for item in pr_list:
                pr = item.get("pullRequest", {})
                if pr:
                    pr_info = pr
                    if pr.get("merged") is True:
                        is_merged = True
                        break
        
        # 3. Filter criteria:
        # - If completed: only count as unmerged if it has a PR and that PR is not merged.
        # - If active (IN_PROGRESS, PLANNING, etc.): count as unmerged/active.
        if status == "COMPLETED":
            if pr_info and not is_merged:
                unmerged_tasks.append((task, pr_info))
        else:
            # Active tasks (not COMPLETED, not FAILED, not UNKNOWN)
            unmerged_tasks.append((task, pr_info))
            
    if not unmerged_tasks:
        print("All Jules tasks have been merged! No unmerged tasks found.")
        return
        
    print(f"Found {len(unmerged_tasks)} unmerged/active tasks:\n")
    
    # Print header
    print(f"{'Task ID':<21} | {'Repository':<30} | {'Status':<25} | {'PR Status / Link'}")
    print("-" * 110)
    
    for task, pr in unmerged_tasks:
        task_id = task["id"]
        repo = task.get("sourceId", "Unknown Repo")
        if repo.startswith("github/"):
            repo = repo[7:]
            
        status = task.get("taskStatus") or "UNKNOWN"
        
        # Format PR info
        pr_status = "No PR created"
        if pr:
            pr_state = pr.get("state", "open").upper()
            pr_url = pr.get("htmlUrl", "")
            pr_num = pr.get("number", "")
            pr_status = f"PR #{pr_num} ({pr_state}) -> {pr_url}"
            
        print(f"{task_id:<21} | {repo:<30} | {status:<25} | {pr_status}")


if __name__ == "__main__":
    main()
