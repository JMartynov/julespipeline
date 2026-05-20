# Task 43: Comprehensive Acceptance Tests - delete_blank_pages

## Phase
Testing & Validation

## Description
Develop granular acceptance tests for the `delete_blank_pages` tool. The current implementation relies on `page.get_text().strip()` and `len(page.get_images())`. We must test the edge cases where this naive approach fails, establishing a TDD baseline for future improvements.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Structural Use Cases (Generated via `generator.py`)
- **Structurally Empty (`/Contents` is empty):** Generate a PDF page with zero objects. **Test:** Page is successfully deleted.
- **Whitespace Only:** Generate a page containing only space characters `(" ", "\t")`. **Test:** `get_text().strip()` catches this; page is deleted.
- **Invisible Text (Rendering Mode 3):** Generate a page with invisible OCR text. **Test:** Define expected behavior (Should it be deleted? Currently it will NOT be deleted because `get_text()` finds it).
- **White-on-White Text:** Text color matches background. **Test:** Validate if tool correctly identifies it as blank (currently it will fail to delete).
- **Transparent 1x1 Image:** Generate a page containing a single invisible pixel spacer image. **Test:** Currently `len(page.get_images()) > 0` will incorrectly preserve this blank page. Write the test to expose this.

### 2. Format & Edge Cases (Corpus / Generated)
- **Scanned Noise/Dust:** Use a corpus PDF scanned at low quality where a "blank" page contains pepper noise. **Test:** Expose the flaw that raster scans are preserved due to being a single large image, necessitating a future pixel standard-deviation check.
- **Annotations/Forms:** A page containing an empty text form field. **Test:** Verify behavior.
- **Catalog Integrity:** Delete page 3 of a 5-page document containing a TOC/Bookmarks. **Test:** Ensure bookmarks pointing to page 4 and 5 are safely shifted or preserved, and `/Count` is updated.