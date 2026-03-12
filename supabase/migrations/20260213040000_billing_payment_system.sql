-- Billing & Payment System Migration
-- Timestamp: 20260213040000
-- Description: Payment methods, invoices, billing alerts, subscription events, payment disputes, refunds, compliance

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.payment_method_type CASCADE;
CREATE TYPE public.payment_method_type AS ENUM (
  'credit_card',
  'debit_card',
  'bank_account',
    'paypal',
  'digital_wallet'
);

DROP TYPE IF EXISTS public.invoice_status CASCADE;
CREATE TYPE public.invoice_status AS ENUM (
  'draft',
  'pending',
  'paid',
  'failed',
  'refunded',
  'disputed'
);

DROP TYPE IF EXISTS public.payment_alert_type CASCADE;
CREATE TYPE public.payment_alert_type AS ENUM (
  'failed_payment',
  'upcoming_renewal',
  'payment_method_expiring',
  'subscription_cancelled',
  'refund_processed'
);

DROP TYPE IF EXISTS public.dispute_status CASCADE;
CREATE TYPE public.dispute_status AS ENUM (
  'submitted',
  'under_review',
  'resolved',
  'rejected'
);

DROP TYPE IF EXISTS public.refund_status CASCADE;
CREATE TYPE public.refund_status AS ENUM (
  'requested',
  'processing',
  'completed',
  'rejected'
);

