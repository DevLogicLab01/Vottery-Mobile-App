-- Phase 5: Critical Features Implementation
-- Google Analytics, Blockchain Voting, Claude Feed Curation, Perplexity Log Analysis,
-- Real-time System Monitoring, App Performance Dashboard, Gemini Cost-Efficiency Analyzer

-- Drop existing tables if they exist
DROP TABLE IF EXISTS google_analytics_events CASCADE;
DROP TABLE IF EXISTS analytics_attribution CASCADE;
DROP TABLE IF EXISTS vote_receipts CASCADE;
DROP TABLE IF EXISTS feed_ranking_cache CASCADE;
DROP TABLE IF EXISTS user_content_preferences CASCADE;
DROP TABLE IF EXISTS log_analysis_results CASCADE;
DROP TABLE IF EXISTS security_incidents CASCADE;
DROP TABLE IF EXISTS service_health_metrics CASCADE;
DROP TABLE IF EXISTS system_alerts CASCADE;
DROP TABLE IF EXISTS unified_performance_metrics CASCADE;
DROP TABLE IF EXISTS performance_alerts CASCADE;
DROP TABLE IF EXISTS ai_service_costs CASCADE;
DROP TABLE IF EXISTS gemini_opportunity_reports CASCADE;
DROP TABLE IF EXISTS cost_optimization_approvals CASCADE;
DROP TABLE IF EXISTS claude_curation_analytics CASCADE;

