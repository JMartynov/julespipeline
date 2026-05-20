# Task 50: Comprehensive Acceptance Tests - remove_duplicate_pages

## Phase
Testing & Validation

## Description
Develop granular acceptance tests for `remove_duplicate_pages`. This tool uses PyMuPDF pixmaps at a low DPI (36) to hash pages and detect visual duplicates, bypassing XRef ID discrepancies.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Duplication Use Cases (Generated via `generator.py`)
- **Identical Object References:** A PDF where pages 1 and 2 point to the exact same dictionary object. **Test:** Page 2 is removed; `removed_pages_count == 1`.
- **Distinct Objects, Identical Visuals:** Pages 1 and 2 are different objects with identical byte content streams. **Test:** Hashing catches them; Page 2 is removed.
- **Different Metadata, Identical Visuals:** Page 1 has a modification timestamp in its dictionary, Page 2 has a different timestamp, but visually they are the same text. **Test:** Pixmap hashing ignores metadata; Page 2 is removed.
- **Slight Visual Variations:** Page 1 has page number "1" at the bottom, Page 2 has "2". **Test:** Even at 36 DPI, the hash of the pixmap *should* differ. The test must verify if the resolution is low enough to cause a false positive (deleting a non-duplicate) or high enough to preserve them.

### 2. Format & Edge Cases (Corpus / Generated)
- **Completely Blank Pages:** A PDF with three blank pages. **Test:** Blank pages will all yield the same hash. Only the first blank page remains; the others are deleted.
- **Watermarks:** Identical pages where one has a faint "DRAFT" watermark. **Test:** The hash must differ; neither page should be removed.
- **Lossy Image Artifacts:** Two pages contain the same JPEG, but one was compressed slightly differently resulting in subtle macroblocking. **Test:** MD5 hashing is exact. Test will verify if strict hashing preserves both pages (expected behavior) due to pixel variations.