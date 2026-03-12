-- Live Question Injection + Image Options + Performance Profiling Migration
-- Timestamp: 20260219094500

-- ============================================================
-- 1. LIVE QUESTION INJECTION SYSTEM
-- ============================================================

-- Live question injection queue
CREATE TABLE IF NOT EXISTS public.live_question_injection_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  options JSONB NOT NULL DEFAULT '[]'::jsonb,
  correct_answer_index INTEGER NOT NULL,
  question_image_url TEXT,
  difficulty_level TEXT DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
  injection_position TEXT DEFAULT 'end' CHECK (injection_position IN ('start', 'end', 'after_question')),
  injection_status TEXT DEFAULT 'pending' CHECK (injection_status IN ('pending', 'scheduled', 'broadcasted', 'cancelled')),
  scheduled_for TIMESTAMPTZ,
  broadcasted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_live_question_injection_election ON public.live_question_injection_queue(election_id);
CREATE INDEX IF NOT EXISTS idx_live_question_injection_status ON public.live_question_injection_queue(injection_status);
CREATE INDEX IF NOT EXISTS idx_live_question_injection_scheduled ON public.live_question_injection_queue(scheduled_for) WHERE scheduled_for IS NOT NULL;

-- Live question broadcasts tracking
CREATE TABLE IF NOT EXISTS public.live_question_broadcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  injection_id UUID NOT NULL REFERENCES public.live_question_injection_queue(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  active_voters_count INTEGER DEFAULT 0,
  notification_sent_count INTEGER DEFAULT 0,
  broadcast_timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(injection_id)
);

CREATE INDEX IF NOT EXISTS idx_live_question_broadcasts_election ON public.live_question_broadcasts(election_id);

-- Live question response analytics
CREATE TABLE IF NOT EXISTS public.live_question_response_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  injection_id UUID NOT NULL REFERENCES public.live_question_injection_queue(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  total_responses INTEGER DEFAULT 0,
  correct_responses INTEGER DEFAULT 0,
  average_response_time_seconds NUMERIC(10,2) DEFAULT 0.00,
  response_rate_percentage NUMERIC(5,2) DEFAULT 0.00,
  last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(injection_id)
);

CREATE INDEX IF NOT EXISTS idx_live_question_response_analytics_election ON public.live_question_response_analytics(election_id);

-- ============================================================
-- 2. MCQ OPTION IMAGE METADATA
-- ============================================================

-- MCQ option image metadata
CREATE TABLE IF NOT EXISTS public.mcq_option_image_metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mcq_id UUID NOT NULL REFERENCES public.election_mcqs(id) ON DELETE CASCADE,
  option_index INTEGER NOT NULL,
  original_image_url TEXT NOT NULL,
  thumbnail_url TEXT,
  compressed_url TEXT,
  image_format TEXT DEFAULT 'jpg' CHECK (image_format IN ('jpg', 'png', 'webp')),
  file_size_bytes INTEGER,
  width_px INTEGER,
  height_px INTEGER,
  alt_text TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(mcq_id, option_index)
);

CREATE INDEX IF NOT EXISTS idx_mcq_option_image_metadata_mcq ON public.mcq_option_image_metadata(mcq_id);

-- MCQ image gallery exports
CREATE TABLE IF NOT EXISTS public.mcq_image_gallery_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  export_format TEXT DEFAULT 'zip' CHECK (export_format IN ('zip', 'pdf', 'json')),
  total_images INTEGER DEFAULT 0,
  includes_voting_results BOOLEAN DEFAULT true,
  export_status TEXT DEFAULT 'pending' CHECK (export_status IN ('pending', 'processing', 'completed', 'failed')),
  download_url TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_mcq_image_gallery_exports_election ON public.mcq_image_gallery_exports(election_id);
CREATE INDEX IF NOT EXISTS idx_mcq_image_gallery_exports_creator ON public.mcq_image_gallery_exports(creator_id);

-- ============================================================
-- 3. PERFORMANCE PROFILING INFRASTRUCTURE
-- ============================================================

-- Per-screen performance metrics
CREATE TABLE IF NOT EXISTS public.screen_performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  screen_name TEXT NOT NULL,
  session_id TEXT NOT NULL,
  cpu_usage_percentage NUMERIC(5,2) DEFAULT 0.00,
  memory_usage_mb NUMERIC(10,2) DEFAULT 0.00,
  network_bandwidth_mbps NUMERIC(10,2) DEFAULT 0.00,
  frame_render_time_ms NUMERIC(10,2) DEFAULT 0.00,
  fps NUMERIC(5,2) DEFAULT 60.00,
  load_time_ms INTEGER DEFAULT 0,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_screen_performance_metrics_screen ON public.screen_performance_metrics(screen_name);
