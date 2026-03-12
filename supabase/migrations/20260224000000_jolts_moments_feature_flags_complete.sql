-- Phase 2 & 3 Complete Implementation: Jolts, Moments, Feature Flags, APM
-- Timestamp: 20260224000000

-- ============================================
-- PHASE 2 FEATURE 1: JOLTS VIDEO STUDIO
-- ============================================

-- Jolts Drafts Table (for draft management)
CREATE TABLE IF NOT EXISTS public.jolts_drafts (
  draft_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  video_file_path VARCHAR(500),
  title VARCHAR(200),
  description TEXT,
  hashtags VARCHAR[] DEFAULT '{}',
  category VARCHAR(50),
  privacy VARCHAR(20) DEFAULT 'public' CHECK (privacy IN ('public', 'followers', 'private')),
  thumbnail_url VARCHAR(500),
  duration_seconds INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_jolts_drafts_creator ON public.jolts_drafts(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_jolts_drafts_updated ON public.jolts_drafts(updated_at DESC);

-- ============================================
-- PHASE 2 FEATURE 2: MOMENTS CREATION STUDIO
-- ============================================

-- Enhance carousel_content_moments with interactive elements
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'carousel_content_moments' AND column_name = 'interactive_elements') THEN
    ALTER TABLE public.carousel_content_moments ADD COLUMN interactive_elements JSONB DEFAULT '[]'::jsonb;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'carousel_content_moments' AND column_name = 'music_track_id') THEN
    ALTER TABLE public.carousel_content_moments ADD COLUMN music_track_id UUID;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'carousel_content_moments' AND column_name = 'privacy_settings') THEN
    ALTER TABLE public.carousel_content_moments ADD COLUMN privacy_settings JSONB DEFAULT '{"audience": "all_followers"}'::jsonb;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'carousel_content_moments' AND column_name = 'text_overlays') THEN
    ALTER TABLE public.carousel_content_moments ADD COLUMN text_overlays JSONB DEFAULT '[]'::jsonb;
  END IF;
END $$;

