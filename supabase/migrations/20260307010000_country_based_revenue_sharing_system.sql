-- =====================================================
-- COUNTRY-BASED REVENUE SHARING SYSTEM
-- Migration: 20260307010000
-- Description: Flexible admin-controlled revenue splits per country with audit trails,
--              split history tracking, negotiation interface, and payout calculation integration
-- =====================================================

-- =====================================================
-- 1. CREATOR REVENUE SPLITS TABLE (Core Configuration)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.creator_revenue_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL UNIQUE CHECK (LENGTH(country_code) = 2),
  country_name TEXT NOT NULL,
  platform_percentage NUMERIC(5,2) NOT NULL CHECK (platform_percentage >= 0 AND platform_percentage <= 100),
  creator_percentage NUMERIC(5,2) NOT NULL CHECK (creator_percentage >= 0 AND creator_percentage <= 100),
  currency_code TEXT DEFAULT 'USD',
  is_active BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  CONSTRAINT valid_split_total CHECK (platform_percentage + creator_percentage = 100)
);

CREATE INDEX IF NOT EXISTS idx_creator_revenue_splits_country_code ON public.creator_revenue_splits(country_code);
CREATE INDEX IF NOT EXISTS idx_creator_revenue_splits_active ON public.creator_revenue_splits(is_active) WHERE is_active = true;

COMMENT ON TABLE public.creator_revenue_splits IS 'Country-specific revenue split configuration (e.g., US: 70/30, India: 60/40, Nigeria: 75/25)';
COMMENT ON COLUMN public.creator_revenue_splits.platform_percentage IS 'Platform share percentage (0-100)';
COMMENT ON COLUMN public.creator_revenue_splits.creator_percentage IS 'Creator share percentage (0-100)';

-- =====================================================
-- 2. REVENUE SPLIT HISTORY (Audit Trail for Changes)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.revenue_split_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL,
  previous_platform_percentage NUMERIC(5,2),
  previous_creator_percentage NUMERIC(5,2),
  new_platform_percentage NUMERIC(5,2) NOT NULL,
  new_creator_percentage NUMERIC(5,2) NOT NULL,
  change_reason TEXT,
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  effective_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  notification_sent BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_revenue_split_history_country ON public.revenue_split_history(country_code);
CREATE INDEX IF NOT EXISTS idx_revenue_split_history_changed_at ON public.revenue_split_history(changed_at DESC);

COMMENT ON TABLE public.revenue_split_history IS 'Complete audit trail of all revenue split changes with 30-day notice tracking';

