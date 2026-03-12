-- Phase 1 Batch 2: Gamification & Trust System Migration
-- Timestamp: 20260215010000
-- Description: MCQ system, video watch time, voter IDs, lottery automation, verify/audit, permissions, social features

-- ============================================================
-- 1. VOTER ID SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.voter_ids (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  voter_id_number TEXT NOT NULL UNIQUE,
  sequential_number INTEGER NOT NULL,
  generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_voter_ids_election ON public.voter_ids(election_id);
CREATE INDEX IF NOT EXISTS idx_voter_ids_user ON public.voter_ids(user_id);
CREATE INDEX IF NOT EXISTS idx_voter_ids_number ON public.voter_ids(voter_id_number);

-- Function to generate voter ID
CREATE OR REPLACE FUNCTION public.generate_voter_id(
  p_election_id UUID,
  p_user_id UUID
)
RETURNS TEXT AS $$
DECLARE
  v_sequential_number INTEGER;
  v_voter_id_number TEXT;
BEGIN
  -- Get next sequential number for this election
  SELECT COALESCE(MAX(sequential_number), 0) + 1
  INTO v_sequential_number
  FROM public.voter_ids
  WHERE election_id = p_election_id;

  -- Generate voter ID in format: VTR-{election_id_short}-{sequential_number}
  v_voter_id_number := 'VTR-' || SUBSTRING(p_election_id::TEXT, 1, 8) || '-' || LPAD(v_sequential_number::TEXT, 6, '0');

  -- Insert voter ID
  INSERT INTO public.voter_ids (election_id, user_id, voter_id_number, sequential_number)
  VALUES (p_election_id, p_user_id, v_voter_id_number, v_sequential_number)
  ON CONFLICT (election_id, user_id) DO NOTHING;

  RETURN v_voter_id_number;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 2. LOTTERY AUTOMATION ENHANCEMENTS
-- ============================================================

-- Add winner notification tracking
ALTER TABLE public.lottery_winners ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN DEFAULT false;
ALTER TABLE public.lottery_winners ADD COLUMN IF NOT EXISTS notification_sent_at TIMESTAMPTZ;
ALTER TABLE public.lottery_winners ADD COLUMN IF NOT EXISTS message_id UUID REFERENCES public.messages(id);

-- Add sequential announcement tracking
ALTER TABLE public.lottery_winners ADD COLUMN IF NOT EXISTS announcement_order INTEGER;
ALTER TABLE public.lottery_winners ADD COLUMN IF NOT EXISTS announced_at TIMESTAMPTZ;

-- Add slot machine state tracking
CREATE TABLE IF NOT EXISTS public.slot_machine_state (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE UNIQUE,
  is_spinning BOOLEAN DEFAULT false,
  started_spinning_at TIMESTAMPTZ,
  total_participants INTEGER DEFAULT 0,
  winner_count INTEGER DEFAULT 1,
  current_winner_index INTEGER DEFAULT 0,
  last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_slot_machine_state_election ON public.slot_machine_state(election_id);

-- ============================================================
-- 3. CREATOR BLACKLIST SYSTEM
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
-- 4. ELECTION SOCIAL FEATURES
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
CREATE INDEX IF NOT EXISTS idx_election_comments_parent ON public.election_comments(parent_comment_id);

CREATE TABLE IF NOT EXISTS public.election_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reaction_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, user_id, reaction_type)
);

CREATE INDEX IF NOT EXISTS idx_election_reactions_election ON public.election_reactions(election_id);
CREATE INDEX IF NOT EXISTS idx_election_reactions_user ON public.election_reactions(user_id);

CREATE TABLE IF NOT EXISTS public.election_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  share_platform TEXT NOT NULL,
  shared_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_election_shares_election ON public.election_shares(election_id);
CREATE INDEX IF NOT EXISTS idx_election_shares_user ON public.election_shares(user_id);

-- Add comment toggle to elections
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS comments_enabled BOOLEAN DEFAULT true;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS reactions_enabled BOOLEAN DEFAULT true;

-- ============================================================
-- 5. VOTE TOTALS VISIBILITY CONTROLS
-- ============================================================

ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS show_live_results BOOLEAN DEFAULT false;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS results_visibility_changed_at TIMESTAMPTZ;

-- ============================================================
-- 6. ELECTION EDIT/DELETE RULES
-- ============================================================

ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS first_vote_at TIMESTAMPTZ;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS can_edit BOOLEAN DEFAULT true;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS can_delete BOOLEAN DEFAULT true;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS max_deadline_extension_months INTEGER DEFAULT 6;

