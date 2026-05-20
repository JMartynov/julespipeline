# Task 32: Storage temp

**Phase:** Bonus - Shared Libraries

## Description
Implement `shared/storage/temp.py` for temp file saving and cleanup.

**Best Practices:**
- Use Python's built-in `tempfile` module.
- Ensure files are guaranteed to be deleted after processing using `try...finally` blocks or Context Managers (`with`), even if the extraction process crashes.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
