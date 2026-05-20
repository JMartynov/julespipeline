# Task 38: Remove Duplicate Pages

**Phase:** Phase 12 - Additional Tools

## Description
Implement the **Remove Duplicate Pages** tool.
This tool detects and removes pages with identical content. This is highly useful for aggregated documents or scans where pages were duplicated by mistake.

**Best Approaches & Python Libraries:**
- **PyMuPDF (`fitz`) + Cryptographic Hashing:**
  Comparing raw text is insufficient because pages might have identical text but different images/layouts. The most robust way to detect visual duplicates is rendering the page to a low-resolution pixmap and hashing the pixel data.
  
**Example Python Flow:**
```python
import fitz
import hashlib

def remove_duplicates(input_path, output_path):
    doc = fitz.open(input_path)
    new_doc = fitz.open()
    seen_hashes = set()
    
    for page in doc:
        # Render at low DPI to ignore microscopic rendering artifacts
        pix = page.get_pixmap(dpi=36)
        page_hash = hashlib.md5(pix.samples).hexdigest()
        
        if page_hash not in seen_hashes:
            seen_hashes.add(page_hash)
            new_doc.insert_pdf(doc, from_page=page.number, to_page=page.number)
            
    new_doc.save(output_path)
```

**Best Practices & Codebase Alignment:**
- Create `tools/remove_duplicate_pages/service.py` and `cli.py`.
- The logic involves pure CPU computation. While `fitz` is relatively fast, large PDFs should still have the execution wrapped in `asyncio.to_thread` for the FastAPI endpoints.
- Return metrics in the `ToolResult` (e.g., "removed_pages_count": 3) so the UI can display to the user how many pages were deleted.

**Test Cases:**
- **Unit Test:** Provide a PDF with exactly identical pages (e.g., Pages 1, 2, 3 are identical, Page 4 is different). Assert the output PDF contains exactly 2 pages.
- **Acceptance Test:** Test with a mix of text and image-heavy PDFs to ensure hashing speed doesn't time out.

## Acceptance Criteria
- [ ] Implemented as a standalone module in `tools/remove_duplicate_pages/`.
- [ ] Registered within the FastAPI router.
- [ ] Uses PyMuPDF and MD5/SHA256 hashing on pixmaps/content streams to ensure accuracy.
- [ ] **Unit Tests (pytest):** Must accurately reduce page counts on duplicate data.
- [ ] **Acceptance Tests (pytest):** Execute against real-world PDFs.