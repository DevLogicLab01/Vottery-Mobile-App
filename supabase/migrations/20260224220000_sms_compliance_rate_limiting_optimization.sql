-- =====================================================
-- SMS Compliance Manager, Rate Limiting & Queue, OpenAI Optimization Migration
-- Feature 1: SMS Compliance Manager (GDPR/TCPA)
-- Feature 2: SMS Rate Limiting & Queue Management
-- Feature 3: OpenAI SMS Optimization

-- =====================================================
-- FEATURE 1: SMS COMPLIANCE MANAGER TABLES
-- =====================================================

-- SMS Consent Preferences Table
CREATE TABLE IF NOT EXISTS sms_consent_preferences (
  consent_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  phone_number VARCHAR(20) NOT NULL,
  consent_type VARCHAR(50) NOT NULL CHECK (consent_type IN ('marketing', 'transactional', 'alerts')),
  consent_status VARCHAR(20) DEFAULT 'pending' CHECK (consent_status IN ('opted_in', 'opted_out', 'pending')),
  consent_method VARCHAR(50),
  consent_timestamp TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_consent UNIQUE (user_id, consent_type)
);

CREATE INDEX IF NOT EXISTS idx_consent_status ON sms_consent_preferences(consent_status, phone_number);
CREATE INDEX IF NOT EXISTS idx_consent_user ON sms_consent_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_consent_phone ON sms_consent_preferences(phone_number);

-- SMS Suppression List Table
CREATE TABLE IF NOT EXISTS sms_suppression_list (
  suppression_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) NOT NULL UNIQUE,
  suppression_reason VARCHAR(50) NOT NULL CHECK (suppression_reason IN ('opted_out', 'bounced', 'invalid', 'spam_complaint')),
  suppressed_at TIMESTAMPTZ DEFAULT NOW(),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_suppression_phone ON sms_suppression_list(phone_number);
CREATE INDEX IF NOT EXISTS idx_suppression_reason ON sms_suppression_list(suppression_reason);

-- SMS Compliance Audit Table
CREATE TABLE IF NOT EXISTS sms_compliance_audit (
  audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(50) NOT NULL,
  user_id UUID REFERENCES user_profiles(id),
  admin_id UUID REFERENCES user_profiles(id),
  event_details JSONB,
  ip_address INET,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_type_time ON sms_compliance_audit(event_type, timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_user ON sms_compliance_audit(user_id);

-- =====================================================
-- FEATURE 2: SMS RATE LIMITING & QUEUE TABLES
-- =====================================================

-- SMS User Rate Limits Table
CREATE TABLE IF NOT EXISTS sms_user_rate_limits (
  limit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id),
  tier VARCHAR(20) NOT NULL,
  messages_sent INTEGER DEFAULT 0,
  limit_amount INTEGER NOT NULL,
  period_start TIMESTAMPTZ DEFAULT NOW(),
  period_end TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_user ON sms_user_rate_limits(user_id, period_end);
CREATE INDEX IF NOT EXISTS idx_rate_limits_period ON sms_user_rate_limits(period_end);

-- SMS Provider Rate Limits Table
CREATE TABLE IF NOT EXISTS sms_provider_rate_limits (
  provider_rate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider VARCHAR(20) NOT NULL CHECK (provider IN ('telnyx', 'twilio')),
  messages_sent_current_second INTEGER DEFAULT 0,
  limit_per_second INTEGER NOT NULL,
  window_start TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_provider_rate ON sms_provider_rate_limits(provider, window_start);

-- SMS Queue Table
CREATE TABLE IF NOT EXISTS sms_queue (
  queue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id),
  recipient_phone VARCHAR(20) NOT NULL,
  message_body TEXT NOT NULL,
  message_category VARCHAR(50),
  priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('critical', 'high', 'normal')),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'sent', 'failed')),
  enqueued_at TIMESTAMPTZ DEFAULT NOW(),
  scheduled_for TIMESTAMPTZ DEFAULT NOW(),
  sent_at TIMESTAMPTZ,
  retry_count INTEGER DEFAULT 0,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_queue_status ON sms_queue(status, priority, scheduled_for);
CREATE INDEX IF NOT EXISTS idx_queue_scheduled ON sms_queue(scheduled_for) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_queue_user ON sms_queue(user_id);

-- =====================================================
-- FEATURE 3: OPENAI SMS OPTIMIZATION TABLES
-- =====================================================

