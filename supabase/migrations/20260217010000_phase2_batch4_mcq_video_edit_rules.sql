-- Phase 2 Batch 4: Election Enhancement Features
-- MCQ Creation & Answering System, Video Watch Time Enforcement, Election Edit/Delete Rules Engine
-- Timestamp: 20260217010000

-- ============================================================
-- 1. MCQ SYSTEM TABLES (Enhanced from existing schema)
-- ============================================================

-- Main MCQ questions table (uses simpler JSONB approach)
CREATE TABLE IF NOT EXISTS public.election_mcqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_order INTEGER NOT NULL DEFAULT 1,
  options JSONB NOT NULL DEFAULT '[]'::jsonb,
  correct_answer_index INTEGER NOT NULL,
  question_image_url TEXT,
  difficulty_level TEXT DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_election_mcqs_election ON public.election_mcqs(election_id);
CREATE INDEX IF NOT EXISTS idx_election_mcqs_order ON public.election_mcqs(election_id, question_order);

-- Voter MCQ responses with scoring
CREATE TABLE IF NOT EXISTS public.voter_mcq_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mcq_id UUID NOT NULL REFERENCES public.election_mcqs(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  selected_answer_index INTEGER NOT NULL,
  is_correct BOOLEAN NOT NULL,
  attempt_number INTEGER DEFAULT 1,
  answered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(mcq_id, voter_id, attempt_number)
);

CREATE INDEX IF NOT EXISTS idx_voter_mcq_responses_voter ON public.voter_mcq_responses(voter_id);
CREATE INDEX IF NOT EXISTS idx_voter_mcq_responses_election ON public.voter_mcq_responses(election_id);
CREATE INDEX IF NOT EXISTS idx_voter_mcq_responses_mcq ON public.voter_mcq_responses(mcq_id);

-- MCQ attempt tracking for retry logic
CREATE TABLE IF NOT EXISTS public.voter_mcq_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  voter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL DEFAULT 1,
  total_questions INTEGER NOT NULL,
  correct_answers INTEGER NOT NULL,
  score_percentage NUMERIC(5,2) NOT NULL,
  passed BOOLEAN NOT NULL,
  attempted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(voter_id, election_id, attempt_number)
);

CREATE INDEX IF NOT EXISTS idx_voter_mcq_attempts_voter ON public.voter_mcq_attempts(voter_id);
CREATE INDEX IF NOT EXISTS idx_voter_mcq_attempts_election ON public.voter_mcq_attempts(election_id);

-- Add MCQ settings to elections table
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS require_mcq BOOLEAN DEFAULT false;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS mcq_passing_score_percentage INTEGER DEFAULT 70;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS mcq_max_attempts INTEGER DEFAULT 3;

-- ============================================================
-- 2. VIDEO WATCH TIME ENFORCEMENT TABLES
-- ============================================================

-- Video watch progress tracking (prevents refresh bypass)
CREATE TABLE IF NOT EXISTS public.voter_video_watch_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  video_index INTEGER NOT NULL DEFAULT 0,
  watch_duration_seconds INTEGER NOT NULL DEFAULT 0,
  total_video_duration_seconds INTEGER,
  watch_percentage NUMERIC(5,2) NOT NULL DEFAULT 0.00,
  completed_requirement BOOLEAN DEFAULT false,
  last_watched_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, voter_id, video_index)
);

CREATE INDEX IF NOT EXISTS idx_voter_video_watch_election ON public.voter_video_watch_progress(election_id);
CREATE INDEX IF NOT EXISTS idx_voter_video_watch_voter ON public.voter_video_watch_progress(voter_id);

-- Video analytics tracking
CREATE TABLE IF NOT EXISTS public.video_watch_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  video_index INTEGER NOT NULL DEFAULT 0,
  total_views INTEGER DEFAULT 0,
  total_completions INTEGER DEFAULT 0,
  average_watch_time_seconds NUMERIC(10,2) DEFAULT 0.00,
  completion_rate_percentage NUMERIC(5,2) DEFAULT 0.00,
  last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, video_index)
);

