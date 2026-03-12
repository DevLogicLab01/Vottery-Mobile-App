-- AI Failover Engine Comprehensive Database Schema
-- Supports instant detection, zero-downtime switching, exponential backoff, and cost tracking

-- Drop existing objects if they exist (idempotent)
DROP TABLE IF EXISTS ai_service_health_log CASCADE;
DROP TABLE IF EXISTS ai_service_costs CASCADE;
DROP TABLE IF EXISTS failover_events CASCADE;
DROP TABLE IF EXISTS retry_attempts_log CASCADE;
DROP TABLE IF EXISTS service_router_config CASCADE;
DROP TABLE IF EXISTS ai_service_notifications CASCADE;
DROP TABLE IF EXISTS gemini_warmup_status CASCADE;

-- AI Service Health Log
-- Tracks continuous health checks every 2 seconds for all AI services
CREATE TABLE ai_service_health_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name VARCHAR(50) NOT NULL CHECK (service_name IN ('openai', 'anthropic', 'perplexity', 'gemini')),
  status VARCHAR(20) NOT NULL CHECK (status IN ('healthy', 'degraded', 'down')),
  response_time_ms INTEGER NOT NULL,
  consecutive_failures INTEGER DEFAULT 0,
  health_score DECIMAL(5,2) DEFAULT 100.00,
  error_message TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_health_log_service_time ON ai_service_health_log(service_name, timestamp DESC);
CREATE INDEX idx_health_log_status ON ai_service_health_log(status, timestamp DESC);

-- AI Service Costs
-- Tracks every API call with token usage and cost calculation
CREATE TABLE ai_service_costs (
  cost_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name VARCHAR(50) NOT NULL CHECK (service_name IN ('openai', 'anthropic', 'perplexity', 'gemini')),
  operation_type VARCHAR(50) NOT NULL,
  model_name VARCHAR(100) NOT NULL,
  input_tokens INTEGER NOT NULL DEFAULT 0,
  output_tokens INTEGER NOT NULL DEFAULT 0,
  cost_usd DECIMAL(10,4) NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  request_id UUID,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_costs_service_time ON ai_service_costs(service_name, timestamp DESC);
CREATE INDEX idx_costs_user ON ai_service_costs(user_id, timestamp DESC);
CREATE INDEX idx_costs_operation ON ai_service_costs(operation_type, timestamp DESC);

-- Failover Events
-- Records every failover event with trigger reason and recovery tracking
CREATE TABLE failover_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  failed_service VARCHAR(50) NOT NULL,
  backup_service VARCHAR(50) NOT NULL,
  trigger_reason TEXT NOT NULL,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  recovered_at TIMESTAMPTZ,
  requests_affected INTEGER DEFAULT 0,
  cost_impact DECIMAL(10,2) DEFAULT 0.00,
  recovery_duration_seconds INTEGER,
  notification_sent BOOLEAN DEFAULT FALSE
);

CREATE INDEX idx_failover_events_time ON failover_events(detected_at DESC);
CREATE INDEX idx_failover_events_service ON failover_events(failed_service, detected_at DESC);

