# Task 45: Comprehensive Acceptance Tests - extract_tables

## Phase
Testing & Validation

## Description
Develop granular acceptance tests for the `extract_tables` tool using Camelot. Camelot relies heavily on Ghostscript, and tests must cover both `lattice` (bordered) and `stream` (whitespace-aligned) extraction modes.

## Acceptance Criteria
Using the infrastructure from Task 40 (`tests/fixtures/generator.py` and `tests/fixtures/corpus/`), write tests covering:

### 1. Structural Use Cases (Generated via `generator.py`)
- **Lattice Mode (Explicit Borders):** Generate a PDF table drawn with intersecting vector lines. **Test:** Flavor="lattice" extracts a 100% accurate CSV representation.
- **Stream Mode (Whitespace Aligned):** Generate a PDF table with no lines, aligned purely by text coordinates. **Test:** Flavor="stream" correctly infers columns based on spatial gaps.
- **Spanning Cells:** Generate tables utilizing `rowspan` and `colspan` equivalents. **Test:** Verify how Camelot merges or duplicates text in the resulting DataFrame.
- **Multi-page Tables:** Generate a single table spanning a page break. **Test:** Ensure Camelot extracts them as separate dataframes that can be logically concatenated.

### 2. Format & Edge Cases (Corpus / Generated)
- **False Positives:** Process a standard 2-column text article with no tables. **Test:** Tool must gracefully return 0 tables without crashing.
- **DocLayNet Corpus:** Process highly complex financial reports from the DocLayNet corpus. **Test:** Measure extraction completeness and assert no unhandled exceptions in the Ghostscript subprocess.
- **Encrypted/Protected PDFs:** Process a PDF with text extraction disabled. **Test:** Must fail gracefully with an access/permission error.
- **Rotated Pages:** Process a PDF where the table is rotated 90 degrees (`/Rotate 90`). **Test:** Camelot should respect the rotation matrix and extract the text accurately.