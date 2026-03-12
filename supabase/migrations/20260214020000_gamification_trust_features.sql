-- Phase 1 Batch 2: Gamification & Trust Features Migration
-- Timestamp: 20260214020000
-- Description: MCQ system, video requirements, lottery automation, permissions, social features

-- ============================================================
-- 1. TYPES
-- ============================================================

DO $$ BEGIN
  CREATE TYPE public.election_permission_type AS ENUM (
    'public',
    'group_only',
    'country_specific'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.prize_type AS ENUM (
    'monetary',
    'non_monetary',
    'content_revenue'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.election_social_action AS ENUM (
    'like',
    'love',
    'celebrate',
    'support',
    'insightful'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 2. MCQ SYSTEM TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_mcqs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_order INTEGER NOT NULL DEFAULT 1,
  options JSONB NOT NULL DEFAULT '[]'::jsonb,
  correct_answer_index INTEGER,
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.voter_mcq_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mcq_id UUID NOT NULL REFERENCES public.election_mcqs(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  selected_answer_index INTEGER NOT NULL,
  is_correct BOOLEAN,
  answered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(mcq_id, voter_id)
);

-- ============================================================
-- 3. VIDEO WATCH REQUIREMENTS
-- ============================================================

ALTER TABLE public.elections
ADD COLUMN IF NOT EXISTS video_url TEXT,
ADD COLUMN IF NOT EXISTS video_min_watch_seconds INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS video_min_watch_percentage INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS require_video_watch BOOLEAN DEFAULT false;

CREATE TABLE IF NOT EXISTS public.voter_video_watch_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  watch_duration_seconds INTEGER NOT NULL DEFAULT 0,
  watch_percentage INTEGER NOT NULL DEFAULT 0,
  completed_requirement BOOLEAN DEFAULT false,
  last_watched_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, voter_id)
);

-- ============================================================
-- 4. LOTTERY SYSTEM ENHANCEMENTS
-- ============================================================

-- Add voter_id_display to lottery_entries if it exists
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'lottery_entries') THEN
    ALTER TABLE public.lottery_entries ADD COLUMN IF NOT EXISTS voter_id_display TEXT;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.lottery_winner_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lottery_draw_id UUID NOT NULL,
  winner_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  rank INTEGER NOT NULL,
  prize_amount DECIMAL(15,2),
  notification_sent BOOLEAN DEFAULT false,
  notification_sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. ELECTION PERMISSION CONTROLS
-- ============================================================

ALTER TABLE public.elections
ADD COLUMN IF NOT EXISTS permission_type TEXT DEFAULT 'public',
ADD COLUMN IF NOT EXISTS allowed_countries TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS allowed_group_id UUID;

-- Add foreign key constraint if groups table exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'groups') THEN
    ALTER TABLE public.elections
    DROP CONSTRAINT IF EXISTS elections_allowed_group_id_fkey;
    
    ALTER TABLE public.elections
    ADD CONSTRAINT elections_allowed_group_id_fkey 
    FOREIGN KEY (allowed_group_id) REFERENCES public.groups(id);
  END IF;
END $$;

-- ============================================================
-- 6. BIOMETRIC VOTING REQUIREMENT
-- ============================================================

ALTER TABLE public.elections
ADD COLUMN IF NOT EXISTS require_biometric_voting BOOLEAN DEFAULT false;

-- ============================================================
-- 7. PRIZE DISTRIBUTION SYSTEM (Only if not exists from earlier migration)
-- ============================================================

-- The prizes table already exists from migration 20260213010000_phase2_monetization_security.sql
-- We only need to ensure prize_distributions has the prize_id column and foreign key

-- Ensure prize_distributions table exists (should already exist from earlier migration)
CREATE TABLE IF NOT EXISTS public.prize_distributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  winner_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  prize_id UUID,
  rank INTEGER NOT NULL,
  distributed_at TIMESTAMPTZ,
  distribution_status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add prize_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'prize_distributions' 
    AND column_name = 'prize_id'
  ) THEN
    ALTER TABLE public.prize_distributions ADD COLUMN prize_id UUID;
  END IF;
END $$;

-- Add foreign key to prizes table (from earlier migration) only if prize_id column exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'prize_distributions' 
    AND column_name = 'prize_id'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'prizes'
  ) THEN
    ALTER TABLE public.prize_distributions
    DROP CONSTRAINT IF EXISTS prize_distributions_prize_id_fkey;
    
    ALTER TABLE public.prize_distributions
    ADD CONSTRAINT prize_distributions_prize_id_fkey 
    FOREIGN KEY (prize_id) REFERENCES public.prizes(id) ON DELETE CASCADE;
  END IF;
