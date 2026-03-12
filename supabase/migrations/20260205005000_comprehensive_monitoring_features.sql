-- Phase 5: Comprehensive Monitoring & System Health Migration
-- Timestamp: 20260205005000
-- Description: Real-time system monitoring, integration health, performance metrics, automated alerting

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.integration_status CASCADE;
CREATE TYPE public.integration_status AS ENUM (
  'healthy',
  'degraded',
  'down',
  'maintenance'
);

DROP TYPE IF EXISTS public.alert_severity CASCADE;
CREATE TYPE public.alert_severity AS ENUM (
  'info',
  'warning',
  'critical',
  'emergency'
);

DROP TYPE IF EXISTS public.alert_status CASCADE;
CREATE TYPE public.alert_status AS ENUM (
  'active',
  'acknowledged',
  'resolved',
  'suppressed'
);

-- ============================================================
-- 2. INTEGRATION HEALTH MONITORING
-- ============================================================

CREATE TABLE IF NOT EXISTS public.integration_health (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_name TEXT NOT NULL,
  integration_type TEXT NOT NULL,
  status public.integration_status NOT NULL DEFAULT 'healthy',
  last_check_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  response_time_ms INTEGER,
  error_rate NUMERIC(5,2) DEFAULT 0.00,
  uptime_percentage NUMERIC(5,2) DEFAULT 100.00,
  last_error TEXT,
  last_error_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(integration_name)
);

CREATE INDEX idx_integration_health_status ON public.integration_health(status);
CREATE INDEX idx_integration_health_type ON public.integration_health(integration_type);
CREATE INDEX idx_integration_health_updated ON public.integration_health(updated_at DESC);

CREATE TABLE IF NOT EXISTS public.integration_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_name TEXT NOT NULL,
  metric_type TEXT NOT NULL,
  metric_value NUMERIC(12,2) NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_integration_metrics_name ON public.integration_metrics(integration_name);
CREATE INDEX idx_integration_metrics_type ON public.integration_metrics(metric_type);
CREATE INDEX idx_integration_metrics_timestamp ON public.integration_metrics(timestamp DESC);

-- ============================================================
-- 3. PERFORMANCE MONITORING
-- ============================================================

CREATE TABLE IF NOT EXISTS public.performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name TEXT NOT NULL,
  metric_category TEXT NOT NULL,
  current_value NUMERIC(12,2) NOT NULL,
  threshold_warning NUMERIC(12,2),
  threshold_critical NUMERIC(12,2),
  unit TEXT,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_performance_metrics_name ON public.performance_metrics(metric_name);
CREATE INDEX idx_performance_metrics_category ON public.performance_metrics(metric_category);
CREATE INDEX idx_performance_metrics_timestamp ON public.performance_metrics(timestamp DESC);

CREATE TABLE IF NOT EXISTS public.api_latency_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL,
  response_time_ms INTEGER NOT NULL,
  status_code INTEGER,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  error_message TEXT,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_api_latency_endpoint ON public.api_latency_tracking(endpoint);
CREATE INDEX idx_api_latency_timestamp ON public.api_latency_tracking(timestamp DESC);

CREATE TABLE IF NOT EXISTS public.database_performance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  query_type TEXT NOT NULL,
  execution_time_ms INTEGER NOT NULL,
  rows_affected INTEGER,
  connection_pool_size INTEGER,
  active_connections INTEGER,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_database_performance_timestamp ON public.database_performance(timestamp DESC);

-- ============================================================
-- 4. AUTOMATED ALERTING SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.system_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type TEXT NOT NULL,
  severity public.alert_severity NOT NULL,
  status public.alert_status NOT NULL DEFAULT 'active',
  title TEXT NOT NULL,
  description TEXT,
  source_system TEXT NOT NULL,
  affected_component TEXT,
  error_details JSONB DEFAULT '{}'::jsonb,
  acknowledged_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  acknowledged_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_system_alerts_severity ON public.system_alerts(severity);
CREATE INDEX idx_system_alerts_status ON public.system_alerts(status);
CREATE INDEX idx_system_alerts_created ON public.system_alerts(created_at DESC);

CREATE TABLE IF NOT EXISTS public.alert_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_name TEXT NOT NULL UNIQUE,
  metric_name TEXT NOT NULL,
  condition TEXT NOT NULL,
  threshold_value NUMERIC(12,2) NOT NULL,
  severity public.alert_severity NOT NULL,
  is_enabled BOOLEAN DEFAULT true,
  notification_channels TEXT[] DEFAULT ARRAY['dashboard']::TEXT[],
  cooldown_minutes INTEGER DEFAULT 5,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_alert_rules_enabled ON public.alert_rules(is_enabled);

-- ============================================================
-- 5. SYSTEM HEALTH DASHBOARD DATA
-- ============================================================

