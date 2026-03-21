-- Enterprise operations foundation
-- Covers white-label, SSO, pricing/licensing, and multi-role approval workflows.
-- Communication policy note: SMS remains Telnyx primary with Twilio fallback.

create table if not exists public.enterprise_branding_configs (
  id uuid primary key default gen_random_uuid(),
  tenant_id text not null unique,
  custom_domain text,
  brand_name text not null default 'Vottery Enterprise',
  primary_color text not null default '#4f46e5',
  hide_vottery_branding boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.enterprise_sso_configs (
  id uuid primary key default gen_random_uuid(),
  tenant_id text not null unique,
  provider text not null check (provider in ('okta', 'azure_ad', 'google_workspace', 'saml2')),
  client_id text,
  issuer text,
  saml_entry_point text,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.enterprise_pricing_models (
  id uuid primary key default gen_random_uuid(),
  tenant_id text not null unique,
  participation_discount_percent numeric(5,2) not null default 0,
  bulk_vp_discount_percent numeric(5,2) not null default 0,
  flat_fee_unlimited_elections numeric(14,2) not null default 0,
  license_terms text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.enterprise_approval_workflows (
  id uuid primary key default gen_random_uuid(),
  tenant_id text not null,
  workflow_name text not null,
  required_roles text[] not null default '{}',
  min_approvals int not null default 1 check (min_approvals > 0),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.enterprise_approval_requests (
  id uuid primary key default gen_random_uuid(),
  workflow_id uuid not null references public.enterprise_approval_workflows(id) on delete cascade,
  requester_id uuid references auth.users(id) on delete set null,
  request_type text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.enterprise_approval_decisions (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.enterprise_approval_requests(id) on delete cascade,
  approver_role text not null,
  decision text not null check (decision in ('approved', 'rejected')),
  note text,
  decided_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_enterprise_approval_workflows_tenant
  on public.enterprise_approval_workflows(tenant_id);
create index if not exists idx_enterprise_approval_requests_workflow
  on public.enterprise_approval_requests(workflow_id, status);
create index if not exists idx_enterprise_approval_decisions_request
  on public.enterprise_approval_decisions(request_id);

alter table public.enterprise_branding_configs enable row level security;
alter table public.enterprise_sso_configs enable row level security;
alter table public.enterprise_pricing_models enable row level security;
alter table public.enterprise_approval_workflows enable row level security;
alter table public.enterprise_approval_requests enable row level security;
alter table public.enterprise_approval_decisions enable row level security;

drop policy if exists enterprise_branding_authenticated_rw on public.enterprise_branding_configs;
create policy enterprise_branding_authenticated_rw
  on public.enterprise_branding_configs
  for all
  to authenticated
  using (true)
  with check (true);

drop policy if exists enterprise_sso_authenticated_rw on public.enterprise_sso_configs;
create policy enterprise_sso_authenticated_rw
  on public.enterprise_sso_configs
  for all
  to authenticated
  using (true)
  with check (true);

drop policy if exists enterprise_pricing_authenticated_rw on public.enterprise_pricing_models;
create policy enterprise_pricing_authenticated_rw
  on public.enterprise_pricing_models
  for all
  to authenticated
  using (true)
  with check (true);

drop policy if exists enterprise_workflows_authenticated_rw on public.enterprise_approval_workflows;
create policy enterprise_workflows_authenticated_rw
  on public.enterprise_approval_workflows
  for all
  to authenticated
  using (true)
  with check (true);

drop policy if exists enterprise_requests_authenticated_rw on public.enterprise_approval_requests;
create policy enterprise_requests_authenticated_rw
  on public.enterprise_approval_requests
  for all
  to authenticated
  using (true)
  with check (true);

drop policy if exists enterprise_decisions_authenticated_rw on public.enterprise_approval_decisions;
create policy enterprise_decisions_authenticated_rw
  on public.enterprise_approval_decisions
  for all
  to authenticated
  using (true)
  with check (true);