-- Moment Interactions Table (polls, quizzes, reactions)
CREATE TABLE IF NOT EXISTS public.moment_interactions (
  interaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID REFERENCES public.carousel_content_moments(moment_id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  interaction_type VARCHAR(50) NOT NULL CHECK (interaction_type IN ('poll_vote', 'quiz_answer', 'election_vote', 'reaction')),
  interaction_data JSONB NOT NULL,
  interacted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_moment_interactions_moment ON public.moment_interactions(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_interactions_user ON public.moment_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_moment_interactions_type ON public.moment_interactions(interaction_type);

-- Story Highlights Table
CREATE TABLE IF NOT EXISTS public.story_highlights (
  highlight_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  highlight_title VARCHAR(100) NOT NULL,
  cover_image_url VARCHAR(500),
  moment_ids UUID[] DEFAULT '{}',
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_story_highlights_creator ON public.story_highlights(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_story_highlights_order ON public.story_highlights(display_order);

-- ============================================
-- PHASE 3 FEATURE 3: FEATURE FLAG MANAGEMENT
-- ============================================

-- Flag Experiments Table (A/B Testing)
CREATE TABLE IF NOT EXISTS public.flag_experiments (
  experiment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_id UUID REFERENCES public.feature_flags(id) ON DELETE CASCADE,
  variant_configs JSONB NOT NULL,
  traffic_split JSONB NOT NULL,
  success_metric VARCHAR(100),
  tracking_events VARCHAR[] DEFAULT '{}',
  significance_threshold DECIMAL(5,2) DEFAULT 95.00,
  start_date DATE DEFAULT CURRENT_DATE,
  end_date DATE,
  status VARCHAR(20) DEFAULT 'running' CHECK (status IN ('running', 'completed', 'paused')),
  winner_variant VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_flag_experiments_flag ON public.flag_experiments(flag_id);
CREATE INDEX IF NOT EXISTS idx_flag_experiments_status ON public.flag_experiments(status);

-- Flag Usage Log Table
CREATE TABLE IF NOT EXISTS public.flag_usage_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  flag_key VARCHAR(100) NOT NULL,
  evaluated_value BOOLEAN NOT NULL,
  variant VARCHAR(50),
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_flag_usage_log_flag ON public.flag_usage_log(flag_key);
CREATE INDEX IF NOT EXISTS idx_flag_usage_log_user ON public.flag_usage_log(user_id);
CREATE INDEX IF NOT EXISTS idx_flag_usage_log_timestamp ON public.flag_usage_log(timestamp DESC);

-- Flag Archive Table
CREATE TABLE IF NOT EXISTS public.flag_archive (
  archive_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_key VARCHAR(100) NOT NULL,
  flag_data JSONB NOT NULL,
  archived_at TIMESTAMPTZ DEFAULT NOW(),
  archived_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_flag_archive_key ON public.flag_archive(flag_key);
CREATE INDEX IF NOT EXISTS idx_flag_archive_date ON public.flag_archive(archived_at DESC);

-- ============================================
-- PHASE 3 FEATURE 4: DATADOG APM MONITORING
-- ============================================

-- APM Traces Table (optional local caching)
CREATE TABLE IF NOT EXISTS public.apm_traces (
  trace_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  span_id UUID NOT NULL,
  parent_span_id UUID,
  service_name VARCHAR(100) NOT NULL,
  operation_name VARCHAR(200) NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  duration_ms INTEGER NOT NULL,
  tags JSONB DEFAULT '{}'::jsonb,
  error BOOLEAN DEFAULT false,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_apm_traces_service ON public.apm_traces(service_name);
CREATE INDEX IF NOT EXISTS idx_apm_traces_operation ON public.apm_traces(operation_name);
CREATE INDEX IF NOT EXISTS idx_apm_traces_start_time ON public.apm_traces(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_apm_traces_error ON public.apm_traces(error) WHERE error = true;

-- ============================================
-- RLS POLICIES
-- ============================================

-- Jolts Drafts RLS
ALTER TABLE public.jolts_drafts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own drafts" ON public.jolts_drafts;
CREATE POLICY "Users can view their own drafts"
  ON public.jolts_drafts FOR SELECT
  USING (auth.uid() = creator_user_id);

DROP POLICY IF EXISTS "Users can insert their own drafts" ON public.jolts_drafts;
CREATE POLICY "Users can insert their own drafts"
  ON public.jolts_drafts FOR INSERT
  WITH CHECK (auth.uid() = creator_user_id);

DROP POLICY IF EXISTS "Users can update their own drafts" ON public.jolts_drafts;
CREATE POLICY "Users can update their own drafts"
  ON public.jolts_drafts FOR UPDATE
  USING (auth.uid() = creator_user_id);

DROP POLICY IF EXISTS "Users can delete their own drafts" ON public.jolts_drafts;
CREATE POLICY "Users can delete their own drafts"
  ON public.jolts_drafts FOR DELETE
  USING (auth.uid() = creator_user_id);

-- Moment Interactions RLS
ALTER TABLE public.moment_interactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all moment interactions" ON public.moment_interactions;
CREATE POLICY "Users can view all moment interactions"
  ON public.moment_interactions FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert their own interactions" ON public.moment_interactions;
CREATE POLICY "Users can insert their own interactions"
  ON public.moment_interactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Story Highlights RLS
ALTER TABLE public.story_highlights ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all highlights" ON public.story_highlights;
CREATE POLICY "Users can view all highlights"
  ON public.story_highlights FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can manage their own highlights" ON public.story_highlights;
CREATE POLICY "Users can manage their own highlights"
  ON public.story_highlights FOR ALL
  USING (auth.uid() = creator_user_id);

-- Flag Experiments RLS (Admin only)
ALTER TABLE public.flag_experiments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage experiments" ON public.flag_experiments;
CREATE POLICY "Admins can manage experiments"
  ON public.flag_experiments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Flag Usage Log RLS (Admin only)
ALTER TABLE public.flag_usage_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can insert usage logs" ON public.flag_usage_log;
CREATE POLICY "Anyone can insert usage logs"
  ON public.flag_usage_log FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can view usage logs" ON public.flag_usage_log;
CREATE POLICY "Admins can view usage logs"
  ON public.flag_usage_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- APM Traces RLS (Admin only)
ALTER TABLE public.apm_traces ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage APM traces" ON public.apm_traces;
CREATE POLICY "Admins can manage APM traces"
  ON public.apm_traces FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to clean up expired moments
CREATE OR REPLACE FUNCTION cleanup_expired_moments()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.carousel_content_moments
  SET is_active = false
  WHERE expires_at < NOW() AND is_active = true;
END;
$$;

-- Function to calculate A/B test statistical significance
CREATE OR REPLACE FUNCTION calculate_ab_test_significance(
  p_experiment_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_result JSONB;
  v_variant_a_conversions INTEGER;
  v_variant_a_total INTEGER;
  v_variant_b_conversions INTEGER;
  v_variant_b_total INTEGER;
  v_p_value DECIMAL;
BEGIN
  -- Get conversion data for variants
  SELECT 
    COUNT(*) FILTER (WHERE variant = 'A' AND interaction_data->>'converted' = 'true'),
    COUNT(*) FILTER (WHERE variant = 'A'),
    COUNT(*) FILTER (WHERE variant = 'B' AND interaction_data->>'converted' = 'true'),
    COUNT(*) FILTER (WHERE variant = 'B')
  INTO v_variant_a_conversions, v_variant_a_total, v_variant_b_conversions, v_variant_b_total
  FROM public.flag_usage_log
  WHERE flag_key = (SELECT flag_key FROM public.feature_flags f JOIN public.flag_experiments e ON f.id = e.flag_id WHERE e.experiment_id = p_experiment_id);
  
  -- Simple chi-square approximation (for demonstration)
  v_p_value := CASE 
    WHEN v_variant_a_total > 0 AND v_variant_b_total > 0 THEN
      ABS((v_variant_a_conversions::DECIMAL / v_variant_a_total) - (v_variant_b_conversions::DECIMAL / v_variant_b_total)) * 100
    ELSE 0
  END;
  
  v_result := jsonb_build_object(
    'variant_a_conversion_rate', CASE WHEN v_variant_a_total > 0 THEN (v_variant_a_conversions::DECIMAL / v_variant_a_total * 100) ELSE 0 END,
    'variant_b_conversion_rate', CASE WHEN v_variant_b_total > 0 THEN (v_variant_b_conversions::DECIMAL / v_variant_b_total * 100) ELSE 0 END,
    'p_value', v_p_value,
    'is_significant', v_p_value > 5,
    'winner', CASE 
      WHEN v_variant_a_conversions::DECIMAL / NULLIF(v_variant_a_total, 0) > v_variant_b_conversions::DECIMAL / NULLIF(v_variant_b_total, 0) THEN 'A'
      WHEN v_variant_b_conversions::DECIMAL / NULLIF(v_variant_b_total, 0) > v_variant_a_conversions::DECIMAL / NULLIF(v_variant_a_total, 0) THEN 'B'
      ELSE 'tie'
    END
  );
  
  RETURN v_result;
END;
$$;
