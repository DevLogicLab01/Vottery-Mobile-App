-- Header Audit Log and Performance Metrics Tables
-- Migration: 20260227030000_header_audit_performance_tables.sql

-- 1. Create header_audit_log table
CREATE TABLE IF NOT EXISTS public.header_audit_log (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screen_name VARCHAR(200) NOT NULL,
    background_color VARCHAR(20),
    icon_color VARCHAR(20),
    contrast_ratio DECIMAL(4, 2),
    wcag_aa_compliant BOOLEAN DEFAULT false,
    wcag_aaa_compliant BOOLEAN DEFAULT false,
    audited_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create header_performance_metrics table
CREATE TABLE IF NOT EXISTS public.header_performance_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screen_name VARCHAR(200) NOT NULL,
    frame_rate DECIMAL(5, 2),
    avg_frame_time_ms INTEGER,
    layout_time_ms INTEGER,
    icon_render_time_ms INTEGER,
    sample_size INTEGER DEFAULT 1,
    recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_header_audit_audited_at
    ON public.header_audit_log (audited_at);

CREATE INDEX IF NOT EXISTS idx_header_audit_screen_name
    ON public.header_audit_log (screen_name);

CREATE INDEX IF NOT EXISTS idx_header_performance_screen_name
    ON public.header_performance_metrics (screen_name);

CREATE INDEX IF NOT EXISTS idx_header_performance_recorded_at
    ON public.header_performance_metrics (recorded_at);

CREATE INDEX IF NOT EXISTS idx_header_performance_screen_recorded
    ON public.header_performance_metrics (screen_name, recorded_at);

-- 4. Enable RLS
ALTER TABLE public.header_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.header_performance_metrics ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for header_audit_log
DROP POLICY IF EXISTS "allow_read_header_audit_log" ON public.header_audit_log;
CREATE POLICY "allow_read_header_audit_log"
    ON public.header_audit_log
    FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "allow_insert_header_audit_log" ON public.header_audit_log;
CREATE POLICY "allow_insert_header_audit_log"
    ON public.header_audit_log
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- 6. RLS Policies for header_performance_metrics
DROP POLICY IF EXISTS "allow_read_header_performance_metrics" ON public.header_performance_metrics;
CREATE POLICY "allow_read_header_performance_metrics"
    ON public.header_performance_metrics
    FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "allow_insert_header_performance_metrics" ON public.header_performance_metrics;
CREATE POLICY "allow_insert_header_performance_metrics"
    ON public.header_performance_metrics
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Also allow anonymous/service role inserts for background monitoring
DROP POLICY IF EXISTS "allow_anon_insert_header_performance" ON public.header_performance_metrics;
CREATE POLICY "allow_anon_insert_header_performance"
    ON public.header_performance_metrics
    FOR INSERT
    TO anon
    WITH CHECK (true);

DROP POLICY IF EXISTS "allow_anon_read_header_performance" ON public.header_performance_metrics;
CREATE POLICY "allow_anon_read_header_performance"
    ON public.header_performance_metrics
    FOR SELECT
    TO anon
    USING (true);

-- 7. Mock audit data
DO $$
BEGIN
    INSERT INTO public.header_audit_log (
        screen_name, background_color, icon_color, contrast_ratio,
        wcag_aa_compliant, wcag_aaa_compliant, audited_at
    ) VALUES
        ('vote_dashboard', '#FFFFFF', '#212121', 15.30, true, true, NOW() - INTERVAL '1 hour'),
        ('feature_performance_dashboard', '#FFFFFF', '#212121', 15.30, true, true, NOW() - INTERVAL '1 hour'),
        ('admin_dashboard', '#FFFFFF', '#212121', 15.30, true, true, NOW() - INTERVAL '1 hour'),
        ('creator_analytics_dashboard', '#FFFFFF', '#212121', 15.30, true, true, NOW() - INTERVAL '1 hour'),
        ('fraud_monitoring_dashboard', '#FFFFFF', '#212121', 15.30, true, true, NOW() - INTERVAL '1 hour')
    ON CONFLICT (audit_id) DO NOTHING;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock audit data insertion failed: %', SQLERRM;
END $$;

-- 8. Mock performance data
DO $$
BEGIN
    INSERT INTO public.header_performance_metrics (
        screen_name, frame_rate, avg_frame_time_ms, layout_time_ms,
        icon_render_time_ms, sample_size, recorded_at
    ) VALUES
        ('vote_dashboard', 59.8, 16, 4, 2, 120, NOW() - INTERVAL '30 minutes'),
        ('feature_performance_dashboard', 58.2, 17, 6, 3, 85, NOW() - INTERVAL '25 minutes'),
        ('admin_dashboard', 60.0, 16, 3, 2, 200, NOW() - INTERVAL '20 minutes'),
        ('creator_analytics_dashboard', 55.4, 18, 8, 4, 67, NOW() - INTERVAL '15 minutes'),
        ('fraud_monitoring_dashboard', 57.1, 17, 5, 3, 143, NOW() - INTERVAL '10 minutes'),
        ('blockchain_vote_verification', 38.2, 26, 22, 8, 34, NOW() - INTERVAL '5 minutes'),
        ('advanced_fraud_detection', 42.1, 23, 18, 6, 56, NOW() - INTERVAL '3 minutes'),
        ('social_media_home_feed', 46.3, 21, 14, 5, 89, NOW() - INTERVAL '2 minutes'),
        ('wallet_dashboard', 58.9, 16, 5, 2, 112, NOW() - INTERVAL '1 minute'),
        ('creator_marketplace', 53.7, 18, 9, 4, 78, NOW())
    ON CONFLICT (metric_id) DO NOTHING;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock performance data insertion failed: %', SQLERRM;
END $$;
