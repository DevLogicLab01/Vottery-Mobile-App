-- =====================================================
-- CAROUSEL OPTIMIZATION FEATURES MIGRATION
-- Feature 1: A/B Testing Framework
-- Feature 2: Content Moderation Automation  
-- Feature 3: Mobile Optimization Suite
-- =====================================================

-- =====================================================
-- FEATURE 1: CAROUSEL A/B TESTING FRAMEWORK
-- =====================================================

-- Carousel Experiments Table
CREATE TABLE IF NOT EXISTS carousel_experiments (
  experiment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_name VARCHAR(200) NOT NULL,
  experiment_description TEXT,
  test_type VARCHAR(50) NOT NULL CHECK (test_type IN ('sequencing_strategy','content_ordering','carousel_rotation')),
  variants JSONB NOT NULL,
  success_metrics JSONB NOT NULL,
  primary_metric VARCHAR(50) NOT NULL,
  duration_days INTEGER NOT NULL CHECK (duration_days > 0),
  minimum_sample_size INTEGER DEFAULT 1000,
  significance_threshold DECIMAL(3,2) DEFAULT 0.95 CHECK (significance_threshold >= 0.80 AND significance_threshold <= 0.99),
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft','running','paused','concluded','archived')),
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  winning_variant_id VARCHAR(50),
  auto_promote BOOLEAN DEFAULT false,
  created_by UUID REFERENCES user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  concluded_at TIMESTAMPTZ
);

CREATE INDEX idx_experiments_status ON carousel_experiments(status, start_date);
CREATE INDEX idx_experiments_creator ON carousel_experiments(created_by);

-- Experiment Assignments Table
CREATE TABLE IF NOT EXISTS experiment_assignments (
  assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID NOT NULL REFERENCES carousel_experiments(experiment_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  variant_id VARCHAR(50) NOT NULL,
  assigned_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT unique_user_experiment UNIQUE(user_id, experiment_id)
);

CREATE INDEX idx_assignments_experiment ON experiment_assignments(experiment_id, variant_id);
CREATE INDEX idx_assignments_user ON experiment_assignments(user_id);

-- Experiment Variant Metrics Table
CREATE TABLE IF NOT EXISTS experiment_variant_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID NOT NULL REFERENCES carousel_experiments(experiment_id) ON DELETE CASCADE,
  variant_id VARCHAR(50) NOT NULL,
  metric_date DATE NOT NULL,
  users_assigned INTEGER DEFAULT 0,
  total_interactions INTEGER DEFAULT 0,
  engaged_users INTEGER DEFAULT 0,
  conversions INTEGER DEFAULT 0,
  total_revenue DECIMAL(10,2) DEFAULT 0,
  avg_session_duration DECIMAL(8,2),
  engagement_rate DECIMAL(5,2),
  conversion_rate DECIMAL(5,2),
  revenue_per_user DECIMAL(10,2),
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_variant_metric_date UNIQUE(experiment_id, variant_id, metric_date)
);

CREATE INDEX idx_variant_metrics ON experiment_variant_metrics(experiment_id, variant_id, metric_date DESC);

-- Experiment Statistical Results Table
CREATE TABLE IF NOT EXISTS experiment_statistical_results (
  result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID NOT NULL REFERENCES carousel_experiments(experiment_id),
  variant_a_id VARCHAR(50) NOT NULL,
  variant_b_id VARCHAR(50) NOT NULL,
  metric_name VARCHAR(50) NOT NULL,
  test_type VARCHAR(50) NOT NULL,
  test_statistic DECIMAL(10,4),
  p_value DECIMAL(10,8),
  confidence_level DECIMAL(3,2),
  effect_size DECIMAL(6,4),
  confidence_interval_lower DECIMAL(10,4),
  confidence_interval_upper DECIMAL(10,4),
  is_significant BOOLEAN,
  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_statistical_results ON experiment_statistical_results(experiment_id, is_significant);

-- =====================================================
-- FEATURE 2: CAROUSEL CONTENT MODERATION AUTOMATION
-- =====================================================

-- Carousel Content Moderation Table
CREATE TABLE IF NOT EXISTS carousel_content_moderation (
  moderation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL,
  title TEXT,
  description TEXT,
  media_urls JSONB,
  creator_user_id UUID REFERENCES user_profiles(id),
  violations JSONB,
  overall_safety_score INTEGER CHECK (overall_safety_score >= 0 AND overall_safety_score <= 100),
  content_quality_score INTEGER CHECK (content_quality_score >= 0 AND content_quality_score <= 100),
  engagement_prediction INTEGER,
  recommended_actions JSONB,
  moderation_status VARCHAR(20) DEFAULT 'pending' CHECK (moderation_status IN ('pending','approved','flagged','removed','appealed')),
  auto_actioned BOOLEAN DEFAULT false,
  claude_reasoning TEXT,
  moderated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_moderation_status ON carousel_content_moderation(moderation_status, moderated_at);
CREATE INDEX idx_moderation_creator ON carousel_content_moderation(creator_user_id);
CREATE INDEX idx_moderation_content ON carousel_content_moderation(content_id);

-- Moderation Queue Table
CREATE TABLE IF NOT EXISTS moderation_queue (
  queue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moderation_id UUID NOT NULL REFERENCES carousel_content_moderation(moderation_id) ON DELETE CASCADE,
  assigned_to UUID REFERENCES user_profiles(id),
  priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low','medium','high','critical')),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','in_review','approved','removed','escalated')),
  assigned_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT
);

