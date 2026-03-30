-- scan.run reference PostgreSQL schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email CITEXT UNIQUE NOT NULL,
  password_hash TEXT,
  auth_provider TEXT NOT NULL DEFAULT 'local',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_login_at TIMESTAMPTZ
);

CREATE TABLE tenant_members (
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner','admin','security_analyst','manager','billing_manager','viewer')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, user_id)
);

CREATE TABLE projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE domains (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  hostname TEXT NOT NULL,
  verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending','verified','failed','revoked')),
  verification_method TEXT CHECK (verification_method IN ('dns_txt','http_file','meta_tag','manual_exception')),
  verified_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, hostname)
);

CREATE TABLE domain_verification_challenges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  domain_id UUID NOT NULL REFERENCES domains(id) ON DELETE CASCADE,
  method TEXT NOT NULL CHECK (method IN ('dns_txt','http_file','meta_tag')),
  token TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  validated_at TIMESTAMPTZ,
  validation_evidence JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  provider TEXT NOT NULL DEFAULT 'stripe',
  provider_customer_id TEXT NOT NULL,
  provider_subscription_id TEXT,
  plan_code TEXT NOT NULL CHECK (plan_code IN ('single_scan','monthly_5_commit_12m')),
  status TEXT NOT NULL CHECK (status IN ('trialing','active','past_due','canceled','incomplete','paused')),
  contract_start_at TIMESTAMPTZ,
  minimum_term_end_at TIMESTAMPTZ,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE credit_ledger (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES subscriptions(id),
  scan_id UUID,
  entry_type TEXT NOT NULL CHECK (entry_type IN (
    'grant_subscription_monthly',
    'grant_one_time_purchase',
    'reserve_scan',
    'consume_scan',
    'release_scan',
    'adjustment_admin'
  )),
  quantity INTEGER NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  provider TEXT NOT NULL DEFAULT 'stripe',
  provider_payment_id TEXT NOT NULL,
  amount_cents INTEGER NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  status TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE scan_jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  domain_id UUID NOT NULL REFERENCES domains(id) ON DELETE CASCADE,
  requested_by UUID REFERENCES users(id),
  status TEXT NOT NULL CHECK (status IN (
    'queued','validating','running','retrying','partial_failure','succeeded','failed','canceled','report_generating','complete'
  )),
  engine TEXT NOT NULL,
  priority SMALLINT NOT NULL DEFAULT 5,
  queued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  failure_reason TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE scan_executions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scan_job_id UUID NOT NULL REFERENCES scan_jobs(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL,
  worker_id TEXT,
  status TEXT NOT NULL CHECK (status IN ('running','succeeded','failed','timed_out','aborted')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ,
  runtime_metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  UNIQUE (scan_job_id, attempt_number)
);

CREATE TABLE findings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  scan_job_id UUID NOT NULL REFERENCES scan_jobs(id) ON DELETE CASCADE,
  fingerprint TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  severity TEXT NOT NULL CHECK (severity IN ('critical','high','medium','low','info')),
  confidence TEXT CHECK (confidence IN ('high','medium','low')),
  owasp_category TEXT,
  cwe_id TEXT,
  cvss_vector TEXT,
  cvss_score NUMERIC(3,1),
  exploitability_score NUMERIC(3,1),
  affected_url TEXT,
  evidence_ref TEXT,
  remediation TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (scan_job_id, fingerprint)
);

CREATE TABLE report_snapshots (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  scan_job_id UUID NOT NULL REFERENCES scan_jobs(id) ON DELETE CASCADE,
  management_report JSONB NOT NULL,
  technical_report JSONB NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (scan_job_id)
);

CREATE TABLE report_exports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  scan_job_id UUID NOT NULL REFERENCES scan_jobs(id) ON DELETE CASCADE,
  format TEXT NOT NULL CHECK (format IN ('pdf','json')),
  artifact_uri TEXT NOT NULL,
  checksum_sha256 TEXT,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  key_prefix TEXT NOT NULL,
  key_hash TEXT NOT NULL,
  scopes TEXT[] NOT NULL DEFAULT '{}',
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
  actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  actor_type TEXT NOT NULL CHECK (actor_type IN ('user','system','worker','admin')),
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  ip_address INET,
  user_agent TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE rate_limit_counters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scope TEXT NOT NULL,
  scope_key TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL,
  request_count INTEGER NOT NULL,
  UNIQUE (scope, scope_key, window_start)
);

CREATE INDEX idx_scan_jobs_tenant_status ON scan_jobs (tenant_id, status);
CREATE INDEX idx_findings_scan_job ON findings (scan_job_id, severity);
CREATE INDEX idx_credit_ledger_tenant_created ON credit_ledger (tenant_id, created_at DESC);
CREATE INDEX idx_audit_logs_tenant_created ON audit_logs (tenant_id, created_at DESC);
