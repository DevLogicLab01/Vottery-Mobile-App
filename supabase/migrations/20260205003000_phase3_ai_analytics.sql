-- Phase 3: Advanced AI & Analytics Migration
-- Timestamp: 20260205003000
-- Description: Multi-AI orchestration, fraud detection, analytics hub, intelligent recommendations

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.ai_service_type CASCADE;
CREATE TYPE public.ai_service_type AS ENUM (
  'openai',
  'claude',
  'perplexity'
);

DROP TYPE IF EXISTS public.fraud_severity CASCADE;
CREATE TYPE public.fraud_severity AS ENUM (
  'low',
  'medium',
  'high',
  'critical'
);

DROP TYPE IF EXISTS public.alert_status CASCADE;
CREATE TYPE public.alert_status AS ENUM (
  'pending',
  'investigating',
  'resolved',
  'false_positive'
);

DROP TYPE IF EXISTS public.recommendation_type CASCADE;
CREATE TYPE public.recommendation_type AS ENUM (
  'content',
  'election',
  'user',
  'prediction_pool'
);

-- ============================================================
-- 2. AI ORCHESTRATION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.ai_orchestration_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_type TEXT NOT NULL,
  input_data JSONB NOT NULL,
  openai_result JSONB,
  claude_result JSONB,
  perplexity_result JSONB,
  consensus_detected BOOLEAN DEFAULT false,
  consensus_variance NUMERIC(5,4),
  agreement_level NUMERIC(5,4),
  recommended_action TEXT,
  action_confidence NUMERIC(5,4),
  execution_status TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_orchestration_analysis_type ON public.ai_orchestration_logs(analysis_type);
CREATE INDEX idx_ai_orchestration_created_at ON public.ai_orchestration_logs(created_at DESC);

-- ============================================================
-- 3. FRAUD DETECTION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.fraud_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  alert_type TEXT NOT NULL,
  fraud_score INTEGER NOT NULL CHECK (fraud_score >= 0 AND fraud_score <= 100),
  severity public.fraud_severity NOT NULL,
  status public.alert_status NOT NULL DEFAULT 'pending',
  ai_analysis JSONB NOT NULL,
  detected_patterns TEXT[],
  recommended_action TEXT,
  assigned_to UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  resolution_notes TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_fraud_alerts_election ON public.fraud_alerts(election_id);
CREATE INDEX idx_fraud_alerts_user ON public.fraud_alerts(user_id);
CREATE INDEX idx_fraud_alerts_severity ON public.fraud_alerts(severity);
CREATE INDEX idx_fraud_alerts_status ON public.fraud_alerts(status);
CREATE INDEX idx_fraud_alerts_created_at ON public.fraud_alerts(created_at DESC);

CREATE TABLE IF NOT EXISTS public.fraud_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pattern_name TEXT NOT NULL UNIQUE,
  pattern_description TEXT,
  detection_rules JSONB NOT NULL,
  severity_threshold INTEGER DEFAULT 70,
  is_active BOOLEAN DEFAULT true,
  detection_count INTEGER DEFAULT 0,
  false_positive_rate NUMERIC(5,4) DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 4. AI ANALYTICS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.ai_analytics_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type TEXT NOT NULL,
  report_data JSONB NOT NULL,
  ai_service public.ai_service_type NOT NULL,
  confidence_score NUMERIC(5,4),
  generated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  valid_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ai_analytics_report_type ON public.ai_analytics_reports(report_type);
CREATE INDEX idx_ai_analytics_created_at ON public.ai_analytics_reports(created_at DESC);

CREATE TABLE IF NOT EXISTS public.predictive_models (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name TEXT NOT NULL UNIQUE,
  model_type TEXT NOT NULL,
  model_config JSONB NOT NULL,
  accuracy_score NUMERIC(5,4),
  training_data_count INTEGER DEFAULT 0,
  last_trained_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. INTELLIGENT RECOMMENDATIONS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.ai_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  recommendation_type public.recommendation_type NOT NULL,
  target_id UUID NOT NULL,
  target_metadata JSONB,
  relevance_score NUMERIC(5,4) NOT NULL,
  ai_reasoning TEXT,
  ai_service public.ai_service_type NOT NULL,
  displayed_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  dismissed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMPTZ
);

