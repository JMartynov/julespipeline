# Task 6: Extract Tables Service

**Phase:** Phase 3 - Implement Tools

## Description
Implement `tools/extract_tables/service.py` using `camelot-py`.

**Best Practices:**
- Support both `lattice` (for tables with clear lines) and `stream` (for tables defined by whitespace) parsing flavors in Camelot.
- Handle `ValueError` gracefully if Camelot detects no tables.
- Export directly to structured CSV/Excel bytes in memory to avoid unnecessary disk I/O when possible.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
