-- Live Question Injection, Advanced Performance Profiling, and Image Questions to MCQ
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
  injection_position TEXT DEFAULT 'end' CHECK (injection_position IN ('beginning', 'middle', 'end')),
  injection_status TEXT DEFAULT 'pending' CHECK (injection_status IN ('pending', 'scheduled', 'broadcasted', 'cancelled')),
  scheduled_for TIMESTAMPTZ,
  broadcasted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_live_question_injection_election ON public.live_question_injection_queue(election_id);
CREATE INDEX IF NOT EXISTS idx_live_question_injection_status ON public.live_question_injection_queue(injection_status);
CREATE INDEX IF NOT EXISTS idx_live_question_injection_creator ON public.live_question_injection_queue(creator_id);

-- Live question broadcast tracking
CREATE TABLE IF NOT EXISTS public.live_question_broadcasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  injection_id UUID NOT NULL REFERENCES public.live_question_injection_queue(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  active_voters_count INTEGER DEFAULT 0,
  notification_sent_count INTEGER DEFAULT 0,
  response_count INTEGER DEFAULT 0,
  engagement_rate NUMERIC(5,2) DEFAULT 0.00,
  broadcasted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(injection_id)
);

CREATE INDEX IF NOT EXISTS idx_live_question_broadcasts_election ON public.live_question_broadcasts(election_id);
CREATE INDEX IF NOT EXISTS idx_live_question_broadcasts_injection ON public.live_question_broadcasts(injection_id);

-- Live question response analytics
CREATE TABLE IF NOT EXISTS public.live_question_response_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  injection_id UUID NOT NULL REFERENCES public.live_question_injection_queue(id) ON DELETE CASCADE,
  mcq_id UUID REFERENCES public.election_mcqs(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  total_responses INTEGER DEFAULT 0,
  correct_responses INTEGER DEFAULT 0,
  response_rate NUMERIC(5,2) DEFAULT 0.00,
  avg_response_time_seconds NUMERIC(10,2) DEFAULT 0.00,
  is_live_injected BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(injection_id)
);

CREATE INDEX IF NOT EXISTS idx_live_question_response_analytics_election ON public.live_question_response_analytics(election_id);
CREATE INDEX IF NOT EXISTS idx_live_question_response_analytics_mcq ON public.live_question_response_analytics(mcq_id);

-- Add live injection tracking to election_mcqs
ALTER TABLE public.election_mcqs ADD COLUMN IF NOT EXISTS is_live_injected BOOLEAN DEFAULT false;
ALTER TABLE public.election_mcqs ADD COLUMN IF NOT EXISTS injection_id UUID REFERENCES public.live_question_injection_queue(id) ON DELETE SET NULL;
ALTER TABLE public.election_mcqs ADD COLUMN IF NOT EXISTS injected_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_election_mcqs_live_injected ON public.election_mcqs(is_live_injected);
CREATE INDEX IF NOT EXISTS idx_election_mcqs_injection_id ON public.election_mcqs(injection_id);

-- ============================================================
-- 2. ADVANCED PERFORMANCE PROFILING SYSTEM
-- ============================================================

-- Per-screen performance metrics
CREATE TABLE IF NOT EXISTS public.screen_performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  session_id UUID,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  cpu_usage_percentage NUMERIC(5,2) DEFAULT 0.00,
  memory_heap_mb NUMERIC(10,2) DEFAULT 0.00,
  memory_stack_mb NUMERIC(10,2) DEFAULT 0.00,
  network_bandwidth_mbps NUMERIC(10,2) DEFAULT 0.00,
  frame_render_time_ms NUMERIC(10,2) DEFAULT 0.00,
  frames_per_second NUMERIC(5,2) DEFAULT 60.00,
  screen_load_time_ms INTEGER DEFAULT 0,
  widget_rebuild_count INTEGER DEFAULT 0,
  recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_screen_performance_metrics_screen ON public.screen_performance_metrics(screen_name);
CREATE INDEX IF NOT EXISTS idx_screen_performance_metrics_user ON public.screen_performance_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_screen_performance_metrics_recorded ON public.screen_performance_metrics(recorded_at DESC);