-- Function to check if election can be edited
CREATE OR REPLACE FUNCTION public.can_edit_election(
  p_election_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_first_vote_at TIMESTAMPTZ;
BEGIN
  SELECT first_vote_at INTO v_first_vote_at
  FROM public.elections
  WHERE id = p_election_id;

  -- Can edit if no votes have been cast
  RETURN v_first_vote_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 7. VERIFICATION & AUDIT ENHANCEMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.verification_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_ids UUID[] NOT NULL,
  verification_status TEXT DEFAULT 'pending',
  verification_results JSONB DEFAULT '{}'::jsonb,
  requested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_verification_requests_user ON public.verification_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_verification_requests_status ON public.verification_requests(verification_status);

CREATE TABLE IF NOT EXISTS public.audit_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  generated_by UUID REFERENCES public.user_profiles(id),
  report_type TEXT NOT NULL,
  report_data JSONB NOT NULL,
  pdf_url TEXT,
  generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_reports_election ON public.audit_reports(election_id);
CREATE INDEX IF NOT EXISTS idx_audit_reports_generated ON public.audit_reports(generated_at DESC);

-- ============================================================
-- 8. PRIZE DISTRIBUTION ENHANCEMENTS
-- ============================================================

-- Add prize type options
DO $$ BEGIN
  CREATE TYPE public.prize_type AS ENUM (
    'monetary',
    'non_monetary',
    'projected_revenue'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE public.election_prizes ADD COLUMN IF NOT EXISTS prize_type public.prize_type DEFAULT 'monetary';
ALTER TABLE public.election_prizes ADD COLUMN IF NOT EXISTS prize_description TEXT;
ALTER TABLE public.election_prizes ADD COLUMN IF NOT EXISTS coupon_code TEXT;
ALTER TABLE public.election_prizes ADD COLUMN IF NOT EXISTS voucher_details JSONB;

-- ============================================================
-- 9. SUGGESTED ELECTIONS SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  suggestion_score NUMERIC(5,2) DEFAULT 0.00,
  suggestion_reason TEXT,
  shown_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  clicked BOOLEAN DEFAULT false,
  UNIQUE(user_id, election_id)
);

CREATE INDEX IF NOT EXISTS idx_election_suggestions_user ON public.election_suggestions(user_id);
CREATE INDEX IF NOT EXISTS idx_election_suggestions_score ON public.election_suggestions(suggestion_score DESC);

-- ============================================================
-- 10. RLS POLICIES
-- ============================================================

ALTER TABLE public.voter_ids ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slot_machine_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_blacklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_suggestions ENABLE ROW LEVEL SECURITY;

-- Voter IDs policies
CREATE POLICY "Users can view own voter IDs"
  ON public.voter_ids FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view voter IDs for elections they participated in"
  ON public.voter_ids FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.votes
      WHERE votes.election_id = voter_ids.election_id
        AND votes.user_id = auth.uid()
    )
  );

-- Slot machine state policies
CREATE POLICY "Anyone can view slot machine state"
  ON public.slot_machine_state FOR SELECT
  USING (true);

-- Creator blacklist policies
CREATE POLICY "Anyone can view active blacklist"
  ON public.creator_blacklist FOR SELECT
  USING (is_active = true);

-- Election comments policies
CREATE POLICY "Users can view comments on elections"
  ON public.election_comments FOR SELECT
  USING (true);

CREATE POLICY "Users can create comments"
  ON public.election_comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments"
  ON public.election_comments FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
  ON public.election_comments FOR DELETE
  USING (auth.uid() = user_id);

-- Election reactions policies
CREATE POLICY "Users can view reactions"
  ON public.election_reactions FOR SELECT
  USING (true);

CREATE POLICY "Users can manage own reactions"
  ON public.election_reactions FOR ALL
  USING (auth.uid() = user_id);

-- Election shares policies
CREATE POLICY "Users can view shares"
  ON public.election_shares FOR SELECT
  USING (true);

CREATE POLICY "Users can create shares"
  ON public.election_shares FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Verification requests policies
CREATE POLICY "Users can manage own verification requests"
  ON public.verification_requests FOR ALL
  USING (auth.uid() = user_id);

-- Audit reports policies
CREATE POLICY "Anyone can view audit reports"
  ON public.audit_reports FOR SELECT
  USING (true);

-- Election suggestions policies
CREATE POLICY "Users can view own suggestions"
  ON public.election_suggestions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own suggestions"
  ON public.election_suggestions FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- 11. TRIGGERS
-- ============================================================

-- Trigger to set first_vote_at and lock editing
CREATE OR REPLACE FUNCTION public.set_first_vote_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.elections
  SET first_vote_at = CURRENT_TIMESTAMP,
      can_edit = false,
      can_delete = false
  WHERE id = NEW.election_id
    AND first_vote_at IS NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_first_vote ON public.votes;
CREATE TRIGGER trigger_set_first_vote
  AFTER INSERT ON public.votes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_first_vote_timestamp();

-- Trigger to start slot machine spinning on 2nd vote
CREATE OR REPLACE FUNCTION public.start_slot_machine_spinning()
RETURNS TRIGGER AS $$
DECLARE
  v_vote_count INTEGER;
BEGIN
  -- Count votes for this election
  SELECT COUNT(*) INTO v_vote_count
  FROM public.votes
  WHERE election_id = NEW.election_id;

  -- Start spinning if this is the 2nd vote
  IF v_vote_count = 2 THEN
    INSERT INTO public.slot_machine_state (election_id, is_spinning, started_spinning_at, total_participants)
    VALUES (NEW.election_id, true, CURRENT_TIMESTAMP, 2)
    ON CONFLICT (election_id) DO UPDATE
    SET is_spinning = true,
        started_spinning_at = CURRENT_TIMESTAMP,
        total_participants = 2;
  ELSIF v_vote_count > 2 THEN
    UPDATE public.slot_machine_state
    SET total_participants = v_vote_count,
        last_updated = CURRENT_TIMESTAMP
    WHERE election_id = NEW.election_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_start_slot_machine ON public.votes;
CREATE TRIGGER trigger_start_slot_machine
  AFTER INSERT ON public.votes
  FOR EACH ROW
  EXECUTE FUNCTION public.start_slot_machine_spinning();