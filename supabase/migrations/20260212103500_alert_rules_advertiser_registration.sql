-- Alert Rules and Advertiser Registration Migration
-- Supports: Automated Threshold-Based Alerting Hub + Brand Advertiser Registration Portal

-- ============================================================================
-- TYPES
-- ============================================================================

DROP TYPE IF EXISTS public.alert_rule_status CASCADE;
CREATE TYPE public.alert_rule_status AS ENUM ('active', 'paused', 'archived');

DROP TYPE IF EXISTS public.alert_severity CASCADE;
CREATE TYPE public.alert_severity AS ENUM ('low', 'medium', 'high', 'critical');

DROP TYPE IF EXISTS public.alert_channel CASCADE;
CREATE TYPE public.alert_channel AS ENUM ('sms', 'email', 'push', 'all');

DROP TYPE IF EXISTS public.logic_operator CASCADE;
CREATE TYPE public.logic_operator AS ENUM ('AND', 'OR', 'NOT');

DROP TYPE IF EXISTS public.comparison_operator CASCADE;
CREATE TYPE public.comparison_operator AS ENUM ('greater_than', 'less_than', 'equals', 'not_equals', 'between');

DROP TYPE IF EXISTS public.advertiser_status CASCADE;
CREATE TYPE public.advertiser_status AS ENUM ('pending', 'under_review', 'approved', 'rejected', 'suspended');

DROP TYPE IF EXISTS public.kyc_status CASCADE;
CREATE TYPE public.kyc_status AS ENUM ('not_started', 'in_progress', 'pending_review', 'approved', 'rejected');

DROP TYPE IF EXISTS public.document_type CASCADE;
CREATE TYPE public.document_type AS ENUM ('business_registration', 'tax_id', 'identity_proof', 'address_proof', 'bank_statement', 'other');

DROP TYPE IF EXISTS public.verification_status CASCADE;
CREATE TYPE public.verification_status AS ENUM ('pending', 'verified', 'failed', 'expired');

-- ============================================================================
-- ALERT RULES TABLES
-- ============================================================================

DROP TABLE IF EXISTS public.alert_history CASCADE;
DROP TABLE IF EXISTS public.active_alerts CASCADE;
DROP TABLE IF EXISTS public.alert_rule_conditions CASCADE;
DROP TABLE IF EXISTS public.alert_rules CASCADE;

CREATE TABLE public.alert_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    rule_name TEXT NOT NULL,
    description TEXT,
    metric_type TEXT NOT NULL,
    threshold_value DECIMAL NOT NULL,
    comparison_operator public.comparison_operator NOT NULL DEFAULT 'greater_than',
    severity public.alert_severity NOT NULL DEFAULT 'medium',
    notification_channels public.alert_channel[] NOT NULL DEFAULT ARRAY['email']::public.alert_channel[],
    status public.alert_rule_status NOT NULL DEFAULT 'active',
    cooldown_minutes INTEGER DEFAULT 60,
    is_system_rule BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.alert_rule_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES public.alert_rules(id) ON DELETE CASCADE,
    condition_group INTEGER DEFAULT 1,
    logic_operator public.logic_operator NOT NULL DEFAULT 'AND',
    metric_name TEXT NOT NULL,
    comparison_operator public.comparison_operator NOT NULL,
    threshold_value DECIMAL NOT NULL,
    time_window_minutes INTEGER DEFAULT 5,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.active_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES public.alert_rules(id) ON DELETE CASCADE,
    triggered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    severity public.alert_severity NOT NULL,
    metric_type TEXT NOT NULL,
    current_value DECIMAL NOT NULL,
    threshold_value DECIMAL NOT NULL,
    message TEXT NOT NULL,
    is_acknowledged BOOLEAN DEFAULT false,
    acknowledged_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    acknowledged_at TIMESTAMPTZ,
    is_resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE TABLE public.alert_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES public.alert_rules(id) ON DELETE CASCADE,
    triggered_at TIMESTAMPTZ NOT NULL,
    resolved_at TIMESTAMPTZ,
    severity public.alert_severity NOT NULL,
    metric_type TEXT NOT NULL,
    metric_value DECIMAL NOT NULL,
    threshold_value DECIMAL NOT NULL,
    notification_sent BOOLEAN DEFAULT false,
    notification_channels TEXT[],
    metadata JSONB DEFAULT '{}'::jsonb
);

-- ============================================================================
-- ADVERTISER REGISTRATION TABLES
-- ============================================================================

