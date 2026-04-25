# Jules Stateful Pipeline Orchestrator

This project implements an automated, stateful development pipeline built on top of [Jules](https://jules.google). It allows you to define a series of feature requests (tasks) in a configuration file and execute them sequentially. Each task generates a PR, which is then automatically reviewed by a second Jules session before being merged into the main branch.

## 🚀 How it Works

The pipeline follows a strict **Task -> Build -> Review -> Merge** cycle:

1.  **Task Execution**: The orchestrator reads a task description from a `.md` file.
2.  **Feature Session**: It creates a Jules session using `AUTO_CREATE_PR` mode to implement the feature and tests.
3.  **Branch Extraction**: It retrieves the PR URL from the session output and uses the GitHub CLI (`gh`) to extract the head branch name.
4.  **Review Session**: It starts a *second* Jules session targeting the **extracted branch** to perform code review, bug fixes, and PEP 8 compliance.
5.  **Automated Merge**: Once the review is complete, the final PR is merged into the base branch (e.g., `main`).
6.  **State Progression**: The local repository pulls the latest changes, and the pipeline moves to the next task using the updated code as the new base.

## 🛠 Prerequisites

Ensure you have the following installed and configured:

-   **Jules API Key**: Obtain your key from the [Jules Console](https://jules.google).
-   **GitHub CLI (`gh`)**: Installed and authenticated (`gh auth login`).
-   **jq**: A lightweight command-line JSON processor.
-   **git**: Configured with access to your target repository.

## 📂 Project Structure

-   `pipeline.yaml`: The central configuration file.
-   `demo.sh`: The Bash orchestrator script.
-   `tasks/`: A directory containing 10 predefined feature tasks in Markdown format.
-   `src/`: Starter code for the demonstration Python calculator app.

## ⚙️ Configuration

Edit `pipeline.yaml` to match your environment:

```yaml
settings:
  repo: "your-username/your-repo-name"  # The GitHub repository to work on
  base_branch: "main"                 # The starting branch for the first task
  automation_mode: "AUTO_CREATE_PR"   # Required to get a stable branch output
prompts:
  review: "Review this branch for bugs, improve code quality, fix issues, and ensure all tests pass."
tasks:
  - tasks/01_basic_math.md
  - tasks/02_string_parsing.md
  # ... (list of tasks to execute)
```

## 🏃 Execution

1.  **Export your API Key**:
    ```bash
    export JULES_API_KEY="your_actual_api_key"
    ```

2.  **Make the script executable**:
    ```bash
    chmod +x demo.sh
    ```

3.  **Start the pipeline**:
    ```bash
    ./demo.sh
    ```

## 📝 The 10 Tasks

The pipeline is pre-configured to build a robust Python Calculator with:
1.  Basic Math & Custom Exceptions
2.  String Expression Parsing
3.  Floating Point Support (Decimal)
4.  Advanced Functions (Log, Sqrt)
5.  History Tracking
6.  CLI Interface (`argparse`)
7.  JSON Export
8.  JSON Import
9.  Standard Logging
10. REST API (`FastAPI`)

## ⚠️ Important Notes

-   **Statelessness**: Each Jules session is independent. The pipeline manages state by passing the `startingBranch` from the previous task's resulting PR.
-   **Branch Control**: Jules generates internal branch names. The orchestrator dynamically discovers these names via the GitHub API.
-   **Merge Strategy**: By default, `demo.sh` uses `--squash` to keep the main branch history clean.
