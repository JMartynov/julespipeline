# Task 15: Add routes for all tools

**Phase:** Phase 4 - API Layer

## Description
Add endpoints for `/extract-images`, `/compress`, `/pdf-to-markdown`, etc.

**Best Practices:**
- Organize routes using FastAPI's `APIRouter`.
- Provide comprehensive OpenAPI (Swagger) documentation, including expected file types and potential HTTP error codes (400, 415, 422).

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
