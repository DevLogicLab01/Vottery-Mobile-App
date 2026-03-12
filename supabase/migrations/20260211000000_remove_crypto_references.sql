-- Migration: Remove crypto/blockchain references from Vottery
-- Created: 2026-02-11
-- Purpose: Remove blockchain_hash and vote_hash columns as they are not actual blockchain features

-- Remove blockchain-related columns from votes table
DO $$
BEGIN
  -- Drop blockchain_hash column if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'votes'
    AND column_name = 'blockchain_hash'
  ) THEN
    ALTER TABLE public.votes DROP COLUMN blockchain_hash;
  END IF;

  -- Drop vote_hash column if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'votes'
    AND column_name = 'vote_hash'
  ) THEN
    ALTER TABLE public.votes DROP COLUMN vote_hash;
  END IF;
END $$;