-- =====================================================
-- 3. CREATOR SPLIT NEGOTIATIONS (High-Performing Creators)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.creator_split_negotiations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  requested_creator_percentage NUMERIC(5,2) NOT NULL CHECK (requested_creator_percentage >= 0 AND requested_creator_percentage <= 100),
  justification TEXT NOT NULL,
  monthly_revenue_usd NUMERIC(10,2) NOT NULL,
  performance_metrics JSONB DEFAULT '{}'::JSONB,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
  admin_notes TEXT,
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '90 days'),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_creator_split_negotiations_creator ON public.creator_split_negotiations(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_split_negotiations_status ON public.creator_split_negotiations(status);
CREATE INDEX IF NOT EXISTS idx_creator_split_negotiations_pending ON public.creator_split_negotiations(status) WHERE status = 'pending';

COMMENT ON TABLE public.creator_split_negotiations IS 'Custom split requests from high-performing creators (>$10k monthly revenue)';

-- =====================================================
-- 4. CREATOR SPLIT PREFERENCES (Grandfathering & Notifications)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.creator_split_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL UNIQUE REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  grandfathered_split_percentage NUMERIC(5,2),
  grandfathered_until TIMESTAMPTZ,
  opted_into_grandfathering BOOLEAN DEFAULT false,
  notify_on_split_changes BOOLEAN DEFAULT true,
  notification_email TEXT,
  notification_sms TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_creator_split_preferences_creator ON public.creator_split_preferences(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_split_preferences_grandfathered ON public.creator_split_preferences(grandfathered_until) WHERE grandfathered_until IS NOT NULL;

COMMENT ON TABLE public.creator_split_preferences IS 'Creator preferences for split notifications and grandfathering options (90-day protection)';

-- =====================================================
-- 5. SPLIT EFFECTIVENESS ANALYTICS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.split_effectiveness_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL,
  measurement_period TEXT NOT NULL,
  total_revenue_usd NUMERIC(12,2) DEFAULT 0,
  platform_earnings_usd NUMERIC(12,2) DEFAULT 0,
  creator_earnings_usd NUMERIC(12,2) DEFAULT 0,
  active_creators INTEGER DEFAULT 0,
  creator_satisfaction_score NUMERIC(3,2),
  content_quality_score NUMERIC(3,2),
  creator_retention_rate NUMERIC(5,2),
  revenue_growth_rate NUMERIC(5,2),
  measured_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_split_effectiveness_country ON public.split_effectiveness_metrics(country_code);
CREATE INDEX IF NOT EXISTS idx_split_effectiveness_measured_at ON public.split_effectiveness_metrics(measured_at DESC);

COMMENT ON TABLE public.split_effectiveness_metrics IS 'Analytics tracking split performance by country for optimization recommendations';

-- =====================================================
-- 6. RLS POLICIES
-- =====================================================

-- Creator Revenue Splits (Admin Only)
ALTER TABLE public.creator_revenue_splits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view all revenue splits" ON public.creator_revenue_splits;
CREATE POLICY "Admin can view all revenue splits"
  ON public.creator_revenue_splits
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'finance_admin')
    )
  );

DROP POLICY IF EXISTS "Admin can manage revenue splits" ON public.creator_revenue_splits;
CREATE POLICY "Admin can manage revenue splits"
  ON public.creator_revenue_splits
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'finance_admin')
    )
  );

-- Revenue Split History (Admin + Creators can view their country)
ALTER TABLE public.revenue_split_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view split history" ON public.revenue_split_history;
CREATE POLICY "Admin can view split history"
  ON public.revenue_split_history
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'finance_admin')
    )
  );

DROP POLICY IF EXISTS "Creators can view their country split history" ON public.revenue_split_history;
CREATE POLICY "Creators can view their country split history"
  ON public.revenue_split_history
  FOR SELECT
  USING (
    country_code = (
      SELECT country FROM public.creator_verification
      WHERE creator_id = auth.uid()
    )
  );

-- Creator Split Negotiations
ALTER TABLE public.creator_split_negotiations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own negotiations" ON public.creator_split_negotiations;
CREATE POLICY "Creators can view own negotiations"
  ON public.creator_split_negotiations
  FOR SELECT
  USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can create negotiations" ON public.creator_split_negotiations;
CREATE POLICY "Creators can create negotiations"
  ON public.creator_split_negotiations
  FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Admin can manage negotiations" ON public.creator_split_negotiations;
CREATE POLICY "Admin can manage negotiations"
  ON public.creator_split_negotiations
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'finance_admin')
    )
  );

-- Creator Split Preferences
ALTER TABLE public.creator_split_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can manage own preferences" ON public.creator_split_preferences;
CREATE POLICY "Creators can manage own preferences"
  ON public.creator_split_preferences
  FOR ALL
  USING (auth.uid() = creator_id);

-- Split Effectiveness Metrics (Admin Only)
ALTER TABLE public.split_effectiveness_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view effectiveness metrics" ON public.split_effectiveness_metrics;
CREATE POLICY "Admin can view effectiveness metrics"
  ON public.split_effectiveness_metrics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'finance_admin')
    )
  );

-- =====================================================
-- 7. SQL FUNCTIONS
-- =====================================================