-- Retry Attempts Log
-- Tracks exponential backoff retry attempts with delay and error details
CREATE TABLE retry_attempts_log (
  attempt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_type VARCHAR(50) NOT NULL,
  service_name VARCHAR(50) NOT NULL,
  attempt_number INTEGER NOT NULL,
  delay_ms INTEGER NOT NULL,
  error_message TEXT,
  success BOOLEAN DEFAULT FALSE,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_retry_log_service_time ON retry_attempts_log(service_name, timestamp DESC);
CREATE INDEX idx_retry_log_operation ON retry_attempts_log(operation_type, timestamp DESC);

-- Service Router Configuration
-- Manages traffic routing preferences and fallback chains
CREATE TABLE service_router_config (
  config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_type VARCHAR(50) NOT NULL UNIQUE,
  preferred_service VARCHAR(50) NOT NULL,
  fallback_chain JSONB NOT NULL DEFAULT '["gemini"]'::jsonb,
  circuit_breaker_threshold INTEGER DEFAULT 3,
  timeout_ms INTEGER DEFAULT 2000,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE INDEX idx_router_config_operation ON service_router_config(operation_type);

-- AI Service Notifications
-- Tracks multi-channel notifications (Slack, Email, SMS, Push)
CREATE TABLE ai_service_notifications (
  notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('failover', 'recovery', 'degraded', 'cost_alert', 'critical')),
  service_name VARCHAR(50),
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  message TEXT NOT NULL,
  channels JSONB NOT NULL DEFAULT '[]'::jsonb,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  delivery_status JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_notifications_time ON ai_service_notifications(sent_at DESC);
CREATE INDEX idx_notifications_severity ON ai_service_notifications(severity, sent_at DESC);

-- Gemini Warmup Status
-- Tracks Gemini connection pool and pre-authentication status
CREATE TABLE gemini_warmup_status (
  status_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  connection_pool_size INTEGER DEFAULT 1,
  authenticated BOOLEAN DEFAULT FALSE,
  last_health_ping TIMESTAMPTZ,
  avg_activation_latency_ms INTEGER DEFAULT 0,
  total_activations INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default Gemini warmup status
INSERT INTO gemini_warmup_status (connection_pool_size, authenticated, last_health_ping, updated_at)
VALUES (1, TRUE, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- Insert default router configurations
INSERT INTO service_router_config (operation_type, preferred_service, fallback_chain, updated_at)
VALUES 
  ('text_generation', 'openai', '["anthropic", "gemini"]'::jsonb, NOW()),
  ('chat_completion', 'anthropic', '["openai", "gemini"]'::jsonb, NOW()),
  ('embeddings', 'openai', '["gemini"]'::jsonb, NOW()),
  ('image_analysis', 'gemini', '["openai"]'::jsonb, NOW()),
  ('semantic_search', 'perplexity', '["gemini", "openai"]'::jsonb, NOW())
ON CONFLICT (operation_type) DO NOTHING;

-- RLS Policies

-- Health Log: Admins can view all, users can view aggregated stats
ALTER TABLE ai_service_health_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all health logs"
ON ai_service_health_log FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.raw_user_meta_data->>'role' = 'admin'
  )
);

-- Costs: Admins view all, users view their own attributed costs
ALTER TABLE ai_service_costs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all costs"
ON ai_service_costs FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.raw_user_meta_data->>'role' = 'admin'
  )
);

CREATE POLICY "Users can view their own costs"
ON ai_service_costs FOR SELECT
USING (user_id = auth.uid());

-- Failover Events: Admin only
ALTER TABLE failover_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage failover events"
ON failover_events FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.raw_user_meta_data->>'role' = 'admin'
  )
);

-- Retry Attempts: Admin only
ALTER TABLE retry_attempts_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view retry logs"
ON retry_attempts_log FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.raw_user_meta_data->>'role' = 'admin'
  )
);

-- Router Config: Admin only
ALTER TABLE service_router_config ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage router config"
ON service_router_config FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.raw_user_meta_data->>'role' = 'admin'
  )
);

-- Notifications: Admin only
ALTER TABLE ai_service_notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view notifications"
ON ai_service_notifications FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.raw_user_meta_data->>'role' = 'admin'
  )
);

-- Gemini Warmup: Admin only
ALTER TABLE gemini_warmup_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage Gemini warmup"
ON gemini_warmup_status FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM auth.users
    WHERE auth.users.id = auth.uid()
    AND auth.users.raw_user_meta_data->>'role' = 'admin'
  )
);

-- Functions for cost aggregation

CREATE OR REPLACE FUNCTION get_daily_cost_summary(target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
  service_name VARCHAR,
  total_cost DECIMAL,
  request_count BIGINT,
  avg_cost DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    aisc.service_name,
    SUM(aisc.cost_usd) as total_cost,
    COUNT(*) as request_count,
    AVG(aisc.cost_usd) as avg_cost
  FROM ai_service_costs aisc
  WHERE DATE(aisc.timestamp) = target_date
  GROUP BY aisc.service_name
  ORDER BY total_cost DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_service_health_score(target_service VARCHAR, time_window_minutes INTEGER DEFAULT 5)
RETURNS DECIMAL AS $$
DECLARE
  health_score DECIMAL;
BEGIN
  SELECT 
    CASE 
      WHEN COUNT(*) = 0 THEN 100.00
      ELSE (COUNT(*) FILTER (WHERE status = 'healthy')::DECIMAL / COUNT(*) * 100)
    END
  INTO health_score
  FROM ai_service_health_log
  WHERE service_name = target_service
    AND timestamp >= NOW() - (time_window_minutes || ' minutes')::INTERVAL;
  
  RETURN COALESCE(health_score, 100.00);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update recovery duration on failover recovery
CREATE OR REPLACE FUNCTION update_failover_recovery()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.recovered_at IS NOT NULL AND OLD.recovered_at IS NULL THEN
    NEW.recovery_duration_seconds := EXTRACT(EPOCH FROM (NEW.recovered_at - NEW.detected_at))::INTEGER;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_failover_recovery
BEFORE UPDATE ON failover_events
FOR EACH ROW
EXECUTE FUNCTION update_failover_recovery();