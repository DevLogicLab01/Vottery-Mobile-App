-- =============================================
-- Enhanced Fraud Investigation Workflows
-- Unified Incident Management
-- Twilio SMS Emergency Alerts
-- Migration: 20260223010000
-- =============================================

-- Investigation actions audit log
CREATE TABLE IF NOT EXISTS public.investigation_actions_log (
  action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  investigation_id UUID REFERENCES public.fraud_investigations(investigation_id) ON DELETE CASCADE,
  action_type VARCHAR(100) NOT NULL,
  action_description TEXT NOT NULL,
  performed_by UUID,
  affected_entities JSONB DEFAULT '[]'::jsonb,
  action_result VARCHAR(50) DEFAULT 'success' CHECK (action_result IN ('success', 'failed', 'partial')),
  error_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_investigation_actions_investigation ON public.investigation_actions_log(investigation_id);
CREATE INDEX IF NOT EXISTS idx_investigation_actions_performed_by ON public.investigation_actions_log(performed_by) WHERE performed_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_investigation_actions_type ON public.investigation_actions_log(action_type);
CREATE INDEX IF NOT EXISTS idx_investigation_actions_performed_at ON public.investigation_actions_log(performed_at DESC);

COMMENT ON TABLE public.investigation_actions_log IS 'Audit trail for all actions taken on fraud investigations';

-- SMS alerts log for emergency notifications
CREATE TABLE IF NOT EXISTS public.sms_alerts_log (
  alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type VARCHAR(50) NOT NULL CHECK (alert_type IN ('fraud', 'failover', 'security', 'performance', 'health', 'compliance')),
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  recipient_phone VARCHAR(20) NOT NULL,
  recipient_user_id UUID,
  message TEXT NOT NULL,
  sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  delivery_status VARCHAR(20) DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'sent', 'delivered', 'failed')),
  twilio_message_sid VARCHAR(100),
  acknowledged_at TIMESTAMPTZ,
  response_time_minutes INTEGER,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_sms_alerts_alert_type ON public.sms_alerts_log(alert_type);
CREATE INDEX IF NOT EXISTS idx_sms_alerts_severity ON public.sms_alerts_log(severity);
CREATE INDEX IF NOT EXISTS idx_sms_alerts_recipient ON public.sms_alerts_log(recipient_user_id) WHERE recipient_user_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sms_alerts_sent_at ON public.sms_alerts_log(sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_sms_alerts_delivery_status ON public.sms_alerts_log(delivery_status);
CREATE INDEX IF NOT EXISTS idx_sms_alerts_acknowledged ON public.sms_alerts_log(acknowledged_at) WHERE acknowledged_at IS NOT NULL;

COMMENT ON TABLE public.sms_alerts_log IS 'Log of all SMS emergency alerts sent via Twilio';

-- Alert acknowledgments tracking
CREATE TABLE IF NOT EXISTS public.alert_acknowledgments (
  ack_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_id UUID REFERENCES public.sms_alerts_log(alert_id) ON DELETE CASCADE,
  acknowledged_by UUID,
  acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  acknowledgment_method VARCHAR(20) CHECK (acknowledgment_method IN ('sms_reply', 'dashboard', 'phone_call', 'email')),
  response_notes TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_alert_acks_alert ON public.alert_acknowledgments(alert_id);
CREATE INDEX IF NOT EXISTS idx_alert_acks_acknowledged_by ON public.alert_acknowledgments(acknowledged_by) WHERE acknowledged_by IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_alert_acks_acknowledged_at ON public.alert_acknowledgments(acknowledged_at DESC);

COMMENT ON TABLE public.alert_acknowledgments IS 'Tracks acknowledgments of SMS emergency alerts';

-- RLS Policies for investigation_actions_log
ALTER TABLE public.investigation_actions_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "investigation_actions_log_select_policy" ON public.investigation_actions_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

CREATE POLICY "investigation_actions_log_insert_policy" ON public.investigation_actions_log
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

-- RLS Policies for sms_alerts_log
ALTER TABLE public.sms_alerts_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sms_alerts_log_select_policy" ON public.sms_alerts_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
    OR recipient_user_id = auth.uid()
  );

CREATE POLICY "sms_alerts_log_insert_policy" ON public.sms_alerts_log
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

CREATE POLICY "sms_alerts_log_update_policy" ON public.sms_alerts_log
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

-- RLS Policies for alert_acknowledgments
ALTER TABLE public.alert_acknowledgments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "alert_acknowledgments_select_policy" ON public.alert_acknowledgments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
    OR acknowledged_by = auth.uid()
  );

CREATE POLICY "alert_acknowledgments_insert_policy" ON public.alert_acknowledgments
  FOR INSERT WITH CHECK (true);

-- SQL comment for migration tracking
-- Migration: Enhanced Fraud Investigation Workflows, Unified Incident Management, Twilio SMS Emergency Alerts