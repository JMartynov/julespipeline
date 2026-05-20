# Task: Implement LLM-Powered UI Analysis Fixture & Reporter

## Status
- **Priority:** High
- **Owner:** AI Agent
- **Category:** Testing / DX (Developer Experience)

## Description
Develop a specialized Playwright fixture/plugin that acts as a "Visual Auditor" during web acceptance tests. The tool will capture screenshots at every significant test step, metadata about the application state, and use an LLM (Vision-enabled) to analyze the UI for regressions, misalignments, and UX flaws. The final output is a rich HTML report containing screenshots, metadata, and actionable code-level recommendations.

## Acceptance Criteria
1.  **Playwright Fixture:** A reusable fixture that can be injected into any web test.
2.  **Configuration:** Support a `.yaml` configuration file to customize the model, prompt, report directory, and toggle the feature.
3.  **Lossless Compression:** Screenshots must be captured in a highly compressed but lossless format (e.g., optimized PNG or Lossless WebP).
4.  **Metadata Capture:** For each screenshot, capture:
    - Current URL
    - Scenario Description (from the test docstring/name)
    - Current Action (the step just performed)
    - **Action Duration:** Execution time in milliseconds (to help LLM evaluate perceived speed).
    - Console Logs (errors/warnings)
    - Browser Viewport details
5.  **Vision Prompt Engineering:** A robust system prompt for the LLM that focuses on:
    - **Visual Alignment & Spacing:** Are elements balanced? Any overlapping text? Is the grid consistent?
    - **Component Integrity:** Are elements clipped by viewports or overlapping due to z-index issues?
    - **Logical Consistency:** Does the UI state match the test action (e.g., a "Processing" state should show a spinner or skeleton loader)?
    - **Visual Hierarchy:** Is the primary Call-to-Action (CTA) prominent? Is the information architecture clear?
    - **AI Transparency:** Are confidence scores, "AI-generated" badges, or verification cues present where applicable?
    - **Trust & Security Cues:** Visibility of encryption badges, data retention warnings, and secure connection indicators.
    - **Error Recovery UX:** Are error messages actionable, clear, and visually prioritized?
    - **Progressive Disclosure:** Are complex settings hidden behind "Advanced" toggles to prevent cognitive overload?
    - **Interaction Responsiveness:** Did the UI provide immediate visual feedback (e.g., button loading states, optimistic UI, skeleton screens) proportional to the `Action Duration`?
    - **Responsive Adaptation:** Touch target sizes (min 44x44px), mobile-first layout shifts, and readable typography at all scales.
    - **Accessibility (Visual):** Sufficient contrast ratios, clear focus indicators, and distinct state changes (e.g., disabled vs. active).
6.  **Actionable Recommendations:** The LLM must suggest specific code changes, referencing the project's file structure (e.g., `apps/web/templates/tool.html`, `static/css/design-system.css`).
7.  **HTML Report:** An interactive HTML file that aggregates all findings, showing side-by-side screenshots and analysis.
8.  **Analyzer Acceptance Tests:** The UI Analyzer fixture must itself be verified via acceptance tests. These tests must feed intentionally flawed UI fixtures (e.g., overlapping elements, missing loading states) to the analyzer and assert that the LLM successfully detects and reports the expected issues.

## Technical Details

### Workflow
1.  **Test Execution:** Run existing `tests/e2e/` scenarios.
2.  **Hook:** The fixture triggers `page.screenshot()` after each `await` action.
3.  **Processing:** Use `Pillow` or similar to optimize the image.
4.  **LLM Inference:** Send the image + metadata to the LLM.
5.  **Aggregation:** Store results in a JSON manifest.
6.  **Reporting:** Generate `temp/ui_audit_[timestamp].html`.

### Proposed Vision Prompt Template
```text
Context: You are a Senior UI/UX Auditor for a PDF Tools SaaS platform.
Project Structure: [Include File Tree]
Current Page: {{url}}
Test Action: {{action}}
Action Duration: {{duration}}ms
Scenario: {{scenario}}

Analyze the attached screenshot using the following Audit Categories:
1. Alignment: Check for spacing inconsistencies or overlapping elements.
2. Integrity: Look for components cut off by the viewport or hidden by other layers.
3. Responsiveness: Given the action took {{duration}}ms, did the UI provide appropriate feedback? (e.g., for long durations, is there a progress bar? for short ones, was there a 'pop' or state change?).
4. State: Does the UI logically reflect the action '{{action}}'? (e.g., loading states, success messages).
4. AI/Trust: Are there clear cues for data security and AI confidence?
5. Hierarchy: Is the "Primary Action" for this step clearly the most prominent?
6. Accessibility: Identify potential contrast or visibility issues.

Format recommendations as:
- Issue: [Description]
- Category: [Alignment/State/Trust/etc.]
- Severity: [Low/Med/High]
- Fix Suggestion: [Specific HTML/CSS change]
- Targeted Files: [e.g., apps/web/templates/base.html]
```

## Implementation Steps
1.  [x] Create `tests/support/ui_analyzer.py` containing the fixture logic.
2.  [x] Implement lossless image optimization utility.
3.  [x] Set up LLM client integration (Gemini/OpenAI Vision).
4.  [x] Design the HTML report template (using Jinja2 for consistency with the app).
5.  [x] Add a CLI flag to `pytest` (e.g., `--analyze-ui`) to toggle this feature.
6.  [x] Run a sample test (e.g., `test_rotate_pages_web.py`) and verify the report generation.
7.  [x] Create acceptance tests for the analyzer (`tests/acceptance/test_ui_analyzer.py`) using intentionally broken UI states to verify the LLM's detection capabilities.

