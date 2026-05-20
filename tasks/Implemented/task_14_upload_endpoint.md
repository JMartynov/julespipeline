# Task 14: Upload endpoint

**Phase:** Phase 4 - API Layer

## Description
Create `apps/api/routes/upload.py` with a `/extract-tables` POST endpoint.

**Best Practices:**
- Use FastAPI's `UploadFile` to stream large PDFs directly to temporary storage without overwhelming RAM.
- Use `BackgroundTasks` if the extraction is expected to take longer than a standard HTTP timeout, returning a job ID instead.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
