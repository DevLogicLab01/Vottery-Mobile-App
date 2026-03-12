-- Phase A Batch 4: OTP Email Verification, Expanded Subscriptions, Country Biometric Controls
-- Migration: 20260226010000_phase_a_batch4_otp_subscription_biometric.sql

-- ============================================================================
-- 1. EMAIL OTP VERIFICATION SYSTEM
-- ============================================================================

-- Email OTP verifications table
CREATE TABLE IF NOT EXISTS public.email_otp_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ,
    attempts INT DEFAULT 0,
    ip_address TEXT,
    device_fingerprint TEXT,
    CONSTRAINT unique_pending_otp UNIQUE (election_id, user_id, email)
);

CREATE INDEX IF NOT EXISTS idx_email_otp_election_user ON public.email_otp_verifications(election_id, user_id);
CREATE INDEX IF NOT EXISTS idx_email_otp_expires ON public.email_otp_verifications(expires_at);
CREATE INDEX IF NOT EXISTS idx_email_otp_verified ON public.email_otp_verifications(verified_at);

-- Add require_email_otp column to elections
ALTER TABLE public.elections
ADD COLUMN IF NOT EXISTS require_email_otp BOOLEAN DEFAULT false;

-- ============================================================================
-- 2. EXPANDED SUBSCRIPTION FEATURES
-- ============================================================================

-- Subscription changes tracking
CREATE TABLE IF NOT EXISTS public.subscription_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    from_plan_id UUID REFERENCES public.subscription_plans(id),
    to_plan_id UUID NOT NULL REFERENCES public.subscription_plans(id),
    change_type TEXT NOT NULL CHECK (change_type IN ('upgrade', 'downgrade', 'new', 'cancel')),
    proration_credit DECIMAL(10, 2) DEFAULT 0,
    effective_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subscription_changes_user ON public.subscription_changes(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_changes_effective ON public.subscription_changes(effective_date);

-- Add pending_plan_change to user_subscriptions table (not subscriptions)
ALTER TABLE public.user_subscriptions
ADD COLUMN IF NOT EXISTS pending_plan_change UUID,
ADD COLUMN IF NOT EXISTS pending_change_date TIMESTAMPTZ;

-- ============================================================================
-- 3. COUNTRY BIOMETRIC CONTROLS
-- ============================================================================

-- Per-country biometric settings
CREATE TABLE IF NOT EXISTS public.per_country_biometric_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code TEXT NOT NULL UNIQUE,
    country_name TEXT NOT NULL,
    biometric_enabled BOOLEAN DEFAULT true,
    compliance_reason TEXT,
    is_gdpr_country BOOLEAN DEFAULT false,
    last_modified_by UUID REFERENCES public.user_profiles(id),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_biometric_settings_country ON public.per_country_biometric_settings(country_code);
CREATE INDEX IF NOT EXISTS idx_biometric_settings_gdpr ON public.per_country_biometric_settings(is_gdpr_country);
CREATE INDEX IF NOT EXISTS idx_biometric_settings_enabled ON public.per_country_biometric_settings(biometric_enabled);

-- Biometric compliance audit log
CREATE TABLE IF NOT EXISTS public.biometric_compliance_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code TEXT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('enabled', 'disabled', 'override_enabled', 'override_disabled')),
    previous_value BOOLEAN,
    new_value BOOLEAN NOT NULL,
    admin_id UUID REFERENCES public.user_profiles(id),
    justification TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_biometric_audit_country ON public.biometric_compliance_audit(country_code);
CREATE INDEX IF NOT EXISTS idx_biometric_audit_admin ON public.biometric_compliance_audit(admin_id);

-- ============================================================================
-- 4. FUNCTIONS
-- ============================================================================

-- Generate 6-digit OTP code
CREATE OR REPLACE FUNCTION public.generate_otp_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
END;
$$;

