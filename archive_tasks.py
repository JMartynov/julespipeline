#!/usr/bin/env python3
"""
archive_failed_tasks.py — Archive Jules tasks (failed and/or completed+merged).

Uses Jules sessions API (:archive action) via JULES_API_KEY.
Fetches task list from Aida tasks API via OAuth (macOS Keychain).

Merge detection logic:
  A task is considered "merged" when:
    - taskStatus == "COMPLETED"
    - isAwaitingReview == False  (PR is no longer open — was merged or closed)
    - hasCodeChanges == True OR outputs is non-empty  (a PR was actually created)

  Tasks that completed without creating a PR are NOT included in "merged" mode.

Usage examples:
    # Dry run — today's failed tasks
    python3 archive_failed_tasks.py --mode failed --dry-run

    # Dry run — all merged tasks ever
    python3 archive_failed_tasks.py --mode merged --all --dry-run

    # Dry run — both failed and merged, all time
    python3 archive_failed_tasks.py --mode both --all --dry-run

    # Archive failed tasks in a date range
    python3 archive_failed_tasks.py --mode failed --from 2026-05-26 --to 2026-05-26

    # Archive merged tasks from a specific repo
    python3 archive_failed_tasks.py --mode merged --all --repo JMartynov/llm-mongo-optimizer
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


def get_jules_auth():
    """Return (header_name, header_value) for Jules sessions API.
    Tries JULES_API_KEY env var first, then OAuth probe as fallback."""
    api_key = os.environ.get("JULES_API_KEY")
    if api_key:
        return ("x-goog-api-key", api_key)

    try:
        res = subprocess.run(
            ["security", "find-generic-password", "-s", "jules-cli", "-a", "default", "-w"],
            capture_output=True, text=True, check=True
        )
        b64_str = res.stdout.strip()
        if b64_str.startswith("go-keyring-base64:"):
            b64_str = b64_str[len("go-keyring-base64:"):]
        token_data = json.loads(base64.b64decode(b64_str).decode("utf-8"))
        oauth_token = token_data.get("access_token")
        if oauth_token:
            ctx = _ssl_ctx()
            probe = urllib.request.Request(
                "https://jules.googleapis.com/v1alpha/sessions",
                headers={"Authorization": f"Bearer {oauth_token}", "Content-Type": "application/json"}
            )
            try:
                with urllib.request.urlopen(probe, context=ctx) as r:
                    r.read()
                return ("Authorization", f"Bearer {oauth_token}")
            except Exception:
                pass
    except Exception:
        pass

    return None


# ---------------------------------------------------------------------------
# HTTP helpers
# ---------------------------------------------------------------------------

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
# Task classification helpers
# ---------------------------------------------------------------------------

def get_task_branch(task):
    """Extract branch from task outputs."""
    for out in task.get("outputs", []):
        gc = out.get("gitCommit", {})
        if "gitBranchName" in gc:
            return gc["gitBranchName"]
    return None

def is_merged(task, repo_path=None):
    """Return True if a COMPLETED task has been merged (PR is no longer awaiting review).

    Signals from Aida API:
      - taskStatus == COMPLETED
      - isAwaitingReview == False  → PR was merged (or manually closed)
      - hasCodeChanges == True OR outputs non-empty  → a PR was actually created
      
    If repo_path is provided, actively queries GitHub to bypass Aida API delays.
    """
    if task.get("taskStatus") != "COMPLETED":
        return False
    has_pr = bool(task.get("hasCodeChanges") or task.get("outputs"))
    awaiting = task.get("isAwaitingReview", False)
    
    if has_pr and not awaiting:
        return True
        
    if has_pr and awaiting and repo_path:
        branch = get_task_branch(task)
        if branch:
            res = subprocess.run(
                ["gh", "pr", "list", "--state", "merged", "--head", branch, "--json", "number"],
                cwd=repo_path, capture_output=True, text=True
            )
            if res.returncode == 0:
                try:
                    prs = json.loads(res.stdout)
                    if len(prs) > 0:
                        return True
                except Exception as e:
                    print(f"Error parsing JSON for {branch}: {e}")
        else:
            # Maybe the branch wasn't extracted? Let's check if the PR title exists
            print(f"Task {task.get('id')} has_pr but no branch found in outputs. Outputs: {json.dumps(task.get('outputs'))[:100]}")
    return False


def is_failed(task):
    return task.get("taskStatus") == "FAILED"


def merge_status_label(task):
    """Human-readable label describing the merge state of a completed task."""
    if task.get("taskStatus") != "COMPLETED":
        return ""
    has_pr = bool(task.get("hasCodeChanges") or task.get("outputs"))
    awaiting = task.get("isAwaitingReview", False)
    if not has_pr:
        return "no-PR"
    if awaiting:
        return "PR-open"
    return "MERGED"


def pr_title(task):
    """Extract the PR title from task outputs if available."""
    outputs = task.get("outputs", [])
    for out in outputs:
        gc = out.get("gitCommit", {})
        t = gc.get("title", "")
        if t:
            return t
    return ""


# ---------------------------------------------------------------------------
# Timestamp helpers
# ---------------------------------------------------------------------------

def parse_timestamp(s):
    """Parse a date or datetime string into a UTC-aware datetime.

    Accepts:
        YYYY-MM-DD               → interpreted as 00:00:00 UTC
        YYYY-MM-DDTHH:MM:SS      → assumed UTC
        YYYY-MM-DDTHH:MM:SSZ     → UTC
        YYYY-MM-DDTHH:MM:SS+HH:MM
    """
    s = s.strip()
    if re.match(r"^\d{4}-\d{2}-\d{2}$", s):
        dt = datetime.strptime(s, "%Y-%m-%d")
        return dt.replace(tzinfo=timezone.utc)
    if s.endswith("Z"):
        s = s[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(s).astimezone(timezone.utc)
    except ValueError:
        print(f"Error: Cannot parse timestamp '{s}'. Use YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS.", file=sys.stderr)
        sys.exit(1)


def parse_task_time(ts_str):
    """Parse a task's createdAt/completedAt string (RFC3339 with nanoseconds)."""
    if not ts_str:
        return None
    ts_str = re.sub(r"(\.\d{6})\d+(Z)", r"\1\2", ts_str)
    ts_str = re.sub(r"(\.\d{6})\d+(\+)", r"\1\2", ts_str)
    if ts_str.endswith("Z"):
        ts_str = ts_str[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(ts_str).astimezone(timezone.utc)
    except ValueError:
        return None


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    start_time = time.time()
    start_dt = datetime.now()

    parser = argparse.ArgumentParser(
        description="Archive Jules tasks (failed and/or completed+merged).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--mode",
        choices=["failed", "merged", "both"],
        default="failed",
        help=(
            "Which tasks to archive: "
            "'failed' = FAILED tasks (default), "
            "'merged' = COMPLETED tasks where PR was merged, "
            "'both' = both categories."
        ),
    )
    parser.add_argument(
        "--from", dest="from_ts", metavar="TIMESTAMP",
        help="Include tasks created at or after this time (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS)."
    )
    parser.add_argument(
        "--to", dest="to_ts", metavar="TIMESTAMP",
        help="Include tasks created at or before this time (YYYY-MM-DD = end-of-day assumed)."
    )
    parser.add_argument(
        "--all", action="store_true",
        help="Include tasks from all time (no date filter). Overrides --from/--to."
    )
    parser.add_argument(
        "--repo", metavar="OWNER/REPO",
        help="Only include tasks from this repository."
    )
    parser.add_argument(
        "--repo-path", help="Local path to the repository for running 'gh pr list' to verify merged PRs."
    )
    parser.add_argument(
        "-d", "--dry-run", action="store_true",
        help="Show which tasks would be archived without making any changes."
    )
    args = parser.parse_args()

    # ── Print run metadata ──────────────────────────────────────────────────
    print(f"Datetime:        {start_dt.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"CLI Arguments:   {sys.argv}")
    print(f"Start Timestamp: {start_time:.6f}")
    print(f"Mode:            {args.mode}")
    print(f"Dry Run:         {args.dry_run}")
    print("-" * 60)

    # ── Parse time bounds ───────────────────────────────────────────────────
    from_dt = parse_timestamp(args.from_ts) if args.from_ts else None
    to_dt_raw = args.to_ts
    if to_dt_raw and re.match(r"^\d{4}-\d{2}-\d{2}$", to_dt_raw.strip()):
        to_dt = parse_timestamp(to_dt_raw.strip() + "T23:59:59")
    else:
        to_dt = parse_timestamp(to_dt_raw) if to_dt_raw else None

    if args.all:
        from_dt = None
        to_dt = None
        print("Date filter:     ALL time (no restriction)")
    elif from_dt or to_dt:
        print(f"Date filter:     [{from_dt or '(any)'}, {to_dt or '(any)'}]")
    else:
        # Default: today
        today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
        from_dt = today_start
        print(f"Date filter:     today ({from_dt.strftime('%Y-%m-%d')})")

    if args.repo:
        print(f"Repo filter:     {args.repo}")

    # ── Auth ────────────────────────────────────────────────────────────────
    token = get_oauth_token()
    jules_auth = get_jules_auth()
    if jules_auth:
        auth_type = "OAuth" if jules_auth[0] == "Authorization" else "API key"
        print(f"Jules auth:      {auth_type}")
    else:
        print("Warning: No Jules auth available (JULES_API_KEY not set).")
        print("         Archive will be skipped even in live mode.")
    print()

    # ── Fetch tasks ─────────────────────────────────────────────────────────
    print("Fetching task list...")
    tasks_data = make_request("https://aida.googleapis.com/v1/swebot/tasks", token)
    if not tasks_data or "tasks" not in tasks_data:
        print("Error: Could not fetch tasks.", file=sys.stderr)
        sys.exit(1)

    all_tasks = tasks_data["tasks"]
    total_failed   = sum(1 for t in all_tasks if is_failed(t))
    total_merged   = sum(1 for t in all_tasks if is_merged(t))
    total_pr_open  = sum(1 for t in all_tasks if t.get("taskStatus") == "COMPLETED"
                         and t.get("isAwaitingReview") and
                         (t.get("hasCodeChanges") or t.get("outputs")))

    print(f"Total tasks fetched:   {len(all_tasks)}")
    print(f"  FAILED:              {total_failed}")
    print(f"  COMPLETED+merged:    {total_merged}")
    print(f"  COMPLETED+PR-open:   {total_pr_open}  (skipped — PR still awaiting review)")
    print()

    # ── Filter candidates ───────────────────────────────────────────────────
    def matches_mode(task):
        if args.mode == "failed":
            return is_failed(task)
        if args.mode == "merged":
            return is_merged(task, args.repo_path)
        return is_failed(task) or is_merged(task, args.repo_path)  # "both"

    def task_ref_time(task):
        """Use completedAt for merged tasks, createdAt for failed."""
        if is_merged(task, args.repo_path):
            return parse_task_time(task.get("completedAt") or task.get("createdAt", ""))
        return parse_task_time(task.get("createdAt", ""))

    candidates = []
    for task in all_tasks:
        if not matches_mode(task):
            continue

        ref_time = task_ref_time(task)
        if from_dt and ref_time and ref_time < from_dt:
            continue
        if to_dt and ref_time and ref_time > to_dt:
            continue

        if args.repo:
            task_repo = task.get("sourceId", "").replace("github/", "")
            if task_repo.lower() != args.repo.lower():
                continue

        candidates.append(task)

    # Sort: failed first, then merged; within each group newest first
    candidates.sort(key=lambda t: (0 if is_failed(t) else 1, t.get("createdAt", ""), ))
    candidates.sort(key=lambda t: t.get("createdAt", ""), reverse=True)

    print(f"Matching candidates:   {len(candidates)}")
    failed_count = sum(1 for t in candidates if is_failed(t))
    merged_count = sum(1 for t in candidates if is_merged(t, args.repo_path))
    if args.mode == "both":
        print(f"  — failed:   {failed_count}")
        print(f"  — merged:   {merged_count}")
    print()

    if not candidates:
        print("No matching tasks found. Nothing to do.")
        _print_footer(start_time)
        sys.exit(0)

    # ── Print candidate table ───────────────────────────────────────────────
    col_status = 8   # "FAILED" / "MERGED"
    col_repo   = 25
    col_date   = 19
    col_title  = 52

    header = (
        f"  {'#':>5}  {'STATUS':<{col_status}}  {'REPOSITORY':<{col_repo}}  "
        f"{'DATE':<{col_date}}  {'TITLE':<{col_title}}"
    )
    print(header)
    print("  " + "-" * (len(header) - 2))

    for idx, task in enumerate(candidates, 1):
        task_id = task["id"]
        status  = "FAILED" if is_failed(task) else merge_status_label(task)
        repo    = task.get("sourceId", "").replace("github/JMartynov/", "")
        ref_time = task_ref_time(task)
        date_str = ref_time.strftime("%Y-%m-%d %H:%M:%S") if ref_time else "Unknown"
        title   = (pr_title(task) or task.get("suggestedTitle", "Untitled"))[:col_title]
        print(
            f"  [{idx:03d}]  {status:<{col_status}}  {repo:<{col_repo}}  "
            f"{date_str:<{col_date}}  {title}"
        )

    print()

    if args.dry_run:
        print(f"DRY RUN — would archive {len(candidates)} tasks ({failed_count} failed, {merged_count} merged). No changes made.")
        _print_footer(start_time)
        sys.exit(0)

    if not jules_auth:
        print("Error: Cannot archive — no Jules API auth. Set JULES_API_KEY.", file=sys.stderr)
        sys.exit(1)

    # ── Archive ─────────────────────────────────────────────────────────────
    base_url = "https://jules.googleapis.com/v1alpha"
    archived = 0
    archive_errors = []

    print(f"Archiving {len(candidates)} tasks...")
    for idx, task in enumerate(candidates, 1):
        task_id  = task["id"]
        status   = "FAILED" if is_failed(task) else "MERGED"
        title    = (pr_title(task) or task.get("suggestedTitle", "Untitled"))[:52]
        print(f"  [{idx:03d}/{len(candidates)}] [{status}] {task_id}  {title}", end="  ")

        result = make_request_jules(
            f"{base_url}/sessions/{task_id}:archive",
            jules_auth,
            method="POST",
            data={}
        )
        if result is not None:
            print("✅ archived")
            archived += 1
        else:
            print("❌ failed")
            archive_errors.append(task_id)

        time.sleep(0.2)  # gentle rate limiting

    print()
    print("=" * 60)
    print(f"Archived:        {archived}")
    print(f"Errors:          {len(archive_errors)}")
    if archive_errors:
        print("Failed task IDs:")
        for tid in archive_errors:
            print(f"  {tid}")

    _print_footer(start_time)


def _print_footer(start_time):
    end_time = time.time()
    print("-" * 60)
    print(f"End Timestamp:   {end_time:.6f}")
    print(f"Duration:        {end_time - start_time:.4f}s")


if __name__ == "__main__":
    main()
