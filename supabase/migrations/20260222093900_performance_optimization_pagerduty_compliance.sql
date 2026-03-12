-- Performance Optimization, PagerDuty Integration, and Compliance Reports
-- Migration: 20260222093900_performance_optimization_pagerduty_compliance.sql
-- Description: AI-powered performance optimization advisor, PagerDuty on-call routing, and automated compliance reporting

-- =====================================================
-- ENUMS
-- =====================================================

DO $$ BEGIN
  CREATE TYPE public.optimization_type AS ENUM (
    'slow_query',
    'api_bottleneck',
    'infrastructure',
    'caching'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.optimization_severity AS ENUM (
    'critical',
    'high',
    'medium',
    'low'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.implementation_status AS ENUM (
    'pending',
    'in_progress',
    'completed',
    'dismissed'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.pagerduty_incident_status AS ENUM (
    'triggered',
    'acknowledged',
    'resolved'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.compliance_report_type_v2 AS ENUM (
    'GDPR',
    'SOC2',
    'HIPAA',
    'ISO27001',
    'CUSTOM'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- TABLES
-- =====================================================

-- Performance optimizations table
CREATE TABLE IF NOT EXISTS public.performance_optimizations (
  optimization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  optimization_type public.optimization_type NOT NULL,
  severity public.optimization_severity NOT NULL,
  affected_component TEXT NOT NULL,
  current_metrics JSONB NOT NULL DEFAULT '{}',
  recommended_actions JSONB NOT NULL DEFAULT '[]',
  estimated_improvement JSONB NOT NULL DEFAULT '{}',
  implementation_status public.implementation_status NOT NULL DEFAULT 'pending',
  implemented_at TIMESTAMPTZ,
  implementation_notes TEXT,
  assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ai_analysis JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- On-call schedules table
CREATE TABLE IF NOT EXISTS public.on_call_schedules (
  schedule_id TEXT PRIMARY KEY,
  schedule_name TEXT NOT NULL,
  team_name TEXT,
  current_on_call_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  current_on_call_name TEXT,
  current_on_call_email TEXT,
  current_on_call_phone TEXT,
  on_call_until TIMESTAMPTZ,
  next_on_call_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  next_on_call_name TEXT,
  escalation_policy JSONB DEFAULT '{}',
  last_synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PagerDuty incidents table
CREATE TABLE IF NOT EXISTS public.pagerduty_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vottery_incident_id UUID REFERENCES public.incidents(id) ON DELETE CASCADE,
  pagerduty_incident_id TEXT NOT NULL UNIQUE,
  fingerprint TEXT NOT NULL,
  status public.pagerduty_incident_status NOT NULL DEFAULT 'triggered',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ,
  acknowledged_by TEXT,
  resolved_at TIMESTAMPTZ,
  escalation_policy TEXT,
  assigned_to TEXT,
  deduplication_count INTEGER DEFAULT 0,
  last_deduplicated_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PagerDuty routing rules table
CREATE TABLE IF NOT EXISTS public.pagerduty_routing_rules (
  rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_name TEXT NOT NULL,
  conditions JSONB NOT NULL DEFAULT '{}',
  escalation_policy TEXT NOT NULL,
  team_name TEXT,
  priority INTEGER DEFAULT 0,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Compliance reports v2 table (extended)
CREATE TABLE IF NOT EXISTS public.compliance_reports_v2 (
  report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type public.compliance_report_type_v2 NOT NULL,
  reporting_period_start DATE NOT NULL,
  reporting_period_end DATE NOT NULL,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  generated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  compliance_status TEXT NOT NULL,
  report_data JSONB NOT NULL DEFAULT '{}',
  pdf_url TEXT,
  digital_signature TEXT,
  signature_hash TEXT,
  signed_at TIMESTAMPTZ,
  signed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'completed',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Scheduled compliance reports table
CREATE TABLE IF NOT EXISTS public.scheduled_compliance_reports (
  schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type public.compliance_report_type_v2 NOT NULL,
  frequency TEXT NOT NULL,
  recipients TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  report_scope JSONB DEFAULT '{}',
  enabled BOOLEAN DEFAULT TRUE,
  last_run_at TIMESTAMPTZ,
  next_run_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Report signatures table
CREATE TABLE IF NOT EXISTS public.report_signatures (
  signature_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID REFERENCES public.compliance_reports_v2(report_id) ON DELETE CASCADE,
  signature_hash TEXT NOT NULL,
  signed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  signed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  verification_method TEXT NOT NULL,
  public_key TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_performance_optimizations_type ON public.performance_optimizations(optimization_type);
CREATE INDEX IF NOT EXISTS idx_performance_optimizations_severity ON public.performance_optimizations(severity);
CREATE INDEX IF NOT EXISTS idx_performance_optimizations_status ON public.performance_optimizations(implementation_status);
CREATE INDEX IF NOT EXISTS idx_performance_optimizations_detected_at ON public.performance_optimizations(detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_on_call_schedules_team ON public.on_call_schedules(team_name);
CREATE INDEX IF NOT EXISTS idx_on_call_schedules_current_user ON public.on_call_schedules(current_on_call_user_id);

CREATE INDEX IF NOT EXISTS idx_pagerduty_incidents_vottery_id ON public.pagerduty_incidents(vottery_incident_id);
CREATE INDEX IF NOT EXISTS idx_pagerduty_incidents_pagerduty_id ON public.pagerduty_incidents(pagerduty_incident_id);
CREATE INDEX IF NOT EXISTS idx_pagerduty_incidents_fingerprint ON public.pagerduty_incidents(fingerprint);
CREATE INDEX IF NOT EXISTS idx_pagerduty_incidents_status ON public.pagerduty_incidents(status);

CREATE INDEX IF NOT EXISTS idx_compliance_reports_v2_type ON public.compliance_reports_v2(report_type);
CREATE INDEX IF NOT EXISTS idx_compliance_reports_v2_generated_at ON public.compliance_reports_v2(generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_compliance_reports_v2_status ON public.compliance_reports_v2(status);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Performance optimizations RLS
ALTER TABLE public.performance_optimizations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view optimizations" ON public.performance_optimizations;
CREATE POLICY "Admins can view optimizations"
  ON public.performance_optimizations FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'devops_admin')
    )
  );

DROP POLICY IF EXISTS "System can insert optimizations" ON public.performance_optimizations;
CREATE POLICY "System can insert optimizations"
  ON public.performance_optimizations FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can update optimizations" ON public.performance_optimizations;
CREATE POLICY "Admins can update optimizations"
  ON public.performance_optimizations FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'devops_admin')
    )
  );

-- On-call schedules RLS
ALTER TABLE public.on_call_schedules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view schedules" ON public.on_call_schedules;
CREATE POLICY "Admins can view schedules"
  ON public.on_call_schedules FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin', 'devops_admin')
    )
  );

DROP POLICY IF EXISTS "System can manage schedules" ON public.on_call_schedules;
CREATE POLICY "System can manage schedules"
  ON public.on_call_schedules FOR ALL
  TO authenticated
  WITH CHECK (true);

-- PagerDuty incidents RLS
ALTER TABLE public.pagerduty_incidents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view pagerduty incidents" ON public.pagerduty_incidents;
CREATE POLICY "Admins can view pagerduty incidents"
  ON public.pagerduty_incidents FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin', 'devops_admin')
    )
  );

DROP POLICY IF EXISTS "System can manage pagerduty incidents" ON public.pagerduty_incidents;
CREATE POLICY "System can manage pagerduty incidents"
  ON public.pagerduty_incidents FOR ALL
  TO authenticated
  WITH CHECK (true);

-- PagerDuty routing rules RLS
ALTER TABLE public.pagerduty_routing_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage routing rules" ON public.pagerduty_routing_rules;
CREATE POLICY "Admins can manage routing rules"
  ON public.pagerduty_routing_rules FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

-- Compliance reports v2 RLS
ALTER TABLE public.compliance_reports_v2 ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view compliance reports" ON public.compliance_reports_v2;
CREATE POLICY "Admins can view compliance reports"
  ON public.compliance_reports_v2 FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'auditor')
    )
  );

DROP POLICY IF EXISTS "System can insert compliance reports" ON public.compliance_reports_v2;
CREATE POLICY "System can insert compliance reports"
  ON public.compliance_reports_v2 FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Scheduled compliance reports RLS
ALTER TABLE public.scheduled_compliance_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage scheduled reports" ON public.scheduled_compliance_reports;
CREATE POLICY "Admins can manage scheduled reports"
  ON public.scheduled_compliance_reports FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'auditor')
    )
  );

-- Report signatures RLS
ALTER TABLE public.report_signatures ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view signatures" ON public.report_signatures;
CREATE POLICY "Admins can view signatures"
  ON public.report_signatures FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'auditor')
    )
  );

DROP POLICY IF EXISTS "System can insert signatures" ON public.report_signatures;
CREATE POLICY "System can insert signatures"
  ON public.report_signatures FOR INSERT
  TO authenticated
  WITH CHECK (true);
