-- Country Restrictions & Platform Integrations (Admin Panel)
-- Shared schema with Web; idempotent for dual-platform sync.

DO $$ BEGIN
  CREATE TYPE public.integration_type AS ENUM (
    'advertising',
    'payment',
    'communication',
    'ai_service'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.country_restrictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  country_code TEXT NOT NULL UNIQUE,
  country_name TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT true,
  biometric_allowed BOOLEAN DEFAULT true,
  fee_zone INTEGER CHECK (fee_zone >= 1 AND fee_zone <= 8),
  compliance_level TEXT DEFAULT 'moderate',
  data_residency TEXT,
  feature_overrides JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  last_modified_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS public.integration_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_name TEXT NOT NULL UNIQUE,
  integration_type TEXT NOT NULL,
  is_enabled BOOLEAN DEFAULT false,
  api_key_masked TEXT,
  weekly_budget_cap DECIMAL(12,2) DEFAULT 0.00,
  monthly_budget_cap DECIMAL(12,2) DEFAULT 0.00,
  current_weekly_usage DECIMAL(12,2) DEFAULT 0.00,
  current_monthly_usage DECIMAL(12,2) DEFAULT 0.00,
  rate_limit_per_minute INTEGER DEFAULT 60,
  config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  last_modified_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_country_restrictions_country_code ON public.country_restrictions(country_code);
CREATE INDEX IF NOT EXISTS idx_country_restrictions_is_enabled ON public.country_restrictions(is_enabled);
CREATE INDEX IF NOT EXISTS idx_integration_settings_integration_name ON public.integration_settings(integration_name);
CREATE INDEX IF NOT EXISTS idx_integration_settings_is_enabled ON public.integration_settings(is_enabled);

ALTER TABLE public.country_restrictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "country_restrictions_select_public" ON public.country_restrictions;
CREATE POLICY "country_restrictions_select_public" ON public.country_restrictions
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "country_restrictions_admin_all" ON public.country_restrictions;
CREATE POLICY "country_restrictions_admin_all" ON public.country_restrictions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role IN ('admin','manager'))
  );

DROP POLICY IF EXISTS "integration_settings_select_public" ON public.integration_settings;
CREATE POLICY "integration_settings_select_public" ON public.integration_settings
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "integration_settings_admin_all" ON public.integration_settings;
CREATE POLICY "integration_settings_admin_all" ON public.integration_settings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role IN ('admin','manager'))
  );

COMMENT ON TABLE public.country_restrictions IS 'Admin: restrict/derestrict countries; is_enabled = platform access.';
COMMENT ON TABLE public.integration_settings IS 'Admin: enable/disable integrations and set weekly/monthly budget caps.';