-- SMS Optimization History Table
CREATE TABLE IF NOT EXISTS sms_optimization_history (
  optimization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  original_message TEXT NOT NULL,
  optimized_message TEXT NOT NULL,
  optimization_type VARCHAR(50) NOT NULL CHECK (optimization_type IN ('length', 'personalization', 'engagement', 'tone')),
  character_savings INTEGER,
  user_id UUID REFERENCES user_profiles(id),
  optimized_at TIMESTAMPTZ DEFAULT NOW(),
  was_sent BOOLEAN DEFAULT false,
  performance_metrics JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_optimization_type ON sms_optimization_history(optimization_type, optimized_at);
CREATE INDEX IF NOT EXISTS idx_optimization_user ON sms_optimization_history(user_id);

-- OpenAI Optimization Analytics Table
CREATE TABLE IF NOT EXISTS openai_optimization_analytics (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  total_optimizations INTEGER DEFAULT 0,
  avg_character_reduction INTEGER,
  total_api_calls INTEGER,
  total_cost DECIMAL(10, 4),
  avg_engagement_improvement DECIMAL(5, 2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_analytics_date ON openai_optimization_analytics(date);

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Check if phone number is suppressed
CREATE OR REPLACE FUNCTION is_phone_suppressed(p_phone_number VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM sms_suppression_list
    WHERE phone_number = p_phone_number
  );
END;
$$ LANGUAGE plpgsql;

-- Check user rate limit
CREATE OR REPLACE FUNCTION check_user_rate_limit(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_limit_record RECORD;
BEGIN
  SELECT * INTO v_limit_record
  FROM sms_user_rate_limits
  WHERE user_id = p_user_id
    AND period_end > NOW()
  ORDER BY period_end DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN TRUE;
  END IF;

  RETURN v_limit_record.messages_sent < v_limit_record.limit_amount;
END;
$$ LANGUAGE plpgsql;

-- Increment user rate limit counter
CREATE OR REPLACE FUNCTION increment_user_rate_limit(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE sms_user_rate_limits
  SET messages_sent = messages_sent + 1,
      updated_at = NOW()
  WHERE user_id = p_user_id
    AND period_end > NOW();
END;
$$ LANGUAGE plpgsql;

-- Log compliance event
CREATE OR REPLACE FUNCTION log_compliance_event(
  p_event_type VARCHAR,
  p_user_id UUID,
  p_admin_id UUID,
  p_event_details JSONB,
  p_ip_address INET
)
RETURNS UUID AS $$
DECLARE
  v_audit_id UUID;
BEGIN
  INSERT INTO sms_compliance_audit (
    event_type,
    user_id,
    admin_id,
    event_details,
    ip_address
  ) VALUES (
    p_event_type,
    p_user_id,
    p_admin_id,
    p_event_details,
    p_ip_address
  ) RETURNING audit_id INTO v_audit_id;

  RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

-- SMS Consent Preferences RLS
ALTER TABLE sms_consent_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own consent preferences"
  ON sms_consent_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own consent preferences"
  ON sms_consent_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own consent preferences"
  ON sms_consent_preferences FOR UPDATE
  USING (auth.uid() = user_id);

-- SMS Suppression List RLS
ALTER TABLE sms_suppression_list ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service can manage suppression list"
  ON sms_suppression_list FOR ALL
  USING (true);

-- SMS Compliance Audit RLS
ALTER TABLE sms_compliance_audit ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own audit logs"
  ON sms_compliance_audit FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service can insert audit logs"
  ON sms_compliance_audit FOR INSERT
  WITH CHECK (true);

-- SMS User Rate Limits RLS
ALTER TABLE sms_user_rate_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own rate limits"
  ON sms_user_rate_limits FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service can manage rate limits"
  ON sms_user_rate_limits FOR ALL
  USING (true);

-- SMS Provider Rate Limits RLS
ALTER TABLE sms_provider_rate_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service can manage provider rate limits"
  ON sms_provider_rate_limits FOR ALL
  USING (true);

-- SMS Queue RLS
ALTER TABLE sms_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own queued messages"
  ON sms_queue FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service can manage queue"
  ON sms_queue FOR ALL
  USING (true);

-- SMS Optimization History RLS
ALTER TABLE sms_optimization_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own optimization history"
  ON sms_optimization_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Service can manage optimization history"
  ON sms_optimization_history FOR ALL
  USING (true);

-- OpenAI Optimization Analytics RLS
ALTER TABLE openai_optimization_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service can manage optimization analytics"
  ON openai_optimization_analytics FOR ALL
  USING (true);