-- Automated bottleneck detection
CREATE TABLE IF NOT EXISTS public.performance_bottleneck_detection (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  bottleneck_type TEXT NOT NULL CHECK (bottleneck_type IN ('cpu', 'memory', 'network', 'rendering')),
  severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  threshold_exceeded TEXT NOT NULL,
  current_value NUMERIC(10,2) NOT NULL,
  threshold_value NUMERIC(10,2) NOT NULL,
  detection_algorithm TEXT DEFAULT 'threshold_based',
  detected_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_performance_bottleneck_screen ON public.performance_bottleneck_detection(screen_name);
CREATE INDEX IF NOT EXISTS idx_performance_bottleneck_severity ON public.performance_bottleneck_detection(severity);
CREATE INDEX IF NOT EXISTS idx_performance_bottleneck_detected ON public.performance_bottleneck_detection(detected_at DESC);

-- Optimization recommendations engine
CREATE TABLE IF NOT EXISTS public.performance_optimization_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bottleneck_id UUID REFERENCES public.performance_bottleneck_detection(id) ON DELETE CASCADE,
  screen_name TEXT NOT NULL,
  recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('lazy_load', 'reduce_rebuilds', 'memoization', 'optimize_network', 'image_compression', 'code_splitting')),
  priority_score INTEGER DEFAULT 50 CHECK (priority_score >= 0 AND priority_score <= 100),
  actionable_playbook JSONB NOT NULL DEFAULT '{}'::jsonb,
  estimated_improvement_percentage NUMERIC(5,2) DEFAULT 0.00,
  implementation_status TEXT DEFAULT 'pending' CHECK (implementation_status IN ('pending', 'in_progress', 'completed', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  implemented_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_performance_optimization_screen ON public.performance_optimization_recommendations(screen_name);
CREATE INDEX IF NOT EXISTS idx_performance_optimization_status ON public.performance_optimization_recommendations(implementation_status);
CREATE INDEX IF NOT EXISTS idx_performance_optimization_priority ON public.performance_optimization_recommendations(priority_score DESC);

-- Flame graph generation data
CREATE TABLE IF NOT EXISTS public.performance_flame_graph_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  session_id UUID,
  widget_build_tree JSONB NOT NULL DEFAULT '{}'::jsonb,
  hot_spots JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_build_time_ms NUMERIC(10,2) DEFAULT 0.00,
  generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_performance_flame_graph_screen ON public.performance_flame_graph_data(screen_name);
CREATE INDEX IF NOT EXISTS idx_performance_flame_graph_generated ON public.performance_flame_graph_data(generated_at DESC);

-- Performance timeline events
CREATE TABLE IF NOT EXISTS public.performance_timeline_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  session_id UUID,
  event_type TEXT NOT NULL CHECK (event_type IN ('screen_load', 'widget_build', 'network_call', 'state_update', 'animation', 'user_interaction')),
  event_name TEXT NOT NULL,
  duration_ms NUMERIC(10,2) DEFAULT 0.00,
  metadata JSONB DEFAULT '{}'::jsonb,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_performance_timeline_screen ON public.performance_timeline_events(screen_name);
CREATE INDEX IF NOT EXISTS idx_performance_timeline_session ON public.performance_timeline_events(session_id);
CREATE INDEX IF NOT EXISTS idx_performance_timeline_timestamp ON public.performance_timeline_events(timestamp DESC);

-- Performance regression detection
CREATE TABLE IF NOT EXISTS public.performance_regression_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL,
  metric_type TEXT NOT NULL CHECK (metric_type IN ('cpu', 'memory', 'network', 'rendering', 'load_time')),
  baseline_value NUMERIC(10,2) NOT NULL,
  current_value NUMERIC(10,2) NOT NULL,
  regression_percentage NUMERIC(5,2) NOT NULL,
  is_regression BOOLEAN DEFAULT false,
  detected_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_performance_regression_screen ON public.performance_regression_tracking(screen_name);
CREATE INDEX IF NOT EXISTS idx_performance_regression_detected ON public.performance_regression_tracking(is_regression);

-- ============================================================
-- 3. IMAGE QUESTIONS TO MCQ - ADD IMAGE_URL PER OPTION
-- ============================================================

-- Modify election_mcqs options structure to support image URLs per option
-- Note: options is already JSONB, we'll store as array of objects: [{"text": "...", "image_url": "...", "alt_text": "..."}]

COMMENT ON COLUMN public.election_mcqs.options IS 'JSONB array of option objects with structure: [{"text": "option text", "image_url": "https://...", "alt_text": "accessibility description"}]';

-- Image optimization tracking for MCQ options
CREATE TABLE IF NOT EXISTS public.mcq_option_image_metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mcq_id UUID NOT NULL REFERENCES public.election_mcqs(id) ON DELETE CASCADE,
  option_index INTEGER NOT NULL,
  original_image_url TEXT NOT NULL,
  optimized_image_url TEXT,
  thumbnail_url TEXT,
  image_format TEXT CHECK (image_format IN ('jpg', 'png', 'webp')),
  original_size_kb INTEGER,
  optimized_size_kb INTEGER,
  compression_ratio NUMERIC(5,2),
  width_px INTEGER,
  height_px INTEGER,
  alt_text TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(mcq_id, option_index)
);

CREATE INDEX IF NOT EXISTS idx_mcq_option_image_metadata_mcq ON public.mcq_option_image_metadata(mcq_id);

-- Image gallery export tracking
CREATE TABLE IF NOT EXISTS public.mcq_image_gallery_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  export_format TEXT DEFAULT 'zip' CHECK (export_format IN ('zip', 'pdf', 'json')),
  total_images INTEGER DEFAULT 0,
  export_url TEXT,
  export_size_mb NUMERIC(10,2),
  includes_voting_results BOOLEAN DEFAULT true,
  exported_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_mcq_image_gallery_exports_election ON public.mcq_image_gallery_exports(election_id);
CREATE INDEX IF NOT EXISTS idx_mcq_image_gallery_exports_creator ON public.mcq_image_gallery_exports(creator_id);

-- ============================================================
-- 4. RLS POLICIES
-- ============================================================

-- Live question injection queue policies
ALTER TABLE public.live_question_injection_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can manage live question injection"
  ON public.live_question_injection_queue
  FOR ALL
  USING (
    creator_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.elections e
      WHERE e.id = live_question_injection_queue.election_id
      AND e.created_by = auth.uid()
    )
  );

