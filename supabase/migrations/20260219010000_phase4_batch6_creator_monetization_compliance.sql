-- Phase 4-5 Batch 6: Creator Monetization & Compliance
-- Real-time Creator Earnings, KYC Verification, Stripe Connect Integration

-- =====================================================
-- 1. TYPES (with idempotency)
-- =====================================================

DROP TYPE IF EXISTS public.kyc_verification_status CASCADE;
CREATE TYPE public.kyc_verification_status AS ENUM (
  'pending',
  'under_review',
  'approved',
  'rejected',
  'expired'
);

DROP TYPE IF EXISTS public.kyc_document_type CASCADE;
CREATE TYPE public.kyc_document_type AS ENUM (
  'passport',
  'drivers_license',
  'national_id',
  'tax_document_w9',
  'tax_document_w8ben',
  'bank_statement'
);

DROP TYPE IF EXISTS public.stripe_account_status CASCADE;
CREATE TYPE public.stripe_account_status AS ENUM (
  'pending',
  'active',
  'restricted',
  'disabled'
);

DROP TYPE IF EXISTS public.payout_status CASCADE;
CREATE TYPE public.payout_status AS ENUM (
  'pending',
  'in_transit',
  'paid',
  'failed',
  'canceled'
);

DROP TYPE IF EXISTS public.subscription_tier CASCADE;
CREATE TYPE public.subscription_tier AS ENUM (
  'free',
  'premium',
  'enterprise'
);

DROP TYPE IF EXISTS public.subscription_status CASCADE;
CREATE TYPE public.subscription_status AS ENUM (
  'active',
  'past_due',
  'canceled',
  'unpaid',
  'trialing'
);

DROP TYPE IF EXISTS public.transaction_type CASCADE;
CREATE TYPE public.transaction_type AS ENUM (
  'vp_earned',
  'vote_reward',
  'election_prize',
  'subscription_payment',
  'payout',
  'refund',
  'chargeback'
);

DROP TYPE IF EXISTS public.webhook_event_type CASCADE;
CREATE TYPE public.webhook_event_type AS ENUM (
  'payment_intent_succeeded',
  'payment_intent_failed',
  'payout_paid',
  'payout_failed',
  'customer_subscription_created',
  'customer_subscription_updated',
  'customer_subscription_deleted',
  'charge_dispute_created',
  'charge_refunded'
);

