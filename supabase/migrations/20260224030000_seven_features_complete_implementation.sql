-- ============================================================
-- COMPREHENSIVE 7 FEATURES MIGRATION
-- Google Analytics, Blockchain Voting, Claude Feed Curation,
-- Perplexity Log Analysis, System Monitoring, Performance Dashboard,
-- Gemini Cost Analyzer
-- ============================================================

-- ============================================================
-- FEATURE 1: GOOGLE ANALYTICS FULL INTEGRATION
-- ============================================================

-- Google Analytics Events Table
CREATE TABLE IF NOT EXISTS public.google_analytics_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  event_name VARCHAR(255) NOT NULL,
  event_parameters JSONB,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  synced_to_ga4 BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Analytics Attribution Table
CREATE TABLE IF NOT EXISTS public.analytics_attribution (
  attribution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  utm_source VARCHAR(255),
  utm_medium VARCHAR(255),
  utm_campaign VARCHAR(255),
  utm_content VARCHAR(255),
  first_touch_at TIMESTAMPTZ,
  last_touch_at TIMESTAMPTZ,
  user_properties JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Indexes for Google Analytics
CREATE INDEX IF NOT EXISTS idx_ga_events_user_id ON public.google_analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_ga_events_timestamp ON public.google_analytics_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ga_events_synced ON public.google_analytics_events(synced_to_ga4);
CREATE INDEX IF NOT EXISTS idx_analytics_attribution_user ON public.analytics_attribution(user_id);

-- RLS Policies for Google Analytics
ALTER TABLE public.google_analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analytics_attribution ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own analytics events" ON public.google_analytics_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own analytics events" ON public.google_analytics_events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own attribution" ON public.analytics_attribution
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can upsert own attribution" ON public.analytics_attribution
  FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- FEATURE 2: BLOCKCHAIN VOTING CRYPTOGRAPHIC RECEIPTS
-- ============================================================

-- Vote Receipts Table
CREATE TABLE IF NOT EXISTS public.vote_receipts (
  receipt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID REFERENCES public.elections(id) ON DELETE CASCADE,
  vote_hash VARCHAR(255) NOT NULL,
  blockchain_tx_hash VARCHAR(255) NOT NULL,
  block_number BIGINT NOT NULL,
  receipt_data JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Vote Receipts
CREATE INDEX IF NOT EXISTS idx_vote_receipts_user ON public.vote_receipts(user_id);
CREATE INDEX IF NOT EXISTS idx_vote_receipts_election ON public.vote_receipts(election_id);
CREATE INDEX IF NOT EXISTS idx_vote_receipts_tx_hash ON public.vote_receipts(blockchain_tx_hash);
CREATE INDEX IF NOT EXISTS idx_vote_receipts_created ON public.vote_receipts(created_at DESC);

-- RLS Policies for Vote Receipts
ALTER TABLE public.vote_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own receipts" ON public.vote_receipts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own receipts" ON public.vote_receipts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Function to get receipt analytics
CREATE OR REPLACE FUNCTION public.get_receipt_analytics()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_receipts', COUNT(*),
    'verified_receipts', COUNT(*),
    'adoption_rate', (COUNT(*)::FLOAT / NULLIF((SELECT COUNT(*) FROM public.votes), 0) * 100)
  )
  INTO result
  FROM public.vote_receipts;
  
  RETURN result;
END;
$$;

-- ============================================================
-- FEATURE 3: CLAUDE FEED CURATION PERSONALIZATION
-- ============================================================

-- User Content Preferences Table
CREATE TABLE IF NOT EXISTS public.user_content_preferences (
  preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content_type VARCHAR(50) NOT NULL,
  content_id UUID NOT NULL,
  action VARCHAR(50) NOT NULL,
  reason VARCHAR(255),
  preference_score INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feed Ranking Cache Table
CREATE TABLE IF NOT EXISTS public.feed_ranking_cache (
  cache_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content_type VARCHAR(50) NOT NULL,
  ranked_feed_items TEXT NOT NULL,
  ranking_metadata JSONB,
  cached_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  UNIQUE(user_id, content_type)
);

-- Claude Curation Analytics Table
CREATE TABLE IF NOT EXISTS public.claude_curation_analytics (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  prediction_accuracy DECIMAL(5,2),
  engagement_lift DECIMAL(5,2),
  ranking_cost_tokens INTEGER,
  ranking_latency_ms INTEGER,
  ranked_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Claude Feed Curation
CREATE INDEX IF NOT EXISTS idx_user_content_prefs_user ON public.user_content_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_content_prefs_content ON public.user_content_preferences(content_id);
CREATE INDEX IF NOT EXISTS idx_feed_ranking_cache_user ON public.feed_ranking_cache(user_id);
CREATE INDEX IF NOT EXISTS idx_feed_ranking_cache_expires ON public.feed_ranking_cache(expires_at);
CREATE INDEX IF NOT EXISTS idx_claude_curation_analytics_user ON public.claude_curation_analytics(user_id);

-- RLS Policies for Claude Feed Curation
ALTER TABLE public.user_content_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_ranking_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.claude_curation_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own content preferences" ON public.user_content_preferences
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own feed cache" ON public.feed_ranking_cache
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can manage feed cache" ON public.feed_ranking_cache
  FOR ALL USING (true);

CREATE POLICY "Users can view own curation analytics" ON public.claude_curation_analytics
  FOR SELECT USING (auth.uid() = user_id);

-- ============================================================
-- FEATURE 4: PERPLEXITY LOG ANALYSIS INTEGRATION
-- ============================================================

-- Log Analysis Results Table
CREATE TABLE IF NOT EXISTS public.log_analysis_results (
  analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_window_start TIMESTAMPTZ NOT NULL,
  analysis_window_end TIMESTAMPTZ NOT NULL,
  log_count INTEGER NOT NULL,
  threats_detected JSONB,
  overall_threat_score INTEGER DEFAULT 0,
  analyzed_at TIMESTAMPTZ DEFAULT NOW(),
  analyzed_by VARCHAR(50) DEFAULT 'perplexity'
);

-- Security Incidents Table
CREATE TABLE IF NOT EXISTS public.security_incidents (
  incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  threat_type VARCHAR(255) NOT NULL,
  severity VARCHAR(50) NOT NULL,
  confidence DECIMAL(3,2),
  affected_users UUID[],
  affected_entities JSONB,
  evidence_logs JSONB,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'open',
  assigned_to UUID REFERENCES public.user_profiles(id),
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT
);

-- Threat Log Table
CREATE TABLE IF NOT EXISTS public.threat_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  threat_type VARCHAR(255) NOT NULL,
  severity VARCHAR(50) NOT NULL,
  confidence DECIMAL(3,2),
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Perplexity Log Analysis
CREATE INDEX IF NOT EXISTS idx_log_analysis_results_window ON public.log_analysis_results(analysis_window_start, analysis_window_end);
CREATE INDEX IF NOT EXISTS idx_log_analysis_results_analyzed ON public.log_analysis_results(analyzed_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_incidents_status ON public.security_incidents(status);
CREATE INDEX IF NOT EXISTS idx_security_incidents_severity ON public.security_incidents(severity);
CREATE INDEX IF NOT EXISTS idx_security_incidents_detected ON public.security_incidents(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_threat_log_logged ON public.threat_log(logged_at DESC);

-- RLS Policies for Perplexity Log Analysis
ALTER TABLE public.log_analysis_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.threat_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view log analysis" ON public.log_analysis_results
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can manage security incidents" ON public.security_incidents
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can view threat log" ON public.threat_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- FEATURE 5: REAL-TIME SYSTEM MONITORING DASHBOARD
-- ============================================================

-- Service Health Metrics Table
CREATE TABLE IF NOT EXISTS public.service_health_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name VARCHAR(100) NOT NULL,
  metric_type VARCHAR(100) NOT NULL,
  metric_value DECIMAL(10,2),
  health_score INTEGER DEFAULT 0,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- System Alerts Table
CREATE TABLE IF NOT EXISTS public.system_alerts (
  alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type VARCHAR(255) NOT NULL,
  severity VARCHAR(50) NOT NULL,
  service_name VARCHAR(100),
  alert_message TEXT,
  triggered_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged_by UUID REFERENCES public.user_profiles(id),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for System Monitoring
CREATE INDEX IF NOT EXISTS idx_service_health_metrics_service ON public.service_health_metrics(service_name);
CREATE INDEX IF NOT EXISTS idx_service_health_metrics_recorded ON public.service_health_metrics(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_system_alerts_status ON public.system_alerts(status);
CREATE INDEX IF NOT EXISTS idx_system_alerts_severity ON public.system_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_system_alerts_triggered ON public.system_alerts(triggered_at DESC);

-- RLS Policies for System Monitoring
ALTER TABLE public.service_health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view health metrics" ON public.service_health_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can insert health metrics" ON public.service_health_metrics
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage system alerts" ON public.system_alerts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- FEATURE 6: APP PERFORMANCE DASHBOARD UNIFIED
-- ============================================================

-- Unified Performance Metrics Table
CREATE TABLE IF NOT EXISTS public.unified_performance_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_category VARCHAR(100) NOT NULL,
  metric_name VARCHAR(255) NOT NULL,
  metric_value DECIMAL(10,2),
  device_model VARCHAR(255),
  user_id UUID REFERENCES public.user_profiles(id),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance Alerts Table
CREATE TABLE IF NOT EXISTS public.performance_alerts (
  alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type VARCHAR(255) NOT NULL,
  metric_name VARCHAR(255) NOT NULL,
  current_value DECIMAL(10,2),
  threshold_value DECIMAL(10,2),
  predicted_at TIMESTAMPTZ,
  triggered_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Performance Dashboard
CREATE INDEX IF NOT EXISTS idx_unified_perf_metrics_category ON public.unified_performance_metrics(metric_category);
CREATE INDEX IF NOT EXISTS idx_unified_perf_metrics_recorded ON public.unified_performance_metrics(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_unified_perf_metrics_user ON public.unified_performance_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_alerts_triggered ON public.performance_alerts(triggered_at DESC);

-- RLS Policies for Performance Dashboard
ALTER TABLE public.unified_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own performance metrics" ON public.unified_performance_metrics
  FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "System can insert performance metrics" ON public.unified_performance_metrics
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can view performance alerts" ON public.performance_alerts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- FEATURE 7: GEMINI COST-EFFICIENCY ANALYZER
-- ============================================================

-- Gemini Opportunity Reports Table
CREATE TABLE IF NOT EXISTS public.gemini_opportunity_reports (
  report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_period_start DATE NOT NULL,
  analysis_period_end DATE NOT NULL,
  current_monthly_cost DECIMAL(10,2),
  projected_gemini_cost DECIMAL(10,2),
  potential_savings DECIMAL(10,2),
  task_analysis TEXT,
  recommendations TEXT,
  generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cost Optimization Approvals Table
CREATE TABLE IF NOT EXISTS public.cost_optimization_approvals (
  approval_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID REFERENCES public.gemini_opportunity_reports(report_id) ON DELETE CASCADE,
  approved_by UUID REFERENCES public.user_profiles(id),
  approval_status VARCHAR(50) DEFAULT 'pending',
  implementation_plan TEXT,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Gemini Cost Analyzer
CREATE INDEX IF NOT EXISTS idx_gemini_reports_generated ON public.gemini_opportunity_reports(generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_cost_approvals_status ON public.cost_optimization_approvals(approval_status);
CREATE INDEX IF NOT EXISTS idx_cost_approvals_report ON public.cost_optimization_approvals(report_id);

-- RLS Policies for Gemini Cost Analyzer
ALTER TABLE public.gemini_opportunity_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cost_optimization_approvals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view cost reports" ON public.gemini_opportunity_reports
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can insert cost reports" ON public.gemini_opportunity_reports
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage cost approvals" ON public.cost_optimization_approvals
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- GRANT PERMISSIONS
-- ============================================================

GRANT ALL ON public.google_analytics_events TO authenticated;
GRANT ALL ON public.analytics_attribution TO authenticated;
GRANT ALL ON public.vote_receipts TO authenticated;
GRANT ALL ON public.user_content_preferences TO authenticated;
GRANT ALL ON public.feed_ranking_cache TO authenticated;
GRANT ALL ON public.claude_curation_analytics TO authenticated;
GRANT ALL ON public.log_analysis_results TO authenticated;
GRANT ALL ON public.security_incidents TO authenticated;
GRANT ALL ON public.threat_log TO authenticated;
GRANT ALL ON public.service_health_metrics TO authenticated;
GRANT ALL ON public.system_alerts TO authenticated;
GRANT ALL ON public.unified_performance_metrics TO authenticated;
GRANT ALL ON public.performance_alerts TO authenticated;
GRANT ALL ON public.gemini_opportunity_reports TO authenticated;
GRANT ALL ON public.cost_optimization_approvals TO authenticated;