CREATE INDEX IF NOT EXISTS idx_video_watch_analytics_election ON public.video_watch_analytics(election_id);

-- Add video settings to elections table
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS require_video_watch BOOLEAN DEFAULT false;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS video_urls JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS video_min_watch_seconds INTEGER DEFAULT 0;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS video_min_watch_percentage INTEGER DEFAULT 0;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS video_watch_enforcement_type TEXT DEFAULT 'seconds' CHECK (video_watch_enforcement_type IN ('seconds', 'percentage'));

-- ============================================================
-- 3. ELECTION EDIT/DELETE RULES ENGINE
-- ============================================================

-- Add edit/delete rule columns to elections table
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS first_vote_at TIMESTAMPTZ;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS can_edit BOOLEAN DEFAULT true;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS can_delete BOOLEAN DEFAULT true;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS max_deadline_extension_months INTEGER DEFAULT 6;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS deleted_by UUID REFERENCES public.user_profiles(id);

-- Election edit history tracking
CREATE TABLE IF NOT EXISTS public.election_edit_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  edited_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  changed_fields JSONB NOT NULL,
  previous_values JSONB NOT NULL,
  new_values JSONB NOT NULL,
  edit_type TEXT NOT NULL CHECK (edit_type IN ('pre_vote', 'post_vote', 'admin_override')),
  edited_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_election_edit_history_election ON public.election_edit_history(election_id);
CREATE INDEX IF NOT EXISTS idx_election_edit_history_edited_at ON public.election_edit_history(edited_at DESC);

-- Admin override log for destructive actions
CREATE TABLE IF NOT EXISTS public.election_admin_overrides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  admin_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL CHECK (action_type IN ('force_edit', 'force_delete', 'extend_deadline', 'modify_prize')),
  justification TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  performed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_election_admin_overrides_election ON public.election_admin_overrides(election_id);
CREATE INDEX IF NOT EXISTS idx_election_admin_overrides_admin ON public.election_admin_overrides(admin_id);

-- ============================================================
-- 4. FUNCTIONS FOR BUSINESS LOGIC
-- ============================================================

