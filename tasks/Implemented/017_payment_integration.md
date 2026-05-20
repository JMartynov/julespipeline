# Task 17: Payment Integration (Stripe)

## Subtasks

### 17.1: Stripe Account Setup
- [ ] Create Stripe account (if not exists)
- [ ] Get API keys (publishable, secret)
- [ ] Store in environment variables
- [ ] Test mode vs. Live mode separation
- [ ] Webhook setup (for payment confirmals)

### 17.2: Pricing Page
- [ ] Design pricing page with 3-4 tiers
- [ ] Free tier (limited usage)
- [ ] Pro tier ($9.99/month)
- [ ] Business tier ($29.99/month)
- [ ] Feature comparison table
- [ ] CTA buttons ("Subscribe Now")

### 17.3: Stripe Checkout Integration
- [ ] Stripe.js integration (frontend)
- [ ] Stripe Elements (payment form)
- [ ] Card input field (secure)
- [ ] Billing email field
- [ ] Create checkout session (backend)
- [ ] Redirect to Stripe Hosted Checkout

### 17.4: Subscription Management
- [ ] Store `stripe_customer_id` in user table
- [ ] Store `stripe_subscription_id`
- [ ] Track subscription status (active, canceled, paused)
- [ ] Track billing cycle dates
- [ ] Invoice history

### 17.5: Webhook Handling
- [ ] Implement webhook endpoint (`/stripe-webhook`)
- [ ] Listen to events:
  - [ ] `customer.subscription.created`
  - [ ] `customer.subscription.updated`
  - [ ] `customer.subscription.deleted`
  - [ ] `invoice.payment_succeeded`
  - [ ] `invoice.payment_failed`
- [ ] Update user subscription status in DB

### 17.6: Subscription Cancellation
- [ ] Add "Cancel Subscription" button (user account)
- [ ] Confirm cancellation (prevent accidents)
- [ ] Call Stripe API: `stripe.subscriptions.cancel()`
- [ ] Update local DB (mark as canceled)
- [ ] Send cancellation email

### 17.7: Usage Limits & Enforcement
- [ ] Track API usage per user (free vs. paid)
- [ ] Free tier: limit 3 files/month
- [ ] Pro tier: limit 100 files/month
- [ ] Business tier: unlimited
- [ ] Show usage meter in user dashboard
- [ ] Enforce limits (reject over-limit requests)

### 17.8: Invoices & Receipts
- [ ] Generate invoices in Stripe
- [ ] Email invoices to user
- [ ] Provide invoice download link in dashboard
- [ ] Invoice history page

### 17.9: Payment Error Handling
- [ ] Retry failed payments (3 retries)
- [ ] Email notifications (payment failed, retry pending)
- [ ] User message: "Payment failed, please try again"
- [ ] Link to update payment method

### 17.10: Backend Implementation
- [ ] Create Stripe service module
- [ ] `create_checkout_session()`
- [ ] `create_subscription()`
- [ ] `cancel_subscription()`
- [ ] `get_subscription_status()`
- [ ] `verify_webhook_signature()`

---

## Deliverables
- Pricing page (HTML/CSS)
- Stripe integration module
- Webhook endpoint
- Subscription management endpoints
- Usage tracking/enforcement

---

## Acceptance Criteria
✅ Stripe checkout works end-to-end
✅ Webhooks received and processed
✅ Usage limits enforced
✅ Subscription cancellation works
✅ Invoices generated
✅ All payment errors handled gracefully

---

## Time Estimate
**5-6 days** (includes testing with Stripe test mode)

---

## Dependencies
- Task 18 (Authentication) - user accounts needed first
