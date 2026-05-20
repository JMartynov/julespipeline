# Task 11: Upload & Error Handling UX

## Subtasks

### 11.1: File Validation Feedback
- [ ] Real-time file type check (before upload)
- [ ] Error: "Only PDF files are supported"
- [ ] File size warning if > 25MB
- [ ] Message: "Large files may take longer to process"
- [ ] Estimated processing time based on file size

### 11.2: Upload Progress
- [ ] Progress bar (percentage)
- [ ] "Uploading 45%..."
- [ ] Cancel upload button
- [ ] Time estimate (time remaining)
- [ ] Upload speed indicator (optional)

### 11.3: User-Friendly Error Messages
- [ ] Encrypted PDF: "This PDF is encrypted. Please remove the password first."
- [ ] No content: "No tables found. Try another PDF or use Extract Tables (Scanned)."
- [ ] Timeout: "Processing took too long. Please try again with a smaller file."
- [ ] Invalid format: "This PDF format is not supported."
- [ ] Server error: "We encountered an error. Please try again."
- [ ] All messages include next steps

### 11.4: Success Confirmation
- [ ] Checkmark animation (✓)
- [ ] Success message: "Successfully processed!"
- [ ] Summary of results:
  - [ ] "Extracted 5 tables"
  - [ ] "Extracted 12 images"
  - [ ] "Converted to Markdown"
  - [ ] etc. per tool
- [ ] Download CTA button (prominent)

### 11.5: Processing State Feedback
- [ ] At 5s: Show animated spinner
- [ ] At 10s: Show "Still processing..." message
- [ ] At 20s: Show "This may take a moment..."
- [ ] At 30s: Timeout with retry option
- [ ] Cancel button always visible

### 11.6: Error Recovery
- [ ] "Retry" button after error
- [ ] "Upload different file" link
- [ ] Clear error message with next steps
- [ ] No confusing technical errors

### 11.7: Inline Validation
- [ ] Form inputs show errors as user types
- [ ] Invalid field highlighted (red border)
- [ ] Error text below field
- [ ] Success state (green checkmark) optional

### 11.8: Toast Notifications (Optional)
- [ ] Upload started
- [ ] Upload complete
- [ ] Copy to clipboard success
- [ ] Download ready
- [ ] Position: bottom-right or top-center

---

## Deliverables
- Updated tool page templates
- Error message templates/constants
- Validation functions (JavaScript)
- Toast notification component (optional)

---

## Acceptance Criteria
✅ File validation working
✅ Upload progress visible
✅ Error messages user-friendly
✅ Success confirmation clear
✅ Timeout handling graceful
✅ Recovery options obvious

---

## Time Estimate
**3 days**

---

## Dependencies
- Task 9 (Tool templates)
