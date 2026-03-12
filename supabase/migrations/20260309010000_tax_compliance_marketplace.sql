-- Tax Compliance Dashboard + Creator Marketplace Integration
-- Automated tax form generation, marketplace service listings, transaction management

-- =====================================================
-- 1. TYPES (with idempotency)
-- =====================================================

DROP TYPE IF EXISTS public.tax_document_type CASCADE;
CREATE TYPE public.tax_document_type AS ENUM (
  'form_1099_nec',
  'form_1099_k',
  'form_w9',
  'form_w8ben',
  'vat_return',
  'gst_return',
  'income_statement',
  'tax_exemption_certificate'
);

DROP TYPE IF EXISTS public.tax_document_status CASCADE;
CREATE TYPE public.tax_document_status AS ENUM (
  'pending',
  'generated',
  'submitted',
  'expired',
  'rejected'
);

DROP TYPE IF EXISTS public.marketplace_service_type CASCADE;
CREATE TYPE public.marketplace_service_type AS ENUM (
  'consultation',
  'sponsored_content',
  'exclusive_access',
  'collaboration_bundle',
  'shoutout',
  'election_promotion',
  'content_review'
);

DROP TYPE IF EXISTS public.marketplace_transaction_status CASCADE;
CREATE TYPE public.marketplace_transaction_status AS ENUM (
  'pending',
  'in_progress',
  'delivered',
  'completed',
  'disputed',
  'refunded',
  'cancelled'
);

-- =====================================================
-- 2. TAX COMPLIANCE TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.tax_compliance_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  document_type public.tax_document_type NOT NULL,
  tax_year INTEGER NOT NULL,
  file_url TEXT,
  file_name TEXT,
  file_size INTEGER,
  generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMPTZ,
  status public.tax_document_status DEFAULT 'pending'::public.tax_document_status,
  jurisdiction_code TEXT NOT NULL,
  jurisdiction_name TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tax_compliance_documents_creator_id ON public.tax_compliance_documents(creator_id);
CREATE INDEX IF NOT EXISTS idx_tax_compliance_documents_status ON public.tax_compliance_documents(status);
CREATE INDEX IF NOT EXISTS idx_tax_compliance_documents_expires_at ON public.tax_compliance_documents(expires_at);
CREATE INDEX IF NOT EXISTS idx_tax_compliance_documents_jurisdiction ON public.tax_compliance_documents(jurisdiction_code);
CREATE INDEX IF NOT EXISTS idx_tax_compliance_documents_tax_year ON public.tax_compliance_documents(tax_year);

CREATE TABLE IF NOT EXISTS public.tax_jurisdiction_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  jurisdiction_code TEXT NOT NULL,
  jurisdiction_name TEXT NOT NULL,
  registration_number TEXT,
  registration_date DATE,
  is_active BOOLEAN DEFAULT true,
  tax_exemption_status BOOLEAN DEFAULT false,
  exemption_certificate_url TEXT,
  compliance_score INTEGER DEFAULT 0,
  last_filing_date DATE,
  next_filing_due DATE,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_id, jurisdiction_code)
);

CREATE INDEX IF NOT EXISTS idx_tax_jurisdiction_registrations_creator_id ON public.tax_jurisdiction_registrations(creator_id);
CREATE INDEX IF NOT EXISTS idx_tax_jurisdiction_registrations_jurisdiction ON public.tax_jurisdiction_registrations(jurisdiction_code);

CREATE TABLE IF NOT EXISTS public.tax_expiration_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id UUID NOT NULL REFERENCES public.tax_compliance_documents(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reminder_type TEXT NOT NULL,
  days_before_expiration INTEGER NOT NULL,
  sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  email_sent BOOLEAN DEFAULT false,
  push_sent BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::JSONB
);

CREATE INDEX IF NOT EXISTS idx_tax_expiration_reminders_document_id ON public.tax_expiration_reminders(document_id);
CREATE INDEX IF NOT EXISTS idx_tax_expiration_reminders_creator_id ON public.tax_expiration_reminders(creator_id);