-- ============================================================
-- 2. PAYMENT METHODS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  payment_type public.payment_method_type NOT NULL,
  stripe_payment_method_id TEXT NOT NULL,
  card_brand TEXT,
  card_last4 TEXT,
  card_exp_month INTEGER,
  card_exp_year INTEGER,
  bank_name TEXT,
  bank_last4 TEXT,
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  billing_name TEXT NOT NULL,
  billing_email TEXT,
  billing_address JSONB DEFAULT '{}'::jsonb,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_stripe_id ON public.payment_methods(stripe_payment_method_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_is_default ON public.payment_methods(user_id, is_default) WHERE is_default = true;

-- ============================================================
-- 3. INVOICES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.user_subscriptions(id) ON DELETE SET NULL,
  invoice_number TEXT NOT NULL UNIQUE,
  stripe_invoice_id TEXT,
  amount NUMERIC(12,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  status public.invoice_status DEFAULT 'pending',
  line_items JSONB DEFAULT '[]'::jsonb,
  pdf_url TEXT,
  payment_intent_id TEXT,
  payment_method_id UUID REFERENCES public.payment_methods(id) ON DELETE SET NULL,
  billing_period_start TIMESTAMPTZ,
  billing_period_end TIMESTAMPTZ,
  due_date TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON public.invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_subscription_id ON public.invoices(subscription_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_created_at ON public.invoices(created_at DESC);

-- ============================================================
-- 4. BILLING ALERTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.billing_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  alert_type public.payment_alert_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  email_sent BOOLEAN DEFAULT false,
  related_invoice_id UUID REFERENCES public.invoices(id) ON DELETE SET NULL,
  related_subscription_id UUID REFERENCES public.user_subscriptions(id) ON DELETE SET NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_billing_alerts_user_id ON public.billing_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_billing_alerts_is_read ON public.billing_alerts(user_id, is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_billing_alerts_created_at ON public.billing_alerts(created_at DESC);

-- ============================================================
-- 5. SUBSCRIPTION EVENTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.subscription_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES public.user_subscriptions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  old_tier TEXT,
  new_tier TEXT,
  cancellation_reason TEXT,
  cancellation_feedback TEXT,
  proration_amount NUMERIC(12,2),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subscription_events_subscription_id ON public.subscription_events(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_user_id ON public.subscription_events(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_events_created_at ON public.subscription_events(created_at DESC);

-- ============================================================
-- 6. PAYMENT DISPUTES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.payment_disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  invoice_id UUID REFERENCES public.invoices(id) ON DELETE SET NULL,
  stripe_dispute_id TEXT,
  amount NUMERIC(12,2) NOT NULL,
  reason TEXT NOT NULL,
  description TEXT,
  status public.dispute_status DEFAULT 'submitted',
  evidence JSONB DEFAULT '{}'::jsonb,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_disputes_user_id ON public.payment_disputes(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_disputes_invoice_id ON public.payment_disputes(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payment_disputes_status ON public.payment_disputes(status);

-- ============================================================
-- 7. REFUND RECORDS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.refund_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  invoice_id UUID REFERENCES public.invoices(id) ON DELETE SET NULL,
  stripe_refund_id TEXT,
  amount NUMERIC(12,2) NOT NULL,
  reason TEXT NOT NULL,
  status public.refund_status DEFAULT 'requested',
  processed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_refund_records_user_id ON public.refund_records(user_id);
CREATE INDEX IF NOT EXISTS idx_refund_records_invoice_id ON public.refund_records(invoice_id);
CREATE INDEX IF NOT EXISTS idx_refund_records_status ON public.refund_records(status);

-- ============================================================
-- 8. PAYMENT COMPLIANCE LOGS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.payment_compliance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  compliance_type TEXT NOT NULL,
  transaction_id UUID,
  transaction_type TEXT,
  amount NUMERIC(12,2),
  currency TEXT,
  zone public.purchasing_power_zone,
  gdpr_consent BOOLEAN DEFAULT false,
  pci_dss_compliant BOOLEAN DEFAULT true,
  ip_address TEXT,
  user_agent TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_compliance_user_id ON public.payment_compliance_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_compliance_type ON public.payment_compliance_logs(compliance_type);
CREATE INDEX IF NOT EXISTS idx_payment_compliance_created_at ON public.payment_compliance_logs(created_at DESC);

-- ============================================================
-- 9. PAYMENT RETRY LOGS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.payment_retry_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL,
  retry_strategy TEXT DEFAULT 'exponential_backoff',
  next_retry_at TIMESTAMPTZ,
  error_message TEXT,
  success BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_retry_invoice_id ON public.payment_retry_logs(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payment_retry_next_retry ON public.payment_retry_logs(next_retry_at) WHERE success = false;

-- ============================================================
-- 10. BILLING PREFERENCES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.billing_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  email_alerts_enabled BOOLEAN DEFAULT true,
  failed_payment_alerts BOOLEAN DEFAULT true,
  renewal_reminders BOOLEAN DEFAULT true,
  payment_receipts BOOLEAN DEFAULT true,
  auto_renewal_enabled BOOLEAN DEFAULT true,
  preferred_currency TEXT DEFAULT 'USD',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_billing_preferences_user_id ON public.billing_preferences(user_id);

-- ============================================================
-- 11. FUNCTIONS
-- ============================================================

-- Generate invoice number
CREATE OR REPLACE FUNCTION public.generate_invoice_number()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  invoice_count INTEGER;
  invoice_num TEXT;
BEGIN
  SELECT COUNT(*) INTO invoice_count FROM public.invoices;
  invoice_num := 'INV-' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDD') || '-' || LPAD((invoice_count + 1)::TEXT, 6, '0');
  RETURN invoice_num;
END;
$$;

-- Update invoice updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_invoice_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- ============================================================
-- 12. ENABLE RLS
-- ============================================================

ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refund_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_compliance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_retry_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.billing_preferences ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 13. RLS POLICIES
-- ============================================================

-- Payment Methods
DROP POLICY IF EXISTS "users_manage_own_payment_methods" ON public.payment_methods;
CREATE POLICY "users_manage_own_payment_methods"
ON public.payment_methods
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Invoices
DROP POLICY IF EXISTS "users_view_own_invoices" ON public.invoices;
CREATE POLICY "users_view_own_invoices"
ON public.invoices
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Billing Alerts
DROP POLICY IF EXISTS "users_manage_own_billing_alerts" ON public.billing_alerts;
CREATE POLICY "users_manage_own_billing_alerts"
ON public.billing_alerts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Subscription Events
DROP POLICY IF EXISTS "users_view_own_subscription_events" ON public.subscription_events;
CREATE POLICY "users_view_own_subscription_events"
ON public.subscription_events
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Payment Disputes
DROP POLICY IF EXISTS "users_manage_own_payment_disputes" ON public.payment_disputes;
CREATE POLICY "users_manage_own_payment_disputes"
ON public.payment_disputes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Refund Records
DROP POLICY IF EXISTS "users_view_own_refund_records" ON public.refund_records;
CREATE POLICY "users_view_own_refund_records"
ON public.refund_records
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Payment Compliance Logs
DROP POLICY IF EXISTS "users_view_own_compliance_logs" ON public.payment_compliance_logs;
CREATE POLICY "users_view_own_compliance_logs"
ON public.payment_compliance_logs
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Payment Retry Logs
DROP POLICY IF EXISTS "users_view_own_retry_logs" ON public.payment_retry_logs;
CREATE POLICY "users_view_own_retry_logs"
ON public.payment_retry_logs
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Billing Preferences
DROP POLICY IF EXISTS "users_manage_own_billing_preferences" ON public.billing_preferences;
CREATE POLICY "users_manage_own_billing_preferences"
ON public.billing_preferences
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 14. TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS update_invoice_timestamp_trigger ON public.invoices;
CREATE TRIGGER update_invoice_timestamp_trigger
BEFORE UPDATE ON public.invoices
FOR EACH ROW
EXECUTE FUNCTION public.update_invoice_timestamp();

-- ============================================================
-- 15. MOCK DATA
-- ============================================================

DO $$
DECLARE
  existing_user_id UUID;
  existing_subscription_id UUID;
  payment_method_id UUID;
  invoice_id UUID;
BEGIN
  -- Get existing user
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) THEN
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
    
    IF existing_user_id IS NOT NULL THEN
      -- Get existing subscription
      SELECT id INTO existing_subscription_id 
      FROM public.user_subscriptions 
      WHERE user_id = existing_user_id 
      LIMIT 1;
      
      -- Create billing preferences
      INSERT INTO public.billing_preferences (
        user_id, email_alerts_enabled, failed_payment_alerts, 
        renewal_reminders, auto_renewal_enabled
      ) VALUES (
        existing_user_id, true, true, true, true
      )
      ON CONFLICT (user_id) DO NOTHING;
      
      -- Create payment method
      INSERT INTO public.payment_methods (
        id, user_id, payment_type, stripe_payment_method_id,
        card_brand, card_last4, card_exp_month, card_exp_year,
        is_default, billing_name, billing_email
      ) VALUES (
        gen_random_uuid(), existing_user_id, 'credit_card'::public.payment_method_type,
        'pm_demo_visa_4242', 'Visa', '4242', 12, 2026,
        true, 'Demo User', 'demo@example.com'
      )
      ON CONFLICT (id) DO NOTHING
      RETURNING id INTO payment_method_id;
      
      -- Create invoices
      INSERT INTO public.invoices (
        id, user_id, subscription_id, invoice_number,
        amount, status, line_items, billing_period_start,
        billing_period_end, paid_at
      ) VALUES (
        gen_random_uuid(), existing_user_id, existing_subscription_id,
        public.generate_invoice_number(), 9.99, 'paid'::public.invoice_status,
        jsonb_build_array(
          jsonb_build_object('description', 'Pro Monthly Subscription', 'amount', 9.99)
        ),
        CURRENT_TIMESTAMP - INTERVAL '30 days',
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP - INTERVAL '29 days'
      )
      ON CONFLICT (invoice_number) DO NOTHING
      RETURNING id INTO invoice_id;
      
      -- Create billing alert
      INSERT INTO public.billing_alerts (
        user_id, alert_type, title, message, related_invoice_id
      ) VALUES (
        existing_user_id, 'upcoming_renewal'::public.payment_alert_type,
        'Subscription Renewal', 
        'Your Pro subscription will renew in 5 days',
        invoice_id
      )
      ON CONFLICT (id) DO NOTHING;
      
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock billing data insertion failed: %', SQLERRM;
END $$;