-- =====================================================
-- Phase A Batch 3: Admin Control and Configuration Centers
-- Feature Flags, Country Restrictions, Integration Management
-- =====================================================

-- =====================================================
-- 1. ENUMS
-- =====================================================

DROP TYPE IF EXISTS public.feature_category CASCADE;
CREATE TYPE public.feature_category AS ENUM (
  'voting_methods',
  'gamification',
  'payments',
  'social',
  'analytics',
  'notifications',
  'authentication',
  'content_moderation',
  'admin_tools'
);

DROP TYPE IF EXISTS public.compliance_level CASCADE;
CREATE TYPE public.compliance_level AS ENUM (
  'strict',
  'moderate',
  'permissive'
);

DROP TYPE IF EXISTS public.integration_type CASCADE;
CREATE TYPE public.integration_type AS ENUM (
  'advertising',
  'payment',
  'communication',
  'ai_service'
);

-- =====================================================
-- 2. TABLES
-- =====================================================

-- Feature Flags Table
CREATE TABLE IF NOT EXISTS public.feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_name TEXT NOT NULL UNIQUE,
  is_enabled BOOLEAN DEFAULT false,
  category public.feature_category NOT NULL,
  description TEXT,
  dependencies TEXT[], -- Array of feature_name values this feature depends on
  usage_count INTEGER DEFAULT 0,
  rollout_percentage INTEGER DEFAULT 100 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  scheduled_enable_at TIMESTAMPTZ,
  scheduled_disable_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  last_modified_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL
);

-- Feature Usage Analytics Table
CREATE TABLE IF NOT EXISTS public.feature_usage_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_id UUID REFERENCES public.feature_flags(id) ON DELETE CASCADE,
  adoption_rate DECIMAL(5,2) DEFAULT 0.00,
  active_users INTEGER DEFAULT 0,
  total_interactions INTEGER DEFAULT 0,
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Country Restrictions Table
CREATE TABLE IF NOT EXISTS public.country_restrictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL UNIQUE, -- ISO 3166-1 alpha-2
  country_name TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT true,
  biometric_allowed BOOLEAN DEFAULT true,
  fee_zone INTEGER CHECK (fee_zone >= 1 AND fee_zone <= 8),
  compliance_level public.compliance_level DEFAULT 'moderate'::public.compliance_level,
  data_residency TEXT,
  feature_overrides JSONB DEFAULT '{}'::jsonb, -- Per-country feature flags
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  last_modified_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL
);

-- Country Access Logs Table
CREATE TABLE IF NOT EXISTS public.country_access_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  ip_address TEXT,
  access_granted BOOLEAN,
  vpn_detected BOOLEAN DEFAULT false,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Integration Settings Table
CREATE TABLE IF NOT EXISTS public.integration_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_name TEXT NOT NULL UNIQUE,
  integration_type public.integration_type NOT NULL,
  is_enabled BOOLEAN DEFAULT false,
  api_key_masked TEXT, -- Masked version for display
  weekly_budget_cap DECIMAL(10,2) DEFAULT 0.00,
  monthly_budget_cap DECIMAL(10,2) DEFAULT 0.00,
  current_weekly_usage DECIMAL(10,2) DEFAULT 0.00,
  current_monthly_usage DECIMAL(10,2) DEFAULT 0.00,
  rate_limit_per_minute INTEGER DEFAULT 60,
  rate_limit_per_hour INTEGER DEFAULT 3600,
  rate_limit_per_day INTEGER DEFAULT 86400,
  uptime_percentage DECIMAL(5,2) DEFAULT 100.00,
  last_error TEXT,
  last_error_at TIMESTAMPTZ,
  webhook_url TEXT,
  test_mode BOOLEAN DEFAULT true,
  config JSONB DEFAULT '{}'::jsonb, -- Integration-specific settings
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  last_modified_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL
);