-- Function to check if election can be edited
CREATE OR REPLACE FUNCTION public.can_edit_election(
  p_election_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_first_vote_at TIMESTAMPTZ;
  v_can_edit BOOLEAN;
  v_vote_count INTEGER;
  v_result JSONB;
BEGIN
  SELECT first_vote_at, can_edit, vote_count
  INTO v_first_vote_at, v_can_edit, v_vote_count
  FROM public.elections
  WHERE id = p_election_id;

  -- If no votes cast, full edit allowed
  IF v_first_vote_at IS NULL OR v_vote_count = 0 THEN
    v_result := jsonb_build_object(
      'can_edit', true,
      'can_edit_all_fields', true,
      'can_delete', true,
      'reason', 'No votes cast yet - full edit and delete allowed'
    );
  ELSE
    -- After votes cast, restricted edit only
    v_result := jsonb_build_object(
      'can_edit', v_can_edit,
      'can_edit_all_fields', false,
      'can_delete', false,
      'allowed_edits', jsonb_build_array('deadline', 'prize_amount'),
      'reason', 'Votes already cast - only deadline extension and prize editing allowed'
    );
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate MCQ passing score
CREATE OR REPLACE FUNCTION public.calculate_mcq_score(
  p_voter_id UUID,
  p_election_id UUID,
  p_attempt_number INTEGER
)
RETURNS JSONB AS $$
DECLARE
  v_total_questions INTEGER;
  v_correct_answers INTEGER;
  v_score_percentage NUMERIC(5,2);
  v_passing_score INTEGER;
  v_passed BOOLEAN;
  v_result JSONB;
BEGIN
  -- Get total questions for election
  SELECT COUNT(*) INTO v_total_questions
  FROM public.election_mcqs
  WHERE election_id = p_election_id;

  -- Get correct answers count
  SELECT COUNT(*) INTO v_correct_answers
  FROM public.voter_mcq_responses
  WHERE voter_id = p_voter_id
    AND election_id = p_election_id
    AND attempt_number = p_attempt_number
    AND is_correct = true;

  -- Calculate score percentage
  IF v_total_questions > 0 THEN
    v_score_percentage := (v_correct_answers::NUMERIC / v_total_questions::NUMERIC) * 100;
  ELSE
    v_score_percentage := 0;
  END IF;

  -- Get passing score requirement
  SELECT mcq_passing_score_percentage INTO v_passing_score
  FROM public.elections
  WHERE id = p_election_id;

  -- Determine if passed
  v_passed := v_score_percentage >= v_passing_score;

  -- Build result
  v_result := jsonb_build_object(
    'total_questions', v_total_questions,
    'correct_answers', v_correct_answers,
    'score_percentage', v_score_percentage,
    'passing_score', v_passing_score,
    'passed', v_passed
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update video watch analytics
CREATE OR REPLACE FUNCTION public.update_video_analytics(
  p_election_id UUID,
  p_video_index INTEGER
)
RETURNS VOID AS $$
DECLARE
  v_total_views INTEGER;
  v_total_completions INTEGER;
  v_avg_watch_time NUMERIC(10,2);
  v_completion_rate NUMERIC(5,2);
BEGIN
  -- Calculate analytics
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE completed_requirement = true),
    AVG(watch_duration_seconds),
    (COUNT(*) FILTER (WHERE completed_requirement = true)::NUMERIC / NULLIF(COUNT(*)::NUMERIC, 0)) * 100
  INTO v_total_views, v_total_completions, v_avg_watch_time, v_completion_rate
  FROM public.voter_video_watch_progress
  WHERE election_id = p_election_id
    AND video_index = p_video_index;

  -- Upsert analytics
  INSERT INTO public.video_watch_analytics (
    election_id,
    video_index,
    total_views,
    total_completions,
    average_watch_time_seconds,
    completion_rate_percentage,
    last_updated
  ) VALUES (
    p_election_id,
    p_video_index,
    v_total_views,
    v_total_completions,
    COALESCE(v_avg_watch_time, 0),
    COALESCE(v_completion_rate, 0),
    CURRENT_TIMESTAMP
  )
  ON CONFLICT (election_id, video_index)
  DO UPDATE SET
    total_views = v_total_views,
    total_completions = v_total_completions,
    average_watch_time_seconds = COALESCE(v_avg_watch_time, 0),
    completion_rate_percentage = COALESCE(v_completion_rate, 0),
    last_updated = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to set first_vote_at timestamp
CREATE OR REPLACE FUNCTION public.set_first_vote_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.elections
  SET first_vote_at = CURRENT_TIMESTAMP
  WHERE id = NEW.election_id
    AND first_vote_at IS NULL;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_first_vote_timestamp ON public.votes;
CREATE TRIGGER trigger_set_first_vote_timestamp
  AFTER INSERT ON public.votes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_first_vote_timestamp();

-- ============================================================
-- 5. RLS POLICIES
-- ============================================================

-- MCQ tables policies
ALTER TABLE public.election_mcqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voter_mcq_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voter_mcq_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS election_mcqs_select_policy ON public.election_mcqs;
CREATE POLICY election_mcqs_select_policy ON public.election_mcqs
  FOR SELECT USING (true);

DROP POLICY IF EXISTS election_mcqs_insert_policy ON public.election_mcqs;
CREATE POLICY election_mcqs_insert_policy ON public.election_mcqs
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = election_mcqs.election_id
      AND elections.created_by = auth.uid()
    )
  );

DROP POLICY IF EXISTS election_mcqs_update_policy ON public.election_mcqs;
CREATE POLICY election_mcqs_update_policy ON public.election_mcqs
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = election_mcqs.election_id
      AND elections.created_by = auth.uid()
    )
  );