CREATE INDEX idx_queue_status ON moderation_queue(status, priority, assigned_at);
CREATE INDEX idx_queue_assignee ON moderation_queue(assigned_to);

-- Moderation Appeals Table
CREATE TABLE IF NOT EXISTS moderation_appeals (
  appeal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moderation_id UUID NOT NULL REFERENCES carousel_content_moderation(moderation_id),
  appellant_user_id UUID NOT NULL REFERENCES user_profiles(id),
  appeal_reason TEXT NOT NULL,
  evidence_urls JSONB,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','under_review','approved','denied')),
  reviewed_by UUID REFERENCES user_profiles(id),
  reviewed_at TIMESTAMPTZ,
  resolution_notes TEXT,
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_appeals_status ON moderation_appeals(status, submitted_at);
CREATE INDEX idx_appeals_appellant ON moderation_appeals(appellant_user_id);

-- =====================================================
-- FEATURE 3: CAROUSEL MOBILE OPTIMIZATION SUITE
-- =====================================================

-- Mobile Optimization Metrics Table
CREATE TABLE IF NOT EXISTS mobile_optimization_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_model VARCHAR(100) NOT NULL,
  device_tier VARCHAR(20) CHECK (device_tier IN ('low_end','mid_range','high_end')),
  carousel_type VARCHAR(50),
  avg_fps DECIMAL(5,2),
  frame_drops_count INTEGER,
  memory_usage_mb INTEGER,
  battery_drain_percent_per_hour DECIMAL(5,2),
  gesture_response_time_ms INTEGER,
  optimization_level VARCHAR(20) CHECK (optimization_level IN ('full','standard','reduced','minimal')),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_mobile_metrics_device ON mobile_optimization_metrics(device_model, recorded_at);
CREATE INDEX idx_mobile_metrics_tier ON mobile_optimization_metrics(device_tier);

-- Gesture Performance Logs Table
CREATE TABLE IF NOT EXISTS gesture_performance_logs (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id),
  device_model VARCHAR(100),
  gesture_type VARCHAR(50),
  response_time_ms INTEGER,
  success BOOLEAN,
  carousel_type VARCHAR(50),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_gesture_logs ON gesture_performance_logs(device_model, gesture_type, recorded_at);
CREATE INDEX idx_gesture_user ON gesture_performance_logs(user_id);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE carousel_experiments ENABLE ROW LEVEL SECURITY;
ALTER TABLE experiment_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE experiment_variant_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE experiment_statistical_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_content_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_appeals ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_optimization_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE gesture_performance_logs ENABLE ROW LEVEL SECURITY;

-- Carousel Experiments Policies
CREATE POLICY "Admins can manage experiments" ON carousel_experiments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role = 'admin'
    )
  );

CREATE POLICY "Users can view running experiments" ON carousel_experiments
  FOR SELECT USING (status = 'running');

-- Experiment Assignments Policies
CREATE POLICY "Users can view own assignments" ON experiment_assignments
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "System can insert assignments" ON experiment_assignments
  FOR INSERT WITH CHECK (true);

-- Experiment Variant Metrics Policies
CREATE POLICY "Admins can view metrics" ON experiment_variant_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role = 'admin'
    )
  );

CREATE POLICY "System can insert metrics" ON experiment_variant_metrics
  FOR INSERT WITH CHECK (true);

-- Experiment Statistical Results Policies
CREATE POLICY "Admins can view statistical results" ON experiment_statistical_results
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role = 'admin'
    )
  );

