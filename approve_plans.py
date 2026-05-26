#!/usr/bin/env python3
import base64
import json
import os
import subprocess
import urllib.request
import urllib.parse
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
        print(f"Warning: Could not retrieve token from macOS Keychain: {e}", file=sys.stderr)
        return None

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

def approve_remote_sessions(api_key):
    print("Checking remote sessions (Jules Sessions API)...")
    base_url = "https://jules.googleapis.com/v1alpha"
    
    # Fetch active sessions
    sessions_data = make_request(f"{base_url}/sessions", api_key=api_key)
    if not sessions_data or "sessions" not in sessions_data:
        print("No active sessions found via Sessions API.")
        return
        
    sessions = sessions_data["sessions"]
    awaiting_sessions = [s for s in sessions if s.get("state") == "AWAITING_PLAN_APPROVAL"]
    print(f"Found {len(awaiting_sessions)} sessions awaiting plan approval.")
    
    for session in awaiting_sessions:
        name = session["name"]
        print(f"Approving remote session {name}...")
        res = make_request(f"{base_url}/{name}:approvePlan", api_key=api_key, method='POST', data={})
        if res is not None:
            print(f"Successfully approved session {name}")
        else:
            print(f"Failed to approve session {name}")

def approve_local_tasks(token):
    print("Checking local tasks (Jules Tasks API)...")
    base_url = "https://aida.googleapis.com/v1/swebot"
    
    tasks_data = make_request(f"{base_url}/tasks", token=token)
    if not tasks_data or "tasks" not in tasks_data:
        print("No tasks found via Tasks API.")
        return
        
    tasks = tasks_data["tasks"]
    awaiting_tasks = [t for t in tasks if t.get("taskStatus") == "AWAITING_PLAN_APPROVAL"]
    print(f"Found {len(awaiting_tasks)} tasks awaiting plan approval.")
    
    for task in awaiting_tasks:
        task_id = task["id"]
        title = task.get("suggestedTitle") or task.get("description", "").strip()[:50]
        repo = task.get("sourceId") or "Unknown Repo"
        
        print(f"Approving Task {task_id} ({title}) on {repo}...")
        
        # Approve via the interact endpoint
        interact_url = f"{base_url}/tasks/{task_id}:interact"
        payload = {
            "userActivity": {
                "feedbackGiven": {
                    "feedback": "Approve plan, continue task execution"
                }
            }
        }
        res = make_request(interact_url, token=token, method='POST', data=payload)
        if res is not None:
            print(f"Successfully approved task {task_id}")
        else:
            print(f"Failed to approve task {task_id}")


def main():
    api_key = os.environ.get("JULES_API_KEY")
    token = get_oauth_token()
    
    if not api_key and not token:
        print("Error: Neither JULES_API_KEY environment variable nor macOS Keychain 'jules-cli' credentials found.", file=sys.stderr)
        sys.exit(1)
        
    if api_key:
        approve_remote_sessions(api_key)
        
    if token:
        approve_local_tasks(token)

if __name__ == "__main__":
    main()
