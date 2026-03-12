-- =====================================================
-- SMS Emergency Alerts Hub & User Security Center
-- Migration: 20260213050000
-- =====================================================

-- =====================================================
-- SECTION 1: ENUMS
-- =====================================================

DROP TYPE IF EXISTS public.alert_type CASCADE;
CREATE TYPE public.alert_type AS ENUM (
  'fraud',
  'compliance',
  'security',
  'system'
);

DROP TYPE IF EXISTS public.sms_delivery_status CASCADE;
CREATE TYPE public.sms_delivery_status AS ENUM (
  'pending',
  'sent',
  'delivered',
  'failed',
  'read'
);

DROP TYPE IF EXISTS public.contact_priority CASCADE;
CREATE TYPE public.contact_priority AS ENUM (
  'primary',
  'backup',
  'emergency'
);

DROP TYPE IF EXISTS public.security_event_type CASCADE;
CREATE TYPE public.security_event_type AS ENUM (
  'login_attempt',
  'suspicious_voting',
  'payment_anomaly',
  'unauthorized_access',
  'password_change',
  'device_authorization',
  'data_breach'
);

DROP TYPE IF EXISTS public.threat_level CASCADE;
CREATE TYPE public.threat_level AS ENUM (
  'low',
  'medium',
  'high',
  'critical'
);

DROP TYPE IF EXISTS public.two_factor_method CASCADE;
CREATE TYPE public.two_factor_method AS ENUM (
  'sms',
  'authenticator',
  'email'
);

-- =====================================================
-- SECTION 2: SMS EMERGENCY ALERTS TABLES
-- =====================================================

-- Emergency contacts for admin notifications
CREATE TABLE IF NOT EXISTS public.sms_emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  contact_name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  country_code TEXT NOT NULL DEFAULT '+1',
  priority public.contact_priority DEFAULT 'primary'::public.contact_priority,
  is_active BOOLEAN DEFAULT true,
  coverage_hours TEXT DEFAULT '24/7',
  notification_preferences JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Message templates for different alert types
CREATE TABLE IF NOT EXISTS public.sms_message_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_name TEXT NOT NULL UNIQUE,
  alert_type public.alert_type NOT NULL,
  message_template TEXT NOT NULL,
  variables JSONB DEFAULT '[]'::JSONB,
  is_active BOOLEAN DEFAULT true,
  usage_count INTEGER DEFAULT 0,
  created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- SMS delivery tracking with read receipts
CREATE TABLE IF NOT EXISTS public.sms_delivery_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID REFERENCES public.sms_emergency_contacts(id) ON DELETE CASCADE,
  template_id UUID REFERENCES public.sms_message_templates(id) ON DELETE SET NULL,
  phone_number TEXT NOT NULL,
  message_content TEXT NOT NULL,
  alert_type public.alert_type NOT NULL,
  delivery_status public.sms_delivery_status DEFAULT 'pending'::public.sms_delivery_status,
  twilio_message_sid TEXT,
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  failed_reason TEXT,
  retry_count INTEGER DEFAULT 0,
  cost_usd DECIMAL(10, 4),
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- SMS cost tracking and budget alerts
CREATE TABLE IF NOT EXISTS public.sms_cost_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_name TEXT NOT NULL,
  country_code TEXT NOT NULL,
  cost_per_sms DECIMAL(10, 4) NOT NULL,
  monthly_budget DECIMAL(10, 2),
  current_spend DECIMAL(10, 2) DEFAULT 0,
  message_count INTEGER DEFAULT 0,
  budget_alert_threshold DECIMAL(5, 2) DEFAULT 80.00,
  last_alert_sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- SMS scheduling for non-urgent alerts
CREATE TABLE IF NOT EXISTS public.sms_scheduled_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact_id UUID REFERENCES public.sms_emergency_contacts(id) ON DELETE CASCADE,
  template_id UUID REFERENCES public.sms_message_templates(id) ON DELETE SET NULL,
  message_content TEXT NOT NULL,
  alert_type public.alert_type NOT NULL,
  scheduled_for TIMESTAMPTZ NOT NULL,
  is_sent BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ,
  created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 3: USER SECURITY CENTER TABLES
-- =====================================================

