# Task 9: Unified Tool Page Template (All 5 Tools)

## Subtasks

### 9.1: Tool Header Section
- [ ] Tool icon (from library)
- [ ] Tool name (heading)
- [ ] Short description (1-2 lines)
- [ ] Benefits list (3 bullet points)
- [ ] Responsive padding/spacing
- [ ] Dark mode support

### 9.2: Upload Area Redesign
- [ ] Prominent drag-and-drop zone (light blue or primary color)
- [ ] "Drag files here or click to upload" text
- [ ] File type validation feedback (real-time)
- [ ] File size indicator with warning if too large
- [ ] Upload progress bar (during upload)
- [ ] Cancel upload button
- [ ] Hover/focus states

### 9.3: Tool Options Panel
- [ ] Sidebar layout (desktop) or accordion (mobile)
- [ ] Tool-specific options:
  - [ ] Extract Tables: flavor selection (Lattice/Stream)
  - [ ] Compress PDF: target size slider
  - [ ] Delete Blank Pages: sensitivity threshold
  - [ ] etc. per tool
- [ ] Clear labels with help tooltips (?)
- [ ] Input validation with inline errors
- [ ] Reset button

### 9.4: Processing State
- [ ] Animated spinner icon
- [ ] "Processing..." text
- [ ] Progress bar (if available)
- [ ] Time estimate (if available)
- [ ] Cancel processing button
- [ ] No interaction allowed while processing

### 9.5: Result Presentation Container
- [ ] Preview area:
  - [ ] Extract Tables: table grid preview
  - [ ] Extract Images: image gallery with thumbnails
  - [ ] PDF to Markdown: markdown editor with preview tabs
  - [ ] Delete Blank Pages: before/after page count
  - [ ] Compress PDF: compression ratio visualization
  
- [ ] Download options:
  - [ ] Download format dropdown (CSV, PDF, ZIP, etc.)
  - [ ] Download button (enabled after success)
  - [ ] File size shown after download ready
  
- [ ] Share buttons (optional):
  - [ ] Copy link
  - [ ] Copy to clipboard
  - [ ] Email
  
- [ ] Action buttons:
  - [ ] "Try another file"
  - [ ] "Go to home"

### 9.6: Responsive Layout
- [ ] Desktop: Two columns (upload/options on left, preview on right)
- [ ] Tablet: Stacked vertically
- [ ] Mobile: Single column, full-width
- [ ] Breakpoints: 375px, 768px, 1024px

### 9.7: Tool-Specific Variants
- [ ] Create CSS classes for each tool variant
- [ ] Extract Tables: table preview grid
- [ ] Extract Images: image gallery layout
- [ ] PDF to Markdown: markdown editor with syntax highlight
- [ ] Delete Blank Pages: page count display
- [ ] Compress PDF: ratio chart/visualization

### 9.8: Accessibility
- [ ] Keyboard navigation for all controls
- [ ] ARIA labels for icons
- [ ] Focus indicators
- [ ] Form labels properly associated
- [ ] Skip to main content link (if needed)

### 9.9: Dark Mode
- [ ] All colors have dark variants
- [ ] Text contrast OK
- [ ] Preview areas readable
- [ ] Icons visible

### 9.10: Create Template Files
- [ ] `apps/web/templates/tool_base.html` (Jinja2 template)
- [ ] `apps/web/static/css/tool_page.css`
- [ ] `apps/web/static/css/tool_variants.css`
- [ ] Update each tool page to use template

---

## Deliverables
- `apps/web/templates/tool_base.html` (base template)
- `apps/web/static/css/tool_page.css` (styles)
- Updated tool page templates (index.html for each tool)

---

## Acceptance Criteria
✅ Unified look across all 5 tools
✅ Responsive on all devices
✅ Dark mode working
✅ Accessible (keyboard + screen reader)
✅ Smooth interactions
✅ Tool-specific variants working

---

## Time Estimate
**5 days** (design + template + CSS)

---

## Dependencies
- Task 7 (Design System)
