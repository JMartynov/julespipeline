#!/usr/bin/env python3
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
from datetime import datetime

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
        sys.exit(1)

def make_request(url, token=None, api_key=None, method='GET', data=None):
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    headers = {
        "Content-Type": "application/json"
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    elif api_key:
        headers["x-goog-api-key"] = api_key
    
    req_data = None
    if data is not None:
        req_data = json.dumps(data).encode('utf-8')
    
    req = urllib.request.Request(url, headers=headers, method=method, data=req_data)
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            res_data = response.read().decode('utf-8')
            return json.loads(res_data) if res_data else {}
    except Exception as e:
        print(f"Error calling {url}: {e}", file=sys.stderr)
        return None

def get_jules_auth():
    """Return (header_name, header_value) for Jules sessions API.
    Tries OAuth token first (aida.googleapis.com scope), then JULES_API_KEY env var.
    Returns None if neither is available.
    """
    # Try OAuth token — works if user has run 'jules' CLI recently
    try:
        res = subprocess.run(
            ["security", "find-generic-password", "-s", "jules-cli", "-a", "default", "-w"],
            capture_output=True, text=True, check=True
        )
        b64_str = res.stdout.strip()
        if b64_str.startswith("go-keyring-base64:"):
            b64_str = b64_str[len("go-keyring-base64:"):]
        token_data = json.loads(base64.b64decode(b64_str).decode('utf-8'))
        oauth_token = token_data.get("access_token")
        
        if oauth_token:
            # Probe the Jules API to confirm this token has access
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            probe = urllib.request.Request(
                "https://jules.googleapis.com/v1alpha/sessions",
                headers={"Authorization": f"Bearer {oauth_token}", "Content-Type": "application/json"}
            )
            try:
                with urllib.request.urlopen(probe, context=ctx) as r:
                    r.read()
                return ("Authorization", f"Bearer {oauth_token}")
            except Exception:
                pass  # 403 = OAuth doesn't work for Jules API, fall through
    except Exception:
        pass
    
    # Fall back to JULES_API_KEY env var
    api_key = os.environ.get("JULES_API_KEY")
    if api_key:
        return ("x-goog-api-key", api_key)
    
    return None

def make_request_jules(url, jules_auth, method='GET', data=None):
    """Make a request to the Jules sessions API using jules_auth tuple."""
    if not jules_auth:
        return None
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    header_name, header_value = jules_auth
    headers = {"Content-Type": "application/json", header_name: header_value}
    req_data = json.dumps(data).encode('utf-8') if data is not None else None
    req = urllib.request.Request(url, headers=headers, method=method, data=req_data)
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            res_data = response.read().decode('utf-8')
            return json.loads(res_data) if res_data else {}
    except Exception as e:
        print(f"Error calling {url}: {e}", file=sys.stderr)
        return None

def extract_session_id(stdout, stderr):
    """Extract Jules session ID from CLI output using multiple patterns."""
    combined = stdout + "\n" + stderr
    # Pattern 1: sessions/<numeric-id>
    m = re.search(r'sessions/(\d{10,})', combined)
    if m:
        return m.group(1)
    # Pattern 2: standalone large numeric token
    for word in combined.split():
        clean = word.strip('/:.,;()"\'`')
        if clean.isdigit() and len(clean) > 10:
            return clean
    return None

def main():
    start_time = time.time()
    start_dt = datetime.now()
    
    parser = argparse.ArgumentParser(description="Recreate failed Jules tasks and run with auto-approval.")
    parser.add_argument("-t", "--task-id", type=str, default=None, help="ID of a specific failed task to recreate")
    parser.add_argument("-a", "--all", action="store_true", help="Process all failed tasks across all dates")
    parser.add_argument("-y", "--today", action="store_true", help="Process only today's failed tasks (default if no other filter is set)")
    parser.add_argument("--date", type=str, default=None, help="Filter failed tasks by creation date (YYYY-MM-DD)")
    parser.add_argument("-d", "--dry-run", action="store_true", help="Perform a dry run without creating the task, logging to file")
    parser.add_argument("-l", "--log-file", type=str, default="/Users/ivan/.gemini/antigravity/scratch/dry_run_recreate_task.log", help="Path to save the dry-run output log")
    args = parser.parse_args()

    # Print execution metadata to stdout
    print(f"Datetime:        {start_dt.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"CLI Arguments:   {sys.argv}")
    print(f"Start Timestamp: {start_time:.6f}")
    print("-" * 50)

    token = get_oauth_token()
    jules_auth = get_jules_auth()
    if jules_auth:
        auth_type = "OAuth" if jules_auth[0] == "Authorization" else "API key"
        print(f"Jules sessions auth: {auth_type}")
    else:
        print("Warning: No Jules sessions auth available (JULES_API_KEY not set, OAuth probe failed).")
        print("         Plan auto-approval will be skipped.")
    
    tasks_url = "https://aida.googleapis.com/v1/swebot/tasks"
    print("Fetching tasks list...")
    tasks_data = make_request(tasks_url, token=token)
    if not tasks_data or "tasks" not in tasks_data:
        print("No tasks found.")
        sys.exit(1)
        
    tasks = tasks_data["tasks"]
    
    # Track titles and descriptions of all currently active tasks
    active_statuses = ("IN_PROGRESS", "PLANNING", "AWAITING_PLAN_APPROVAL", "AWAITING_USER_FEEDBACK")
    active_titles = {t.get("suggestedTitle") for t in tasks if t.get("taskStatus") in active_statuses}
    active_descriptions = {t.get("description", "").strip() for t in tasks if t.get("taskStatus") in active_statuses}
    
    failed_tasks = [t for t in tasks if t.get("taskStatus") == "FAILED"]
    
    if not failed_tasks:
        print("No failed tasks found.")
        sys.exit(0)
        
    # Sort by creation time (most recent first)
    failed_tasks.sort(key=lambda t: t.get("createdAt", ""), reverse=True)
    
    # Apply filtering logic
    if args.task_id:
        failed_tasks = [t for t in failed_tasks if t["id"] == args.task_id]
        if not failed_tasks:
            print(f"Failed task with ID {args.task_id} not found.")
            sys.exit(1)
    else:
        # Determine date filter
        target_date = None
        if args.date:
            target_date = args.date
        elif args.today or (not args.all):
            # Default to today's date if no filter is set and not requesting --all
            target_date = start_dt.strftime("%Y-%m-%d")
            
        if target_date:
            print(f"Filtering failed tasks for date: {target_date}")
            failed_tasks = [t for t in failed_tasks if target_date in t.get("createdAt", "")]
            
    if not failed_tasks:
        print("No matching failed tasks found after filtering.")
        sys.exit(0)
        
    if args.dry_run:
        # Dry run mode - log all to file
        log_dir = os.path.dirname(args.log_file)
        if log_dir and not os.path.exists(log_dir):
            os.makedirs(log_dir, exist_ok=True)
            
        with open(args.log_file, "w") as f:
            f.write("=== RECREATE FAILED TASKS (DRY RUN) ===\n")
            f.write(f"Datetime:        {start_dt.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"CLI Arguments:   {sys.argv}\n")
            f.write(f"Start Timestamp: {start_time:.6f}\n")
            f.write(f"Total Failed Tasks Identified: {len(failed_tasks)}\n")
            f.write("=" * 80 + "\n\n")
            
            for idx, task in enumerate(failed_tasks, 1):
                task_id = task["id"]
                title = task.get("suggestedTitle", "Untitled Task")
                repo = task.get("sourceId", "Unknown Repo")
                if repo.startswith("github/"):
                    repo = repo[7:]
                description = task.get("description", "")
                
                # Check if it would be skipped in active mode
                is_active = title in active_titles or description.strip() in active_descriptions
                skip_note = " (WOULD SKIP: Active task already exists)" if is_active else ""
                
                f.write(f"TASK {idx}/{len(failed_tasks)} (ID: {task_id}){skip_note}\n")
                f.write(f"Title:       {title}\n")
                f.write(f"Repository:  {repo}\n")
                f.write(f"Created At:  {task.get('createdAt', 'Unknown')}\n")
                f.write("-" * 50 + "\n")
                f.write("WOULD EXECUTE COMMAND:\n")
                f.write(f"  jules remote new --repo {repo}\n")
                f.write("-" * 50 + "\n")
                f.write("INPUT TASK DESCRIPTION:\n")
                f.write(description)
                f.write("\n" + "=" * 80 + "\n\n")
                
            end_time = time.time()
            f.write(f"End Timestamp: {end_time:.6f}\n")
            f.write(f"Duration:      {end_time - start_time:.4f} seconds\n")
            
        print(f"Dry run complete. Identified and simulated recreation of {len(failed_tasks)} failed tasks.")
        print(f"Log file written to: {args.log_file}")
        
        end_time = time.time()
        print(f"End Timestamp:   {end_time:.6f}")
        print(f"Duration:        {end_time - start_time:.4f} seconds")
        sys.exit(0)
        
    # Filter out tasks that already have active runs
    runnable_tasks = []
    for task in failed_tasks:
        title = task.get("suggestedTitle", "Untitled Task")
        description = task.get("description", "")
        if title in active_titles or description.strip() in active_descriptions:
            print(f"Skipping task '{title}' because an active run is already in progress.")
        else:
            runnable_tasks.append(task)
            
    if not runnable_tasks:
        print("All matching failed tasks already have active runs in progress.")
        sys.exit(0)
        
    # Active execution mode
    print(f"Recreating {len(runnable_tasks)} tasks...")
    created_sessions = []
    
    for idx, task in enumerate(runnable_tasks, 1):
        task_id = task["id"]
        title = task.get("suggestedTitle", "Untitled Task")
        repo = task.get("sourceId", "Unknown Repo")
        if repo.startswith("github/"):
            repo = repo[7:]
        description = task.get("description", "")
        
        print(f"\n[{idx}/{len(runnable_tasks)}] Creating task '{title}' (ID: {task_id}) on repo {repo}...")
        try:
            res = subprocess.run(
                ["jules", "remote", "new", "--repo", repo],
                input=description,
                capture_output=True,
                text=True,
                timeout=60
            )
            new_session_id = extract_session_id(res.stdout, res.stderr)
            if new_session_id:
                print(f"  ✅ Created | session_id: {new_session_id}")
                created_sessions.append((new_session_id, title))
            elif res.returncode == 0:
                print(f"  ✅ Created (session_id not extractable — CLI may have queued it)")
                if res.stdout.strip():
                    print(f"     stdout: {res.stdout[:120]}")
            else:
                print(f"  ❌ Failed (rc={res.returncode}): {res.stderr[:120]}", file=sys.stderr)
        except subprocess.TimeoutExpired:
            print(f"  ❌ Timeout waiting for jules CLI", file=sys.stderr)
        except Exception as e:
            print(f"  ❌ Error creating task: {e}", file=sys.stderr)
            
    # Now run concurrent auto-approval monitor
    if created_sessions:
        if jules_auth:
            print(f"\nMonitoring {len(created_sessions)} created sessions for plan approval...")
            base_url = "https://jules.googleapis.com/v1alpha"
            active_sessions = list(created_sessions)  # list of (id, title)
            
            # Run loop for up to 60 iterations (15 minutes max)
            for attempt in range(1, 60):
                if not active_sessions:
                    break
                    
                print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Poll #{attempt}: checking {len(active_sessions)} sessions...")
                remaining_sessions = []
                
                for sid, title in active_sessions:
                    session_data = make_request_jules(f"{base_url}/sessions/{sid}", jules_auth)
                    if not session_data:
                        remaining_sessions.append((sid, title))
                        continue
                        
                    state = session_data.get("state", "UNKNOWN")
                    print(f"  {sid} ({title[:40]}): {state}")
                    
                    if state == "AWAITING_PLAN_APPROVAL":
                        res = make_request_jules(f"{base_url}/sessions/{sid}:approvePlan",
                                                jules_auth, method='POST', data={})
                        if res is not None:
                            print(f"  -> Approved ✅")
                        else:
                            print(f"  -> Approval failed, will retry")
                            remaining_sessions.append((sid, title))
                    elif state in ("COMPLETED", "FAILED"):
                        print(f"  -> Terminal: {state}")
                    elif state in ("PLANNING", "IN_PROGRESS"):
                        print(f"  -> Running: {state}")
                    else:
                        remaining_sessions.append((sid, title))  # QUEUED etc.
                        
                active_sessions = remaining_sessions
                if active_sessions:
                    time.sleep(15)
            
            if active_sessions:
                print(f"\n⚠️  {len(active_sessions)} sessions did not reach approval/running state.")
            else:
                print("\n✅ All sessions approved/running!")
        else:
            print("\n⚠️  No Jules auth available — skipping auto-approval monitor.")
            print("   Set JULES_API_KEY env var or ensure the 'jules' CLI is authenticated.")
            
    end_time = time.time()
    print("-" * 50)
    print(f"End Timestamp:   {end_time:.6f}")
    print(f"Duration:        {end_time - start_time:.4f} seconds")

if __name__ == "__main__":
    main()
