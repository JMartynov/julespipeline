# Task 48: Comprehensive Acceptance Tests - pdf_to_grayscale

## Phase
Testing & Validation

## Description
Develop granular acceptance tests for `pdf_to_grayscale`. This tool executes a `gs` (Ghostscript) subprocess. Tests must verify color space conversions, ICC profiles, and subprocess safety.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Color Space Use Cases (Generated via `generator.py`)
- **RGB and CMYK Images:** Generate a PDF containing vibrant RGB photos and prepress CMYK charts. **Test:** Ghostscript successfully converts all embedded XObjects to `DeviceGray`. Verify using PyMuPDF to ensure 0% saturation.
- **Vector Fill & Stroke:** Generate a PDF with colored vector rectangles (`rg`/`RG` commands) and text. **Test:** All vector elements and text must be rendered in shades of gray.
- **Already Grayscale:** Pass a document that is strictly `DeviceGray`. **Test:** Subprocess completes quickly; file is unaltered or optimized without quality loss.
- **ICC Profiles:** Embed a specific sRGB ICC profile. **Test:** The `-dOverrideICC` flag successfully forces conversion.

### 2. Format & Edge Cases (Corpus / Generated)
- **Malformed PDFs:** Pass a corrupted PDF. **Test:** Ghostscript will likely return a non-zero exit code. The tool MUST catch `subprocess.CalledProcessError`, parse `e.stderr`, and return a graceful `ToolResult(status="error")`.
- **Subprocess Security:** Pass a filename with shell injection characters (e.g., `test"; rm -rf /; ".pdf`). **Test:** Because `subprocess.run` is using a list of arguments and `shell=False`, the injection must fail, and the file should be treated literally.
- **Font Preservation:** **Test:** Verify that converting to grayscale does not rasterize the text or strip embedded subset fonts (making the PDF unsearchable).