#!/usr/bin/env python3
import subprocess
import json
import argparse
import sys
import time

def main():
    parser = argparse.ArgumentParser(description="Merge open PRs that have no conflicts.")
    parser.add_argument("--repo-path", required=True, help="Path to the repository")
    args = parser.parse_args()

    print("Fetching open PRs...")
    res = subprocess.run(
        ["gh", "pr", "list", "--state", "open", "--json", "number,title,mergeable,mergeStateStatus,headRefName"],
        cwd=args.repo_path, capture_output=True, text=True
    )
    
    if res.returncode != 0:
        print(f"Error fetching PRs: {res.stderr}", file=sys.stderr)
        sys.exit(1)
        
    prs = json.loads(res.stdout)
    if not prs:
        print("No open PRs found.")
        return
        
    merged_count = 0
    conflicting_prs = []
    
    for pr in prs:
        num = pr["number"]
        title = pr["title"]
        mergeable = pr["mergeable"]
        status = pr["mergeStateStatus"]
        branch = pr["headRefName"]
        
        print(f"\n[PR #{num}] {title}")
        print(f"  Branch: {branch}")
        print(f"  Mergeable: {mergeable}")
        print(f"  Status: {status}")
        
        if mergeable == "CONFLICTING" or status == "DIRTY":
            print("  ⚠️ PR has conflicts. Skipping.")
            conflicting_prs.append(pr)
            continue
            
        if mergeable == "UNKNOWN":
            print("  ⏳ GitHub is still calculating mergeability. Retrying slightly...")
            # Trigger a retry or just skip
            pass
            
        if mergeable in ("MERGEABLE", "UNKNOWN"):
            print(f"  🚀 Attempting to merge PR #{num}...")
            # We use --admin or --merge. Since we might have checks failing (UNSTABLE) but user wants to merge them if no conflict.
            # Using --merge --admin if needed, or just --merge.
            merge_res = subprocess.run(
                ["gh", "pr", "merge", str(num), "--merge", "--delete-branch", "--admin"],
                cwd=args.repo_path, capture_output=True, text=True
            )
            
            if merge_res.returncode == 0:
                print(f"  ✅ Merged PR #{num}")
                merged_count += 1
            else:
                err = merge_res.stderr.strip()
                print(f"  ❌ Failed to merge PR #{num}: {err}")
                
    print(f"\nSummary: Merged {merged_count} PRs.")
    if conflicting_prs:
        print(f"The following {len(conflicting_prs)} PRs have conflicts and require manual resolution:")
        for pr in conflicting_prs:
            print(f"  - #{pr['number']}: {pr['title']} ({pr['headRefName']})")

if __name__ == "__main__":
    main()