CREATE POLICY "Voters can view broadcasted live questions"
  ON public.live_question_injection_queue
  FOR SELECT
  USING (injection_status = 'broadcasted');

-- Live question broadcasts policies
ALTER TABLE public.live_question_broadcasts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can view broadcast analytics"
  ON public.live_question_broadcasts
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.elections e
      WHERE e.id = live_question_broadcasts.election_id
      AND e.created_by = auth.uid()
    )
  );

-- Live question response analytics policies
ALTER TABLE public.live_question_response_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can view response analytics"
  ON public.live_question_response_analytics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.elections e
      WHERE e.id = live_question_response_analytics.election_id
      AND e.created_by = auth.uid()
    )
  );

-- Performance metrics policies (admin only)
ALTER TABLE public.screen_performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all performance metrics"
  ON public.screen_performance_metrics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles ar
      JOIN public.user_role_assignments ura ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'technical_admin')
    )
  );

CREATE POLICY "System can insert performance metrics"
  ON public.screen_performance_metrics
  FOR INSERT
  WITH CHECK (true);

-- Bottleneck detection policies
ALTER TABLE public.performance_bottleneck_detection ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view bottleneck detection"
  ON public.performance_bottleneck_detection
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles ar
      JOIN public.user_role_assignments ura ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'technical_admin')
    )
  );

-- Optimization recommendations policies
ALTER TABLE public.performance_optimization_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage optimization recommendations"
  ON public.performance_optimization_recommendations
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles ar
      JOIN public.user_role_assignments ura ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'technical_admin')
    )
  );

-- Flame graph data policies
ALTER TABLE public.performance_flame_graph_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view flame graph data"
  ON public.performance_flame_graph_data
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles ar
      JOIN public.user_role_assignments ura ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'technical_admin')
    )
  );

-- Performance timeline events policies
ALTER TABLE public.performance_timeline_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view timeline events"
  ON public.performance_timeline_events
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles ar
      JOIN public.user_role_assignments ura ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'technical_admin')
    )
  );

CREATE POLICY "System can insert timeline events"
  ON public.performance_timeline_events
  FOR INSERT
  WITH CHECK (true);

-- Performance regression tracking policies
ALTER TABLE public.performance_regression_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view regression tracking"
  ON public.performance_regression_tracking
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_roles ar
      JOIN public.user_role_assignments ura ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'technical_admin')
    )
  );

-- MCQ option image metadata policies
ALTER TABLE public.mcq_option_image_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can manage option image metadata"
  ON public.mcq_option_image_metadata
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.election_mcqs em
      JOIN public.elections e ON em.election_id = e.id
      WHERE em.id = mcq_option_image_metadata.mcq_id
      AND e.created_by = auth.uid()
    )
  );

