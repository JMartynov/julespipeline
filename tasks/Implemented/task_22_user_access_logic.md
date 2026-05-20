# Task 22: User access logic

**Phase:** Phase 6 - Paywall Stripe

## Description
Create `shared/limits/service.py` for user usage limits (free vs pro).

**Best Practices:**
- Isolate the access logic from the API routes using FastAPI Dependencies (`Depends(check_rate_limit)`).
- Raise explicit `HTTPException(status_code=402, detail="Payment Required")` when limits are hit.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
