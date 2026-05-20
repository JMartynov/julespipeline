# Task 8: Extract Tables Unit Test

**Phase:** Phase 3 - Implement Tools

## Description
Create `tests/unit/test_extract_tables.py` using tool-specific test PDF files.

**Best Practices:**
- Use `pytest` fixtures to manage test PDF files.
- Verify not just the execution, but the integrity of the extracted CSV data against a known "golden" snapshot.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
