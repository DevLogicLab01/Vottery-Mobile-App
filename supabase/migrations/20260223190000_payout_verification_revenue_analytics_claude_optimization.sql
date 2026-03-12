-- Phase: Payout Verification + Enhanced Revenue Analytics + Claude Revenue Optimization
-- Implements verification workflows, comprehensive analytics, and AI-powered revenue coaching

-- =====================================================
-- 1. TYPES
-- =====================================================

DROP TYPE IF EXISTS public.discrepancy_type CASCADE;
CREATE TYPE public.discrepancy_type AS ENUM ('missing_transaction', 'amount_mismatch', 'fee_error', 'currency_error', 'tax_error');

DROP TYPE IF EXISTS public.discrepancy_status CASCADE;
CREATE TYPE public.discrepancy_status AS ENUM ('open', 'investigating', 'resolved', 'escalated');

DROP TYPE IF EXISTS public.adjustment_type CASCADE;
CREATE TYPE public.adjustment_type AS ENUM ('increase_balance', 'decrease_balance', 'correct_fee', 'refund');

DROP TYPE IF EXISTS public.verification_status CASCADE;
CREATE TYPE public.verification_status AS ENUM ('pending_verification', 'verified', 'discrepancy', 'auto_verified');

DROP TYPE IF EXISTS public.recommendation_type CASCADE;
CREATE TYPE public.recommendation_type AS ENUM ('pricing', 'content', 'channel', 'efficiency');

DROP TYPE IF EXISTS public.recommendation_priority CASCADE;
CREATE TYPE public.recommendation_priority AS ENUM ('high', 'medium', 'low');

DROP TYPE IF EXISTS public.recommendation_status CASCADE;
CREATE TYPE public.recommendation_status AS ENUM ('pending', 'accepted', 'implemented', 'dismissed');

DROP TYPE IF EXISTS public.coaching_session_type CASCADE;
CREATE TYPE public.coaching_session_type AS ENUM ('weekly_checkin', 'on_demand', 'milestone');

-- =====================================================
-- 2. PAYOUT VERIFICATION TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.verification_discrepancies (
  discrepancy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  settlement_id UUID NOT NULL REFERENCES public.settlement_records(settlement_id) ON DELETE CASCADE,
  discrepancy_type public.discrepancy_type NOT NULL,
  discrepancy_amount DECIMAL(10,2) NOT NULL,
  description TEXT NOT NULL,
  evidence_urls JSONB DEFAULT '[]'::jsonb,
  status public.discrepancy_status DEFAULT 'open'::public.discrepancy_status,
  assigned_to UUID REFERENCES public.user_profiles(id),
  reported_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT
);

CREATE TABLE IF NOT EXISTS public.balance_adjustments (
  adjustment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  adjustment_type public.adjustment_type NOT NULL,
  adjustment_amount DECIMAL(10,2) NOT NULL,
  previous_balance DECIMAL(10,2) NOT NULL,
  new_balance DECIMAL(10,2) NOT NULL,
  reason TEXT NOT NULL,
  evidence_urls JSONB DEFAULT '[]'::jsonb,
  approved_by UUID REFERENCES public.user_profiles(id),
  adjusted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. ENHANCED REVENUE ANALYTICS TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.revenue_analytics_snapshots (
  snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  snapshot_date DATE NOT NULL,
  election_revenue DECIMAL(10,2) DEFAULT 0,
  marketplace_revenue DECIMAL(10,2) DEFAULT 0,
  ad_revenue DECIMAL(10,2) DEFAULT 0,
  referral_revenue DECIMAL(10,2) DEFAULT 0,
  total_revenue DECIMAL(10,2) NOT NULL,
  transaction_count INTEGER DEFAULT 0,
  avg_transaction_value DECIMAL(10,2) DEFAULT 0,
  forecast_next_month DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_user_id, snapshot_date)
);

