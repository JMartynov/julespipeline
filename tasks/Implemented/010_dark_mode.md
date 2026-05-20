# Task 10: Dark Mode Support

## Subtasks

### 10.1: Create Dark Mode CSS Variables
- [ ] Light mode variables
- [ ] Dark mode variables
- [ ] Semantic variable names (bg-primary, text-primary, etc.)
- [ ] File: `apps/web/static/css/variables-light.css`
- [ ] File: `apps/web/static/css/variables-dark.css`

### 10.2: Implement Theme Toggle
- [ ] Toggle button in header (sun/moon icon)
- [ ] JavaScript to switch themes
- [ ] Store preference in localStorage
- [ ] Apply class to `<html>` element: `data-theme="dark"`

### 10.3: System Preference Detection
- [ ] Detect `prefers-color-scheme: dark`
- [ ] Use system preference if no saved preference
- [ ] Code: `window.matchMedia('(prefers-color-scheme: dark)')`

### 10.4: Update All Components
- [ ] Text colors (WCAG contrast 4.5:1 or 3:1 for large)
- [ ] Background colors (dark neutrals, not pure black #000)
- [ ] Borders (subtle, visible in both modes)
- [ ] Shadows (adjusted for dark background)
- [ ] Form inputs, buttons, cards

### 10.5: Image & Chart Optimization
- [ ] Test images in both light and dark modes
- [ ] Adjust image contrast if needed
- [ ] Charts/graphs adapt colors
- [ ] Consider filter: invert() for some images

### 10.6: Testing
- [ ] Test all pages in light and dark mode
- [ ] Use axe DevTools to verify contrast
- [ ] Test toggle functionality
- [ ] Test system preference override
- [ ] Test localStorage persistence

### 10.7: Smooth Transitions
- [ ] CSS transition on theme change (0.3s)
- [ ] No flash/flicker when switching

---

## Deliverables
- `apps/web/static/css/variables-light.css`
- `apps/web/static/css/variables-dark.css`
- Updated HTML (add theme toggle)
- JavaScript for theme switching
- Updated all component CSS

---

## Acceptance Criteria
✅ Dark mode toggle works
✅ System preference detected
✅ Contrast OK in both modes
✅ localStorage persistence
✅ Smooth transitions
✅ All pages/components updated

---

## Time Estimate
**3 days**

---

## Dependencies
- Task 7 (Design System)
- Task 9 (Tool templates)
