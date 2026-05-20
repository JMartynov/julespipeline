# Task 1: Test Architecture - Setup Playwright + Gherkin Framework

## Overview
Set up complete Gherkin/Playwright acceptance test infrastructure for web tests.

---

## Subtask 1.1: Install Dependencies
- [ ] Install `pytest-playwright`
- [ ] Install `pytest-bdd` (for Gherkin)
- [ ] Install `httpx` (for async HTTP client)
- [ ] Update `requirements-dev.txt` with new dependencies
- [ ] Verify versions compatible with Python 3.11
- [ ] Run `pip install -r requirements-dev.txt`

**Expected**: All packages installed without conflicts

---

## Subtask 1.2: Create Test Directory Structure
- [ ] Create `tests/acceptance/web/` directory
- [ ] Create `tests/acceptance/web/features/` directory
- [ ] Create `tests/acceptance/web/steps/` directory
- [ ] Create `tests/acceptance/web/conftest.py`
- [ ] Create `tests/acceptance/web/fixtures/` for test files
- [ ] Create `.gitignore` entry for web test artifacts

**Expected**: Directory structure matches architecture blueprint

---

## Subtask 1.3: Configure Playwright
- [ ] Initialize Playwright config (`playwright.ini` or `pytest.ini` section)
- [ ] Configure browser options:
  - [ ] Chromium (default)
  - [ ] Firefox (optional)
  - [ ] WebKit (optional)
- [ ] Set headless mode (default True)
- [ ] Set viewport size (1280x720)
- [ ] Set timeout (30 seconds)
- [ ] Enable trace capture on failure
- [ ] Configure screenshot on failure

**Expected**: Playwright runs with proper browser setup

---

## Subtask 1.4: Create conftest.py
Create `tests/acceptance/web/conftest.py` with:

- [ ] `@pytest.fixture(scope="session")` for FastAPI server startup
  - Start server on `http://localhost:8000`
  - Use TestClient or uvicorn subprocess
  - Cleanup on session end
  
- [ ] `@pytest.fixture` for Playwright browser
  - Launch browser context
  - Create new page for each test
  - Cleanup after test
  
- [ ] `@pytest.fixture` for `page` object
  - Provide Playwright page to tests
  - Auto-navigate to base URL
  
- [ ] `@pytest.fixture` for `server_url`
  - Return base URL string
  
- [ ] `@pytest.fixture` for temp file cleanup
  - Track downloaded/generated files
  - Clean up after test

**Expected**: All fixtures functional, server starts/stops correctly

---

## Subtask 1.5: Create Common Step Definitions (steps/common_steps.py)

**Navigation Steps**:
- [ ] Implement: `Given I navigate to "{url}"`
- [ ] Implement: `When I go to "{url}"`
- [ ] Verify page loads with timeout

**Upload Steps**:
- [ ] Implement: `When I upload "{filename}"`
  - Find file in `tests/acceptance/web/fixtures/`
  - Trigger file input
  - Wait for upload completion
  
**Element Interaction**:
- [ ] Implement: `When I click "{text_or_selector}"`
- [ ] Implement: `When I fill "{field}" with "{value}"`
- [ ] Implement: `When I select "{option}" from "{dropdown}"`

**Assertion Steps**:
- [ ] Implement: `Then I see "{text}"`
  - Wait for element (max 10s)
  - Assert text is visible
  
- [ ] Implement: `Then I don't see "{text}"`
  - Verify text is not present
  
- [ ] Implement: `Then I see element with id "{id}"`

**Download Steps**:
- [ ] Implement: `When I click download button`
- [ ] Implement: `Then I can download the result as "{format}"`
  - Wait for download
  - Verify file exists
  - Return file path

**Wait Steps**:
- [ ] Implement: `And I wait for "{text}" to appear`
  - Wait up to 30s
  - Handle timeout
  
- [ ] Implement: `And I wait {seconds} seconds`

**Expected**: All steps work, properly handle waits and errors

---

## Subtask 1.6: Create pytest.ini Configuration
Update or create `pytest.ini`:

```ini
[pytest]
minversion = 7.0
addopts = 
    -v
    --tb=short
    --strict-markers
    --disable-warnings
testpaths = tests/acceptance/web
python_files = conftest.py
python_classes = Test*
python_functions = test_*
markers =
    web: web acceptance tests
    smoke: smoke tests
    slow: slow tests
```

- [ ] Set proper test discovery patterns
- [ ] Configure logging (verbose output)
- [ ] Add markers for test organization
- [ ] Set screenshot on failure
- [ ] Configure parallel execution (if needed)

**Expected**: Pytest correctly discovers and runs tests

---

## Subtask 1.7: Create Smoke Test Feature Files

**File**: `tests/acceptance/web/features/smoke_tests.feature`

- [ ] Create `smoke_tests.feature` with:
  - [ ] Feature: "Smoke Tests"
  - [ ] Scenario 1: "Homepage loads and shows all 5 tools"
    - Given I navigate to "/"
    - Then I see "Extract Tables"
    - And I see "Extract Images"
    - And I see "PDF to Markdown"
    - And I see "Delete Blank Pages"
    - And I see "Compress PDF"
  
  - [ ] Scenario 2: "User can upload PDF to tool"
    - Given I navigate to "/tools/extract-tables"
    - When I upload "sample.pdf"
    - Then I see upload success indicator

**Expected**: Feature file is valid Gherkin syntax

---

## Subtask 1.8: Create Smoke Test Steps

**File**: `tests/acceptance/web/steps/smoke_steps.py`

- [ ] Implement step definitions for smoke tests
- [ ] Handle both success and error scenarios
- [ ] Add proper assertions
- [ ] Use common steps where applicable

**Expected**: Smoke tests pass and provide good test output

---

## Subtask 1.9: Create Test Sample Files

In `tests/acceptance/web/fixtures/`:

- [ ] Create/add `sample.pdf` (small, simple PDF)
- [ ] Create/add `table_lattice.pdf` (PDF with bordered table)
- [ ] Create/add `table_stream.pdf` (PDF with whitespace tables)
- [ ] Verify all files are in .gitignore (or use fixtures generator)

**Expected**: All fixture files present and accessible

---

## Subtask 1.10: Test Local Execution

- [ ] Run: `pytest tests/acceptance/web/features/smoke_tests.feature -v`
- [ ] Verify both smoke tests pass
- [ ] Check browser launches and closes correctly
- [ ] Verify screenshots captured on failure
- [ ] Verify server starts/stops properly
- [ ] Check all dependencies load without errors
- [ ] Test with `--headed` flag (see browser)
- [ ] Test with `--browser firefox` (different browser)

**Expected**: 
- 2 smoke tests pass consistently
- Browser automation works
- Server lifecycle handled correctly
- No dependency errors

---

## Acceptance Criteria

✅ All 10 subtasks completed
✅ 2 smoke tests passing consistently
✅ Headless and headed modes work
✅ Multiple browsers supported (at least Chromium)
✅ Proper error handling and timeouts
✅ Clean code with reusable step definitions
✅ Documentation in README or comments

---

## Time Estimate
**4-5 days** (including debugging and iteration)

---

## Blockers/Dependencies
- None (foundational task)

---

## Related Tasks
- Task 2-6: Depend on this architecture
- Task 8 onwards: May reuse same infrastructure
