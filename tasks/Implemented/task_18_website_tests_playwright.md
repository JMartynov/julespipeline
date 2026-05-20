# Task 18: Website tests Playwright

**Phase:** Phase 5 - Acceptance Tests

## Description
Install `playwright` and write UI upload flow tests (automatic acceptance tests for web).

**Best Practices:**
- Use `page.set_input_files()` to simulate user file uploads.
- Assert on visual states (e.g., loading spinners, success messages, and download button visibility).

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
