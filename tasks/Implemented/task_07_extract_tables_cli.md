# Task 7: Extract Tables CLI

**Phase:** Phase 3 - Implement Tools

## Description
Implement `tools/extract_tables/cli.py` to run extraction from the command line separately.

**Best Practices:**
- Use `argparse` or `typer` for robust CLI argument parsing and help text generation.
- Ensure the CLI exit codes are standard (`0` for success, non-zero for failures).

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
