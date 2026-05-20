# Task 20: Create checkout endpoint

**Phase:** Phase 6 - Paywall Stripe

## Description
Implement `/create-checkout-session` endpoint.

**Best Practices:**
- Pass a `client_reference_id` (like a user ID or session cookie) to Stripe so you can reliably fulfill the order in the webhook.
- Provide clear `success_url` and `cancel_url` redirects.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
