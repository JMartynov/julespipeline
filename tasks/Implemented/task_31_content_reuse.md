# Task 31: Content reuse

**Phase:** Phase 10 - SEO Pages

## Description
Wire up different SEO pages to the same backend tool.

**Best Practices:**
- Decouple the frontend marketing copy from the backend tool logic. `/extract-tables-from-bank-statement` and `/extract-tables-from-invoice` should both point to the `/extract-tables` API endpoint.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
