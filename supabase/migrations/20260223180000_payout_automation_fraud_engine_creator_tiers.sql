-- Phase: Payout Automation + Fraud Detection Engine + Creator Tier System
-- Implements automated Stripe payout scheduler, Claude fraud detection, and 5-tier creator progression

-- =====================================================
-- 1. TYPES
-- =====================================================

DROP TYPE IF EXISTS public.payout_schedule_frequency CASCADE;
CREATE TYPE public.payout_schedule_frequency AS ENUM ('daily', 'weekly', 'biweekly', 'monthly');

DROP TYPE IF EXISTS public.fraud_event_type CASCADE;
CREATE TYPE public.fraud_event_type AS ENUM ('behavioral_anomaly', 'coordinated_voting', 'account_manipulation', 'earnings_fraud', 'multi_accounting');

DROP TYPE IF EXISTS public.fraud_risk_level CASCADE;
CREATE TYPE public.fraud_risk_level AS ENUM ('minimal', 'low', 'medium', 'high', 'critical');

DROP TYPE IF EXISTS public.suspension_status CASCADE;
CREATE TYPE public.suspension_status AS ENUM ('active', 'appealed', 'lifted', 'permanent');

DROP TYPE IF EXISTS public.appeal_status CASCADE;
CREATE TYPE public.appeal_status AS ENUM ('pending', 'approved', 'denied', 'escalated');

DROP TYPE IF EXISTS public.creator_tier_new CASCADE;
CREATE TYPE public.creator_tier_new AS ENUM ('bronze', 'silver', 'gold', 'platinum', 'elite');

-- =====================================================
-- 2. PAYOUT AUTOMATION TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.payout_schedule_config (
  config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_level public.creator_tier_new NOT NULL UNIQUE,
  schedule_frequency public.payout_schedule_frequency NOT NULL,
  minimum_threshold DECIMAL(10,2) NOT NULL,
  auto_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.tax_treaty_rates (
  treaty_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code VARCHAR(2) NOT NULL,
  country_name VARCHAR(100) NOT NULL,
  default_rate DECIMAL(5,4) NOT NULL DEFAULT 0.3000,
  treaty_rate DECIMAL(5,4),
  effective_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(country_code, effective_date)
);

CREATE TABLE IF NOT EXISTS public.tax_withholding_records (
  record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  settlement_id UUID REFERENCES public.settlement_records(settlement_id) ON DELETE SET NULL,
  withholding_amount DECIMAL(10,2) NOT NULL,
  tax_rate DECIMAL(5,4) NOT NULL,
  country_code VARCHAR(2) NOT NULL,
  withheld_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. FRAUD DETECTION ENGINE TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.fraud_detection_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  event_type public.fraud_event_type NOT NULL,
  fraud_score DECIMAL(3,2) NOT NULL CHECK (fraud_score >= 0 AND fraud_score <= 1),
  confidence DECIMAL(3,2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  fraud_indicators JSONB NOT NULL DEFAULT '{}'::jsonb,
  risk_level public.fraud_risk_level NOT NULL,
  detected_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  action_taken VARCHAR(100),
  claude_analysis_id VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS public.account_suspensions (
  suspension_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  suspension_reason TEXT NOT NULL,
  fraud_event_id UUID REFERENCES public.fraud_detection_events(event_id) ON DELETE SET NULL,
  expires_at TIMESTAMPTZ,
  status public.suspension_status DEFAULT 'active'::public.suspension_status,
  suspended_by UUID REFERENCES public.user_profiles(id),
  suspended_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  lifted_at TIMESTAMPTZ,
  lifted_by UUID REFERENCES public.user_profiles(id)
);

CREATE TABLE IF NOT EXISTS public.fraud_appeals (
  appeal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  suspension_id UUID NOT NULL REFERENCES public.account_suspensions(suspension_id) ON DELETE CASCADE,
  appellant_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  appeal_reason TEXT NOT NULL,
  evidence_urls JSONB DEFAULT '[]'::jsonb,
  status public.appeal_status DEFAULT 'pending'::public.appeal_status,
  reviewed_by UUID REFERENCES public.user_profiles(id),
  reviewed_at TIMESTAMPTZ,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 4. CREATOR TIER & INCENTIVE SYSTEM TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.creator_tier_config (
  tier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_level public.creator_tier_new NOT NULL UNIQUE,
  tier_rank INTEGER NOT NULL UNIQUE,
  tier_name VARCHAR(50) NOT NULL,
  earnings_requirement DECIMAL(10,2) NOT NULL,
  vp_requirement INTEGER NOT NULL,
  vp_multiplier DECIMAL(3,2) NOT NULL,
  payout_schedule public.payout_schedule_frequency NOT NULL,
  minimum_threshold DECIMAL(10,2) NOT NULL,
  features JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.tier_upgrade_history (
  upgrade_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  old_tier public.creator_tier_new,
  new_tier public.creator_tier_new NOT NULL,
  upgraded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 5. INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_tax_withholding_creator ON public.tax_withholding_records(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_tax_withholding_settlement ON public.tax_withholding_records(settlement_id);
CREATE INDEX IF NOT EXISTS idx_tax_treaty_country ON public.tax_treaty_rates(country_code);

CREATE INDEX IF NOT EXISTS idx_fraud_events_user ON public.fraud_detection_events(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_events_type ON public.fraud_detection_events(event_type);
CREATE INDEX IF NOT EXISTS idx_fraud_events_risk ON public.fraud_detection_events(risk_level);
CREATE INDEX IF NOT EXISTS idx_fraud_events_detected ON public.fraud_detection_events(detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_account_suspensions_user ON public.account_suspensions(user_id);
CREATE INDEX IF NOT EXISTS idx_account_suspensions_status ON public.account_suspensions(status);
CREATE INDEX IF NOT EXISTS idx_account_suspensions_expires ON public.account_suspensions(expires_at);

CREATE INDEX IF NOT EXISTS idx_fraud_appeals_suspension ON public.fraud_appeals(suspension_id);
CREATE INDEX IF NOT EXISTS idx_fraud_appeals_status ON public.fraud_appeals(status);

CREATE INDEX IF NOT EXISTS idx_tier_upgrade_user ON public.tier_upgrade_history(user_id);
CREATE INDEX IF NOT EXISTS idx_tier_upgrade_date ON public.tier_upgrade_history(upgraded_at DESC);

-- =====================================================
-- 6. FUNCTIONS
-- =====================================================

-- Function to calculate tier based on earnings and VP
CREATE OR REPLACE FUNCTION public.calculate_creator_tier(p_total_earnings DECIMAL, p_lifetime_vp INTEGER)
RETURNS public.creator_tier_new
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  tier_result public.creator_tier_new;
BEGIN
  -- Check from highest tier down
  IF p_total_earnings >= 250000 AND p_lifetime_vp >= 500000 THEN
    tier_result := 'elite'::public.creator_tier_new;
  ELSIF p_total_earnings >= 50000 AND p_lifetime_vp >= 100000 THEN
    tier_result := 'platinum'::public.creator_tier_new;
  ELSIF p_total_earnings >= 10000 AND p_lifetime_vp >= 25000 THEN
    tier_result := 'gold'::public.creator_tier_new;
  ELSIF p_total_earnings >= 1000 AND p_lifetime_vp >= 5000 THEN
    tier_result := 'silver'::public.creator_tier_new;
  ELSE
    tier_result := 'bronze'::public.creator_tier_new;
  END IF;
  
  RETURN tier_result;
END;
$$;

-- Function to get tax withholding rate
CREATE OR REPLACE FUNCTION public.get_tax_withholding_rate(p_country_code VARCHAR)
RETURNS DECIMAL
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  withholding_rate DECIMAL;
BEGIN
  SELECT COALESCE(treaty_rate, default_rate) INTO withholding_rate
  FROM public.tax_treaty_rates
  WHERE country_code = p_country_code
  AND effective_date <= CURRENT_DATE
  ORDER BY effective_date DESC
  LIMIT 1;
  
  RETURN COALESCE(withholding_rate, 0.3000);
END;
$$;

-- =====================================================
-- 7. ENABLE RLS
-- =====================================================

ALTER TABLE public.payout_schedule_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_treaty_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_withholding_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_detection_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.account_suspensions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_appeals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_tier_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tier_upgrade_history ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 8. RLS POLICIES
-- =====================================================

-- Payout Schedule Config: Admin only
DROP POLICY IF EXISTS "admin_manage_payout_schedule_config" ON public.payout_schedule_config;
CREATE POLICY "admin_manage_payout_schedule_config"
ON public.payout_schedule_config
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

DROP POLICY IF EXISTS "public_read_payout_schedule_config" ON public.payout_schedule_config;
CREATE POLICY "public_read_payout_schedule_config"
ON public.payout_schedule_config
FOR SELECT
TO authenticated
USING (true);

-- Tax Treaty Rates: Public read, admin write
DROP POLICY IF EXISTS "public_read_tax_treaty_rates" ON public.tax_treaty_rates;
CREATE POLICY "public_read_tax_treaty_rates"
ON public.tax_treaty_rates
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "admin_manage_tax_treaty_rates" ON public.tax_treaty_rates;
CREATE POLICY "admin_manage_tax_treaty_rates"
ON public.tax_treaty_rates
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- Tax Withholding Records: Users view own
DROP POLICY IF EXISTS "users_view_own_tax_withholding_records" ON public.tax_withholding_records;
CREATE POLICY "users_view_own_tax_withholding_records"
ON public.tax_withholding_records
FOR SELECT
TO authenticated
USING (creator_user_id = auth.uid());

DROP POLICY IF EXISTS "system_insert_tax_withholding_records" ON public.tax_withholding_records;
CREATE POLICY "system_insert_tax_withholding_records"
ON public.tax_withholding_records
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Fraud Detection Events: Admin and affected user
DROP POLICY IF EXISTS "users_view_own_fraud_events" ON public.fraud_detection_events;
CREATE POLICY "users_view_own_fraud_events"
ON public.fraud_detection_events
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "admin_view_all_fraud_events" ON public.fraud_detection_events;
CREATE POLICY "admin_view_all_fraud_events"
ON public.fraud_detection_events
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

DROP POLICY IF EXISTS "system_insert_fraud_events" ON public.fraud_detection_events;
CREATE POLICY "system_insert_fraud_events"
ON public.fraud_detection_events
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Account Suspensions: Admin manage, users view own
DROP POLICY IF EXISTS "users_view_own_suspensions" ON public.account_suspensions;
CREATE POLICY "users_view_own_suspensions"
ON public.account_suspensions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_suspensions" ON public.account_suspensions;
CREATE POLICY "admin_manage_suspensions"
ON public.account_suspensions
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- Fraud Appeals: Users manage own
DROP POLICY IF EXISTS "users_manage_own_fraud_appeals" ON public.fraud_appeals;
CREATE POLICY "users_manage_own_fraud_appeals"
ON public.fraud_appeals
FOR ALL
TO authenticated
USING (appellant_user_id = auth.uid())
WITH CHECK (appellant_user_id = auth.uid());

DROP POLICY IF EXISTS "admin_review_fraud_appeals" ON public.fraud_appeals;
CREATE POLICY "admin_review_fraud_appeals"
ON public.fraud_appeals
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- Creator Tier Config: Public read, admin write
DROP POLICY IF EXISTS "public_read_creator_tier_config" ON public.creator_tier_config;
CREATE POLICY "public_read_creator_tier_config"
ON public.creator_tier_config
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "admin_manage_creator_tier_config" ON public.creator_tier_config;
CREATE POLICY "admin_manage_creator_tier_config"
ON public.creator_tier_config
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- Tier Upgrade History: Users view own
DROP POLICY IF EXISTS "users_view_own_tier_history" ON public.tier_upgrade_history;
CREATE POLICY "users_view_own_tier_history"
ON public.tier_upgrade_history
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "system_insert_tier_history" ON public.tier_upgrade_history;
CREATE POLICY "system_insert_tier_history"
ON public.tier_upgrade_history
FOR INSERT
TO authenticated
WITH CHECK (true);

-- =====================================================
-- 9. MOCK DATA
-- =====================================================

DO $$
DECLARE
  existing_user_id UUID;
BEGIN
  -- Payout Schedule Config (Tier-based)
  INSERT INTO public.payout_schedule_config (tier_level, schedule_frequency, minimum_threshold, auto_enabled) VALUES
    ('bronze'::public.creator_tier_new, 'weekly'::public.payout_schedule_frequency, 50.00, true),
    ('silver'::public.creator_tier_new, 'biweekly'::public.payout_schedule_frequency, 100.00, true),
    ('gold'::public.creator_tier_new, 'weekly'::public.payout_schedule_frequency, 25.00, true),
    ('platinum'::public.creator_tier_new, 'daily'::public.payout_schedule_frequency, 10.00, true),
    ('elite'::public.creator_tier_new, 'daily'::public.payout_schedule_frequency, 5.00, true)
  ON CONFLICT (tier_level) DO NOTHING;

  -- Tax Treaty Rates
  INSERT INTO public.tax_treaty_rates (country_code, country_name, default_rate, treaty_rate, effective_date) VALUES
    ('US', 'United States', 0.0000, NULL, '2024-01-01'),
    ('GB', 'United Kingdom', 0.3000, 0.0000, '2024-01-01'),
    ('CA', 'Canada', 0.3000, 0.1500, '2024-01-01'),
    ('IN', 'India', 0.3000, 0.1000, '2024-01-01'),
    ('AU', 'Australia', 0.3000, 0.0500, '2024-01-01'),
    ('DE', 'Germany', 0.3000, 0.0000, '2024-01-01'),
    ('FR', 'France', 0.3000, 0.0000, '2024-01-01'),
    ('JP', 'Japan', 0.3000, 0.1000, '2024-01-01')
  ON CONFLICT (country_code, effective_date) DO NOTHING;

  -- Creator Tier Config
  INSERT INTO public.creator_tier_config (tier_level, tier_rank, tier_name, earnings_requirement, vp_requirement, vp_multiplier, payout_schedule, minimum_threshold, features) VALUES
    ('bronze'::public.creator_tier_new, 1, 'Bronze', 0.00, 0, 1.00, 'weekly'::public.payout_schedule_frequency, 50.00, '["standard_support"]'::jsonb),
    ('silver'::public.creator_tier_new, 2, 'Silver', 1000.00, 5000, 1.20, 'biweekly'::public.payout_schedule_frequency, 100.00, '["priority_support", "analytics_basic"]'::jsonb),
    ('gold'::public.creator_tier_new, 3, 'Gold', 10000.00, 25000, 1.50, 'weekly'::public.payout_schedule_frequency, 25.00, '["analytics_advanced", "custom_badge", "priority_listing"]'::jsonb),
    ('platinum'::public.creator_tier_new, 4, 'Platinum', 50000.00, 100000, 2.00, 'daily'::public.payout_schedule_frequency, 10.00, '["account_manager", "early_access", "marketplace_priority"]'::jsonb),
    ('elite'::public.creator_tier_new, 5, 'Elite', 250000.00, 500000, 2.50, 'daily'::public.payout_schedule_frequency, 5.00, '["exclusive_events", "partnerships", "revenue_share_75_25"]'::jsonb)
  ON CONFLICT (tier_level) DO NOTHING;

  -- Mock fraud detection event
  SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
  IF existing_user_id IS NOT NULL THEN
    INSERT INTO public.fraud_detection_events (user_id, event_type, fraud_score, confidence, fraud_indicators, risk_level, action_taken)
    VALUES (
      existing_user_id,
      'behavioral_anomaly'::public.fraud_event_type,
      0.45,
      0.82,
      '{"votes_per_hour": 85, "velocity": "high", "device_changes": 2}'::jsonb,
      'medium'::public.fraud_risk_level,
      'flagged'
    )
    ON CONFLICT (event_id) DO NOTHING;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;