#!/usr/bin/env python3
import base64
import json
import subprocess
import urllib.request
import ssl
import sys
import argparse

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
    parser = argparse.ArgumentParser(description="Identify failed Jules tasks, displaying their definition and plan steps.")
    parser.add_argument("-n", "--limit", type=int, default=None, help="Limit the number of failed tasks displayed (default: all)")
    parser.add_argument("-r", "--repo", type=str, default=None, help="Filter by repository name")
    args = parser.parse_args()

    token = get_oauth_token()
    tasks_data = fetch_tasks(token)
    
    if not tasks_data or "tasks" not in tasks_data:
        print("No tasks found or failed to fetch tasks.")
        return
        
    tasks = tasks_data["tasks"]
    failed_tasks = [t for t in tasks if t.get("taskStatus") == "FAILED"]
    
    if args.repo:
        repo_filter = args.repo.lower()
        failed_tasks = [t for t in failed_tasks if repo_filter in (t.get("sourceId") or "").lower()]
        
    if not failed_tasks:
        print("No failed tasks found.")
        return
        
    # Sort tasks by creation time (most recent first)
    failed_tasks.sort(key=lambda t: t.get("createdAt", ""), reverse=True)
    
    total_found = len(failed_tasks)
    display_limit = args.limit if args.limit is not None else total_found
    failed_tasks_to_show = failed_tasks[:display_limit]
    
    print(f"Found {total_found} failed tasks. Showing {len(failed_tasks_to_show)}:\n")
    
    for idx, task in enumerate(failed_tasks_to_show, 1):
        task_id = task["id"]
        title = task.get("suggestedTitle") or "Untitled Task"
        repo = task.get("sourceId", "Unknown Repo")
        if repo.startswith("github/"):
            repo = repo[7:]
        created_at = task.get("createdAt", "Unknown")
        description = task.get("description", "").strip()
        
        print("=" * 80)
        print(f"FAILED TASK #{idx} (ID: {task_id})")
        print(f"Title:      {title}")
        print(f"Repository: {repo}")
        print(f"Created At: {created_at}")
        print("-" * 80)
        print("DEFINITION:")
        if description:
            # Indent definition for readability
            indented_desc = "\n".join("  " + line for line in description.splitlines())
            print(indented_desc)
        else:
            print("  [No definition/description available]")
            
        print("-" * 80)
        
        # Check if plan steps are available
        latest_plan = task.get("latestPlan") or {}
        steps = latest_plan.get("steps", [])
        
        if steps:
            print("PLAN STEPS:")
            for step in sorted(steps, key=lambda s: s.get("index", 0)):
                step_idx = step.get("index", 0) + 1
                step_title = step.get("title", "").strip()
                step_desc = step.get("description", "").strip()
                print(f"  {step_idx}. {step_title}")
                if step_desc:
                    indented_step_desc = "\n".join("     " + line for line in step_desc.splitlines())
                    print(indented_step_desc)
        else:
            print("PLAN STEPS:\n  [No plan steps available]")
            
        print("=" * 80)
        print("\n")

if __name__ == "__main__":
    main()
