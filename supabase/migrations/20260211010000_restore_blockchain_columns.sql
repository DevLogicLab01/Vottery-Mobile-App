-- Migration: Restore blockchain_hash and vote_hash columns
-- Created: 2026-02-11
-- Purpose: Restore blockchain verification columns for vote auditing and security

-- Add blockchain-related columns back to votes table
DO $$
BEGIN
  -- Add blockchain_hash column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'votes'
    AND column_name = 'blockchain_hash'
  ) THEN
    ALTER TABLE public.votes ADD COLUMN blockchain_hash TEXT;
  END IF;

  -- Add vote_hash column if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'votes'
    AND column_name = 'vote_hash'
  ) THEN
    ALTER TABLE public.votes ADD COLUMN vote_hash TEXT;
  END IF;
END $$;

-- Create indexes for blockchain columns for efficient querying
CREATE INDEX IF NOT EXISTS idx_votes_blockchain_hash ON public.votes(blockchain_hash);
CREATE INDEX IF NOT EXISTS idx_votes_vote_hash ON public.votes(vote_hash);

-- Add comment explaining the purpose
COMMENT ON COLUMN public.votes.blockchain_hash IS 'Mock blockchain hash for vote verification and audit trail';
COMMENT ON COLUMN public.votes.vote_hash IS 'Individual vote hash for tamper detection and verification';