# scan.run Recommended Codebase Structure

```text
scan.run/
  apps/
    web/                      # Next.js frontend
    api/                      # NestJS public API + BFF endpoints
    admin/                    # Internal admin UI (can be merged with web + route guards)
    worker/                   # Scan worker runtime entrypoints
    scheduler/                # Cron-like scheduled jobs (credit refills, re-verification)

  packages/
    ui/                       # Reusable component library + dashboard templates
    config/                   # Shared lint/tsconfig/build presets
    auth/                     # Auth utilities, JWT, RBAC policy helpers
    billing/                  # Stripe adapters + entitlement logic
    scanning-core/            # Scan orchestration contracts and engine adapters
    reporting/                # Report projections, scoring, export renderers
    taxonomy/                 # OWASP/CWE/CVSS mapping rules
    database/                 # Prisma/SQL migrations + repository helpers
    observability/            # logging, tracing, metrics wrappers
    shared-types/             # zod schemas + TS types for API contracts

  infrastructure/
    terraform/
      environments/
        dev/
        staging/
        prod/
      modules/
        k8s/
        postgres/
        redis/
        storage/
        networking/
    kubernetes/
      base/
      overlays/
        dev/
        staging/
        prod/

  docs/
    architecture.md
    database_schema.sql
    api.md
    runbooks/
      incident-response.md
      scanner-failure-retry.md
      billing-reconciliation.md

  .github/
    workflows/
      ci.yml
      cd.yml
      security.yml

  scripts/
    bootstrap.sh
    seed-dev.ts
    rotate-keys.ts
```

## Modularity and extensibility patterns

1. **Scanner plugin interface** in `packages/scanning-core`:
   - each engine implements `prepare`, `execute`, `normalizeFindings`, `collectEvidence`.
2. **Report template registry** in `packages/reporting`:
   - register management/technical widget templates via metadata.
3. **Dashboard widget composition** in `packages/ui`:
   - route-level configs define active widgets, data source bindings, and access policy.
4. **Entitlement engine** in `packages/billing`:
   - plan rules are data-driven to support future tiers.
5. **Policy enforcement middleware** in API:
   - centralized checks for verification, limits, and role permissions.

## CI/CD recommendations

- PR checks: lint, unit tests, integration tests, migration checks, SAST, dependency audit
- Deploy gates: staging smoke scans, synthetic transaction checks, queue health checks
- Progressive rollouts: canary release for orchestrator and worker components

