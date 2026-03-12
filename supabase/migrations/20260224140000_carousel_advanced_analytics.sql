-- Carousel Advanced Analytics Migration
-- Features: Performance Analytics, ROI Analytics, Health & Scaling
-- Created: 2026-02-24

-- ============================================
-- FEATURE 1: CAROUSEL PERFORMANCE ANALYTICS
-- ============================================

-- Funnel Events Tracking
CREATE TABLE IF NOT EXISTS public.carousel_funnel_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  session_id UUID NOT NULL,
  carousel_type VARCHAR(50) NOT NULL CHECK (carousel_type IN ('horizontal_snap', 'vertical_stack', 'gradient_flow')),
  content_type VARCHAR(50),
  content_id UUID,
  stage_name VARCHAR(50) NOT NULL CHECK (stage_name IN ('impression', 'view', 'interaction', 'detail_view', 'conversion')),
  timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  device_info JSONB,
  CONSTRAINT idx_funnel_events_unique UNIQUE (user_id, session_id, carousel_type, stage_name, timestamp)
);

CREATE INDEX IF NOT EXISTS idx_funnel_events_user_session ON public.carousel_funnel_events(user_id, session_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_funnel_events_carousel ON public.carousel_funnel_events(carousel_type, stage_name, timestamp);

-- Performance Baselines
CREATE TABLE IF NOT EXISTS public.carousel_performance_baselines (
  baseline_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50) NOT NULL,
  content_type VARCHAR(50),
  metric_name VARCHAR(100) NOT NULL,
  baseline_value DECIMAL(10,4) NOT NULL,
  sample_size INTEGER,
  calculation_period_start TIMESTAMPTZ NOT NULL,
  calculation_period_end TIMESTAMPTZ NOT NULL,
  calculated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_baselines_carousel_metric ON public.carousel_performance_baselines(carousel_type, content_type, metric_name);

-- Performance Alerts
CREATE TABLE IF NOT EXISTS public.carousel_performance_alerts (
  alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50) NOT NULL,
  content_type VARCHAR(50),
  metric_name VARCHAR(100) NOT NULL,
  baseline_value DECIMAL(10,4),
  current_value DECIMAL(10,4),
  regression_percentage DECIMAL(5,2) NOT NULL,
  severity VARCHAR(20) CHECK (severity IN ('minor', 'moderate', 'major', 'critical')),
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'investigating', 'resolved')),
  detected_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  acknowledged_by UUID REFERENCES public.user_profiles(id),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_alerts_status ON public.carousel_performance_alerts(status, severity, detected_at DESC);

-- Correlation Analysis
CREATE TABLE IF NOT EXISTS public.carousel_correlation_analysis (
  analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50),
  metric_x VARCHAR(100) NOT NULL,
  metric_y VARCHAR(100) NOT NULL,
  correlation_coefficient DECIMAL(5,4),
  p_value DECIMAL(10,8),
  sample_size INTEGER,
  analysis_period_start TIMESTAMPTZ,
  analysis_period_end TIMESTAMPTZ,
  insights TEXT,
  analyzed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_correlation_metrics ON public.carousel_correlation_analysis(metric_x, metric_y, analyzed_at DESC);

-- ============================================
-- FEATURE 2: CAROUSEL ROI ANALYTICS
-- ============================================

