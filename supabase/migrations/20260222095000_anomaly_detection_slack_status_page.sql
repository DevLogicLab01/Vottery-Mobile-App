-- Performance Anomaly Detection, Slack Notifications, and Status Page
-- Migration: 20260222095000_anomaly_detection_slack_status_page.sql
-- Description: Automated baseline calculation, threshold-based anomaly detection, Slack integration, and public status page

-- =====================================================
-- ENUMS
-- =====================================================

DO $$ BEGIN
  CREATE TYPE public.anomaly_severity AS ENUM (
    'critical',
    'high',
    'medium'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.system_status AS ENUM (
    'operational',
    'degraded',
    'outage'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.maintenance_status AS ENUM (
    'scheduled',
    'in_progress',
    'completed',
    'cancelled'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- TABLES
-- =====================================================

-- Performance baselines table
CREATE TABLE IF NOT EXISTS public.performance_baselines (
  baseline_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_name TEXT NOT NULL,
  operation_type TEXT NOT NULL,
  p50_baseline_ms NUMERIC NOT NULL,
  p95_baseline_ms NUMERIC NOT NULL,
  p99_baseline_ms NUMERIC NOT NULL,
  sample_count INTEGER NOT NULL,
  baseline_period_start TIMESTAMPTZ NOT NULL,
  baseline_period_end TIMESTAMPTZ NOT NULL,
  calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  confidence_score NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(operation_name, operation_type)
);

-- Performance anomalies table
CREATE TABLE IF NOT EXISTS public.performance_anomalies (
  anomaly_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_name TEXT NOT NULL,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  baseline_p95_ms NUMERIC NOT NULL,
  current_p95_ms NUMERIC NOT NULL,
  deviation_percentage NUMERIC NOT NULL,
  severity public.anomaly_severity NOT NULL,
  alert_sent BOOLEAN DEFAULT FALSE,
  acknowledged BOOLEAN DEFAULT FALSE,
  acknowledged_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  acknowledged_at TIMESTAMPTZ,
  root_cause_analysis JSONB DEFAULT '{}',
  affected_requests INTEGER DEFAULT 0,
  impact_assessment TEXT,
  resolution_actions JSONB DEFAULT '[]',
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Slack workspaces table
CREATE TABLE IF NOT EXISTS public.slack_workspaces (
  workspace_id TEXT PRIMARY KEY,
  team_name TEXT NOT NULL,
  access_token TEXT NOT NULL,
  webhook_url TEXT NOT NULL,
  installed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  installed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Slack messages table
CREATE TABLE IF NOT EXISTS public.slack_messages (
  message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workspace_id TEXT REFERENCES public.slack_workspaces(workspace_id) ON DELETE CASCADE,
  channel TEXT NOT NULL,
  message_type TEXT NOT NULL,
  incident_id UUID,
  anomaly_id UUID REFERENCES public.performance_anomalies(anomaly_id) ON DELETE CASCADE,
  message_payload JSONB NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivery_status TEXT NOT NULL DEFAULT 'pending',
  slack_ts TEXT,
  error_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Slack notification settings table
CREATE TABLE IF NOT EXISTS public.slack_notification_settings (
  setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_type TEXT NOT NULL,
  channel TEXT NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  severity_threshold TEXT,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(notification_type)
);

-- System services table
CREATE TABLE IF NOT EXISTS public.system_services (
  service_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name TEXT NOT NULL UNIQUE,
  service_type TEXT NOT NULL,
  current_status public.system_status NOT NULL DEFAULT 'operational',
  response_time_ms NUMERIC,
  uptime_percentage NUMERIC DEFAULT 100,
  last_checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status_message TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Service incidents table
CREATE TABLE IF NOT EXISTS public.service_incidents (
  incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID REFERENCES public.system_services(service_id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  severity TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'investigating',
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  affected_components TEXT[] DEFAULT '{}',
  updates JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Scheduled maintenance table
CREATE TABLE IF NOT EXISTS public.scheduled_maintenance (
  maintenance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  maintenance_start TIMESTAMPTZ NOT NULL,
  maintenance_end TIMESTAMPTZ NOT NULL,
  affected_services TEXT[] DEFAULT '{}',
  maintenance_type TEXT NOT NULL,
  impact_level TEXT NOT NULL,
  status public.maintenance_status NOT NULL DEFAULT 'scheduled',
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Daily uptime records table
CREATE TABLE IF NOT EXISTS public.daily_uptime_records (
  record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  record_date DATE NOT NULL UNIQUE,
  uptime_percentage NUMERIC NOT NULL,
  downtime_minutes INTEGER NOT NULL DEFAULT 0,
  incident_count INTEGER NOT NULL DEFAULT 0,
  incidents JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Status page subscribers table
CREATE TABLE IF NOT EXISTS public.status_page_subscribers (
  subscriber_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  subscribed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  notification_preferences JSONB DEFAULT '{"incidents": true, "maintenance": true, "monthly_reports": true}',
  verified BOOLEAN DEFAULT FALSE,
  verification_token TEXT,
  unsubscribe_token TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =====================================================
-- INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_performance_baselines_operation ON public.performance_baselines(operation_name, operation_type);
CREATE INDEX IF NOT EXISTS idx_performance_anomalies_detected_at ON public.performance_anomalies(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_performance_anomalies_severity ON public.performance_anomalies(severity);
CREATE INDEX IF NOT EXISTS idx_slack_messages_sent_at ON public.slack_messages(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_services_status ON public.system_services(current_status);
CREATE INDEX IF NOT EXISTS idx_service_incidents_status ON public.service_incidents(status);
CREATE INDEX IF NOT EXISTS idx_scheduled_maintenance_dates ON public.scheduled_maintenance(maintenance_start, maintenance_end);
CREATE INDEX IF NOT EXISTS idx_daily_uptime_date ON public.daily_uptime_records(record_date DESC);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Performance baselines policies
ALTER TABLE public.performance_baselines ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage baselines"
ON public.performance_baselines FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

CREATE POLICY "All users can view baselines"
ON public.performance_baselines FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Performance anomalies policies
ALTER TABLE public.performance_anomalies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage anomalies"
ON public.performance_anomalies FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

CREATE POLICY "All users can view anomalies"
ON public.performance_anomalies FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Slack workspaces policies
ALTER TABLE public.slack_workspaces ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage Slack workspaces"
ON public.slack_workspaces FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

-- Slack messages policies
ALTER TABLE public.slack_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view Slack messages"
ON public.slack_messages FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

-- System services policies (public read)
ALTER TABLE public.system_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view system services"
ON public.system_services FOR SELECT
USING (TRUE);

CREATE POLICY "Admins can manage system services"
ON public.system_services FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

-- Service incidents policies (public read)
ALTER TABLE public.service_incidents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view service incidents"
ON public.service_incidents FOR SELECT
USING (TRUE);

CREATE POLICY "Admins can manage service incidents"
ON public.service_incidents FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

-- Scheduled maintenance policies (public read)
ALTER TABLE public.scheduled_maintenance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view scheduled maintenance"
ON public.scheduled_maintenance FOR SELECT
USING (TRUE);

CREATE POLICY "Admins can manage scheduled maintenance"
ON public.scheduled_maintenance FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

-- Daily uptime records policies (public read)
ALTER TABLE public.daily_uptime_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view daily uptime records"
ON public.daily_uptime_records FOR SELECT
USING (TRUE);

CREATE POLICY "Admins can manage daily uptime records"
ON public.daily_uptime_records FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

-- Status page subscribers policies (public insert for subscription)
ALTER TABLE public.status_page_subscribers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can subscribe"
ON public.status_page_subscribers FOR INSERT
WITH CHECK (TRUE);

CREATE POLICY "Subscribers can view own subscription"
ON public.status_page_subscribers FOR SELECT
USING (email = (SELECT email FROM auth.users WHERE id = auth.uid()));

CREATE POLICY "Admins can manage subscribers"
ON public.status_page_subscribers FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to calculate baseline confidence score
CREATE OR REPLACE FUNCTION calculate_baseline_confidence(sample_count INTEGER)
RETURNS NUMERIC AS $$
BEGIN
  RETURN CASE
    WHEN sample_count >= 1000 THEN 0.95
    WHEN sample_count >= 500 THEN 0.85
    WHEN sample_count >= 100 THEN 0.70
    ELSE 0.50
  END;
END;
$$ LANGUAGE plpgsql;

-- Function to determine anomaly severity
CREATE OR REPLACE FUNCTION determine_anomaly_severity(deviation_percentage NUMERIC)
RETURNS public.anomaly_severity AS $$
BEGIN
  RETURN CASE
    WHEN deviation_percentage > 200 THEN 'critical'::public.anomaly_severity
    WHEN deviation_percentage > 150 THEN 'high'::public.anomaly_severity
    ELSE 'medium'::public.anomaly_severity
  END;
END;
$$ LANGUAGE plpgsql;

-- Function to get overall system status
CREATE OR REPLACE FUNCTION get_overall_system_status()
RETURNS public.system_status AS $$
DECLARE
  outage_count INTEGER;
  degraded_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO outage_count
  FROM public.system_services
  WHERE current_status = 'outage';

  IF outage_count > 0 THEN
    RETURN 'outage'::public.system_status;
  END IF;

  SELECT COUNT(*) INTO degraded_count
  FROM public.system_services
  WHERE current_status = 'degraded';

  IF degraded_count > 0 THEN
    RETURN 'degraded'::public.system_status;
  END IF;

  RETURN 'operational'::public.system_status;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEED DATA
-- =====================================================

-- Insert default system services
INSERT INTO public.system_services (service_name, service_type, current_status, uptime_percentage)
VALUES
  ('Supabase Database', 'database', 'operational', 99.97),
  ('Stripe Payments', 'payment', 'operational', 99.95),
  ('OpenAI Services', 'ai', 'operational', 99.90),
  ('Anthropic Claude', 'ai', 'operational', 99.92),
  ('Perplexity AI', 'ai', 'operational', 99.88),
  ('Gemini AI', 'ai', 'operational', 99.91),
  ('Twilio SMS', 'communication', 'operational', 99.99),
  ('Resend Email', 'communication', 'operational', 99.98),
  ('Mobile App Backend', 'api', 'operational', 99.96)
ON CONFLICT (service_name) DO NOTHING;

-- Insert default Slack notification settings
INSERT INTO public.slack_notification_settings (notification_type, channel, enabled)
VALUES
  ('security_incidents', '#security-alerts', TRUE),
  ('performance_alerts', '#performance-alerts', TRUE),
  ('payment_failures', '#payment-ops', TRUE),
  ('system_outages', '#incidents', TRUE)
ON CONFLICT (notification_type) DO NOTHING;