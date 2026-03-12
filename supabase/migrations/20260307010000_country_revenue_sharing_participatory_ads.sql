-- Phase C: Country-Based Revenue Sharing & Participatory Advertising
-- Migration: 20260307010000_country_revenue_sharing_participatory_ads.sql

-- =====================================================
-- 1. TYPES (with idempotency)
-- =====================================================

-- Note: sponsored_election_status already exists from previous migration
-- We'll add new values if needed
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ad_vote_status') THEN
    CREATE TYPE public.ad_vote_status AS ENUM (
      'pending',
      'charged',
      'refunded'
    );
  END IF;
END$$;

-- =====================================================
-- 2. CREATOR REVENUE SPLITS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.creator_revenue_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL UNIQUE CHECK (length(country_code) = 2),
  country_name TEXT NOT NULL,
  platform_percentage NUMERIC(5,2) NOT NULL CHECK (platform_percentage >= 0 AND platform_percentage <= 100),
  creator_percentage NUMERIC(5,2) NOT NULL CHECK (creator_percentage >= 0 AND creator_percentage <= 100),
  currency_code TEXT DEFAULT 'USD',
  is_active BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  CONSTRAINT valid_split_total CHECK (platform_percentage + creator_percentage = 100)
);

CREATE INDEX IF NOT EXISTS idx_revenue_splits_country_code ON public.creator_revenue_splits(country_code);
CREATE INDEX IF NOT EXISTS idx_revenue_splits_active ON public.creator_revenue_splits(is_active);

COMMENT ON TABLE public.creator_revenue_splits IS 'Country-specific revenue split configuration for creator monetization';

-- =====================================================
-- 3. REVENUE SPLIT HISTORY (AUDIT TRAIL)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.revenue_split_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL,
  country_name TEXT NOT NULL,
  previous_platform_percentage NUMERIC(5,2),
  previous_creator_percentage NUMERIC(5,2),
  new_platform_percentage NUMERIC(5,2) NOT NULL,
  new_creator_percentage NUMERIC(5,2) NOT NULL,
  change_reason TEXT,
  updated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_revenue_split_history_country ON public.revenue_split_history(country_code);
CREATE INDEX IF NOT EXISTS idx_revenue_split_history_created_at ON public.revenue_split_history(created_at DESC);

COMMENT ON TABLE public.revenue_split_history IS 'Audit trail for all revenue split changes with who/when/previous_values/new_values';

-- =====================================================
-- 4. BRAND ACCOUNTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.brand_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_name TEXT NOT NULL,
  industry TEXT,
  contact_email TEXT NOT NULL,
  contact_phone TEXT,
  stripe_customer_id TEXT,
  total_budget_allocated NUMERIC(12,2) DEFAULT 0.00,
  total_spent NUMERIC(12,2) DEFAULT 0.00,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_brand_accounts_active ON public.brand_accounts(is_active);
CREATE INDEX IF NOT EXISTS idx_brand_accounts_email ON public.brand_accounts(contact_email);

COMMENT ON TABLE public.brand_accounts IS 'Brand/advertiser accounts for participatory advertising campaigns';

-- =====================================================
-- 5. ENHANCE EXISTING SPONSORED ELECTIONS TABLE
-- =====================================================

-- Add new columns for participatory advertising if they don't exist
DO $$
BEGIN
  -- Add reward_multiplier column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'reward_multiplier'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN reward_multiplier NUMERIC(3,1) DEFAULT 2.0 CHECK (reward_multiplier >= 1.0 AND reward_multiplier <= 5.0);
  END IF;

  -- Add target_audience_tags column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'target_audience_tags'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN target_audience_tags TEXT[] DEFAULT ARRAY[]::TEXT[];
  END IF;

  -- Add campaign_start column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'campaign_start'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN campaign_start TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;
  END IF;

  -- Add campaign_end column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'campaign_end'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN campaign_end TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days');
  END IF;

  -- Add total_impressions column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'total_impressions'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN total_impressions INTEGER DEFAULT 0;
  END IF;

  -- Add total_votes column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'total_votes'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN total_votes INTEGER DEFAULT 0;
  END IF;

  -- Add engagement_rate column (different from engagement_metrics JSONB)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'sponsored_elections' 
    AND column_name = 'engagement_rate'
  ) THEN
    ALTER TABLE public.sponsored_elections 
    ADD COLUMN engagement_rate NUMERIC(5,2) DEFAULT 0.00;
  END IF;
END$$;

