-- =====================================================
-- WEBHOOK INTEGRATION SYSTEM + PERPLEXITY 90-DAY FORECASTING + FREE-TEXT MCQ ANSWERS
-- =====================================================

-- Lottery event types enum
DO $$ BEGIN
  CREATE TYPE lottery_event_type AS ENUM (
    'vote.cast',
    'draw.completed',
    'winner.announced',
    'ticket.generated',
    'prize.distributed'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Webhook delivery status enum
DO $$ BEGIN
  CREATE TYPE webhook_delivery_status AS ENUM (
    'pending',
    'success',
    'failed',
    'retrying'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Forecast period enum
DO $$ BEGIN
  CREATE TYPE forecast_period AS ENUM (
    'thirty_days',
    'sixty_days',
    'ninety_days'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- WEBHOOK CONFIGURATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS webhook_configurations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  webhook_url TEXT NOT NULL,
  event_types lottery_event_type[] NOT NULL DEFAULT ARRAY['vote.cast']::lottery_event_type[],
  is_active BOOLEAN NOT NULL DEFAULT true,
  secret_key TEXT NOT NULL,
  description TEXT,
  retry_enabled BOOLEAN NOT NULL DEFAULT true,
  max_retries INTEGER NOT NULL DEFAULT 5,
  timeout_seconds INTEGER NOT NULL DEFAULT 30,
  custom_headers JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhook_configurations_user_id ON webhook_configurations(user_id);
CREATE INDEX IF NOT EXISTS idx_webhook_configurations_active ON webhook_configurations(is_active) WHERE is_active = true;

-- =====================================================
-- WEBHOOK DELIVERY LOGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS webhook_delivery_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  webhook_config_id UUID NOT NULL REFERENCES webhook_configurations(id) ON DELETE CASCADE,
  event_type lottery_event_type NOT NULL,
  payload JSONB NOT NULL,
  delivery_status webhook_delivery_status NOT NULL DEFAULT 'pending',
  http_status_code INTEGER,
  response_body TEXT,
  error_message TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  next_retry_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_webhook_delivery_logs_config_id ON webhook_delivery_logs(webhook_config_id);
CREATE INDEX IF NOT EXISTS idx_webhook_delivery_logs_status ON webhook_delivery_logs(delivery_status);
CREATE INDEX IF NOT EXISTS idx_webhook_delivery_logs_retry ON webhook_delivery_logs(next_retry_at) WHERE delivery_status = 'retrying';
CREATE INDEX IF NOT EXISTS idx_webhook_delivery_logs_created_at ON webhook_delivery_logs(created_at DESC);

-- =====================================================
-- FREE-TEXT ANSWERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS free_text_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mcq_id UUID NOT NULL REFERENCES election_mcqs(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
  answer_text TEXT NOT NULL,
  character_count INTEGER NOT NULL,
  sentiment_score DECIMAL(5,2),
  sentiment_label TEXT,
  themes JSONB DEFAULT '[]'::jsonb,
  moderation_flag BOOLEAN NOT NULL DEFAULT false,
  moderation_reason TEXT,
  ai_analysis JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_free_text_answers_mcq_id ON free_text_answers(mcq_id);
CREATE INDEX IF NOT EXISTS idx_free_text_answers_voter_id ON free_text_answers(voter_id);
CREATE INDEX IF NOT EXISTS idx_free_text_answers_election_id ON free_text_answers(election_id);
CREATE INDEX IF NOT EXISTS idx_free_text_answers_moderation ON free_text_answers(moderation_flag) WHERE moderation_flag = true;
CREATE INDEX IF NOT EXISTS idx_free_text_answers_created_at ON free_text_answers(created_at DESC);

-- =====================================================
-- THREAT FORECASTING REPORTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS threat_forecasting_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  forecast_period forecast_period NOT NULL,
  zones TEXT[] NOT NULL,
  threat_level TEXT NOT NULL,
  confidence_score DECIMAL(5,2) NOT NULL,
  predicted_patterns JSONB NOT NULL DEFAULT '{}'::jsonb,
  seasonal_anomalies JSONB DEFAULT '[]'::jsonb,
  vulnerability_analysis JSONB DEFAULT '{}'::jsonb,
  recommendations JSONB DEFAULT '[]'::jsonb,
  generated_by TEXT NOT NULL DEFAULT 'perplexity',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_threat_forecasting_period ON threat_forecasting_reports(forecast_period);
CREATE INDEX IF NOT EXISTS idx_threat_forecasting_created_at ON threat_forecasting_reports(created_at DESC);

-- =====================================================
-- CROSS-ZONE FRAUD PATTERNS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS cross_zone_fraud_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pattern_type TEXT NOT NULL,
  affected_zones TEXT[] NOT NULL,
  correlation_score DECIMAL(5,2) NOT NULL,
  detection_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  pattern_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  synchronized_events JSONB DEFAULT '[]'::jsonb,
  risk_level TEXT NOT NULL,
  alert_sent BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cross_zone_fraud_zones ON cross_zone_fraud_patterns USING GIN(affected_zones);
CREATE INDEX IF NOT EXISTS idx_cross_zone_fraud_risk ON cross_zone_fraud_patterns(risk_level);
CREATE INDEX IF NOT EXISTS idx_cross_zone_fraud_created_at ON cross_zone_fraud_patterns(created_at DESC);

-- =====================================================
-- FUNCTION: Calculate next retry time with exponential backoff
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_next_retry_time(attempt_count INTEGER)
RETURNS TIMESTAMPTZ AS $$
BEGIN
  RETURN CASE
    WHEN attempt_count = 1 THEN NOW() + INTERVAL '1 minute'
    WHEN attempt_count = 2 THEN NOW() + INTERVAL '5 minutes'
    WHEN attempt_count = 3 THEN NOW() + INTERVAL '15 minutes'
    WHEN attempt_count = 4 THEN NOW() + INTERVAL '1 hour'
    WHEN attempt_count = 5 THEN NOW() + INTERVAL '6 hours'
    ELSE NULL
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- FUNCTION: Get webhook delivery analytics
-- =====================================================
CREATE OR REPLACE FUNCTION get_webhook_delivery_analytics(
  p_webhook_config_id UUID,
  p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
  total_deliveries BIGINT,
  successful_deliveries BIGINT,
  failed_deliveries BIGINT,
  success_rate DECIMAL,
  average_response_time DECIMAL,
  retry_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_deliveries,
    COUNT(*) FILTER (WHERE delivery_status = 'success')::BIGINT AS successful_deliveries,
    COUNT(*) FILTER (WHERE delivery_status = 'failed')::BIGINT AS failed_deliveries,
    ROUND(
      (COUNT(*) FILTER (WHERE delivery_status = 'success')::DECIMAL / NULLIF(COUNT(*), 0) * 100),
      2
    ) AS success_rate,
    ROUND(
      AVG(EXTRACT(EPOCH FROM (delivered_at - created_at)))::DECIMAL,
      2
    ) AS average_response_time,
    SUM(attempt_count - 1)::BIGINT AS retry_count
  FROM webhook_delivery_logs
  WHERE webhook_config_id = p_webhook_config_id
    AND created_at >= NOW() - (p_days || ' days')::INTERVAL;
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- FUNCTION: Get free-text answer analytics
-- =====================================================
CREATE OR REPLACE FUNCTION get_free_text_analytics(
  p_election_id UUID,
  p_mcq_id UUID DEFAULT NULL
)
RETURNS TABLE (
  total_responses BIGINT,
  average_character_count DECIMAL,
  sentiment_distribution JSONB,
  common_themes JSONB,
  moderation_flags BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*)::BIGINT AS total_responses,
    ROUND(AVG(character_count)::DECIMAL, 2) AS average_character_count,
    jsonb_build_object(
      'positive', COUNT(*) FILTER (WHERE sentiment_label = 'positive'),
      'neutral', COUNT(*) FILTER (WHERE sentiment_label = 'neutral'),
      'negative', COUNT(*) FILTER (WHERE sentiment_label = 'negative')
    ) AS sentiment_distribution,
    (
      SELECT jsonb_agg(DISTINCT theme)
      FROM free_text_answers,
      jsonb_array_elements_text(themes) AS theme
      WHERE election_id = p_election_id
        AND (p_mcq_id IS NULL OR mcq_id = p_mcq_id)
    ) AS common_themes,
    COUNT(*) FILTER (WHERE moderation_flag = true)::BIGINT AS moderation_flags
  FROM free_text_answers
  WHERE election_id = p_election_id
    AND (p_mcq_id IS NULL OR mcq_id = p_mcq_id);
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Webhook configurations: Users can manage their own webhooks
ALTER TABLE webhook_configurations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own webhook configurations"
  ON webhook_configurations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own webhook configurations"
  ON webhook_configurations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own webhook configurations"
  ON webhook_configurations FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own webhook configurations"
  ON webhook_configurations FOR DELETE
  USING (auth.uid() = user_id);

-- Webhook delivery logs: Users can view logs for their webhooks
ALTER TABLE webhook_delivery_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their webhook delivery logs"
  ON webhook_delivery_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM webhook_configurations
      WHERE webhook_configurations.id = webhook_delivery_logs.webhook_config_id
        AND webhook_configurations.user_id = auth.uid()
    )
  );

-- Free-text answers: Voters own their answers, election creators can view all
ALTER TABLE free_text_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Voters can view their own free-text answers"
  ON free_text_answers FOR SELECT
  USING (auth.uid() = voter_id);

CREATE POLICY "Election creators can view all free-text answers for their elections"
  ON free_text_answers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM elections
      WHERE elections.id = free_text_answers.election_id
        AND elections.created_by = auth.uid()
    )
  );

CREATE POLICY "Voters can insert their own free-text answers"
  ON free_text_answers FOR INSERT
  WITH CHECK (auth.uid() = voter_id);

CREATE POLICY "Voters can update their own free-text answers"
  ON free_text_answers FOR UPDATE
  USING (auth.uid() = voter_id);

-- Threat forecasting reports: Admin-only access
ALTER TABLE threat_forecasting_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view threat forecasting reports"
  ON threat_forecasting_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
        AND ar.role_name = 'admin'
        AND ura.is_active = true
    )
  );