CREATE TABLE IF NOT EXISTS public.system_health_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  overall_health_score INTEGER NOT NULL CHECK (overall_health_score >= 0 AND overall_health_score <= 100),
  active_integrations INTEGER DEFAULT 0,
  healthy_integrations INTEGER DEFAULT 0,
  degraded_integrations INTEGER DEFAULT 0,
  down_integrations INTEGER DEFAULT 0,
  active_alerts INTEGER DEFAULT 0,
  critical_alerts INTEGER DEFAULT 0,
  avg_api_latency_ms INTEGER,
  error_rate NUMERIC(5,2) DEFAULT 0.00,
  uptime_percentage NUMERIC(5,2) DEFAULT 100.00,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_system_health_snapshots_timestamp ON public.system_health_snapshots(timestamp DESC);

-- ============================================================
-- 6. EMERGENCY CONTROLS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.emergency_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action_type TEXT NOT NULL,
  action_name TEXT NOT NULL,
  triggered_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  reason TEXT NOT NULL,
  affected_systems TEXT[],
  is_active BOOLEAN DEFAULT true,
  activated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  deactivated_at TIMESTAMPTZ,
  deactivated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_emergency_actions_active ON public.emergency_actions(is_active);
CREATE INDEX idx_emergency_actions_activated ON public.emergency_actions(activated_at DESC);

-- ============================================================
-- 7. SEED DATA - INTEGRATION HEALTH TRACKING
-- ============================================================

INSERT INTO public.integration_health (integration_name, integration_type, status, response_time_ms, uptime_percentage)
VALUES
  ('Supabase Database', 'database', 'healthy', 45, 99.98),
  ('Supabase Auth', 'authentication', 'healthy', 120, 99.95),
  ('Supabase Storage', 'storage', 'healthy', 180, 99.90),
  ('OpenAI API', 'ai_service', 'healthy', 850, 99.85),
  ('Anthropic Claude', 'ai_service', 'healthy', 920, 99.80),
  ('Perplexity API', 'ai_service', 'healthy', 780, 99.75),
  ('Stripe Payments', 'payment', 'healthy', 320, 99.99),
  ('Twilio Notifications', 'notification', 'healthy', 250, 99.92),
  ('Google Maps', 'location', 'healthy', 210, 99.88),
  ('Google AdSense', 'advertising', 'healthy', 340, 99.70)
ON CONFLICT (integration_name) DO NOTHING;

-- ============================================================
-- 8. SEED DATA - ALERT RULES
-- ============================================================

INSERT INTO public.alert_rules (rule_name, metric_name, condition, threshold_value, severity, notification_channels)
VALUES
  ('High API Latency', 'api_response_time_ms', 'greater_than', 2000, 'warning', ARRAY['dashboard', 'email']),
  ('Critical API Latency', 'api_response_time_ms', 'greater_than', 5000, 'critical', ARRAY['dashboard', 'email', 'sms']),
  ('High Error Rate', 'error_rate_percentage', 'greater_than', 5.0, 'warning', ARRAY['dashboard', 'email']),
  ('Critical Error Rate', 'error_rate_percentage', 'greater_than', 10.0, 'critical', ARRAY['dashboard', 'email', 'sms']),
  ('Integration Down', 'integration_status', 'equals', 0, 'emergency', ARRAY['dashboard', 'email', 'sms', 'slack']),
  ('Database Connection Pool Full', 'db_connection_pool_usage', 'greater_than', 90.0, 'critical', ARRAY['dashboard', 'email']),
  ('Low Uptime', 'uptime_percentage', 'less_than', 99.0, 'warning', ARRAY['dashboard', 'email'])
ON CONFLICT (rule_name) DO NOTHING;

-- ============================================================
-- 9. RLS POLICIES
-- ============================================================

ALTER TABLE public.integration_health ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_latency_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.database_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_health_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emergency_actions ENABLE ROW LEVEL SECURITY;

-- Admin-only access for monitoring tables
CREATE POLICY "Admin full access to integration_health"
  ON public.integration_health
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admin full access to system_alerts"
  ON public.system_alerts
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admin full access to emergency_actions"
  ON public.emergency_actions
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Read-only access for performance metrics (all authenticated users)
CREATE POLICY "Authenticated users can view performance_metrics"
  ON public.performance_metrics
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can view system_health_snapshots"
  ON public.system_health_snapshots
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- ============================================================
-- 10. DATABASE FUNCTIONS
-- ============================================================