-- Transactions Tracking
CREATE TABLE IF NOT EXISTS public.carousel_transactions (
  transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50) NOT NULL,
  content_type VARCHAR(50),
  content_id UUID,
  transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('ad_revenue', 'sponsorship', 'creator_tip', 'premium_feature', 'marketplace_commission')),
  amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  currency VARCHAR(3) DEFAULT 'USD',
  user_id UUID REFERENCES public.user_profiles(id),
  creator_user_id UUID REFERENCES public.user_profiles(id),
  sponsor_id UUID,
  purchasing_power_zone VARCHAR(20),
  transaction_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_transactions_carousel ON public.carousel_transactions(carousel_type, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_creator ON public.carousel_transactions(creator_user_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_zone ON public.carousel_transactions(purchasing_power_zone, transaction_date);

-- Sponsorships
CREATE TABLE IF NOT EXISTS public.carousel_sponsorships (
  sponsorship_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sponsor_id UUID NOT NULL REFERENCES public.user_profiles(id),
  carousel_type VARCHAR(50) NOT NULL,
  content_id UUID NOT NULL,
  sponsorship_type VARCHAR(50) NOT NULL,
  investment_amount DECIMAL(10,2) NOT NULL,
  target_impressions INTEGER,
  impressions_delivered INTEGER DEFAULT 0,
  clicks_generated INTEGER DEFAULT 0,
  conversions_achieved INTEGER DEFAULT 0,
  revenue_generated DECIMAL(10,2) DEFAULT 0,
  campaign_start TIMESTAMPTZ NOT NULL,
  campaign_end TIMESTAMPTZ NOT NULL,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('pending', 'active', 'paused', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sponsorships_sponsor ON public.carousel_sponsorships(sponsor_id, status);
CREATE INDEX IF NOT EXISTS idx_sponsorships_dates ON public.carousel_sponsorships(campaign_start, campaign_end);

-- Revenue Forecasts
CREATE TABLE IF NOT EXISTS public.carousel_revenue_forecasts (
  forecast_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50),
  forecast_period VARCHAR(20) CHECK (forecast_period IN ('30_days', '90_days', '12_months')),
  predicted_revenue DECIMAL(12,2) NOT NULL,
  confidence_interval_lower DECIMAL(12,2),
  confidence_interval_upper DECIMAL(12,2),
  confidence_level DECIMAL(3,2),
  forecasting_model VARCHAR(50),
  input_data JSONB,
  generated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_forecasts_carousel ON public.carousel_revenue_forecasts(carousel_type, forecast_period, generated_at DESC);

-- ============================================
-- FEATURE 3: CAROUSEL HEALTH & SCALING
-- ============================================

-- Infrastructure Metrics
CREATE TABLE IF NOT EXISTS public.carousel_infrastructure_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_category VARCHAR(50) NOT NULL CHECK (metric_category IN ('database', 'application', 'cdn', 'cache')),
  metric_name VARCHAR(100) NOT NULL,
  metric_value DECIMAL(12,4) NOT NULL,
  threshold_warning DECIMAL(12,4),
  threshold_critical DECIMAL(12,4),
  unit VARCHAR(20),
  recorded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_infra_metrics ON public.carousel_infrastructure_metrics(metric_category, metric_name, recorded_at DESC);

-- Auto-Scaling Events
CREATE TABLE IF NOT EXISTS public.carousel_auto_scaling_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trigger_metric VARCHAR(100) NOT NULL,
  trigger_value DECIMAL(12,4) NOT NULL,
  threshold_value DECIMAL(12,4) NOT NULL,
  scaling_action VARCHAR(100) NOT NULL,
  action_result VARCHAR(20) CHECK (action_result IN ('success', 'failed', 'partial')),
  new_capacity JSONB,
  cost_impact DECIMAL(10,2),
  triggered_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  completed_at TIMESTAMPTZ,
  error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_scaling_events ON public.carousel_auto_scaling_events(triggered_at DESC);

-- Query Performance
CREATE TABLE IF NOT EXISTS public.carousel_query_performance (
  query_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  query_text TEXT NOT NULL,
  query_type VARCHAR(50),
  avg_execution_time_ms INTEGER NOT NULL,
  p95_execution_time_ms INTEGER,
  call_count INTEGER DEFAULT 0,
  total_time_ms BIGINT DEFAULT 0,
  last_execution TIMESTAMPTZ,
  optimization_applied BOOLEAN DEFAULT false,
  optimization_details JSONB
);

CREATE INDEX IF NOT EXISTS idx_query_perf ON public.carousel_query_performance(avg_execution_time_ms DESC, call_count DESC);

-- Bottlenecks
CREATE TABLE IF NOT EXISTS public.carousel_bottlenecks (
  bottleneck_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bottleneck_type VARCHAR(50) NOT NULL CHECK (bottleneck_type IN ('render', 'loading', 'query', 'network', 'memory')),
  carousel_type VARCHAR(50),
  severity VARCHAR(20) CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  affected_users_estimate INTEGER,
  latency_p50 INTEGER,
  latency_p95 INTEGER,
  latency_p99 INTEGER,
  root_cause TEXT,
  recommended_fixes JSONB,
  detected_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_bottlenecks_active ON public.carousel_bottlenecks(severity, detected_at DESC) WHERE resolved_at IS NULL;

-- Predictive Alerts
CREATE TABLE IF NOT EXISTS public.carousel_predictive_alerts (
  alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type VARCHAR(50) NOT NULL,
  metric_name VARCHAR(100) NOT NULL,
  current_value DECIMAL(12,4) NOT NULL,
  threshold_value DECIMAL(12,4) NOT NULL,
  predicted_violation_date TIMESTAMPTZ,
  confidence_level DECIMAL(3,2),
  trend_data JSONB,
  recommended_actions JSONB,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved', 'false_positive')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_predictive_alerts ON public.carousel_predictive_alerts(status, predicted_violation_date);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

ALTER TABLE public.carousel_funnel_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_performance_baselines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_performance_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_correlation_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_sponsorships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_revenue_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_infrastructure_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_auto_scaling_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_query_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_bottlenecks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_predictive_alerts ENABLE ROW LEVEL SECURITY;

-- Funnel Events Policies
CREATE POLICY "Users can view their own funnel events" ON public.carousel_funnel_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own funnel events" ON public.carousel_funnel_events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all funnel events" ON public.carousel_funnel_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Performance Baselines Policies (Admin only)
CREATE POLICY "Admins can manage baselines" ON public.carousel_performance_baselines
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Performance Alerts Policies (Admin only)
CREATE POLICY "Admins can manage alerts" ON public.carousel_performance_alerts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Correlation Analysis Policies (Admin only)
CREATE POLICY "Admins can view correlation analysis" ON public.carousel_correlation_analysis
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Transactions Policies
CREATE POLICY "Users can view their own transactions" ON public.carousel_transactions
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = creator_user_id);

CREATE POLICY "Admins can view all transactions" ON public.carousel_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Sponsorships Policies
CREATE POLICY "Sponsors can view their sponsorships" ON public.carousel_sponsorships
  FOR SELECT USING (auth.uid() = sponsor_id);

CREATE POLICY "Admins can manage sponsorships" ON public.carousel_sponsorships
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Revenue Forecasts Policies (Admin only)
CREATE POLICY "Admins can view forecasts" ON public.carousel_revenue_forecasts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Infrastructure Metrics Policies (Admin only)
CREATE POLICY "Admins can manage infrastructure metrics" ON public.carousel_infrastructure_metrics
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Auto-Scaling Events Policies (Admin only)
CREATE POLICY "Admins can view scaling events" ON public.carousel_auto_scaling_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Query Performance Policies (Admin only)
CREATE POLICY "Admins can manage query performance" ON public.carousel_query_performance
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Bottlenecks Policies (Admin only)
CREATE POLICY "Admins can manage bottlenecks" ON public.carousel_bottlenecks
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Predictive Alerts Policies (Admin only)
CREATE POLICY "Admins can manage predictive alerts" ON public.carousel_predictive_alerts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );
