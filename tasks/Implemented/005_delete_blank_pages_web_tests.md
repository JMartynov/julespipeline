# Task 5: Implement Delete Blank Pages Web Tests (5 Test Cases)

## Test Cases

### TC1: Delete Single Blank Page
- [ ] Feature: Upload PDF with 3 pages (content, blank, content)
- [ ] Steps: Click "Remove Blank Pages"
- [ ] Assert: "1 blank page removed"
- [ ] Assert: Page count reduced 3 → 2
- [ ] Assert: Download button enabled
- [ ] Fixture: `document_with_blank_page.pdf`

### TC2: Delete Multiple Blank Pages
- [ ] Feature: 10-page PDF with 3 blank pages scattered
- [ ] Assert: "3 blank pages removed"
- [ ] Assert: Page count 10 → 7
- [ ] Assert: Content pages preserved in order
- [ ] Fixture: `report_with_multiple_blanks.pdf`

### TC3: No Blank Pages to Remove
- [ ] Feature: All pages have content
- [ ] Assert: "No blank pages found"
- [ ] Assert: Original PDF returned unchanged
- [ ] Assert: Download available (same as original)
- [ ] Fixture: `clean_document.pdf`

### TC4: Delete Whitespace-Only Pages
- [ ] Feature: Pages with only whitespace/faint watermarks
- [ ] Assert: Whitespace pages detected and removed
- [ ] Assert: "2 blank pages removed"
- [ ] Fixture: `document_with_whitespace_pages.pdf`

### TC5: Pages with Images/Graphics Only
- [ ] Feature: Mixed content - text pages, image-only pages, blank pages
- [ ] Assert: Image-only pages preserved
- [ ] Assert: Only truly blank pages removed
- [ ] Assert: Shows exact count removed
- [ ] Fixture: `mixed_content.pdf`

---

## Implementation Checklist

- [ ] Create `tests/acceptance/web/features/delete_blank_pages.feature`
- [ ] Create `tests/acceptance/web/steps/delete_blank_pages_steps.py`
- [ ] Create 5 test fixtures:
  - [ ] `document_with_blank_page.pdf` (3 pages)
  - [ ] `report_with_multiple_blanks.pdf` (10 pages, 3 blank)
  - [ ] `clean_document.pdf` (all content)
  - [ ] `document_with_whitespace_pages.pdf` (whitespace)
  - [ ] `mixed_content.pdf` (mixed: text, images, blank)

- [ ] Implement step definitions
- [ ] Add page count verification steps
- [ ] Add before/after comparison steps
- [ ] Run tests: `pytest tests/acceptance/web/features/delete_blank_pages.feature -v`
- [ ] Verify 5/5 passing
- [ ] Check execution time (should be ~15 sec per test)

---

## Acceptance Criteria

✅ 5/5 tests passing
✅ Page count validation working
✅ All blank page scenarios covered
✅ No flaky tests
✅ Fast execution (~1.25 min total)

---

## Time Estimate
**2 days**

---

## Dependencies
- Task 1 (Architecture)
