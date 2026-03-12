-- Perplexity Fraud Log Analysis System Migration
-- Creates tables for log aggregation, fraud analysis, pattern detection, threat predictions, and investigations

-- =============================================
-- TABLE: platform_logs_aggregated
-- Stores aggregated logs from multiple sources
-- =============================================
CREATE TABLE IF NOT EXISTS public.platform_logs_aggregated (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    event_type VARCHAR(50) NOT NULL CHECK (event_type IN (
        'auth_event', 'api_call', 'database_query', 'payment_transaction',
        'user_action', 'security_event', 'system_event', 'error'
    )),
    user_id UUID,
    ip_address VARCHAR(45),
    action VARCHAR(200) NOT NULL,
    resource VARCHAR(200),
    metadata JSONB DEFAULT '{}'::jsonb,
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    fingerprint VARCHAR(64) UNIQUE,
    source_table VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_platform_logs_timestamp ON public.platform_logs_aggregated(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_platform_logs_user_id ON public.platform_logs_aggregated(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_platform_logs_ip_address ON public.platform_logs_aggregated(ip_address) WHERE ip_address IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_platform_logs_event_type ON public.platform_logs_aggregated(event_type);
CREATE INDEX IF NOT EXISTS idx_platform_logs_severity ON public.platform_logs_aggregated(severity);
CREATE INDEX IF NOT EXISTS idx_platform_logs_fingerprint ON public.platform_logs_aggregated(fingerprint) WHERE fingerprint IS NOT NULL;

COMMENT ON TABLE public.platform_logs_aggregated IS 'Aggregated platform logs from multiple sources for fraud analysis';
COMMENT ON COLUMN public.platform_logs_aggregated.fingerprint IS 'Unique hash for deduplication: hash(timestamp, event_type, user_id, action)';

-- =============================================
-- TABLE: fraud_analysis_results
-- Stores Perplexity AI fraud analysis results
-- =============================================
CREATE TABLE IF NOT EXISTS public.fraud_analysis_results (
    analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    log_batch_id UUID,
    log_start_time TIMESTAMPTZ NOT NULL,
    log_end_time TIMESTAMPTZ NOT NULL,
    analyzed_log_count INTEGER NOT NULL DEFAULT 0,
    detected_patterns JSONB DEFAULT '[]'::jsonb,
    threat_correlations JSONB DEFAULT '[]'::jsonb,
    anomaly_predictions JSONB DEFAULT '[]'::jsonb,
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    perplexity_response TEXT,
    perplexity_model VARCHAR(50) DEFAULT 'sonar-pro',
    processing_time_seconds INTEGER,
    status VARCHAR(50) DEFAULT 'completed' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fraud_analysis_timestamp ON public.fraud_analysis_results(analysis_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_fraud_analysis_log_times ON public.fraud_analysis_results(log_start_time, log_end_time);
CREATE INDEX IF NOT EXISTS idx_fraud_analysis_confidence ON public.fraud_analysis_results(confidence_score DESC) WHERE confidence_score IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fraud_analysis_status ON public.fraud_analysis_results(status);

COMMENT ON TABLE public.fraud_analysis_results IS 'Perplexity AI fraud analysis results with detected patterns, correlations, and predictions';

-- =============================================
-- TABLE: fraud_pattern_evidence
-- Links fraud patterns to specific log entries
-- =============================================
CREATE TABLE IF NOT EXISTS public.fraud_pattern_evidence (
    evidence_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id UUID NOT NULL REFERENCES public.fraud_analysis_results(analysis_id) ON DELETE CASCADE,
    pattern_name VARCHAR(100) NOT NULL,
    log_entry_id UUID REFERENCES public.platform_logs_aggregated(log_id) ON DELETE SET NULL,
    relevance_score DECIMAL(3,2) CHECK (relevance_score >= 0 AND relevance_score <= 1),
    evidence_type VARCHAR(50) CHECK (evidence_type IN (
        'multi_account_abuse', 'account_takeover', 'payment_fraud',
        'credential_stuffing', 'referral_fraud', 'vote_manipulation',
        'bot_activity', 'suspicious_pattern', 'other'
    )),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fraud_evidence_analysis ON public.fraud_pattern_evidence(analysis_id);
CREATE INDEX IF NOT EXISTS idx_fraud_evidence_pattern ON public.fraud_pattern_evidence(pattern_name);
CREATE INDEX IF NOT EXISTS idx_fraud_evidence_log ON public.fraud_pattern_evidence(log_entry_id) WHERE log_entry_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fraud_evidence_type ON public.fraud_pattern_evidence(evidence_type);

COMMENT ON TABLE public.fraud_pattern_evidence IS 'Links detected fraud patterns to specific log entries as evidence';

-- =============================================
-- TABLE: threat_predictions
-- Stores 24-48 hour threat forecasts
-- =============================================
CREATE TABLE IF NOT EXISTS public.threat_predictions (
    prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id UUID NOT NULL REFERENCES public.fraud_analysis_results(analysis_id) ON DELETE CASCADE,
    predicted_threat VARCHAR(100) NOT NULL,
    threat_category VARCHAR(50) CHECK (threat_category IN (
        'authentication', 'payments', 'user_data', 'elections',
        'content', 'system', 'other'
    )),
    likelihood_percentage INTEGER CHECK (likelihood_percentage >= 0 AND likelihood_percentage <= 100),
    predicted_timeframe VARCHAR(100),
    predicted_start_time TIMESTAMPTZ,
    predicted_end_time TIMESTAMPTZ,
    warning_signs JSONB DEFAULT '[]'::jsonb,
    target_systems JSONB DEFAULT '[]'::jsonb,
    preventive_actions JSONB DEFAULT '[]'::jsonb,
    confidence_level VARCHAR(20) CHECK (confidence_level IN ('low', 'medium', 'high', 'very_high')),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'monitoring', 'occurred', 'prevented', 'false_positive')),
    actual_occurrence_time TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_threat_predictions_analysis ON public.threat_predictions(analysis_id);
CREATE INDEX IF NOT EXISTS idx_threat_predictions_likelihood ON public.threat_predictions(likelihood_percentage DESC);
CREATE INDEX IF NOT EXISTS idx_threat_predictions_timeframe ON public.threat_predictions(predicted_start_time, predicted_end_time) WHERE predicted_start_time IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_threat_predictions_status ON public.threat_predictions(status);
CREATE INDEX IF NOT EXISTS idx_threat_predictions_category ON public.threat_predictions(threat_category);

COMMENT ON TABLE public.threat_predictions IS '24-48 hour threat forecasts from Perplexity AI analysis';

-- =============================================
-- TABLE: fraud_investigations
-- Tracks fraud investigation workflow
-- =============================================
CREATE TABLE IF NOT EXISTS public.fraud_investigations (
    investigation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_id UUID REFERENCES public.fraud_analysis_results(analysis_id) ON DELETE SET NULL,
    pattern_name VARCHAR(100),
    title VARCHAR(200) NOT NULL,
    description TEXT,
    assigned_to UUID,
    status VARCHAR(50) DEFAULT 'pending_review' CHECK (status IN (
        'pending_review', 'investigating', 'action_taken', 'resolved', 'false_positive', 'escalated'
    )),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    affected_users JSONB DEFAULT '[]'::jsonb,
    actions_taken JSONB DEFAULT '[]'::jsonb,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_fraud_investigations_analysis ON public.fraud_investigations(analysis_id) WHERE analysis_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fraud_investigations_assigned ON public.fraud_investigations(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fraud_investigations_status ON public.fraud_investigations(status);
CREATE INDEX IF NOT EXISTS idx_fraud_investigations_priority ON public.fraud_investigations(priority);
CREATE INDEX IF NOT EXISTS idx_fraud_investigations_created ON public.fraud_investigations(created_at DESC);

COMMENT ON TABLE public.fraud_investigations IS 'Fraud investigation workflow tracking';

-- =============================================
-- TABLE: fraud_detection_log
-- Historical fraud detection tracking
-- =============================================
CREATE TABLE IF NOT EXISTS public.fraud_detection_log (
    detection_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    detection_type VARCHAR(100) NOT NULL,
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    user_id UUID,
    ip_address VARCHAR(45),
    details JSONB DEFAULT '{}'::jsonb,
    action_taken VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fraud_detection_type ON public.fraud_detection_log(detection_type);
CREATE INDEX IF NOT EXISTS idx_fraud_detection_user ON public.fraud_detection_log(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_fraud_detection_created ON public.fraud_detection_log(created_at DESC);

COMMENT ON TABLE public.fraud_detection_log IS 'Historical log of fraud detection events';

-- =============================================
-- TABLE: log_aggregation_runs
-- Tracks log aggregation execution
-- =============================================
CREATE TABLE IF NOT EXISTS public.log_aggregation_runs (
    run_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_time TIMESTAMPTZ,
    logs_collected INTEGER DEFAULT 0,
    sources_processed JSONB DEFAULT '[]'::jsonb,
    status VARCHAR(50) DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed')),
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_log_aggregation_start ON public.log_aggregation_runs(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_log_aggregation_status ON public.log_aggregation_runs(status);

COMMENT ON TABLE public.log_aggregation_runs IS 'Tracks log aggregation pipeline execution';

-- =============================================
-- RLS POLICIES
-- =============================================

-- Enable RLS
ALTER TABLE public.platform_logs_aggregated ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_analysis_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_pattern_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.threat_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_investigations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_detection_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.log_aggregation_runs ENABLE ROW LEVEL SECURITY;

-- Admin and security team access
DO $$ 
BEGIN
    -- platform_logs_aggregated policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'platform_logs_aggregated' AND policyname = 'Admin security team can view all logs') THEN
        CREATE POLICY "Admin security team can view all logs"
            ON public.platform_logs_aggregated
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM public.user_profiles
                    WHERE user_profiles.id = auth.uid()
                    AND (user_profiles.role = 'admin' OR user_profiles.role = 'security_admin')
                )
            );
    END IF;

    -- fraud_analysis_results policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fraud_analysis_results' AND policyname = 'Admin security team can view fraud analysis') THEN
        CREATE POLICY "Admin security team can view fraud analysis"
            ON public.fraud_analysis_results
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM public.user_profiles
                    WHERE user_profiles.id = auth.uid()
                    AND (user_profiles.role = 'admin' OR user_profiles.role = 'security_admin')
                )
            );
    END IF;

    -- fraud_pattern_evidence policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fraud_pattern_evidence' AND policyname = 'Admin security team can view fraud evidence') THEN
        CREATE POLICY "Admin security team can view fraud evidence"
            ON public.fraud_pattern_evidence
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM public.user_profiles
                    WHERE user_profiles.id = auth.uid()
                    AND (user_profiles.role = 'admin' OR user_profiles.role = 'security_admin')
                )
            );
    END IF;

    -- threat_predictions policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'threat_predictions' AND policyname = 'Admin security team can view threat predictions') THEN
        CREATE POLICY "Admin security team can view threat predictions"
            ON public.threat_predictions
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM public.user_profiles
                    WHERE user_profiles.id = auth.uid()
                    AND (user_profiles.role = 'admin' OR user_profiles.role = 'security_admin')
                )
            );
    END IF;

    -- fraud_investigations policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fraud_investigations' AND policyname = 'Admin security team can manage investigations') THEN
        CREATE POLICY "Admin security team can manage investigations"
            ON public.fraud_investigations
            FOR ALL
            USING (
                EXISTS (
                    SELECT 1 FROM public.user_profiles
                    WHERE user_profiles.id = auth.uid()
                    AND (user_profiles.role = 'admin' OR user_profiles.role = 'security_admin')
                )
            );
    END IF;

    -- fraud_detection_log policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fraud_detection_log' AND policyname = 'Admin security team can view fraud detection log') THEN
        CREATE POLICY "Admin security team can view fraud detection log"
            ON public.fraud_detection_log
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM public.user_profiles
                    WHERE user_profiles.id = auth.uid()
                    AND (user_profiles.role = 'admin' OR user_profiles.role = 'security_admin')
                )
            );
    END IF;

    -- log_aggregation_runs policies
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'log_aggregation_runs' AND policyname = 'Admin security team can view log aggregation runs') THEN
        CREATE POLICY "Admin security team can view log aggregation runs"
            ON public.log_aggregation_runs
            FOR SELECT
            USING (
                EXISTS (
                    SELECT 1 FROM public.user_profiles
                    WHERE user_profiles.id = auth.uid()
                    AND (user_profiles.role = 'admin' OR user_profiles.role = 'security_admin')
                )
            );
    END IF;
