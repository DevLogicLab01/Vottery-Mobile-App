-- Phase B Batch 3: Compliance Reports and System Monitoring
-- Migration: 20260302010000_phase_b_batch3_compliance_sentry_integration.sql
-- Description: Enhanced compliance reports with multi-jurisdiction support and system health monitoring

-- =====================================================
-- ENUMS
-- =====================================================

-- Jurisdiction enum for compliance reports
DO $$ BEGIN
  CREATE TYPE public.jurisdiction_type AS ENUM ('GDPR', 'CCPA', 'CCRA');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Report type enum
DO $$ BEGIN
  CREATE TYPE public.compliance_report_type AS ENUM (
    'data_export',
    'right_to_erasure',
    'consent_audit',
    'access_log'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Report status enum
DO $$ BEGIN
  CREATE TYPE public.report_status_type AS ENUM ('pending', 'completed', 'failed');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- TABLES
-- =====================================================

-- Compliance reports table
CREATE TABLE IF NOT EXISTS public.compliance_reports (
  report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction public.jurisdiction_type NOT NULL,
  report_type public.compliance_report_type NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status public.report_status_type NOT NULL DEFAULT 'pending',
  report_data JSONB DEFAULT '{}',
  file_url TEXT,
  requested_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  completed_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- System health metrics table
CREATE TABLE IF NOT EXISTS public.system_health_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name TEXT NOT NULL,
  metric_value NUMERIC NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  service_name TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit trail for data access events
CREATE TABLE IF NOT EXISTS public.data_access_audit_trail (
  audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_actor UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action_type TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ip_address TEXT,
  affected_records JSONB DEFAULT '[]',
  jurisdiction public.jurisdiction_type,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Scheduled compliance deliveries
CREATE TABLE IF NOT EXISTS public.scheduled_compliance_deliveries (
  delivery_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jurisdiction public.jurisdiction_type NOT NULL,
  report_type public.compliance_report_type NOT NULL,
  schedule_frequency TEXT NOT NULL, -- 'monthly', 'quarterly', 'annual'
  recipient_email TEXT NOT NULL,
  last_sent_at TIMESTAMPTZ,
  next_scheduled_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Data retention policies
CREATE TABLE IF NOT EXISTS public.data_retention_policies (
  policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data_category TEXT NOT NULL,
  retention_period_days INTEGER NOT NULL,
  legal_basis TEXT,
  auto_purge_enabled BOOLEAN DEFAULT TRUE,
  last_purge_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Error tracking incidents (Sentry integration)
CREATE TABLE IF NOT EXISTS public.error_tracking_incidents (
  incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  error_type TEXT NOT NULL, -- 'crash', 'ai_failure', 'network', 'payment'
  severity TEXT NOT NULL, -- 'critical', 'high', 'medium', 'low'
  affected_feature TEXT, -- 'voting', 'gamification', 'payments', 'social'
  error_message TEXT NOT NULL,
  stack_trace TEXT,
  user_context JSONB DEFAULT '{}',
  device_info JSONB DEFAULT '{}',
  sentry_event_id TEXT,
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'open', -- 'open', 'in_progress', 'resolved'
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_compliance_reports_user_id ON public.compliance_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_compliance_reports_jurisdiction ON public.compliance_reports(jurisdiction);
CREATE INDEX IF NOT EXISTS idx_compliance_reports_status ON public.compliance_reports(status);
CREATE INDEX IF NOT EXISTS idx_compliance_reports_generated_at ON public.compliance_reports(generated_at DESC);

CREATE INDEX IF NOT EXISTS idx_system_health_metrics_service_name ON public.system_health_metrics(service_name);
CREATE INDEX IF NOT EXISTS idx_system_health_metrics_timestamp ON public.system_health_metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_system_health_metrics_metric_name ON public.system_health_metrics(metric_name);

CREATE INDEX IF NOT EXISTS idx_data_access_audit_trail_admin_actor ON public.data_access_audit_trail(admin_actor);
CREATE INDEX IF NOT EXISTS idx_data_access_audit_trail_timestamp ON public.data_access_audit_trail(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_data_access_audit_trail_jurisdiction ON public.data_access_audit_trail(jurisdiction);

CREATE INDEX IF NOT EXISTS idx_error_tracking_incidents_severity ON public.error_tracking_incidents(severity);
CREATE INDEX IF NOT EXISTS idx_error_tracking_incidents_status ON public.error_tracking_incidents(status);
CREATE INDEX IF NOT EXISTS idx_error_tracking_incidents_occurred_at ON public.error_tracking_incidents(occurred_at DESC);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.compliance_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_access_audit_trail ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scheduled_compliance_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.data_retention_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.error_tracking_incidents ENABLE ROW LEVEL SECURITY;

-- Compliance reports policies
CREATE POLICY compliance_reports_select_own ON public.compliance_reports
  FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = requested_by);

CREATE POLICY compliance_reports_insert_authenticated ON public.compliance_reports
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY compliance_reports_update_own ON public.compliance_reports
  FOR UPDATE
  USING (auth.uid() = requested_by);

-- System health metrics policies (admin only)
CREATE POLICY system_health_metrics_select_all ON public.system_health_metrics
  FOR SELECT
  USING (TRUE);

CREATE POLICY system_health_metrics_insert_service ON public.system_health_metrics
  FOR INSERT
  WITH CHECK (TRUE);

-- Data access audit trail policies (admin only)
CREATE POLICY data_access_audit_trail_select_all ON public.data_access_audit_trail
  FOR SELECT
  USING (TRUE);

CREATE POLICY data_access_audit_trail_insert_authenticated ON public.data_access_audit_trail
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Scheduled compliance deliveries policies (admin only)
CREATE POLICY scheduled_compliance_deliveries_select_all ON public.scheduled_compliance_deliveries
  FOR SELECT
  USING (TRUE);

CREATE POLICY scheduled_compliance_deliveries_insert_admin ON public.scheduled_compliance_deliveries
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY scheduled_compliance_deliveries_update_admin ON public.scheduled_compliance_deliveries
  FOR UPDATE
  USING (auth.uid() IS NOT NULL);

-- Data retention policies (admin only)
CREATE POLICY data_retention_policies_select_all ON public.data_retention_policies
  FOR SELECT
  USING (TRUE);

CREATE POLICY data_retention_policies_insert_admin ON public.data_retention_policies
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY data_retention_policies_update_admin ON public.data_retention_policies
  FOR UPDATE
  USING (auth.uid() IS NOT NULL);

-- Error tracking incidents policies
CREATE POLICY error_tracking_incidents_select_all ON public.error_tracking_incidents
  FOR SELECT
  USING (TRUE);

CREATE POLICY error_tracking_incidents_insert_service ON public.error_tracking_incidents
  FOR INSERT
  WITH CHECK (TRUE);

CREATE POLICY error_tracking_incidents_update_assigned ON public.error_tracking_incidents
  FOR UPDATE
  USING (auth.uid() = assigned_to OR auth.uid() IS NOT NULL);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to generate compliance report
CREATE OR REPLACE FUNCTION public.generate_compliance_report(
  p_jurisdiction public.jurisdiction_type,
  p_report_type public.compliance_report_type,
  p_user_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_report_id UUID;
BEGIN
  INSERT INTO public.compliance_reports (
    jurisdiction,
    report_type,
    user_id,
    requested_by,
    status
  ) VALUES (
    p_jurisdiction,
    p_report_type,
    p_user_id,
    auth.uid(),
    'pending'
  )
  RETURNING report_id INTO v_report_id;

  RETURN v_report_id;
END;
$$;

-- Function to log data access
CREATE OR REPLACE FUNCTION public.log_data_access(
  p_action_type TEXT,
  p_ip_address TEXT,
  p_affected_records JSONB,
  p_jurisdiction public.jurisdiction_type DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_audit_id UUID;
BEGIN
  INSERT INTO public.data_access_audit_trail (
    admin_actor,
    action_type,
    ip_address,
    affected_records,
    jurisdiction
  ) VALUES (
    auth.uid(),
    p_action_type,
    p_ip_address,
    p_affected_records,
    p_jurisdiction
  )
  RETURNING audit_id INTO v_audit_id;

  RETURN v_audit_id;
END;
$$;

-- Function to track system health metric
CREATE OR REPLACE FUNCTION public.track_system_health_metric(
  p_metric_name TEXT,
  p_metric_value NUMERIC,
  p_service_name TEXT,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_metric_id UUID;
BEGIN
  INSERT INTO public.system_health_metrics (
    metric_name,
    metric_value,
    service_name,
    metadata
  ) VALUES (
    p_metric_name,
    p_metric_value,
    p_service_name,
    p_metadata
  )
  RETURNING metric_id INTO v_metric_id;

  RETURN v_metric_id;
END;
$$;

-- Function to get compliance status by jurisdiction
CREATE OR REPLACE FUNCTION public.get_compliance_status_by_jurisdiction(
  p_jurisdiction public.jurisdiction_type
)
RETURNS TABLE (
  total_reports BIGINT,
  pending_reports BIGINT,
  completed_reports BIGINT,
  failed_reports BIGINT,
  compliance_score NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_reports,
    COUNT(*) FILTER (WHERE status = 'pending')::BIGINT AS pending_reports,
    COUNT(*) FILTER (WHERE status = 'completed')::BIGINT AS completed_reports,
    COUNT(*) FILTER (WHERE status = 'failed')::BIGINT AS failed_reports,
    CASE
      WHEN COUNT(*) = 0 THEN 100.0
      ELSE (COUNT(*) FILTER (WHERE status = 'completed')::NUMERIC / COUNT(*)::NUMERIC * 100.0)
    END AS compliance_score
  FROM public.compliance_reports
  WHERE jurisdiction = p_jurisdiction
    AND generated_at >= NOW() - INTERVAL '30 days';
END;
$$;

-- Function to get recent error incidents
CREATE OR REPLACE FUNCTION public.get_recent_error_incidents(
  p_limit INTEGER DEFAULT 50,
  p_severity TEXT DEFAULT NULL
)
RETURNS TABLE (
  incident_id UUID,
  error_type TEXT,
  severity TEXT,
  affected_feature TEXT,
  error_message TEXT,
  user_context JSONB,
  status TEXT,
  occurred_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.incident_id,
    e.error_type,
    e.severity,
    e.affected_feature,
    e.error_message,
    e.user_context,
    e.status,
    e.occurred_at
  FROM public.error_tracking_incidents e
  WHERE (p_severity IS NULL OR e.severity = p_severity)
  ORDER BY e.occurred_at DESC
  LIMIT p_limit;
END;
$$;

-- =====================================================
-- MOCK DATA
-- =====================================================

-- Insert data retention policies
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.data_retention_policies WHERE data_category = 'analytics') THEN
    INSERT INTO public.data_retention_policies (data_category, retention_period_days, legal_basis, auto_purge_enabled)
    VALUES
      ('analytics', 730, 'Business analytics and reporting', TRUE),
      ('marketing', 365, 'Marketing consent and communications', TRUE),
      ('financial', 2555, 'Tax law compliance (7 years)', FALSE),
      ('user_content', 1095, 'User-generated content retention', TRUE),
      ('audit_logs', 1825, 'Security and compliance auditing', FALSE);
  END IF;
END $$;

-- Insert scheduled compliance deliveries
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.scheduled_compliance_deliveries WHERE recipient_email = 'compliance@vottery.com') THEN
    INSERT INTO public.scheduled_compliance_deliveries (
      jurisdiction,
      report_type,
      schedule_frequency,
      recipient_email,
      next_scheduled_at
    ) VALUES
      ('GDPR', 'data_export', 'monthly', 'compliance@vottery.com', NOW() + INTERVAL '30 days'),
      ('CCPA', 'consent_audit', 'quarterly', 'compliance@vottery.com', NOW() + INTERVAL '90 days'),
      ('CCRA', 'access_log', 'monthly', 'compliance@vottery.com', NOW() + INTERVAL '30 days');
  END IF;
END $$;

-- Insert sample system health metrics
DO $$
BEGIN
  INSERT INTO public.system_health_metrics (metric_name, metric_value, service_name, metadata)
  VALUES
    ('api_latency_p50', 85, 'supabase', '{"unit": "ms", "target": 100}'),
    ('api_latency_p95', 250, 'supabase', '{"unit": "ms", "target": 500}'),
    ('api_latency_p50', 450, 'stripe', '{"unit": "ms", "target": 500}'),
    ('api_latency_p50', 1800, 'openai', '{"unit": "ms", "target": 2000}'),
    ('api_latency_p50', 2500, 'anthropic', '{"unit": "ms", "target": 3000}'),
    ('database_query_time', 45, 'supabase', '{"unit": "ms", "threshold": 1000}'),
    ('service_uptime', 99.95, 'supabase', '{"unit": "percent", "sla_target": 99.9}'),
    ('error_rate', 0.5, 'application', '{"unit": "percent", "threshold": 1.0}');
END $$;

-- Insert sample error tracking incidents
DO $$
BEGIN
  INSERT INTO public.error_tracking_incidents (
    error_type,
    severity,
    affected_feature,
    error_message,
    user_context,
    device_info,
    status
  ) VALUES
    ('crash', 'critical', 'voting', 'Unhandled exception in vote submission', '{"user_id": "anonymous"}', '{"platform": "android", "version": "1.0.0"}', 'open'),
    ('ai_failure', 'high', 'gamification', 'OpenAI API timeout after 30 seconds', '{"operation": "quest_generation"}', '{"platform": "ios", "version": "1.0.0"}', 'in_progress'),
    ('network', 'medium', 'payments', 'Stripe API returned 503 Service Unavailable', '{"payment_method": "card"}', '{"platform": "web"}', 'resolved'),
    ('payment', 'high', 'payments', 'Payment intent creation failed', '{"amount": 50.00}', '{"platform": "android"}', 'open');
END $$;
