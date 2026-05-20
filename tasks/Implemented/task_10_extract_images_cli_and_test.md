# Task 10: Extract Images CLI and Test

**Phase:** Phase 3 - Implement Tools

## Description
Implement CLI and unit test for the Extract Images tool with its own test PDF.

**Best Practices:**
- Provide a CLI flag for output directory.
- Test against PDFs containing multiple image formats (CMYK JPEGs, transparent PNGs).

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
