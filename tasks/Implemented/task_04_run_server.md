# Task 4: Run server

**Phase:** Phase 1 - Base Setup

## Description
Setup script or verify `uvicorn apps.api.main:app --reload` works.

**Best Practices:**
- Create a `Makefile` or `Taskfile` to encapsulate common commands (e.g., `make run`, `make test`).
- Ensure the server binds to `0.0.0.0` inside Docker, but defaults to `127.0.0.1` locally.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
