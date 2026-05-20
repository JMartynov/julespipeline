# Task 41: Global Cross-Tool Matrix Testing

## Phase
Testing & Validation

## Description
Ensure that every PDF tool is executed against every file in both the generated library and the downloaded "Wild" corpus. The primary goal is to ensure zero unhandled exceptions, zero memory leaks, and absolute resilience against malformed "fuzzer" data across the entire suite.

## Acceptance Criteria
1. **Goal:** Ensure zero unhandled exceptions across the entire suite when processing unexpected, malformed, or malicious data.
2. **Implementation:** Create `tests/acceptance/test_all_tools_matrix.py`.
3. Parameterize all 10 PDF tools against *every* file in the generated library (`tests/fixtures/generated/`) and downloaded corpus (`tests/fixtures/corpus/`).
4. **Resilience & Fuzzing Checks:** 
   - **Graceful Degradation:** The test passes if the tool either succeeds (returns `ToolResult` with status 'success') or fails gracefully with a structured error (status 'error').
   - **Crash Prevention:** The test FAILS if the tool crashes, throws an unhandled exception (e.g., segmentation fault, `MemoryError`, `RecursionError`), or brings down the test runner.
   - **Timeout Enforcement:** Wrap tool execution in a strict timeout (e.g., 30 seconds). A "PDF Bomb" designed to cause an infinite loop must be caught by the timeout and return a graceful error, rather than hanging the process.
   - **I/O Cleanup Guarantee:** Assert that regardless of whether the tool succeeds, fails, or times out, all temporary files in `/tmp` (or `TEMP_DIR`) are successfully cleaned up to prevent disk-exhaustion DoS attacks.