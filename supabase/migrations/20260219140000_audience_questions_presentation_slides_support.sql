-- Audience Questions & Presentation Slides Support Tables Migration
-- Timestamp: 20260219140000
-- Description: Supporting tables for audience questions voting/answers and presentation slides metadata/analytics

-- ============================================================
-- 1. AUDIENCE QUESTIONS SUPPORTING TABLES
-- ============================================================

-- Question votes table for upvoting/downvoting
CREATE TABLE IF NOT EXISTS public.question_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.audience_questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('upvote', 'downvote')),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(question_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_question_votes_question_id ON public.question_votes(question_id);
CREATE INDEX IF NOT EXISTS idx_question_votes_user_id ON public.question_votes(user_id);

-- Question answers table for creator responses
CREATE TABLE IF NOT EXISTS public.question_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.audience_questions(id) ON DELETE CASCADE,
  answered_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  answer_text TEXT NOT NULL,
  is_live BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_question_answers_question_id ON public.question_answers(question_id);
CREATE INDEX IF NOT EXISTS idx_question_answers_answered_by ON public.question_answers(answered_by);

-- Question moderation logs
CREATE TABLE IF NOT EXISTS public.question_moderation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.audience_questions(id) ON DELETE CASCADE,
  moderator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('approve', 'reject', 'flag', 'unflag')),
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_question_moderation_logs_question_id ON public.question_moderation_logs(question_id);

-- ============================================================
-- 2. PRESENTATION SLIDES SUPPORTING TABLES
-- ============================================================

-- Slide metadata table for speaker notes and timing
CREATE TABLE IF NOT EXISTS public.slide_metadata (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slide_id UUID NOT NULL REFERENCES public.presentation_slides(id) ON DELETE CASCADE,
  speaker_notes TEXT,
  duration_seconds INTEGER DEFAULT 0,
  auto_advance BOOLEAN DEFAULT false,
  bookmarked_by UUID[] DEFAULT ARRAY[]::UUID[],
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(slide_id)
);

CREATE INDEX IF NOT EXISTS idx_slide_metadata_slide_id ON public.slide_metadata(slide_id);

