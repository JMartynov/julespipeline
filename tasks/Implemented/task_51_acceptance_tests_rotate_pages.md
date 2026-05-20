# Task 51: Comprehensive Acceptance Tests - rotate_pages

## Phase
Testing & Validation

## Description
Develop granular acceptance tests for `rotate_pages`. This tool uses Pydantic to validate a `rotation_map` and PyMuPDF's `set_rotation()` for execution.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Payload & Validation Use Cases
- **Valid Rotations:** Supply `{0: 90, 1: 180, 2: 270, 3: -90}`. **Test:** Pages are rotated correctly.
- **Invalid Angles:** Supply an angle of `45` or `100`. **Test:** Pydantic `@field_validator` immediately throws a `ValueError` caught by the service, returning a graceful `ToolResult` error.
- **Out of Bounds Index:** Supply `{99: 90}` for a 5-page document. **Test:** Tool safely ignores the out-of-bounds index without crashing.

### 2. Geometry & Edge Cases (Generated via `generator.py`)
- **Cumulative vs. Absolute:** Generate a page that already has `/Rotate 90` in its PDF dictionary. Apply a rotation of `90` via the payload. **Test:** Verify if PyMuPDF's `set_rotation(90)` makes the absolute rotation 90 (no visual change) or relative 180. The test establishes the invariant.
- **Non-Standard MediaBoxes:** Generate a landscape page with a MediaBox of `[0, 0, 792, 612]`. Rotate it by 90. **Test:** The content must not be clipped, and the output must logically display as portrait.
- **Annotations/Form Fields:** Rotate a page containing an interactive text box. **Test:** Verify that the coordinates of the annotation matrix are correctly rotated alongside the page content, allowing text to still be clicked and entered.