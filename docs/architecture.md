# scan.run Architecture Blueprint

## 1) Recommended full-stack architecture

scan.run follows a modular, service-oriented architecture with clear bounded contexts:

- **Web App (Frontend BFF client)**
- **API Gateway / Edge**
- **Core Platform API** (auth, projects, scans, reports, billing state)
- **Scan Orchestrator Service** (job lifecycle + policy checks)
- **Queue + Worker Fleet** (isolated scanners)
- **Report Service** (materialized report projections + export generation)
- **Admin API** (internal operations)
- **Billing Integrations** (Stripe webhooks + entitlements)
- **Observability + Audit pipeline**

### Logical flow

1. User authenticates and verifies domain ownership.
2. User starts scan (credit/subscription entitlement validated).
3. Orchestrator enqueues a scan job and reserves credit.
4. Worker executes in sandbox, stores raw evidence and normalized findings.
5. Report service generates management/technical projections.
6. Dashboard streams status updates and renders report modules.
7. Billing cycle replenishes monthly credits for active subscriptions.

---

## 2) Suggested technology stack

### Frontend
- **Next.js (App Router) + TypeScript**
- **Tailwind CSS + shadcn/ui** for modular design system
- **TanStack Query** for data fetching/state
- **Zod** for runtime schema validation
- **ECharts/Recharts** for risk visualizations

### Backend
- **Node.js (NestJS) + TypeScript**
- **PostgreSQL** (primary relational store)
- **Redis** (queue, rate limits, idempotency, cache)
- **BullMQ** (job orchestration)
- **Object Storage (S3-compatible)** for evidence/report artifacts
- **NATS/Kafka** optional for event-driven scale stage

### Scanning runtime
- **Containerized scanner workers** (e.g., Nuclei, OWASP ZAP automation, custom modules)
- **Kubernetes Jobs** or dedicated worker deployments
- **gVisor/Kata/Firecracker-style isolation** at higher security levels

### Billing/Auth/Infra
- **Stripe** for subscriptions + one-time payments
- **OIDC-compatible auth** (self-hosted or managed) + JWT/refresh token strategy
- **Terraform** for infrastructure as code
- **OpenTelemetry + Prometheus + Grafana + Loki** for observability

---

## 3) Multi-tenant architecture considerations

- Every tenant-scoped table includes `tenant_id`.
- Tenant isolation at API policy layer and query layer.
- Optional PostgreSQL RLS in enterprise tier.
- Per-tenant usage/rate-limit quotas.
- Per-tenant encryption context for sensitive artifacts.

---

## 4) Background job architecture

### Queues
- `scan.requested`
- `scan.dispatch`
- `scan.execute`
- `scan.retry`
- `scan.finalize`
- `report.generate`
- `billing.reconcile`
- `notifications.send`

### Job states
`queued -> validating -> running -> partial_failure|succeeded|failed -> report_generating -> complete`

### Retry policy
- Exponential backoff with jitter
- max attempts configurable by failure class
- hard-stop on policy violations (unverified domain, abuse score)

### Idempotency
- API uses idempotency keys for scan creation and payments
- workers write through immutable execution IDs

---

## 5) Billing/subscription flow

### Single scan ($5)
1. User purchases `1` credit.
2. Stripe payment success webhook confirms transaction.
3. Credit ledger entry created (`credit +1`).
4. Credit consumed when scan enters `running`.

### Subscription ($10/month, 5 scans/month, 12-month minimum)
1. User starts subscription checkout.
2. Contract metadata stores minimum term end date.
3. Monthly renewal webhook triggers ledger refill (`+5` monthly credits).
4. Unused monthly credits can be configured as non-rollover (default) or capped rollover.
5. Early cancellation requests marked pending until term end.

### Credit ledger model
- Never mutate balances directly.
- Derive current balance from immutable ledger entries:
  - `grant_subscription_monthly`
  - `grant_one_time_purchase`
  - `reserve_scan`
  - `consume_scan`
  - `release_scan`
  - `adjustment_admin`

---

## 6) Domain verification flow