CREATE POLICY "System can insert threat forecasting reports"
  ON threat_forecasting_reports FOR INSERT
  WITH CHECK (true);

-- Cross-zone fraud patterns: Admin-only access
ALTER TABLE cross_zone_fraud_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view cross-zone fraud patterns"
  ON cross_zone_fraud_patterns FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
        AND ar.role_name = 'admin'
        AND ura.is_active = true
    )
  );

CREATE POLICY "System can insert cross-zone fraud patterns"
  ON cross_zone_fraud_patterns FOR INSERT
  WITH CHECK (true);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update updated_at timestamp for webhook_configurations
CREATE OR REPLACE FUNCTION update_webhook_configurations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_webhook_configurations_updated_at ON webhook_configurations;
CREATE TRIGGER trigger_update_webhook_configurations_updated_at
  BEFORE UPDATE ON webhook_configurations
  FOR EACH ROW
  EXECUTE FUNCTION update_webhook_configurations_updated_at();

-- Update updated_at timestamp for free_text_answers
CREATE OR REPLACE FUNCTION update_free_text_answers_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_free_text_answers_updated_at ON free_text_answers;
CREATE TRIGGER trigger_update_free_text_answers_updated_at
  BEFORE UPDATE ON free_text_answers
  FOR EACH ROW
  EXECUTE FUNCTION update_free_text_answers_updated_at();