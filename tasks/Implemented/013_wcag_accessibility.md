# Task 13: WCAG Accessibility (AA Standard)

## Subtasks

### 13.1: Keyboard Navigation
- [ ] Tab order is logical
- [ ] Focus indicators visible (outline/ring)
- [ ] No keyboard traps
- [ ] Skip to main content link
- [ ] All buttons clickable with Enter/Space
- [ ] Modals closable with Escape

### 13.2: Screen Reader Support
- [ ] Proper heading hierarchy (h1, h2, h3)
- [ ] ARIA labels for buttons without text
- [ ] Form labels `<label for="">` associated with inputs
- [ ] Status messages announced (aria-live)
- [ ] Form errors announced
- [ ] Image alt text (descriptive, not "image")

### 13.3: Color Contrast
- [ ] All text min 4.5:1 (normal) or 3:1 (large 18+px)
- [ ] Use axe DevTools to verify
- [ ] Test both light and dark modes
- [ ] No color-only information (use icons + text)

### 13.4: Animations
- [ ] Respect `prefers-reduced-motion` media query
- [ ] No auto-playing videos
- [ ] No flashing/blinking elements (> 3Hz)
- [ ] Pause buttons for animations
- [ ] No parallax scrolling (can cause motion sickness)

### 13.5: Alternative Text
- [ ] All icons have aria-label or title
- [ ] All images have alt text
- [ ] Alt text descriptive (not "image1")
- [ ] Decorative images: alt=""
- [ ] Charts/graphs: descriptive alt or data table

### 13.6: Form Accessibility
- [ ] All inputs have associated labels
- [ ] Required fields marked (asterisk + aria-required)
- [ ] Error messages associated with input (aria-describedby)
- [ ] Inline error messages
- [ ] Success messages announced

### 13.7: Focus Management
- [ ] Focus visible after modal opens
- [ ] Focus returned when modal closes
- [ ] Focus managed on page navigation
- [ ] Focus trap in modals (optional, for accessibility)

### 13.8: Text & Language
- [ ] Text is clear and simple (avoid jargon)
- [ ] Abbreviations have title/aria-label
- [ ] Text can be resized (up to 200%)
- [ ] No time limits (or extendable)
- [ ] Page language: `<html lang="en">`

### 13.9: Testing
- [ ] axe DevTools scan (0 violations)
- [ ] WAVE scan (contrast, etc.)
- [ ] Lighthouse accessibility audit (90+)
- [ ] Manual keyboard testing
- [ ] Screen reader testing (NVDA/MacOS VO)

### 13.10: Documentation
- [ ] Accessibility statement on website
- [ ] Document WCAG 2.1 AA compliance
- [ ] Provide contact for accessibility issues
- [ ] Commit to continuous improvement

---

## Deliverables
- Updated HTML with ARIA attributes
- CSS for focus indicators
- Accessibility statement (page)
- Testing reports (axe, WAVE, Lighthouse)

---

## Acceptance Criteria
✅ axe DevTools: 0 violations
✅ Lighthouse accessibility: 90+
✅ WAVE: 0 errors
✅ Keyboard navigation works
✅ Screen reader compatible
✅ Color contrast OK (both modes)

---

## Time Estimate
**3 days** (includes testing)

---

## Dependencies
- Task 8-12 (all pages)