-- Create OTP verification
CREATE OR REPLACE FUNCTION public.create_otp_verification(
    p_election_id UUID,
    p_user_id UUID,
    p_email TEXT,
    p_ip_address TEXT DEFAULT NULL,
    p_device_fingerprint TEXT DEFAULT NULL
)
RETURNS TABLE(
    otp_code TEXT,
    expires_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_otp_code TEXT;
    v_expires_at TIMESTAMPTZ;
BEGIN
    -- Delete existing pending OTPs for this user/election
    DELETE FROM public.email_otp_verifications
    WHERE election_id = p_election_id
    AND user_id = p_user_id
    AND verified_at IS NULL;
    
    -- Generate new OTP
    v_otp_code := public.generate_otp_code();
    v_expires_at := CURRENT_TIMESTAMP + INTERVAL '10 minutes';
    
    -- Insert new OTP
    INSERT INTO public.email_otp_verifications (
        election_id, user_id, email, otp_code, expires_at, ip_address, device_fingerprint
    ) VALUES (
        p_election_id, p_user_id, p_email, v_otp_code, v_expires_at, p_ip_address, p_device_fingerprint
    );
    
    RETURN QUERY SELECT v_otp_code, v_expires_at;
END;
$$;

-- Verify OTP code
CREATE OR REPLACE FUNCTION public.verify_otp_code(
    p_election_id UUID,
    p_user_id UUID,
    p_otp_code TEXT
)
RETURNS TABLE(
    success BOOLEAN,
    message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_otp_record RECORD;
BEGIN
    -- Get OTP record
    SELECT * INTO v_otp_record
    FROM public.email_otp_verifications
    WHERE election_id = p_election_id
    AND user_id = p_user_id
    AND verified_at IS NULL
    ORDER BY created_at DESC
    LIMIT 1;
    
    -- Check if OTP exists
    IF v_otp_record IS NULL THEN
        RETURN QUERY SELECT false, 'No pending OTP verification found';
        RETURN;
    END IF;
    
    -- Check if expired
    IF v_otp_record.expires_at < CURRENT_TIMESTAMP THEN
        RETURN QUERY SELECT false, 'OTP code has expired';
        RETURN;
    END IF;
    
    -- Check attempts
    IF v_otp_record.attempts >= 3 THEN
        RETURN QUERY SELECT false, 'Maximum verification attempts exceeded';
        RETURN;
    END IF;
    
    -- Increment attempts
    UPDATE public.email_otp_verifications
    SET attempts = attempts + 1
    WHERE id = v_otp_record.id;
    
    -- Check code
    IF v_otp_record.otp_code = p_otp_code THEN
        UPDATE public.email_otp_verifications
        SET verified_at = CURRENT_TIMESTAMP
        WHERE id = v_otp_record.id;
        
        RETURN QUERY SELECT true, 'Email verified successfully';
    ELSE
        RETURN QUERY SELECT false, 'Invalid OTP code';
    END IF;
END;
$$;

-- Check if user has verified email for election
CREATE OR REPLACE FUNCTION public.has_verified_email_for_election(
    p_election_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.email_otp_verifications
        WHERE election_id = p_election_id
        AND user_id = p_user_id
        AND verified_at IS NOT NULL
    );
$$;

-- Calculate proration credit
CREATE OR REPLACE FUNCTION public.calculate_proration_credit(
    p_user_id UUID,
    p_new_plan_id UUID
)
RETURNS DECIMAL(10, 2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_plan_id UUID;
    v_end_date TIMESTAMPTZ;
    v_current_price NUMERIC;
    v_new_price NUMERIC;
    v_days_remaining INT;
    v_daily_rate NUMERIC;
    v_credit NUMERIC;
BEGIN
    -- Get current active subscription from user_subscriptions table
    SELECT us.plan_id, us.end_date
    INTO v_current_plan_id, v_end_date
    FROM public.user_subscriptions us
    WHERE us.user_id = p_user_id
    AND us.is_active = true
    ORDER BY us.created_at DESC
    LIMIT 1;
    
    -- Check if subscription exists
    IF NOT FOUND OR v_current_plan_id IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Get current plan price from existing subscription_plans table
    SELECT sp.price
    INTO v_current_price
    FROM public.subscription_plans sp
    WHERE sp.id = v_current_plan_id;
    
    IF v_current_price IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Get new plan price from existing subscription_plans table
    SELECT sp.price
    INTO v_new_price
    FROM public.subscription_plans sp
    WHERE sp.id = p_new_plan_id;
    
    IF v_new_price IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Calculate days remaining until end_date
    v_days_remaining := EXTRACT(DAY FROM (v_end_date - CURRENT_TIMESTAMP));
    
    -- If no days remaining or negative, return 0
    IF v_days_remaining <= 0 THEN
        RETURN 0;
    END IF;
    
    -- Calculate daily rate of current plan
    v_daily_rate := v_current_price / 30.0;
    
    -- Calculate credit
    v_credit := v_daily_rate * v_days_remaining;
    
    RETURN GREATEST(v_credit, 0);
END;
$$;

-- Get country biometric status
CREATE OR REPLACE FUNCTION public.get_country_biometric_status(
    p_country_code TEXT
)
RETURNS TABLE(
    enabled BOOLEAN,
    compliance_reason TEXT,
    is_gdpr BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT biometric_enabled, compliance_reason, is_gdpr_country
    FROM public.per_country_biometric_settings
    WHERE country_code = p_country_code
    LIMIT 1;
$$;

-- ============================================================================
-- 5. ENABLE RLS
-- ============================================================================

ALTER TABLE public.email_otp_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.per_country_biometric_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.biometric_compliance_audit ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. RLS POLICIES
-- ============================================================================

-- Email OTP Verifications
DROP POLICY IF EXISTS "users_manage_own_otp_verifications" ON public.email_otp_verifications;
CREATE POLICY "users_manage_own_otp_verifications"
ON public.email_otp_verifications
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Subscription Plans (public read)
DROP POLICY IF EXISTS "public_read_subscription_plans" ON public.subscription_plans;
CREATE POLICY "public_read_subscription_plans"
ON public.subscription_plans
FOR SELECT
TO public
USING (is_active = true);

-- Subscription Changes
DROP POLICY IF EXISTS "users_view_own_subscription_changes" ON public.subscription_changes;
CREATE POLICY "users_view_own_subscription_changes"
ON public.subscription_changes
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Country Biometric Settings (public read)
DROP POLICY IF EXISTS "public_read_biometric_settings" ON public.per_country_biometric_settings;
CREATE POLICY "public_read_biometric_settings"
ON public.per_country_biometric_settings
FOR SELECT
TO public
USING (true);

-- Biometric Compliance Audit (admin only)
DROP POLICY IF EXISTS "admin_view_biometric_audit" ON public.biometric_compliance_audit;
CREATE POLICY "admin_view_biometric_audit"
ON public.biometric_compliance_audit
FOR SELECT
TO authenticated
USING (true);

-- ============================================================================
-- 7. MOCK DATA
-- ============================================================================

DO $$
DECLARE
    v_existing_user_id UUID;
    v_existing_election_id UUID;
BEGIN
    -- Get existing user and election
    SELECT id INTO v_existing_user_id FROM public.user_profiles LIMIT 1;
    SELECT id INTO v_existing_election_id FROM public.elections LIMIT 1;
    
    -- Insert GDPR countries with biometric disabled
    INSERT INTO public.per_country_biometric_settings (country_code, country_name, biometric_enabled, compliance_reason, is_gdpr_country) VALUES
        ('AT', 'Austria', false, 'GDPR Article 9 - Special Category Data', true),
        ('BE', 'Belgium', false, 'GDPR Article 9 - Special Category Data', true),
        ('BG', 'Bulgaria', false, 'GDPR Article 9 - Special Category Data', true),
        ('HR', 'Croatia', false, 'GDPR Article 9 - Special Category Data', true),
        ('CY', 'Cyprus', false, 'GDPR Article 9 - Special Category Data', true),
        ('CZ', 'Czech Republic', false, 'GDPR Article 9 - Special Category Data', true),
        ('DK', 'Denmark', false, 'GDPR Article 9 - Special Category Data', true),
        ('EE', 'Estonia', false, 'GDPR Article 9 - Special Category Data', true),
        ('FI', 'Finland', false, 'GDPR Article 9 - Special Category Data', true),
        ('FR', 'France', false, 'GDPR Article 9 - Special Category Data', true),
        ('DE', 'Germany', false, 'GDPR Article 9 - Special Category Data', true),
        ('GR', 'Greece', false, 'GDPR Article 9 - Special Category Data', true),
        ('HU', 'Hungary', false, 'GDPR Article 9 - Special Category Data', true),
        ('IE', 'Ireland', false, 'GDPR Article 9 - Special Category Data', true),
        ('IT', 'Italy', false, 'GDPR Article 9 - Special Category Data', true),
        ('LV', 'Latvia', false, 'GDPR Article 9 - Special Category Data', true),
        ('LT', 'Lithuania', false, 'GDPR Article 9 - Special Category Data', true),
        ('LU', 'Luxembourg', false, 'GDPR Article 9 - Special Category Data', true),
        ('MT', 'Malta', false, 'GDPR Article 9 - Special Category Data', true),
        ('NL', 'Netherlands', false, 'GDPR Article 9 - Special Category Data', true),
        ('PL', 'Poland', false, 'GDPR Article 9 - Special Category Data', true),
        ('PT', 'Portugal', false, 'GDPR Article 9 - Special Category Data', true),
        ('RO', 'Romania', false, 'GDPR Article 9 - Special Category Data', true),
        ('SK', 'Slovakia', false, 'GDPR Article 9 - Special Category Data', true),
        ('SI', 'Slovenia', false, 'GDPR Article 9 - Special Category Data', true),
        ('ES', 'Spain', false, 'GDPR Article 9 - Special Category Data', true),
        ('SE', 'Sweden', false, 'GDPR Article 9 - Special Category Data', true),
        ('US', 'United States', true, NULL, false),
        ('CA', 'Canada', true, NULL, false),
        ('GB', 'United Kingdom', true, NULL, false),
        ('AU', 'Australia', true, NULL, false),
        ('JP', 'Japan', true, NULL, false),
        ('IN', 'India', true, NULL, false)
    ON CONFLICT (country_code) DO NOTHING;
    
    -- Sample OTP verification (if user and election exist)
    IF v_existing_user_id IS NOT NULL AND v_existing_election_id IS NOT NULL THEN
        INSERT INTO public.email_otp_verifications (election_id, user_id, email, otp_code, expires_at, verified_at)
        VALUES (
            v_existing_election_id,
            v_existing_user_id,
            'user@example.com',
            '123456',
            CURRENT_TIMESTAMP + INTERVAL '10 minutes',
            CURRENT_TIMESTAMP
        )
        ON CONFLICT (election_id, user_id, email) DO NOTHING;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;