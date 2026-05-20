# Implement Remaining Web Acceptance Tests

**Phase:** Testing
**Description:** Implement the remaining acceptance test scenarios identified in the comprehensive `tests/acceptance/web/TEST_PLAN.md` to achieve 100% frontend test coverage.

## Background
A comprehensive test plan has been mapped out covering all website paths, UI elements, and user flows. We currently have 18 scenarios passing. We need to implement the remaining edge cases, error handling, tool-specific parameters, and complex interactions detailed in the plan.

## Acceptance Criteria
- [ ] Implement multi-file upload scenario.
- [ ] Implement scenario verifying that invalid file types (e.g., `.txt`) are rejected with an appropriate UI error message and the file input is cleared.
- [ ] Implement tool execution scenario for `compress-pdf` selecting a specific preset dropdown value.
- [ ] Implement tool execution scenario for `rotate-pages` selecting a specific angle from the dropdown.
- [ ] Implement error handling scenario for simulating an API 500 timeout/failure and verifying the "Processing failed" card appears.
- [ ] Implement session reset scenario: complete a tool execution, click "Start Over", and verify the UI resets to the empty drop zone state.
- [ ] Implement route protection scenario: attempt to access `/admin/dashboard` without an active cookie and verify redirection to `/admin/login`.
- [ ] Implement admin dashboard action: clicking "Change Tier" for a user, handling the browser prompt, and verifying the action (using a mock API response).
- [ ] Ensure all new scenarios pass successfully against the mocked Playwright backend in headless/headed modes.
- [ ] Ensure `pytest-html` report generates cleanly without warnings.

## Notes
- Refer to `tests/acceptance/web/TEST_PLAN.md` for the exact expected UI text, CSS selectors, and test parameters.
- Use `tests/acceptance/web/conftest.py` for adding any new API route mocks needed for these remaining scenarios.
- Add the necessary step definitions to `tests/acceptance/web/steps/test_all_web_steps.py`.