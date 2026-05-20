# Task 19: Admin Dashboard

## Subtasks

### 19.1: Admin Access Control
- [ ] Create `admin_users` table
- [ ] Mark users as admin (boolean flag)
- [ ] Admin-only route protection
- [ ] Audit log (who, what, when)

### 19.2: Admin Layout
- [ ] Navigation sidebar (admin-only pages)
- [ ] Top navigation (welcome admin, logout, profile)
- [ ] Responsive layout (mobile hamburger menu)
- [ ] Dark mode support

### 19.3: User Management
- [ ] List all users (pagination, search)
- [ ] User details: email, name, signup date, subscription
- [ ] Edit user details
- [ ] Manually upgrade/downgrade tier
- [ ] Disable/enable user account
- [ ] Delete user (with confirmation)
- [ ] View user API usage
- [ ] Send email to user (optional)

### 19.4: Subscription Management
- [ ] List all active subscriptions
- [ ] List canceled subscriptions
- [ ] View subscription details (user, tier, billing date)
- [ ] Manual subscription management:
  - [ ] Upgrade tier
  - [ ] Downgrade tier
  - [ ] Cancel subscription
  - [ ] Extend trial (if applicable)

### 19.5: Payment/Billing
- [ ] View recent payments
- [ ] List failed payments
- [ ] Payment history (all users)
- [ ] Revenue metrics (monthly, yearly)
- [ ] Subscription revenue vs. one-time payments
- [ ] Outstanding invoices

### 19.6: Usage Analytics
- [ ] Total API calls (all users)
- [ ] API calls per tool (extract tables, images, etc.)
- [ ] Average file size processed
- [ ] Peak usage times (hourly/daily)
- [ ] Top users (by API calls)
- [ ] Usage by subscription tier

### 19.7: System Monitoring
- [ ] Server status (uptime)
- [ ] API health (response times)
- [ ] Error rate dashboard
- [ ] Failed jobs (PDF processing failures)
- [ ] Recent errors (searchable)

### 19.8: Dashboard/Reports
- [ ] Key metrics at a glance:
  - [ ] Total users
  - [ ] Active subscriptions
  - [ ] Monthly recurring revenue (MRR)
  - [ ] Total revenue
  - [ ] API calls today/month
  
- [ ] Charts:
  - [ ] Revenue over time (line chart)
  - [ ] Subscription tiers breakdown (pie chart)
  - [ ] API usage by tool (bar chart)
  - [ ] New users over time (line chart)

### 19.9: Logging & Audit
- [ ] Log all admin actions
- [ ] Audit trail (view changes)
- [ ] Who changed what, when, why
- [ ] Filterable audit log

### 19.10: Settings Page
- [ ] Update system settings:
  - [ ] Free tier API limit
  - [ ] Pro tier API limit
  - [ ] Business tier API limit
  - [ ] File size limits per tier
  - [ ] Pricing per tier (dynamic)
  
- [ ] Email configuration (SMTP settings)
- [ ] Stripe keys (test/live toggle)

### 19.11: Security
- [ ] Only admins can access dashboard
- [ ] Admin user must be manually created (bootstrap)
- [ ] Sensitive data should be logged
- [ ] Rate limiting on admin endpoints
- [ ] Admin session timeout (shorter than normal: 1 hour)

### 19.12: Backend Implementation
- [ ] `/admin/` routes (protected)
- [ ] `/admin/users` (CRUD)
- [ ] `/admin/subscriptions` (view, manage)
- [ ] `/admin/payments` (view)
- [ ] `/admin/analytics` (metrics)
- [ ] `/admin/logs` (audit log)
- [ ] `/admin/settings` (system config)

---

## Deliverables
- Admin dashboard pages (HTML/CSS)
- Admin API endpoints (FastAPI)
- Audit logging system
- Analytics data aggregation

---

## Acceptance Criteria
✅ Admin access control works
✅ User CRUD operations work
✅ Analytics displayed correctly
✅ Audit log functional
✅ System settings updateable
✅ Dashboard loads quickly

---

## Time Estimate
**5-6 days**

---

## Dependencies
- Task 18 (Authentication) - user management depends on it
- Task 17 (Payment) - subscription management depends on it