COMMENT ON COLUMN public.sponsored_elections.reward_multiplier IS 'XP multiplier for votes on sponsored elections (1.0x - 5.0x)';
COMMENT ON COLUMN public.sponsored_elections.target_audience_tags IS 'Interest tags for targeting specific user segments';

-- =====================================================
-- 6. AD VOTE TRACKING TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.ad_vote_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sponsored_election_id UUID NOT NULL REFERENCES public.sponsored_elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  vote_id UUID,
  cost_charged NUMERIC(6,2) NOT NULL,
  xp_awarded INTEGER NOT NULL DEFAULT 0,
  vote_status public.ad_vote_status DEFAULT 'pending',
  voted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(sponsored_election_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_ad_vote_tracking_sponsored_election ON public.ad_vote_tracking(sponsored_election_id);
CREATE INDEX IF NOT EXISTS idx_ad_vote_tracking_user_id ON public.ad_vote_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_ad_vote_tracking_voted_at ON public.ad_vote_tracking(voted_at DESC);
CREATE INDEX IF NOT EXISTS idx_ad_vote_tracking_status ON public.ad_vote_tracking(vote_status);

COMMENT ON TABLE public.ad_vote_tracking IS 'Tracks user votes on sponsored elections with cost and XP rewards';
COMMENT ON COLUMN public.ad_vote_tracking.vote_status IS 'Payment status: pending, charged, or refunded';

-- =====================================================
-- 7. GAMIFICATION ENHANCEMENTS
-- =====================================================

-- Add sponsored election tracking to XP log
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'xp_action_type') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_type t
      JOIN pg_enum e ON t.oid = e.enumtypid
      WHERE t.typname = 'xp_action_type' AND e.enumlabel = 'VOTE_SPONSORED_ELECTION'
    ) THEN
      ALTER TYPE public.xp_action_type ADD VALUE IF NOT EXISTS 'VOTE_SPONSORED_ELECTION';
    END IF;
  END IF;
END$$;

-- =====================================================
-- 8. REGIONAL REVENUE ANALYTICS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.regional_revenue_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL,
  country_name TEXT NOT NULL,
  total_creators INTEGER DEFAULT 0,
  total_revenue_usd NUMERIC(12,2) DEFAULT 0.00,
  platform_earnings_usd NUMERIC(12,2) DEFAULT 0.00,
  creator_earnings_usd NUMERIC(12,2) DEFAULT 0.00,
  average_creator_earnings_usd NUMERIC(10,2) DEFAULT 0.00,
  split_effectiveness_score NUMERIC(5,2) DEFAULT 0.00,
  creator_satisfaction_score NUMERIC(5,2) DEFAULT 0.00,
  analysis_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(country_code, analysis_date)
);

CREATE INDEX IF NOT EXISTS idx_regional_revenue_analytics_country ON public.regional_revenue_analytics(country_code);
CREATE INDEX IF NOT EXISTS idx_regional_revenue_analytics_date ON public.regional_revenue_analytics(analysis_date DESC);

COMMENT ON TABLE public.regional_revenue_analytics IS 'Daily aggregated revenue analytics by country for split effectiveness tracking';

-- =====================================================
-- 9. SPLIT RECOMMENDATION ENGINE CACHE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.split_recommendation_cache (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL,
  recommended_platform_percentage NUMERIC(5,2) NOT NULL,
  recommended_creator_percentage NUMERIC(5,2) NOT NULL,
  confidence_score NUMERIC(5,2) DEFAULT 0.00,
  reasoning TEXT,
  data_analyzed JSONB DEFAULT '{}'::JSONB,
  generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days')
);

CREATE INDEX IF NOT EXISTS idx_split_recommendation_country ON public.split_recommendation_cache(country_code);
CREATE INDEX IF NOT EXISTS idx_split_recommendation_expires ON public.split_recommendation_cache(expires_at);

COMMENT ON TABLE public.split_recommendation_cache IS 'Claude AI-powered split recommendations with 7-day cache';

-- =====================================================
-- 10. RLS POLICIES
-- =====================================================

-- Creator Revenue Splits (Admin only)
ALTER TABLE public.creator_revenue_splits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view all revenue splits" ON public.creator_revenue_splits;
CREATE POLICY "Admin can view all revenue splits"
  ON public.creator_revenue_splits FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin', 'analyst')
    )
  );

DROP POLICY IF EXISTS "Manager/Admin can update revenue splits" ON public.creator_revenue_splits;
CREATE POLICY "Manager/Admin can update revenue splits"
  ON public.creator_revenue_splits FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin')
    )
  );