DROP POLICY IF EXISTS voter_mcq_responses_select_policy ON public.voter_mcq_responses;
CREATE POLICY voter_mcq_responses_select_policy ON public.voter_mcq_responses
  FOR SELECT USING (voter_id = auth.uid());

DROP POLICY IF EXISTS voter_mcq_responses_insert_policy ON public.voter_mcq_responses;
CREATE POLICY voter_mcq_responses_insert_policy ON public.voter_mcq_responses
  FOR INSERT WITH CHECK (voter_id = auth.uid());

DROP POLICY IF EXISTS voter_mcq_attempts_select_policy ON public.voter_mcq_attempts;
CREATE POLICY voter_mcq_attempts_select_policy ON public.voter_mcq_attempts
  FOR SELECT USING (voter_id = auth.uid());

DROP POLICY IF EXISTS voter_mcq_attempts_insert_policy ON public.voter_mcq_attempts;
CREATE POLICY voter_mcq_attempts_insert_policy ON public.voter_mcq_attempts
  FOR INSERT WITH CHECK (voter_id = auth.uid());

-- Video watch progress policies
ALTER TABLE public.voter_video_watch_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_watch_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS voter_video_watch_select_policy ON public.voter_video_watch_progress;
CREATE POLICY voter_video_watch_select_policy ON public.voter_video_watch_progress
  FOR SELECT USING (voter_id = auth.uid());

DROP POLICY IF EXISTS voter_video_watch_insert_policy ON public.voter_video_watch_progress;
CREATE POLICY voter_video_watch_insert_policy ON public.voter_video_watch_progress
  FOR INSERT WITH CHECK (voter_id = auth.uid());

DROP POLICY IF EXISTS voter_video_watch_update_policy ON public.voter_video_watch_progress;
CREATE POLICY voter_video_watch_update_policy ON public.voter_video_watch_progress
  FOR UPDATE USING (voter_id = auth.uid());

DROP POLICY IF EXISTS video_watch_analytics_select_policy ON public.video_watch_analytics;
CREATE POLICY video_watch_analytics_select_policy ON public.video_watch_analytics
  FOR SELECT USING (true);

-- Edit history policies
ALTER TABLE public.election_edit_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_admin_overrides ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS election_edit_history_select_policy ON public.election_edit_history;
CREATE POLICY election_edit_history_select_policy ON public.election_edit_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = election_edit_history.election_id
      AND elections.created_by = auth.uid()
    )
  );

DROP POLICY IF EXISTS election_edit_history_insert_policy ON public.election_edit_history;
CREATE POLICY election_edit_history_insert_policy ON public.election_edit_history
  FOR INSERT WITH CHECK (edited_by = auth.uid());

DROP POLICY IF EXISTS election_admin_overrides_select_policy ON public.election_admin_overrides;
CREATE POLICY election_admin_overrides_select_policy ON public.election_admin_overrides
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- ============================================================
-- 6. COMMENTS FOR DOCUMENTATION
-- ============================================================

COMMENT ON TABLE public.election_mcqs IS 'MCQ questions for elections with JSONB options array';
COMMENT ON TABLE public.voter_mcq_responses IS 'Individual voter responses to MCQ questions with scoring';
COMMENT ON TABLE public.voter_mcq_attempts IS 'MCQ attempt tracking with retry logic (max 3 attempts)';
COMMENT ON TABLE public.voter_video_watch_progress IS 'Video watch progress tracking to prevent refresh bypass';
COMMENT ON TABLE public.video_watch_analytics IS 'Video watch analytics for creators';
COMMENT ON TABLE public.election_edit_history IS 'Audit trail for all election edits with field-level tracking';
COMMENT ON TABLE public.election_admin_overrides IS 'Admin override log for destructive actions with justification';
COMMENT ON FUNCTION public.can_edit_election IS 'Determines edit/delete permissions based on vote status';
COMMENT ON FUNCTION public.calculate_mcq_score IS 'Calculates MCQ score and determines if voter passed';
COMMENT ON FUNCTION public.update_video_analytics IS 'Updates video watch analytics for creator dashboard';