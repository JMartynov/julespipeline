# Task 3: Implement Extract Images Web Tests (6 Test Cases)

## Overview
Implement Gherkin/Playwright tests for Extract Images tool - single images, multiple images, vector graphics, CMYK color space.

---

## Test Cases (6 total)

### TC1: Extract Single Image Success
- [ ] Subtask 3.1: Create feature file scenario
  - Upload "document_with_image.pdf"
  - Click "Extract Images"
  - See "1 image extracted"
  - Preview displays image
  - Download button enabled
  - Format shows dimensions/size

- [ ] Subtask 3.2: Implement step definitions
  - Upload handler
  - Processing wait
  - Image preview assertion
  - Download availability check

- [ ] Subtask 3.3: Create fixture `document_with_image.pdf`
  - Single high-quality image (500x400px)
  - Expected: Clean extraction

### TC2: Extract Multiple Images
- [ ] Subtask 3.4: Create scenario
  - Upload "report_with_charts.pdf" (3+ images)
  - See "3 images extracted"
  - Gallery preview with thumbnails
  - Download as ZIP

- [ ] Subtask 3.5: Implement steps
  - Multiple image count assertion
  - Thumbnail gallery verification
  - ZIP file handling

- [ ] Subtask 3.6: Create fixture `report_with_charts.pdf`
  - Contains 3+ chart images
  - Mixed sizes and formats

### TC3: Extract Vector Graphics
- [ ] Subtask 3.7: Create scenario
  - Upload "diagram.pdf" (SVG content)
  - See "vector graphic extracted"
  - Rasterized as PNG
  - Preview shows diagram clearly

- [ ] Subtask 3.8: Implement vector graphics handling
  - Vector detection
  - Rasterization assertion
  - Quality verification

- [ ] Subtask 3.9: Create fixture `diagram.pdf`
  - Vector-based diagram/drawing
  - Expected: Clean rasterization

### TC4: No Images Found
- [ ] Subtask 3.10: Create scenario
  - Upload "text_only.pdf"
  - See "No images found"
  - Download disabled

- [ ] Subtask 3.11: Implement empty result handling
  - "No images" message assertion
  - Download button disabled check

- [ ] Subtask 3.12: Create fixture `text_only.pdf`
  - Text-only document

### TC5: CMYK Color Space Conversion
- [ ] Subtask 3.13: Create scenario
  - Upload "print_document.pdf" (CMYK images)
  - See "2 images extracted"
  - Converted to RGB for web
  - Colors display correctly

- [ ] Subtask 3.14: Implement color space handling
  - CMYK detection
  - RGB conversion assertion
  - Color accuracy check

- [ ] Subtask 3.15: Create fixture `print_document.pdf`
  - CMYK-encoded images
  - Print-ready content

### TC6: Download & Verify
- [ ] Subtask 3.16: Create scenario
  - Upload "photo_document.pdf"
  - Extract images
  - Download as ZIP
  - Extract ZIP and verify contents
  - Images are viewable and valid

- [ ] Subtask 3.17: Implement download verification
  - ZIP download handling
  - File extraction
  - Image validity check (format, size)
  - No corruption verification

- [ ] Subtask 3.18: Create fixture `photo_document.pdf`
  - Photo-quality images
  - Multiple formats

---

## Implementation Steps

- [ ] Subtask 3.19: Create feature file `tests/acceptance/web/features/extract_images.feature`

- [ ] Subtask 3.20: Create step definitions `tests/acceptance/web/steps/extract_images_steps.py`

- [ ] Subtask 3.21: Create all 6 fixtures in `tests/acceptance/web/fixtures/`

- [ ] Subtask 3.22: Run all tests
  - Command: `pytest tests/acceptance/web/features/extract_images.feature -v`
  - Expected: 6/6 passing

- [ ] Subtask 3.23: Verify no flaky tests
  - Run twice, expect consistent results

- [ ] Subtask 3.24: Code review and documentation

---

## Acceptance Criteria

✅ 6/6 tests passing
✅ All image extraction scenarios covered
✅ ZIP download tested
✅ Color space conversion tested
✅ No flaky tests
✅ Execution time < 2.5 minutes

---

## Time Estimate
**2-3 days**

---

## Blockers/Dependencies
- Depends on: Task 1 (Architecture)
