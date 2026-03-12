-- Brand Onboarding Enhancements Migration
-- Adds comprehensive brand onboarding workflow tracking and account management fields

-- =====================================================
-- 1. ENHANCE BRAND_ACCOUNTS TABLE
-- =====================================================

-- Add new columns for brand onboarding
DO $$
BEGIN
  -- Add billing_settings column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_accounts' 
    AND column_name = 'billing_settings'
  ) THEN
    ALTER TABLE public.brand_accounts 
    ADD COLUMN billing_settings JSONB DEFAULT '{}'::jsonb;
  END IF;

  -- Add campaign_preferences column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_accounts' 
    AND column_name = 'campaign_preferences'
  ) THEN
    ALTER TABLE public.brand_accounts 
    ADD COLUMN campaign_preferences JSONB DEFAULT '{}'::jsonb;
  END IF;

  -- Add industry_targeting column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_accounts' 
    AND column_name = 'industry_targeting'
  ) THEN
    ALTER TABLE public.brand_accounts 
    ADD COLUMN industry_targeting JSONB DEFAULT '{}'::jsonb;
  END IF;

  -- Add stripe_subscription_id column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_accounts' 
    AND column_name = 'stripe_subscription_id'
  ) THEN
    ALTER TABLE public.brand_accounts 
    ADD COLUMN stripe_subscription_id TEXT;
  END IF;

  -- Add company_registration_number column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_accounts' 
    AND column_name = 'company_registration_number'
  ) THEN
    ALTER TABLE public.brand_accounts 
    ADD COLUMN company_registration_number TEXT;
  END IF;

  -- Add tax_identification column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_accounts' 
    AND column_name = 'tax_identification'
  ) THEN
    ALTER TABLE public.brand_accounts 
    ADD COLUMN tax_identification TEXT;
  END IF;

  -- Add verification_status column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_accounts' 
    AND column_name = 'verification_status'
  ) THEN
    ALTER TABLE public.brand_accounts 
    ADD COLUMN verification_status TEXT DEFAULT 'pending';
  END IF;

  -- Add user_id column for account ownership
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_accounts' 
    AND column_name = 'user_id'
  ) THEN
    ALTER TABLE public.brand_accounts 
    ADD COLUMN user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_brand_accounts_user_id ON public.brand_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_brand_accounts_stripe_subscription ON public.brand_accounts(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_brand_accounts_verification_status ON public.brand_accounts(verification_status);

COMMENT ON COLUMN public.brand_accounts.billing_settings IS 'Stripe billing configuration and payment method details';
COMMENT ON COLUMN public.brand_accounts.campaign_preferences IS 'Default targeting parameters and budget allocation templates';
COMMENT ON COLUMN public.brand_accounts.industry_targeting IS 'Sector-specific audience segments and performance benchmarks';

-- =====================================================
-- 2. BRAND ONBOARDING TRACKING TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.brand_onboarding (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  brand_account_id UUID REFERENCES public.brand_accounts(id) ON DELETE CASCADE,
  current_step INTEGER DEFAULT 1 CHECK (current_step >= 1 AND current_step <= 5),
  company_info JSONB DEFAULT '{}'::jsonb,
  verification_documents JSONB DEFAULT '{}'::jsonb,
  payment_setup JSONB DEFAULT '{}'::jsonb,
  targeting_config JSONB DEFAULT '{}'::jsonb,
  budget_allocation JSONB DEFAULT '{}'::jsonb,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_brand_onboarding_user_id ON public.brand_onboarding(user_id);
CREATE INDEX IF NOT EXISTS idx_brand_onboarding_brand_account ON public.brand_onboarding(brand_account_id);
CREATE INDEX IF NOT EXISTS idx_brand_onboarding_completed ON public.brand_onboarding(is_completed);

COMMENT ON TABLE public.brand_onboarding IS 'Tracks brand onboarding wizard progress with save-and-resume functionality';

-- =====================================================
-- 3. SPONSORED ELECTION CAMPAIGN OBJECTIVES
-- =====================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'campaign_objective') THEN
    CREATE TYPE public.campaign_objective AS ENUM (
      'market_research',
      'brand_awareness',
      'product_launch'
    );
  END IF;
END$$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'bidding_strategy') THEN
    CREATE TYPE public.bidding_strategy AS ENUM (
      'cost_per_vote',
      'cost_per_impression',
      'cost_per_engagement'
    );
  END IF;
END$$;

-- Add new columns to sponsored_elections
DO $$
BEGIN
  -- Add campaign_objective column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'campaign_objective'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN campaign_objective public.campaign_objective DEFAULT 'brand_awareness';
  END IF;

  -- Add target_demographics column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'target_demographics'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN target_demographics JSONB DEFAULT '{}'::jsonb;
  END IF;

  -- Add bidding_strategy column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'bidding_strategy'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN bidding_strategy public.bidding_strategy DEFAULT 'cost_per_vote';
  END IF;

  -- Add daily_budget_cap column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'daily_budget_cap'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN daily_budget_cap NUMERIC(10,2) DEFAULT 0.00;
  END IF;

  -- Add audience_size_estimate column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'audience_size_estimate'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN audience_size_estimate INTEGER DEFAULT 0;
  END IF;

  -- Add content_moderation_status column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'content_moderation_status'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN content_moderation_status TEXT DEFAULT 'pending';
  END IF;

  -- Add moderation_notes column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'moderation_notes'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN moderation_notes TEXT;
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_sponsored_elections_campaign_objective ON public.sponsored_elections(campaign_objective);
CREATE INDEX IF NOT EXISTS idx_sponsored_elections_bidding_strategy ON public.sponsored_elections(bidding_strategy);
CREATE INDEX IF NOT EXISTS idx_sponsored_elections_moderation_status ON public.sponsored_elections(content_moderation_status);

-- =====================================================
-- 4. RLS POLICIES
-- =====================================================

ALTER TABLE public.brand_onboarding ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_brand_onboarding" ON public.brand_onboarding;
CREATE POLICY "users_manage_own_brand_onboarding"
  ON public.brand_onboarding
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_brand_accounts" ON public.brand_accounts;
CREATE POLICY "users_manage_own_brand_accounts"
  ON public.brand_accounts
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- =====================================================
-- 5. FUNCTIONS
-- =====================================================

-- Function to update brand onboarding timestamp
CREATE OR REPLACE FUNCTION public.update_brand_onboarding_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_brand_onboarding_timestamp_trigger ON public.brand_onboarding;
CREATE TRIGGER update_brand_onboarding_timestamp_trigger
  BEFORE UPDATE ON public.brand_onboarding
  FOR EACH ROW
  EXECUTE FUNCTION public.update_brand_onboarding_timestamp();