-- User fraud risk scores with ML-powered assessment
CREATE TABLE IF NOT EXISTS public.user_fraud_risk_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  risk_score INTEGER NOT NULL CHECK (risk_score >= 0 AND risk_score <= 100),
  threat_level public.threat_level NOT NULL,
  contributing_factors JSONB DEFAULT '[]'::JSONB,
  recommendations JSONB DEFAULT '[]'::JSONB,
  last_scan_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  previous_score INTEGER,
  score_trend TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Security event logs with comprehensive tracking
CREATE TABLE IF NOT EXISTS public.user_security_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  event_type public.security_event_type NOT NULL,
  threat_level public.threat_level NOT NULL,
  description TEXT NOT NULL,
  ip_address TEXT,
  device_fingerprint TEXT,
  device_name TEXT,
  geolocation JSONB DEFAULT '{}'::JSONB,
  user_agent TEXT,
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  resolution_action TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Trusted devices with authorization controls
CREATE TABLE IF NOT EXISTS public.trusted_devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  device_name TEXT NOT NULL,
  device_fingerprint TEXT NOT NULL UNIQUE,
  device_type TEXT,
  browser TEXT,
  operating_system TEXT,
  is_trusted BOOLEAN DEFAULT false,
  last_used_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  ip_address TEXT,
  geolocation JSONB DEFAULT '{}'::JSONB,
  authorization_date TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User security settings (2FA, biometric, password)
CREATE TABLE IF NOT EXISTS public.user_security_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE UNIQUE,
  two_factor_enabled BOOLEAN DEFAULT false,
  two_factor_method public.two_factor_method,
  two_factor_phone TEXT,
  two_factor_backup_codes JSONB DEFAULT '[]'::JSONB,
  biometric_enabled BOOLEAN DEFAULT false,
  biometric_type TEXT,
  password_last_changed_at TIMESTAMPTZ,
  password_strength_score INTEGER CHECK (password_strength_score >= 0 AND password_strength_score <= 100),
  require_password_change BOOLEAN DEFAULT false,
  session_timeout_minutes INTEGER DEFAULT 60,
  breach_notifications_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Active sessions for remote logout
CREATE TABLE IF NOT EXISTS public.user_active_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  device_id UUID REFERENCES public.trusted_devices(id) ON DELETE CASCADE,
  session_token TEXT NOT NULL UNIQUE,
  ip_address TEXT,
  user_agent TEXT,
  is_current BOOLEAN DEFAULT false,
  last_activity_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Security audit trail for compliance
