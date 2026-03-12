-- Performance Optimization Advisor, PagerDuty Integration, and Compliance Reports Generator
-- Migration: 20260222094500_performance_pagerduty_compliance.sql

-- 1. Create ENUMs
DROP TYPE IF EXISTS public.optimization_type CASCADE;
CREATE TYPE public.optimization_type AS ENUM ('slow_query', 'api_bottleneck', 'infrastructure', 'caching');

DROP TYPE IF EXISTS public.optimization_severity CASCADE;
CREATE TYPE public.optimization_severity AS ENUM ('critical', 'high', 'medium', 'low');

DROP TYPE IF EXISTS public.implementation_status CASCADE;
CREATE TYPE public.implementation_status AS ENUM ('pending', 'in_progress', 'completed', 'dismissed');

DROP TYPE IF EXISTS public.pagerduty_incident_status CASCADE;
CREATE TYPE public.pagerduty_incident_status AS ENUM ('triggered', 'acknowledged', 'resolved');

DROP TYPE IF EXISTS public.compliance_framework CASCADE;
CREATE TYPE public.compliance_framework AS ENUM ('GDPR', 'SOC2', 'HIPAA', 'ISO27001');

DROP TYPE IF EXISTS public.report_frequency CASCADE;
CREATE TYPE public.report_frequency AS ENUM ('weekly', 'monthly', 'quarterly', 'annually');

-- 2. Create Tables

