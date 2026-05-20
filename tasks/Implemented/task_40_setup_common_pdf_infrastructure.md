# Task 40: Setup Common PDF Test Infrastructure

## Phase
Testing & Infrastructure

## Description
Develop a dedicated test-fixture generator library to programmatically create PDFs with strict invariants, and a script to download curated edge-case files. This serves as the foundation for the rigorous acceptance testing and resilience fuzzing of all PDF tools.

## Acceptance Criteria
1. **Generator Library (`tests/fixtures/generator.py`):** 
   - Create an extensible architecture using `pikepdf`, `reportlab`, `borb`, and `weasyprint` (add dependencies to `pyproject.toml`/`uv.lock`).
   - Must programmatically generate PDFs with strict invariants (versions 1.3-2.0, Standard 14/CID fonts, varying encodings like JPX/CCITTFax, RC4/AES encryption, rotated CropBoxes).
   - **Malicious/Malformed Generators:** Include functions to generate "fuzzer-style" edge cases, such as:
     - Missing `%EOF` markers or corrupted XRef tables.
     - "PDF Bombs" with deeply nested object streams or massive compression ratios to test resource exhaustion.
     - Files with massive amounts of garbage bytes before the `%PDF-` header.

2. **Wild Corpus Downloader (`scripts/download_test_corpus.py`):**
   - Create a script to idempotently download edge-case files into `tests/fixtures/corpus/`.
   - Source from established repositories:
     - **veraPDF Corpus** (for strict ISO PDF/A and PDF/UA compliance).
     - **PDF Association Corpora** (e.g., Isartor test suite).
     - **Cabinet of Horrors / ArturT Test-PDF-Files** (specifically curated malformed and dirty PDFs for resilience testing).
     - **DocLayNet** (for complex layouts and tables).
   - Ensure these files are `.gitignore`d so they don't bloat the repository.