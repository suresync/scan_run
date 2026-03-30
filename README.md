# scan.run

**scan.run** is a production-oriented SaaS platform for safe, authorized OWASP-focused web vulnerability scanning.

This repository currently contains the reference architecture, data model, API design, and implementation blueprint for building scan.run from MVP through enterprise scale.

## What is included

- Full-stack architecture and service boundaries
- Recommended technology stack
- Multi-tenant database schema (PostgreSQL)
- Public API and admin API design
- Scan queue and worker orchestration design
- Billing and subscription lifecycle
- Domain ownership verification flow
- Role/permission model
- Dashboard/module composition design
- Report data model (management + technical views)
- Deployment architecture and scaling strategy
- Security controls for safe scanning
- Extensible monorepo codebase structure

## Core pricing model

1. **Single Scan**: `$5` one-time purchase for one scan credit.
2. **Subscription**: `$10/month` with `5 scans/month`, minimum `12-month` commitment.

## Product principles

- Scan only verified/authorized targets
- Isolated scan execution with strict egress controls
- Strong abuse prevention and auditability
- Clear separation of reusable UI templates and business logic
- Modular architecture for adding engines, plans, and enterprise features

## Documents

- [`docs/architecture.md`](docs/architecture.md)
- [`docs/database_schema.sql`](docs/database_schema.sql)
- [`docs/api.md`](docs/api.md)
- [`docs/codebase-structure.md`](docs/codebase-structure.md)

# Scan Run Web App

A lightweight, production-minded starter web application with:

- A documented architecture and delivery plan.
- A working client-side site (no build tools required).
- A modular JavaScript code structure that can scale.

## Quick start

Run a local web server from the repository root:

```bash
python3 -m http.server 8080
```

Then open `http://localhost:8080`.

## What is included

- `docs/ARCHITECTURE.md` — high-level design architecture and roadmap.
- `index.html` — semantic app shell.
- `styles.css` — responsive, accessible styling system.
- `app.js` — modular app logic with persistence in `localStorage`.

## Features

- Task creation/edit/delete.
- Status workflow (`backlog`, `in-progress`, `done`).
- Priority levels and filtering.
- Search and statistics.
- Persistent storage in the browser.

## Next steps

See the architecture document for a staged evolution into a full stack deployment with API, auth, observability, CI/CD, and managed infrastructure.
