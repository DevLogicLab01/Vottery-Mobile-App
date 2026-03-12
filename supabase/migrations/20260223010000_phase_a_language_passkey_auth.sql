-- Phase A: Multi-Language Support & Passkey Authentication
-- Migration: 20260223010000_phase_a_language_passkey_auth.sql

-- ============================================================================
-- USER LANGUAGE PREFERENCES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_language_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    language_code TEXT NOT NULL, -- ISO 639-1 code (e.g., 'en', 'es', 'ar')
    auto_detect BOOLEAN DEFAULT true,
    rtl_enabled BOOLEAN DEFAULT false,
    date_format TEXT DEFAULT 'MM/DD/YYYY',
    time_format TEXT DEFAULT '12h',
    number_format TEXT DEFAULT 'comma', -- 'comma' or 'period' for decimal separator
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id)
);

CREATE INDEX idx_user_language_preferences_user_id ON public.user_language_preferences(user_id);
CREATE INDEX idx_user_language_preferences_language_code ON public.user_language_preferences(language_code);

COMMENT ON TABLE public.user_language_preferences IS 'Stores user language preferences for multi-language support across 80+ languages';

-- ============================================================================
-- PASSKEY DEVICES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.passkey_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    credential_id TEXT NOT NULL UNIQUE,
    public_key TEXT NOT NULL,
    device_name TEXT NOT NULL,
    device_type TEXT NOT NULL, -- 'mobile', 'desktop', 'security_key'
    authenticator_type TEXT NOT NULL, -- 'platform', 'cross_platform'
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    revoked_at TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_passkey_devices_user_id ON public.passkey_devices(user_id);
CREATE INDEX idx_passkey_devices_credential_id ON public.passkey_devices(credential_id);
CREATE INDEX idx_passkey_devices_active ON public.passkey_devices(user_id, is_active) WHERE is_active = true;

COMMENT ON TABLE public.passkey_devices IS 'Stores registered passkey devices for WebAuthn authentication';

-- ============================================================================
-- ELECTION AUTHENTICATION METHODS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.election_auth_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    auth_method TEXT NOT NULL, -- 'email_password', 'magic_link', 'oauth_google', 'oauth_facebook', 'oauth_apple', 'passkey', 'biometric'
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(election_id, auth_method)
);

CREATE INDEX idx_election_auth_methods_election_id ON public.election_auth_methods(election_id);
CREATE INDEX idx_election_auth_methods_enabled ON public.election_auth_methods(election_id, enabled) WHERE enabled = true;

COMMENT ON TABLE public.election_auth_methods IS 'Defines allowed authentication methods per election (creator-configurable)';

-- ============================================================================
-- AUTHENTICATION AUDIT LOG TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.authentication_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    election_id UUID REFERENCES public.elections(id) ON DELETE SET NULL,
    auth_method TEXT NOT NULL,
    success BOOLEAN NOT NULL,
    ip_address TEXT,
    user_agent TEXT,
    device_fingerprint TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_authentication_audit_log_user_id ON public.authentication_audit_log(user_id);
CREATE INDEX idx_authentication_audit_log_election_id ON public.authentication_audit_log(election_id);
CREATE INDEX idx_authentication_audit_log_created_at ON public.authentication_audit_log(created_at DESC);

COMMENT ON TABLE public.authentication_audit_log IS 'Tracks authentication attempts and methods used for security auditing';

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- User Language Preferences Policies
ALTER TABLE public.user_language_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own language preferences"
    ON public.user_language_preferences FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own language preferences"
    ON public.user_language_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own language preferences"
    ON public.user_language_preferences FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Passkey Devices Policies
ALTER TABLE public.passkey_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own passkey devices"
    ON public.passkey_devices FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own passkey devices"
    ON public.passkey_devices FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own passkey devices"
    ON public.passkey_devices FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Election Auth Methods Policies
ALTER TABLE public.election_auth_methods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view election auth methods"
    ON public.election_auth_methods FOR SELECT
    USING (true);

CREATE POLICY "Election creators can manage auth methods"
    ON public.election_auth_methods FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.elections
            WHERE elections.id = election_auth_methods.election_id
            AND elections.created_by = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.elections
            WHERE elections.id = election_auth_methods.election_id
            AND elections.created_by = auth.uid()
        )
    );

-- Authentication Audit Log Policies
ALTER TABLE public.authentication_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own auth audit logs"
    ON public.authentication_audit_log FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "System can insert auth audit logs"
    ON public.authentication_audit_log FOR INSERT
    WITH CHECK (true);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_language_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_language_preferences_updated_at
    BEFORE UPDATE ON public.user_language_preferences
    FOR EACH ROW
    EXECUTE FUNCTION public.update_language_preferences_updated_at();

-- Function to update passkey last_used_at
CREATE OR REPLACE FUNCTION public.update_passkey_last_used(p_credential_id TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE public.passkey_devices
    SET last_used_at = now()
    WHERE credential_id = p_credential_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MOCK DATA (Development Only)
-- ============================================================================

DO $$
DECLARE
    v_test_user_id UUID;
    v_test_election_id UUID;
BEGIN
    -- Get first test user
    SELECT id INTO v_test_user_id FROM auth.users LIMIT 1;
    
    -- Get first test election
    SELECT id INTO v_test_election_id FROM public.elections LIMIT 1;
    
    IF v_test_user_id IS NOT NULL THEN
        -- Insert language preference if not exists
        INSERT INTO public.user_language_preferences (user_id, language_code, auto_detect, rtl_enabled)
        VALUES (v_test_user_id, 'en', true, false)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    
    IF v_test_election_id IS NOT NULL THEN
        -- Insert default auth methods for test election
        INSERT INTO public.election_auth_methods (election_id, auth_method, enabled)
        VALUES 
            (v_test_election_id, 'email_password', true),
            (v_test_election_id, 'magic_link', true),
            (v_test_election_id, 'oauth_google', true),
            (v_test_election_id, 'passkey', false)
        ON CONFLICT (election_id, auth_method) DO NOTHING;
    END IF;
END $$;