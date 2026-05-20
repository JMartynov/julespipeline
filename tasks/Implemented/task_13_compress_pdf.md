# Task 13: Compress PDF

**Phase:** Phase 3 - Implement Tools

## Description
Implement Compress PDF tool wrapping Ghostscript.

**Best Practices:**
- Wrap the Ghostscript `subprocess` call securely. Prevent command injection by passing arguments as an array, not a shell string.
- Offer presets (e.g., `screen`, `ebook`, `printer`) which map to Ghostscript's `-dPDFSETTINGS`.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
