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

## 📂 Project Structure

-   `pipeline.yaml`: The central configuration file.
-   `approve_plans.py`: Automatically approves all active Jules sessions or tasks currently in `AWAITING_PLAN_APPROVAL` status.
-   `get_unmerged_tasks.py`: Helper script to list and check the status of all current unmerged/active Jules tasks.
-   `get_failed_tasks.py`: Helper script to find and inspect all Jules tasks that are currently in `FAILED` state, displaying their definitions and plans (if available).
-   `recreate_failed_task.py`: Re-runs/re-creates a failed task, passing its original description and automatically monitoring/approving the plan step.
-   `jules_local_pipeline.sh`: Orchestrator for local git-based workflows.
-   `jules_remote_pipeline.sh`: Orchestrator for API-based, zero-copy remote workflows.
-   `tasks/`: A directory containing sequential feature tasks.
-   `implemented/`: History of completed and merged tasks.



## ⚙️ Configuration

Edit `pipeline.yaml` to match your environment:

```yaml
settings:
  repo: "your-username/your-repo-name"
  base_branch: "main"
prompts:
  task_start: "Instructions for implementation..."
  review: "Instructions for code review..."
tasks:
  - tasks/01_task_name.md
```

## 🏃 Execution

1.  **Export your API Key**:
    ```bash
    export JULES_API_KEY="your_actual_api_key"
    ```

2.  **Run in Remote Mode (Recommended)**:
    Does not require a local clone. Operations happen on GitHub servers.
    ```bash
    ./jules_remote_pipeline.sh pipeline.yaml
    ```

3.  **Run in Local Mode**:
    Requires you to be inside a git clone of the target repository.
    ```bash
    ./jules_local_pipeline.sh pipeline.yaml
    ```

## 🤖 Plan Auto-Approval Script

If you have multiple Jules sessions or tasks that are currently waiting for plan confirmation, you can use the `approve_plans.py` script to approve them all in one go from your terminal without opening the web console.

### How to use:

1. **Option A (OAuth/Keychain)**: Make sure you are logged in locally (run `jules login`). The script will automatically fetch your active token from the macOS Keychain.
2. **Option B (Sessions API)**: Make sure `JULES_API_KEY` is exported in your environment.
3. Run the script:
   ```bash
   ./approve_plans.py
   ```

## 🔍 Retrieve Failed Tasks Script

If you want to quickly identify and debug tasks that ended up in a `FAILED` state, you can run `get_failed_tasks.py`. It pulls failed tasks directly from the API, printing their full instructions/definition, and listing their plan steps if they had generated one.

### CLI Options:
- `-n`, `--limit`: Limit the number of failed tasks displayed (e.g. `-n 5` to show only the 5 most recent failed tasks).
- `-r`, `--repo`: Filter by repository name substring (e.g. `-r ai-usage-monitor`).

### How to run:
```bash
./get_failed_tasks.py -n 5
```

## ⚠️ Important Notes

-   **Autonomy**: The orchestrator is designed to be "hands-off". It automatically approves Jules' plans and answers clarification questions with a "Proceed" directive.
-   **Colorized Logs**: Green `[OK]` indicates a successful step; Red `[FAIL]` indicates an error that requires attention.
-   **Terminal States**: The script tracks terminal session states and will retry auto-approvals up to 10 times before failing a task.