Allowed verification methods:
- **DNS TXT token** (preferred)
- **HTTP file challenge** (`/.well-known/scan-run-verification.txt`)
- **Meta tag challenge**

Flow:
1. User adds domain/project.
2. System generates signed verification token and challenge instructions.
3. Verification worker validates challenge from multiple resolvers/regions.
4. Domain marked `verified` with verification evidence snapshot.
5. Re-verification required periodically or upon ownership risk signal.

Policy: scans are blocked unless domain status is `verified` or has explicit admin-approved authorization exception.

---

## 7) User roles & permissions

### Tenant roles
- **Owner**: full tenant access + billing/admin within tenant
- **Admin**: manage members/projects/scans, no ownership transfer
- **Security Analyst**: run scans/view technical reports/export
- **Manager**: view management reports only, limited exports
- **Billing Manager**: subscriptions/invoices/payment methods
- **Viewer**: read-only dashboard access

### Internal roles
- **Platform Admin**: all internal controls
- **Support**: read + limited remedial actions
- **Ops**: queue/worker/retry controls
- **Finance Ops**: billing state tools

Enforce RBAC + optional ABAC policies (resource ownership, environment tags).

---

## 8) Dashboard structure (modular templates)

- `/dashboard/overview`
  - scan utilization, credits, risk trend, recent jobs
- `/dashboard/projects`
  - domains, verification status, project settings
- `/dashboard/scans`
  - scan list, status timeline, filters
- `/dashboard/reports/:scanId`
  - **Management View** module set
  - **Technical View** module set
- `/dashboard/billing`
  - plan, term end, invoices, payment methods, credit ledger
- `/dashboard/settings`
  - members, API keys, notifications
- `/internal/*`
  - user/subscription activity, queue health, policy config, taxonomy editor

UI modularity:
- Widget registry + report section schema
- Renderers separated from API data loaders
- Feature flags for progressive rollout

---

## 9) Report model (management + technical)

### Management view includes
- overall risk score and rating (Critical/High/Medium/Low)
- top prioritized issues
- business impact summary
- remediation roadmap by effort/impact
- trend vs previous scans

### Technical view includes
- finding ID and fingerprint
- affected asset/URL and endpoint metadata
- request/response evidence pointers
- OWASP Top 10 mapping
- CWE/CVSS mapping and vectors
- severity, confidence, exploitability
- remediation guidance and references

### Export formats
- JSON (full machine-readable)
- PDF (management-friendly + technical appendix)

---

## 10) Deployment architecture for scale

### Core runtime
- Kubernetes across multiple node pools:
  - web/api pool
  - background services pool
  - isolated scanner worker pool
- Managed PostgreSQL with read replicas
- Redis cluster/sentinel
- Object storage with lifecycle + immutability controls

### Networking & security
- WAF + API gateway at edge
- strict worker egress policies (allowlist + DNS controls)
- secret manager + short-lived credentials
- private service mesh mTLS

### Scaling strategy
- Horizontal pod autoscaling by queue depth and CPU/memory
- worker autoscaling by `scan.execute` backlog
- partition queues by priority/tenant tier

---

## 11) Security considerations (safe scanning)

- Mandatory domain verification or explicit documented authorization
- Target allow/deny policy engine (block internal/private CIDRs by default)
- SSRF and lateral movement controls in scanner runtime
- Isolated per-job execution context and ephemeral filesystems
- Sanitization of captured evidence and secrets detection/redaction
- Signed artifact URLs with short TTL
- Full audit logs for user/admin/worker actions
- Abuse detection (velocity, anomaly, suspicious targets)
- Rate limiting per IP, user, tenant, and endpoint class
- Legal safeguards: terms acceptance + scanning authorization attestations

---

## 12) MVP -> Growth -> Enterprise path

### MVP
- Single region, one primary scan engine, essential RBAC, Stripe billing

### Growth
- multiple scan engines, event bus, richer reporting templates, multi-region read scaling

### Enterprise
- SSO/SAML, SCIM, custom retention, dedicated workers/VPC, RLS, policy packs, SIEM integrations

