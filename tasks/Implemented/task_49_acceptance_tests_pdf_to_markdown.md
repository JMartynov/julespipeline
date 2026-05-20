# Task 49: Comprehensive Acceptance Tests - pdf_to_markdown

## Phase
Testing & Validation

## Description
Develop granular acceptance tests for `pdf_to_markdown`. The current naive implementation just dumps `page.get_text()`. We must test structural scenarios to expose the need for a smarter layout-aware parser.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Structural Use Cases (Generated via `generator.py`)
- **Hierarchical Headers:** Generate a PDF with 24pt bold Title, 18pt H1, and 12pt body text. **Test:** Current code drops formatting. Assert current behavior (raw text) to establish a baseline, driving TDD toward mapping font sizes to `#`, `##`.
- **Inline Formatting:** Generate bold and italic text. **Test:** Assert whether `**` and `*` are applied (they currently won't be).
- **Lists and Bullets:** Generate a list with bullet glyphs (`•`). **Test:** Ensure they translate cleanly to `-` or `*` in the markdown output.
- **Multi-Column Layout:** Generate an academic 2-column layout. **Test:** Expose the flaw where naive `get_text()` might read left-to-right across the gutter, mixing sentences from column A and B.

### 2. Format & Edge Cases (Corpus / Generated)
- **Image/Vector Heavy PDF:** Pass a presentation slide deck with minimal text. **Test:** Handles text blocks correctly; does not crash on images.
- **Empty or Scanned PDF:** Pass a purely scanned document (no OCR layer). **Test:** Must gracefully return "No extractable text found."
- **DocLayNet Corpus:** Process highly complex documents with tables, charts, and footnotes. **Test:** The markdown output should be generated without unhandled exceptions, even if the logical ordering is imperfect.