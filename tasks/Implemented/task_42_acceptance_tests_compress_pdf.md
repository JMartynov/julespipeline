# Task 42: Comprehensive Acceptance Tests - compress_pdf

## Phase
Testing & Validation

## Description
Develop highly granular acceptance tests for the `compress_pdf` tool. Ensure testing spans procedural invariant-based PDFs and real-world edge cases from the wild corpus. The focus is verifying that `doc.save(garbage=4, deflate=True, clean=True)` behaves correctly across varying structures.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Structural Use Cases (Generated via `generator.py`)
- **Uncompressed RGB Images:** Generate a PDF containing raw uncompressed BMP/TIFF images. **Test:** Output size is reduced by >50%.
- **Dangling/Unused Objects:** Generate a PDF with unreferenced XObjects and subset fonts (orphaned in the XREF table). **Test:** `garbage=4` strips these, reducing file size and object count.
- **Unoptimized Vector Paths:** Generate a PDF with thousands of redundant vector points. **Test:** `clean=True` simplifies the paths.
- **Already Deflated:** Pass an optimally deflated PDF. **Test:** File size should not increase significantly; no unhandled exceptions.

### 2. Format & Edge Cases (Corpus / Generated)
- **Encryption:** Attempt to compress an RC4/AES encrypted PDF. **Test:** Should gracefully fail or retain encryption without corrupting the file.
- **Exotic Image Encodings:** Use a corpus PDF containing `JBIG2Decode` and `JPXDecode` (JPEG2000) streams. **Test:** Compression completes successfully, and images are not visually destroyed or removed.
- **PDF/A Compliance:** Use a strictly compliant PDF/A-1b document from veraPDF corpus. **Test:** Check if the output remains compliant or explicitly logs the loss of compliance.
- **Large File Streaming:** Pass a massive >500MB PDF. **Test:** Peak memory consumption must remain stable (due to `asyncio.to_thread` and fitz memory mapping).