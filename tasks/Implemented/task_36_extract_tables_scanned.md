# Task 36: Extract Tables from Scanned PDF

**Phase:** Phase 12 - Additional Tools

## Description
Implement the **Extract Tables from Scanned PDF** tool.
Unlike the standard table extractor, this tool handles non-text (image-based) PDFs by first running an OCR pass, then extracting the tables.

**Best Approaches & Python Libraries:**
- **Pipeline Approach:**
  1. **OCR Pass:** Use `ocrmypdf` (which uses Tesseract and Ghostscript under the hood) or PyMuPDF's built-in Tesseract integration (`page.get_textpage_ocr()`) to create a searchable text layer over the images. Using `ocrmypdf` via subprocess or its Python API is highly recommended because it perfectly aligns invisible text over the image.
  2. **Table Extraction:** Feed the newly searchable PDF into the existing `camelot-py` logic.

**Example Python Flow:**
```python
import ocrmypdf
import camelot

# 1. OCR the scanned PDF
ocrmypdf.ocr(input_pdf, ocr_pdf, force_ocr=True)

# 2. Extract tables
tables = camelot.read_pdf(ocr_pdf, flavor='lattice')
```

**Best Practices & Codebase Alignment:**
- Create `tools/extract_tables_scanned/service.py` and `cli.py`.
- Run the OCR step via `asyncio.to_thread` since `ocrmypdf` and `camelot` are synchronous and CPU-bound.
- Ensure the intermediate OCR'd PDF is written to a secure temporary location using `shared.storage.temp` and is strictly cleaned up after processing.
- Reuse the `ToolResult` interface and standard CSV/Excel output methods.

**Test Cases:**
- **Unit Test:** Provide a PDF containing only images of tables (no text layer). Validate that tables are detected and the text content matches expected strings.
- **Edge Cases:** Handle PDFs where OCR fails gracefully, throwing a structured HTTP 422 or 400 error rather than a server crash 500.

## Acceptance Criteria
- [ ] Implemented as a standalone module in `tools/extract_tables_scanned/`.
- [ ] Registered within the FastAPI router.
- [ ] Uses Tesseract/`ocrmypdf` for the OCR pass and `camelot` for the table extraction.
- [ ] **Unit Tests (pytest):** Must include tests for extracting data from a purely scanned table.
- [ ] **Acceptance Tests (pytest):** Real scanned PDF test.
- [ ] Intermediate files rigorously cleaned up.