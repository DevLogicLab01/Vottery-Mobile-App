-- Carousel Optimization Features Migration
-- Implements A/B Testing Framework, Content Moderation Automation, and Mobile Optimization Suite

-- ============================================
-- FEATURE 1: CAROUSEL A/B TESTING FRAMEWORK
-- ============================================

-- Carousel Experiments Table
CREATE TABLE IF NOT EXISTS public.carousel_experiments (
  experiment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_name VARCHAR(200) NOT NULL,
  experiment_description TEXT,
  test_type VARCHAR(50) NOT NULL CHECK (test_type IN ('sequencing_strategy','content_ordering','carousel_rotation')),
  variants JSONB NOT NULL,
  success_metrics JSONB NOT NULL,
  primary_metric VARCHAR(50) NOT NULL,
  duration_days INTEGER NOT NULL CHECK (duration_days > 0),
  minimum_sample_size INTEGER DEFAULT 1000 CHECK (minimum_sample_size > 0),
  significance_threshold DECIMAL(3,2) DEFAULT 0.95 CHECK (significance_threshold >= 0.80 AND significance_threshold <= 0.99),
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft','running','paused','concluded','archived')),
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  winning_variant_id VARCHAR(50),
  auto_promote BOOLEAN DEFAULT false,
  created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  concluded_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_experiments_status ON public.carousel_experiments(status, start_date);
CREATE INDEX IF NOT EXISTS idx_experiments_test_type ON public.carousel_experiments(test_type);
CREATE INDEX IF NOT EXISTS idx_experiments_created_by ON public.carousel_experiments(created_by);

-- Experiment Assignments Table
CREATE TABLE IF NOT EXISTS public.experiment_assignments (
  assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID NOT NULL REFERENCES public.carousel_experiments(experiment_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  variant_id VARCHAR(50) NOT NULL,
  assigned_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT unique_user_experiment UNIQUE(user_id, experiment_id)
);

CREATE INDEX IF NOT EXISTS idx_assignments_experiment ON public.experiment_assignments(experiment_id, variant_id);
CREATE INDEX IF NOT EXISTS idx_assignments_user ON public.experiment_assignments(user_id);

-- Experiment Variant Metrics Table
CREATE TABLE IF NOT EXISTS public.experiment_variant_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID NOT NULL REFERENCES public.carousel_experiments(experiment_id) ON DELETE CASCADE,
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

CREATE INDEX IF NOT EXISTS idx_variant_metrics ON public.experiment_variant_metrics(experiment_id, variant_id, metric_date DESC);

-- Experiment Statistical Results Table
CREATE TABLE IF NOT EXISTS public.experiment_statistical_results (
  result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID NOT NULL REFERENCES public.carousel_experiments(experiment_id) ON DELETE CASCADE,
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

CREATE INDEX IF NOT EXISTS idx_statistical_results ON public.experiment_statistical_results(experiment_id, is_significant);

-- ============================================
-- FEATURE 2: CAROUSEL CONTENT MODERATION AUTOMATION
-- ============================================

-- Carousel Content Moderation Table
CREATE TABLE IF NOT EXISTS public.carousel_content_moderation (
  moderation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL,
  title TEXT,
  description TEXT,
  media_urls JSONB,
  creator_user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
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

CREATE INDEX IF NOT EXISTS idx_moderation_status ON public.carousel_content_moderation(moderation_status, moderated_at);
CREATE INDEX IF NOT EXISTS idx_moderation_creator ON public.carousel_content_moderation(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_moderation_content ON public.carousel_content_moderation(content_id, content_type);

-- Moderation Queue Table
CREATE TABLE IF NOT EXISTS public.moderation_queue (
  queue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moderation_id UUID NOT NULL REFERENCES public.carousel_content_moderation(moderation_id) ON DELETE CASCADE,
  assigned_to UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low','medium','high','critical')),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','in_review','approved','removed','escalated')),
  assigned_at TIMESTAMPTZ,
  reviewed_at TIMESTAMPTZ,
  review_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_queue_status ON public.moderation_queue(status, priority, assigned_at);
CREATE INDEX IF NOT EXISTS idx_queue_assigned ON public.moderation_queue(assigned_to);

-- Moderation Appeals Table
CREATE TABLE IF NOT EXISTS public.moderation_appeals (
  appeal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moderation_id UUID NOT NULL REFERENCES public.carousel_content_moderation(moderation_id) ON DELETE CASCADE,
  appellant_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  appeal_reason TEXT NOT NULL,
  evidence_urls JSONB,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','under_review','approved','denied')),
  reviewed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  resolution_notes TEXT,
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_appeals_status ON public.moderation_appeals(status, submitted_at);
CREATE INDEX IF NOT EXISTS idx_appeals_appellant ON public.moderation_appeals(appellant_user_id);

-- ============================================
-- FEATURE 3: CAROUSEL MOBILE OPTIMIZATION SUITE
-- ============================================

-- Mobile Optimization Metrics Table
CREATE TABLE IF NOT EXISTS public.mobile_optimization_metrics (
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

CREATE INDEX IF NOT EXISTS idx_mobile_metrics_device ON public.mobile_optimization_metrics(device_model, recorded_at);
CREATE INDEX IF NOT EXISTS idx_mobile_metrics_tier ON public.mobile_optimization_metrics(device_tier);
CREATE INDEX IF NOT EXISTS idx_mobile_metrics_carousel ON public.mobile_optimization_metrics(carousel_type);

-- Gesture Performance Logs Table
CREATE TABLE IF NOT EXISTS public.gesture_performance_logs (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  device_model VARCHAR(100),
  gesture_type VARCHAR(50),
  response_time_ms INTEGER,
  success BOOLEAN,
  carousel_type VARCHAR(50),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_gesture_logs ON public.gesture_performance_logs(device_model, gesture_type, recorded_at);
CREATE INDEX IF NOT EXISTS idx_gesture_logs_user ON public.gesture_performance_logs(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Carousel Experiments Policies
ALTER TABLE public.carousel_experiments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all experiments" ON public.carousel_experiments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can create experiments" ON public.carousel_experiments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update experiments" ON public.carousel_experiments
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Experiment Assignments Policies
ALTER TABLE public.experiment_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own assignments" ON public.experiment_assignments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert assignments" ON public.experiment_assignments
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can view all assignments" ON public.experiment_assignments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Experiment Variant Metrics Policies
ALTER TABLE public.experiment_variant_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view variant metrics" ON public.experiment_variant_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can insert variant metrics" ON public.experiment_variant_metrics
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "System can update variant metrics" ON public.experiment_variant_metrics
  FOR UPDATE USING (auth.uid() IS NOT NULL);

-- Experiment Statistical Results Policies
ALTER TABLE public.experiment_statistical_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view statistical results" ON public.experiment_statistical_results
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can insert statistical results" ON public.experiment_statistical_results
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Carousel Content Moderation Policies
ALTER TABLE public.carousel_content_moderation ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Moderators can view all moderation records" ON public.carousel_content_moderation
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'moderator')
    )
  );

CREATE POLICY "System can insert moderation records" ON public.carousel_content_moderation
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Moderators can update moderation records" ON public.carousel_content_moderation
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'moderator')
    )
  );

-- Moderation Queue Policies
ALTER TABLE public.moderation_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Moderators can view queue" ON public.moderation_queue
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'moderator')
    )
  );