DROP TABLE IF EXISTS public.advertiser_billing_info CASCADE;
DROP TABLE IF EXISTS public.compliance_screenings CASCADE;
DROP TABLE IF EXISTS public.beneficial_owners CASCADE;
DROP TABLE IF EXISTS public.advertiser_documents CASCADE;
DROP TABLE IF EXISTS public.advertiser_registrations CASCADE;

CREATE TABLE public.advertiser_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    company_name TEXT NOT NULL,
    company_email TEXT NOT NULL,
    company_phone TEXT,
    company_website TEXT,
    business_address TEXT,
    city TEXT,
    state TEXT,
    country TEXT NOT NULL,
    postal_code TEXT,
    tax_id TEXT,
    business_registration_number TEXT,
    industry_classification TEXT,
    company_description TEXT,
    registration_status public.advertiser_status NOT NULL DEFAULT 'pending',
    kyc_status public.kyc_status NOT NULL DEFAULT 'not_started',
    current_step INTEGER DEFAULT 1,
    submitted_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    rejection_reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.advertiser_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    registration_id UUID REFERENCES public.advertiser_registrations(id) ON DELETE CASCADE,
    document_type public.document_type NOT NULL,
    document_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size_bytes BIGINT,
    mime_type TEXT,
    verification_status public.verification_status NOT NULL DEFAULT 'pending',
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    rejection_reason TEXT,
    expiry_date DATE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.beneficial_owners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    registration_id UUID REFERENCES public.advertiser_registrations(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    date_of_birth DATE,
    nationality TEXT,
    ownership_percentage DECIMAL(5,2) NOT NULL,
    id_document_type TEXT,
    id_document_number TEXT,
    address TEXT,
    is_politically_exposed BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.compliance_screenings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    registration_id UUID REFERENCES public.advertiser_registrations(id) ON DELETE CASCADE,
    screening_type TEXT NOT NULL,
    screening_provider TEXT,
    screening_result TEXT,
    risk_score DECIMAL(5,2),
    passed BOOLEAN DEFAULT false,
    screening_data JSONB DEFAULT '{}'::jsonb,
    screened_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE public.advertiser_billing_info (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    registration_id UUID REFERENCES public.advertiser_registrations(id) ON DELETE CASCADE,
    billing_contact_name TEXT NOT NULL,
    billing_email TEXT NOT NULL,
    billing_phone TEXT,
    billing_address TEXT,
    billing_city TEXT,
    billing_state TEXT,
    billing_country TEXT NOT NULL,
    billing_postal_code TEXT,
    payment_method TEXT,
    bank_name TEXT,
    account_holder_name TEXT,
    account_number_last4 TEXT,
    routing_number TEXT,
    swift_code TEXT,
    iban TEXT,
    stripe_customer_id TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_alert_rules_created_by ON public.alert_rules(created_by);
CREATE INDEX IF NOT EXISTS idx_alert_rules_status ON public.alert_rules(status);
CREATE INDEX IF NOT EXISTS idx_alert_rules_metric_type ON public.alert_rules(metric_type);
CREATE INDEX IF NOT EXISTS idx_alert_rule_conditions_rule_id ON public.alert_rule_conditions(rule_id);

CREATE INDEX IF NOT EXISTS idx_active_alerts_rule_id ON public.active_alerts(rule_id);
CREATE INDEX IF NOT EXISTS idx_active_alerts_severity ON public.active_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_active_alerts_is_resolved ON public.active_alerts(is_resolved);
CREATE INDEX IF NOT EXISTS idx_alert_history_rule_id ON public.alert_history(rule_id);
CREATE INDEX IF NOT EXISTS idx_alert_history_triggered_at ON public.alert_history(triggered_at);

CREATE INDEX IF NOT EXISTS idx_advertiser_registrations_user_id ON public.advertiser_registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_advertiser_registrations_status ON public.advertiser_registrations(registration_status);
CREATE INDEX IF NOT EXISTS idx_advertiser_registrations_kyc_status ON public.advertiser_registrations(kyc_status);
CREATE INDEX IF NOT EXISTS idx_advertiser_documents_registration_id ON public.advertiser_documents(registration_id);
CREATE INDEX IF NOT EXISTS idx_advertiser_documents_verification_status ON public.advertiser_documents(verification_status);
CREATE INDEX IF NOT EXISTS idx_beneficial_owners_registration_id ON public.beneficial_owners(registration_id);
CREATE INDEX IF NOT EXISTS idx_compliance_screenings_registration_id ON public.compliance_screenings(registration_id);
CREATE INDEX IF NOT EXISTS idx_advertiser_billing_info_registration_id ON public.advertiser_billing_info(registration_id);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- ============================================================================
-- ENABLE RLS
-- ============================================================================

ALTER TABLE public.alert_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_rule_conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.active_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advertiser_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advertiser_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.beneficial_owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compliance_screenings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advertiser_billing_info ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Alert Rules Policies
DROP POLICY IF EXISTS "users_manage_own_alert_rules" ON public.alert_rules;
CREATE POLICY "users_manage_own_alert_rules" ON public.alert_rules
FOR ALL TO authenticated
USING (created_by = auth.uid() OR is_system_rule = true);

DROP POLICY IF EXISTS "admins_manage_all_alert_rules" ON public.alert_rules;
CREATE POLICY "admins_manage_all_alert_rules" ON public.alert_rules
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Alert Rule Conditions Policies
DROP POLICY IF EXISTS "users_view_rule_conditions" ON public.alert_rule_conditions;
CREATE POLICY "users_view_rule_conditions" ON public.alert_rule_conditions
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.alert_rules
        WHERE id = alert_rule_conditions.rule_id
        AND (created_by = auth.uid() OR is_system_rule = true)
    )
);

