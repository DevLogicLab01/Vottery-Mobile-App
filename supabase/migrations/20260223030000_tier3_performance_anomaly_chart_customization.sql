-- TIER 3: Enhanced Performance Anomaly Detection, Advanced Chart Customization, Mobile Performance Optimization
-- Migration: 20260223030000_tier3_performance_anomaly_chart_customization.sql

-- =====================================================
-- DROP EXISTING OBJECTS (IDEMPOTENT CLEANUP)
-- =====================================================

-- Drop functions first (they may depend on tables)
DROP FUNCTION IF EXISTS public.get_mobile_performance_summary(INTEGER);
DROP FUNCTION IF EXISTS public.determine_anomaly_severity(NUMERIC);
DROP FUNCTION IF EXISTS public.calculate_baseline_confidence(INTEGER);
DROP FUNCTION IF EXISTS public.get_detection_statistics();

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS public.mobile_performance_metrics CASCADE;
DROP TABLE IF EXISTS public.chart_drill_down_sessions CASCADE;
DROP TABLE IF EXISTS public.dashboard_filters CASCADE;
DROP TABLE IF EXISTS public.user_chart_preferences CASCADE;
DROP TABLE IF EXISTS public.chart_anomalies CASCADE;
DROP TABLE IF EXISTS public.anomaly_acknowledgments CASCADE;
DROP TABLE IF EXISTS public.performance_baselines_history CASCADE;
DROP TABLE IF EXISTS public.performance_anomalies CASCADE;

-- =====================================================
-- PERFORMANCE ANOMALIES (for anomaly detection service)
-- =====================================================

