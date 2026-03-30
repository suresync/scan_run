# scan.run API Design (v1)

Base URL: `https://api.scan.run/v1`

## Auth

- `POST /auth/register`
- `POST /auth/login`
- `POST /auth/refresh`
- `POST /auth/logout`
- `POST /auth/mfa/verify`

## Tenant and membership

- `GET /me`
- `GET /tenants`
- `POST /tenants`
- `GET /tenants/{tenantId}/members`
- `POST /tenants/{tenantId}/members`
- `PATCH /tenants/{tenantId}/members/{userId}`
- `DELETE /tenants/{tenantId}/members/{userId}`

## Projects and domains

- `GET /tenants/{tenantId}/projects`
- `POST /tenants/{tenantId}/projects`
- `PATCH /tenants/{tenantId}/projects/{projectId}`
- `DELETE /tenants/{tenantId}/projects/{projectId}`
- `GET /tenants/{tenantId}/domains`
- `POST /tenants/{tenantId}/domains`
- `GET /tenants/{tenantId}/domains/{domainId}/verification`
- `POST /tenants/{tenantId}/domains/{domainId}/verification/start`
- `POST /tenants/{tenantId}/domains/{domainId}/verification/complete`

## Scans

- `POST /tenants/{tenantId}/scans`
  - Validates verified domain + available credits
  - Creates scan job and reserve credit ledger entry
- `GET /tenants/{tenantId}/scans`
- `GET /tenants/{tenantId}/scans/{scanId}`
- `POST /tenants/{tenantId}/scans/{scanId}/cancel`
- `POST /tenants/{tenantId}/scans/{scanId}/retry`

## Reports

- `GET /tenants/{tenantId}/scans/{scanId}/report/management`
- `GET /tenants/{tenantId}/scans/{scanId}/report/technical`
- `POST /tenants/{tenantId}/scans/{scanId}/report/export`
  - body: `{ "format": "pdf" | "json" }`
- `GET /tenants/{tenantId}/exports/{exportId}`

## Billing

- `GET /tenants/{tenantId}/billing/summary`
- `POST /tenants/{tenantId}/billing/checkout/single-scan`
- `POST /tenants/{tenantId}/billing/checkout/subscription`
- `GET /tenants/{tenantId}/billing/invoices`
- `GET /tenants/{tenantId}/billing/ledger`
- `POST /tenants/{tenantId}/billing/subscription/cancel`
- `POST /webhooks/stripe`

## API keys

- `GET /tenants/{tenantId}/api-keys`
- `POST /tenants/{tenantId}/api-keys`
- `DELETE /tenants/{tenantId}/api-keys/{keyId}`

## Internal admin API

- `GET /internal/users`
- `GET /internal/subscriptions`
- `GET /internal/scans`
- `GET /internal/queue/health`
- `POST /internal/scans/{scanId}/retry`
- `GET /internal/billing/payments`
- `GET /internal/taxonomy`
- `PUT /internal/taxonomy`
- `GET /internal/rate-limit/policies`
- `PUT /internal/rate-limit/policies`

---

## Example: create scan

`POST /tenants/{tenantId}/scans`

```json
{
  "projectId": "4cf8a75a-8b47-4d21-a4c8-5ad0639f4a11",
  "domainId": "8d7fc1e2-b011-4fc4-b0d5-2650d7cb8843",
  "scanProfile": "owasp-baseline",
  "priority": "normal"
}
```

Response:

```json
{
  "scanId": "0f7aa0f6-21ac-4bc8-8cbc-024f355c2a75",
  "status": "queued",
  "creditReservation": {
    "ledgerEntryId": "6a6a9e75-ef85-4680-9f57-8e16e80b9e33",
    "quantity": -1
  }
}
```

---

## Webhook events to consume

- `invoice.paid`
- `invoice.payment_failed`
- `checkout.session.completed`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`

Idempotency requirement: store processed webhook event IDs and reject duplicates.