-- Slide votes table for slide-specific voting
CREATE TABLE IF NOT EXISTS public.slide_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slide_id UUID NOT NULL REFERENCES public.presentation_slides(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  vote_option TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(slide_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_slide_votes_slide_id ON public.slide_votes(slide_id);
CREATE INDEX IF NOT EXISTS idx_slide_votes_user_id ON public.slide_votes(user_id);

-- Slide analytics table for tracking views and engagement
CREATE TABLE IF NOT EXISTS public.slide_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slide_id UUID NOT NULL REFERENCES public.presentation_slides(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  view_count INTEGER DEFAULT 0,
  time_spent_seconds INTEGER DEFAULT 0,
  interaction_count INTEGER DEFAULT 0,
  last_viewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_slide_analytics_slide_id ON public.slide_analytics(slide_id);
CREATE INDEX IF NOT EXISTS idx_slide_analytics_user_id ON public.slide_analytics(user_id);

-- Presentation deck files table for PDF/PowerPoint storage
CREATE TABLE IF NOT EXISTS public.presentation_deck_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  created_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL CHECK (file_type IN ('pdf', 'pptx')),
  file_size_bytes BIGINT,
  total_slides INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_presentation_deck_files_election_id ON public.presentation_deck_files(election_id);
CREATE INDEX IF NOT EXISTS idx_presentation_deck_files_created_by ON public.presentation_deck_files(created_by);

-- ============================================================
-- 3. ENABLE RLS
-- ============================================================

ALTER TABLE public.question_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_moderation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slide_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slide_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slide_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.presentation_deck_files ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 4. RLS POLICIES
-- ============================================================

-- Question votes policies
DROP POLICY IF EXISTS "users_manage_own_question_votes" ON public.question_votes;
CREATE POLICY "users_manage_own_question_votes"
ON public.question_votes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "public_view_question_votes" ON public.question_votes;
CREATE POLICY "public_view_question_votes"
ON public.question_votes
FOR SELECT
TO public
USING (true);

-- Question answers policies
DROP POLICY IF EXISTS "creators_manage_question_answers" ON public.question_answers;
CREATE POLICY "creators_manage_question_answers"
ON public.question_answers
FOR ALL
TO authenticated
USING (answered_by = auth.uid())
WITH CHECK (answered_by = auth.uid());

DROP POLICY IF EXISTS "public_view_question_answers" ON public.question_answers;
CREATE POLICY "public_view_question_answers"
ON public.question_answers
FOR SELECT
TO public
USING (true);

-- Question moderation logs policies
DROP POLICY IF EXISTS "moderators_manage_logs" ON public.question_moderation_logs;
CREATE POLICY "moderators_manage_logs"
ON public.question_moderation_logs
FOR ALL
TO authenticated
USING (moderator_id = auth.uid())
WITH CHECK (moderator_id = auth.uid());

-- Slide metadata policies
DROP POLICY IF EXISTS "creators_manage_slide_metadata" ON public.slide_metadata;
CREATE POLICY "creators_manage_slide_metadata"
ON public.slide_metadata
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.presentation_slides ps
    WHERE ps.id = slide_id AND ps.created_by = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.presentation_slides ps
    WHERE ps.id = slide_id AND ps.created_by = auth.uid()
  )
);

DROP POLICY IF EXISTS "public_view_slide_metadata" ON public.slide_metadata;
CREATE POLICY "public_view_slide_metadata"
ON public.slide_metadata
FOR SELECT
TO public
USING (true);

-- Slide votes policies
DROP POLICY IF EXISTS "users_manage_own_slide_votes" ON public.slide_votes;
CREATE POLICY "users_manage_own_slide_votes"
ON public.slide_votes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "public_view_slide_votes" ON public.slide_votes;
CREATE POLICY "public_view_slide_votes"
ON public.slide_votes
FOR SELECT
TO public
USING (true);

-- Slide analytics policies
DROP POLICY IF EXISTS "users_manage_own_slide_analytics" ON public.slide_analytics;
CREATE POLICY "users_manage_own_slide_analytics"
ON public.slide_analytics
FOR ALL
TO authenticated
USING (user_id = auth.uid() OR user_id IS NULL)
WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

-- Presentation deck files policies
DROP POLICY IF EXISTS "creators_manage_deck_files" ON public.presentation_deck_files;
CREATE POLICY "creators_manage_deck_files"
ON public.presentation_deck_files
FOR ALL
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS "public_view_deck_files" ON public.presentation_deck_files;
CREATE POLICY "public_view_deck_files"
ON public.presentation_deck_files
FOR SELECT
TO public
USING (true);

-- ============================================================
-- 5. FUNCTIONS FOR VOTE COUNT UPDATES
-- ============================================================

-- Function to update question vote counts
CREATE OR REPLACE FUNCTION public.update_question_vote_counts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.vote_type = 'upvote' THEN
      UPDATE public.audience_questions
      SET upvotes = upvotes + 1
      WHERE id = NEW.question_id;
    ELSIF NEW.vote_type = 'downvote' THEN
      UPDATE public.audience_questions
      SET downvotes = downvotes + 1
      WHERE id = NEW.question_id;
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    IF OLD.vote_type = 'upvote' THEN
      UPDATE public.audience_questions
      SET upvotes = GREATEST(upvotes - 1, 0)
      WHERE id = OLD.question_id;
    ELSIF OLD.vote_type = 'downvote' THEN
      UPDATE public.audience_questions
      SET downvotes = GREATEST(downvotes - 1, 0)
      WHERE id = OLD.question_id;
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.vote_type = 'upvote' AND NEW.vote_type = 'downvote' THEN
      UPDATE public.audience_questions
      SET upvotes = GREATEST(upvotes - 1, 0),
          downvotes = downvotes + 1
      WHERE id = NEW.question_id;
    ELSIF OLD.vote_type = 'downvote' AND NEW.vote_type = 'upvote' THEN
      UPDATE public.audience_questions
      SET downvotes = GREATEST(downvotes - 1, 0),
          upvotes = upvotes + 1
      WHERE id = NEW.question_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- ============================================================
-- 6. TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS trigger_update_question_vote_counts ON public.question_votes;
CREATE TRIGGER trigger_update_question_vote_counts
AFTER INSERT OR UPDATE OR DELETE ON public.question_votes
FOR EACH ROW
EXECUTE FUNCTION public.update_question_vote_counts();

-- ============================================================
-- 7. MOCK DATA
-- ============================================================

DO $$
DECLARE
  existing_election_id UUID;
  existing_user_id UUID;
  existing_creator_id UUID;
  sample_question_id UUID;
  sample_slide_id UUID;
BEGIN
  -- Get existing election and users
  SELECT id INTO existing_election_id FROM public.elections LIMIT 1;
  SELECT id INTO existing_user_id FROM public.user_profiles WHERE id != (SELECT created_by FROM public.elections LIMIT 1) LIMIT 1;
  SELECT created_by INTO existing_creator_id FROM public.elections LIMIT 1;

  IF existing_election_id IS NOT NULL AND existing_user_id IS NOT NULL AND existing_creator_id IS NOT NULL THEN
    -- Create sample audience question
    INSERT INTO public.audience_questions (id, election_id, submitted_by, question_text, moderation_status)
    VALUES (
      gen_random_uuid(),
      existing_election_id,
      existing_user_id,
      'What are the key benefits of this proposal for small businesses?',
      'approved'
    )
    ON CONFLICT (id) DO NOTHING
    RETURNING id INTO sample_question_id;

    IF sample_question_id IS NULL THEN
      SELECT id INTO sample_question_id FROM public.audience_questions LIMIT 1;
    END IF;

    -- Create sample question votes
    IF sample_question_id IS NOT NULL THEN
      INSERT INTO public.question_votes (question_id, user_id, vote_type)
      VALUES 
        (sample_question_id, existing_user_id, 'upvote')
      ON CONFLICT (question_id, user_id) DO NOTHING;

      -- Create sample question answer
      INSERT INTO public.question_answers (question_id, answered_by, answer_text, is_live)
      VALUES (
        sample_question_id,
        existing_creator_id,
        'Great question! Small businesses will benefit from reduced regulatory burden and tax incentives.',
        true
      )
      ON CONFLICT (id) DO NOTHING;
    END IF;

    -- Create sample presentation deck file
    INSERT INTO public.presentation_deck_files (election_id, created_by, file_name, file_url, file_type, total_slides)
    VALUES (
      existing_election_id,
      existing_creator_id,
      'Election Proposal Slides.pdf',
      'https://example.com/slides/sample.pdf',
      'pdf',
      10
    )
    ON CONFLICT (id) DO NOTHING;

    -- Create sample presentation slide
    INSERT INTO public.presentation_slides (id, election_id, created_by, title, content, slide_order)
    VALUES (
      gen_random_uuid(),
      existing_election_id,
      existing_creator_id,
      'Introduction',
      'Welcome to our election proposal presentation',
      1
    )
    ON CONFLICT (id) DO NOTHING
    RETURNING id INTO sample_slide_id;

    IF sample_slide_id IS NULL THEN
      SELECT id INTO sample_slide_id FROM public.presentation_slides LIMIT 1;
    END IF;

    -- Create sample slide metadata
    IF sample_slide_id IS NOT NULL THEN
      INSERT INTO public.slide_metadata (slide_id, speaker_notes, duration_seconds, auto_advance)
      VALUES (
        sample_slide_id,
        'Start with a warm welcome and brief overview of the agenda',
        30,
        true
      )
      ON CONFLICT (slide_id) DO NOTHING;

      -- Create sample slide analytics
      INSERT INTO public.slide_analytics (slide_id, user_id, view_count, time_spent_seconds)
      VALUES (
        sample_slide_id,
        existing_user_id,
        5,
        120
      )
      ON CONFLICT (id) DO NOTHING;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;