CREATE POLICY "Moderators can update queue" ON public.moderation_queue
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'moderator')
    )
  );

-- Moderation Appeals Policies
ALTER TABLE public.moderation_appeals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own appeals" ON public.moderation_appeals
  FOR SELECT USING (auth.uid() = appellant_user_id);

CREATE POLICY "Users can create appeals" ON public.moderation_appeals
  FOR INSERT WITH CHECK (auth.uid() = appellant_user_id);

CREATE POLICY "Moderators can view all appeals" ON public.moderation_appeals
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'moderator')
    )
  );

CREATE POLICY "Moderators can update appeals" ON public.moderation_appeals
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'moderator')
    )
  );

-- Mobile Optimization Metrics Policies
ALTER TABLE public.mobile_optimization_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can insert mobile metrics" ON public.mobile_optimization_metrics
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can view mobile metrics" ON public.mobile_optimization_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Gesture Performance Logs Policies
ALTER TABLE public.gesture_performance_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert gesture logs" ON public.gesture_performance_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view gesture logs" ON public.gesture_performance_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function: Calculate experiment metrics
CREATE OR REPLACE FUNCTION public.calculate_experiment_metrics(
  p_experiment_id UUID,
  p_variant_id VARCHAR
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'users_assigned', COUNT(DISTINCT ea.user_id),
    'total_interactions', COUNT(ci.interaction_id),
    'engaged_users', COUNT(DISTINCT CASE WHEN ci.interaction_type IN ('swipe', 'tap', 'conversion') THEN ci.user_id END),
    'conversions', COUNT(*) FILTER (WHERE ci.converted = true),
    'engagement_rate', 
      CASE 
        WHEN COUNT(DISTINCT ea.user_id) > 0 THEN
          (COUNT(DISTINCT CASE WHEN ci.interaction_type IN ('swipe', 'tap', 'conversion') THEN ci.user_id END)::DECIMAL / 
           COUNT(DISTINCT ea.user_id)::DECIMAL * 100)
        ELSE 0
      END,
    'conversion_rate',
      CASE 
        WHEN COUNT(ci.interaction_id) > 0 THEN
          (COUNT(*) FILTER (WHERE ci.converted = true)::DECIMAL / 
           COUNT(ci.interaction_id)::DECIMAL * 100)
        ELSE 0
      END
  )
  INTO v_result
  FROM public.experiment_assignments ea
  LEFT JOIN public.carousel_interactions ci ON ci.user_id = ea.user_id
  WHERE ea.experiment_id = p_experiment_id
    AND ea.variant_id = p_variant_id;

  RETURN v_result;
END;
$$;

-- Function: Get moderation statistics
CREATE OR REPLACE FUNCTION public.get_moderation_statistics(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'total_reviewed', COUNT(*),
    'auto_removed', COUNT(*) FILTER (WHERE auto_actioned = true AND moderation_status = 'removed'),
    'manual_reviews', COUNT(*) FILTER (WHERE auto_actioned = false),
    'avg_safety_score', AVG(overall_safety_score),
    'avg_quality_score', AVG(content_quality_score),
    'false_positive_rate',
      CASE 
        WHEN COUNT(*) FILTER (WHERE moderation_status = 'removed') > 0 THEN
          (COUNT(*) FILTER (WHERE moderation_status = 'removed' AND 
           EXISTS (SELECT 1 FROM public.moderation_appeals ma WHERE ma.moderation_id = carousel_content_moderation.moderation_id AND ma.status = 'approved'))::DECIMAL /
           COUNT(*) FILTER (WHERE moderation_status = 'removed')::DECIMAL * 100)
        ELSE 0
      END
  )
  INTO v_result
  FROM public.carousel_content_moderation
  WHERE moderated_at >= p_start_date
    AND moderated_at <= p_end_date;

  RETURN v_result;
END;
$$;