# Task 44: Comprehensive Acceptance Tests - extract_images

## Phase
Testing & Validation

## Description
Develop granular acceptance tests for the `extract_images` tool. Testing must evaluate how PyMuPDF handles various color spaces, masks, and inline vs. XObject image definitions.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Structural Use Cases (Generated via `generator.py`)
- **Standard `FlateDecode`:** Generate a PDF with embedded PNGs. **Test:** Extracted byte streams match original file signatures.
- **Soft Masks (`/SMask`):** Generate a PDF with an image utilizing an alpha transparency mask. **Test:** Currently, `doc.extract_image(xref)` may extract the mask and base image as two separate opaque files. The test should assert they are either separate or combined, driving TDD for alpha-channel reconstruction.
- **Inline Images vs. XObjects:** Generate a PDF using inline image streams (`BI ... ID ... EI`) instead of XRef objects. **Test:** Ensure `get_images(full=True)` captures them.
- **Vector Drawings:** Generate a page using purely vector graphics (e.g., SVG paths). **Test:** Ensure tool gracefully returns 0 images, not crashing.

### 2. Format & Edge Cases (Corpus / Generated)
- **CMYK Color Space:** Process a corpus prepress PDF in CMYK. **Test:** The extracted JPEG/TIFF must retain the CMYK profile or explicitly convert to sRGB without severe color inversion.
- **Exotic Formats (1-bit / JPX):** Process `CCITTFaxDecode` (monochrome scanned documents) and `JPXDecode` (JPEG2000). **Test:** Must successfully extract and map to `.tiff` or `.jp2` extensions.
- **Deduplication:** A document where the same company logo XRef is used on 50 pages. **Test:** Currently, the service extracts it 50 times. Write a test asserting it extracts 50 times (or assert deduplication if you plan to fix it).
- **Corrupt Image Stream:** A PDF with a truncated image byte stream. **Test:** Must fail gracefully, skipping the image or returning an error, without taking down the server.