# Task 9: Extract Images Service

**Phase:** Phase 3 - Implement Tools

## Description
Implement `tools/extract_images/service.py`.

**Best Practices:**
- Use `PyMuPDF` (`fitz`) as it is significantly faster and more robust than PDFBox in Python environments.
- Extract image bytes directly (e.g., `extract_image()`) to avoid re-encoding and losing original quality/color profiles.
- Keep track of image extensions (`.png`, `.jpeg`) based on the extracted metadata.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