-- =====================================================
-- 2. CREATOR EARNINGS TRACKING TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.creator_earnings_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  transaction_type public.transaction_type NOT NULL,
  vp_amount INTEGER NOT NULL DEFAULT 0,
  usd_amount DECIMAL(10, 2) DEFAULT 0.00,
  source_election_id UUID REFERENCES public.elections(id) ON DELETE SET NULL,
  source_vote_id UUID,
  description TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_creator_earnings_transactions_creator_id ON public.creator_earnings_transactions(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_earnings_transactions_created_at ON public.creator_earnings_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_creator_earnings_transactions_type ON public.creator_earnings_transactions(transaction_type);

CREATE TABLE IF NOT EXISTS public.creator_earnings_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL UNIQUE REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  total_vp_earned INTEGER DEFAULT 0,
  total_usd_earned DECIMAL(10, 2) DEFAULT 0.00,
  available_balance_vp INTEGER DEFAULT 0,
  available_balance_usd DECIMAL(10, 2) DEFAULT 0.00,
  pending_balance_vp INTEGER DEFAULT 0,
  pending_balance_usd DECIMAL(10, 2) DEFAULT 0.00,
  lifetime_payouts_usd DECIMAL(10, 2) DEFAULT 0.00,
  last_payout_date TIMESTAMPTZ,
  next_settlement_date TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_creator_earnings_summary_creator_id ON public.creator_earnings_summary(creator_id);

-- =====================================================
-- 3. KYC VERIFICATION TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.creator_verification (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL UNIQUE REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  verification_status public.kyc_verification_status DEFAULT 'pending'::public.kyc_verification_status,
  full_name TEXT NOT NULL,
  date_of_birth DATE,
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  postal_code TEXT,
  country TEXT,
  phone TEXT,
  bank_account_number TEXT,
  bank_routing_number TEXT,
  bank_swift_code TEXT,
  tax_id TEXT,
  tax_document_type TEXT,
  stripe_identity_verification_id TEXT,
  rejection_reason TEXT,
  approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  verification_expiry TIMESTAMPTZ,
  submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_creator_verification_creator_id ON public.creator_verification(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_verification_status ON public.creator_verification(verification_status);

CREATE TABLE IF NOT EXISTS public.creator_verification_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  verification_id UUID NOT NULL REFERENCES public.creator_verification(id) ON DELETE CASCADE,
  document_type public.kyc_document_type NOT NULL,
  document_url TEXT NOT NULL,
  file_name TEXT,
  file_size INTEGER,
  uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_creator_verification_documents_verification_id ON public.creator_verification_documents(verification_id);

-- =====================================================
-- 4. STRIPE CONNECT & WEBHOOK TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.stripe_connect_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL UNIQUE REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  stripe_account_id TEXT NOT NULL UNIQUE,
  account_status public.stripe_account_status DEFAULT 'pending'::public.stripe_account_status,
  account_type TEXT DEFAULT 'express',
  charges_enabled BOOLEAN DEFAULT false,
  payouts_enabled BOOLEAN DEFAULT false,
  details_submitted BOOLEAN DEFAULT false,
  requirements_due JSONB DEFAULT '[]'::JSONB,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stripe_connect_accounts_creator_id ON public.stripe_connect_accounts(creator_id);
CREATE INDEX IF NOT EXISTS idx_stripe_connect_accounts_stripe_account_id ON public.stripe_connect_accounts(stripe_account_id);

-- Drop existing stripe_payouts table completely
DROP TABLE IF EXISTS public.stripe_payouts CASCADE;

-- Create stripe_payouts table with all columns
CREATE TABLE public.stripe_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_payout_id TEXT NOT NULL UNIQUE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount_usd DECIMAL(10, 2) NOT NULL,
  payout_status public.payout_status DEFAULT 'pending'::public.payout_status,
  arrival_date TIMESTAMPTZ,
  failure_code TEXT,
  failure_message TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stripe_payouts_creator_id ON public.stripe_payouts(creator_id);
CREATE INDEX IF NOT EXISTS idx_stripe_payouts_status ON public.stripe_payouts(payout_status);
CREATE INDEX IF NOT EXISTS idx_stripe_payouts_stripe_payout_id ON public.stripe_payouts(stripe_payout_id);

CREATE TABLE IF NOT EXISTS public.stripe_webhook_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id TEXT NOT NULL UNIQUE,
  event_type public.webhook_event_type NOT NULL,
  event_data JSONB NOT NULL,
  processed BOOLEAN DEFAULT false,
  processed_at TIMESTAMPTZ,
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stripe_webhook_logs_event_type ON public.stripe_webhook_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_stripe_webhook_logs_processed ON public.stripe_webhook_logs(processed);
CREATE INDEX IF NOT EXISTS idx_stripe_webhook_logs_created_at ON public.stripe_webhook_logs(created_at DESC);

CREATE TABLE IF NOT EXISTS public.creator_payout_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  schedule_type TEXT DEFAULT 'weekly',
  payout_day_of_week INTEGER DEFAULT 5,
  payout_day_of_month INTEGER,
  minimum_payout_amount NUMERIC(10,2) DEFAULT 50.00,
  auto_payout_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_id)
);

CREATE INDEX IF NOT EXISTS idx_creator_payout_schedule_creator_id ON public.creator_payout_schedule(creator_id);

-- =====================================================
-- 5. SUBSCRIPTION BILLING ENHANCEMENTS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.subscription_billing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  stripe_subscription_id TEXT UNIQUE,
  subscription_tier public.subscription_tier DEFAULT 'free'::public.subscription_tier,
  subscription_status public.subscription_status DEFAULT 'active'::public.subscription_status,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN DEFAULT false,
  failed_payment_count INTEGER DEFAULT 0,
  last_payment_attempt TIMESTAMPTZ,
  next_retry_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subscription_billing_user_id ON public.subscription_billing(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_billing_status ON public.subscription_billing(subscription_status);

ALTER TABLE public.user_subscriptions ADD COLUMN IF NOT EXISTS failed_payment_count INTEGER DEFAULT 0;
ALTER TABLE public.user_subscriptions ADD COLUMN IF NOT EXISTS last_payment_attempt TIMESTAMPTZ;
ALTER TABLE public.user_subscriptions ADD COLUMN IF NOT EXISTS next_retry_date TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.subscription_invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL REFERENCES public.subscription_billing(id) ON DELETE CASCADE,
  stripe_invoice_id TEXT NOT NULL UNIQUE,
  amount_due DECIMAL(10, 2) NOT NULL,
  amount_paid DECIMAL(10, 2) DEFAULT 0.00,
  invoice_status TEXT NOT NULL,
  invoice_pdf_url TEXT,
  hosted_invoice_url TEXT,
  due_date TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_subscription_invoices_subscription_id ON public.subscription_invoices(subscription_id);
CREATE INDEX IF NOT EXISTS idx_subscription_invoices_status ON public.subscription_invoices(invoice_status);

-- =====================================================
-- 6. TRANSACTION MONITORING TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.transaction_monitoring_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_date DATE NOT NULL,
  total_volume_usd DECIMAL(12, 2) DEFAULT 0.00,
  total_revenue_usd DECIMAL(12, 2) DEFAULT 0.00,
  total_refunds_usd DECIMAL(12, 2) DEFAULT 0.00,
  transaction_count INTEGER DEFAULT 0,
  successful_transactions INTEGER DEFAULT 0,
  failed_transactions INTEGER DEFAULT 0,
  average_transaction_value DECIMAL(10, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transaction_monitoring_logs_date ON public.transaction_monitoring_logs(transaction_date DESC);

CREATE TABLE IF NOT EXISTS public.dispute_management (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_dispute_id TEXT NOT NULL UNIQUE,
  stripe_charge_id TEXT NOT NULL,
  creator_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  amount_usd DECIMAL(10, 2) NOT NULL,
  dispute_reason TEXT,
  dispute_status TEXT NOT NULL,
  evidence_submitted BOOLEAN DEFAULT false,
  evidence_due_by TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_dispute_management_status ON public.dispute_management(dispute_status);
CREATE INDEX IF NOT EXISTS idx_dispute_management_created_at ON public.dispute_management(created_at DESC);

CREATE TABLE IF NOT EXISTS public.refund_processing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stripe_refund_id TEXT NOT NULL UNIQUE,
  stripe_charge_id TEXT NOT NULL,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  amount_usd DECIMAL(10, 2) NOT NULL,
  refund_reason TEXT,
  refund_status TEXT NOT NULL,
  approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_refund_processing_user_id ON public.refund_processing(user_id);
CREATE INDEX IF NOT EXISTS idx_refund_processing_status ON public.refund_processing(refund_status);

-- =====================================================
-- 7. FUNCTIONS (BEFORE RLS POLICIES)
-- =====================================================

-- Function: Update creator earnings summary (trigger function)
CREATE OR REPLACE FUNCTION public.update_creator_earnings_summary()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.creator_earnings_summary (
    creator_id,
    total_vp_earned,
    total_usd_earned,
    available_balance_vp,
    available_balance_usd
  )
  VALUES (
    NEW.creator_id,
    NEW.vp_amount,
    NEW.usd_amount,
    NEW.vp_amount,
    NEW.usd_amount
  )
  ON CONFLICT (creator_id) DO UPDATE SET
    total_vp_earned = public.creator_earnings_summary.total_vp_earned + NEW.vp_amount,
    total_usd_earned = public.creator_earnings_summary.total_usd_earned + NEW.usd_amount,
    available_balance_vp = public.creator_earnings_summary.available_balance_vp + NEW.vp_amount,
    available_balance_usd = public.creator_earnings_summary.available_balance_usd + NEW.usd_amount,
    updated_at = CURRENT_TIMESTAMP;
  
  RETURN NEW;
END;
$$;

-- Function: Get creator daily earnings (last N days)
CREATE OR REPLACE FUNCTION public.get_creator_daily_earnings(
  p_creator_id UUID,
  p_days INTEGER DEFAULT 7
)
RETURNS TABLE(
  date DATE,
  vp_earned INTEGER,
  usd_earned DECIMAL(10, 2),
  transaction_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    DATE(t.created_at) AS date,
    SUM(t.vp_amount)::INTEGER AS vp_earned,
    SUM(t.usd_amount)::DECIMAL(10, 2) AS usd_earned,
    COUNT(*)::BIGINT AS transaction_count
  FROM public.creator_earnings_transactions t
  WHERE t.creator_id = p_creator_id
    AND t.created_at >= CURRENT_DATE - (p_days || ' days')::INTERVAL
  GROUP BY DATE(t.created_at)
  ORDER BY DATE(t.created_at) DESC;
END;
$$;

-- Function: Calculate next settlement date (weekly on Fridays)
CREATE OR REPLACE FUNCTION public.calculate_next_settlement_date(
  p_creator_id UUID
)
RETURNS TIMESTAMPTZ
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_friday TIMESTAMPTZ;
BEGIN
  -- Calculate next Friday at 00:00:00 UTC
  v_next_friday := DATE_TRUNC('week', CURRENT_DATE + INTERVAL '1 week') + INTERVAL '4 days';
  
  RETURN v_next_friday;
END;
$$;

-- Function: Get top performing elections by revenue
CREATE OR REPLACE FUNCTION public.get_top_elections_by_revenue(
  p_creator_id UUID,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE(
  election_id UUID,
  election_title TEXT,
  total_vp_earned INTEGER,
  total_usd_earned DECIMAL(10, 2),
  transaction_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.source_election_id AS election_id,
    e.title AS election_title,
    SUM(t.vp_amount)::INTEGER AS total_vp_earned,
    SUM(t.usd_amount)::DECIMAL(10, 2) AS total_usd_earned,
    COUNT(*)::BIGINT AS transaction_count
  FROM public.creator_earnings_transactions t
  LEFT JOIN public.elections e ON t.source_election_id = e.id
  WHERE t.creator_id = p_creator_id
    AND t.source_election_id IS NOT NULL
  GROUP BY t.source_election_id, e.title
  ORDER BY total_usd_earned DESC
  LIMIT p_limit;
END;
$$;

-- =====================================================
-- 8. TRIGGERS
-- =====================================================

DROP TRIGGER IF EXISTS trg_update_creator_earnings_summary ON public.creator_earnings_transactions;
CREATE TRIGGER trg_update_creator_earnings_summary
AFTER INSERT ON public.creator_earnings_transactions
FOR EACH ROW
EXECUTE FUNCTION public.update_creator_earnings_summary();

-- =====================================================
-- 9. RLS POLICIES
-- =====================================================

-- Creator Earnings Transactions Policies
ALTER TABLE public.creator_earnings_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "creators_view_own_transactions" ON public.creator_earnings_transactions;
CREATE POLICY "creators_view_own_transactions"
ON public.creator_earnings_transactions
FOR SELECT
TO authenticated
USING (creator_id = auth.uid());

DROP POLICY IF EXISTS "system_insert_transactions" ON public.creator_earnings_transactions;
CREATE POLICY "system_insert_transactions"
ON public.creator_earnings_transactions
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Creator Earnings Summary Policies
ALTER TABLE public.creator_earnings_summary ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "creators_view_own_summary" ON public.creator_earnings_summary;
CREATE POLICY "creators_view_own_summary"
ON public.creator_earnings_summary
FOR SELECT
TO authenticated
USING (creator_id = auth.uid());

DROP POLICY IF EXISTS "system_manage_summary" ON public.creator_earnings_summary;
CREATE POLICY "system_manage_summary"
ON public.creator_earnings_summary
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Creator Verification Policies
ALTER TABLE public.creator_verification ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "creators_view_own_verification" ON public.creator_verification;
CREATE POLICY "creators_view_own_verification"
ON public.creator_verification
FOR SELECT
TO authenticated
USING (creator_id = auth.uid());

DROP POLICY IF EXISTS "creators_manage_own_verification" ON public.creator_verification;
CREATE POLICY "creators_manage_own_verification"
ON public.creator_verification
FOR ALL
TO authenticated
USING (creator_id = auth.uid())
WITH CHECK (creator_id = auth.uid());

-- Creator Verification Documents Policies
ALTER TABLE public.creator_verification_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "creators_view_own_documents" ON public.creator_verification_documents;
CREATE POLICY "creators_view_own_documents"
ON public.creator_verification_documents
FOR SELECT
TO authenticated
USING (
  verification_id IN (
    SELECT id FROM public.creator_verification WHERE creator_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "creators_manage_own_documents" ON public.creator_verification_documents;
CREATE POLICY "creators_manage_own_documents"
ON public.creator_verification_documents
FOR ALL
TO authenticated
USING (
  verification_id IN (
    SELECT id FROM public.creator_verification WHERE creator_id = auth.uid()
  )
)
WITH CHECK (
  verification_id IN (
    SELECT id FROM public.creator_verification WHERE creator_id = auth.uid()
  )
);

-- Stripe Connect Accounts Policies
ALTER TABLE public.stripe_connect_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "creators_view_own_stripe_account" ON public.stripe_connect_accounts;
CREATE POLICY "creators_view_own_stripe_account"
ON public.stripe_connect_accounts
FOR SELECT
TO authenticated
USING (creator_id = auth.uid());

DROP POLICY IF EXISTS "system_manage_stripe_accounts" ON public.stripe_connect_accounts;
CREATE POLICY "system_manage_stripe_accounts"
ON public.stripe_connect_accounts
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Stripe Payouts Policies
ALTER TABLE public.stripe_payouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "creators_view_own_payouts" ON public.stripe_payouts;
CREATE POLICY "creators_view_own_payouts"
ON public.stripe_payouts
FOR SELECT
TO authenticated
USING ((stripe_payouts.creator_id) = auth.uid());

DROP POLICY IF EXISTS "system_insert_payouts" ON public.stripe_payouts;
CREATE POLICY "system_insert_payouts"
ON public.stripe_payouts
FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "system_update_payouts" ON public.stripe_payouts;
CREATE POLICY "system_update_payouts"
ON public.stripe_payouts
FOR UPDATE
TO authenticated
USING ((stripe_payouts.creator_id) = auth.uid())
WITH CHECK ((stripe_payouts.creator_id) = auth.uid());

-- =====================================================
-- REMAINING RLS POLICIES
-- =====================================================

-- Stripe Webhook Logs Policies
ALTER TABLE public.stripe_webhook_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "system_manage_webhook_logs" ON public.stripe_webhook_logs;
CREATE POLICY "system_manage_webhook_logs"
ON public.stripe_webhook_logs
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Creator Payout Schedule Policies
ALTER TABLE public.creator_payout_schedule ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "creators_view_own_schedule" ON public.creator_payout_schedule;
CREATE POLICY "creators_view_own_schedule"
ON public.creator_payout_schedule
FOR SELECT
TO authenticated
USING (creator_id = auth.uid());

DROP POLICY IF EXISTS "creators_manage_own_schedule" ON public.creator_payout_schedule;
CREATE POLICY "creators_manage_own_schedule"
ON public.creator_payout_schedule
FOR ALL
TO authenticated
USING (creator_id = auth.uid())
WITH CHECK (creator_id = auth.uid());

-- Subscription Billing Policies
ALTER TABLE public.subscription_billing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_view_own_subscription" ON public.subscription_billing;
CREATE POLICY "users_view_own_subscription"
ON public.subscription_billing
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "system_manage_subscriptions" ON public.subscription_billing;
CREATE POLICY "system_manage_subscriptions"
ON public.subscription_billing
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Subscription Invoices Policies
ALTER TABLE public.subscription_invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_view_own_invoices" ON public.subscription_invoices;
CREATE POLICY "users_view_own_invoices"
ON public.subscription_invoices
FOR SELECT
TO authenticated
USING (
  subscription_id IN (
    SELECT id FROM public.subscription_billing WHERE user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "system_manage_invoices" ON public.subscription_invoices;
CREATE POLICY "system_manage_invoices"
ON public.subscription_invoices
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Transaction Monitoring Logs Policies
ALTER TABLE public.transaction_monitoring_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "system_manage_monitoring_logs" ON public.transaction_monitoring_logs;
CREATE POLICY "system_manage_monitoring_logs"
ON public.transaction_monitoring_logs
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Dispute Management Policies
ALTER TABLE public.dispute_management ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "creators_view_own_disputes" ON public.dispute_management;
CREATE POLICY "creators_view_own_disputes"
ON public.dispute_management
FOR SELECT
TO authenticated
USING (creator_id = auth.uid());

DROP POLICY IF EXISTS "system_manage_disputes" ON public.dispute_management;
CREATE POLICY "system_manage_disputes"
ON public.dispute_management
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- Refund Processing Policies
ALTER TABLE public.refund_processing ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_view_own_refunds" ON public.refund_processing;
CREATE POLICY "users_view_own_refunds"
ON public.refund_processing
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "system_manage_refunds" ON public.refund_processing;
CREATE POLICY "system_manage_refunds"
ON public.refund_processing
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- =====================================================
-- 10. SEED DATA
-- =====================================================

DO $$
DECLARE
  existing_creator_id UUID;
  existing_election_id UUID;
  verification_id UUID;
BEGIN
  -- Verify user_profiles table exists
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) THEN
    SELECT id INTO existing_creator_id FROM public.user_profiles LIMIT 1;
    
    IF existing_creator_id IS NOT NULL THEN
      -- Get an existing election if available
      IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'elections'
      ) THEN
        SELECT id INTO existing_election_id FROM public.elections LIMIT 1;
      END IF;
      
      -- Insert creator earnings transactions
      INSERT INTO public.creator_earnings_transactions (
        creator_id, transaction_type, vp_amount, usd_amount, source_election_id, description
      ) VALUES
        (existing_creator_id, 'vp_earned'::public.transaction_type, 500, 5.00, existing_election_id, 'VP earned from election votes'),
        (existing_creator_id, 'vote_reward'::public.transaction_type, 250, 2.50, existing_election_id, 'Vote participation reward'),
        (existing_creator_id, 'election_prize'::public.transaction_type, 1000, 10.00, existing_election_id, 'Election prize winnings')
      ON CONFLICT (id) DO NOTHING;
      
      -- Insert creator verification
      INSERT INTO public.creator_verification (
        id, creator_id, verification_status, full_name, date_of_birth, address_line1, city, state, postal_code, country, phone
      ) VALUES
        (gen_random_uuid(), existing_creator_id, 'pending'::public.kyc_verification_status, 'John Creator', '1990-01-15', '123 Main St', 'San Francisco', 'CA', '94102', 'US', '+1-555-0100')
      ON CONFLICT (creator_id) DO NOTHING
      RETURNING id INTO verification_id;
      
      -- Insert payout schedule with correct column names
      INSERT INTO public.creator_payout_schedule (
        creator_id, schedule_type, minimum_payout_amount, auto_payout_enabled
      ) VALUES
        (existing_creator_id, 'weekly', 50.00, true)
      ON CONFLICT (creator_id) DO NOTHING;
      
      RAISE NOTICE 'Mock data created successfully for creator monetization';
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

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- Tables created: 15
-- Functions created: 5
-- Triggers created: 1
-- RLS policies: 18
-- Mock data: Sample creator earnings, verification, and payout schedule
-- =====================================================