-- Performance Optimizations Table
CREATE TABLE IF NOT EXISTS public.performance_optimizations (
    optimization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    detected_at TIMESTAMPTZ DEFAULT now(),
    optimization_type public.optimization_type NOT NULL,
    severity public.optimization_severity NOT NULL,
    affected_component TEXT NOT NULL,
    current_metrics JSONB DEFAULT '{}'::jsonb,
    recommended_actions JSONB DEFAULT '{}'::jsonb,
    estimated_improvement JSONB DEFAULT '{}'::jsonb,
    implementation_status public.implementation_status DEFAULT 'pending'::public.implementation_status,
    implemented_at TIMESTAMPTZ,
    implementation_notes TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- On-Call Schedules Table
CREATE TABLE IF NOT EXISTS public.on_call_schedules (
    schedule_id TEXT PRIMARY KEY,
    schedule_name TEXT NOT NULL,
    current_on_call_user_id TEXT,
    on_call_until TIMESTAMPTZ,
    next_on_call_user_id TEXT,
    escalation_policy JSONB DEFAULT '{}'::jsonb,
    last_synced_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- PagerDuty Incidents Table
CREATE TABLE IF NOT EXISTS public.pagerduty_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vottery_incident_id UUID,
    pagerduty_incident_id TEXT UNIQUE NOT NULL,
    incident_key TEXT,
    status public.pagerduty_incident_status DEFAULT 'triggered'::public.pagerduty_incident_status,
    acknowledged_by TEXT,
    acknowledged_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Compliance Report Schedules Table
CREATE TABLE IF NOT EXISTS public.compliance_report_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type public.compliance_framework NOT NULL,
    frequency public.report_frequency NOT NULL,
    recipients TEXT[] DEFAULT ARRAY[]::TEXT[],
    report_scope JSONB DEFAULT '{}'::jsonb,
    next_run_date TIMESTAMPTZ NOT NULL,
    last_run_date TIMESTAMPTZ,
    enabled BOOLEAN DEFAULT true,
    email_template JSONB DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Report Signatures Table
CREATE TABLE IF NOT EXISTS public.report_signatures (
    signature_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL,
    signature_hash TEXT NOT NULL,
    signed_at TIMESTAMPTZ DEFAULT now(),
    signed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    verification_method TEXT DEFAULT 'RSA-SHA256',
    public_key TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Generated Compliance Reports Table
CREATE TABLE IF NOT EXISTS public.generated_compliance_reports (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type public.compliance_framework NOT NULL,
    reporting_period_start TIMESTAMPTZ NOT NULL,
    reporting_period_end TIMESTAMPTZ NOT NULL,
    generated_at TIMESTAMPTZ DEFAULT now(),
    generated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    compliance_status TEXT,
    report_data JSONB DEFAULT '{}'::jsonb,
    report_hash TEXT,
    file_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Create Indexes
CREATE INDEX IF NOT EXISTS idx_performance_optimizations_type ON public.performance_optimizations(optimization_type);
CREATE INDEX IF NOT EXISTS idx_performance_optimizations_severity ON public.performance_optimizations(severity);
CREATE INDEX IF NOT EXISTS idx_performance_optimizations_status ON public.performance_optimizations(implementation_status);
CREATE INDEX IF NOT EXISTS idx_pagerduty_incidents_vottery_id ON public.pagerduty_incidents(vottery_incident_id);
CREATE INDEX IF NOT EXISTS idx_pagerduty_incidents_status ON public.pagerduty_incidents(status);
CREATE INDEX IF NOT EXISTS idx_compliance_schedules_next_run ON public.compliance_report_schedules(next_run_date);
CREATE INDEX IF NOT EXISTS idx_generated_reports_type ON public.generated_compliance_reports(report_type);
CREATE INDEX IF NOT EXISTS idx_report_signatures_report_id ON public.report_signatures(report_id);

-- 4. Enable RLS
ALTER TABLE public.performance_optimizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.on_call_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pagerduty_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compliance_report_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_signatures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generated_compliance_reports ENABLE ROW LEVEL SECURITY;

-- 5. Create RLS Policies

-- Performance Optimizations Policies
DROP POLICY IF EXISTS "authenticated_users_view_performance_optimizations" ON public.performance_optimizations;
CREATE POLICY "authenticated_users_view_performance_optimizations"
ON public.performance_optimizations
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "authenticated_users_manage_performance_optimizations" ON public.performance_optimizations;
CREATE POLICY "authenticated_users_manage_performance_optimizations"
ON public.performance_optimizations
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- On-Call Schedules Policies
DROP POLICY IF EXISTS "authenticated_users_view_on_call_schedules" ON public.on_call_schedules;
CREATE POLICY "authenticated_users_view_on_call_schedules"
ON public.on_call_schedules
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "authenticated_users_manage_on_call_schedules" ON public.on_call_schedules;
CREATE POLICY "authenticated_users_manage_on_call_schedules"
ON public.on_call_schedules
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- PagerDuty Incidents Policies
DROP POLICY IF EXISTS "authenticated_users_view_pagerduty_incidents" ON public.pagerduty_incidents;
CREATE POLICY "authenticated_users_view_pagerduty_incidents"
ON public.pagerduty_incidents
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "authenticated_users_manage_pagerduty_incidents" ON public.pagerduty_incidents;
CREATE POLICY "authenticated_users_manage_pagerduty_incidents"
ON public.pagerduty_incidents
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Compliance Report Schedules Policies
DROP POLICY IF EXISTS "authenticated_users_view_compliance_schedules" ON public.compliance_report_schedules;
CREATE POLICY "authenticated_users_view_compliance_schedules"
ON public.compliance_report_schedules
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "authenticated_users_manage_compliance_schedules" ON public.compliance_report_schedules;
CREATE POLICY "authenticated_users_manage_compliance_schedules"
ON public.compliance_report_schedules
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Report Signatures Policies
DROP POLICY IF EXISTS "authenticated_users_view_report_signatures" ON public.report_signatures;
CREATE POLICY "authenticated_users_view_report_signatures"
ON public.report_signatures
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "authenticated_users_create_report_signatures" ON public.report_signatures;
CREATE POLICY "authenticated_users_create_report_signatures"
ON public.report_signatures
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Generated Compliance Reports Policies
DROP POLICY IF EXISTS "authenticated_users_view_generated_reports" ON public.generated_compliance_reports;
CREATE POLICY "authenticated_users_view_generated_reports"
ON public.generated_compliance_reports
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "authenticated_users_create_generated_reports" ON public.generated_compliance_reports;
CREATE POLICY "authenticated_users_create_generated_reports"
ON public.generated_compliance_reports
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 6. Mock Data
DO $$
DECLARE
    existing_user_id UUID;
    optimization_id_1 UUID := gen_random_uuid();
    optimization_id_2 UUID := gen_random_uuid();
    schedule_id_1 UUID := gen_random_uuid();
    report_id_1 UUID := gen_random_uuid();
BEGIN
    -- Get existing user
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'user_profiles'
    ) THEN
        SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
        
        IF existing_user_id IS NOT NULL THEN
            -- Insert performance optimizations
            INSERT INTO public.performance_optimizations (
                optimization_id, optimization_type, severity, affected_component,
                current_metrics, recommended_actions, estimated_improvement,
                implementation_status, created_by
            ) VALUES
                (
                    optimization_id_1,
                    'slow_query'::public.optimization_type,
                    'high'::public.optimization_severity,
                    'user_profiles SELECT query',
                    jsonb_build_object(
                        'avg_duration_ms', 1245,
                        'p95_duration_ms', 2100,
                        'execution_count', 1247
                    ),
                    jsonb_build_object(
                        'recommendation', 'Add index on email column',
                        'implementation_difficulty', 'low',
                        'estimated_time', '30 minutes'
                    ),
                    jsonb_build_object(
                        'latency_reduction_ms', 450,
                        'throughput_increase_percentage', 23,
                        'cost_savings_monthly', 450
                    ),
                    'pending'::public.implementation_status,
                    existing_user_id
                ),
                (
                    optimization_id_2,
                    'api_bottleneck'::public.optimization_type,
                    'critical'::public.optimization_severity,
                    '/api/elections endpoint',
                    jsonb_build_object(
                        'avg_response_time', 3200,
                        'p95_latency', 5400,
                        'error_rate', 7.5
                    ),
                    jsonb_build_object(
                        'recommendation', 'Implement Redis caching for election data',
                        'implementation_difficulty', 'medium',
                        'estimated_time', '2 hours'
                    ),
                    jsonb_build_object(
                        'latency_reduction_ms', 2800,
                        'throughput_increase_percentage', 45,
                        'cost_savings_monthly', 1200
                    ),
                    'in_progress'::public.implementation_status,
                    existing_user_id
                )
            ON CONFLICT (optimization_id) DO NOTHING;

            -- Insert on-call schedule
            INSERT INTO public.on_call_schedules (
                schedule_id, schedule_name, current_on_call_user_id,
                on_call_until, escalation_policy
            ) VALUES
                (
                    'PD_SCHEDULE_001',
                    'Platform Engineering On-Call',
                    'john.doe@vottery.com',
                    now() + interval '7 days',
                    jsonb_build_object(
                        'policy_id', 'P_ENG_ESCALATION',
                        'escalation_levels', jsonb_build_array(
                            jsonb_build_object('level', 1, 'timeout_minutes', 15),
                            jsonb_build_object('level', 2, 'timeout_minutes', 30)
                        )
                    )
                )
            ON CONFLICT (schedule_id) DO NOTHING;

            -- Insert compliance report schedule
            INSERT INTO public.compliance_report_schedules (
                schedule_id, report_type, frequency, recipients,
                report_scope, next_run_date, enabled, created_by
            ) VALUES
                (
                    schedule_id_1,
                    'GDPR'::public.compliance_framework,
                    'quarterly'::public.report_frequency,
                    ARRAY['compliance@vottery.com', 'legal@vottery.com']::TEXT[],
                    jsonb_build_object(
                        'include_categories', jsonb_build_array(
                            'user_data_access',
                            'data_deletion',
                            'consent_changes'
                        )
                    ),
                    now() + interval '90 days',
                    true,
                    existing_user_id
                )
            ON CONFLICT (schedule_id) DO NOTHING;

            -- Insert generated report
            INSERT INTO public.generated_compliance_reports (
                report_id, report_type, reporting_period_start,
                reporting_period_end, generated_by, compliance_status,
                report_data, report_hash
            ) VALUES
                (
                    report_id_1,
                    'SOC2'::public.compliance_framework,
                    now() - interval '30 days',
                    now(),
                    existing_user_id,
                    'Compliant',
                    jsonb_build_object(
                        'total_events', 1247,
                        'compliant_events', 1240,
                        'non_compliant_events', 7,
                        'key_findings', jsonb_build_array(
                            'All access controls properly configured',
                            '7 minor policy violations detected and resolved'
                        )
                    ),
                    'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6'
                )
            ON CONFLICT (report_id) DO NOTHING;

            RAISE NOTICE 'Mock data inserted successfully';
        ELSE
            RAISE NOTICE 'No users found in user_profiles';
        END IF;
    ELSE
        RAISE NOTICE 'Table user_profiles does not exist';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;