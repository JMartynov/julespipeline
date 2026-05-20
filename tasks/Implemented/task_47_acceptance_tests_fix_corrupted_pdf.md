# Task 47: Comprehensive Acceptance Tests - fix_corrupted_pdf

## Phase
Testing & Validation

## Description
Develop granular acceptance tests for `fix_corrupted_pdf`. This relies on PyMuPDF's internal `convert_to_pdf()` engine to rebuild XREF tables and drop garbage bytes.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Structural Corruption Use Cases (Generated via byte-manipulation)
- **Truncated File:** Programmatically strip the `%%EOF` marker and the last 100 bytes from a valid PDF. **Test:** PyMuPDF reconstructs the XREF table and the file opens successfully.
- **Corrupt XREF Offsets:** Programmatically overwrite the byte offsets in the `xref` table with random integers. **Test:** Tool scans for objects linearly, rebuilding the table and saving a functional PDF.
- **Missing `/Root` Catalog:** Delete the catalog dictionary reference. **Test:** Validate if the tool can salvage orphan pages or if it explicitly fails with a structured error.
- **Circular Object References:** Craft a malicious PDF where object 1 refers to object 2, which refers back to object 1. **Test:** Prevent infinite loops; tool must timeout or detect cyclic references and fail gracefully.

### 2. Format & Edge Cases
- **Completely Invalid Signatures:** Pass an HTML file or a PNG file renamed to `.pdf`. **Test:** `doc.is_pdf` catches this, returning a fast, explicit error without attempting a conversion.
- **Zero-Byte File:** Pass an empty 0-byte file. **Test:** Graceful error handling.
- **Password Protected & Corrupted:** Pass a truncated file that is also encrypted. **Test:** Ensure the cryptographic failure is caught gracefully without an unhandled crash.