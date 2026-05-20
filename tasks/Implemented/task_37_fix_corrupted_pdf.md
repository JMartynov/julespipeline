# Task 37: Fix Corrupted PDF

**Phase:** Phase 12 - Additional Tools

## Description
Implement the **Fix Corrupted PDF** tool.
This tool attempts to recover broken cross-reference (xref) tables, missing EOF markers, and corrupted streams from damaged PDF files.

**Best Approaches & Python Libraries:**
- **Option 1: qpdf (via `pikepdf` or `subprocess`)**
  `qpdf` is excellent at reconstructing xref tables. `pikepdf` is the Python wrapper. Opening and saving a PDF in `pikepdf` automatically repairs many structural errors.
- **Option 2: mutool / PyMuPDF**
  `mutool clean` (the underlying engine of PyMuPDF) is the industry standard for brute-force PDF repair.
  Using PyMuPDF:
  ```python
  import fitz # PyMuPDF
  doc = fitz.open(input_path)
  # Converting to a new PDF structure fixes xrefs and strips garbage
  fixed_bytes = doc.convert_to_pdf()
  ```

**Best Practices & Codebase Alignment:**
- Create `tools/fix_corrupted_pdf/service.py` and `cli.py`.
- Prefer the `PyMuPDF` (`fitz.open(…).convert_to_pdf()`) approach first as PyMuPDF is already heavily utilized in the stack. If it throws an error, fallback to `subprocess.run(["qpdf", "--empty", "--qdf", input_path, output_path])` or `mutool clean`.
- Ensure output maintains the standard `ToolResult` interface.

**Test Cases:**
- **Unit Test:** Provide a deliberately malformed PDF (e.g., open a valid PDF in a text editor, delete the `%%EOF` marker and mess up the `xref` byte offsets). Ensure the tool successfully outputs a readable PDF.
- **Edge Case:** Completely non-PDF files (e.g., a `.txt` file renamed to `.pdf`) must raise a clean Validation error, not crash the server.

## Acceptance Criteria
- [ ] Implemented as a standalone module in `tools/fix_corrupted_pdf/`.
- [ ] Registered within the FastAPI router.
- [ ] Logic clearly attempts to rebuild the PDF structure.
- [ ] **Unit Tests (pytest):** Verification with a broken/corrupted PDF.
- [ ] **Acceptance Tests (pytest):** Ensure output opens seamlessly in a standard PDF viewer.