-- Active Alerts Policies
DROP POLICY IF EXISTS "users_view_relevant_alerts" ON public.active_alerts;
CREATE POLICY "users_view_relevant_alerts" ON public.active_alerts
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.alert_rules
        WHERE id = active_alerts.rule_id
        AND (created_by = auth.uid() OR is_system_rule = true)
    )
);

DROP POLICY IF EXISTS "admins_manage_all_alerts" ON public.active_alerts;
CREATE POLICY "admins_manage_all_alerts" ON public.active_alerts
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Alert History Policies
DROP POLICY IF EXISTS "users_view_alert_history" ON public.alert_history;
CREATE POLICY "users_view_alert_history" ON public.alert_history
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.alert_rules
        WHERE id = alert_history.rule_id
        AND (created_by = auth.uid() OR is_system_rule = true)
    )
);

-- Advertiser Registration Policies
DROP POLICY IF EXISTS "users_manage_own_registrations" ON public.advertiser_registrations;
CREATE POLICY "users_manage_own_registrations" ON public.advertiser_registrations
FOR ALL TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "admins_manage_all_registrations" ON public.advertiser_registrations;
CREATE POLICY "admins_manage_all_registrations" ON public.advertiser_registrations
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Advertiser Documents Policies
DROP POLICY IF EXISTS "users_manage_own_documents" ON public.advertiser_documents;
CREATE POLICY "users_manage_own_documents" ON public.advertiser_documents
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.advertiser_registrations
        WHERE id = advertiser_documents.registration_id
        AND user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "admins_manage_all_documents" ON public.advertiser_documents;
CREATE POLICY "admins_manage_all_documents" ON public.advertiser_documents
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Beneficial Owners Policies
DROP POLICY IF EXISTS "users_manage_own_beneficial_owners" ON public.beneficial_owners;
CREATE POLICY "users_manage_own_beneficial_owners" ON public.beneficial_owners
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.advertiser_registrations
        WHERE id = beneficial_owners.registration_id
        AND user_id = auth.uid()
    )
);

-- Compliance Screenings Policies
DROP POLICY IF EXISTS "users_view_own_screenings" ON public.compliance_screenings;
CREATE POLICY "users_view_own_screenings" ON public.compliance_screenings
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.advertiser_registrations
        WHERE id = compliance_screenings.registration_id
        AND user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "admins_manage_all_screenings" ON public.compliance_screenings;
CREATE POLICY "admins_manage_all_screenings" ON public.compliance_screenings
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- Billing Info Policies
DROP POLICY IF EXISTS "users_manage_own_billing" ON public.advertiser_billing_info;
CREATE POLICY "users_manage_own_billing" ON public.advertiser_billing_info
FOR ALL TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.advertiser_registrations
        WHERE id = advertiser_billing_info.registration_id
        AND user_id = auth.uid()
    )
);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

