# Jules Stateful Pipeline Orchestrator

This project implements an automated, stateful development pipeline built on top of [Jules](https://jules.google). It allows you to define a series of feature requests (tasks) in a configuration file and execute them sequentially. 

The pipeline supports two modes of operation:
1.  **Local Mode**: Performs git operations (clone, branch, merge) on your machine.
2.  **Remote Mode**: Performs all operations (implementation, review, merging) entirely on GitHub's servers via API, requiring no local repository copy.

## 🚀 How it Works

The pipeline follows a strict **Task -> Implement -> Review -> Merge** cycle:

1.  **Task Execution**: The orchestrator reads a task description from a `.md` file.
2.  **Implementation Session**: It creates a Jules session to implement the feature and tests.
3.  **Review Session**: It starts a *second* Jules session to perform code review, bug fixes, and ensure quality.
4.  **Automated Merge**: Once the review is integrated, the feature is merged into the base branch (e.g., `main`).
5.  **State Progression**: The pipeline moves to the next task using the updated code as the new base.

## 🛠 Prerequisites

Ensure you have the following installed and configured:

-   **Jules API Key**: Obtain your key from the [Jules Console](https://jules.google).
-   **GitHub CLI (`gh`)**: Installed and authenticated (`gh auth login`).
-   **jq**: A lightweight command-line JSON processor.
-   **git**: Required only for Local Mode.

## 📂 Project Structure & Scripts

This repository contains multiple orchestrators and utility scripts to manage your Jules workflows at scale.

### 🚀 Orchestrator Scripts

| Script | Mode | Description |
| :--- | :--- | :--- |
| [`jules_parallel_pipeline.sh`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/jules_parallel_pipeline.sh) | **Parallel Remote** | Runs all configured tasks concurrently using background jobs. Integrates automatically via GitHub merges API. Features dynamic macOS Keychain authentication fallback if `JULES_API_KEY` is expired. |
| [`jules_remote_pipeline.sh`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/jules_remote_pipeline.sh) | **Sequential Remote** | Runs configured tasks one after the other on GitHub servers. |
| [`jules_local_pipeline.sh`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/jules_local_pipeline.sh) | **Sequential Local** | Runs tasks sequentially, executing git operations (clone, branch, merge) locally on your machine. |

### 🛠 Utility & Helper Scripts

| Script | Purpose |
| :--- | :--- |
| [`approve_plans.py`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/approve_plans.py) | Auto-approves all active remote sessions or local tasks waiting in `AWAITING_PLAN_APPROVAL` status. |
| [`recreate_failed_task.py`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/recreate_failed_task.py) | Locates a failed task, creates a new run with the same description, and monitors/approves its plan. |
| [`get_failed_tasks.py`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/get_failed_tasks.py) | Pulls and displays details of failed tasks from the Aida API to help with debugging. |
| [`get_unmerged_tasks.py`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/get_unmerged_tasks.py) | Lists and checks status of active/completed remote tasks that have not yet been merged. |
| [`archive_tasks.py`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/archive_tasks.py) | Archives completed/merged or failed tasks to declutter the Jules dashboard. |
| [`open_missing_prs.py`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/open_missing_prs.py) | Scans for completed tasks that successfully pushed code branches but failed to create a PR, and opens them. |
| [`merge_prs.py`](file:///Users/ivan/Project/3t.tools.intellij/mongo/julespipeline/merge_prs.py) | Automates merging of all open pull requests in the target repository that have no conflicts. |

---

## ⚙️ Configuration

Edit your configuration file (e.g., `pipeline_parallel.yaml` or `pipeline_remote.yaml`) to match your settings:

```yaml
settings:
  repo: "your-username/your-repo-name"
  base_branch: "main"
  api_url: "https://jules.googleapis.com/v1alpha"
  polling_interval_seconds: 10
prompts:
  task_start: "Instructions for implementation..."
  review: "Instructions for code review..."
tasks:
  - tasks/ToDo/6.35_demo_enhancement_match_pushdown_validator.md
```

---

## 🏃 Execution Guide

### 1. Set Authentication
Export your Jules API key:
```bash
export JULES_API_KEY="your_api_key_here"
```
*Note: If your key has expired or is invalid, the parallel pipeline will automatically attempt to retrieve a fresh OAuth 2 token from your macOS Keychain (requires active `jules login`).*

### 2. Running the Orchestrators

#### Run Tasks in Parallel (Recommended for Batch Tasks)
Spawns background jobs for all tasks in the config concurrently:
```bash
./jules_parallel_pipeline.sh pipeline_parallel.yaml
```

#### Run Tasks Sequentially (Remote)
Runs tasks one-by-one on remote VMs via GitHub API:
```bash
./jules_remote_pipeline.sh pipeline_remote.yaml
```

#### Run Tasks Sequentially (Local)
Requires you to be inside a local git clone of the target repository:
```bash
./jules_local_pipeline.sh pipeline_local.yaml
```

---

## 📜 Utility Scripts Usage Reference

### 🟢 Plan Auto-Approval
Approve all pending plans to unblock running tasks:
```bash
./approve_plans.py
```
*Uses either `JULES_API_KEY` for remote sessions, or OAuth token from `jules login` for local tasks.*

### 🟡 Recreate a Failed Task
```bash
./recreate_failed_task.py --task-id <id>   # Re-run a specific failed task
./recreate_failed_task.py --today         # Re-run today's failed tasks
./recreate_failed_task.py --all           # Re-run all failed tasks
```

### 🔴 List Failed Tasks
```bash
./get_failed_tasks.py -n 5                 # Show details of the 5 most recent failures
./get_failed_tasks.py -r llm-mongo-optimizer # Filter by repo
```

### 🔵 List Unmerged Tasks
Checks status of tasks that are completed but PR is still open:
```bash
./get_unmerged_tasks.py --repo JMartynov/llm-mongo-optimizer
```

### 🧹 Archive Completed / Failed Tasks
Clean up your Jules task list:
```bash
./archive_tasks.py --mode failed --all     # Archive all failed tasks
./archive_tasks.py --mode merged --all     # Archive all completed and merged tasks
./archive_tasks.py --mode both             # Archive both categories
```

### 📥 Create Missing Pull Requests
Find completed tasks that missed PR creation and open PRs for them:
```bash
./open_missing_prs.py --repo-path /path/to/local/checkout
```

### 🔀 Merge Conflict-Free Pull Requests
Bulk-merges open PRs that have no conflicts:
```bash
./merge_prs.py --repo-path /path/to/local/checkout
```

---

## ⚠️ Important Notes
- **Log Isolation**: In parallel mode, individual task progress is saved under `logs/task_<name>.log` to avoid interleaving, while high-level status updates are color-coded and outputted to the main console.
- **Autonomy**: The orchestrator automatically answers clarification/paused questions with a "Proceed with best judgment" directive.
- **Conflict Handling**: If a remote merge fails due to conflicts, it fails gracefully, skips the merge step for that task, and logs the PR details so you can resolve conflicts manually.

---

## 💡 Running the Mongo Optimizer Demo

If you are looking for details on running the performance tuning orchestrator (using flags like `--fast`, `--detailed`, and `--scenario`), please see the documentation in the optimizer repository:
*   [llm-mongo-optimizer User Instructions (INSTRUCTIONS.md)](file:///Users/ivan/Project/3t.tools.intellij/mongo/llm-mongo-optimizer/INSTRUCTIONS.md#L99)
*   [llm-mongo-optimizer Overview (README.md)](file:///Users/ivan/Project/3t.tools.intellij/mongo/llm-mongo-optimizer/README.md#L76)

