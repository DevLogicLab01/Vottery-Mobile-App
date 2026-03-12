-- Add 'canceled' and 'failed' to election_status enum (idempotent)

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'election_status' AND e.enumlabel = 'canceled'
  ) THEN
    ALTER TYPE public.election_status ADD VALUE 'canceled';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'election_status' AND e.enumlabel = 'failed'
  ) THEN
    ALTER TYPE public.election_status ADD VALUE 'failed';
  END IF;
END $$;