END $$;

-- ============================================================
-- 8. CREATOR BLACKLIST SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.creator_blacklist (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  election_id UUID REFERENCES public.elections(id),
  blacklisted_by UUID REFERENCES public.user_profiles(id),
  blacklisted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  is_active BOOLEAN DEFAULT true,
  appeal_status TEXT DEFAULT 'none',
  appeal_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_creator_blacklist_creator ON public.creator_blacklist(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_blacklist_active ON public.creator_blacklist(is_active);

-- ============================================================
-- 9. ELECTION SOCIAL FEATURES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  comment_text TEXT NOT NULL,
  parent_comment_id UUID REFERENCES public.election_comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_election_comments_election ON public.election_comments(election_id);
CREATE INDEX IF NOT EXISTS idx_election_comments_user ON public.election_comments(user_id);

CREATE TABLE IF NOT EXISTS public.election_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reaction_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, user_id, reaction_type)
);

CREATE INDEX IF NOT EXISTS idx_election_reactions_election ON public.election_reactions(election_id);

CREATE TABLE IF NOT EXISTS public.election_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  share_platform TEXT NOT NULL,
  shared_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_election_shares_election ON public.election_shares(election_id);

ALTER TABLE public.elections
ADD COLUMN IF NOT EXISTS comments_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS reactions_enabled BOOLEAN DEFAULT true;

-- ============================================================
-- 10. VOTE TOTALS VISIBILITY CONTROLS
-- ============================================================

ALTER TABLE public.elections
ADD COLUMN IF NOT EXISTS show_live_results BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS results_visibility_changed_at TIMESTAMPTZ;

-- ============================================================
-- 11. ELECTION EDIT/DELETE RULES
-- ============================================================

ALTER TABLE public.elections
ADD COLUMN IF NOT EXISTS first_vote_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS is_locked BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS max_end_date_extension_months INTEGER DEFAULT 6;

-- ============================================================
-- 12. RLS POLICIES
-- ============================================================

-- MCQ Policies
ALTER TABLE public.election_mcqs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mcqs_view_public" ON public.election_mcqs;
CREATE POLICY "mcqs_view_public"
  ON public.election_mcqs FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "mcqs_manage_creator" ON public.election_mcqs;
CREATE POLICY "mcqs_manage_creator"
  ON public.election_mcqs FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.elections
    WHERE elections.id = election_mcqs.election_id
    AND elections.created_by = auth.uid()
  ));

-- Voter MCQ Responses Policies
ALTER TABLE public.voter_mcq_responses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mcq_responses_view_own" ON public.voter_mcq_responses;
CREATE POLICY "mcq_responses_view_own"
  ON public.voter_mcq_responses FOR SELECT
  USING (voter_id = auth.uid());

DROP POLICY IF EXISTS "mcq_responses_insert_own" ON public.voter_mcq_responses;
CREATE POLICY "mcq_responses_insert_own"
  ON public.voter_mcq_responses FOR INSERT
  WITH CHECK (voter_id = auth.uid());

-- Video Watch Progress Policies
ALTER TABLE public.voter_video_watch_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "video_progress_view_own" ON public.voter_video_watch_progress;
CREATE POLICY "video_progress_view_own"
  ON public.voter_video_watch_progress FOR SELECT
  USING (voter_id = auth.uid());

DROP POLICY IF EXISTS "video_progress_manage_own" ON public.voter_video_watch_progress;
CREATE POLICY "video_progress_manage_own"
  ON public.voter_video_watch_progress FOR ALL
  USING (voter_id = auth.uid());

-- Lottery Winner Notifications Policies
ALTER TABLE public.lottery_winner_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "winner_notifications_view_own" ON public.lottery_winner_notifications;
CREATE POLICY "winner_notifications_view_own"
  ON public.lottery_winner_notifications FOR SELECT
  USING (winner_id = auth.uid());

DROP POLICY IF EXISTS "winner_notifications_manage_admin" ON public.lottery_winner_notifications;
CREATE POLICY "winner_notifications_manage_admin"
  ON public.lottery_winner_notifications FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role = 'admin'
  ));