-- Integration Usage Logs Table
CREATE TABLE IF NOT EXISTS public.integration_usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_id UUID REFERENCES public.integration_settings(id) ON DELETE CASCADE,
  api_calls_count INTEGER DEFAULT 1,
  cost DECIMAL(10,2) DEFAULT 0.00,
  response_time_ms INTEGER,
  status_code INTEGER,
  error_message TEXT,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Admin Audit Logs Table (Enhanced)
CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  target_type TEXT NOT NULL, -- 'feature_flag', 'country_restriction', 'integration_setting'
  target_id UUID,
  reason TEXT,
  old_value JSONB,
  new_value JSONB,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_feature_flags_category ON public.feature_flags(category);
CREATE INDEX IF NOT EXISTS idx_feature_flags_is_enabled ON public.feature_flags(is_enabled);
CREATE INDEX IF NOT EXISTS idx_feature_usage_analytics_feature_id ON public.feature_usage_analytics(feature_id);
CREATE INDEX IF NOT EXISTS idx_feature_usage_analytics_date ON public.feature_usage_analytics(date);
CREATE INDEX IF NOT EXISTS idx_country_restrictions_country_code ON public.country_restrictions(country_code);
CREATE INDEX IF NOT EXISTS idx_country_restrictions_is_enabled ON public.country_restrictions(is_enabled);
CREATE INDEX IF NOT EXISTS idx_country_access_logs_country_code ON public.country_access_logs(country_code);
CREATE INDEX IF NOT EXISTS idx_country_access_logs_timestamp ON public.country_access_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_integration_settings_integration_name ON public.integration_settings(integration_name);
CREATE INDEX IF NOT EXISTS idx_integration_settings_is_enabled ON public.integration_settings(is_enabled);
CREATE INDEX IF NOT EXISTS idx_integration_usage_logs_integration_id ON public.integration_usage_logs(integration_id);
CREATE INDEX IF NOT EXISTS idx_integration_usage_logs_timestamp ON public.integration_usage_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_admin_id ON public.admin_audit_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_logs_timestamp ON public.admin_audit_logs(timestamp);

-- =====================================================
-- 4. FUNCTIONS
-- =====================================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid()
    AND (au.raw_user_meta_data->>'role' = 'admin'
         OR au.raw_app_meta_data->>'role' = 'admin')
  )
$$;

-- Function to update feature flag timestamp
CREATE OR REPLACE FUNCTION public.update_feature_flag_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- Function to update country restriction timestamp
CREATE OR REPLACE FUNCTION public.update_country_restriction_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- Function to update integration setting timestamp
CREATE OR REPLACE FUNCTION public.update_integration_setting_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- Function to reset weekly usage (called by cron)
CREATE OR REPLACE FUNCTION public.reset_weekly_integration_usage()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.integration_settings
  SET current_weekly_usage = 0.00;
END;
$$;

-- Function to reset monthly usage (called by cron)
CREATE OR REPLACE FUNCTION public.reset_monthly_integration_usage()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.integration_settings
  SET current_monthly_usage = 0.00;
END;
$$;

-- =====================================================
-- 5. ENABLE RLS
-- =====================================================

ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_usage_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.country_restrictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.country_access_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 6. RLS POLICIES
-- =====================================================

-- Feature Flags Policies
DROP POLICY IF EXISTS "admin_full_access_feature_flags" ON public.feature_flags;
CREATE POLICY "admin_full_access_feature_flags"
ON public.feature_flags
FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "users_read_feature_flags" ON public.feature_flags;
CREATE POLICY "users_read_feature_flags"
ON public.feature_flags
FOR SELECT
TO authenticated
USING (true);

-- Feature Usage Analytics Policies
DROP POLICY IF EXISTS "admin_full_access_feature_usage_analytics" ON public.feature_usage_analytics;
CREATE POLICY "admin_full_access_feature_usage_analytics"
ON public.feature_usage_analytics
FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- Country Restrictions Policies
DROP POLICY IF EXISTS "admin_full_access_country_restrictions" ON public.country_restrictions;
CREATE POLICY "admin_full_access_country_restrictions"
ON public.country_restrictions
FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "users_read_country_restrictions" ON public.country_restrictions;
CREATE POLICY "users_read_country_restrictions"
ON public.country_restrictions
FOR SELECT
TO authenticated
USING (true);

