# Task 39: Rotate Specific Pages

**Phase:** Phase 12 - Additional Tools

## Description
Implement the **Rotate Specific Pages** tool.
Allows users to rotate individual pages (e.g., 90°, 180°, 270°) without altering the orientation of the rest of the document.

**Best Approaches & Python Libraries:**
- **PyMuPDF (`fitz`):**
  PyMuPDF provides extremely fast, precise manipulation of the PDF page dictionary's `/Rotate` attribute.

**Example Python Flow:**
```python
import fitz

def rotate_pages(input_path, output_path, rotation_map: dict[int, int]):
    # rotation_map maps 0-indexed page numbers to angles (e.g. {0: 90, 2: 180})
    doc = fitz.open(input_path)
    
    for page_num, angle in rotation_map.items():
        if 0 <= page_num < len(doc):
            page = doc[page_num]
            # set_rotation accepts 0, 90, 180, 270
            page.set_rotation(angle)
            
    doc.save(output_path)
```

**Best Practices & Codebase Alignment:**
- Create `tools/rotate_pages/service.py` and `cli.py`.
- **Validation:** Use Pydantic V2 to strictly validate the API payload. The payload must be a dictionary or list mapping page numbers to valid angles (0, 90, 180, 270). Any other angle must fail validation immediately with a 422 HTTP response.
- Expose CLI arguments that parse gracefully (e.g., `--rotate 1:90 --rotate 3:180` where 1 and 3 are page numbers).

**Test Cases:**
- **Unit Test:** Apply rotation to pages 1 and 3. Load the output PDF and assert `page.rotation` equals the applied angle, while page 2 remains unchanged.
- **Edge Cases:** Attempting to rotate a page index that doesn't exist in the document (e.g., rotating page 100 in a 5-page PDF) should be safely ignored or return a specific HTTP 400.

## Acceptance Criteria
- [ ] Implemented as a standalone module in `tools/rotate_pages/`.
- [ ] Registered within the FastAPI router.
- [ ] Uses PyMuPDF `set_rotation` for lossless rotation.
- [ ] API Input Payload strictly validated using Pydantic V2.
- [ ] **Unit Tests (pytest):** Must accurately rotate target pages and leave others intact.
- [ ] **Acceptance Tests (pytest):** Confirm end-to-end functionality via the API and CLI.