CREATE INDEX IF NOT EXISTS idx_screen_performance_metrics_session ON public.screen_performance_metrics(session_id);
CREATE INDEX IF NOT EXISTS idx_screen_performance_metrics_timestamp ON public.screen_performance_metrics(timestamp);

-- Performance bottleneck detection
CREATE TABLE IF NOT EXISTS public.performance_bottlenecks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  bottleneck_type TEXT NOT NULL CHECK (bottleneck_type IN ('cpu', 'memory', 'network', 'rendering')),
  severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  threshold_exceeded TEXT NOT NULL,
  actual_value NUMERIC(10,2) NOT NULL,
  threshold_value NUMERIC(10,2) NOT NULL,
  detection_algorithm TEXT DEFAULT 'threshold_based',
  detected_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_performance_bottlenecks_screen ON public.performance_bottlenecks(screen_name);
CREATE INDEX IF NOT EXISTS idx_performance_bottlenecks_type ON public.performance_bottlenecks(bottleneck_type);
CREATE INDEX IF NOT EXISTS idx_performance_bottlenecks_severity ON public.performance_bottlenecks(severity);
CREATE INDEX IF NOT EXISTS idx_performance_bottlenecks_unresolved ON public.performance_bottlenecks(resolved_at) WHERE resolved_at IS NULL;

-- Optimization recommendations
CREATE TABLE IF NOT EXISTS public.optimization_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  bottleneck_id UUID REFERENCES public.performance_bottlenecks(id) ON DELETE CASCADE,
  recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('lazy_load', 'reduce_rebuilds', 'memoization', 'optimize_network', 'image_optimization', 'code_splitting')),
  recommendation_text TEXT NOT NULL,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  estimated_improvement_percentage NUMERIC(5,2),
  implementation_complexity TEXT DEFAULT 'medium' CHECK (implementation_complexity IN ('low', 'medium', 'high')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'implemented', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  implemented_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_screen ON public.optimization_recommendations(screen_name);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_status ON public.optimization_recommendations(status);
CREATE INDEX IF NOT EXISTS idx_optimization_recommendations_priority ON public.optimization_recommendations(priority);

-- Flame graph data
CREATE TABLE IF NOT EXISTS public.flame_graph_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  session_id TEXT NOT NULL,
  widget_tree_json JSONB NOT NULL,
  hot_spots JSONB DEFAULT '[]'::jsonb,
  total_build_time_ms INTEGER NOT NULL,
  captured_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_flame_graph_data_screen ON public.flame_graph_data(screen_name);
CREATE INDEX IF NOT EXISTS idx_flame_graph_data_session ON public.flame_graph_data(session_id);

-- Performance timeline events
CREATE TABLE IF NOT EXISTS public.performance_timeline_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  session_id TEXT NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('screen_load', 'api_call', 'widget_build', 'image_load', 'user_interaction', 'navigation')),
  event_name TEXT NOT NULL,
  duration_ms INTEGER NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_performance_timeline_events_screen ON public.performance_timeline_events(screen_name);
CREATE INDEX IF NOT EXISTS idx_performance_timeline_events_session ON public.performance_timeline_events(session_id);
CREATE INDEX IF NOT EXISTS idx_performance_timeline_events_type ON public.performance_timeline_events(event_type);

-- Performance comparison reports
CREATE TABLE IF NOT EXISTS public.performance_comparison_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  baseline_session_id TEXT NOT NULL,
  optimized_session_id TEXT NOT NULL,
  cpu_improvement_percentage NUMERIC(5,2),
  memory_improvement_percentage NUMERIC(5,2),
  network_improvement_percentage NUMERIC(5,2),
  fps_improvement_percentage NUMERIC(5,2),
  load_time_improvement_ms INTEGER,
  report_json JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_performance_comparison_reports_screen ON public.performance_comparison_reports(screen_name);

-- ============================================================
-- 4. RPC FUNCTIONS
-- ============================================================