DROP POLICY IF EXISTS "Manager/Admin can insert revenue splits" ON public.creator_revenue_splits;
CREATE POLICY "Manager/Admin can insert revenue splits"
  ON public.creator_revenue_splits FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin')
    )
  );

-- Revenue Split History (Admin read-only)
ALTER TABLE public.revenue_split_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view revenue split history" ON public.revenue_split_history;
CREATE POLICY "Admin can view revenue split history"
  ON public.revenue_split_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin', 'auditor', 'analyst')
    )
  );

-- Brand Accounts (Admin + Advertiser)
ALTER TABLE public.brand_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view all brand accounts" ON public.brand_accounts;
CREATE POLICY "Admin can view all brand accounts"
  ON public.brand_accounts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin', 'advertiser', 'analyst')
    )
  );

DROP POLICY IF EXISTS "Admin/Advertiser can manage brand accounts" ON public.brand_accounts;
CREATE POLICY "Admin/Advertiser can manage brand accounts"
  ON public.brand_accounts FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin', 'advertiser')
    )
  );

-- Sponsored Elections (Admin + Advertiser)
ALTER TABLE public.sponsored_elections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin/Advertiser can view sponsored elections" ON public.sponsored_elections;
CREATE POLICY "Admin/Advertiser can view sponsored elections"
  ON public.sponsored_elections FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin', 'advertiser', 'analyst')
    )
  );

DROP POLICY IF EXISTS "Admin/Advertiser can manage sponsored elections" ON public.sponsored_elections;
CREATE POLICY "Admin/Advertiser can manage sponsored elections"
  ON public.sponsored_elections FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin', 'advertiser')
    )
  );

-- Ad Vote Tracking (Users can view their own, Admin can view all)
ALTER TABLE public.ad_vote_tracking ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own ad votes" ON public.ad_vote_tracking;
CREATE POLICY "Users can view their own ad votes"
  ON public.ad_vote_tracking FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admin can view all ad votes" ON public.ad_vote_tracking;
CREATE POLICY "Admin can view all ad votes"
  ON public.ad_vote_tracking FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin', 'analyst')
    )
  );

DROP POLICY IF EXISTS "System can insert ad vote tracking" ON public.ad_vote_tracking;
CREATE POLICY "System can insert ad vote tracking"
  ON public.ad_vote_tracking FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Regional Revenue Analytics (Admin only)
ALTER TABLE public.regional_revenue_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view regional revenue analytics" ON public.regional_revenue_analytics;
CREATE POLICY "Admin can view regional revenue analytics"
  ON public.regional_revenue_analytics FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin', 'analyst')
    )
  );

-- Split Recommendation Cache (Admin only)
ALTER TABLE public.split_recommendation_cache ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view split recommendations" ON public.split_recommendation_cache;
CREATE POLICY "Admin can view split recommendations"
  ON public.split_recommendation_cache FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('manager', 'admin', 'analyst')
    )
  );

-- =====================================================
-- 11. SQL FUNCTIONS
-- =====================================================