DROP TRIGGER IF EXISTS update_alert_rules_updated_at ON public.alert_rules;
CREATE TRIGGER update_alert_rules_updated_at
BEFORE UPDATE ON public.alert_rules
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_advertiser_registrations_updated_at ON public.advertiser_registrations;
CREATE TRIGGER update_advertiser_registrations_updated_at
BEFORE UPDATE ON public.advertiser_registrations
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_advertiser_documents_updated_at ON public.advertiser_documents;
CREATE TRIGGER update_advertiser_documents_updated_at
BEFORE UPDATE ON public.advertiser_documents
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_beneficial_owners_updated_at ON public.beneficial_owners;
CREATE TRIGGER update_beneficial_owners_updated_at
BEFORE UPDATE ON public.beneficial_owners
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_advertiser_billing_info_updated_at ON public.advertiser_billing_info;
CREATE TRIGGER update_advertiser_billing_info_updated_at
BEFORE UPDATE ON public.advertiser_billing_info
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();

-- ============================================================================
-- MOCK DATA
-- ============================================================================

DO $$
DECLARE
    v_admin_id UUID;
    v_user_id UUID;
    v_rule_id UUID;
    v_registration_id UUID;
BEGIN
    SELECT id INTO v_admin_id FROM public.user_profiles WHERE email = 'admin@example.com' LIMIT 1;
    SELECT id INTO v_user_id FROM public.user_profiles WHERE email = 'user@example.com' LIMIT 1;

    IF v_admin_id IS NOT NULL THEN
        INSERT INTO public.alert_rules (id, created_by, rule_name, description, metric_type, threshold_value, comparison_operator, severity, notification_channels, status)
        VALUES 
            (gen_random_uuid(), v_admin_id, 'High Fraud Score Alert', 'Trigger when fraud score exceeds 85', 'fraud_score', 85, 'greater_than'::public.comparison_operator, 'critical'::public.alert_severity, ARRAY['sms', 'email', 'push']::public.alert_channel[], 'active'::public.alert_rule_status),
            (gen_random_uuid(), v_admin_id, 'Payment Failure Rate', 'Alert when payment failure rate exceeds 10%', 'payment_failure_rate', 10, 'greater_than'::public.comparison_operator, 'high'::public.alert_severity, ARRAY['email']::public.alert_channel[], 'active'::public.alert_rule_status),
            (gen_random_uuid(), v_admin_id, 'Campaign Performance Drop', 'Alert when campaign CTR drops below 2%', 'campaign_ctr', 2, 'less_than'::public.comparison_operator, 'medium'::public.alert_severity, ARRAY['email', 'push']::public.alert_channel[], 'active'::public.alert_rule_status)
        ON CONFLICT (id) DO NOTHING
        RETURNING id INTO v_rule_id;

        IF v_rule_id IS NOT NULL THEN
            INSERT INTO public.alert_rule_conditions (rule_id, metric_name, comparison_operator, threshold_value, time_window_minutes)
            VALUES 
                (v_rule_id, 'fraud_score', 'greater_than'::public.comparison_operator, 85, 5),
                (v_rule_id, 'confidence_level', 'greater_than'::public.comparison_operator, 90, 5)
            ON CONFLICT (id) DO NOTHING;
        END IF;
    END IF;

    IF v_user_id IS NOT NULL THEN
        INSERT INTO public.advertiser_registrations (id, user_id, company_name, company_email, industry_classification, registration_status, kyc_status, current_step)
        VALUES 
            (gen_random_uuid(), v_user_id, 'Acme Advertising Inc', 'contact@acmeads.com', 'Digital Marketing', 'pending'::public.advertiser_status, 'in_progress'::public.kyc_status, 3),
            (gen_random_uuid(), v_user_id, 'BrandBoost LLC', 'info@brandboost.com', 'Brand Management', 'under_review'::public.advertiser_status, 'pending_review'::public.kyc_status, 5)
        ON CONFLICT (id) DO NOTHING
        RETURNING id INTO v_registration_id;

        IF v_registration_id IS NOT NULL THEN
            INSERT INTO public.advertiser_documents (registration_id, document_type, document_name, file_url, verification_status)
            VALUES 
                (v_registration_id, 'business_registration'::public.document_type, 'business_cert.pdf', 'https://storage.example.com/docs/business_cert.pdf', 'verified'::public.verification_status),
                (v_registration_id, 'tax_id'::public.document_type, 'tax_id_proof.pdf', 'https://storage.example.com/docs/tax_id.pdf', 'pending'::public.verification_status)
            ON CONFLICT (id) DO NOTHING;

            INSERT INTO public.beneficial_owners (registration_id, full_name, ownership_percentage, nationality)
            VALUES 
                (v_registration_id, 'John Doe', 60.0, 'US'),
                (v_registration_id, 'Jane Smith', 40.0, 'US')
            ON CONFLICT (id) DO NOTHING;
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;