-- Function to get current system health overview
CREATE OR REPLACE FUNCTION public.get_system_health_overview()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'overall_status', CASE
      WHEN COUNT(*) FILTER (WHERE status = 'down') > 0 THEN 'critical'
      WHEN COUNT(*) FILTER (WHERE status = 'degraded') > 0 THEN 'warning'
      ELSE 'healthy'
    END,
    'total_integrations', COUNT(*),
    'healthy_count', COUNT(*) FILTER (WHERE status = 'healthy'),
    'degraded_count', COUNT(*) FILTER (WHERE status = 'degraded'),
    'down_count', COUNT(*) FILTER (WHERE status = 'down'),
    'avg_response_time_ms', ROUND(AVG(response_time_ms)),
    'avg_uptime_percentage', ROUND(AVG(uptime_percentage), 2),
    'last_updated', MAX(updated_at)
  )
  INTO result
  FROM public.integration_health;
  
  RETURN result;
END;
$$;

-- Function to get active alerts summary
CREATE OR REPLACE FUNCTION public.get_active_alerts_summary()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_active', COUNT(*) FILTER (WHERE status = 'active'),
    'emergency_count', COUNT(*) FILTER (WHERE status = 'active' AND severity = 'emergency'),
    'critical_count', COUNT(*) FILTER (WHERE status = 'active' AND severity = 'critical'),
    'warning_count', COUNT(*) FILTER (WHERE status = 'active' AND severity = 'warning'),
    'info_count', COUNT(*) FILTER (WHERE status = 'active' AND severity = 'info'),
    'oldest_unresolved', MIN(created_at) FILTER (WHERE status = 'active')
  )
  INTO result
  FROM public.system_alerts;
  
  RETURN result;
END;
$$;

-- Function to get integration performance trends
CREATE OR REPLACE FUNCTION public.get_integration_performance_trends(
  p_integration_name TEXT,
  p_hours INTEGER DEFAULT 24
)
RETURNS TABLE (
  hour TIMESTAMPTZ,
  avg_response_time NUMERIC,
  error_count BIGINT,
  success_rate NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    date_trunc('hour', timestamp) AS hour,
    ROUND(AVG(metric_value), 2) AS avg_response_time,
    COUNT(*) FILTER (WHERE metric_type = 'error') AS error_count,
    ROUND(
      (COUNT(*) FILTER (WHERE metric_type = 'success')::NUMERIC / NULLIF(COUNT(*), 0)) * 100,
      2
    ) AS success_rate
  FROM public.integration_metrics
  WHERE integration_name = p_integration_name
    AND timestamp >= NOW() - (p_hours || ' hours')::INTERVAL
  GROUP BY date_trunc('hour', timestamp)
  ORDER BY hour DESC;
END;
$$;

-- Function to record integration health check
CREATE OR REPLACE FUNCTION public.record_integration_health_check(
  p_integration_name TEXT,
  p_status public.integration_status,
  p_response_time_ms INTEGER,
  p_error_message TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_health_id UUID;
BEGIN
  INSERT INTO public.integration_health (
    integration_name,
    integration_type,
    status,
    response_time_ms,
    last_check_at,
    last_error,
    last_error_at,
    updated_at
  )
  VALUES (
    p_integration_name,
    'external_service',
    p_status,
    p_response_time_ms,
    NOW(),
    p_error_message,
    CASE WHEN p_error_message IS NOT NULL THEN NOW() ELSE NULL END,
    NOW()
  )
  ON CONFLICT (integration_name)
  DO UPDATE SET
    status = EXCLUDED.status,
    response_time_ms = EXCLUDED.response_time_ms,
    last_check_at = EXCLUDED.last_check_at,
    last_error = EXCLUDED.last_error,
    last_error_at = EXCLUDED.last_error_at,
    updated_at = EXCLUDED.updated_at
  RETURNING id INTO v_health_id;
  
  RETURN v_health_id;
END;
$$;

-- Function to create system alert
CREATE OR REPLACE FUNCTION public.create_system_alert(
  p_alert_type TEXT,
  p_severity public.alert_severity,
  p_title TEXT,
  p_description TEXT,
  p_source_system TEXT,
  p_affected_component TEXT DEFAULT NULL,
  p_error_details JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_alert_id UUID;
BEGIN
  INSERT INTO public.system_alerts (
    alert_type,
    severity,
    title,
    description,
    source_system,
    affected_component,
    error_details
  )
  VALUES (
    p_alert_type,
    p_severity,
    p_title,
    p_description,
    p_source_system,
    p_affected_component,
    p_error_details
  )
  RETURNING id INTO v_alert_id;
  
  RETURN v_alert_id;
END;
$$;

-- ============================================================
-- 11. TRIGGERS
-- ============================================================

-- Trigger to update integration_health updated_at
CREATE OR REPLACE FUNCTION public.update_integration_health_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_update_integration_health_timestamp
  BEFORE UPDATE ON public.integration_health
  FOR EACH ROW
  EXECUTE FUNCTION public.update_integration_health_timestamp();

-- Trigger to update system_alerts updated_at
CREATE TRIGGER trigger_update_system_alerts_timestamp
  BEFORE UPDATE ON public.system_alerts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_integration_health_timestamp();

-- ============================================================
-- MIGRATION COMPLETE
-- ============================================================