-- Function: Calculate creator payout with country-based split
CREATE OR REPLACE FUNCTION public.calculate_creator_payout_with_split(
  p_creator_id UUID,
  p_gross_revenue NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_country_code TEXT;
  v_creator_percentage NUMERIC;
  v_payout NUMERIC;
BEGIN
  -- Get creator's country from verification table
  SELECT country INTO v_country_code
  FROM public.creator_verification
  WHERE creator_id = p_creator_id
  LIMIT 1;

  -- Default to US if no country found
  IF v_country_code IS NULL THEN
    v_country_code := 'US';
  END IF;

  -- Get creator percentage for country
  SELECT creator_percentage INTO v_creator_percentage
  FROM public.creator_revenue_splits
  WHERE country_code = v_country_code
  AND is_active = true
  LIMIT 1;

  -- Default to 70% if no split configured
  IF v_creator_percentage IS NULL THEN
    v_creator_percentage := 70.00;
  END IF;

  -- Calculate payout
  v_payout := p_gross_revenue * (v_creator_percentage / 100);

  RETURN v_payout;
END;
$$;

COMMENT ON FUNCTION public.calculate_creator_payout_with_split IS 'Calculate creator payout applying country-specific revenue split';

-- Function: Get revenue split for country
CREATE OR REPLACE FUNCTION public.get_revenue_split_for_country(
  p_country_code TEXT
)
RETURNS TABLE (
  platform_percentage NUMERIC,
  creator_percentage NUMERIC,
  currency_code TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    crs.platform_percentage,
    crs.creator_percentage,
    crs.currency_code
  FROM public.creator_revenue_splits crs
  WHERE crs.country_code = p_country_code
  AND crs.is_active = true
  LIMIT 1;

  -- Return default 30/70 split if not found
  IF NOT FOUND THEN
    RETURN QUERY SELECT 30.00::NUMERIC, 70.00::NUMERIC, 'USD'::TEXT;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.get_revenue_split_for_country IS 'Get revenue split configuration for specific country';

-- Drop old trigger-based function from previous migration to avoid name conflict
DROP FUNCTION IF EXISTS public.update_sponsored_election_metrics() CASCADE;

-- Function: Update sponsored election metrics
CREATE OR REPLACE FUNCTION public.update_sponsored_election_metrics(
  p_sponsored_election_id UUID,
  p_cost_charged NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.sponsored_elections
  SET 
    spent_budget = COALESCE(spent_budget, 0) + p_cost_charged,
    total_votes = COALESCE(total_votes, 0) + 1,
    engagement_rate = CASE 
      WHEN COALESCE(total_impressions, 0) > 0 THEN ((COALESCE(total_votes, 0) + 1)::NUMERIC / total_impressions::NUMERIC) * 100
      ELSE 0
    END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_sponsored_election_id;
END;
$$;

COMMENT ON FUNCTION public.update_sponsored_election_metrics IS 'Update sponsored election spend and engagement metrics after vote';

-- Function: Get regional revenue analytics summary
CREATE OR REPLACE FUNCTION public.get_regional_revenue_summary(
  p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
  p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  country_code TEXT,
  country_name TEXT,
  total_revenue NUMERIC,
  platform_earnings NUMERIC,
  creator_earnings NUMERIC,
  avg_split_effectiveness NUMERIC,
  avg_creator_satisfaction NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rra.country_code,
    rra.country_name,
    SUM(rra.total_revenue_usd) as total_revenue,
    SUM(rra.platform_earnings_usd) as platform_earnings,
    SUM(rra.creator_earnings_usd) as creator_earnings,
    AVG(rra.split_effectiveness_score) as avg_split_effectiveness,
    AVG(rra.creator_satisfaction_score) as avg_creator_satisfaction
  FROM public.regional_revenue_analytics rra
  WHERE rra.analysis_date BETWEEN p_start_date AND p_end_date
  GROUP BY rra.country_code, rra.country_name
  ORDER BY total_revenue DESC;
END;
$$;

COMMENT ON FUNCTION public.get_regional_revenue_summary IS 'Get aggregated regional revenue analytics for date range';

-- =====================================================
-- 12. TRIGGERS
-- =====================================================

-- Trigger: Log revenue split changes to history
CREATE OR REPLACE FUNCTION public.log_revenue_split_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    INSERT INTO public.revenue_split_history (
      country_code,
      country_name,
      previous_platform_percentage,
      previous_creator_percentage,
      new_platform_percentage,
      new_creator_percentage,
      updated_by
    ) VALUES (
      NEW.country_code,
      NEW.country_name,
      OLD.platform_percentage,
      OLD.creator_percentage,
      NEW.platform_percentage,
      NEW.creator_percentage,
      NEW.updated_by
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_log_revenue_split_change ON public.creator_revenue_splits;
CREATE TRIGGER trigger_log_revenue_split_change
  AFTER UPDATE ON public.creator_revenue_splits
  FOR EACH ROW
  EXECUTE FUNCTION public.log_revenue_split_change();

-- Trigger: Update brand account total spent
CREATE OR REPLACE FUNCTION public.update_brand_total_spent()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_brand_id UUID;
BEGIN
  -- Get brand_id from the sponsored election
  -- Note: The existing table uses brand_id column
  IF (TG_OP = 'UPDATE') THEN
    v_brand_id := NEW.brand_id;
    
    IF v_brand_id IS NOT NULL THEN
      UPDATE public.brand_accounts
      SET 
        total_spent = (
          SELECT COALESCE(SUM(spent_budget), 0)
          FROM public.sponsored_elections
          WHERE brand_id = v_brand_id
        ),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = v_brand_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_brand_total_spent ON public.sponsored_elections;
CREATE TRIGGER trigger_update_brand_total_spent
  AFTER UPDATE OF spent_budget ON public.sponsored_elections
  FOR EACH ROW
  EXECUTE FUNCTION public.update_brand_total_spent();

-- =====================================================
-- 13. SEED DATA (DEFAULT REVENUE SPLITS)
-- =====================================================

-- Insert default revenue splits for major countries
INSERT INTO public.creator_revenue_splits (country_code, country_name, platform_percentage, creator_percentage, currency_code) VALUES
  ('US', 'United States', 30.00, 70.00, 'USD'),
  ('GB', 'United Kingdom', 30.00, 70.00, 'GBP'),
  ('CA', 'Canada', 30.00, 70.00, 'CAD'),
  ('AU', 'Australia', 30.00, 70.00, 'AUD'),
  ('DE', 'Germany', 30.00, 70.00, 'EUR'),
  ('FR', 'France', 30.00, 70.00, 'EUR'),
  ('IN', 'India', 40.00, 60.00, 'INR'),
  ('NG', 'Nigeria', 25.00, 75.00, 'NGN'),
  ('BR', 'Brazil', 35.00, 65.00, 'BRL'),
  ('MX', 'Mexico', 35.00, 65.00, 'MXN'),
  ('JP', 'Japan', 30.00, 70.00, 'JPY'),
  ('CN', 'China', 40.00, 60.00, 'CNY'),
  ('ZA', 'South Africa', 30.00, 70.00, 'ZAR'),
  ('AE', 'United Arab Emirates', 25.00, 75.00, 'AED'),
  ('SG', 'Singapore', 30.00, 70.00, 'SGD')
ON CONFLICT (country_code) DO NOTHING;

-- =====================================================
-- 14. FEATURE FLAG FOR PARTICIPATORY ADVERTISING
-- =====================================================

-- Ensure feature_flags table has the correct schema
CREATE TABLE IF NOT EXISTS public.feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_name TEXT NOT NULL UNIQUE,
  is_enabled BOOLEAN DEFAULT false,
  category TEXT NOT NULL,
  description TEXT,
  dependencies TEXT[],
  usage_count INTEGER DEFAULT 0,
  rollout_percentage INTEGER DEFAULT 100 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  scheduled_enable_at TIMESTAMPTZ,
  scheduled_disable_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure feature_name column exists (defensive)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'feature_flags' 
    AND column_name = 'feature_name'
  ) THEN
    ALTER TABLE public.feature_flags ADD COLUMN feature_name TEXT NOT NULL UNIQUE;
  END IF;
  
  -- Ensure is_enabled column exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'feature_flags' 
    AND column_name = 'is_enabled'
  ) THEN
    ALTER TABLE public.feature_flags ADD COLUMN is_enabled BOOLEAN DEFAULT false;
  END IF;
  
  -- Ensure category column exists (handle both TEXT and ENUM types)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'feature_flags' 
    AND column_name = 'category'
  ) THEN
    ALTER TABLE public.feature_flags ADD COLUMN category TEXT NOT NULL DEFAULT 'general';
  END IF;
  
  -- Ensure description column exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'feature_flags' 
    AND column_name = 'description'
  ) THEN
    ALTER TABLE public.feature_flags ADD COLUMN description TEXT;
  END IF;
  
  -- Ensure flag_name column exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'feature_flags' 
    AND column_name = 'flag_name'
  ) THEN
    ALTER TABLE public.feature_flags ADD COLUMN flag_name TEXT NOT NULL DEFAULT '';
  END IF;
  
  -- Ensure flag_key column exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'feature_flags' 
    AND column_name = 'flag_key'
  ) THEN
    ALTER TABLE public.feature_flags ADD COLUMN flag_key TEXT;
  END IF;
END $$;

INSERT INTO public.feature_flags (flag_key, flag_name, feature_name, is_enabled, category, description) VALUES
  ('participatory_advertising', 'participatory_advertising', 'participatory_advertising', true, 'monetization', 'Enable gamified sponsored elections in feed with XP rewards')
ON CONFLICT (feature_name) DO UPDATE SET
  flag_key = EXCLUDED.flag_key,
  flag_name = EXCLUDED.flag_name,
  is_enabled = EXCLUDED.is_enabled,
  category = EXCLUDED.category,
  description = EXCLUDED.description;

COMMENT ON TABLE public.creator_revenue_splits IS 'Flexible country-based revenue splits for creator monetization optimization';
COMMENT ON TABLE public.ad_vote_tracking IS 'Participatory advertising: Tracks votes on sponsored elections with engagement-based billing';