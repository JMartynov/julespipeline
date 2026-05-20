# Task 25: Dockerfile

**Phase:** Phase 8 - Docker

## Description
Create `Dockerfile` based on `python:3.11`.

**Best Practices:**
- Use a `slim` image (e.g., `python:3.11-slim`) to reduce vulnerability surface area.
- Use multi-stage builds.
- Install OS-level dependencies (`ghostscript`, `tesseract-ocr`) in a single `RUN apt-get` layer to reduce image size.
- Run the application as a non-root user.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
