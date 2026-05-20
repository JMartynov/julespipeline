# Task 35: PDF to Grayscale Converter

**Phase:** Phase 12 - Additional Tools

## Description
Implement the **PDF → Grayscale Converter** tool.
This tool converts PDFs to black and white (grayscale), which is heavily demanded for cheap printing.

**Best Approaches & Python Libraries:**
- **Ghostscript** is the industry standard for high-quality color space conversions because it alters the internal color spaces (DeviceCMYK, DeviceRGB) to DeviceGray without rasterizing the vector objects and text, keeping the PDF sharp and searchable.
- We will invoke Ghostscript via Python's `subprocess` module, passing arguments as a secure list.

**Example command mapping:**
```python
gs_command = [
    "gs",
    "-sDEVICE=pdfwrite",
    "-sProcessColorModel=DeviceGray",
    "-sColorConversionStrategy=Gray",
    "-dOverrideICC",
    "-dNOPAUSE",
    "-dBATCH",
    f"-sOutputFile={output_path}",
    input_path
]
```

**Best Practices & Codebase Alignment:**
- Create `tools/pdf_to_grayscale/service.py` exposing a `process` function implementing the `PDFTool` interface.
- Wrap the subprocess call using `asyncio.to_thread()` to prevent blocking the FastAPI event loop during heavy Ghostscript execution.
- Create `tools/pdf_to_grayscale/cli.py` using `typer`.
- Add corresponding routes in `apps/api/v1/routes/tools.py` (or a dedicated route).

**Test Cases:**
- **Unit Test:** Provide a PDF containing RGB/CMYK images and colored text. Verify that the output PDF is successfully created and its file size or internal structure indicates conversion.
- **Acceptance Test:** Test with a large PDF and ensure the temporary files are cleaned up correctly using the `shared.storage.temp` context managers.

## Acceptance Criteria
- [ ] Implemented as a standalone module (`service.py` & `cli.py`) in `tools/pdf_to_grayscale/`.
- [ ] Registered within the FastAPI router.
- [ ] **Unit Tests (pytest):** Must include tests for success and failure modes (e.g., malformed PDF).
- [ ] **Acceptance Tests (pytest):** Real PDF conversion verified.
- [ ] Properly handles the `subprocess` call without shell injection vulnerabilities.