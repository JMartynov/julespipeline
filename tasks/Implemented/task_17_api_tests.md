# Task 17: API tests

**Phase:** Phase 5 - Acceptance Tests

## Description
Create `tests/e2e/test_api.py` testing the FastAPI upload routes.

**Best Practices:**
- Use `httpx.AsyncClient` alongside `pytest-asyncio` for robust asynchronous API testing.
- Mock the underlying tool logic if you only want to test the HTTP boundary, or use a small dummy PDF for full integration testing.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