-- Carousel Content Moderation Policies
CREATE POLICY "Admins and moderators can view moderation" ON carousel_content_moderation
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role IN ('admin', 'moderator')
    )
  );

CREATE POLICY "System can insert moderation records" ON carousel_content_moderation
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can update moderation" ON carousel_content_moderation
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role = 'admin'
    )
  );

-- Moderation Queue Policies
CREATE POLICY "Moderators can view queue" ON moderation_queue
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role IN ('admin', 'moderator')
    )
  );

CREATE POLICY "Moderators can update queue" ON moderation_queue
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role IN ('admin', 'moderator')
    )
  );

-- Moderation Appeals Policies
CREATE POLICY "Users can create appeals" ON moderation_appeals
  FOR INSERT WITH CHECK (appellant_user_id = auth.uid());

CREATE POLICY "Users can view own appeals" ON moderation_appeals
  FOR SELECT USING (appellant_user_id = auth.uid());

CREATE POLICY "Moderators can view all appeals" ON moderation_appeals
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role IN ('admin', 'moderator')
    )
  );

CREATE POLICY "Moderators can update appeals" ON moderation_appeals
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role IN ('admin', 'moderator')
    )
  );

-- Mobile Optimization Metrics Policies
CREATE POLICY "System can insert mobile metrics" ON mobile_optimization_metrics
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can view mobile metrics" ON mobile_optimization_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role = 'admin'
    )
  );

-- Gesture Performance Logs Policies
CREATE POLICY "Users can insert gesture logs" ON gesture_performance_logs
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view gesture logs" ON gesture_performance_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND user_role = 'admin'
    )
  );

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Calculate Experiment Metrics
CREATE OR REPLACE FUNCTION calculate_experiment_metrics(exp_id UUID, var_id VARCHAR)
RETURNS TABLE (
  engagement_rate DECIMAL,
  conversion_rate DECIMAL,
  revenue_per_user DECIMAL,
  avg_session_duration DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE(
      (COUNT(DISTINCT CASE WHEN ci.interaction_type = 'tap' THEN ci.user_id END)::DECIMAL / 
       NULLIF(COUNT(DISTINCT ea.user_id), 0)) * 100, 
      0
    ) AS engagement_rate,
    COALESCE(
      (COUNT(DISTINCT CASE WHEN ci.interaction_type = 'conversion' THEN ci.user_id END)::DECIMAL / 
       NULLIF(COUNT(DISTINCT ea.user_id), 0)) * 100,
      0
    ) AS conversion_rate,
    COALESCE(
      SUM(COALESCE((ci.metadata->>'revenue')::DECIMAL, 0)) / 
      NULLIF(COUNT(DISTINCT ea.user_id), 0),
      0
    ) AS revenue_per_user,
    COALESCE(AVG(ci.view_duration_seconds), 0) AS avg_session_duration
  FROM experiment_assignments ea
  LEFT JOIN carousel_interactions ci ON ci.user_id = ea.user_id
  WHERE ea.experiment_id = exp_id AND ea.variant_id = var_id;
END;
$$ LANGUAGE plpgsql;

-- Get Moderation Statistics
CREATE OR REPLACE FUNCTION get_moderation_statistics(days INTEGER DEFAULT 7)
RETURNS TABLE (
  total_reviewed BIGINT,
  auto_removed BIGINT,
  manual_reviews BIGINT,
  false_positive_rate DECIMAL,
  avg_review_time_minutes DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) AS total_reviewed,
    COUNT(*) FILTER (WHERE auto_actioned = true AND moderation_status = 'removed') AS auto_removed,
    COUNT(*) FILTER (WHERE auto_actioned = false) AS manual_reviews,
    COALESCE(
      (COUNT(*) FILTER (WHERE moderation_status = 'appealed' AND 
        EXISTS (SELECT 1 FROM moderation_appeals ma WHERE ma.moderation_id = ccm.moderation_id AND ma.status = 'approved'))::DECIMAL /
       NULLIF(COUNT(*) FILTER (WHERE moderation_status = 'removed'), 0)) * 100,
      0
    ) AS false_positive_rate,
    COALESCE(
      AVG(EXTRACT(EPOCH FROM (mq.reviewed_at - mq.assigned_at)) / 60),
      0
    ) AS avg_review_time_minutes
  FROM carousel_content_moderation ccm
  LEFT JOIN moderation_queue mq ON mq.moderation_id = ccm.moderation_id
  WHERE ccm.moderated_at >= NOW() - INTERVAL '1 day' * days;
END;
$$ LANGUAGE plpgsql;