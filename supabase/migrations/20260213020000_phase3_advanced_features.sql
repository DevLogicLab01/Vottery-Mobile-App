-- Phase 3: Advanced Features Migration
-- Timestamp: 20260213020000
-- Description: End-to-end encryption, blockchain audit logs, MCQ system, video watch time requirements

-- ============================================================
-- 1. TYPES
-- ============================================================

DO $$ BEGIN
  CREATE TYPE public.encryption_algorithm AS ENUM (
    'rsa_2048',
    'rsa_4096',
    'aes_256'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.mcq_difficulty AS ENUM (
    'easy',
    'medium',
    'hard'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 2. ENCRYPTION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.vote_encryption_keys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  public_key TEXT NOT NULL,
  encrypted_private_key TEXT NOT NULL,
  algorithm public.encryption_algorithm DEFAULT 'rsa_2048',
  key_fingerprint TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, key_fingerprint)
);

CREATE TABLE IF NOT EXISTS public.encrypted_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vote_id UUID NOT NULL REFERENCES public.votes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  encrypted_payload TEXT NOT NULL,
  digital_signature TEXT NOT NULL,
  encryption_key_id UUID NOT NULL REFERENCES public.vote_encryption_keys(id) ON DELETE CASCADE,
  verification_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. BLOCKCHAIN AUDIT LOG TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.blockchain_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  block_number BIGSERIAL,
  previous_block_hash TEXT NOT NULL,
  current_block_hash TEXT NOT NULL,
  transaction_type TEXT NOT NULL,
  transaction_data JSONB NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  merkle_root TEXT NOT NULL,
  nonce TEXT NOT NULL,
  difficulty INTEGER DEFAULT 1,
  miner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  is_verified BOOLEAN DEFAULT false,
  verification_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.vote_verification_chain (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vote_id UUID NOT NULL REFERENCES public.votes(id) ON DELETE CASCADE,
  blockchain_log_id UUID NOT NULL REFERENCES public.blockchain_audit_logs(id) ON DELETE CASCADE,
  verification_hash TEXT NOT NULL,
  previous_verification_hash TEXT,
  chain_position INTEGER NOT NULL,
  is_valid BOOLEAN DEFAULT true,
  verified_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(vote_id)
);

-- ============================================================
-- 4. MCQ SYSTEM TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.mcq_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  wrong_answers TEXT[] NOT NULL,
  difficulty public.mcq_difficulty DEFAULT 'medium',
  display_order INTEGER DEFAULT 0,
  time_limit_seconds INTEGER DEFAULT 30,
  points_value INTEGER DEFAULT 10,
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.mcq_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.mcq_questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  selected_answer TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  time_taken_seconds INTEGER NOT NULL,
  points_earned INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(question_id, user_id)
);

-- ============================================================
-- 5. VIDEO WATCH TIME TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.video_watch_requirements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  video_url TEXT NOT NULL,
  video_duration_seconds INTEGER NOT NULL,
  minimum_watch_time_seconds INTEGER NOT NULL,
  minimum_watch_percentage NUMERIC(5,2) NOT NULL DEFAULT 80.00,
  is_required BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id)
);