-- Function: Get creator's applicable revenue split (with grandfathering)
CREATE OR REPLACE FUNCTION public.get_creator_revenue_split(p_creator_id UUID)
RETURNS TABLE (
  platform_percentage NUMERIC,
  creator_percentage NUMERIC,
  is_grandfathered BOOLEAN,
  grandfathered_until TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_country_code TEXT;
  v_grandfathered_split NUMERIC;
  v_grandfathered_until TIMESTAMPTZ;
  v_opted_in BOOLEAN;
BEGIN
  -- Get creator's country from verification
  SELECT country INTO v_country_code
  FROM public.creator_verification
  WHERE creator_id = p_creator_id;

  IF v_country_code IS NULL THEN
    v_country_code := 'US'; -- Default to US if no country set
  END IF;

  -- Check for grandfathered split
  SELECT grandfathered_split_percentage, grandfathered_until, opted_into_grandfathering
  INTO v_grandfathered_split, v_grandfathered_until, v_opted_in
  FROM public.creator_split_preferences
  WHERE creator_id = p_creator_id;

  -- If grandfathered and still valid
  IF v_opted_in = true AND v_grandfathered_until > CURRENT_TIMESTAMP THEN
    RETURN QUERY SELECT 
      (100 - v_grandfathered_split)::NUMERIC AS platform_percentage,
      v_grandfathered_split AS creator_percentage,
      true AS is_grandfathered,
      v_grandfathered_until;
  ELSE
    -- Use current country split
    RETURN QUERY SELECT 
      crs.platform_percentage,
      crs.creator_percentage,
      false AS is_grandfathered,
      NULL::TIMESTAMPTZ AS grandfathered_until
    FROM public.creator_revenue_splits crs
    WHERE crs.country_code = v_country_code
    AND crs.is_active = true;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.get_creator_revenue_split IS 'Returns applicable revenue split for creator considering grandfathering (90-day protection)';

-- Function: Calculate creator payout with country split
CREATE OR REPLACE FUNCTION public.calculate_creator_payout(
  p_creator_id UUID,
  p_gross_revenue_usd NUMERIC
)
RETURNS TABLE (
  creator_payout_usd NUMERIC,
  platform_share_usd NUMERIC,
  split_percentage NUMERIC,
  is_grandfathered BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_split RECORD;
BEGIN
  -- Get applicable split
  SELECT * INTO v_split FROM public.get_creator_revenue_split(p_creator_id);

  RETURN QUERY SELECT
    ROUND(p_gross_revenue_usd * (v_split.creator_percentage / 100), 2) AS creator_payout_usd,
    ROUND(p_gross_revenue_usd * (v_split.platform_percentage / 100), 2) AS platform_share_usd,
    v_split.creator_percentage AS split_percentage,
    v_split.is_grandfathered;
END;
$$;

COMMENT ON FUNCTION public.calculate_creator_payout IS 'Calculates creator payout applying country-specific revenue split with grandfathering';

-- Function: Update revenue split with audit trail
CREATE OR REPLACE FUNCTION public.update_revenue_split(
  p_country_code TEXT,
  p_new_platform_percentage NUMERIC,
  p_new_creator_percentage NUMERIC,
  p_change_reason TEXT,
  p_changed_by UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_previous_platform NUMERIC;
  v_previous_creator NUMERIC;
  v_history_id UUID;
BEGIN
  -- Validate split totals 100%
  IF p_new_platform_percentage + p_new_creator_percentage != 100 THEN
    RAISE EXCEPTION 'Split percentages must total 100%%';
  END IF;

  -- Get previous values
  SELECT platform_percentage, creator_percentage
  INTO v_previous_platform, v_previous_creator
  FROM public.creator_revenue_splits
  WHERE country_code = p_country_code;

  -- Update split
  UPDATE public.creator_revenue_splits
  SET 
    platform_percentage = p_new_platform_percentage,
    creator_percentage = p_new_creator_percentage,
    updated_at = CURRENT_TIMESTAMP,
    updated_by = p_changed_by
  WHERE country_code = p_country_code;

  -- Log history
  INSERT INTO public.revenue_split_history (
    country_code,
    previous_platform_percentage,
    previous_creator_percentage,
    new_platform_percentage,
    new_creator_percentage,
    change_reason,
    changed_by,
    effective_date
  ) VALUES (
    p_country_code,
    v_previous_platform,
    v_previous_creator,
    p_new_platform_percentage,
    p_new_creator_percentage,
    p_change_reason,
    p_changed_by,
    CURRENT_TIMESTAMP + INTERVAL '30 days' -- 30-day notice period
  )
  RETURNING id INTO v_history_id;

  RETURN v_history_id;
END;
$$;

COMMENT ON FUNCTION public.update_revenue_split IS 'Updates revenue split with automatic audit trail and 30-day notice period';

-- =====================================================
-- 8. INITIAL DATA (Default Splits for Major Countries)
-- =====================================================

DO $$
BEGIN
  -- Insert default splits only if table is empty
  IF NOT EXISTS (SELECT 1 FROM public.creator_revenue_splits LIMIT 1) THEN
    INSERT INTO public.creator_revenue_splits (country_code, country_name, platform_percentage, creator_percentage, currency_code) VALUES
    ('US', 'United States', 30.00, 70.00, 'USD'),
    ('CA', 'Canada', 30.00, 70.00, 'CAD'),
    ('GB', 'United Kingdom', 30.00, 70.00, 'GBP'),
    ('IN', 'India', 40.00, 60.00, 'INR'),
    ('NG', 'Nigeria', 25.00, 75.00, 'NGN'),
    ('BR', 'Brazil', 35.00, 65.00, 'BRL'),
    ('MX', 'Mexico', 35.00, 65.00, 'MXN'),
    ('DE', 'Germany', 30.00, 70.00, 'EUR'),
    ('FR', 'France', 30.00, 70.00, 'EUR'),
    ('AU', 'Australia', 30.00, 70.00, 'AUD'),
    ('JP', 'Japan', 30.00, 70.00, 'JPY'),
    ('CN', 'China', 35.00, 65.00, 'CNY'),
    ('ZA', 'South Africa', 35.00, 65.00, 'ZAR'),
    ('KE', 'Kenya', 30.00, 70.00, 'KES'),
    ('PH', 'Philippines', 35.00, 65.00, 'PHP'),
    ('ID', 'Indonesia', 35.00, 65.00, 'IDR'),
    ('AR', 'Argentina', 35.00, 65.00, 'ARS'),
    ('EG', 'Egypt', 35.00, 65.00, 'EGP'),
    ('PK', 'Pakistan', 35.00, 65.00, 'PKR'),
    ('BD', 'Bangladesh', 35.00, 65.00, 'BDT')
    ON CONFLICT (country_code) DO NOTHING;

    RAISE NOTICE 'Inserted default revenue splits for 20 major countries';
  END IF;
END $$;

-- =====================================================
-- 9. TRIGGERS
-- =====================================================

-- Trigger: Auto-expire grandfathered splits after 90 days
CREATE OR REPLACE FUNCTION public.expire_grandfathered_splits()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.grandfathered_until < CURRENT_TIMESTAMP THEN
    NEW.opted_into_grandfathering := false;
    NEW.grandfathered_split_percentage := NULL;
    NEW.grandfathered_until := NULL;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_expire_grandfathered_splits ON public.creator_split_preferences;
CREATE TRIGGER trigger_expire_grandfathered_splits
BEFORE UPDATE ON public.creator_split_preferences
FOR EACH ROW
EXECUTE FUNCTION public.expire_grandfathered_splits();

COMMENT ON FUNCTION public.expire_grandfathered_splits IS 'Automatically expires grandfathered splits after 90-day protection period';