-- Country Access Logs Policies
DROP POLICY IF EXISTS "admin_full_access_country_access_logs" ON public.country_access_logs;
CREATE POLICY "admin_full_access_country_access_logs"
ON public.country_access_logs
FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- Integration Settings Policies
DROP POLICY IF EXISTS "admin_full_access_integration_settings" ON public.integration_settings;
CREATE POLICY "admin_full_access_integration_settings"
ON public.integration_settings
FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- Integration Usage Logs Policies
DROP POLICY IF EXISTS "admin_full_access_integration_usage_logs" ON public.integration_usage_logs;
CREATE POLICY "admin_full_access_integration_usage_logs"
ON public.integration_usage_logs
FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- Admin Audit Logs Policies
DROP POLICY IF EXISTS "admin_read_audit_logs" ON public.admin_audit_logs;
CREATE POLICY "admin_read_audit_logs"
ON public.admin_audit_logs
FOR SELECT
TO authenticated
USING (public.is_admin_user());

DROP POLICY IF EXISTS "system_insert_audit_logs" ON public.admin_audit_logs;
CREATE POLICY "system_insert_audit_logs"
ON public.admin_audit_logs
FOR INSERT
TO authenticated
WITH CHECK (true);

-- =====================================================
-- 7. TRIGGERS
-- =====================================================

DROP TRIGGER IF EXISTS update_feature_flag_timestamp_trigger ON public.feature_flags;
CREATE TRIGGER update_feature_flag_timestamp_trigger
BEFORE UPDATE ON public.feature_flags
FOR EACH ROW
EXECUTE FUNCTION public.update_feature_flag_timestamp();

DROP TRIGGER IF EXISTS update_country_restriction_timestamp_trigger ON public.country_restrictions;
CREATE TRIGGER update_country_restriction_timestamp_trigger
BEFORE UPDATE ON public.country_restrictions
FOR EACH ROW
EXECUTE FUNCTION public.update_country_restriction_timestamp();

DROP TRIGGER IF EXISTS update_integration_setting_timestamp_trigger ON public.integration_settings;
CREATE TRIGGER update_integration_setting_timestamp_trigger
BEFORE UPDATE ON public.integration_settings
FOR EACH ROW
EXECUTE FUNCTION public.update_integration_setting_timestamp();

-- =====================================================
-- 8. MOCK DATA
-- =====================================================

DO $$
DECLARE
  admin_user_id UUID;
  plurality_voting_id UUID := gen_random_uuid();
  ranked_choice_id UUID := gen_random_uuid();
  lottery_system_id UUID := gen_random_uuid();
  stripe_payments_id UUID := gen_random_uuid();
  comments_system_id UUID := gen_random_uuid();
  push_notifications_id UUID := gen_random_uuid();
  biometric_voting_id UUID := gen_random_uuid();
  passkey_auth_id UUID := gen_random_uuid();
  
  stripe_integration_id UUID := gen_random_uuid();
  adsense_integration_id UUID := gen_random_uuid();
  resend_integration_id UUID := gen_random_uuid();
  twilio_integration_id UUID := gen_random_uuid();
  openai_integration_id UUID := gen_random_uuid();
  anthropic_integration_id UUID := gen_random_uuid();
  perplexity_integration_id UUID := gen_random_uuid();
  gemini_integration_id UUID := gen_random_uuid();
BEGIN
  -- Get admin user
  SELECT id INTO admin_user_id FROM public.user_profiles WHERE email = 'admin@example.com' LIMIT 1;
  
  IF admin_user_id IS NULL THEN
    RAISE NOTICE 'Admin user not found. Skipping mock data creation.';
    RETURN;
  END IF;
  
  -- Insert Feature Flags
  INSERT INTO public.feature_flags (id, feature_name, is_enabled, category, description, dependencies, usage_count, rollout_percentage, last_modified_by)
  VALUES
    (plurality_voting_id, 'plurality_voting', true, 'voting_methods'::public.feature_category, 'Standard one-person-one-vote system', ARRAY[]::TEXT[], 1247, 100, admin_user_id),
    (ranked_choice_id, 'ranked_choice_voting', true, 'voting_methods'::public.feature_category, 'Voters rank candidates by preference', ARRAY[]::TEXT[], 856, 100, admin_user_id),
    (gen_random_uuid(), 'approval_voting', false, 'voting_methods'::public.feature_category, 'Voters approve multiple candidates', ARRAY[]::TEXT[], 0, 0, admin_user_id),
    (lottery_system_id, 'lottery_system', true, 'gamification'::public.feature_category, 'Random winner selection from participants', ARRAY[]::TEXT[], 542, 100, admin_user_id),
    (gen_random_uuid(), 'slot_machine_3d', true, 'gamification'::public.feature_category, '3D slot machine animation for lottery draws', ARRAY['lottery_system']::TEXT[], 542, 100, admin_user_id),
    (gen_random_uuid(), 'participation_fees', true, 'payments'::public.feature_category, 'Entry fees for elections', ARRAY[]::TEXT[], 324, 100, admin_user_id),
    (stripe_payments_id, 'stripe_payments', true, 'payments'::public.feature_category, 'Stripe payment processing', ARRAY['participation_fees']::TEXT[], 324, 100, admin_user_id),
    (comments_system_id, 'comments_system', true, 'social'::public.feature_category, 'Election comments and discussions', ARRAY[]::TEXT[], 1089, 100, admin_user_id),
    (gen_random_uuid(), 'reactions', true, 'social'::public.feature_category, 'Emoji reactions on elections', ARRAY[]::TEXT[], 1156, 100, admin_user_id),
    (gen_random_uuid(), 'direct_messaging', true, 'social'::public.feature_category, 'User-to-user messaging', ARRAY[]::TEXT[], 678, 100, admin_user_id),
    (push_notifications_id, 'push_notifications', true, 'notifications'::public.feature_category, 'Mobile push notifications', ARRAY[]::TEXT[], 1432, 100, admin_user_id),
    (gen_random_uuid(), 'email_notifications', true, 'notifications'::public.feature_category, 'Email alerts for events', ARRAY[]::TEXT[], 1247, 100, admin_user_id),
    (gen_random_uuid(), 'sms_alerts', false, 'notifications'::public.feature_category, 'SMS emergency alerts', ARRAY[]::TEXT[], 0, 0, admin_user_id),
    (biometric_voting_id, 'biometric_voting', true, 'authentication'::public.feature_category, 'Fingerprint/Face ID verification', ARRAY[]::TEXT[], 892, 100, admin_user_id),
    (passkey_auth_id, 'passkey_auth', true, 'authentication'::public.feature_category, 'Passwordless authentication', ARRAY[]::TEXT[], 456, 75, admin_user_id),
    (gen_random_uuid(), 'mcq_system', true, 'content_moderation'::public.feature_category, 'Multiple choice questions before voting', ARRAY[]::TEXT[], 234, 100, admin_user_id),
    (gen_random_uuid(), 'video_watch_enforcement', true, 'content_moderation'::public.feature_category, 'Require watching election videos', ARRAY[]::TEXT[], 189, 100, admin_user_id),
    (gen_random_uuid(), 'offline_mode', true, 'admin_tools'::public.feature_category, 'Offline voting with sync', ARRAY[]::TEXT[], 123, 100, admin_user_id),
    (gen_random_uuid(), 'font_scaling', true, 'admin_tools'::public.feature_category, 'Accessibility font size controls', ARRAY[]::TEXT[], 567, 100, admin_user_id),
    (gen_random_uuid(), 'suggested_elections', true, 'analytics'::public.feature_category, 'AI-powered election recommendations', ARRAY[]::TEXT[], 1034, 100, admin_user_id),
    (gen_random_uuid(), 'anonymous_voting', true, 'authentication'::public.feature_category, 'Cryptographic voter anonymity', ARRAY[]::TEXT[], 678, 100, admin_user_id),
    (gen_random_uuid(), 'vote_changes', false, 'admin_tools'::public.feature_category, 'Allow voters to change their votes', ARRAY[]::TEXT[], 0, 0, admin_user_id)
  ON CONFLICT (id) DO NOTHING;
  
  -- Insert Feature Usage Analytics
  INSERT INTO public.feature_usage_analytics (feature_id, adoption_rate, active_users, total_interactions, date)
  VALUES
    (plurality_voting_id, 98.50, 1247, 5678, CURRENT_DATE),
    (ranked_choice_id, 67.30, 856, 3421, CURRENT_DATE),
    (lottery_system_id, 42.80, 542, 2156, CURRENT_DATE),
    (stripe_payments_id, 25.60, 324, 1298, CURRENT_DATE),
    (comments_system_id, 85.90, 1089, 8765, CURRENT_DATE),
    (push_notifications_id, 95.20, 1432, 12456, CURRENT_DATE),
    (biometric_voting_id, 70.40, 892, 4567, CURRENT_DATE),
    (passkey_auth_id, 36.00, 456, 1823, CURRENT_DATE)
  ON CONFLICT (id) DO NOTHING;
  
  -- Insert Country Restrictions (Sample countries)
  INSERT INTO public.country_restrictions (country_code, country_name, is_enabled, biometric_allowed, fee_zone, compliance_level, data_residency, last_modified_by)
  VALUES
    ('US', 'United States', true, true, 1, 'moderate'::public.compliance_level, 'us-east-1', admin_user_id),
    ('GB', 'United Kingdom', true, true, 2, 'strict'::public.compliance_level, 'eu-west-2', admin_user_id),
    ('DE', 'Germany', true, false, 2, 'strict'::public.compliance_level, 'eu-central-1', admin_user_id),
    ('FR', 'France', true, false, 2, 'strict'::public.compliance_level, 'eu-west-3', admin_user_id),
    ('CA', 'Canada', true, true, 1, 'moderate'::public.compliance_level, 'ca-central-1', admin_user_id),
    ('AU', 'Australia', true, true, 3, 'moderate'::public.compliance_level, 'ap-southeast-2', admin_user_id),
    ('JP', 'Japan', true, true, 4, 'moderate'::public.compliance_level, 'ap-northeast-1', admin_user_id),
    ('IN', 'India', true, true, 6, 'permissive'::public.compliance_level, 'ap-south-1', admin_user_id),
    ('BR', 'Brazil', true, true, 5, 'moderate'::public.compliance_level, 'sa-east-1', admin_user_id),
    ('ZA', 'South Africa', true, true, 7, 'permissive'::public.compliance_level, 'af-south-1', admin_user_id),
    ('CN', 'China', false, false, 8, 'strict'::public.compliance_level, null, admin_user_id),
    ('RU', 'Russia', false, false, 8, 'strict'::public.compliance_level, null, admin_user_id),
    ('KP', 'North Korea', false, false, 8, 'strict'::public.compliance_level, null, admin_user_id)
  ON CONFLICT (country_code) DO NOTHING;
  
  -- Insert Integration Settings
  INSERT INTO public.integration_settings (id, integration_name, integration_type, is_enabled, api_key_masked, weekly_budget_cap, monthly_budget_cap, current_weekly_usage, current_monthly_usage, rate_limit_per_minute, uptime_percentage, webhook_url, test_mode, config, last_modified_by)
  VALUES
    (stripe_integration_id, 'Stripe', 'payment'::public.integration_type, true, 'sk_live_••••••••••••1234', 500.00, 2000.00, 127.45, 856.32, 100, 99.87, 'https://api.example.com/webhooks/stripe', false, jsonb_build_object('currency', 'USD', 'auto_capture', true), admin_user_id),
    (adsense_integration_id, 'Google AdSense', 'advertising'::public.integration_type, true, 'ca-pub-••••••••••••5678', 300.00, 1200.00, 89.23, 567.89, 60, 99.95, null, false, jsonb_build_object('ad_format', 'responsive', 'auto_ads', true), admin_user_id),
    (resend_integration_id, 'Resend', 'communication'::public.integration_type, true, 're_••••••••••••9012', 100.00, 400.00, 34.56, 189.45, 120, 99.92, null, false, jsonb_build_object('from_email', 'noreply@vottery.com', 'domain_verified', true), admin_user_id),
    (twilio_integration_id, 'Twilio', 'communication'::public.integration_type, false, 'AC••••••••••••3456', 200.00, 800.00, 0.00, 0.00, 60, 100.00, 'https://api.example.com/webhooks/twilio', true, jsonb_build_object('phone_number', '+1234567890', 'sms_enabled', true), admin_user_id),
    (openai_integration_id, 'OpenAI', 'ai_service'::public.integration_type, true, 'sk-••••••••••••7890', 150.00, 600.00, 67.89, 345.67, 60, 99.78, null, false, jsonb_build_object('model', 'gpt-4', 'max_tokens', 2000), admin_user_id),
    (anthropic_integration_id, 'Anthropic', 'ai_service'::public.integration_type, true, 'sk-ant-••••••••••••1234', 150.00, 600.00, 45.23, 234.56, 60, 99.85, null, false, jsonb_build_object('model', 'claude-3-opus', 'max_tokens', 4000), admin_user_id),
    (perplexity_integration_id, 'Perplexity', 'ai_service'::public.integration_type, true, 'pplx-••••••••••••5678', 100.00, 400.00, 23.45, 123.45, 60, 99.90, null, false, jsonb_build_object('model', 'sonar-medium', 'search_enabled', true), admin_user_id),
    (gemini_integration_id, 'Gemini', 'ai_service'::public.integration_type, true, 'AIza••••••••••••9012', 120.00, 480.00, 34.67, 178.90, 60, 99.82, null, false, jsonb_build_object('model', 'gemini-pro', 'safety_settings', 'medium'), admin_user_id)
  ON CONFLICT (integration_name) DO NOTHING;
  
  -- Insert Integration Usage Logs (Last 7 days sample)
  INSERT INTO public.integration_usage_logs (integration_id, api_calls_count, cost, response_time_ms, status_code, timestamp)
  VALUES
    (stripe_integration_id, 45, 12.34, 234, 200, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (stripe_integration_id, 52, 14.56, 198, 200, CURRENT_TIMESTAMP - INTERVAL '2 days'),
    (adsense_integration_id, 1234, 23.45, 145, 200, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (adsense_integration_id, 1456, 28.90, 167, 200, CURRENT_TIMESTAMP - INTERVAL '2 days'),
    (resend_integration_id, 234, 8.90, 89, 200, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (resend_integration_id, 189, 7.12, 92, 200, CURRENT_TIMESTAMP - INTERVAL '2 days'),
    (openai_integration_id, 156, 23.45, 1234, 200, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (openai_integration_id, 178, 26.78, 1456, 200, CURRENT_TIMESTAMP - INTERVAL '2 days'),
    (anthropic_integration_id, 123, 18.90, 987, 200, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (anthropic_integration_id, 145, 21.34, 1098, 200, CURRENT_TIMESTAMP - INTERVAL '2 days'),
    (perplexity_integration_id, 89, 6.78, 567, 200, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (perplexity_integration_id, 98, 7.45, 623, 200, CURRENT_TIMESTAMP - INTERVAL '2 days'),
    (gemini_integration_id, 112, 11.23, 789, 200, CURRENT_TIMESTAMP - INTERVAL '1 day'),
    (gemini_integration_id, 134, 13.45, 834, 200, CURRENT_TIMESTAMP - INTERVAL '2 days')
  ON CONFLICT (id) DO NOTHING;
  
  RAISE NOTICE 'Mock data created successfully for Phase A Batch 3';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data creation failed: %', SQLERRM;
END $$;