CREATE INDEX idx_ai_recommendations_user ON public.ai_recommendations(user_id);
CREATE INDEX idx_ai_recommendations_type ON public.ai_recommendations(recommendation_type);
CREATE INDEX idx_ai_recommendations_score ON public.ai_recommendations(relevance_score DESC);
CREATE INDEX idx_ai_recommendations_created_at ON public.ai_recommendations(created_at DESC);

CREATE TABLE IF NOT EXISTS public.content_moderation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL,
  content_type TEXT NOT NULL,
  content_text TEXT,
  risk_score INTEGER NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
  risk_categories TEXT[],
  ai_service public.ai_service_type NOT NULL,
  moderation_action TEXT,
  reviewed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_content_moderation_content ON public.content_moderation_logs(content_id);
CREATE INDEX idx_content_moderation_risk_score ON public.content_moderation_logs(risk_score DESC);
CREATE INDEX idx_content_moderation_created_at ON public.content_moderation_logs(created_at DESC);

-- ============================================================
-- 6. ROW LEVEL SECURITY POLICIES
-- ============================================================

-- AI Orchestration Logs (Admin only)
ALTER TABLE public.ai_orchestration_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view all AI orchestration logs"
  ON public.ai_orchestration_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admin can insert AI orchestration logs"
  ON public.ai_orchestration_logs FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Fraud Alerts (Admin and assigned investigators)
ALTER TABLE public.fraud_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view all fraud alerts"
  ON public.fraud_alerts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admin can manage fraud alerts"
  ON public.fraud_alerts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Fraud Patterns (Admin only)
ALTER TABLE public.fraud_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can manage fraud patterns"
  ON public.fraud_patterns FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- AI Analytics Reports (Admin only)
ALTER TABLE public.ai_analytics_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view AI analytics reports"
  ON public.ai_analytics_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admin can create AI analytics reports"
  ON public.ai_analytics_reports FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Predictive Models (Admin only)
ALTER TABLE public.predictive_models ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can manage predictive models"
  ON public.predictive_models FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- AI Recommendations (Users see their own)
ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own recommendations"
  ON public.ai_recommendations FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "System can create recommendations"
  ON public.ai_recommendations FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update their own recommendations"
  ON public.ai_recommendations FOR UPDATE
  USING (user_id = auth.uid());

-- Content Moderation Logs (Admin only)
ALTER TABLE public.content_moderation_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view content moderation logs"
  ON public.content_moderation_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can create moderation logs"
  ON public.content_moderation_logs FOR INSERT
  WITH CHECK (true);

-- ============================================================
-- 7. FUNCTIONS
-- ============================================================

-- Function to calculate fraud risk score
CREATE OR REPLACE FUNCTION public.calculate_fraud_risk(
  p_user_id UUID,
  p_election_id UUID
) RETURNS INTEGER AS $$
DECLARE
  v_risk_score INTEGER := 0;
  v_vote_count INTEGER;
  v_account_age_days INTEGER;
BEGIN
  -- Get user vote count
  SELECT COUNT(*) INTO v_vote_count
  FROM public.votes
  WHERE user_id = p_user_id;

  -- Get account age
  SELECT EXTRACT(DAY FROM NOW() - created_at)::INTEGER INTO v_account_age_days
  FROM public.user_profiles
  WHERE id = p_user_id;

  -- Calculate risk score
  IF v_account_age_days < 7 THEN
    v_risk_score := v_risk_score + 30;
  END IF;

  IF v_vote_count > 50 THEN
    v_risk_score := v_risk_score + 20;
  END IF;

  RETURN LEAST(v_risk_score, 100);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to generate AI recommendations
CREATE OR REPLACE FUNCTION public.generate_ai_recommendations(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 10
) RETURNS SETOF public.ai_recommendations AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM public.ai_recommendations
  WHERE user_id = p_user_id
    AND (expires_at IS NULL OR expires_at > NOW())
    AND dismissed_at IS NULL
  ORDER BY relevance_score DESC, created_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 8. TRIGGERS
-- ============================================================

-- Update fraud alert timestamp
CREATE OR REPLACE FUNCTION public.update_fraud_alert_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_fraud_alert_timestamp ON public.fraud_alerts;
CREATE TRIGGER trigger_update_fraud_alert_timestamp
  BEFORE UPDATE ON public.fraud_alerts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_fraud_alert_timestamp();