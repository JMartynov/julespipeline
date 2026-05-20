# Task 46: Comprehensive Acceptance Tests - extract_tables_scanned

## Phase
Testing & Validation

## Description
Develop granular acceptance tests for `extract_tables_scanned`, which uses PyMuPDF pixmaps and `easyocr`. This tool is highly CPU/Memory intensive and susceptible to noise.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Rasterization & OCR Use Cases (Generated/Corpus)
- **Clean High-Res Scan:** A 300 DPI rasterized image of a table. **Test:** OCR accurately maps text to a searchable hidden layer, and PyMuPDF's `find_tables()` reconstructs the CSV.
- **Skewed/Rotated Scans:** A table scanned with a 5-degree tilt. **Test:** Test extraction accuracy. (Will likely degrade; establishing a baseline is critical).
- **Gaussian Noise & Artifacts:** A simulated fax with heavy pepper noise and vertical streaks. **Test:** Ensure `easyocr` does not throw an exception on unintelligible blobs.
- **Low DPI:** A 72 DPI scanned image. **Test:** Ensure text bounding boxes (`bbox`) map accurately to the scaled page geometry without out-of-bounds exceptions.

### 2. Format & Edge Cases
- **Non-English Characters:** Pass a scanned document containing Japanese or Cyrillic text. **Test:** Since `easyocr.Reader(["en"])` is hardcoded, assert that it returns garbled text or ignores it gracefully without crashing.
- **Memory Profiling:** Process a 50-page scanned document. **Test:** Because `img_data` arrays and `tmp_pdf` are created iteratively, ensure there are no severe memory leaks and that the test passes within a reasonable timeout.
- **Blank Pages / No Tables:** A scanned photo of a landscape. **Test:** Gracefully returns "No tables detected".