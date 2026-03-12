-- =====================================================
-- SMS Infrastructure Enhancements Migration
-- Migration: 20260224200000
-- Features: Webhook Events, Bounce List, Alert Templates, Analytics
-- =====================================================

-- =====================================================
-- SECTION 1: SMS WEBHOOK EVENTS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sms_webhook_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider VARCHAR(20) NOT NULL CHECK (provider IN ('telnyx', 'twilio')),
  event_type VARCHAR(50) NOT NULL,
  provider_message_id VARCHAR(100),
  event_payload JSONB NOT NULL DEFAULT '{}'::JSONB,
  received_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  processed BOOLEAN DEFAULT false,
  processed_at TIMESTAMPTZ,
  error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_webhook_events_provider ON public.sms_webhook_events(provider, event_type, received_at DESC);
CREATE INDEX IF NOT EXISTS idx_webhook_events_message_id ON public.sms_webhook_events(provider_message_id);
CREATE INDEX IF NOT EXISTS idx_webhook_events_processed ON public.sms_webhook_events(processed, received_at DESC) WHERE processed = false;

-- =====================================================
-- SECTION 2: SMS BOUNCE LIST
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sms_bounce_list (
  bounce_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number VARCHAR(20) NOT NULL UNIQUE,
  bounce_type VARCHAR(20) NOT NULL CHECK (bounce_type IN ('hard_bounce', 'soft_bounce')),
  bounce_reason TEXT,
  first_bounced_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  last_bounced_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  bounce_count INTEGER DEFAULT 1,
  is_suppressed BOOLEAN DEFAULT true,
  suppressed_until TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_bounce_phone ON public.sms_bounce_list(phone_number);
CREATE INDEX IF NOT EXISTS idx_bounce_suppressed ON public.sms_bounce_list(is_suppressed, suppressed_until);

-- =====================================================
-- SECTION 3: SMS ALERT TEMPLATES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sms_alert_templates (
  template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_name VARCHAR(200) NOT NULL,
  category VARCHAR(50) NOT NULL CHECK (category IN (
    'fraud',
    'system_outage',
    'performance_degradation',
    'anomaly_detection',
    'security',
    'operational'
  )),
  message_body TEXT NOT NULL,
  variables JSONB DEFAULT '[]'::JSONB,
  priority VARCHAR(20) NOT NULL CHECK (priority IN ('critical', 'high', 'medium', 'low')),
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_templates_category ON public.sms_alert_templates(category, is_active);
CREATE INDEX IF NOT EXISTS idx_templates_priority ON public.sms_alert_templates(priority, is_active);

-- =====================================================
-- SECTION 4: SMS TEMPLATE VERSIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sms_template_versions (
  version_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES public.sms_alert_templates(template_id) ON DELETE CASCADE,
  version_number INTEGER NOT NULL,
  message_body TEXT NOT NULL,
  variables JSONB DEFAULT '[]'::JSONB,
  changed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  changed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  change_reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_versions_template ON public.sms_template_versions(template_id, version_number DESC);

-- =====================================================
-- SECTION 5: SMS ALERTS SENT
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sms_alerts_sent (
  alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID REFERENCES public.sms_alert_templates(template_id) ON DELETE SET NULL,
  recipient_phone VARCHAR(20) NOT NULL,
  message_body TEXT NOT NULL,
  variables_used JSONB DEFAULT '{}'::JSONB,
  provider VARCHAR(20) NOT NULL CHECK (provider IN ('telnyx', 'twilio')),
  delivery_status VARCHAR(20) DEFAULT 'pending',
  provider_message_id VARCHAR(100),
  sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  delivered_at TIMESTAMPTZ,
  error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_alerts_sent_template ON public.sms_alerts_sent(template_id, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_sent_status ON public.sms_alerts_sent(delivery_status, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_sent_provider ON public.sms_alerts_sent(provider, sent_at DESC);

-- =====================================================
-- SECTION 6: SMS DELIVERY ANALYTICS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sms_delivery_analytics (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  time_period TIMESTAMPTZ NOT NULL,
  provider VARCHAR(20) NOT NULL CHECK (provider IN ('telnyx', 'twilio')),
  messages_sent INTEGER DEFAULT 0,
  messages_delivered INTEGER DEFAULT 0,
  messages_failed INTEGER DEFAULT 0,
  messages_bounced INTEGER DEFAULT 0,
  delivery_rate DECIMAL(5, 2),
  bounce_rate DECIMAL(5, 2),
  avg_delivery_latency_ms INTEGER,
  p95_delivery_latency_ms INTEGER,
  p99_delivery_latency_ms INTEGER,
  calculated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_analytics_time ON public.sms_delivery_analytics(time_period DESC, provider);
CREATE INDEX IF NOT EXISTS idx_analytics_provider ON public.sms_delivery_analytics(provider, time_period DESC);

-- =====================================================
-- SECTION 7: SMS WEBHOOK ANALYTICS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sms_webhook_analytics (
  webhook_analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider VARCHAR(20) NOT NULL CHECK (provider IN ('telnyx', 'twilio')),
  date DATE NOT NULL,
  total_webhooks_received INTEGER DEFAULT 0,
  successful_webhooks INTEGER DEFAULT 0,
  failed_webhooks INTEGER DEFAULT 0,
  avg_processing_time_ms INTEGER,
  calculated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_webhook_analytics ON public.sms_webhook_analytics(provider, date DESC);

-- =====================================================
-- SECTION 8: SEED DATA - ALERT TEMPLATES
-- =====================================================

INSERT INTO public.sms_alert_templates (template_name, category, message_body, variables, priority) VALUES
('Fraud Alert', 'fraud', 'Alert: Suspicious activity detected on {carousel_type}. Confidence: {confidence}%. User: {user_id}. Investigate: {dashboard_url}', 
  '[{"name": "carousel_type", "type": "string", "description": "Type of carousel"}, {"name": "confidence", "type": "percentage", "description": "Fraud confidence score"}, {"name": "user_id", "type": "string", "description": "User ID"}, {"name": "dashboard_url", "type": "string", "description": "Investigation dashboard URL"}]'::JSONB, 
  'critical'),
('High Value Transaction', 'fraud', 'Transaction of ${amount} flagged. Review immediately at {review_url}', 
  '[{"name": "amount", "type": "currency", "description": "Transaction amount"}, {"name": "review_url", "type": "string", "description": "Review URL"}]'::JSONB, 
  'high'),
('System Down', 'system_outage', '{system_name} is offline. Affected users: {user_count}. ETA: {eta_minutes} min.', 
  '[{"name": "system_name", "type": "string", "description": "System name"}, {"name": "user_count", "type": "number", "description": "Affected user count"}, {"name": "eta_minutes", "type": "number", "description": "Estimated time to recovery"}]'::JSONB, 
  'critical'),
('Database Outage', 'system_outage', 'Database connection lost. Services impacted: {services_list}. Status: {status_url}', 
  '[{"name": "services_list", "type": "string", "description": "Comma-separated services"}, {"name": "status_url", "type": "string", "description": "Status page URL"}]'::JSONB, 
  'critical'),
('Performance Drop', 'performance_degradation', '{metric_name} degraded by {percentage}%. Current: {current_value}. Baseline: {baseline_value}.', 
  '[{"name": "metric_name", "type": "string", "description": "Metric name"}, {"name": "percentage", "type": "percentage", "description": "Degradation percentage"}, {"name": "current_value", "type": "string", "description": "Current value"}, {"name": "baseline_value", "type": "string", "description": "Baseline value"}]'::JSONB, 
  'high'),
('High Latency', 'performance_degradation', '{system_name} latency increased to {latency_ms}ms. Threshold: {threshold_ms}ms.', 
  '[{"name": "system_name", "type": "string", "description": "System name"}, {"name": "latency_ms", "type": "number", "description": "Current latency"}, {"name": "threshold_ms", "type": "number", "description": "Threshold latency"}]'::JSONB, 
  'medium'),
('Anomaly Detected', 'anomaly_detection', 'Anomaly in {metric_name}. Deviation: {deviation}%. Likely cause: {cause}.', 
  '[{"name": "metric_name", "type": "string", "description": "Metric name"}, {"name": "deviation", "type": "percentage", "description": "Deviation percentage"}, {"name": "cause", "type": "string", "description": "Likely cause"}]'::JSONB, 
  'medium'),
('Unusual Pattern', 'anomaly_detection', 'Unusual activity pattern detected. System: {system_name}. Score: {score}.', 
  '[{"name": "system_name", "type": "string", "description": "System name"}, {"name": "score", "type": "number", "description": "Anomaly score"}]'::JSONB, 
  'low')
ON CONFLICT DO NOTHING;

-- =====================================================
-- SECTION 9: FUNCTIONS
-- =====================================================

-- Function to calculate delivery rate
CREATE OR REPLACE FUNCTION public.calculate_delivery_rate(
  target_provider VARCHAR(20),
  time_window_hours INTEGER DEFAULT 24
)
RETURNS DECIMAL(5, 2)
LANGUAGE plpgsql
AS $$
DECLARE
  total_sent INTEGER;
  total_delivered INTEGER;
  delivery_rate DECIMAL(5, 2);
BEGIN
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE delivery_status = 'delivered')
  INTO total_sent, total_delivered
  FROM public.sms_delivery_log
  WHERE provider_used = target_provider
    AND sent_at >= NOW() - (time_window_hours || ' hours')::INTERVAL;

  IF total_sent = 0 THEN
    RETURN 0.0;
  END IF;

  delivery_rate := (total_delivered::DECIMAL / total_sent::DECIMAL * 100);
  RETURN ROUND(delivery_rate, 2);
END;
$$;

-- Function to check bounce list
CREATE OR REPLACE FUNCTION public.is_phone_bounced(target_phone VARCHAR(20))
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  is_bounced BOOLEAN;
BEGIN
  SELECT EXISTS(
    SELECT 1 FROM public.sms_bounce_list
    WHERE phone_number = target_phone
      AND is_suppressed = true
      AND (suppressed_until IS NULL OR suppressed_until > NOW())
  ) INTO is_bounced;

  RETURN is_bounced;
END;
$$;

-- =====================================================
-- SECTION 10: RLS POLICIES
-- =====================================================

ALTER TABLE public.sms_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_bounce_list ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_alert_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_template_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_alerts_sent ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_delivery_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_webhook_analytics ENABLE ROW LEVEL SECURITY;

-- Admin-only access for webhook events
CREATE POLICY "Admin read access to webhook events" ON public.sms_webhook_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for bounce list
CREATE POLICY "Admin full access to bounce list" ON public.sms_bounce_list
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for alert templates
CREATE POLICY "Admin full access to alert templates" ON public.sms_alert_templates
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for template versions
CREATE POLICY "Admin read access to template versions" ON public.sms_template_versions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for alerts sent
CREATE POLICY "Admin read access to alerts sent" ON public.sms_alerts_sent
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for delivery analytics
CREATE POLICY "Admin read access to delivery analytics" ON public.sms_delivery_analytics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for webhook analytics
CREATE POLICY "Admin read access to webhook analytics" ON public.sms_webhook_analytics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );