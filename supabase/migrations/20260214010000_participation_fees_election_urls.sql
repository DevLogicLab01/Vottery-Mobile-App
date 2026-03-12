-- Phase 1 Batch 1: Core Monetization - Participation Fees & Election URLs
-- Timestamp: 20260214010000
-- Description: Participation fee system, regional pricing zones, unique election URLs, admin controls

-- ============================================================
-- 1. TYPES
-- ============================================================

DO $$ BEGIN
  CREATE TYPE public.participation_fee_type AS ENUM (
    'free',
    'paid_general',
    'paid_regional'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.fee_payment_status AS ENUM (
    'pending',
    'completed',
    'failed',
    'refunded'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 2. EXTEND ELECTIONS TABLE
-- ============================================================

-- Add participation fee fields
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS participation_fee_type public.participation_fee_type DEFAULT 'free';
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS general_fee_amount NUMERIC(8,2) DEFAULT 0.00;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS regional_fee_amounts JSONB DEFAULT '{}'::jsonb;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS unique_url TEXT;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS qr_code_data TEXT;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS external_access_enabled BOOLEAN DEFAULT true;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS total_fee_collected NUMERIC(12,2) DEFAULT 0.00;

-- ============================================================
-- 3. PARTICIPATION FEE PAYMENTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.participation_fee_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount NUMERIC(8,2) NOT NULL,
  currency_code TEXT DEFAULT 'USD',
  purchasing_power_zone public.purchasing_power_zone,
  payment_status public.fee_payment_status DEFAULT 'pending',
  stripe_payment_intent_id TEXT,
  stripe_charge_id TEXT,
  paid_at TIMESTAMPTZ,
  refunded_at TIMESTAMPTZ,
  refund_reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, user_id)
);

-- ============================================================
-- 4. ELECTION REGIONAL FEE CONFIG TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_regional_fees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  zone public.purchasing_power_zone NOT NULL,
  fee_amount NUMERIC(8,2) NOT NULL,
  currency_code TEXT DEFAULT 'USD',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, zone)
);

-- ============================================================
-- 5. ADMIN FEATURE CONTROLS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.platform_feature_controls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_name TEXT NOT NULL UNIQUE,
  is_globally_enabled BOOLEAN DEFAULT false,
  enabled_countries TEXT[] DEFAULT ARRAY[]::TEXT[],
  disabled_countries TEXT[] DEFAULT ARRAY[]::TEXT[],
  configuration JSONB DEFAULT '{}'::jsonb,
  updated_by UUID REFERENCES public.user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Insert default participation fee control
INSERT INTO public.platform_feature_controls (feature_name, is_globally_enabled, configuration)
VALUES (
  'participation_fees',
  false,
  '{"min_fee_usd": 0.50, "max_fee_usd": 1000.00, "default_currency": "USD"}'::jsonb
)
ON CONFLICT (feature_name) DO NOTHING;

-- ============================================================
-- 6. EXTERNAL USER REGISTRATION TRACKING
-- ============================================================

CREATE TABLE IF NOT EXISTS public.external_election_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  access_source TEXT NOT NULL, -- 'url', 'qr_code', 'share'
  referrer_url TEXT,
  ip_address TEXT,
  user_agent TEXT,
  country_code TEXT,
  registered_via_external BOOLEAN DEFAULT false,
  voted BOOLEAN DEFAULT false,
  accessed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  registered_at TIMESTAMPTZ,
  voted_at TIMESTAMPTZ
);

-- ============================================================
-- 7. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_elections_unique_url ON public.elections(unique_url);
CREATE INDEX IF NOT EXISTS idx_elections_fee_type ON public.elections(participation_fee_type);
CREATE INDEX IF NOT EXISTS idx_participation_fee_payments_election ON public.participation_fee_payments(election_id);
CREATE INDEX IF NOT EXISTS idx_participation_fee_payments_user ON public.participation_fee_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_participation_fee_payments_status ON public.participation_fee_payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_election_regional_fees_election ON public.election_regional_fees(election_id);
CREATE INDEX IF NOT EXISTS idx_election_regional_fees_zone ON public.election_regional_fees(zone);
CREATE INDEX IF NOT EXISTS idx_external_election_access_election ON public.external_election_access(election_id);
CREATE INDEX IF NOT EXISTS idx_external_election_access_user ON public.external_election_access(user_id);
CREATE INDEX IF NOT EXISTS idx_external_election_access_source ON public.external_election_access(access_source);

-- ============================================================
-- 8. FUNCTIONS
-- ============================================================

-- Generate unique election URL
CREATE OR REPLACE FUNCTION public.generate_election_url(p_election_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_url TEXT;
BEGIN
  v_url := 'https://vottery.com/election/' || p_election_id::TEXT;
  
  UPDATE public.elections
  SET unique_url = v_url,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = p_election_id;
  
  RETURN v_url;
END;
$$;

-- Check if participation fees are enabled for country
CREATE OR REPLACE FUNCTION public.is_participation_fee_enabled(p_country_code TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_control RECORD;
BEGIN
  SELECT * INTO v_control
  FROM public.platform_feature_controls
  WHERE feature_name = 'participation_fees';
  
  IF NOT FOUND OR NOT v_control.is_globally_enabled THEN
    RETURN false;
  END IF;
  
  -- Check if country is explicitly disabled
  IF p_country_code = ANY(v_control.disabled_countries) THEN
    RETURN false;
  END IF;
  
  -- If enabled_countries is empty, enabled for all (except disabled)
  IF array_length(v_control.enabled_countries, 1) IS NULL THEN
    RETURN true;
  END IF;
  
  -- Check if country is in enabled list
  RETURN p_country_code = ANY(v_control.enabled_countries);
END;
$$;

-- Record participation fee payment
CREATE OR REPLACE FUNCTION public.record_participation_fee_payment(
  p_election_id UUID,
  p_user_id UUID,
  p_amount NUMERIC,
  p_zone public.purchasing_power_zone,
  p_stripe_payment_intent_id TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_payment_id UUID;
BEGIN
  INSERT INTO public.participation_fee_payments (
    election_id,
    user_id,
    amount,
    purchasing_power_zone,
    payment_status,
    stripe_payment_intent_id,
    paid_at
  ) VALUES (
    p_election_id,
    p_user_id,
    p_amount,
    p_zone,
    'completed',
    p_stripe_payment_intent_id,
    CURRENT_TIMESTAMP
  )
  RETURNING id INTO v_payment_id;
  
  -- Update election total fee collected
  UPDATE public.elections
  SET total_fee_collected = total_fee_collected + p_amount,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = p_election_id;
  
  RETURN v_payment_id;
END;
$$;

-- Check if user has paid participation fee
CREATE OR REPLACE FUNCTION public.has_paid_participation_fee(
  p_election_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_payment RECORD;
  v_election RECORD;
BEGIN
  -- Get election fee type
  SELECT participation_fee_type INTO v_election
  FROM public.elections
  WHERE id = p_election_id;
  
  -- If free election, always return true
  IF v_election.participation_fee_type = 'free' THEN
    RETURN true;
  END IF;
  
  -- Check for completed payment
  SELECT * INTO v_payment
  FROM public.participation_fee_payments
  WHERE election_id = p_election_id
    AND user_id = p_user_id
    AND payment_status = 'completed';
  
  RETURN FOUND;
END;
$$;

-- Track external election access
CREATE OR REPLACE FUNCTION public.track_external_access(
  p_election_id UUID,
  p_user_id UUID,
  p_access_source TEXT,
  p_referrer_url TEXT DEFAULT NULL,
  p_ip_address TEXT DEFAULT NULL,
  p_country_code TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_access_id UUID;
BEGIN
  INSERT INTO public.external_election_access (
    election_id,
    user_id,
    access_source,
    referrer_url,
    ip_address,
    country_code
  ) VALUES (
    p_election_id,
    p_user_id,
    p_access_source,
    p_referrer_url,
    p_ip_address,
    p_country_code
  )
  RETURNING id INTO v_access_id;
  
  RETURN v_access_id;
END;
$$;

-- ============================================================
-- 9. RLS POLICIES
-- ============================================================

-- Enable RLS
ALTER TABLE public.participation_fee_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_regional_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_feature_controls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.external_election_access ENABLE ROW LEVEL SECURITY;

-- Participation fee payments policies
CREATE POLICY "Users can view own payments" ON public.participation_fee_payments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own payments" ON public.participation_fee_payments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Election regional fees policies
CREATE POLICY "Anyone can view regional fees" ON public.election_regional_fees
  FOR SELECT USING (true);

CREATE POLICY "Election creators can manage fees" ON public.election_regional_fees
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE id = election_regional_fees.election_id
      AND created_by = auth.uid()
    )
  );

-- Platform feature controls policies
CREATE POLICY "Anyone can view feature controls" ON public.platform_feature_controls
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage feature controls" ON public.platform_feature_controls
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- External election access policies
CREATE POLICY "Users can view own access records" ON public.external_election_access
  FOR SELECT USING (auth.uid() = user_id OR user_id IS NULL);

CREATE POLICY "Anyone can insert access records" ON public.external_election_access
  FOR INSERT WITH CHECK (true);

-- ============================================================
-- 10. TRIGGERS
-- ============================================================

-- Auto-generate election URL on creation
CREATE OR REPLACE FUNCTION public.auto_generate_election_url()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.unique_url IS NULL THEN
    NEW.unique_url := 'https://vottery.com/election/' || NEW.id::TEXT;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_auto_generate_election_url ON public.elections;
CREATE TRIGGER trigger_auto_generate_election_url
  BEFORE INSERT ON public.elections
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_generate_election_url();

-- Update timestamps
CREATE OR REPLACE FUNCTION public.update_participation_fee_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_participation_fee_payments_timestamp ON public.participation_fee_payments;
CREATE TRIGGER trigger_update_participation_fee_payments_timestamp
  BEFORE UPDATE ON public.participation_fee_payments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_participation_fee_timestamp();

DROP TRIGGER IF EXISTS trigger_update_election_regional_fees_timestamp ON public.election_regional_fees;
CREATE TRIGGER trigger_update_election_regional_fees_timestamp
  BEFORE UPDATE ON public.election_regional_fees
  FOR EACH ROW
  EXECUTE FUNCTION public.update_participation_fee_timestamp();

DROP TRIGGER IF EXISTS trigger_update_platform_feature_controls_timestamp ON public.platform_feature_controls;
CREATE TRIGGER trigger_update_platform_feature_controls_timestamp
  BEFORE UPDATE ON public.platform_feature_controls
  FOR EACH ROW
  EXECUTE FUNCTION public.update_participation_fee_timestamp();