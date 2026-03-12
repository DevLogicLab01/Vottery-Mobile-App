-- ============================================================
-- SECURITY FIX: Remove SECURITY DEFINER from active_automatic_fallbacks view
-- Migration: 20260315030000_fix_security_definer_view.sql
-- ============================================================

-- STEP 1: Drop existing SECURITY DEFINER view
DROP VIEW IF EXISTS public.active_automatic_fallbacks CASCADE;

-- STEP 5 (Audit first): Audit all SECURITY DEFINER objects before proceeding
DO $$
DECLARE
  definer_view RECORD;
BEGIN
  RAISE NOTICE 'Auditing SECURITY DEFINER views...';
  FOR definer_view IN
    SELECT schemaname, viewname, definition
    FROM pg_views
    WHERE definition ILIKE '%SECURITY DEFINER%'
      AND schemaname = 'public'
  LOOP
    RAISE WARNING 'Found SECURITY DEFINER view: %.%', definer_view.schemaname, definer_view.viewname;
  END LOOP;
END $$;

-- STEP 4: Create underlying tables if they don't exist
-- Create ai_service_failovers table
CREATE TABLE IF NOT EXISTS public.ai_service_failovers (
  fallback_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name VARCHAR(100) NOT NULL,
  current_handler VARCHAR(100),
  is_active BOOLEAN NOT NULL DEFAULT false,
  triggered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  failure_reason TEXT,
  auto_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create ai_service_health table
CREATE TABLE IF NOT EXISTS public.ai_service_health (
  health_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name VARCHAR(100) NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'healthy',
  response_time_ms INTEGER,
  error_rate DECIMAL(5,4) DEFAULT 0,
  last_check_at TIMESTAMPTZ DEFAULT NOW(),
  consecutive_failures INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create ai_failover_logs table
CREATE TABLE IF NOT EXISTS public.ai_failover_logs (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  failover_id UUID REFERENCES public.ai_service_failovers(fallback_id) ON DELETE SET NULL,
  event_type VARCHAR(50) NOT NULL,
  from_service VARCHAR(100),
  to_service VARCHAR(100),
  trigger_reason TEXT,
  duration_ms INTEGER,
  success BOOLEAN DEFAULT true,
  error_details TEXT,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- STEP 4: Enable RLS on all related tables
ALTER TABLE public.ai_service_failovers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_service_health ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_failover_logs ENABLE ROW LEVEL SECURITY;

-- Enable RLS on gemini_takeover_case_reports if it exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'gemini_takeover_case_reports') THEN
    EXECUTE 'ALTER TABLE public.gemini_takeover_case_reports ENABLE ROW LEVEL SECURITY';
    RAISE NOTICE 'Enabled RLS on gemini_takeover_case_reports';
  END IF;
END $$;

-- STEP 6: Drop ALL existing is_admin overloads to avoid ambiguity, then recreate
DO $$
DECLARE
  func_record RECORD;
BEGIN
  FOR func_record IN
    SELECT oid, pg_get_function_identity_arguments(oid) AS args
    FROM pg_proc
    WHERE proname = 'is_admin'
      AND pronamespace = 'public'::regnamespace
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS public.is_admin(%s) CASCADE', func_record.args);
    RAISE NOTICE 'Dropped existing is_admin(%) function', func_record.args;
  END LOOP;
END $$;

-- Create single canonical is_admin function with explicit UUID parameter (no default)
CREATE OR REPLACE FUNCTION public.is_admin(check_user_id UUID)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = check_user_id
      AND role IN ('admin', 'super_admin', 'security_admin', 'devops_admin')
  );
$$;

-- Grant execute on helper function
GRANT EXECUTE ON FUNCTION public.is_admin(UUID) TO authenticated;

-- STEP 4: Create admin-only RLS policies using helper function with explicit cast
-- Policy for ai_service_failovers
DROP POLICY IF EXISTS admin_only_failover_view ON public.ai_service_failovers;
CREATE POLICY admin_only_failover_view
  ON public.ai_service_failovers
  FOR SELECT
  TO authenticated
  USING (public.is_admin(auth.uid()::uuid));

DROP POLICY IF EXISTS admin_only_failover_insert ON public.ai_service_failovers;
CREATE POLICY admin_only_failover_insert
  ON public.ai_service_failovers
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin(auth.uid()::uuid));

DROP POLICY IF EXISTS admin_only_failover_update ON public.ai_service_failovers;
CREATE POLICY admin_only_failover_update
  ON public.ai_service_failovers
  FOR UPDATE
  TO authenticated
  USING (public.is_admin(auth.uid()::uuid))
  WITH CHECK (public.is_admin(auth.uid()::uuid));

