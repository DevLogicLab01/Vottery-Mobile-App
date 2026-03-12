-- =====================================================
-- Telnyx SMS Provider with AI-Powered Failover System
-- Migration: 20260224180000
-- =====================================================

-- =====================================================
-- SECTION 1: ENUMS
-- =====================================================

DROP TYPE IF EXISTS public.sms_provider_name CASCADE;
CREATE TYPE public.sms_provider_name AS ENUM (
  'telnyx',
  'twilio'
);

DROP TYPE IF EXISTS public.sms_category CASCADE;
CREATE TYPE public.sms_category AS ENUM (
  'operational',
  'gamification',
  'marketing',
  'support'
);

DROP TYPE IF EXISTS public.provider_status CASCADE;
CREATE TYPE public.provider_status AS ENUM (
  'healthy',
  'degraded',
  'down'
);

DROP TYPE IF EXISTS public.sms_delivery_status CASCADE;
CREATE TYPE public.sms_delivery_status AS ENUM (
  'pending',
  'sent',
  'delivered',
  'failed',
  'blocked'
);

DROP TYPE IF EXISTS public.resend_status CASCADE;
CREATE TYPE public.resend_status AS ENUM (
  'pending',
  'sent',
  'failed'
);

-- =====================================================
-- SECTION 2: SMS PROVIDER STATE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sms_provider_state (
  state_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  current_provider public.sms_provider_name NOT NULL DEFAULT 'telnyx'::public.sms_provider_name,
  previous_provider public.sms_provider_name,
  switched_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  switch_reason TEXT,
  is_manual_override BOOLEAN DEFAULT false,
  override_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial state
INSERT INTO public.sms_provider_state (current_provider, switch_reason)
VALUES ('telnyx'::public.sms_provider_name, 'Initial setup - Telnyx as primary provider')
ON CONFLICT DO NOTHING;

-- =====================================================
-- SECTION 3: PROVIDER HEALTH METRICS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.provider_health_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_name public.sms_provider_name NOT NULL,
  is_healthy BOOLEAN NOT NULL,
  latency_ms INTEGER,
  error_rate DECIMAL(5, 2),
  consecutive_failures INTEGER DEFAULT 0,
  last_error TEXT,
  checked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_health_provider ON public.provider_health_metrics(provider_name, checked_at DESC);
CREATE INDEX IF NOT EXISTS idx_health_checked_at ON public.provider_health_metrics(checked_at DESC);

-- =====================================================
-- SECTION 4: PROVIDER FAILOVER LOG
-- =====================================================

CREATE TABLE IF NOT EXISTS public.provider_failover_log (
  failover_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_provider public.sms_provider_name NOT NULL,
  to_provider public.sms_provider_name NOT NULL,
  failover_reason TEXT NOT NULL,
  confidence_score DECIMAL(3, 2),
  claude_reasoning TEXT,
  triggered_by VARCHAR(50) CHECK (triggered_by IN ('automatic', 'manual')),
  failed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  restored_at TIMESTAMPTZ,
  duration_seconds INTEGER,
  messages_affected INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_failover_log ON public.provider_failover_log(failed_at DESC);
CREATE INDEX IF NOT EXISTS idx_failover_provider ON public.provider_failover_log(from_provider, to_provider);

-- =====================================================
-- SECTION 5: BLOCKED SMS LOG
-- =====================================================

CREATE TABLE IF NOT EXISTS public.blocked_sms_log (
  blocked_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_category public.sms_category NOT NULL,
  recipient_phone VARCHAR(20) NOT NULL,
  message_body TEXT NOT NULL,
  blocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  resent_at TIMESTAMPTZ,
  resend_status public.resend_status DEFAULT 'pending'::public.resend_status,
  provider_when_blocked public.sms_provider_name NOT NULL,
  failover_id UUID REFERENCES public.provider_failover_log(failover_id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_blocked_pending ON public.blocked_sms_log(resend_status, blocked_at DESC) WHERE resend_status = 'pending'::public.resend_status;
CREATE INDEX IF NOT EXISTS idx_blocked_category ON public.blocked_sms_log(message_category);

-- =====================================================
-- SECTION 6: SMS DELIVERY LOG
-- =====================================================

CREATE TABLE IF NOT EXISTS public.sms_delivery_log (
  delivery_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_used public.sms_provider_name NOT NULL,
  message_category public.sms_category NOT NULL,
  recipient_phone VARCHAR(20) NOT NULL,
  message_body TEXT NOT NULL,
  delivery_status public.sms_delivery_status DEFAULT 'pending'::public.sms_delivery_status,
  provider_message_id VARCHAR(100),
  sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  delivered_at TIMESTAMPTZ,
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  cost_usd DECIMAL(10, 4),
  metadata JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_delivery_provider ON public.sms_delivery_log(provider_used, sent_at DESC);
CREATE INDEX IF NOT EXISTS idx_delivery_status ON public.sms_delivery_log(delivery_status);
CREATE INDEX IF NOT EXISTS idx_delivery_category ON public.sms_delivery_log(message_category);

-- =====================================================
-- SECTION 7: FUNCTIONS
-- =====================================================

-- Function to calculate provider health score
CREATE OR REPLACE FUNCTION public.get_provider_health_score(
  target_provider public.sms_provider_name,
  time_window_minutes INTEGER DEFAULT 5
)
RETURNS DECIMAL(5, 2)
LANGUAGE plpgsql
AS $$
DECLARE
  health_score DECIMAL(5, 2);
  total_checks INTEGER;
  successful_checks INTEGER;
  avg_latency INTEGER;
BEGIN
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE is_healthy = true),
    AVG(latency_ms) FILTER (WHERE is_healthy = true)
  INTO total_checks, successful_checks, avg_latency
  FROM public.provider_health_metrics
  WHERE provider_name = target_provider
    AND checked_at >= NOW() - (time_window_minutes || ' minutes')::INTERVAL;

  IF total_checks = 0 THEN
    RETURN 100.0;
  END IF;

  -- Calculate score: 70% success rate + 30% latency performance
  health_score := (
    (successful_checks::DECIMAL / total_checks::DECIMAL * 100) * 0.7 +
    (CASE 
      WHEN avg_latency < 1000 THEN 100
      WHEN avg_latency < 3000 THEN 70
      WHEN avg_latency < 5000 THEN 40
      ELSE 10
    END) * 0.3
  );

  RETURN ROUND(health_score, 2);
END;
$$;

-- Function to get current SMS provider
CREATE OR REPLACE FUNCTION public.get_current_sms_provider()
RETURNS public.sms_provider_name
LANGUAGE plpgsql
AS $$
DECLARE
  current_prov public.sms_provider_name;
BEGIN
  SELECT current_provider INTO current_prov
  FROM public.sms_provider_state
  ORDER BY updated_at DESC
  LIMIT 1;

  RETURN COALESCE(current_prov, 'telnyx'::public.sms_provider_name);
END;
$$;

-- =====================================================
-- SECTION 8: RLS POLICIES
-- =====================================================

ALTER TABLE public.sms_provider_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_health_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_failover_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_sms_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_delivery_log ENABLE ROW LEVEL SECURITY;

-- Admin-only access for provider state
CREATE POLICY "Admin full access to provider state" ON public.sms_provider_state
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for health metrics
CREATE POLICY "Admin read access to health metrics" ON public.provider_health_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for failover logs
CREATE POLICY "Admin read access to failover logs" ON public.provider_failover_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for blocked SMS
CREATE POLICY "Admin read access to blocked SMS" ON public.blocked_sms_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin-only access for delivery logs
CREATE POLICY "Admin read access to delivery logs" ON public.sms_delivery_log
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- SECTION 9: TRIGGERS
-- =====================================================

-- Update failover duration when restored
CREATE OR REPLACE FUNCTION public.update_failover_duration()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.restored_at IS NOT NULL AND OLD.restored_at IS NULL THEN
    NEW.duration_seconds := EXTRACT(EPOCH FROM (NEW.restored_at - NEW.failed_at))::INTEGER;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_failover_duration ON public.provider_failover_log;
CREATE TRIGGER trigger_update_failover_duration
  BEFORE UPDATE ON public.provider_failover_log
  FOR EACH ROW
  EXECUTE FUNCTION public.update_failover_duration();

-- Update provider state timestamp
CREATE OR REPLACE FUNCTION public.update_provider_state_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_provider_state_timestamp ON public.sms_provider_state;
CREATE TRIGGER trigger_update_provider_state_timestamp
  BEFORE UPDATE ON public.sms_provider_state
  FOR EACH ROW
  EXECUTE FUNCTION public.update_provider_state_timestamp();