CREATE TABLE IF NOT EXISTS public.tax_estimates (
  estimate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  tax_year INTEGER NOT NULL,
  quarter INTEGER CHECK (quarter >= 1 AND quarter <= 4),
  gross_earnings DECIMAL(10,2) NOT NULL,
  deductible_expenses DECIMAL(10,2) DEFAULT 0,
  taxable_income DECIMAL(10,2) NOT NULL,
  estimated_tax DECIMAL(10,2) NOT NULL,
  tax_type VARCHAR(50) NOT NULL,
  calculated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_user_id, tax_year, quarter, tax_type)
);

CREATE TABLE IF NOT EXISTS public.expense_records (
  expense_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  expense_category VARCHAR(100) NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  expense_date DATE NOT NULL,
  description TEXT,
  receipt_url VARCHAR(500),
  is_deductible BOOLEAN DEFAULT true,
  recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 4. CLAUDE REVENUE OPTIMIZATION TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.claude_optimization_recommendations (
  recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  recommendation_type public.recommendation_type NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  estimated_impact_usd DECIMAL(10,2),
  confidence DECIMAL(3,2) CHECK (confidence >= 0 AND confidence <= 1),
  priority public.recommendation_priority NOT NULL,
  timeframe VARCHAR(50),
  status public.recommendation_status DEFAULT 'pending'::public.recommendation_status,
  claude_reasoning TEXT,
  recommended_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  implemented_at TIMESTAMPTZ,
  actual_impact_usd DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS public.revenue_coaching_sessions (
  session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  session_type public.coaching_session_type NOT NULL,
  analysis_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  recommendations JSONB NOT NULL DEFAULT '[]'::jsonb,
  session_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 5. INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_verification_discrepancies_settlement ON public.verification_discrepancies(settlement_id);
CREATE INDEX IF NOT EXISTS idx_verification_discrepancies_status ON public.verification_discrepancies(status);
CREATE INDEX IF NOT EXISTS idx_verification_discrepancies_reported ON public.verification_discrepancies(reported_at DESC);

CREATE INDEX IF NOT EXISTS idx_balance_adjustments_creator ON public.balance_adjustments(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_balance_adjustments_adjusted ON public.balance_adjustments(adjusted_at DESC);

CREATE INDEX IF NOT EXISTS idx_revenue_snapshots_creator ON public.revenue_analytics_snapshots(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_revenue_snapshots_date ON public.revenue_analytics_snapshots(snapshot_date DESC);

CREATE INDEX IF NOT EXISTS idx_tax_estimates_creator ON public.tax_estimates(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_tax_estimates_year ON public.tax_estimates(tax_year DESC);

CREATE INDEX IF NOT EXISTS idx_expense_records_creator ON public.expense_records(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_expense_records_date ON public.expense_records(expense_date DESC);

CREATE INDEX IF NOT EXISTS idx_claude_recommendations_creator ON public.claude_optimization_recommendations(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_claude_recommendations_status ON public.claude_optimization_recommendations(status);
CREATE INDEX IF NOT EXISTS idx_claude_recommendations_priority ON public.claude_optimization_recommendations(priority);

CREATE INDEX IF NOT EXISTS idx_coaching_sessions_creator ON public.revenue_coaching_sessions(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_coaching_sessions_date ON public.revenue_coaching_sessions(session_date DESC);

-- =====================================================
-- 6. FUNCTIONS
-- =====================================================

-- Function to auto-verify low-risk payouts
CREATE OR REPLACE FUNCTION public.auto_verify_settlement(p_settlement_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_settlement RECORD;
  v_creator_tier TEXT;
  v_previous_discrepancies INTEGER;
BEGIN
  -- Get settlement details
  SELECT * INTO v_settlement
  FROM public.settlement_records
  WHERE settlement_id = p_settlement_id;
  
  IF NOT FOUND THEN
    RETURN false;
  END IF;
  
  -- Get creator tier
  SELECT tier_level INTO v_creator_tier
  FROM public.creator_accounts
  WHERE creator_user_id = v_settlement.creator_user_id;
  
  -- Check previous discrepancies
  SELECT COUNT(*) INTO v_previous_discrepancies
  FROM public.verification_discrepancies vd
  JOIN public.settlement_records sr ON vd.settlement_id = sr.settlement_id
  WHERE sr.creator_user_id = v_settlement.creator_user_id
  AND vd.status IN ('open', 'investigating');
  
  -- Auto-verify if: amount < $1000 AND no previous discrepancies AND tier >= Gold
  IF v_settlement.net_amount < 1000 
     AND v_previous_discrepancies = 0 
     AND v_creator_tier IN ('gold', 'platinum', 'elite') THEN
    
    UPDATE public.settlement_records
    SET verification_status = 'auto_verified'::public.verification_status,
        verified_at = CURRENT_TIMESTAMP
    WHERE settlement_id = p_settlement_id;
    
    RETURN true;
  END IF;
  
  RETURN false;
END;
$$;

-- Function to calculate revenue forecast
CREATE OR REPLACE FUNCTION public.calculate_revenue_forecast(
  p_creator_id UUID,
  p_months_ahead INTEGER DEFAULT 3
)
RETURNS TABLE (
  month_offset INTEGER,
  forecasted_revenue DECIMAL(10,2),
  confidence_min DECIMAL(10,2),
  confidence_max DECIMAL(10,2)
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_avg_revenue DECIMAL(10,2);
  v_growth_rate DECIMAL(5,4);
BEGIN
  -- Calculate average monthly revenue (last 6 months)
  SELECT AVG(total_revenue) INTO v_avg_revenue
  FROM public.revenue_analytics_snapshots
  WHERE creator_user_id = p_creator_id
  AND snapshot_date >= CURRENT_DATE - INTERVAL '6 months';
  
  -- Calculate growth rate
  WITH monthly_totals AS (
    SELECT 
      DATE_TRUNC('month', snapshot_date) AS month,
      SUM(total_revenue) AS revenue
    FROM public.revenue_analytics_snapshots
    WHERE creator_user_id = p_creator_id
    AND snapshot_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY DATE_TRUNC('month', snapshot_date)
    ORDER BY month
  )
  SELECT 
    CASE 
      WHEN COUNT(*) >= 2 THEN
        (MAX(revenue) - MIN(revenue)) / NULLIF(MIN(revenue), 0) / NULLIF(COUNT(*) - 1, 0)
      ELSE 0
    END INTO v_growth_rate
  FROM monthly_totals;
  
  -- Generate forecasts
  FOR i IN 1..p_months_ahead LOOP
    month_offset := i;
    forecasted_revenue := v_avg_revenue * POWER(1 + COALESCE(v_growth_rate, 0), i);
    confidence_min := forecasted_revenue * 0.8;
    confidence_max := forecasted_revenue * 1.2;
    RETURN NEXT;
  END LOOP;
END;
$$;

-- =====================================================
-- 7. ENABLE RLS
-- =====================================================

ALTER TABLE public.verification_discrepancies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.balance_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.revenue_analytics_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_estimates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.claude_optimization_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.revenue_coaching_sessions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 8. RLS POLICIES
-- =====================================================

-- Verification Discrepancies: Admin and finance team
DROP POLICY IF EXISTS "admin_manage_verification_discrepancies" ON public.verification_discrepancies;
CREATE POLICY "admin_manage_verification_discrepancies"
ON public.verification_discrepancies
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

-- Balance Adjustments: Admin only
DROP POLICY IF EXISTS "admin_manage_balance_adjustments" ON public.balance_adjustments;
CREATE POLICY "admin_manage_balance_adjustments"
ON public.balance_adjustments
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
);

DROP POLICY IF EXISTS "creator_view_own_adjustments" ON public.balance_adjustments;
CREATE POLICY "creator_view_own_adjustments"
ON public.balance_adjustments
FOR SELECT
TO authenticated
USING (creator_user_id = auth.uid());

-- Revenue Analytics Snapshots: Creator owns their data
DROP POLICY IF EXISTS "creator_manage_revenue_snapshots" ON public.revenue_analytics_snapshots;
CREATE POLICY "creator_manage_revenue_snapshots"
ON public.revenue_analytics_snapshots
FOR ALL
TO authenticated
USING (creator_user_id = auth.uid())
WITH CHECK (creator_user_id = auth.uid());

-- Tax Estimates: Creator owns their data
DROP POLICY IF EXISTS "creator_manage_tax_estimates" ON public.tax_estimates;
CREATE POLICY "creator_manage_tax_estimates"
ON public.tax_estimates
FOR ALL
TO authenticated
USING (creator_user_id = auth.uid())
WITH CHECK (creator_user_id = auth.uid());

-- Expense Records: Creator owns their data
DROP POLICY IF EXISTS "creator_manage_expense_records" ON public.expense_records;
CREATE POLICY "creator_manage_expense_records"
ON public.expense_records
FOR ALL
TO authenticated
USING (creator_user_id = auth.uid())
WITH CHECK (creator_user_id = auth.uid());

-- Claude Recommendations: Creator owns their data
DROP POLICY IF EXISTS "creator_manage_claude_recommendations" ON public.claude_optimization_recommendations;
CREATE POLICY "creator_manage_claude_recommendations"
ON public.claude_optimization_recommendations
FOR ALL
TO authenticated
USING (creator_user_id = auth.uid())
WITH CHECK (creator_user_id = auth.uid());

-- Coaching Sessions: Creator owns their data
DROP POLICY IF EXISTS "creator_manage_coaching_sessions" ON public.revenue_coaching_sessions;
CREATE POLICY "creator_manage_coaching_sessions"
ON public.revenue_coaching_sessions
FOR ALL
TO authenticated
USING (creator_user_id = auth.uid())
WITH CHECK (creator_user_id = auth.uid());

-- =====================================================
-- 9. MOCK DATA
-- =====================================================

-- Insert mock revenue analytics snapshots
DO $$
DECLARE
  v_creator_id UUID;
  v_date DATE;
BEGIN
  -- Get first creator from creator_accounts table
  SELECT creator_user_id INTO v_creator_id
  FROM public.creator_accounts
  LIMIT 1;
  
  IF v_creator_id IS NOT NULL THEN
    -- Insert last 12 months of data
    FOR i IN 0..11 LOOP
      v_date := CURRENT_DATE - (i || ' months')::INTERVAL;
      
      INSERT INTO public.revenue_analytics_snapshots (
        creator_user_id,
        snapshot_date,
        election_revenue,
        marketplace_revenue,
        ad_revenue,
        referral_revenue,
        total_revenue,
        transaction_count,
        avg_transaction_value,
        forecast_next_month
      ) VALUES (
        v_creator_id,
        v_date,
        500 + (RANDOM() * 1000)::DECIMAL(10,2),
        300 + (RANDOM() * 800)::DECIMAL(10,2),
        100 + (RANDOM() * 300)::DECIMAL(10,2),
        50 + (RANDOM() * 150)::DECIMAL(10,2),
        1000 + (RANDOM() * 2000)::DECIMAL(10,2),
        15 + (RANDOM() * 35)::INTEGER,
        20 + (RANDOM() * 80)::DECIMAL(10,2),
        1100 + (RANDOM() * 2200)::DECIMAL(10,2)
      )
      ON CONFLICT (creator_user_id, snapshot_date) DO NOTHING;
    END LOOP;
  END IF;
END;
$$;

-- Insert mock tax estimates
DO $$
DECLARE
  v_creator_id UUID;
BEGIN
  SELECT creator_user_id INTO v_creator_id
  FROM public.creator_accounts
  LIMIT 1;
  
  IF v_creator_id IS NOT NULL THEN
    INSERT INTO public.tax_estimates (
      creator_user_id,
      tax_year,
      quarter,
      gross_earnings,
      deductible_expenses,
      taxable_income,
      estimated_tax,
      tax_type
    ) VALUES
    (v_creator_id, 2026, 1, 15000, 2000, 13000, 1989, 'federal'),
    (v_creator_id, 2026, 1, 15000, 2000, 13000, 1989, 'self_employment'),
    (v_creator_id, 2025, 4, 12000, 1500, 10500, 1607, 'federal'),
    (v_creator_id, 2025, 4, 12000, 1500, 10500, 1607, 'self_employment')
    ON CONFLICT (creator_user_id, tax_year, quarter, tax_type) DO NOTHING;
  END IF;
END;
$$;

-- Insert mock expense records
DO $$
DECLARE
  v_creator_id UUID;
BEGIN
  SELECT creator_user_id INTO v_creator_id
  FROM public.creator_accounts
  LIMIT 1;
  
  IF v_creator_id IS NOT NULL THEN
    INSERT INTO public.expense_records (
      creator_user_id,
      expense_category,
      amount,
      expense_date,
      description,
      is_deductible
    ) VALUES
    (v_creator_id, 'Equipment', 1200, CURRENT_DATE - INTERVAL '30 days', 'Camera upgrade', true),
    (v_creator_id, 'Software', 99, CURRENT_DATE - INTERVAL '15 days', 'Video editing software subscription', true),
    (v_creator_id, 'Home Office', 500, CURRENT_DATE - INTERVAL '60 days', 'Desk and lighting setup', true),
    (v_creator_id, 'Travel', 350, CURRENT_DATE - INTERVAL '45 days', 'Conference attendance', true);
  END IF;
END;
$$;

-- Insert mock Claude recommendations
DO $$
DECLARE
  v_creator_id UUID;
BEGIN
  SELECT creator_user_id INTO v_creator_id
  FROM public.creator_accounts
  LIMIT 1;
  
  IF v_creator_id IS NOT NULL THEN
    INSERT INTO public.claude_optimization_recommendations (
      creator_user_id,
      recommendation_type,
      title,
      description,
      estimated_impact_usd,
      confidence,
      priority,
      timeframe,
      status,
      claude_reasoning
    ) VALUES
    (
      v_creator_id,
      'pricing'::public.recommendation_type,
      'Increase Service Prices by 15%',
      'Analysis shows demand supports higher pricing. Your marketplace services are priced 15% below market average for your quality tier.',
      2400,
      0.85,
      'high'::public.recommendation_priority,
      'immediate',
      'pending'::public.recommendation_status,
      'Based on 6-month demand elasticity analysis and competitor pricing data'
    ),
    (
      v_creator_id,
      'content'::public.recommendation_type,
      'Focus on Entertainment Category',
      'Your Entertainment elections generate 40% higher engagement than Politics. Shift content mix to 60% Entertainment.',
      1800,
      0.78,
      'high'::public.recommendation_priority,
      'short',
      'pending'::public.recommendation_status,
      'Engagement rate analysis across 100+ elections shows clear category preference'
    ),
    (
      v_creator_id,
      'channel'::public.recommendation_type,
      'Create 2 New Marketplace Services',
      'Photography and Design categories show high demand with low creator supply. Launch services in these niches.',
      1500,
      0.72,
      'medium'::public.recommendation_priority,
      'medium',
      'pending'::public.recommendation_status,
      'Market gap analysis identifies underserved high-value categories'
    );
  END IF;
END;
$$;

COMMENT ON TABLE public.verification_discrepancies IS 'Tracks settlement verification discrepancies for financial accuracy';
COMMENT ON TABLE public.balance_adjustments IS 'Records manual balance adjustments with audit trail';
COMMENT ON TABLE public.revenue_analytics_snapshots IS 'Daily revenue snapshots for trend analysis and forecasting';
COMMENT ON TABLE public.tax_estimates IS 'Quarterly tax liability estimates for creators';
COMMENT ON TABLE public.expense_records IS 'Creator expense tracking for tax deductions';
COMMENT ON TABLE public.claude_optimization_recommendations IS 'AI-powered revenue optimization recommendations';
COMMENT ON TABLE public.revenue_coaching_sessions IS 'Claude coaching session history and analysis';