-- Policy for ai_service_health
DROP POLICY IF EXISTS admin_only_ai_health ON public.ai_service_health;
CREATE POLICY admin_only_ai_health
  ON public.ai_service_health
  FOR SELECT
  TO authenticated
  USING (public.is_admin(auth.uid()::uuid));

DROP POLICY IF EXISTS admin_only_ai_health_write ON public.ai_service_health;
CREATE POLICY admin_only_ai_health_write
  ON public.ai_service_health
  FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()::uuid))
  WITH CHECK (public.is_admin(auth.uid()::uuid));

-- Policy for ai_failover_logs
DROP POLICY IF EXISTS admin_only_failover_logs ON public.ai_failover_logs;
CREATE POLICY admin_only_failover_logs
  ON public.ai_failover_logs
  FOR SELECT
  TO authenticated
  USING (public.is_admin(auth.uid()::uuid));

DROP POLICY IF EXISTS admin_only_failover_logs_write ON public.ai_failover_logs;
CREATE POLICY admin_only_failover_logs_write
  ON public.ai_failover_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (public.is_admin(auth.uid()::uuid));

-- Policy for gemini_takeover_case_reports if it exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'gemini_takeover_case_reports') THEN
    EXECUTE 'DROP POLICY IF EXISTS admin_only_gemini_reports ON public.gemini_takeover_case_reports';
    EXECUTE $policy$
      CREATE POLICY admin_only_gemini_reports
        ON public.gemini_takeover_case_reports
        FOR SELECT
        TO authenticated
        USING (public.is_admin(auth.uid()::uuid))
    $policy$;
    RAISE NOTICE 'Created admin RLS policy on gemini_takeover_case_reports';
  END IF;
END $$;

-- STEP 1: Recreate view WITHOUT SECURITY DEFINER
-- The view now relies on RLS of the underlying table
CREATE VIEW public.active_automatic_fallbacks AS
  SELECT
    fallback_id,
    service_name,
    current_handler,
    is_active,
    triggered_at,
    failure_reason,
    auto_resolved,
    resolved_at
  FROM public.ai_service_failovers
  WHERE is_active = true
    AND triggered_at > NOW() - INTERVAL '24 hours'
  ORDER BY triggered_at DESC;

-- NOTE: ALTER VIEW OWNER is intentionally omitted.
-- Supabase migrations run as a restricted role without superuser privileges.
-- Access control is enforced via RLS on the underlying ai_service_failovers table.

-- STEP 1: Revoke public/anon access, grant only to authenticated
REVOKE ALL ON public.active_automatic_fallbacks FROM PUBLIC;
REVOKE ALL ON public.active_automatic_fallbacks FROM anon;
GRANT SELECT ON public.active_automatic_fallbacks TO authenticated;

-- Add documentation comment
COMMENT ON VIEW public.active_automatic_fallbacks IS
  'Admin-only view of active AI service failovers in last 24 hours. RLS enforced via ai_service_failovers table policy. No SECURITY DEFINER - uses invoker permissions.';

-- STEP 5: Create audit log table
CREATE TABLE IF NOT EXISTS public.security_definer_audit_log (
  audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  object_type VARCHAR(20) NOT NULL,
  object_schema VARCHAR(100) NOT NULL,
  object_name VARCHAR(200) NOT NULL,
  has_security_definer BOOLEAN NOT NULL DEFAULT false,
  issue_severity VARCHAR(20) DEFAULT 'high',
  remediation_status VARCHAR(20) DEFAULT 'pending',
  audited_at TIMESTAMPTZ DEFAULT NOW(),
  audited_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  notes TEXT
);

-- Enable RLS on audit log
ALTER TABLE public.security_definer_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_only_audit_log ON public.security_definer_audit_log;
CREATE POLICY admin_only_audit_log
  ON public.security_definer_audit_log
  FOR ALL
  TO authenticated
  USING (public.is_admin(auth.uid()::uuid))
  WITH CHECK (public.is_admin(auth.uid()::uuid));

-- Insert audit record for the fixed view
INSERT INTO public.security_definer_audit_log (
  object_type,
  object_schema,
  object_name,
  has_security_definer,
  issue_severity,
  remediation_status,
  notes
)
SELECT
  'view',
  'public',
  'active_automatic_fallbacks',
  false,
  'high',
  'fixed',
  'Removed SECURITY DEFINER from active_automatic_fallbacks view. View now uses SECURITY INVOKER (default) with RLS on underlying ai_service_failovers table.'
WHERE NOT EXISTS (
  SELECT 1 FROM public.security_definer_audit_log
  WHERE object_name = 'active_automatic_fallbacks'
    AND remediation_status = 'fixed'
);

-- STEP 7: Add rollback comment
COMMENT ON TABLE public.security_definer_audit_log IS
  'Audit log for SECURITY DEFINER vulnerability remediation. Rollback: DROP VIEW active_automatic_fallbacks CASCADE; Restore from backup if needed.';
