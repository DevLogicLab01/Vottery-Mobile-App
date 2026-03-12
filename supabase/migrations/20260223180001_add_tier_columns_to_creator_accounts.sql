-- Add tier_level and lifetime_vp_earned columns to creator_accounts if they don't exist
DO $$
BEGIN
  -- Add tier_level column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'creator_accounts'
    AND column_name = 'tier_level'
  ) THEN
    ALTER TABLE public.creator_accounts
    ADD COLUMN tier_level public.creator_tier_new DEFAULT 'bronze'::public.creator_tier_new;
  END IF;

  -- Add lifetime_vp_earned column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'creator_accounts'
    AND column_name = 'lifetime_vp_earned'
  ) THEN
    ALTER TABLE public.creator_accounts
    ADD COLUMN lifetime_vp_earned INTEGER DEFAULT 0;
  END IF;
END $$;

-- Create index for tier queries
CREATE INDEX IF NOT EXISTS idx_creator_accounts_tier ON public.creator_accounts(tier_level);