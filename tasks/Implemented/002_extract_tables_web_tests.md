# Task 2: Implement Extract Tables Web Tests (8 Test Cases)

## Overview
Implement comprehensive Gherkin/Playwright tests for Extract Tables tool with all success/error paths.

---

## Subtask 2.1: Create Feature File Structure

**File**: `tests/acceptance/web/features/extract_tables.feature`

- [ ] Create feature file with header:
  ```gherkin
  Feature: Extract Tables from PDF
    As a user
    I want to extract tables from PDF files
    So that I can work with table data in CSV format
  ```

- [ ] Add background section (common setup):
  ```gherkin
  Background:
    Given I navigate to "/tools/extract-tables"
    And the tool page loads successfully
  ```

- [ ] Create 8 scenario skeletons (empty, to fill in next subtasks)

**Expected**: Valid Gherkin file structure

---

## Subtask 2.2: Implement Test Case 1 - Lattice Mode Success

**Gherkin Scenario**:
```gherkin
Scenario: Extract tables using lattice mode from text PDF
  When I upload "table_lattice.pdf"
  And I select flavor "Lattice"
  And I click "Extract Tables" button
  Then I wait for processing to complete (max 10 seconds)
  And I see "1 table extracted"
  And I see table preview with data
  And I can download result as "csv"
```

**Steps to Implement**:
- [ ] Add upload step handler
- [ ] Add flavor selection step
- [ ] Add click button step
- [ ] Add processing wait with timeout
- [ ] Add result assertion steps
- [ ] Add download verification step

**Test Data**:
- [ ] Create/use `table_lattice.pdf` fixture
  - Contains: Single bordered table (2x3)
  - Expected result: 1 CSV file

**Expected**: Test passes, CSV preview shows table data

---

## Subtask 2.3: Implement Test Case 2 - Stream Mode Success

**Gherkin Scenario**:
```gherkin
Scenario: Extract tables using stream mode from text PDF
  When I upload "table_stream.pdf"
  And I select flavor "Stream"
  And I click "Extract Tables" button
  Then I wait for processing to complete
  And I see "1 table extracted"
  And table preview shows correct columns
  And I can download result as "csv"
```

**Steps to Implement**:
- [ ] Stream mode flavor selection
- [ ] Table column validation assertion
- [ ] All other steps reuse from TC1

**Test Data**:
- [ ] Create/use `table_stream.pdf` fixture
  - Contains: Table aligned by whitespace
  - Expected: Column data correctly parsed

**Expected**: Stream mode extracts table correctly

---

## Subtask 2.4: Implement Test Case 3 - No Tables Found

**Gherkin Scenario**:
```gherkin
Scenario: Handle PDF with no tables gracefully
  When I upload "simple_text.pdf"
  And I select flavor "Lattice"
  And I click "Extract Tables" button
  Then I wait for processing to complete
  And I see "No tables found"
  And the download button is disabled
  And I can click "Try another file"
```

**Steps to Implement**:
- [ ] No tables found message assertion
- [ ] Download button disabled check
- [ ] Retry button validation

**Test Data**:
- [ ] Create/use `simple_text.pdf` fixture
  - Contains: Only text paragraphs, no tables
  - Expected: Graceful "no tables" message

**Expected**: Handles edge case gracefully

---

## Subtask 2.5: Implement Test Case 4 - Image-Based PDF (Scanned)

**Gherkin Scenario**:
```gherkin
Scenario: Detect and handle scanned PDF appropriately
  When I upload "scanned_document.pdf"
  And I select flavor "Lattice"
  And I click "Extract Tables" button
  Then I wait for processing to complete
  And I see message about "scanned images"
  And I see suggestion "use Extract Tables (Scanned)"
  And the download button is disabled
```

**Steps to Implement**:
- [ ] Scanned PDF detection message assertion
- [ ] Suggestion link verification
- [ ] Link navigates to scanned tool (bonus)

**Test Data**:
- [ ] Create/use `scanned_document.pdf` fixture
  - Contains: Image-based scanned pages
  - Expected: Detection + suggestion message

**Expected**: Proper detection and guidance for scanned PDFs

---

## Subtask 2.6: Implement Test Case 5 - Large PDF (Multiple Tables)

**Gherkin Scenario**:
```gherkin
Scenario: Extract multiple tables from large PDF
  When I upload "large_report.pdf" (file size shown)
  And I select flavor "Lattice"
  And I click "Extract Tables" button
  Then I wait for processing to complete (max 20 seconds)
  And I see "5 tables extracted"
  And I can see each table in preview
  And I can download all tables as zip or multi-file
```

**Steps to Implement**:
- [ ] Large file handling (longer timeout)
- [ ] Multiple table count assertion
- [ ] Table preview pagination/tabs
- [ ] Zip download handling

**Test Data**:
- [ ] Create/use `large_report.pdf` fixture
  - Contains: 5+ bordered tables
  - File size: 5-10MB
  - Expected: All tables extracted

