# Task 18: Authentication & SSO (Google, GitHub, Email)

## Subtasks

### 18.1: User Table & Database
- [ ] Create `users` table:
  - [ ] `id` (UUID)
  - [ ] `email` (unique)
  - [ ] `name`
  - [ ] `password_hash` (if email/password auth)
  - [ ] `created_at`, `updated_at`
  - [ ] `subscription_tier` (free, pro, business)
  - [ ] `stripe_customer_id`

- [ ] Create `sessions` table:
  - [ ] `id` (UUID)
  - [ ] `user_id` (FK)
  - [ ] `token`
  - [ ] `expires_at`
  - [ ] `created_at`

### 18.2: Email/Password Authentication
- [ ] Sign-up form (email, name, password)
- [ ] Password hashing (bcrypt or argon2)
- [ ] Sign-in form (email, password)
- [ ] Session creation after login
- [ ] Logout endpoint
- [ ] "Forgot password" flow

### 18.3: Google OAuth Integration
- [ ] Create Google OAuth app (Google Console)
- [ ] Get `client_id`, `client_secret`
- [ ] Implement OAuth 2.0 flow (authorization code)
- [ ] Handle Google callback
- [ ] Create/update user from Google profile
- [ ] Link Google account to existing user (optional)

### 18.4: GitHub OAuth Integration
- [ ] Create GitHub OAuth app
- [ ] Get `client_id`, `client_secret`
- [ ] Implement OAuth 2.0 flow
- [ ] Handle GitHub callback
- [ ] Create/update user from GitHub profile

### 18.5: Other SSO Options (Optional)
- [ ] Consider: Microsoft, Apple, Discord
- [ ] Same implementation pattern as Google/GitHub
- [ ] User choice at sign-up

### 18.6: Login Page
- [ ] Email/password form
- [ ] "Sign up" link
- [ ] OAuth buttons (Google, GitHub, etc.)
- [ ] "Forgot password" link
- [ ] Responsive design
- [ ] Dark mode support

### 18.7: Sign-Up Page
- [ ] Email, name, password form
- [ ] Password strength indicator
- [ ] "Terms of Service" checkbox
- [ ] OAuth sign-up buttons
- [ ] Email verification (optional, but recommended)

### 18.8: Password Management
- [ ] Password reset endpoint
- [ ] Email verification link
- [ ] Reset page (new password form)
- [ ] Security: token expires in 1 hour
- [ ] Send confirmation email after reset

### 18.9: Session Management
- [ ] Session cookies (httpOnly, secure, sameSite)
- [ ] Session timeout (30 days, sliding window)
- [ ] Logout clears session
- [ ] Refresh token pattern (if JWT)
- [ ] CSRF protection on forms

### 18.10: User Account Page
- [ ] View profile (name, email, subscription)
- [ ] Edit name
- [ ] Change password
- [ ] Link/unlink OAuth accounts
- [ ] Delete account (GDPR right to deletion)
- [ ] Download data (GDPR)

### 18.11: Backend Implementation
- [ ] Auth middleware (protect routes)
- [ ] `register()` endpoint
- [ ] `login()` endpoint
- [ ] `logout()` endpoint
- [ ] `google_callback()` endpoint
- [ ] `github_callback()` endpoint
- [ ] `change_password()` endpoint
- [ ] `reset_password()` endpoint

### 18.12: Security
- [ ] Rate limiting on login (prevent brute force)
- [ ] Rate limiting on password reset (prevent abuse)
- [ ] Email verification (prevent spam signups)
- [ ] HTTPS only (secure cookies)
- [ ] CSRF tokens on forms
- [ ] XSS protection (sanitize inputs)

---

## Deliverables
- User database schema
- Authentication module (FastAPI dependencies)
- Login/sign-up/password reset pages
- OAuth integration code
- Session management

---

## Acceptance Criteria
✅ Email/password auth works
✅ Google OAuth works
✅ GitHub OAuth works (or alternative)
✅ Sessions persist across requests
✅ Logout clears session
✅ Password reset email works
✅ Rate limiting on auth endpoints

---

## Time Estimate
**5-6 days**

---

## Dependencies
- Database setup