CREATE TABLE public.performance_anomalies (
  anomaly_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_name TEXT NOT NULL,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  baseline_p95_ms NUMERIC NOT NULL,
  current_p95_ms NUMERIC NOT NULL,
  deviation_percentage NUMERIC NOT NULL,
  severity TEXT NOT NULL,
  alert_sent BOOLEAN DEFAULT FALSE,
  acknowledged BOOLEAN DEFAULT FALSE,
  acknowledged_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  acknowledged_at TIMESTAMPTZ,
  acknowledgment_notes TEXT,
  affected_requests INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_performance_anomalies_operation ON public.performance_anomalies(operation_name);
CREATE INDEX idx_performance_anomalies_detected_at ON public.performance_anomalies(detected_at DESC);
CREATE INDEX idx_performance_anomalies_acknowledged ON public.performance_anomalies(acknowledged);
CREATE INDEX idx_performance_anomalies_severity ON public.performance_anomalies(severity);

-- =====================================================
-- PERFORMANCE BASELINES HISTORY
-- =====================================================

CREATE TABLE public.performance_baselines_history (
  history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  baseline_id UUID,
  operation_name TEXT NOT NULL,
  operation_type TEXT NOT NULL,
  p50_baseline_ms NUMERIC NOT NULL,
  p95_baseline_ms NUMERIC NOT NULL,
  p99_baseline_ms NUMERIC NOT NULL,
  sample_count INTEGER NOT NULL,
  confidence_score NUMERIC NOT NULL DEFAULT 0,
  effective_date DATE NOT NULL,
  replaced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_baselines_history_baseline_id ON public.performance_baselines_history(baseline_id);
CREATE INDEX idx_baselines_history_effective_date ON public.performance_baselines_history(effective_date DESC);

-- =====================================================
-- ANOMALY ACKNOWLEDGMENTS
-- =====================================================

CREATE TABLE public.anomaly_acknowledgments (
  ack_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anomaly_id UUID,
  acknowledged_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  acknowledgment_notes TEXT,
  notification_channel TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_anomaly_acks_anomaly_id ON public.anomaly_acknowledgments(anomaly_id);
CREATE INDEX idx_anomaly_acks_acknowledged_by ON public.anomaly_acknowledgments(acknowledged_by);

-- =====================================================
-- CHART ANOMALIES
-- =====================================================

CREATE TABLE public.chart_anomalies (
  anomaly_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chart_id TEXT NOT NULL,
  data_point_id TEXT,
  data_point_timestamp TIMESTAMPTZ NOT NULL,
  data_point_value NUMERIC NOT NULL,
  anomaly_type TEXT NOT NULL,
  z_score NUMERIC,
  explanation TEXT NOT NULL,
  business_cause TEXT,
  confidence NUMERIC NOT NULL,
  recommended_action TEXT,
  investigated BOOLEAN DEFAULT FALSE,
  investigated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  investigated_at TIMESTAMPTZ,
  investigation_notes TEXT,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chart_anomalies_chart_id ON public.chart_anomalies(chart_id);
CREATE INDEX idx_chart_anomalies_detected_at ON public.chart_anomalies(detected_at DESC);
CREATE INDEX idx_chart_anomalies_investigated ON public.chart_anomalies(investigated);

-- =====================================================
-- USER CHART PREFERENCES
-- =====================================================

CREATE TABLE public.user_chart_preferences (
  preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  chart_id TEXT NOT NULL,
  preferences JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, chart_id)
);

CREATE INDEX idx_chart_prefs_user_id ON public.user_chart_preferences(user_id);
CREATE INDEX idx_chart_prefs_chart_id ON public.user_chart_preferences(chart_id);

-- =====================================================
-- DASHBOARD FILTERS
-- =====================================================

CREATE TABLE public.dashboard_filters (
  filter_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  dashboard_id TEXT NOT NULL,
  filter_config JSONB NOT NULL DEFAULT '{}',
  saved_name TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dashboard_filters_user_id ON public.dashboard_filters(user_id);
CREATE INDEX idx_dashboard_filters_dashboard_id ON public.dashboard_filters(dashboard_id);

-- =====================================================
-- CHART DRILL DOWN SESSIONS
-- =====================================================

CREATE TABLE public.chart_drill_down_sessions (
  session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  chart_id TEXT NOT NULL,
  drill_down_path JSONB NOT NULL DEFAULT '[]',
  current_level INTEGER NOT NULL DEFAULT 0,
  applied_filters JSONB NOT NULL DEFAULT '{}',
  session_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_activity TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_drill_down_user_id ON public.chart_drill_down_sessions(user_id);
CREATE INDEX idx_drill_down_chart_id ON public.chart_drill_down_sessions(chart_id);

-- =====================================================
-- MOBILE PERFORMANCE METRICS
-- =====================================================

CREATE TABLE public.mobile_performance_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  platform TEXT NOT NULL,
  load_time_ms INTEGER NOT NULL,
  bundle_size_kb INTEGER,
  image_load_time_ms INTEGER,
  api_call_time_ms INTEGER,
  render_time_ms INTEGER,
  memory_usage_mb NUMERIC,
  network_type TEXT,
  device_model TEXT,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mobile_perf_screen_name ON public.mobile_performance_metrics(screen_name);
CREATE INDEX idx_mobile_perf_platform ON public.mobile_performance_metrics(platform);
CREATE INDEX idx_mobile_perf_recorded_at ON public.mobile_performance_metrics(recorded_at DESC);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Performance baselines history policies
ALTER TABLE public.performance_baselines_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage baselines history"
ON public.performance_baselines_history FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role IN ('super_admin', 'devops_admin')
  )
);

CREATE POLICY "All users can view baselines history"
ON public.performance_baselines_history FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Anomaly acknowledgments policies
ALTER TABLE public.anomaly_acknowledgments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can acknowledge anomalies"
ON public.anomaly_acknowledgments FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can view acknowledgments"
ON public.anomaly_acknowledgments FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Chart anomalies policies
ALTER TABLE public.chart_anomalies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view chart anomalies"
ON public.chart_anomalies FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can investigate anomalies"
ON public.chart_anomalies FOR UPDATE
USING (auth.uid() IS NOT NULL)
WITH CHECK (auth.uid() IS NOT NULL);

-- User chart preferences policies
ALTER TABLE public.user_chart_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own chart preferences"
ON public.user_chart_preferences FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Dashboard filters policies
ALTER TABLE public.dashboard_filters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own dashboard filters"
ON public.dashboard_filters FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Chart drill down sessions policies
ALTER TABLE public.chart_drill_down_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own drill down sessions"
ON public.chart_drill_down_sessions FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Mobile performance metrics policies
ALTER TABLE public.mobile_performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All users can insert performance metrics"
ON public.mobile_performance_metrics FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "All users can view performance metrics"
ON public.mobile_performance_metrics FOR SELECT
USING (auth.uid() IS NOT NULL);

-- Performance anomalies policies
ALTER TABLE public.performance_anomalies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view performance anomalies"
ON public.performance_anomalies FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE POLICY "System can insert performance anomalies"
ON public.performance_anomalies FOR INSERT
WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can acknowledge performance anomalies"
ON public.performance_anomalies FOR UPDATE
USING (auth.uid() IS NOT NULL)
WITH CHECK (auth.uid() IS NOT NULL);

-- =====================================================
-- UTILITY FUNCTIONS (NO TABLE DEPENDENCIES)
-- =====================================================

-- Calculate baseline confidence score
CREATE FUNCTION public.calculate_baseline_confidence(sample_count INTEGER)
RETURNS NUMERIC AS $$
BEGIN
  IF sample_count > 1000 THEN
    RETURN 0.95;
  ELSIF sample_count > 500 THEN
    RETURN 0.75;
  ELSE
    RETURN 0.50;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Determine anomaly severity
CREATE FUNCTION public.determine_anomaly_severity(deviation_percentage NUMERIC)
RETURNS TEXT AS $$
BEGIN
  IF deviation_percentage > 200 THEN
    RETURN 'critical';
  ELSIF deviation_percentage > 150 THEN
    RETURN 'high';
  ELSE
    RETURN 'medium';
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Get mobile performance summary
CREATE FUNCTION public.get_mobile_performance_summary(hours INTEGER DEFAULT 24)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'avg_load_time', COALESCE(AVG(load_time_ms)::INTEGER, 0),
    'performance_score', CASE
      WHEN AVG(load_time_ms) < 1000 THEN 95
      WHEN AVG(load_time_ms) < 2000 THEN 85
      WHEN AVG(load_time_ms) < 3000 THEN 75
      ELSE 60
    END,
    'critical_alerts', (
      SELECT COUNT(*) FROM public.mobile_performance_metrics
      WHERE load_time_ms > 5000
      AND recorded_at >= NOW() - (hours || ' hours')::INTERVAL
    ),
    'slowest_screens', (
      SELECT COUNT(DISTINCT screen_name) FROM public.mobile_performance_metrics
      WHERE load_time_ms > 3000
      AND recorded_at >= NOW() - (hours || ' hours')::INTERVAL
    )
  ) INTO result
  FROM public.mobile_performance_metrics
  WHERE recorded_at >= NOW() - (hours || ' hours')::INTERVAL;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;