**Expected**: Handles large PDFs with multiple tables

---

## Subtask 2.7: Implement Test Case 6 - Invalid File Upload

**Gherkin Scenario**:
```gherkin
Scenario: Reject non-PDF file uploads
  When I attempt to upload "document.docx"
  Then I see error "Only PDF files are supported"
  And the upload input is cleared
  And the Extract Tables button is disabled
  And I can retry upload
```

**Steps to Implement**:
- [ ] File type validation error assertion
- [ ] Input clearing verification
- [ ] Button disabled state check
- [ ] Retry capability verification

**Test Data**:
- [ ] Create/use `document.docx` fixture
- [ ] Add `.doc`, `.txt` files for validation

**Expected**: Proper validation prevents invalid uploads

---

## Subtask 2.8: Implement Test Case 7 - Encrypted PDF

**Gherkin Scenario**:
```gherkin
Scenario: Handle encrypted PDF with error message
  When I upload "encrypted.pdf"
  And I click "Extract Tables" button
  Then I wait for processing to complete
  And I see error "PDF is encrypted"
  And I see message "Remove password protection"
  And the download button is disabled
```

**Steps to Implement**:
- [ ] Encrypted PDF error assertion
- [ ] Helpful error message verification
- [ ] Download button disabled check

**Test Data**:
- [ ] Create/use `encrypted.pdf` fixture
  - Password-protected PDF
  - Expected: Clear error message

**Expected**: Proper error handling for encrypted PDFs

---

## Subtask 2.9: Implement Test Case 8 - UI Responsiveness

**Gherkin Scenario**:
```gherkin
Scenario: UI remains responsive during extraction
  When I upload "table_lattice.pdf"
  And I click "Extract Tables" button
  And processing starts (at 2 seconds)
  Then I can click "Cancel" button
  Or I can click back/home navigation
  And the page responds (no frozen UI)
  And processing stops cleanly
```

**Steps to Implement**:
- [ ] Cancel button functionality
- [ ] Back button navigation
- [ ] Processing cleanup verification
- [ ] No page freeze detection

**Test Data**:
- [ ] Use `table_lattice.pdf` fixture

**Expected**: UI remains responsive, cancellation works

---

## Subtask 2.10: Create Step Definitions File

**File**: `tests/acceptance/web/steps/extract_tables_steps.py`

Implement all step definitions needed for all 8 test cases:

- [ ] Upload file to extract tables tool
- [ ] Select flavor (Lattice, Stream)
- [ ] Click "Extract Tables" button
- [ ] Wait for processing (with timeout)
- [ ] Verify extraction result count
- [ ] Verify table preview
- [ ] Verify download button state
- [ ] Verify error messages
- [ ] Cancel extraction
- [ ] Handle responsive UI checks

**Expected**: All steps implemented and working

---

## Subtask 2.11: Create Test Fixtures

Create test PDFs in `tests/acceptance/web/fixtures/`:

- [ ] `table_lattice.pdf` - Bordered table (2x3)
- [ ] `table_stream.pdf` - Whitespace-aligned table
- [ ] `simple_text.pdf` - Text only, no tables
- [ ] `scanned_document.pdf` - Image-based scanned PDF
- [ ] `large_report.pdf` - Multiple tables (5+), 5-10MB
- [ ] `document.docx` - Non-PDF for validation
- [ ] `encrypted.pdf` - Password-protected

All fixtures should be:
- [ ] Small enough for fast tests (< 100KB each, except large_report)
- [ ] Representative of real-world scenarios
- [ ] Deterministic (same content, consistent results)

**Expected**: All fixtures present and usable

---

## Subtask 2.12: Run All Tests

- [ ] Run: `pytest tests/acceptance/web/features/extract_tables.feature -v`
- [ ] Verify all 8 tests pass
- [ ] Check test execution time (should be ~30 seconds total)
- [ ] Verify no flaky tests (run 2x, expect same results)
- [ ] Check error handling (verify failures are caught)
- [ ] Review test output for clarity

**Expected**: 
- 8/8 tests passing
- Clear, descriptive test output
- No flaky tests
- Reasonable execution time

---

## Subtask 2.13: Documentation & Comments

- [ ] Add docstrings to step functions
- [ ] Comment complex step logic
- [ ] Document test data requirements
- [ ] Add README note about Extract Tables test coverage

**Expected**: Code is self-documenting

---

## Acceptance Criteria

✅ All 8 test cases passing consistently
✅ All happy paths and error cases covered
✅ Test execution ~30 seconds total
✅ No flaky tests (reliable)
✅ Clear, descriptive step names
✅ All test fixtures present
✅ Proper error handling
✅ Code reviewed for quality

---

## Time Estimate
**3-4 days**

---

## Blockers/Dependencies
- Depends on: Task 1 (Architecture setup)

---

## Related Tasks
- Task 3-6: Similar test implementation tasks
