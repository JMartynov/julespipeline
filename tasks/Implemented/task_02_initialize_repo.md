# Task 2: Initialize repo

**Phase:** Phase 1 - Base Setup

## Description
Create repo, setup Python project, install dependencies: `fastapi uvicorn pytest pydantic[email]`.

**Best Practices:**
- Use `pyproject.toml` for modern dependency management and tool configuration.
- Setup a `.gitignore` specifically tailored for Python, FastAPI, and IDEs.
- Isolate environments using `venv` or `poetry`.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