-- Election Prizes Policies (only if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'election_prizes') THEN
    ALTER TABLE public.election_prizes ENABLE ROW LEVEL SECURITY;
    
    DROP POLICY IF EXISTS "election_prizes_view_all" ON public.election_prizes;
    EXECUTE 'CREATE POLICY "election_prizes_view_all" ON public.election_prizes FOR SELECT USING (true)';
    
    DROP POLICY IF EXISTS "election_prizes_manage_creator" ON public.election_prizes;
    EXECUTE 'CREATE POLICY "election_prizes_manage_creator" ON public.election_prizes FOR ALL USING (EXISTS (SELECT 1 FROM public.elections WHERE elections.id = election_prizes.election_id AND elections.created_by = auth.uid()))';
  END IF;
END $$;

-- Prize Distributions Policies (only if winner_id column exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'prize_distributions' 
    AND column_name = 'winner_id'
  ) THEN
    ALTER TABLE public.prize_distributions ENABLE ROW LEVEL SECURITY;
    
    DROP POLICY IF EXISTS "prize_distributions_view_own" ON public.prize_distributions;
    EXECUTE 'CREATE POLICY "prize_distributions_view_own" ON public.prize_distributions FOR SELECT USING (winner_id = auth.uid())';
    
    DROP POLICY IF EXISTS "prize_distributions_manage_admin" ON public.prize_distributions;
    EXECUTE 'CREATE POLICY "prize_distributions_manage_admin" ON public.prize_distributions FOR ALL USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE user_profiles.id = auth.uid() AND user_profiles.role = ''admin''))';
  END IF;
END $$;

-- Creator Blacklist Policies
ALTER TABLE public.creator_blacklist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "creator_blacklist_manage_admin" ON public.creator_blacklist;
CREATE POLICY "creator_blacklist_manage_admin"
  ON public.creator_blacklist FOR ALL
  USING (EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE user_profiles.id = auth.uid()
    AND user_profiles.role = 'admin'
  ));

-- Election Comments Policies
ALTER TABLE public.election_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "comments_view_all" ON public.election_comments;
CREATE POLICY "comments_view_all"
  ON public.election_comments FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "comments_insert_own" ON public.election_comments;
CREATE POLICY "comments_insert_own"
  ON public.election_comments FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "comments_update_own" ON public.election_comments;
CREATE POLICY "comments_update_own"
  ON public.election_comments FOR UPDATE
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "comments_delete_own" ON public.election_comments;
CREATE POLICY "comments_delete_own"
  ON public.election_comments FOR DELETE
  USING (user_id = auth.uid());

-- Election Reactions Policies
ALTER TABLE public.election_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "reactions_view_all" ON public.election_reactions;
CREATE POLICY "reactions_view_all"
  ON public.election_reactions FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "reactions_manage_own" ON public.election_reactions;
CREATE POLICY "reactions_manage_own"
  ON public.election_reactions FOR ALL
  USING (user_id = auth.uid());

-- Election Shares Policies
ALTER TABLE public.election_shares ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "shares_view_all" ON public.election_shares;
CREATE POLICY "shares_view_all"
  ON public.election_shares FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "shares_insert_own" ON public.election_shares;
CREATE POLICY "shares_insert_own"
  ON public.election_shares FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 13. INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_election_mcqs_election ON public.election_mcqs(election_id);
CREATE INDEX IF NOT EXISTS idx_voter_mcq_responses_voter ON public.voter_mcq_responses(voter_id);
CREATE INDEX IF NOT EXISTS idx_voter_mcq_responses_election ON public.voter_mcq_responses(election_id);
CREATE INDEX IF NOT EXISTS idx_voter_video_watch_election ON public.voter_video_watch_progress(election_id);
CREATE INDEX IF NOT EXISTS idx_voter_video_watch_voter ON public.voter_video_watch_progress(voter_id);
CREATE INDEX IF NOT EXISTS idx_lottery_winner_notifications_winner ON public.lottery_winner_notifications(winner_id);
CREATE INDEX IF NOT EXISTS idx_lottery_winner_notifications_election ON public.lottery_winner_notifications(election_id);

-- Only create indexes if prize_distributions table has winner_id column
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'prize_distributions' 
    AND column_name = 'winner_id'
  ) THEN
    CREATE INDEX IF NOT EXISTS idx_prize_distributions_winner ON public.prize_distributions(winner_id);
    CREATE INDEX IF NOT EXISTS idx_prize_distributions_election ON public.prize_distributions(election_id);
  END IF;
END $$;