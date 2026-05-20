# Task 11: PDF to Markdown

**Phase:** Phase 3 - Implement Tools

## Description
Implement PDF to Markdown tool (service, CLI, test) using `pdfplumber`.

**Best Practices:**
- Leverage `pdfplumber`'s precise bounding box extraction to distinguish between headers (larger font) and paragraph text.
- Create a custom parsing heuristic that tracks font weights and sizes to accurately infer Markdown `#` headers and lists.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
