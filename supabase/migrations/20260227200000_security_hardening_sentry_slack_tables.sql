-- Security Hardening Sprint & Sentry Slack Alert Pipeline Tables
-- Migration: 20260227200000_security_hardening_sentry_slack_tables.sql

-- Security Hardening Audit Log
CREATE TABLE IF NOT EXISTS public.security_hardening_audit_log (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_type VARCHAR(50) NOT NULL,
    endpoint_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    details JSONB DEFAULT '{}'::jsonb,
    checked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    checked_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_security_audit ON public.security_hardening_audit_log(checked_at, check_type);
CREATE INDEX IF NOT EXISTS idx_security_audit_status ON public.security_hardening_audit_log(status);

ALTER TABLE public.security_hardening_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_manage_security_audit_log" ON public.security_hardening_audit_log;
CREATE POLICY "admin_manage_security_audit_log"
ON public.security_hardening_audit_log
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Security Sign-Offs table
CREATE TABLE IF NOT EXISTS public.security_sign_offs (
    sign_off_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    approval_timestamp TIMESTAMPTZ,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sign_offs ON public.security_sign_offs(domain_name, status);

ALTER TABLE public.security_sign_offs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_manage_security_sign_offs" ON public.security_sign_offs;
CREATE POLICY "admin_manage_security_sign_offs"
ON public.security_sign_offs
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Insert mock security audit data
DO $$
BEGIN
    INSERT INTO public.security_hardening_audit_log
        (audit_id, check_type, endpoint_url, status, details, checked_at)
    VALUES
        (gen_random_uuid(), 'ssl_tls', 'https://vottery2205.builtwithrocket.new', 'passed',
         jsonb_build_object('certificate_valid', true, 'days_until_expiry', 87, 'protocol', 'TLS 1.3', 'grade', 'A+'),
         CURRENT_TIMESTAMP),
        (gen_random_uuid(), 'ssl_tls', 'https://api.vottery2205.builtwithrocket.new', 'passed',
         jsonb_build_object('certificate_valid', true, 'days_until_expiry', 87, 'protocol', 'TLS 1.3', 'grade', 'A'),
         CURRENT_TIMESTAMP - INTERVAL '1 hour'),
        (gen_random_uuid(), 'cors', '/api/votes', 'passed',
         jsonb_build_object('allowed_origins', 3, 'credentials_enabled', false, 'wildcard_blocked', true),
         CURRENT_TIMESTAMP - INTERVAL '2 hours'),
        (gen_random_uuid(), 'rate_limiting', '/api/auth/login', 'passed',
         jsonb_build_object('max_requests_per_minute', 10, 'current_usage', 3, 'burst_allowance', 15),
         CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
        (gen_random_uuid(), 'rate_limiting', '/api/elections', 'warning',
         jsonb_build_object('max_requests_per_minute', 100, 'current_usage', 95, 'burst_allowance', 120),
         CURRENT_TIMESTAMP - INTERVAL '15 minutes')
    ON CONFLICT (audit_id) DO NOTHING;

    -- Insert security sign-off domains
    INSERT INTO public.security_sign_offs
        (sign_off_id, domain_name, status)
    VALUES
        (gen_random_uuid(), 'OWASP Testing', 'pending'),
        (gen_random_uuid(), 'Pen Testing', 'pending'),
        (gen_random_uuid(), 'Biometric Compliance', 'pending'),
        (gen_random_uuid(), 'Data Residency', 'pending'),
        (gen_random_uuid(), 'GDPR', 'pending'),
        (gen_random_uuid(), 'CCPA', 'pending'),
        (gen_random_uuid(), 'SSL TLS', 'approved'),
        (gen_random_uuid(), 'Rate Limiting', 'pending')
    ON CONFLICT (sign_off_id) DO NOTHING;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;
