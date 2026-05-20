# Task 6: Implement Compress PDF Web Tests (6 Test Cases)

## Test Cases

### TC1: Compress Large PDF Successfully
- [ ] Feature: Upload large PDF (25MB)
- [ ] Assert: "Compression successful"
- [ ] Assert: Original size displayed (25 MB)
- [ ] Assert: Compressed size displayed (8 MB, 68% reduction)
- [ ] Assert: Preview quality preserved
- [ ] Fixture: `large_report.pdf` (25MB)

### TC2: Compress Already Deflated PDF
- [ ] Feature: Already optimized PDF (2MB)
- [ ] Assert: "PDF is already optimized"
- [ ] Assert: Compression < 5%
- [ ] Assert: Original PDF returned
- [ ] Fixture: `already_compressed.pdf` (2MB)

### TC3: Compress PDF with Images
- [ ] Feature: Photo-heavy PDF (30MB)
- [ ] Assert: Shows compression in progress
- [ ] Assert: 30MB → 5MB (83% reduction)
- [ ] Assert: Images resampled but viewable
- [ ] Assert: Text quality preserved
- [ ] Fixture: `photo_document.pdf` (30MB)

### TC4: Compress to Specific Size Limit
- [ ] Feature: Target size option (e.g., "Under 5MB")
- [ ] Assert: Final size meets target (4.8MB < 5MB)
- [ ] Assert: Quality warning for aggressive compression
- [ ] Assert: Preview shows result quality
- [ ] Fixture: `document.pdf` (12MB)

### TC5: Compress Encrypted PDF
- [ ] Feature: Password-protected PDF
- [ ] Assert: Error "Cannot compress encrypted PDF"
- [ ] Assert: Suggestion to remove encryption
- [ ] Assert: Download disabled
- [ ] Fixture: `encrypted.pdf`

### TC6: Compress Small PDF (No Benefit)
- [ ] Feature: Very small PDF (0.5MB)
- [ ] Assert: Shows "Compression overhead exceeds benefit"
- [ ] Assert: Result size similar to original
- [ ] Assert: Download available
- [ ] Fixture: `small_document.pdf` (0.5MB)

---

## Implementation Checklist

- [ ] Create `tests/acceptance/web/features/compress_pdf.feature`
- [ ] Create `tests/acceptance/web/steps/compress_pdf_steps.py`
- [ ] Create 6 test fixtures:
  - [ ] `large_report.pdf` (25MB, with charts/images)
  - [ ] `already_compressed.pdf` (2MB, optimized)
  - [ ] `photo_document.pdf` (30MB, many images)
  - [ ] `document.pdf` (12MB, mixed content)
  - [ ] `encrypted.pdf` (password-protected)
  - [ ] `small_document.pdf` (0.5MB, single page)

- [ ] Implement step definitions:
  - [ ] Size reduction calculation and assertion
  - [ ] Percentage display verification
  - [ ] Compression ratio display
  - [ ] Target size handling
  - [ ] Error message verification

- [ ] Add image quality verification steps
- [ ] Run tests: `pytest tests/acceptance/web/features/compress_pdf.feature -v`
- [ ] Verify 6/6 passing
- [ ] Check timeout handling (larger files take longer)

---

## Acceptance Criteria

✅ 6/6 tests passing
✅ Size reduction calculations correct
✅ All compression scenarios covered
✅ Error handling (encrypted PDFs)
✅ No flaky tests
✅ Execution time ~4 minutes (includes large file processing)

---

## Time Estimate
**3 days** (includes large file handling)

---

## Dependencies
- Task 1 (Architecture)

---

## Notes
- Use real large PDFs or generate them with fixture generator
- Compression ratios may vary slightly - use tolerance in assertions
- Execution time will be longer due to large file processing
