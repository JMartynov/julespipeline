# Task 29: Reverse proxy nginx

**Phase:** Phase 9 - Deploy Ubuntu

## Description
Document configuring Nginx to route domain to port 8000.

**Best Practices:**
- Always configure SSL/TLS using Let's Encrypt (`certbot`).
- Set appropriate `client_max_body_size` in Nginx to allow large PDF uploads (e.g., `50M`).

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
