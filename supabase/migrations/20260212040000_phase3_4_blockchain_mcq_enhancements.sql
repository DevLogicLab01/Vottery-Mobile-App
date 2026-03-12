-- Phase 3: Blockchain Vote Verification & MCQ System Migration
-- Timestamp: 20260212040000
-- Description: End-to-end encryption, blockchain audit logs, MCQ system, video watch time

-- ============================================================
-- 1. VOTE ENCRYPTION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.vote_encryption_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  public_key TEXT NOT NULL,
  key_algorithm TEXT DEFAULT 'RSA-2048',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_vote_encryption_keys_user ON public.vote_encryption_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_vote_encryption_keys_active ON public.vote_encryption_keys(is_active);

-- Add encryption fields to votes table
ALTER TABLE public.votes ADD COLUMN IF NOT EXISTS encrypted_vote_data TEXT;
ALTER TABLE public.votes ADD COLUMN IF NOT EXISTS digital_signature TEXT;
ALTER TABLE public.votes ADD COLUMN IF NOT EXISTS encryption_key_id UUID REFERENCES public.vote_encryption_keys(id);

-- ============================================================
-- 2. BLOCKCHAIN AUDIT TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.blockchain_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vote_id UUID REFERENCES public.votes(id) ON DELETE CASCADE,
  block_hash TEXT NOT NULL,
  previous_block_hash TEXT,
  transaction_hash TEXT NOT NULL,
  block_number BIGINT,
  consensus_validation TEXT,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  verification_status TEXT DEFAULT 'verified',
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_blockchain_audit_vote ON public.blockchain_audit_log(vote_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_audit_block ON public.blockchain_audit_log(block_number DESC);
CREATE INDEX IF NOT EXISTS idx_blockchain_audit_timestamp ON public.blockchain_audit_log(timestamp DESC);

-- ============================================================
-- 3. MCQ SYSTEM TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_mcq_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_order INTEGER DEFAULT 0,
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_election_mcq_election ON public.election_mcq_questions(election_id);

CREATE TABLE IF NOT EXISTS public.mcq_answer_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.election_mcq_questions(id) ON DELETE CASCADE,
  option_text TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT false,
  option_order INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_mcq_answer_options_question ON public.mcq_answer_options(question_id);

CREATE TABLE IF NOT EXISTS public.user_mcq_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.election_mcq_questions(id) ON DELETE CASCADE,
  selected_option_id UUID REFERENCES public.mcq_answer_options(id) ON DELETE CASCADE,
  is_correct BOOLEAN,
  answered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, election_id, question_id)
);

CREATE INDEX IF NOT EXISTS idx_user_mcq_responses_user ON public.user_mcq_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_user_mcq_responses_election ON public.user_mcq_responses(election_id);

-- ============================================================
-- 4. VIDEO WATCH TIME TRACKING
-- ============================================================

CREATE TABLE IF NOT EXISTS public.video_watch_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  video_url TEXT NOT NULL,
  watch_duration_seconds INTEGER DEFAULT 0,
  total_video_duration_seconds INTEGER,
  watch_percentage NUMERIC(5,2) DEFAULT 0.00,
  requirement_met BOOLEAN DEFAULT false,
  started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMPTZ,
  UNIQUE(user_id, election_id)
);

CREATE INDEX IF NOT EXISTS idx_video_watch_tracking_user ON public.video_watch_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_video_watch_tracking_election ON public.video_watch_tracking(election_id);

-- Add video requirements to elections table
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS video_url TEXT;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS min_watch_time_seconds INTEGER DEFAULT 0;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS require_full_watch BOOLEAN DEFAULT false;

-- ============================================================
-- 5. PHASE 4: BIOMETRIC & PERMISSIONS
-- ============================================================

-- Add biometric and permission fields to elections table
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS require_biometric BOOLEAN DEFAULT false;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS permission_type TEXT DEFAULT 'public';
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS allowed_countries TEXT[];
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS allowed_groups UUID[];

-- ============================================================
-- 6. PHASE 4: RICH MEDIA MESSAGING
-- ============================================================

-- Add rich media fields to messages table
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS emoji_reactions JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_message_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_duration_seconds INTEGER;

CREATE TABLE IF NOT EXISTS public.message_media_gallery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL,
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  file_size_bytes BIGINT,
  duration_seconds INTEGER,
  width INTEGER,
  height INTEGER,
  uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_message_media_gallery_message ON public.message_media_gallery(message_id);

-- ============================================================
-- 7. RLS POLICIES
-- ============================================================

ALTER TABLE public.vote_encryption_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blockchain_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_mcq_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mcq_answer_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_mcq_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_watch_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_media_gallery ENABLE ROW LEVEL SECURITY;

-- Vote encryption keys policies
CREATE POLICY "Users can manage own encryption keys"
  ON public.vote_encryption_keys FOR ALL
  USING (auth.uid() = user_id);

-- Blockchain audit log policies
CREATE POLICY "Users can view blockchain audit logs"
  ON public.blockchain_audit_log FOR SELECT
  USING (true);

-- MCQ policies
CREATE POLICY "Users can view MCQ questions"
  ON public.election_mcq_questions FOR SELECT
  USING (true);

CREATE POLICY "Users can view MCQ options"
  ON public.mcq_answer_options FOR SELECT
  USING (true);

CREATE POLICY "Users can manage own MCQ responses"
  ON public.user_mcq_responses FOR ALL
  USING (auth.uid() = user_id);

-- Video watch tracking policies
CREATE POLICY "Users can manage own watch tracking"
  ON public.video_watch_tracking FOR ALL
  USING (auth.uid() = user_id);

-- Message media gallery policies
CREATE POLICY "Users can view media in their conversations"
  ON public.message_media_gallery FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.messages m
      JOIN public.conversations c ON m.conversation_id = c.id
      WHERE m.id = message_id
        AND auth.uid() = ANY(c.participant_ids)
    )
  );

CREATE POLICY "Users can upload media to their messages"
  ON public.message_media_gallery FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.messages m
      JOIN public.conversations c ON m.conversation_id = c.id
      WHERE m.id = message_id
        AND auth.uid() = m.sender_id
    )
  );