CREATE POLICY "Voters can view option image metadata"
  ON public.mcq_option_image_metadata
  FOR SELECT
  USING (true);

-- MCQ image gallery exports policies
ALTER TABLE public.mcq_image_gallery_exports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can manage their image gallery exports"
  ON public.mcq_image_gallery_exports
  FOR ALL
  USING (creator_id = auth.uid());

-- ============================================================
-- 5. FUNCTIONS
-- ============================================================

-- Function to broadcast live question to active voters
CREATE OR REPLACE FUNCTION broadcast_live_question(
  p_injection_id UUID,
  p_election_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_active_voters_count INTEGER;
  v_mcq_id UUID;
  v_question_data JSONB;
BEGIN
  -- Get active voters count (voters who have accessed the election in last 10 minutes)
  SELECT COUNT(DISTINCT voter_id) INTO v_active_voters_count
  FROM public.voter_video_watch_progress
  WHERE election_id = p_election_id
  AND last_watched_at > NOW() - INTERVAL '10 minutes';

  -- Get question data from injection queue
  SELECT jsonb_build_object(
    'question_text', question_text,
    'options', options,
    'correct_answer_index', correct_answer_index,
    'question_image_url', question_image_url,
    'difficulty_level', difficulty_level
  ) INTO v_question_data
  FROM public.live_question_injection_queue
  WHERE id = p_injection_id;

  -- Insert into election_mcqs as live-injected question
  INSERT INTO public.election_mcqs (
    election_id,
    question_text,
    question_order,
    options,
    correct_answer_index,
    question_image_url,
    difficulty_level,
    is_required,
    is_live_injected,
    injection_id,
    injected_at
  )
  SELECT
    p_election_id,
    v_question_data->>'question_text',
    COALESCE(MAX(question_order), 0) + 1,
    (v_question_data->>'options')::jsonb,
    (v_question_data->>'correct_answer_index')::integer,
    v_question_data->>'question_image_url',
    v_question_data->>'difficulty_level',
    true,
    true,
    p_injection_id,
    NOW()
  FROM public.election_mcqs
  WHERE election_id = p_election_id
  RETURNING id INTO v_mcq_id;

  -- Update injection queue status
  UPDATE public.live_question_injection_queue
  SET injection_status = 'broadcasted',
      broadcasted_at = NOW(),
      updated_at = NOW()
  WHERE id = p_injection_id;

  -- Record broadcast tracking
  INSERT INTO public.live_question_broadcasts (
    injection_id,
    election_id,
    active_voters_count,
    notification_sent_count,
    broadcasted_at
  ) VALUES (
    p_injection_id,
    p_election_id,
    v_active_voters_count,
    v_active_voters_count,
    NOW()
  );

  -- Initialize response analytics
  INSERT INTO public.live_question_response_analytics (
    injection_id,
    mcq_id,
    election_id,
    is_live_injected
  ) VALUES (
    p_injection_id,
    v_mcq_id,
    p_election_id,
    true
  );

  RETURN jsonb_build_object(
    'success', true,
    'mcq_id', v_mcq_id,
    'active_voters_count', v_active_voters_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to detect performance bottlenecks
CREATE OR REPLACE FUNCTION detect_performance_bottlenecks(
  p_screen_name TEXT
) RETURNS TABLE (
  bottleneck_type TEXT,
  severity TEXT,
  current_value NUMERIC,
  threshold_value NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH recent_metrics AS (
    SELECT
      screen_name,
      AVG(cpu_usage_percentage) as avg_cpu,
      AVG(memory_heap_mb + memory_stack_mb) as avg_memory,
      AVG(network_bandwidth_mbps) as avg_network,
      AVG(frames_per_second) as avg_fps
    FROM public.screen_performance_metrics
    WHERE screen_name = p_screen_name
    AND recorded_at > NOW() - INTERVAL '1 hour'
    GROUP BY screen_name
  )
  SELECT
    'cpu'::TEXT,
    CASE
      WHEN avg_cpu > 90 THEN 'critical'
      WHEN avg_cpu > 70 THEN 'high'
      WHEN avg_cpu > 50 THEN 'medium'
      ELSE 'low'
    END::TEXT,
    avg_cpu,
    70.00::NUMERIC
  FROM recent_metrics
  WHERE avg_cpu > 70
  
  UNION ALL
  
  SELECT
    'memory'::TEXT,
    CASE
      WHEN avg_memory > 1000 THEN 'critical'
      WHEN avg_memory > 500 THEN 'high'
      WHEN avg_memory > 300 THEN 'medium'
      ELSE 'low'
    END::TEXT,
    avg_memory,
    500.00::NUMERIC
  FROM recent_metrics
  WHERE avg_memory > 500
  
  UNION ALL
  
  SELECT
    'network'::TEXT,
    CASE
      WHEN avg_network > 10 THEN 'critical'
      WHEN avg_network > 5 THEN 'high'
      WHEN avg_network > 3 THEN 'medium'
      ELSE 'low'
    END::TEXT,
    avg_network,
    5.00::NUMERIC
  FROM recent_metrics
  WHERE avg_network > 5
  
  UNION ALL
  
  SELECT
    'rendering'::TEXT,
    CASE
      WHEN avg_fps < 30 THEN 'critical'
      WHEN avg_fps < 45 THEN 'high'
      WHEN avg_fps < 55 THEN 'medium'
      ELSE 'low'
    END::TEXT,
    avg_fps,
    45.00::NUMERIC
  FROM recent_metrics
  WHERE avg_fps < 45;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate optimization recommendations
CREATE OR REPLACE FUNCTION generate_optimization_recommendations(
  p_bottleneck_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_bottleneck_type TEXT;
  v_screen_name TEXT;
  v_recommendations JSONB;
BEGIN
  SELECT bottleneck_type, screen_name
  INTO v_bottleneck_type, v_screen_name
  FROM public.performance_bottleneck_detection
  WHERE id = p_bottleneck_id;

  v_recommendations := CASE v_bottleneck_type
    WHEN 'cpu' THEN jsonb_build_object(
      'type', 'reduce_rebuilds',
      'playbook', jsonb_build_array(
        'Use const constructors for widgets',
        'Implement shouldRebuild checks in custom widgets',
        'Move expensive computations outside build method',
        'Use RepaintBoundary for complex widgets'
      ),
      'priority', 85
    )
    WHEN 'memory' THEN jsonb_build_object(
      'type', 'lazy_load',
      'playbook', jsonb_build_array(
        'Implement lazy loading for lists',
        'Use ListView.builder instead of ListView',
        'Dispose controllers and streams properly',
        'Optimize image caching strategy'
      ),
      'priority', 90
    )
    WHEN 'network' THEN jsonb_build_object(
      'type', 'optimize_network',
      'playbook', jsonb_build_array(
        'Implement request batching',
        'Add response caching layer',
        'Reduce payload size with field selection',
        'Use pagination for large datasets'
      ),
      'priority', 80
    )
    WHEN 'rendering' THEN jsonb_build_object(
      'type', 'memoization',
      'playbook', jsonb_build_array(
        'Use Selector for expensive computations',
        'Implement widget memoization',
        'Reduce animation complexity',
        'Optimize image rendering with CachedNetworkImage'
      ),
      'priority', 75
    )
    ELSE jsonb_build_object('type', 'general', 'playbook', '[]'::jsonb, 'priority', 50)
  END;

  INSERT INTO public.performance_optimization_recommendations (
    bottleneck_id,
    screen_name,
    recommendation_type,
    priority_score,
    actionable_playbook,
    estimated_improvement_percentage
  ) VALUES (
    p_bottleneck_id,
    v_screen_name,
    v_recommendations->>'type',
    (v_recommendations->>'priority')::integer,
    v_recommendations->'playbook',
    CASE v_bottleneck_type
      WHEN 'cpu' THEN 25.00
      WHEN 'memory' THEN 30.00
      WHEN 'network' THEN 35.00
      WHEN 'rendering' THEN 20.00
      ELSE 10.00
    END
  );

  RETURN v_recommendations;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 6. TRIGGERS
-- ============================================================

-- Trigger to auto-detect bottlenecks on metric insert
CREATE OR REPLACE FUNCTION auto_detect_bottlenecks_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_bottleneck_id UUID;
BEGIN
  -- Check CPU bottleneck
  IF NEW.cpu_usage_percentage > 70 THEN
    INSERT INTO public.performance_bottleneck_detection (
      screen_name,
      bottleneck_type,
      severity,
      threshold_exceeded,
      current_value,
      threshold_value
    ) VALUES (
      NEW.screen_name,
      'cpu',
      CASE
        WHEN NEW.cpu_usage_percentage > 90 THEN 'critical'
        WHEN NEW.cpu_usage_percentage > 70 THEN 'high'
        ELSE 'medium'
      END,
      'CPU usage exceeds 70%',
      NEW.cpu_usage_percentage,
      70.00
    ) RETURNING id INTO v_bottleneck_id;
    
    PERFORM generate_optimization_recommendations(v_bottleneck_id);
  END IF;

  -- Check memory bottleneck
  IF (NEW.memory_heap_mb + NEW.memory_stack_mb) > 500 THEN
    INSERT INTO public.performance_bottleneck_detection (
      screen_name,
      bottleneck_type,
      severity,
      threshold_exceeded,
      current_value,
      threshold_value
    ) VALUES (
      NEW.screen_name,
      'memory',
      CASE
        WHEN (NEW.memory_heap_mb + NEW.memory_stack_mb) > 1000 THEN 'critical'
        WHEN (NEW.memory_heap_mb + NEW.memory_stack_mb) > 500 THEN 'high'
        ELSE 'medium'
      END,
      'Memory usage exceeds 500MB',
      NEW.memory_heap_mb + NEW.memory_stack_mb,
      500.00
    ) RETURNING id INTO v_bottleneck_id;
    
    PERFORM generate_optimization_recommendations(v_bottleneck_id);
  END IF;

  -- Check network bottleneck
  IF NEW.network_bandwidth_mbps > 5 THEN
    INSERT INTO public.performance_bottleneck_detection (
      screen_name,
      bottleneck_type,
      severity,
      threshold_exceeded,
      current_value,
      threshold_value
    ) VALUES (
      NEW.screen_name,
      'network',
      'high',
      'Network bandwidth exceeds 5MB/s',
      NEW.network_bandwidth_mbps,
      5.00
    ) RETURNING id INTO v_bottleneck_id;
    
    PERFORM generate_optimization_recommendations(v_bottleneck_id);
  END IF;

  -- Check rendering bottleneck
  IF NEW.frames_per_second < 45 THEN
    INSERT INTO public.performance_bottleneck_detection (
      screen_name,
      bottleneck_type,
      severity,
      threshold_exceeded,
      current_value,
      threshold_value
    ) VALUES (
      NEW.screen_name,
      'rendering',
      CASE
        WHEN NEW.frames_per_second < 30 THEN 'critical'
        WHEN NEW.frames_per_second < 45 THEN 'high'
        ELSE 'medium'
      END,
      'Frame rate below 45 FPS',
      NEW.frames_per_second,
      45.00
    ) RETURNING id INTO v_bottleneck_id;
    
    PERFORM generate_optimization_recommendations(v_bottleneck_id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_auto_detect_bottlenecks ON public.screen_performance_metrics;
CREATE TRIGGER trigger_auto_detect_bottlenecks
  AFTER INSERT ON public.screen_performance_metrics
  FOR EACH ROW
  EXECUTE FUNCTION auto_detect_bottlenecks_trigger();

-- Trigger to update live question response analytics
CREATE OR REPLACE FUNCTION update_live_question_analytics_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_injection_id UUID;
BEGIN
  -- Get injection_id from mcq
  SELECT injection_id INTO v_injection_id
  FROM public.election_mcqs
  WHERE id = NEW.mcq_id
  AND is_live_injected = true;

  IF v_injection_id IS NOT NULL THEN
    -- Update response analytics
    UPDATE public.live_question_response_analytics
    SET
      total_responses = total_responses + 1,
      correct_responses = correct_responses + CASE WHEN NEW.is_correct THEN 1 ELSE 0 END,
      response_rate = (
        SELECT (COUNT(DISTINCT voter_id)::NUMERIC / NULLIF(active_voters_count, 0) * 100)
        FROM public.voter_mcq_responses vmr
        JOIN public.live_question_broadcasts lqb ON lqb.injection_id = v_injection_id
        WHERE vmr.mcq_id = NEW.mcq_id
      ),
      updated_at = NOW()
    WHERE injection_id = v_injection_id;

    -- Update broadcast engagement rate
    UPDATE public.live_question_broadcasts
    SET
      response_count = response_count + 1,
      engagement_rate = (
        SELECT (COUNT(DISTINCT voter_id)::NUMERIC / NULLIF(active_voters_count, 0) * 100)
        FROM public.voter_mcq_responses vmr
        WHERE vmr.mcq_id = NEW.mcq_id
      )
    WHERE injection_id = v_injection_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_live_question_analytics ON public.voter_mcq_responses;
CREATE TRIGGER trigger_update_live_question_analytics
  AFTER INSERT ON public.voter_mcq_responses
  FOR EACH ROW
  EXECUTE FUNCTION update_live_question_analytics_trigger();