# Task 33: Utils hash

**Phase:** Bonus - Shared Libraries

## Description
Implement `shared/utils/hash.py` for file caching.

**Best Practices:**
- Use fast cryptographic hashes (like SHA-256) to fingerprint incoming PDFs.
- If a hashed PDF has already been processed, return the cached result instead of re-running CPU-intensive extraction.

## Acceptance Criteria
- [ ] Implemented as a standalone module/step and executable independently.
- [ ] Adheres strictly to the outlined best practices.
- [ ] **Unit Tests (pytest):** Must include comprehensive unit tests covering the core logic, success paths, and error handling. Aim for extremely high coverage.
- [ ] **Acceptance Tests (pytest):** Must include real-world scenario tests (using actual obfuscated PDF files or HTTP mocks where applicable) to verify the end-to-end success of the specific tool or module.
- [ ] **Edge Cases:** All edge cases (e.g., malformed input, missing data, timeouts) must be explicitly tested and handled gracefully.