-- Broadcast live question to active voters
CREATE OR REPLACE FUNCTION public.broadcast_live_question(
  p_injection_id UUID,
  p_election_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_active_voters_count INTEGER;
  v_question_data JSONB;
  v_broadcast_id UUID;
BEGIN
  -- Get active voters count (voters who have started but not completed voting)
  SELECT COUNT(DISTINCT voter_id) INTO v_active_voters_count
  FROM public.votes
  WHERE election_id = p_election_id
  AND created_at > NOW() - INTERVAL '1 hour';

  -- Get question data
  SELECT to_jsonb(lqiq.*) INTO v_question_data
  FROM public.live_question_injection_queue lqiq
  WHERE lqiq.id = p_injection_id;

  -- Update injection status
  UPDATE public.live_question_injection_queue
  SET injection_status = 'broadcasted',
      broadcasted_at = NOW(),
      updated_at = NOW()
  WHERE id = p_injection_id;

  -- Create broadcast record
  INSERT INTO public.live_question_broadcasts (
    injection_id,
    election_id,
    active_voters_count,
    notification_sent_count
  ) VALUES (
    p_injection_id,
    p_election_id,
    v_active_voters_count,
    v_active_voters_count
  )
  RETURNING id INTO v_broadcast_id;

  -- Initialize analytics record
  INSERT INTO public.live_question_response_analytics (
    injection_id,
    election_id
  ) VALUES (
    p_injection_id,
    p_election_id
  )
  ON CONFLICT (injection_id) DO NOTHING;

  RETURN json_build_object(
    'success', true,
    'broadcast_id', v_broadcast_id,
    'active_voters_count', v_active_voters_count,
    'question_data', v_question_data
  );
END;
$$;

-- Get performance bottleneck summary
CREATE OR REPLACE FUNCTION public.get_performance_bottleneck_summary(
  p_hours INTEGER DEFAULT 24
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'total_bottlenecks', COUNT(*),
    'critical_count', COUNT(*) FILTER (WHERE severity = 'critical'),
    'high_count', COUNT(*) FILTER (WHERE severity = 'high'),
    'medium_count', COUNT(*) FILTER (WHERE severity = 'medium'),
    'low_count', COUNT(*) FILTER (WHERE severity = 'low'),
    'cpu_bottlenecks', COUNT(*) FILTER (WHERE bottleneck_type = 'cpu'),
    'memory_bottlenecks', COUNT(*) FILTER (WHERE bottleneck_type = 'memory'),
    'network_bottlenecks', COUNT(*) FILTER (WHERE bottleneck_type = 'network'),
    'rendering_bottlenecks', COUNT(*) FILTER (WHERE bottleneck_type = 'rendering'),
    'unresolved_count', COUNT(*) FILTER (WHERE resolved_at IS NULL)
  ) INTO v_result
  FROM public.performance_bottlenecks
  WHERE detected_at > NOW() - (p_hours || ' hours')::INTERVAL;

  RETURN v_result;
END;
$$;

-- ============================================================
-- 5. RLS POLICIES
-- ============================================================

-- Live question injection queue policies
ALTER TABLE public.live_question_injection_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can manage live questions"
  ON public.live_question_injection_queue
  FOR ALL
  USING (
    creator_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = live_question_injection_queue.election_id
      AND elections.created_by = auth.uid()
    )
  );

CREATE POLICY "Voters can view broadcasted live questions"
  ON public.live_question_injection_queue
  FOR SELECT
  USING (injection_status = 'broadcasted');

-- Live question broadcasts policies
ALTER TABLE public.live_question_broadcasts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can view broadcasts"
  ON public.live_question_broadcasts
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = live_question_broadcasts.election_id
      AND elections.created_by = auth.uid()
    )
  );

-- Live question response analytics policies
ALTER TABLE public.live_question_response_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can view analytics"
  ON public.live_question_response_analytics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = live_question_response_analytics.election_id
      AND elections.created_by = auth.uid()
    )
  );

-- MCQ option image metadata policies
ALTER TABLE public.mcq_option_image_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can manage option images"
  ON public.mcq_option_image_metadata
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.election_mcqs
      JOIN public.elections ON elections.id = election_mcqs.election_id
      WHERE election_mcqs.id = mcq_option_image_metadata.mcq_id
      AND elections.created_by = auth.uid()
    )
  );

CREATE POLICY "Voters can view option images"
  ON public.mcq_option_image_metadata
  FOR SELECT
  USING (true);

-- MCQ image gallery exports policies
ALTER TABLE public.mcq_image_gallery_exports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can manage their exports"
  ON public.mcq_image_gallery_exports
  FOR ALL
  USING (creator_id = auth.uid());

-- Performance metrics policies (admin only)
ALTER TABLE public.screen_performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all performance metrics"
  ON public.screen_performance_metrics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert their own metrics"
  ON public.screen_performance_metrics
  FOR INSERT
  WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

-- Performance bottlenecks policies
ALTER TABLE public.performance_bottlenecks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage bottlenecks"
  ON public.performance_bottlenecks
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );

-- Optimization recommendations policies
ALTER TABLE public.optimization_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage recommendations"
  ON public.optimization_recommendations
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );

-- Flame graph data policies
ALTER TABLE public.flame_graph_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view flame graphs"
  ON public.flame_graph_data
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );

-- Performance timeline events policies
ALTER TABLE public.performance_timeline_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view timeline events"
  ON public.performance_timeline_events
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert timeline events"
  ON public.performance_timeline_events
  FOR INSERT
  WITH CHECK (true);

-- Performance comparison reports policies
ALTER TABLE public.performance_comparison_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage comparison reports"
  ON public.performance_comparison_reports
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles
      WHERE admin_roles.user_id = auth.uid()
    )
  );
