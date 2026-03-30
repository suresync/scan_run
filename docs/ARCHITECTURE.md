# Design Architecture: From Idea to Working Application

This document defines an architecture that starts with a simple working web app and can evolve into a production-ready platform.

## 1) Product goals

### Primary goals

1. Deliver a usable web application quickly.
2. Keep complexity low while the product validates usage.
3. Preserve clear upgrade paths to backend services and cloud deployment.

### Non-goals (phase 1)

- No user accounts or multi-tenant data model.
- No server-side rendering requirement.
- No external dependencies required to run locally.

## 2) Current implementation (this repository)

### Frontend

- **Stack**: HTML, CSS, vanilla JavaScript.
- **Pattern**: Module-style organization in one script file (`state`, `storage`, `ui`, `stats`, `controller`).
- **Data persistence**: Browser `localStorage`.

### Application capabilities

- Create, update, and delete tasks.
- Move tasks through a three-state workflow.
- Filter by status/priority and search by text.
- View lightweight operational stats.

## 3) Proposed target architecture (phase 2+)

### Logical components

1. **Web Client (SPA)**
   - Framework: React/Vue/Svelte (team choice).
   - Responsibilities: Rendering, form/state interactions, API integration.

2. **API Layer**
   - Framework: Node (Express/Fastify) or Python (FastAPI).
   - Responsibilities: Validation, business rules, auth, audit metadata.

3. **Data Layer**
   - Relational DB (PostgreSQL).
   - Tables: `users`, `projects`, `tasks`, `activity_events`.

4. **Infrastructure**
   - Containerized services.
   - Reverse proxy / edge routing.
   - Managed database and object storage.

5. **Observability**
   - Structured logs, metrics dashboards, error tracking.

### Sequence of maturity

- **Phase 1 (now)**: single-page local app.
- **Phase 2**: API + DB + frontend API client.
- **Phase 3**: authentication/authorization and team collaboration.
- **Phase 4**: analytics, automation, and integrations.

## 4) Suggested folder structure for phase 2

```text
/web                 # Frontend SPA
/api                 # REST API service
/infrastructure      # IaC (Terraform/CDK), deployment manifests
/docs                # Architecture, ADRs, runbooks
```

## 5) Quality standards

- Accessibility-first UI semantics and labels.
- Deterministic data model and pure helper functions where possible.
- Minimal coupling between rendering and state update logic.
- Clear coding conventions and incremental test coverage.

## 6) Security and compliance baseline (phase 2+)

- Input validation at API boundary.
- Auth token expiration and rotation.
- Principle of least privilege for DB/service credentials.
- HTTPS-only traffic and secure cookie settings.

## 7) Delivery workflow

1. Build vertical slices (UI + logic + persistence) incrementally.
2. Add automated checks (lint/test/type) in CI.
3. Use feature branches and PR reviews.
4. Deploy to staging, run smoke tests, then promote to production.

## 8) Operational checklist

- [ ] Document environment configuration.
- [ ] Add synthetic uptime checks.
- [ ] Add backup/restore strategy.
- [ ] Add incident response runbook.
- [ ] Add error budgets and SLOs.