END $$;

-- =============================================
-- FUNCTIONS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_fraud_analysis_updated_at') THEN
        CREATE TRIGGER update_fraud_analysis_updated_at
            BEFORE UPDATE ON public.fraud_analysis_results
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_threat_predictions_updated_at') THEN
        CREATE TRIGGER update_threat_predictions_updated_at
            BEFORE UPDATE ON public.threat_predictions
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_fraud_investigations_updated_at') THEN
        CREATE TRIGGER update_fraud_investigations_updated_at
            BEFORE UPDATE ON public.fraud_investigations
            FOR EACH ROW
            EXECUTE FUNCTION public.update_updated_at_column();
    END IF;
END $$;

-- =============================================
-- SAMPLE DATA (for testing)
-- =============================================

-- Insert sample log entries (idempotent)
INSERT INTO public.platform_logs_aggregated (log_id, timestamp, event_type, user_id, ip_address, action, resource, metadata, severity, fingerprint)
VALUES 
    ('11111111-1111-1111-1111-111111111111', NOW() - INTERVAL '5 minutes', 'auth_event', NULL, '192.168.1.100', 'failed_login', 'auth/login', '{"reason": "invalid_password", "attempts": 3}'::jsonb, 'medium', 'fp_auth_001'),
    ('22222222-2222-2222-2222-222222222222', NOW() - INTERVAL '3 minutes', 'payment_transaction', NULL, '192.168.1.100', 'payment_failed', 'payments/charge', '{"amount": 100, "currency": "USD"}'::jsonb, 'high', 'fp_payment_001'),
    ('33333333-3333-3333-3333-333333333333', NOW() - INTERVAL '1 minute', 'user_action', NULL, '192.168.1.100', 'vote_cast', 'elections/vote', '{"election_id": "test-election"}'::jsonb, 'low', 'fp_vote_001')
ON CONFLICT (fingerprint) DO NOTHING;

-- Perplexity Fraud Log Analysis System - Comprehensive log aggregation, AI-powered fraud detection, threat correlation, and 24-48 hour anomaly prediction