CREATE TABLE IF NOT EXISTS public.user_video_watch_time (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requirement_id UUID NOT NULL REFERENCES public.video_watch_requirements(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  total_watch_time_seconds INTEGER DEFAULT 0,
  watch_percentage NUMERIC(5,2) DEFAULT 0.00,
  has_met_requirement BOOLEAN DEFAULT false,
  watch_sessions JSONB DEFAULT '[]'::jsonb,
  last_watched_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(requirement_id, user_id)
);

-- ============================================================
-- 6. EXTEND ELECTIONS TABLE
-- ============================================================

ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS encryption_enabled BOOLEAN DEFAULT false;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS blockchain_verification_enabled BOOLEAN DEFAULT true;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS mcq_required BOOLEAN DEFAULT false;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS video_watch_required BOOLEAN DEFAULT false;

-- ============================================================
-- 7. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_vote_encryption_keys_user_id ON public.vote_encryption_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_vote_encryption_keys_active ON public.vote_encryption_keys(is_active);
CREATE INDEX IF NOT EXISTS idx_encrypted_votes_vote_id ON public.encrypted_votes(vote_id);
CREATE INDEX IF NOT EXISTS idx_encrypted_votes_user_id ON public.encrypted_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_audit_logs_block_number ON public.blockchain_audit_logs(block_number);
CREATE INDEX IF NOT EXISTS idx_blockchain_audit_logs_transaction_type ON public.blockchain_audit_logs(transaction_type);
CREATE INDEX IF NOT EXISTS idx_vote_verification_chain_vote_id ON public.vote_verification_chain(vote_id);
CREATE INDEX IF NOT EXISTS idx_mcq_questions_election_id ON public.mcq_questions(election_id);
CREATE INDEX IF NOT EXISTS idx_mcq_responses_user_id ON public.mcq_responses(user_id);
CREATE INDEX IF NOT EXISTS idx_mcq_responses_election_id ON public.mcq_responses(election_id);
CREATE INDEX IF NOT EXISTS idx_video_watch_requirements_election_id ON public.video_watch_requirements(election_id);
CREATE INDEX IF NOT EXISTS idx_user_video_watch_time_user_id ON public.user_video_watch_time(user_id);
CREATE INDEX IF NOT EXISTS idx_user_video_watch_time_requirement_met ON public.user_video_watch_time(has_met_requirement);

-- ============================================================
-- 8. FUNCTIONS
-- ============================================================

-- Create blockchain audit log entry
CREATE OR REPLACE FUNCTION public.create_blockchain_audit_log(
  p_transaction_type TEXT,
  p_transaction_data JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_previous_hash TEXT;
  v_current_hash TEXT;
  v_merkle_root TEXT;
  v_nonce TEXT;
  v_log_id UUID;
BEGIN
  -- Get previous block hash
  SELECT current_block_hash INTO v_previous_hash
  FROM public.blockchain_audit_logs
  ORDER BY block_number DESC
  LIMIT 1;

  IF v_previous_hash IS NULL THEN
    v_previous_hash := '0000000000000000000000000000000000000000000000000000000000000000';
  END IF;

  -- Generate nonce
  v_nonce := encode(gen_random_bytes(16), 'hex');

  -- Generate merkle root (simplified)
  v_merkle_root := encode(digest(p_transaction_data::text, 'sha256'), 'hex');

  -- Generate current block hash
  v_current_hash := encode(
    digest(
      v_previous_hash || p_transaction_type || p_transaction_data::text || v_nonce,
      'sha256'
    ),
    'hex'
  );

  -- Insert audit log
  INSERT INTO public.blockchain_audit_logs (
    previous_block_hash,
    current_block_hash,
    transaction_type,
    transaction_data,
    merkle_root,
    nonce
  ) VALUES (
    v_previous_hash,
    v_current_hash,
    p_transaction_type,
    p_transaction_data,
    v_merkle_root,
    v_nonce
  ) RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$;

-- Verify MCQ responses
CREATE OR REPLACE FUNCTION public.verify_mcq_completion(
  p_user_id UUID,
  p_election_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_required_count INTEGER;
  v_completed_count INTEGER;
BEGIN
  -- Count required questions
  SELECT COUNT(*) INTO v_required_count
  FROM public.mcq_questions
  WHERE election_id = p_election_id AND is_required = true;

  -- Count completed responses
  SELECT COUNT(*) INTO v_completed_count
  FROM public.mcq_responses
  WHERE user_id = p_user_id AND election_id = p_election_id;

  RETURN v_completed_count >= v_required_count;
END;
$$;

-- Verify video watch requirement
CREATE OR REPLACE FUNCTION public.verify_video_watch_requirement(
  p_user_id UUID,
  p_election_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_has_met_requirement BOOLEAN;
BEGIN
  SELECT has_met_requirement INTO v_has_met_requirement
  FROM public.user_video_watch_time uvwt
  JOIN public.video_watch_requirements vwr ON uvwt.requirement_id = vwr.id
  WHERE uvwt.user_id = p_user_id AND vwr.election_id = p_election_id;

  RETURN COALESCE(v_has_met_requirement, false);
END;
$$;

-- ============================================================
-- 9. ENABLE RLS
-- ============================================================

ALTER TABLE public.vote_encryption_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.encrypted_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blockchain_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vote_verification_chain ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mcq_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mcq_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.video_watch_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_video_watch_time ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 10. RLS POLICIES
-- ============================================================

-- Vote encryption keys policies
DROP POLICY IF EXISTS "users_view_own_encryption_keys" ON public.vote_encryption_keys;
CREATE POLICY "users_view_own_encryption_keys"
ON public.vote_encryption_keys
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_manage_own_encryption_keys" ON public.vote_encryption_keys;
CREATE POLICY "users_manage_own_encryption_keys"
ON public.vote_encryption_keys
FOR ALL
USING (auth.uid() = user_id);

-- Encrypted votes policies
DROP POLICY IF EXISTS "users_view_own_encrypted_votes" ON public.encrypted_votes;
CREATE POLICY "users_view_own_encrypted_votes"
ON public.encrypted_votes
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_insert_encrypted_votes" ON public.encrypted_votes;
CREATE POLICY "users_insert_encrypted_votes"
ON public.encrypted_votes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Blockchain audit logs policies
DROP POLICY IF EXISTS "anyone_view_blockchain_logs" ON public.blockchain_audit_logs;
CREATE POLICY "anyone_view_blockchain_logs"
ON public.blockchain_audit_logs
FOR SELECT
USING (true);

-- Vote verification chain policies
DROP POLICY IF EXISTS "anyone_view_verification_chain" ON public.vote_verification_chain;
CREATE POLICY "anyone_view_verification_chain"
ON public.vote_verification_chain
FOR SELECT
USING (true);

-- MCQ questions policies
DROP POLICY IF EXISTS "anyone_view_mcq_questions" ON public.mcq_questions;
CREATE POLICY "anyone_view_mcq_questions"
ON public.mcq_questions
FOR SELECT
USING (true);

-- MCQ responses policies
DROP POLICY IF EXISTS "users_view_own_mcq_responses" ON public.mcq_responses;
CREATE POLICY "users_view_own_mcq_responses"
ON public.mcq_responses
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_insert_mcq_responses" ON public.mcq_responses;
CREATE POLICY "users_insert_mcq_responses"
ON public.mcq_responses
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Video watch requirements policies
DROP POLICY IF EXISTS "anyone_view_video_requirements" ON public.video_watch_requirements;
CREATE POLICY "anyone_view_video_requirements"
ON public.video_watch_requirements
FOR SELECT
USING (true);

-- User video watch time policies
DROP POLICY IF EXISTS "users_view_own_watch_time" ON public.user_video_watch_time;
CREATE POLICY "users_view_own_watch_time"
ON public.user_video_watch_time
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_manage_own_watch_time" ON public.user_video_watch_time;
CREATE POLICY "users_manage_own_watch_time"
ON public.user_video_watch_time
FOR ALL
USING (auth.uid() = user_id);

COMMENT ON TABLE public.vote_encryption_keys IS 'RSA encryption keys for end-to-end encrypted votes';
COMMENT ON TABLE public.blockchain_audit_logs IS 'Immutable blockchain audit trail for vote verification';
COMMENT ON TABLE public.mcq_questions IS 'Multiple choice questions before voting';
COMMENT ON TABLE public.video_watch_requirements IS 'Video watch time requirements before voting';