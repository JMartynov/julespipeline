# Task 20: Analytics & Usage Tracking

## Subtasks

### 20.1: Tool Usage Tracking
- [ ] Log every API call:
  - [ ] `user_id`
  - [ ] `tool_name` (extract_tables, extract_images, etc.)
  - [ ] `file_size`
  - [ ] `processing_time`
  - [ ] `status` (success, error)
  - [ ] `timestamp`
  - [ ] `ip_address`

- [ ] Create `usage_logs` table:
  - [ ] `id` (UUID)
  - [ ] `user_id` (FK)
  - [ ] `tool` (string)
  - [ ] `file_size` (integer)
  - [ ] `processing_time` (integer, milliseconds)
  - [ ] `status` (success/error)
  - [ ] `error_message` (if error)
  - [ ] `created_at`

### 20.2: Page Visit Tracking
- [ ] Google Analytics integration
  - [ ] Add GA script to all pages
  - [ ] Track page views
  - [ ] Track user engagement (scroll depth, time on page)
  - [ ] Track outbound link clicks
  - [ ] Track button clicks (CTA)

- [ ] Privacy-first approach:
  - [ ] No personal data tracking
  - [ ] Anonymize IPs
  - [ ] Respect DNT header
  - [ ] Privacy policy disclosure

### 20.3: User Activity Dashboard (User-Facing)
- [ ] Show user's own usage:
  - [ ] Files processed (today, this month, all-time)
  - [ ] Tools used (most used first)
  - [ ] Storage used (if applicable)
  - [ ] Average processing time per tool
  - [ ] Success rate (successful vs. failed)

- [ ] Usage history table:
  - [ ] Date, tool, file size, processing time, status
  - [ ] Downloadable as CSV (export)

### 20.4: Usage Limits & Quotas
- [ ] Track usage per user per month
- [ ] Free tier: 3 files/month
- [ ] Pro tier: 100 files/month
- [ ] Business tier: unlimited
- [ ] Show remaining quota in user dashboard
- [ ] Email warning when near limit (80%, 100%)
- [ ] Block requests if over limit (free tier)

### 20.5: Performance Metrics
- [ ] Track average processing time per tool:
  - [ ] Extract Tables: avg 2-5 seconds
  - [ ] Extract Images: avg 2-3 seconds
  - [ ] PDF to Markdown: avg 3-8 seconds (longer for scanned)
  - [ ] Delete Blank Pages: avg 1-2 seconds
  - [ ] Compress PDF: avg 3-10 seconds

- [ ] Monitor performance degradation
- [ ] Alert if avg time exceeds threshold (e.g., > 30s)

### 20.6: Error Tracking
- [ ] Log all errors with context:
  - [ ] Error message
  - [ ] Error type (timeout, validation, server error, etc.)
  - [ ] Stack trace (for server errors)
  - [ ] User ID (if known)
  - [ ] Tool name
  - [ ] Timestamp

- [ ] Create error dashboard:
  - [ ] Total errors today/week/month
  - [ ] Error rate by tool
  - [ ] Most common errors
  - [ ] Recent errors (searchable, filterable)

- [ ] Integration with Sentry (optional, for error monitoring)
  - [ ] Real-time error alerts
  - [ ] Error grouping
  - [ ] Release tracking

### 20.7: Backend Implementation
- [ ] Create logging middleware:
  - [ ] Log all requests (`POST /api/v1/tools/{tool}`)
  - [ ] Capture request/response time
  - [ ] Capture status code
  - [ ] Store in `usage_logs` table

- [ ] Create analytics endpoints:
  - [ ] `/api/v1/analytics/my-usage` (user's own stats)
  - [ ] `/api/v1/analytics/daily-quota` (remaining quota)
  - [ ] `/api/v1/analytics/export` (export as CSV)

- [ ] Create admin analytics endpoints:
  - [ ] `/admin/analytics/overview` (total metrics)
  - [ ] `/admin/analytics/users` (per-user stats)
  - [ ] `/admin/analytics/tools` (per-tool stats)
  - [ ] `/admin/analytics/errors` (error dashboard)

### 20.8: Database Optimization
- [ ] Index on `usage_logs`:
  - [ ] `(user_id, created_at)` for quick user queries
  - [ ] `(tool, created_at)` for per-tool metrics
  - [ ] `(status, created_at)` for error tracking

- [ ] Archive old logs (> 1 year)
- [ ] Or use data warehouse (BigQuery, Snowflake) for analysis

### 20.9: Privacy & GDPR Compliance
- [ ] Privacy policy updated
- [ ] Data retention: logs deleted after 1 year
- [ ] User can request their data (export)
- [ ] User can request deletion (right to be forgotten)
- [ ] No tracking without consent

### 20.10: Dashboard Visualizations
- [ ] Charts using Chart.js or similar:
  - [ ] Line chart: usage over time
  - [ ] Pie chart: tool usage breakdown
  - [ ] Bar chart: errors by tool
  - [ ] Table: detailed usage history

### 20.11: Reporting
- [ ] Weekly usage report (email to user)
  - [ ] Files processed
  - [ ] Tools used
  - [ ] Most used tool
  - [ ] Growth vs. previous week

- [ ] Monthly admin report:
  - [ ] Total users, revenue, API calls
  - [ ] Trends
  - [ ] Anomalies (spike in errors, etc.)

### 20.12: Monitoring & Alerts
- [ ] Set up alerts for:
  - [ ] Sudden spike in errors
  - [ ] Drop in API success rate (< 95%)
  - [ ] Performance degradation
  - [ ] Unusual user behavior (spam)

- [ ] Notification channels:
  - [ ] Email to admins
  - [ ] Slack webhook (if applicable)
  - [ ] Dashboard alert badge

---

## Deliverables
- `usage_logs` table and schema
- Logging middleware
- User analytics dashboard page
- Admin analytics endpoints
- Error tracking system
- Google Analytics setup

---

## Acceptance Criteria
✅ All API calls logged
✅ Usage limits enforced
✅ Analytics dashboard shows correct data
✅ User can export usage history
✅ Errors tracked and visible
✅ Performance metrics collected

---

## Time Estimate
**4-5 days**

---

## Dependencies
- Task 18 (Authentication) - user tracking depends on it
- Task 19 (Admin) - admin analytics endpoints