-- FEATURE 1: Google Analytics Integration
CREATE TABLE google_analytics_events (
  event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  event_name VARCHAR(255) NOT NULL,
  event_parameters JSONB DEFAULT '{}'::jsonb,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  synced_to_ga4 BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE analytics_attribution (
  attribution_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  utm_source VARCHAR(255),
  utm_medium VARCHAR(255),
  utm_campaign VARCHAR(255),
  utm_content VARCHAR(255),
  first_touch_at TIMESTAMPTZ DEFAULT NOW(),
  last_touch_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- FEATURE 2: Blockchain Vote Receipts
CREATE TABLE vote_receipts (
  receipt_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  election_id UUID REFERENCES elections(id) ON DELETE CASCADE,
  vote_hash VARCHAR(255) NOT NULL UNIQUE,
  blockchain_tx_hash VARCHAR(255),
  block_number BIGINT,
  receipt_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- FEATURE 3: Claude Feed Curation
CREATE TABLE feed_ranking_cache (
  cache_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  ranked_feed_items JSONB DEFAULT '[]'::jsonb,
  ranking_metadata JSONB DEFAULT '{}'::jsonb,
  cached_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '15 minutes'
);

CREATE TABLE user_content_preferences (
  preference_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  content_type VARCHAR(100),
  content_id UUID,
  action VARCHAR(50), -- dismissed, liked, hidden
  reason VARCHAR(255),
  preference_score INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE claude_curation_analytics (
  analytics_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  prediction_accuracy DECIMAL(5,2),
  engagement_lift DECIMAL(5,2),
  ranking_cost_tokens INTEGER,
  ranking_latency_ms INTEGER,
  ranked_at TIMESTAMPTZ DEFAULT NOW()
);

-- FEATURE 4: Perplexity Log Analysis
CREATE TABLE log_analysis_results (
  analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  analysis_window_start TIMESTAMPTZ NOT NULL,
  analysis_window_end TIMESTAMPTZ NOT NULL,
  log_count INTEGER DEFAULT 0,
  threats_detected JSONB DEFAULT '[]'::jsonb,
  overall_threat_score INTEGER DEFAULT 0,
  analyzed_at TIMESTAMPTZ DEFAULT NOW(),
  analyzed_by VARCHAR(100) DEFAULT 'perplexity'
);

CREATE TABLE security_incidents (
  incident_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  threat_type VARCHAR(255) NOT NULL,
  severity VARCHAR(50) NOT NULL, -- critical, high, medium, low
  confidence DECIMAL(3,2),
  affected_users UUID[],
  affected_entities JSONB DEFAULT '{}'::jsonb,
  evidence_logs JSONB DEFAULT '[]'::jsonb,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'open', -- open, investigating, resolved
  assigned_to UUID REFERENCES user_profiles(id),
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT
);

-- FEATURE 5: Real-time System Monitoring
CREATE TABLE service_health_metrics (
  metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_name VARCHAR(100) NOT NULL, -- supabase, openai, anthropic, etc.
  metric_type VARCHAR(100) NOT NULL, -- uptime, latency, error_rate, cost
  metric_value DECIMAL(10,2),
  health_score INTEGER DEFAULT 100,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE system_alerts (
  alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alert_type VARCHAR(100) NOT NULL,
  severity VARCHAR(50) NOT NULL,
  service_name VARCHAR(100),
  alert_message TEXT,
  triggered_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged_by UUID REFERENCES user_profiles(id),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT
);

-- FEATURE 6: App Performance Dashboard
CREATE TABLE unified_performance_metrics (
  metric_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  metric_category VARCHAR(100) NOT NULL, -- app, screen, carousel, network, device
  metric_name VARCHAR(255) NOT NULL,
  metric_value DECIMAL(10,2),
  device_model VARCHAR(255),
  user_id UUID REFERENCES user_profiles(id),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE performance_alerts (
  alert_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  alert_type VARCHAR(100) NOT NULL, -- degradation, threshold_exceeded, anomaly
  metric_name VARCHAR(255),
  current_value DECIMAL(10,2),
  threshold_value DECIMAL(10,2),
  predicted_at TIMESTAMPTZ,
  triggered_at TIMESTAMPTZ DEFAULT NOW()
);

-- FEATURE 7: Gemini Cost-Efficiency Analyzer
CREATE TABLE ai_service_costs (
  cost_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_name VARCHAR(100) NOT NULL, -- openai, anthropic, perplexity, gemini
  model_name VARCHAR(255),
  usage_tokens INTEGER DEFAULT 0,
  cost_usd DECIMAL(10,4),
  task_type VARCHAR(100), -- moderation, fraud, curation, optimization
  quality_score DECIMAL(3,2),
  latency_ms INTEGER,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gemini_opportunity_reports (
  report_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  analysis_period_start DATE NOT NULL,
  analysis_period_end DATE NOT NULL,
  current_monthly_cost DECIMAL(10,2),
  projected_gemini_cost DECIMAL(10,2),
  potential_savings DECIMAL(10,2),
  task_analysis JSONB DEFAULT '[]'::jsonb,
  recommendations TEXT,
  generated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cost_optimization_approvals (
  approval_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  report_id UUID REFERENCES gemini_opportunity_reports(report_id) ON DELETE CASCADE,
  approved_by UUID REFERENCES user_profiles(id),
  approval_status VARCHAR(50) DEFAULT 'pending', -- approved, rejected, pending
  implementation_plan TEXT,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
DROP INDEX IF EXISTS idx_ga_events_user_timestamp;
CREATE INDEX idx_ga_events_user_timestamp ON google_analytics_events(user_id, timestamp DESC);

DROP INDEX IF EXISTS idx_ga_events_name;
CREATE INDEX idx_ga_events_name ON google_analytics_events(event_name);

DROP INDEX IF EXISTS idx_vote_receipts_user;
CREATE INDEX idx_vote_receipts_user ON vote_receipts(user_id);

DROP INDEX IF EXISTS idx_vote_receipts_hash;
CREATE INDEX idx_vote_receipts_hash ON vote_receipts(vote_hash);

DROP INDEX IF EXISTS idx_feed_cache_user;
CREATE INDEX idx_feed_cache_user ON feed_ranking_cache(user_id);

DROP INDEX IF EXISTS idx_feed_cache_expires;
CREATE INDEX idx_feed_cache_expires ON feed_ranking_cache(expires_at);

DROP INDEX IF EXISTS idx_log_analysis_window;
CREATE INDEX idx_log_analysis_window ON log_analysis_results(analysis_window_start, analysis_window_end);

DROP INDEX IF EXISTS idx_security_incidents_status;
CREATE INDEX idx_security_incidents_status ON security_incidents(status, severity);

DROP INDEX IF EXISTS idx_health_metrics_service;
CREATE INDEX idx_health_metrics_service ON service_health_metrics(service_name, recorded_at DESC);

DROP INDEX IF EXISTS idx_system_alerts_resolved;
CREATE INDEX idx_system_alerts_resolved ON system_alerts(resolved_at) WHERE resolved_at IS NULL;

DROP INDEX IF EXISTS idx_performance_metrics_category;
CREATE INDEX idx_performance_metrics_category ON unified_performance_metrics(metric_category, recorded_at DESC);

DROP INDEX IF EXISTS idx_ai_costs_service;
CREATE INDEX idx_ai_costs_service ON ai_service_costs(service_name, recorded_at DESC);

-- Enable Row Level Security
ALTER TABLE google_analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_attribution ENABLE ROW LEVEL SECURITY;
ALTER TABLE vote_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_ranking_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_content_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE claude_curation_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE log_analysis_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE unified_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_service_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE gemini_opportunity_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE cost_optimization_approvals ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Google Analytics: Users can view their own events, admins can view all
DROP POLICY IF EXISTS google_analytics_events_select ON google_analytics_events;
CREATE POLICY google_analytics_events_select ON google_analytics_events
  FOR SELECT USING (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS google_analytics_events_insert ON google_analytics_events;
CREATE POLICY google_analytics_events_insert ON google_analytics_events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Vote Receipts: Users can view their own receipts
DROP POLICY IF EXISTS vote_receipts_select ON vote_receipts;
CREATE POLICY vote_receipts_select ON vote_receipts
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS vote_receipts_insert ON vote_receipts;
CREATE POLICY vote_receipts_insert ON vote_receipts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Feed Ranking Cache: Users can view their own cache
DROP POLICY IF EXISTS feed_cache_select ON feed_ranking_cache;
CREATE POLICY feed_cache_select ON feed_ranking_cache
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS feed_cache_upsert ON feed_ranking_cache;
CREATE POLICY feed_cache_upsert ON feed_ranking_cache
  FOR ALL USING (auth.uid() = user_id);

-- User Content Preferences: Users can manage their own preferences
DROP POLICY IF EXISTS content_prefs_all ON user_content_preferences;
CREATE POLICY content_prefs_all ON user_content_preferences
  FOR ALL USING (auth.uid() = user_id);

-- Security Incidents: Admin only
DROP POLICY IF EXISTS security_incidents_admin ON security_incidents;
CREATE POLICY security_incidents_admin ON security_incidents
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- System Monitoring: Admin only
DROP POLICY IF EXISTS health_metrics_admin ON service_health_metrics;
CREATE POLICY health_metrics_admin ON service_health_metrics
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS system_alerts_admin ON system_alerts;
CREATE POLICY system_alerts_admin ON system_alerts
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Performance Metrics: Users can view their own, admins can view all
DROP POLICY IF EXISTS performance_metrics_select ON unified_performance_metrics;
CREATE POLICY performance_metrics_select ON unified_performance_metrics
  FOR SELECT USING (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS performance_metrics_insert ON unified_performance_metrics;
CREATE POLICY performance_metrics_insert ON unified_performance_metrics
  FOR INSERT WITH CHECK (true); -- Allow system to insert

-- AI Service Costs: Admin only
DROP POLICY IF EXISTS ai_costs_admin ON ai_service_costs;
CREATE POLICY ai_costs_admin ON ai_service_costs
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS gemini_reports_admin ON gemini_opportunity_reports;
CREATE POLICY gemini_reports_admin ON gemini_opportunity_reports
  FOR ALL USING (
    EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Grant permissions
GRANT ALL ON google_analytics_events TO authenticated;
GRANT ALL ON analytics_attribution TO authenticated;
GRANT ALL ON vote_receipts TO authenticated;
GRANT ALL ON feed_ranking_cache TO authenticated;
GRANT ALL ON user_content_preferences TO authenticated;
GRANT ALL ON claude_curation_analytics TO authenticated;
GRANT ALL ON log_analysis_results TO authenticated;
GRANT ALL ON security_incidents TO authenticated;
GRANT ALL ON service_health_metrics TO authenticated;
GRANT ALL ON system_alerts TO authenticated;
GRANT ALL ON unified_performance_metrics TO authenticated;
GRANT ALL ON performance_alerts TO authenticated;
GRANT ALL ON ai_service_costs TO authenticated;
GRANT ALL ON gemini_opportunity_reports TO authenticated;
GRANT ALL ON cost_optimization_approvals TO authenticated;