CREATE TABLE IF NOT EXISTS public.security_audit_trail (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  action_description TEXT NOT NULL,
  ip_address TEXT,
  device_fingerprint TEXT,
  before_state JSONB DEFAULT '{}'::JSONB,
  after_state JSONB DEFAULT '{}'::JSONB,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- SECTION 4: INDEXES
-- =====================================================

-- SMS Emergency Alerts indexes
CREATE INDEX IF NOT EXISTS idx_sms_emergency_contacts_user_id ON public.sms_emergency_contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_sms_emergency_contacts_priority ON public.sms_emergency_contacts(priority);
CREATE INDEX IF NOT EXISTS idx_sms_message_templates_alert_type ON public.sms_message_templates(alert_type);
CREATE INDEX IF NOT EXISTS idx_sms_delivery_tracking_contact_id ON public.sms_delivery_tracking(contact_id);
CREATE INDEX IF NOT EXISTS idx_sms_delivery_tracking_status ON public.sms_delivery_tracking(delivery_status);
CREATE INDEX IF NOT EXISTS idx_sms_delivery_tracking_created_at ON public.sms_delivery_tracking(created_at);
CREATE INDEX IF NOT EXISTS idx_sms_cost_tracking_country_code ON public.sms_cost_tracking(country_code);
CREATE INDEX IF NOT EXISTS idx_sms_scheduled_messages_scheduled_for ON public.sms_scheduled_messages(scheduled_for);

-- User Security Center indexes
CREATE INDEX IF NOT EXISTS idx_user_fraud_risk_scores_user_id ON public.user_fraud_risk_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_user_fraud_risk_scores_threat_level ON public.user_fraud_risk_scores(threat_level);
CREATE INDEX IF NOT EXISTS idx_user_security_events_user_id ON public.user_security_events(user_id);
CREATE INDEX IF NOT EXISTS idx_user_security_events_event_type ON public.user_security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_user_security_events_created_at ON public.user_security_events(created_at);
CREATE INDEX IF NOT EXISTS idx_trusted_devices_user_id ON public.trusted_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_trusted_devices_fingerprint ON public.trusted_devices(device_fingerprint);
CREATE INDEX IF NOT EXISTS idx_user_security_settings_user_id ON public.user_security_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_user_active_sessions_user_id ON public.user_active_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_active_sessions_device_id ON public.user_active_sessions(device_id);
CREATE INDEX IF NOT EXISTS idx_security_audit_trail_user_id ON public.security_audit_trail(user_id);
CREATE INDEX IF NOT EXISTS idx_security_audit_trail_created_at ON public.security_audit_trail(created_at);

-- =====================================================
-- SECTION 5: FUNCTIONS
-- =====================================================

-- Function to update SMS cost tracking
CREATE OR REPLACE FUNCTION public.update_sms_cost_tracking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  zone_record RECORD;
BEGIN
  IF NEW.delivery_status = 'delivered' AND NEW.cost_usd IS NOT NULL THEN
    SELECT * INTO zone_record
    FROM public.sms_cost_tracking
    WHERE country_code = SUBSTRING(NEW.phone_number FROM 1 FOR 3)
    LIMIT 1;
    
    IF FOUND THEN
      UPDATE public.sms_cost_tracking
      SET 
        current_spend = current_spend + NEW.cost_usd,
        message_count = message_count + 1,
        updated_at = CURRENT_TIMESTAMP
      WHERE id = zone_record.id;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Function to update fraud risk score trend
CREATE OR REPLACE FUNCTION public.update_fraud_risk_trend()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.previous_score IS NOT NULL THEN
    IF NEW.risk_score > NEW.previous_score THEN
      NEW.score_trend := 'increasing';
    ELSIF NEW.risk_score < NEW.previous_score THEN
      NEW.score_trend := 'decreasing';
    ELSE
      NEW.score_trend := 'stable';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Function to log security audit trail
CREATE OR REPLACE FUNCTION public.log_security_audit(
  p_user_id UUID,
  p_action_type TEXT,
  p_action_description TEXT,
  p_ip_address TEXT DEFAULT NULL,
  p_device_fingerprint TEXT DEFAULT NULL,
  p_before_state JSONB DEFAULT '{}'::JSONB,
  p_after_state JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  audit_id UUID;
BEGIN
  INSERT INTO public.security_audit_trail (
    user_id,
    action_type,
    action_description,
    ip_address,
    device_fingerprint,
    before_state,
    after_state
  ) VALUES (
    p_user_id,
    p_action_type,
    p_action_description,
    p_ip_address,
    p_device_fingerprint,
    p_before_state,
    p_after_state
  )
  RETURNING id INTO audit_id;
  
  RETURN audit_id;
END;
$$;

-- =====================================================
-- SECTION 6: ENABLE RLS
-- =====================================================

ALTER TABLE public.sms_emergency_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_message_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_delivery_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_cost_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_scheduled_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_fraud_risk_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trusted_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_security_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_active_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_audit_trail ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- SECTION 7: RLS POLICIES
-- =====================================================

-- SMS Emergency Contacts policies
DROP POLICY IF EXISTS "users_manage_own_sms_emergency_contacts" ON public.sms_emergency_contacts;
CREATE POLICY "users_manage_own_sms_emergency_contacts"
ON public.sms_emergency_contacts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- SMS Message Templates policies (admin only for creation)
DROP POLICY IF EXISTS "users_view_sms_message_templates" ON public.sms_message_templates;
CREATE POLICY "users_view_sms_message_templates"
ON public.sms_message_templates
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "users_manage_own_sms_message_templates" ON public.sms_message_templates;
CREATE POLICY "users_manage_own_sms_message_templates"
ON public.sms_message_templates
FOR ALL
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- SMS Delivery Tracking policies
DROP POLICY IF EXISTS "users_view_sms_delivery_tracking" ON public.sms_delivery_tracking;
CREATE POLICY "users_view_sms_delivery_tracking"
ON public.sms_delivery_tracking
FOR SELECT
TO authenticated
USING (true);

-- SMS Cost Tracking policies (read-only for users)
DROP POLICY IF EXISTS "users_view_sms_cost_tracking" ON public.sms_cost_tracking;
CREATE POLICY "users_view_sms_cost_tracking"
ON public.sms_cost_tracking
FOR SELECT
TO authenticated
USING (true);

-- SMS Scheduled Messages policies
DROP POLICY IF EXISTS "users_manage_own_sms_scheduled_messages" ON public.sms_scheduled_messages;
CREATE POLICY "users_manage_own_sms_scheduled_messages"
ON public.sms_scheduled_messages
FOR ALL
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- User Fraud Risk Scores policies
DROP POLICY IF EXISTS "users_view_own_fraud_risk_scores" ON public.user_fraud_risk_scores;
CREATE POLICY "users_view_own_fraud_risk_scores"
ON public.user_fraud_risk_scores
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- User Security Events policies
DROP POLICY IF EXISTS "users_view_own_security_events" ON public.user_security_events;
CREATE POLICY "users_view_own_security_events"
ON public.user_security_events
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Trusted Devices policies
DROP POLICY IF EXISTS "users_manage_own_trusted_devices" ON public.trusted_devices;
CREATE POLICY "users_manage_own_trusted_devices"
ON public.trusted_devices
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- User Security Settings policies
DROP POLICY IF EXISTS "users_manage_own_security_settings" ON public.user_security_settings;
CREATE POLICY "users_manage_own_security_settings"
ON public.user_security_settings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- User Active Sessions policies
DROP POLICY IF EXISTS "users_manage_own_active_sessions" ON public.user_active_sessions;
CREATE POLICY "users_manage_own_active_sessions"
ON public.user_active_sessions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Security Audit Trail policies
DROP POLICY IF EXISTS "users_view_own_security_audit_trail" ON public.security_audit_trail;
CREATE POLICY "users_view_own_security_audit_trail"
ON public.security_audit_trail
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- =====================================================
-- SECTION 8: TRIGGERS
-- =====================================================

DROP TRIGGER IF EXISTS update_sms_cost_tracking_trigger ON public.sms_delivery_tracking;
CREATE TRIGGER update_sms_cost_tracking_trigger
AFTER INSERT OR UPDATE ON public.sms_delivery_tracking
FOR EACH ROW
EXECUTE FUNCTION public.update_sms_cost_tracking();

DROP TRIGGER IF EXISTS update_fraud_risk_trend_trigger ON public.user_fraud_risk_scores;
CREATE TRIGGER update_fraud_risk_trend_trigger
BEFORE INSERT OR UPDATE ON public.user_fraud_risk_scores
FOR EACH ROW
EXECUTE FUNCTION public.update_fraud_risk_trend();

-- =====================================================
-- SECTION 9: MOCK DATA
-- =====================================================

DO $$
DECLARE
  existing_user_id UUID;
  admin_user_id UUID;
  contact_id_1 UUID;
  contact_id_2 UUID;
  template_id_fraud UUID;
  template_id_security UUID;
  device_id_1 UUID;
BEGIN
  -- Get existing users
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) THEN
    SELECT id INTO existing_user_id FROM public.user_profiles WHERE email LIKE '%user%' LIMIT 1;
    SELECT id INTO admin_user_id FROM public.user_profiles WHERE email LIKE '%admin%' LIMIT 1;
    
    IF existing_user_id IS NOT NULL THEN
      -- SMS Emergency Contacts
      INSERT INTO public.sms_emergency_contacts (id, user_id, contact_name, phone_number, country_code, priority, coverage_hours)
      VALUES 
        (gen_random_uuid(), COALESCE(admin_user_id, existing_user_id), 'Primary Admin Contact', '+14155551234', '+1', 'primary'::public.contact_priority, '24/7'),
        (gen_random_uuid(), COALESCE(admin_user_id, existing_user_id), 'Backup Security Team', '+14155555678', '+1', 'backup'::public.contact_priority, 'Business Hours')
      ON CONFLICT (id) DO NOTHING
      RETURNING id INTO contact_id_1;
      
      -- SMS Message Templates
      INSERT INTO public.sms_message_templates (id, template_name, alert_type, message_template, variables, created_by)
      VALUES 
        (gen_random_uuid(), 'Fraud Alert Critical', 'fraud'::public.alert_type, 'CRITICAL FRAUD ALERT: {fraud_type} detected for user {user_email}. Risk score: {risk_score}. Immediate action required.', '["fraud_type", "user_email", "risk_score"]'::JSONB, COALESCE(admin_user_id, existing_user_id)),
        (gen_random_uuid(), 'Security Breach Notification', 'security'::public.alert_type, 'SECURITY BREACH: {breach_type} detected at {timestamp}. Affected users: {user_count}. Response initiated.', '["breach_type", "timestamp", "user_count"]'::JSONB, COALESCE(admin_user_id, existing_user_id)),
        (gen_random_uuid(), 'System Downtime Alert', 'system'::public.alert_type, 'SYSTEM ALERT: {service_name} experiencing downtime. ETA: {eta}. Status: {status}.', '["service_name", "eta", "status"]'::JSONB, COALESCE(admin_user_id, existing_user_id)),
        (gen_random_uuid(), 'Compliance Violation', 'compliance'::public.alert_type, 'COMPLIANCE ALERT: {violation_type} detected in {jurisdiction}. Severity: {severity}. Action required within {timeframe}.', '["violation_type", "jurisdiction", "severity", "timeframe"]'::JSONB, COALESCE(admin_user_id, existing_user_id))
      ON CONFLICT (template_name) DO NOTHING
      RETURNING id INTO template_id_fraud;
      
      -- SMS Cost Tracking (8 purchasing power zones)
      INSERT INTO public.sms_cost_tracking (zone_name, country_code, cost_per_sms, monthly_budget, current_spend)
      VALUES 
        ('North America', '+1', 0.0075, 500.00, 127.50),
        ('Western Europe', '+44', 0.0085, 400.00, 89.25),
        ('Eastern Europe', '+48', 0.0065, 300.00, 45.80),
        ('Asia Pacific', '+81', 0.0095, 450.00, 112.30),
        ('Latin America', '+52', 0.0055, 250.00, 67.40),
        ('Middle East', '+971', 0.0105, 350.00, 98.75),
        ('Africa', '+234', 0.0045, 200.00, 34.20),
        ('Oceania', '+61', 0.0090, 300.00, 78.90)
      ON CONFLICT (id) DO NOTHING;
      
      -- SMS Delivery Tracking
      INSERT INTO public.sms_delivery_tracking (contact_id, template_id, phone_number, message_content, alert_type, delivery_status, twilio_message_sid, sent_at, delivered_at, cost_usd)
      VALUES 
        (contact_id_1, template_id_fraud, '+14155551234', 'CRITICAL FRAUD ALERT: Multiple failed login attempts detected for user test@example.com. Risk score: 85. Immediate action required.', 'fraud'::public.alert_type, 'delivered'::public.sms_delivery_status, 'SM1234567890abcdef', CURRENT_TIMESTAMP - INTERVAL '2 hours', CURRENT_TIMESTAMP - INTERVAL '1 hour 58 minutes', 0.0075),
        (contact_id_1, template_id_security, '+14155551234', 'SECURITY BREACH: Unauthorized access attempt detected at 2026-02-12 18:30:00. Affected users: 3. Response initiated.', 'security'::public.alert_type, 'read'::public.sms_delivery_status, 'SM0987654321fedcba', CURRENT_TIMESTAMP - INTERVAL '5 hours', CURRENT_TIMESTAMP - INTERVAL '4 hours 57 minutes', 0.0075)
      ON CONFLICT (id) DO NOTHING;
      
      -- User Fraud Risk Scores
      INSERT INTO public.user_fraud_risk_scores (user_id, risk_score, threat_level, contributing_factors, recommendations, previous_score, score_trend)
      VALUES 
        (existing_user_id, 35, 'low'::public.threat_level, 
         '[{"factor": "Login from new device", "weight": 15}, {"factor": "Unusual voting pattern", "weight": 20}]'::JSONB,
         '[{"action": "Enable two-factor authentication", "priority": "medium"}, {"action": "Review recent login activity", "priority": "low"}]'::JSONB,
         42, 'decreasing')
      ON CONFLICT (id) DO NOTHING;
      
      -- User Security Events
      INSERT INTO public.user_security_events (user_id, event_type, threat_level, description, ip_address, device_name, geolocation)
      VALUES 
        (existing_user_id, 'login_attempt'::public.security_event_type, 'low'::public.threat_level, 'Successful login from new device', '192.168.1.100', 'iPhone 14 Pro', '{"city": "San Francisco", "country": "USA", "latitude": 37.7749, "longitude": -122.4194}'::JSONB),
        (existing_user_id, 'suspicious_voting'::public.security_event_type, 'medium'::public.threat_level, 'Rapid voting pattern detected - 15 votes in 2 minutes', '192.168.1.100', 'iPhone 14 Pro', '{"city": "San Francisco", "country": "USA"}'::JSONB),
        (existing_user_id, 'device_authorization'::public.security_event_type, 'low'::public.threat_level, 'New device authorized successfully', '192.168.1.105', 'MacBook Pro', '{"city": "San Francisco", "country": "USA"}'::JSONB)
      ON CONFLICT (id) DO NOTHING;
      
      -- Trusted Devices
      INSERT INTO public.trusted_devices (id, user_id, device_name, device_fingerprint, device_type, browser, operating_system, is_trusted, ip_address, geolocation)
      VALUES 
        (gen_random_uuid(), existing_user_id, 'iPhone 14 Pro', 'fp_iphone14pro_' || existing_user_id::TEXT, 'mobile', 'Safari', 'iOS 17.2', true, '192.168.1.100', '{"city": "San Francisco", "country": "USA"}'::JSONB),
        (gen_random_uuid(), existing_user_id, 'MacBook Pro', 'fp_macbookpro_' || existing_user_id::TEXT, 'desktop', 'Chrome', 'macOS 14.1', true, '192.168.1.105', '{"city": "San Francisco", "country": "USA"}'::JSONB)
      ON CONFLICT (device_fingerprint) DO NOTHING
      RETURNING id INTO device_id_1;
      
      -- User Security Settings
      INSERT INTO public.user_security_settings (user_id, two_factor_enabled, two_factor_method, two_factor_phone, biometric_enabled, biometric_type, password_last_changed_at, password_strength_score)
      VALUES 
        (existing_user_id, true, 'sms'::public.two_factor_method, '+14155551234', true, 'Face ID', CURRENT_TIMESTAMP - INTERVAL '30 days', 85)
      ON CONFLICT (user_id) DO NOTHING;
      
      -- User Active Sessions
      INSERT INTO public.user_active_sessions (user_id, device_id, session_token, ip_address, user_agent, is_current, last_activity_at, expires_at)
      VALUES 
        (existing_user_id, device_id_1, 'session_token_' || gen_random_uuid()::TEXT, '192.168.1.100', 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X)', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + INTERVAL '7 days')
      ON CONFLICT (session_token) DO NOTHING;
      
      -- Security Audit Trail
      INSERT INTO public.security_audit_trail (user_id, action_type, action_description, ip_address, device_fingerprint, before_state, after_state)
      VALUES 
        (existing_user_id, 'two_factor_enabled', 'User enabled two-factor authentication via SMS', '192.168.1.100', 'fp_iphone14pro_' || existing_user_id::TEXT, '{"two_factor_enabled": false}'::JSONB, '{"two_factor_enabled": true, "method": "sms"}'::JSONB),
        (existing_user_id, 'device_authorized', 'User authorized new device: MacBook Pro', '192.168.1.105', 'fp_macbookpro_' || existing_user_id::TEXT, '{}'::JSONB, '{"device_name": "MacBook Pro", "is_trusted": true}'::JSONB)
      ON CONFLICT (id) DO NOTHING;
      
    ELSE
      RAISE NOTICE 'No existing users found. Run auth migration first.';
    END IF;
  ELSE
    RAISE NOTICE 'Table user_profiles does not exist. Run auth migration first.';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;