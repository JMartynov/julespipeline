# Task 23: IP limiter

**Phase:** Phase 7 - Limit System

## Description
Implement IP rate limiting middleware.

**Best Practices:**
- Use a fast in-memory store (like Redis) for rate limit tracking in production. For MVP, Python's built-in memory/cache is acceptable.
- Ensure the middleware correctly identifies the client IP, especially when behind a reverse proxy (trusting `X-Forwarded-For` safely).

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
