# Task 4: Implement PDF to Markdown Web Tests (6 Test Cases)

## Test Cases

### TC1: Convert Structured Document
- [ ] Feature file scenario with steps for structured PDF
- [ ] Step definitions for heading hierarchy validation
- [ ] Fixture `report_with_structure.pdf` with H1/H2 headings
- [ ] Assertion: Preview shows "# Main Title", "## Subsection"
- [ ] Copy to clipboard verification

### TC2: Convert Document with Lists
- [ ] Feature: Lists converted to "- " bullets and "1. " numbers
- [ ] Step: Verify nested list indentation
- [ ] Fixture: `document_with_lists.pdf`
- [ ] Assertion: Markdown table format for lists

### TC3: Convert with Code/Tables
- [ ] Feature: Code blocks wrapped in triple backticks
- [ ] Feature: Tables converted to Markdown pipe format
- [ ] Step: Code indentation preserved
- [ ] Fixture: `technical_guide.pdf`
- [ ] Assertion: Valid Markdown code blocks and tables

### TC4: Convert Scanned PDF (OCR)
- [ ] Feature: "OCR in progress" message during processing
- [ ] Step: Wait up to 30 seconds (longer timeout)
- [ ] Step: OCR confidence warning if low
- [ ] Fixture: `scanned_document.pdf` (image-based)
- [ ] Assertion: Text extracted as Markdown

### TC5: Convert Empty/Text-Only PDF
- [ ] Feature: Simple text paragraphs converted
- [ ] Step: Proper line break preservation
- [ ] Fixture: `simple_text.pdf`
- [ ] Assertion: Paragraphs separated by blank lines

### TC6: Markdown Preview Rendering
- [ ] Feature: Toggle between "Markdown" and "Preview" views
- [ ] Step: Preview renders HTML correctly
- [ ] Step: Headings display with correct hierarchy
- [ ] Step: Bold/italic renders correctly
- [ ] Assertion: Live preview matches Markdown content

---

## Implementation Checklist

- [ ] Create `tests/acceptance/web/features/pdf_to_markdown.feature`
- [ ] Create `tests/acceptance/web/steps/pdf_to_markdown_steps.py`
- [ ] Create 6 test fixtures:
  - [ ] `report_with_structure.pdf` (H1, H2, paragraphs)
  - [ ] `document_with_lists.pdf` (bullets, numbered)
  - [ ] `technical_guide.pdf` (code blocks, tables)
  - [ ] `scanned_document.pdf` (image-based for OCR)
  - [ ] `simple_text.pdf` (text only)
  - [ ] Markdown reference file for preview validation

- [ ] Implement all step definitions
- [ ] Run tests: `pytest tests/acceptance/web/features/pdf_to_markdown.feature -v`
- [ ] Verify 6/6 passing
- [ ] Check for flaky tests (run 2x)
- [ ] Code review

---

## Acceptance Criteria

✅ 6/6 tests passing
✅ OCR/scanned PDF tested (longer timeout)
✅ Markdown preview rendering validated
✅ Code blocks and tables handled
✅ No flaky tests
✅ Execution time < 4 minutes (OCR takes longer)

---

## Time Estimate
**3 days** (includes OCR timeout handling)

---

## Dependencies
- Task 1 (Architecture setup)
