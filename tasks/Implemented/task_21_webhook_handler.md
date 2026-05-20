# Task 21: Webhook handler

**Phase:** Phase 6 - Paywall Stripe

## Description
Implement webhook listener for `checkout.session.completed`.

**Best Practices:**
- **CRITICAL:** Always verify the Stripe webhook signature using `stripe.Webhook.construct_event`.
- Make the webhook handler idempotent. If Stripe sends the same event twice, your system should not upgrade the user twice.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
