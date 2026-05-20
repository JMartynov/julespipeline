# Task 24: Cookie tracking

**Phase:** Phase 7 - Limit System

## Description
Implement cookie-based usage tracking.

**Best Practices:**
- Use HttpOnly, Secure cookies to prevent XSS attacks.
- Sign or encrypt the cookie to prevent users from tampering with their usage count.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
