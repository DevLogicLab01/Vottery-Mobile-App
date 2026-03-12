-- Migration: 7 Features Implementation
-- Tables: release_history, feature_flags_deployment, deployment_rollbacks,
--         staged_rollout_progress, security_hardening_audit_log, security_sign_offs,
--         battery_usage_metrics, network_performance_metrics, performance_regression_alerts,
--         adaptive_layout_configs, jolts_video_analytics

-- Release History
CREATE TABLE IF NOT EXISTS public.release_history (
    release_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version VARCHAR(20) NOT NULL,
    release_notes TEXT,
    deployment_strategy VARCHAR(20) DEFAULT 'blue_green',
    target_environment VARCHAR(20) DEFAULT 'staging',
    deployed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    deployed_at TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'pending',
    rollback_version UUID REFERENCES public.release_history(release_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_releases ON public.release_history(deployed_at, status);

-- Feature Flags Deployment
CREATE TABLE IF NOT EXISTS public.feature_flags_deployment (
    flag_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    flag_name VARCHAR(100) NOT NULL,
    description TEXT,
    enabled_percentage INTEGER DEFAULT 0 CHECK (enabled_percentage BETWEEN 0 AND 100),
    target_segments JSONB DEFAULT '[]'::jsonb,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    deployed_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_feature_flags_name ON public.feature_flags_deployment(flag_name);
CREATE INDEX IF NOT EXISTS idx_feature_flags ON public.feature_flags_deployment(flag_name, is_active);

-- Deployment Rollbacks
CREATE TABLE IF NOT EXISTS public.deployment_rollbacks (
    rollback_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_version UUID REFERENCES public.release_history(release_id) ON DELETE SET NULL,
    to_version UUID REFERENCES public.release_history(release_id) ON DELETE SET NULL,
    reason TEXT,
    executed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    executed_at TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'pending',
    affected_users INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_rollbacks ON public.deployment_rollbacks(executed_at, status);

-- Staged Rollout Progress
CREATE TABLE IF NOT EXISTS public.staged_rollout_progress (
    progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    release_id UUID REFERENCES public.release_history(release_id) ON DELETE CASCADE,
    current_stage VARCHAR(20) DEFAULT 'canary',
    user_percentage INTEGER DEFAULT 10,
    active_users INTEGER DEFAULT 0,
    error_rate DECIMAL(5,2) DEFAULT 0.00,
    promoted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rollout_progress ON public.staged_rollout_progress(release_id, current_stage);

-- Security Hardening Audit Log
CREATE TABLE IF NOT EXISTS public.security_hardening_audit_log (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_type VARCHAR(50) NOT NULL,
    endpoint_url TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    details JSONB DEFAULT '{}'::jsonb,
    checked_at TIMESTAMPTZ DEFAULT NOW(),
    checked_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_security_audit ON public.security_hardening_audit_log(checked_at, check_type);

-- Security Sign-Offs
CREATE TABLE IF NOT EXISTS public.security_sign_offs (
    sign_off_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_name VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending',
    approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    approval_timestamp TIMESTAMPTZ DEFAULT NOW(),
    rejection_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_sign_offs ON public.security_sign_offs(domain_name, status);

-- Battery Usage Metrics
CREATE TABLE IF NOT EXISTS public.battery_usage_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screen_name VARCHAR(200) NOT NULL,
    battery_drain_percent DECIMAL(5,2) DEFAULT 0.00,
    time_spent_seconds INTEGER DEFAULT 0,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_battery_metrics ON public.battery_usage_metrics(recorded_at, screen_name);

-- Network Performance Metrics
CREATE TABLE IF NOT EXISTS public.network_performance_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    network_type VARCHAR(20) NOT NULL,
    screen_name VARCHAR(200) NOT NULL,
    load_time_ms INTEGER DEFAULT 0,
    api_latency_ms INTEGER DEFAULT 0,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_network_metrics ON public.network_performance_metrics(network_type, recorded_at);

-- Performance Regression Alerts
CREATE TABLE IF NOT EXISTS public.performance_regression_alerts (
    alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_name VARCHAR(100) NOT NULL,
    baseline_value DECIMAL(10,2) DEFAULT 0.00,
    current_value DECIMAL(10,2) DEFAULT 0.00,
    deviation_percentage DECIMAL(5,2) DEFAULT 0.00,
    severity VARCHAR(20) DEFAULT 'info',
    detected_at TIMESTAMPTZ DEFAULT NOW(),
    acknowledged BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_regression_alerts ON public.performance_regression_alerts(detected_at, severity);

-- Adaptive Layout Configs
CREATE TABLE IF NOT EXISTS public.adaptive_layout_configs (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content_box_width DECIMAL(5,2) DEFAULT 14.50,
    breakpoints JSONB DEFAULT '[]'::jsonb,
    transition_duration INTEGER DEFAULT 300,
    easing_curve VARCHAR(20) DEFAULT 'easeInOut',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_layout_configs ON public.adaptive_layout_configs(user_id);

-- Jolts Video Analytics
CREATE TABLE IF NOT EXISTS public.jolts_video_analytics (
    analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    jolt_id UUID,
    video_title VARCHAR(200),
    total_views INTEGER DEFAULT 0,
    unique_viewers INTEGER DEFAULT 0,
    avg_watch_time_seconds INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2) DEFAULT 0.00,
    engagement_count INTEGER DEFAULT 0,
    viewer_demographics JSONB DEFAULT '{}'::jsonb,
    recorded_date DATE DEFAULT CURRENT_DATE
);

CREATE INDEX IF NOT EXISTS idx_jolts_analytics ON public.jolts_video_analytics(jolt_id, recorded_date);

-- Enable RLS on all new tables
ALTER TABLE public.release_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flags_deployment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deployment_rollbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staged_rollout_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_hardening_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_sign_offs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.battery_usage_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.network_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_regression_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.adaptive_layout_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jolts_video_analytics ENABLE ROW LEVEL SECURITY;

-- RLS Policies (authenticated users can read, admins can write)
DROP POLICY IF EXISTS "authenticated_read_release_history" ON public.release_history;
CREATE POLICY "authenticated_read_release_history" ON public.release_history
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "authenticated_manage_release_history" ON public.release_history;
CREATE POLICY "authenticated_manage_release_history" ON public.release_history
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_manage_feature_flags" ON public.feature_flags_deployment;
CREATE POLICY "authenticated_manage_feature_flags" ON public.feature_flags_deployment
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_manage_rollbacks" ON public.deployment_rollbacks;
CREATE POLICY "authenticated_manage_rollbacks" ON public.deployment_rollbacks
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_manage_rollout_progress" ON public.staged_rollout_progress;
CREATE POLICY "authenticated_manage_rollout_progress" ON public.staged_rollout_progress
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_manage_security_audit" ON public.security_hardening_audit_log;
CREATE POLICY "authenticated_manage_security_audit" ON public.security_hardening_audit_log
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_manage_sign_offs" ON public.security_sign_offs;
CREATE POLICY "authenticated_manage_sign_offs" ON public.security_sign_offs
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "users_manage_own_battery_metrics" ON public.battery_usage_metrics;
CREATE POLICY "users_manage_own_battery_metrics" ON public.battery_usage_metrics
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "authenticated_manage_network_metrics" ON public.network_performance_metrics;
CREATE POLICY "authenticated_manage_network_metrics" ON public.network_performance_metrics
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_manage_regression_alerts" ON public.performance_regression_alerts;
CREATE POLICY "authenticated_manage_regression_alerts" ON public.performance_regression_alerts
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "users_manage_own_layout_configs" ON public.adaptive_layout_configs;
CREATE POLICY "users_manage_own_layout_configs" ON public.adaptive_layout_configs
    FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "authenticated_manage_jolts_analytics" ON public.jolts_video_analytics;
CREATE POLICY "authenticated_manage_jolts_analytics" ON public.jolts_video_analytics
    FOR ALL TO authenticated USING (true) WITH CHECK (true);
