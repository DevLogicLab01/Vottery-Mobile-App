-- Phase 5 Batch 8: Payout Operations & Compliance Alerts
-- Payout retry attempts, reconciliation discrepancies, admin on-call rotation, notification preferences

-- =====================================================
-- PAYOUT RETRY ATTEMPTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.payout_retry_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payout_id UUID NOT NULL,
  attempt_number INTEGER NOT NULL,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  failure_reason TEXT,
  next_retry_at TIMESTAMPTZ,
  status TEXT NOT NULL CHECK (status IN ('pending', 'retrying', 'succeeded', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payout_retry_attempts_payout_id ON public.payout_retry_attempts(payout_id);
CREATE INDEX IF NOT EXISTS idx_payout_retry_attempts_status ON public.payout_retry_attempts(status);
CREATE INDEX IF NOT EXISTS idx_payout_retry_attempts_next_retry ON public.payout_retry_attempts(next_retry_at);

-- Add foreign key constraint only if stripe_payouts table exists
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'stripe_payouts') THEN
    ALTER TABLE public.payout_retry_attempts 
    ADD CONSTRAINT fk_payout_retry_attempts_payout_id 
    FOREIGN KEY (payout_id) REFERENCES public.stripe_payouts(id) ON DELETE CASCADE;
  END IF;
END $$;

-- =====================================================
-- RECONCILIATION DISCREPANCIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.reconciliation_discrepancies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reconciliation_date DATE NOT NULL,
  expected_amount DECIMAL(10, 2) NOT NULL,
  actual_amount DECIMAL(10, 2) NOT NULL,
  discrepancy_amount DECIMAL(10, 2) NOT NULL,
  severity TEXT NOT NULL CHECK (severity IN ('minor', 'major', 'critical')),
  status TEXT NOT NULL CHECK (status IN ('unresolved', 'investigating', 'resolved', 'auto_resolved')),
  root_cause TEXT,
  resolution_notes TEXT,
  resolved_by UUID REFERENCES auth.users(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reconciliation_discrepancies_date ON public.reconciliation_discrepancies(reconciliation_date);
CREATE INDEX IF NOT EXISTS idx_reconciliation_discrepancies_status ON public.reconciliation_discrepancies(status);
CREATE INDEX IF NOT EXISTS idx_reconciliation_discrepancies_severity ON public.reconciliation_discrepancies(severity);

-- =====================================================
-- ADMIN ON-CALL ROTATION TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.admin_on_call_rotation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  priority TEXT NOT NULL CHECK (priority IN ('primary', 'secondary', 'tertiary')),
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  phone_number TEXT NOT NULL,
  country_code TEXT NOT NULL DEFAULT '+1',
  is_active BOOLEAN NOT NULL DEFAULT true,
  acknowledgment_timeout_minutes INTEGER NOT NULL DEFAULT 5,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_on_call_rotation_admin_id ON public.admin_on_call_rotation(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_on_call_rotation_dates ON public.admin_on_call_rotation(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_admin_on_call_rotation_active ON public.admin_on_call_rotation(is_active);

-- =====================================================
-- PAYOUT NOTIFICATION PREFERENCES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.payout_notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notify_on_initiated BOOLEAN NOT NULL DEFAULT true,
  notify_on_completed BOOLEAN NOT NULL DEFAULT true,
  notify_on_failed BOOLEAN NOT NULL DEFAULT true,
  email_enabled BOOLEAN NOT NULL DEFAULT true,
  sms_enabled BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(creator_id)
);

CREATE INDEX IF NOT EXISTS idx_payout_notification_preferences_creator_id ON public.payout_notification_preferences(creator_id);

-- =====================================================
-- FRAUD ALERT ESCALATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.fraud_alert_escalations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type TEXT NOT NULL CHECK (alert_type IN ('high_fraud_score', 'multi_account_pattern', 'compliance_deadline', 'gdpr_deletion', 'security_breach')),
  severity TEXT NOT NULL CHECK (severity IN ('critical', 'high', 'medium')),
  target_user_id UUID REFERENCES auth.users(id),
  fraud_score DECIMAL(5, 2),
  description TEXT NOT NULL,
  escalation_status TEXT NOT NULL CHECK (escalation_status IN ('pending', 'acknowledged', 'resolved')),
  acknowledged_by UUID REFERENCES auth.users(id),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  sms_sent BOOLEAN NOT NULL DEFAULT false,
  sms_delivery_status TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fraud_alert_escalations_status ON public.fraud_alert_escalations(escalation_status);
CREATE INDEX IF NOT EXISTS idx_fraud_alert_escalations_severity ON public.fraud_alert_escalations(severity);
CREATE INDEX IF NOT EXISTS idx_fraud_alert_escalations_created ON public.fraud_alert_escalations(created_at);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Payout Retry Attempts
ALTER TABLE public.payout_retry_attempts ENABLE ROW LEVEL SECURITY;

-- Only create policy referencing stripe_payouts if that table exists
DO $$ 
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'stripe_payouts') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payout_retry_attempts' AND policyname = 'creator_view_own_retry_attempts') THEN
      EXECUTE 'CREATE POLICY creator_view_own_retry_attempts ON public.payout_retry_attempts
        FOR SELECT
        USING (
          EXISTS (
            SELECT 1 FROM public.stripe_payouts 
            WHERE stripe_payouts.id = payout_retry_attempts.payout_id 
            AND stripe_payouts.creator_id = auth.uid()
          )
        )';
    END IF;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payout_retry_attempts' AND policyname = 'system_manage_retry_attempts') THEN
    CREATE POLICY system_manage_retry_attempts ON public.payout_retry_attempts
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

-- Reconciliation Discrepancies
ALTER TABLE public.reconciliation_discrepancies ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'reconciliation_discrepancies' AND policyname = 'admin_view_discrepancies') THEN
    CREATE POLICY admin_view_discrepancies ON public.reconciliation_discrepancies
      FOR SELECT
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'reconciliation_discrepancies' AND policyname = 'admin_manage_discrepancies') THEN
    CREATE POLICY admin_manage_discrepancies ON public.reconciliation_discrepancies
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

-- Admin On-Call Rotation
ALTER TABLE public.admin_on_call_rotation ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'admin_on_call_rotation' AND policyname = 'admin_view_rotation') THEN
    CREATE POLICY admin_view_rotation ON public.admin_on_call_rotation
      FOR SELECT
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'admin_on_call_rotation' AND policyname = 'admin_manage_rotation') THEN
    CREATE POLICY admin_manage_rotation ON public.admin_on_call_rotation
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

-- Payout Notification Preferences
ALTER TABLE public.payout_notification_preferences ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payout_notification_preferences' AND policyname = 'creator_view_own_preferences') THEN
    CREATE POLICY creator_view_own_preferences ON public.payout_notification_preferences
      FOR SELECT
      USING (creator_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'payout_notification_preferences' AND policyname = 'creator_manage_own_preferences') THEN
    CREATE POLICY creator_manage_own_preferences ON public.payout_notification_preferences
      FOR ALL
      USING (creator_id = auth.uid())
      WITH CHECK (creator_id = auth.uid());
  END IF;
END $$;

-- Fraud Alert Escalations
ALTER TABLE public.fraud_alert_escalations ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fraud_alert_escalations' AND policyname = 'admin_view_fraud_alerts') THEN
    CREATE POLICY admin_view_fraud_alerts ON public.fraud_alert_escalations
      FOR SELECT
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'fraud_alert_escalations' AND policyname = 'system_manage_fraud_alerts') THEN
    CREATE POLICY system_manage_fraud_alerts ON public.fraud_alert_escalations
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;