CREATE TABLE IF NOT EXISTS public.stripe_tax_calculations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  transaction_id UUID,
  calculation_id TEXT,
  amount_usd DECIMAL(10, 2) NOT NULL,
  tax_amount_usd DECIMAL(10, 2) DEFAULT 0.00,
  jurisdiction_code TEXT NOT NULL,
  tax_rate DECIMAL(5, 4) DEFAULT 0.0000,
  calculation_data JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_stripe_tax_calculations_creator_id ON public.stripe_tax_calculations(creator_id);
CREATE INDEX IF NOT EXISTS idx_stripe_tax_calculations_transaction_id ON public.stripe_tax_calculations(transaction_id);

-- =====================================================
-- 3. MARKETPLACE TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.marketplace_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  service_type public.marketplace_service_type NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  price_tiers JSONB NOT NULL DEFAULT '[]'::JSONB,
  delivery_time_days INTEGER NOT NULL DEFAULT 7,
  category TEXT,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  portfolio_items JSONB DEFAULT '[]'::JSONB,
  is_active BOOLEAN DEFAULT true,
  total_orders INTEGER DEFAULT 0,
  average_rating DECIMAL(3, 2) DEFAULT 0.00,
  total_reviews INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_marketplace_services_creator_id ON public.marketplace_services(creator_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_services_service_type ON public.marketplace_services(service_type);
CREATE INDEX IF NOT EXISTS idx_marketplace_services_is_active ON public.marketplace_services(is_active);
CREATE INDEX IF NOT EXISTS idx_marketplace_services_category ON public.marketplace_services(category);

CREATE TABLE IF NOT EXISTS public.marketplace_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.marketplace_services(id) ON DELETE CASCADE,
  tier_selected TEXT NOT NULL,
  amount_paid DECIMAL(10, 2) NOT NULL,
  platform_fee DECIMAL(10, 2) NOT NULL,
  creator_earnings DECIMAL(10, 2) NOT NULL,
  stripe_payment_intent_id TEXT,
  transaction_status public.marketplace_transaction_status DEFAULT 'pending'::public.marketplace_transaction_status,
  deliverables JSONB DEFAULT '[]'::JSONB,
  delivery_date TIMESTAMPTZ,
  buyer_approved_at TIMESTAMPTZ,
  dispute_reason TEXT,
  dispute_resolved_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_marketplace_transactions_buyer_id ON public.marketplace_transactions(buyer_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_transactions_seller_id ON public.marketplace_transactions(seller_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_transactions_service_id ON public.marketplace_transactions(service_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_transactions_status ON public.marketplace_transactions(transaction_status);

CREATE TABLE IF NOT EXISTS public.marketplace_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES public.marketplace_transactions(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.marketplace_services(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT,
  response_text TEXT,
  response_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_marketplace_reviews_transaction_id ON public.marketplace_reviews(transaction_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_reviews_service_id ON public.marketplace_reviews(service_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_reviews_seller_id ON public.marketplace_reviews(seller_id);

CREATE TABLE IF NOT EXISTS public.marketplace_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  analysis_date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_revenue_usd DECIMAL(10, 2) DEFAULT 0.00,
  total_orders INTEGER DEFAULT 0,
  average_order_value DECIMAL(10, 2) DEFAULT 0.00,
  conversion_rate DECIMAL(5, 2) DEFAULT 0.00,
  best_selling_service_id UUID REFERENCES public.marketplace_services(id) ON DELETE SET NULL,
  buyer_demographics JSONB DEFAULT '{}'::JSONB,
  service_performance JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_id, analysis_date)
);

CREATE INDEX IF NOT EXISTS idx_marketplace_analytics_creator_id ON public.marketplace_analytics(creator_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_analytics_analysis_date ON public.marketplace_analytics(analysis_date);

-- =====================================================
-- 4. EXTEND EXISTING TRANSACTION TYPE ENUM
-- =====================================================

-- Add marketplace_service to existing transaction_type enum if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum 
    WHERE enumlabel = 'marketplace_service' 
    AND enumtypid = 'public.transaction_type'::regtype
  ) THEN
    ALTER TYPE public.transaction_type ADD VALUE 'marketplace_service';
  END IF;
END$$;

-- =====================================================
-- 5. RLS POLICIES
-- =====================================================

-- Tax Compliance Documents
ALTER TABLE public.tax_compliance_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own tax documents" ON public.tax_compliance_documents;
CREATE POLICY "Creators can view own tax documents" ON public.tax_compliance_documents
  FOR SELECT USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can insert own tax documents" ON public.tax_compliance_documents;
CREATE POLICY "Creators can insert own tax documents" ON public.tax_compliance_documents
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can update own tax documents" ON public.tax_compliance_documents;
CREATE POLICY "Creators can update own tax documents" ON public.tax_compliance_documents
  FOR UPDATE USING (auth.uid() = creator_id);

-- Tax Jurisdiction Registrations
ALTER TABLE public.tax_jurisdiction_registrations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own jurisdiction registrations" ON public.tax_jurisdiction_registrations;
CREATE POLICY "Creators can view own jurisdiction registrations" ON public.tax_jurisdiction_registrations
  FOR SELECT USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can manage own jurisdiction registrations" ON public.tax_jurisdiction_registrations;
CREATE POLICY "Creators can manage own jurisdiction registrations" ON public.tax_jurisdiction_registrations
  FOR ALL USING (auth.uid() = creator_id);

-- Marketplace Services
ALTER TABLE public.marketplace_services ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view active marketplace services" ON public.marketplace_services;
CREATE POLICY "Anyone can view active marketplace services" ON public.marketplace_services
  FOR SELECT USING (is_active = true OR auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can manage own marketplace services" ON public.marketplace_services;
CREATE POLICY "Creators can manage own marketplace services" ON public.marketplace_services
  FOR ALL USING (auth.uid() = creator_id);

-- Marketplace Transactions
ALTER TABLE public.marketplace_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own marketplace transactions" ON public.marketplace_transactions;
CREATE POLICY "Users can view own marketplace transactions" ON public.marketplace_transactions
  FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

DROP POLICY IF EXISTS "Buyers can create marketplace transactions" ON public.marketplace_transactions;
CREATE POLICY "Buyers can create marketplace transactions" ON public.marketplace_transactions
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Sellers can update marketplace transactions" ON public.marketplace_transactions;
CREATE POLICY "Sellers can update marketplace transactions" ON public.marketplace_transactions
  FOR UPDATE USING (auth.uid() = seller_id);

-- Marketplace Reviews
ALTER TABLE public.marketplace_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view marketplace reviews" ON public.marketplace_reviews;
CREATE POLICY "Anyone can view marketplace reviews" ON public.marketplace_reviews
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Buyers can create marketplace reviews" ON public.marketplace_reviews;
CREATE POLICY "Buyers can create marketplace reviews" ON public.marketplace_reviews
  FOR INSERT WITH CHECK (auth.uid() = buyer_id);

DROP POLICY IF EXISTS "Sellers can respond to marketplace reviews" ON public.marketplace_reviews;
CREATE POLICY "Sellers can respond to marketplace reviews" ON public.marketplace_reviews
  FOR UPDATE USING (auth.uid() = seller_id);

-- Marketplace Analytics
ALTER TABLE public.marketplace_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own marketplace analytics" ON public.marketplace_analytics;
CREATE POLICY "Creators can view own marketplace analytics" ON public.marketplace_analytics
  FOR SELECT USING (auth.uid() = creator_id);

-- Stripe Tax Calculations
ALTER TABLE public.stripe_tax_calculations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own tax calculations" ON public.stripe_tax_calculations;
CREATE POLICY "Creators can view own tax calculations" ON public.stripe_tax_calculations
  FOR SELECT USING (auth.uid() = creator_id);

-- =====================================================
-- 6. STORAGE BUCKET FOR TAX DOCUMENTS
-- =====================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('tax-documents', 'tax-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for tax documents
DROP POLICY IF EXISTS "Creators can upload own tax documents" ON storage.objects;
CREATE POLICY "Creators can upload own tax documents" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'tax-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Creators can view own tax documents" ON storage.objects;
CREATE POLICY "Creators can view own tax documents" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'tax-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- =====================================================
-- 7. FUNCTIONS
-- =====================================================

-- Function to calculate marketplace revenue split
CREATE OR REPLACE FUNCTION calculate_marketplace_revenue_split(
  p_amount DECIMAL,
  p_country_code TEXT
)
RETURNS TABLE(
  platform_fee DECIMAL,
  creator_earnings DECIMAL
) AS $$
DECLARE
  v_creator_percentage DECIMAL;
BEGIN
  -- Get creator percentage from revenue splits table
  SELECT creator_percentage INTO v_creator_percentage
  FROM creator_revenue_splits
  WHERE country_code = p_country_code
  LIMIT 1;

  -- Default to 70/30 if country not found
  IF v_creator_percentage IS NULL THEN
    v_creator_percentage := 70.0;
  END IF;

  RETURN QUERY SELECT
    ROUND(p_amount * (100 - v_creator_percentage) / 100, 2) AS platform_fee,
    ROUND(p_amount * v_creator_percentage / 100, 2) AS creator_earnings;
END;
$$ LANGUAGE plpgsql;

-- Function to get expiring tax documents
CREATE OR REPLACE FUNCTION get_expiring_tax_documents(
  p_days_threshold INTEGER DEFAULT 90
)
RETURNS TABLE(
  document_id UUID,
  creator_id UUID,
  document_type TEXT,
  expires_at TIMESTAMPTZ,
  days_until_expiration INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    id,
    tax_compliance_documents.creator_id,
    tax_compliance_documents.document_type::TEXT,
    tax_compliance_documents.expires_at,
    EXTRACT(DAY FROM (tax_compliance_documents.expires_at - CURRENT_TIMESTAMP))::INTEGER
  FROM tax_compliance_documents
  WHERE
    status = 'generated' AND
    expires_at IS NOT NULL AND
    expires_at > CURRENT_TIMESTAMP AND
    expires_at <= CURRENT_TIMESTAMP + (p_days_threshold || ' days')::INTERVAL
  ORDER BY expires_at ASC;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 8. MOCK DATA
-- =====================================================

-- Insert sample tax compliance documents (only if table is empty)
DO $$
DECLARE
  v_creator_id UUID;
BEGIN
  -- Check if tax_compliance_documents table is empty
  IF NOT EXISTS (SELECT 1 FROM public.tax_compliance_documents LIMIT 1) THEN
    -- Get first creator from user_profiles
    SELECT id INTO v_creator_id FROM public.user_profiles LIMIT 1;

    IF v_creator_id IS NOT NULL THEN
      INSERT INTO public.tax_compliance_documents (
        creator_id, document_type, tax_year, status, jurisdiction_code, jurisdiction_name, expires_at
      ) VALUES
      (v_creator_id, 'form_1099_nec', 2025, 'generated', 'US', 'United States', CURRENT_TIMESTAMP + INTERVAL '60 days'),
      (v_creator_id, 'form_w9', 2025, 'generated', 'US', 'United States', CURRENT_TIMESTAMP + INTERVAL '365 days');
    END IF;
  END IF;
END$$;

-- Insert sample marketplace services (only if table is empty)
DO $$
DECLARE
  v_creator_id UUID;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.marketplace_services LIMIT 1) THEN
    SELECT id INTO v_creator_id FROM public.user_profiles LIMIT 1;

    IF v_creator_id IS NOT NULL THEN
      INSERT INTO public.marketplace_services (
        creator_id, service_type, title, description, price_tiers, delivery_time_days, category, is_active
      ) VALUES
      (v_creator_id, 'consultation', '1-on-1 Strategy Consultation', 'Get personalized advice on your election campaigns', 
       '[{"tier_name": "Basic", "price": 50, "deliverables": ["30-minute video call", "Strategy notes"]}, {"tier_name": "Premium", "price": 150, "deliverables": ["60-minute video call", "Detailed action plan", "Follow-up email support"]}]'::JSONB, 
       3, 'Consulting', true);
    END IF;
  END IF;
END$$;