-- Migration: Unlimited Audience Toggle + Subscription Analytics Dashboard
-- Description: Add unlimited audience size option to elections and comprehensive subscription analytics

-- =====================================================
-- PART 1: UNLIMITED AUDIENCE TOGGLE
-- =====================================================

-- Add unlimited audience size column to elections
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'elections' 
    AND column_name = 'unlimited_audience_size'
  ) THEN
    ALTER TABLE public.elections 
    ADD COLUMN unlimited_audience_size BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Add max audience size column (NULL means unlimited when unlimited_audience_size is true)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'elections' 
    AND column_name = 'max_audience_size'
  ) THEN
    ALTER TABLE public.elections 
    ADD COLUMN max_audience_size INTEGER DEFAULT NULL;
  END IF;
END $$;

-- Add auto-scaling settings for unlimited elections
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'elections' 
    AND column_name = 'auto_scaling_enabled'
  ) THEN
    ALTER TABLE public.elections 
    ADD COLUMN auto_scaling_enabled BOOLEAN DEFAULT TRUE;
  END IF;
END $$;

-- Add performance optimization indicators
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'elections' 
    AND column_name = 'performance_optimization_level'
  ) THEN
    ALTER TABLE public.elections 
    ADD COLUMN performance_optimization_level TEXT DEFAULT 'standard' CHECK (performance_optimization_level IN ('standard', 'high', 'extreme'));
  END IF;
END $$;

COMMENT ON COLUMN public.elections.unlimited_audience_size IS 'Enable unlimited audience size for election';
COMMENT ON COLUMN public.elections.max_audience_size IS 'Maximum audience size (NULL if unlimited)';
COMMENT ON COLUMN public.elections.auto_scaling_enabled IS 'Enable auto-scaling for large audiences';
COMMENT ON COLUMN public.elections.performance_optimization_level IS 'Performance optimization level: standard, high, extreme';

-- =====================================================
-- PART 2: SUBSCRIPTION ANALYTICS TABLES
-- =====================================================

-- Monthly Recurring Revenue (MRR) Tracking
CREATE TABLE IF NOT EXISTS public.subscription_mrr_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  month_year DATE NOT NULL,
  total_mrr DECIMAL(12, 2) DEFAULT 0,
  new_mrr DECIMAL(12, 2) DEFAULT 0,
  expansion_mrr DECIMAL(12, 2) DEFAULT 0,
  contraction_mrr DECIMAL(12, 2) DEFAULT 0,
  churned_mrr DECIMAL(12, 2) DEFAULT 0,
  net_new_mrr DECIMAL(12, 2) DEFAULT 0,
  active_subscriptions INTEGER DEFAULT 0,
  average_revenue_per_user DECIMAL(10, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(month_year)
);

COMMENT ON TABLE public.subscription_mrr_tracking IS 'Monthly Recurring Revenue tracking with expansion and contraction metrics';

-- Churn Analysis
CREATE TABLE IF NOT EXISTS public.subscription_churn_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  month_year DATE NOT NULL,
  total_churned_users INTEGER DEFAULT 0,
  voluntary_churn INTEGER DEFAULT 0,
  involuntary_churn INTEGER DEFAULT 0,
  churn_rate DECIMAL(5, 2) DEFAULT 0,
  revenue_churn_rate DECIMAL(5, 2) DEFAULT 0,
  churned_revenue DECIMAL(12, 2) DEFAULT 0,
  churn_reasons JSONB DEFAULT '{}',
  retention_rate DECIMAL(5, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(month_year)
);

COMMENT ON TABLE public.subscription_churn_analysis IS 'Comprehensive churn analysis with voluntary/involuntary breakdown';

-- LTV Cohort Analysis
CREATE TABLE IF NOT EXISTS public.subscription_ltv_cohorts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cohort_month DATE NOT NULL,
  cohort_size INTEGER DEFAULT 0,
  tier TEXT NOT NULL CHECK (tier IN ('basic', 'pro', 'elite')),
  month_0_revenue DECIMAL(12, 2) DEFAULT 0,
  month_1_revenue DECIMAL(12, 2) DEFAULT 0,
  month_2_revenue DECIMAL(12, 2) DEFAULT 0,
  month_3_revenue DECIMAL(12, 2) DEFAULT 0,
  month_6_revenue DECIMAL(12, 2) DEFAULT 0,
  month_12_revenue DECIMAL(12, 2) DEFAULT 0,
  cumulative_ltv DECIMAL(12, 2) DEFAULT 0,
  average_ltv DECIMAL(10, 2) DEFAULT 0,
  retention_month_1 DECIMAL(5, 2) DEFAULT 0,
  retention_month_3 DECIMAL(5, 2) DEFAULT 0,
  retention_month_6 DECIMAL(5, 2) DEFAULT 0,
  retention_month_12 DECIMAL(5, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(cohort_month, tier)
);

COMMENT ON TABLE public.subscription_ltv_cohorts IS 'Lifetime Value cohort analysis by subscription tier';

-- Revenue Forecasting
CREATE TABLE IF NOT EXISTS public.subscription_revenue_forecasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  forecast_month DATE NOT NULL,
  predicted_mrr DECIMAL(12, 2) DEFAULT 0,
  predicted_new_subscriptions INTEGER DEFAULT 0,
  predicted_churn_rate DECIMAL(5, 2) DEFAULT 0,
  confidence_level DECIMAL(5, 2) DEFAULT 0,
  forecast_model TEXT DEFAULT 'linear_regression',
  actual_mrr DECIMAL(12, 2) DEFAULT NULL,
  forecast_accuracy DECIMAL(5, 2) DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(forecast_month)
);

COMMENT ON TABLE public.subscription_revenue_forecasts IS 'AI-powered revenue forecasting with accuracy tracking';

-- Subscription Events for Analytics
CREATE TABLE IF NOT EXISTS public.subscription_analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('subscription_started', 'subscription_upgraded', 'subscription_downgraded', 'subscription_cancelled', 'subscription_reactivated', 'payment_failed', 'payment_succeeded')),
  tier TEXT NOT NULL CHECK (tier IN ('basic', 'pro', 'elite')),
  previous_tier TEXT CHECK (previous_tier IN ('basic', 'pro', 'elite')),
  mrr_impact DECIMAL(10, 2) DEFAULT 0,
  event_metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_subscription_analytics_events_user ON public.subscription_analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_subscription_analytics_events_type ON public.subscription_analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_subscription_analytics_events_created ON public.subscription_analytics_events(created_at DESC);

COMMENT ON TABLE public.subscription_analytics_events IS 'Detailed subscription events for analytics and MRR calculation';

-- =====================================================
-- FUNCTIONS FOR ANALYTICS CALCULATION
-- =====================================================

-- Function to calculate MRR for a given month
CREATE OR REPLACE FUNCTION public.calculate_monthly_mrr(target_month DATE)
RETURNS VOID AS $$
DECLARE
  v_total_mrr DECIMAL(12, 2);
  v_new_mrr DECIMAL(12, 2);
  v_expansion_mrr DECIMAL(12, 2);
  v_contraction_mrr DECIMAL(12, 2);
  v_churned_mrr DECIMAL(12, 2);
  v_active_subs INTEGER;
  v_arpu DECIMAL(10, 2);
BEGIN
  -- Calculate total MRR from active subscriptions
  SELECT COALESCE(SUM(
    CASE 
      WHEN tier = 'basic' AND billing_cycle = 'monthly' THEN 4.99
      WHEN tier = 'basic' AND billing_cycle = 'annual' THEN 4.99 * 0.83
      WHEN tier = 'pro' AND billing_cycle = 'monthly' THEN 9.99
      WHEN tier = 'pro' AND billing_cycle = 'annual' THEN 9.99 * 0.83
      WHEN tier = 'elite' AND billing_cycle = 'monthly' THEN 19.99
      WHEN tier = 'elite' AND billing_cycle = 'annual' THEN 19.99 * 0.83
      ELSE 0
    END
  ), 0), COUNT(*)
  INTO v_total_mrr, v_active_subs
  FROM public.user_subscriptions
  WHERE status = 'active'
  AND DATE_TRUNC('month', created_at) <= target_month;

  -- Calculate new MRR (subscriptions started this month)
  SELECT COALESCE(SUM(mrr_impact), 0)
  INTO v_new_mrr
  FROM public.subscription_analytics_events
  WHERE event_type = 'subscription_started'
  AND DATE_TRUNC('month', created_at) = target_month;

  -- Calculate expansion MRR (upgrades)
  SELECT COALESCE(SUM(mrr_impact), 0)
  INTO v_expansion_mrr
  FROM public.subscription_analytics_events
  WHERE event_type = 'subscription_upgraded'
  AND DATE_TRUNC('month', created_at) = target_month;

  -- Calculate contraction MRR (downgrades)
  SELECT COALESCE(SUM(ABS(mrr_impact)), 0)
  INTO v_contraction_mrr
  FROM public.subscription_analytics_events
  WHERE event_type = 'subscription_downgraded'
  AND DATE_TRUNC('month', created_at) = target_month;

  -- Calculate churned MRR
  SELECT COALESCE(SUM(ABS(mrr_impact)), 0)
  INTO v_churned_mrr
  FROM public.subscription_analytics_events
  WHERE event_type = 'subscription_cancelled'
  AND DATE_TRUNC('month', created_at) = target_month;

  -- Calculate ARPU
  v_arpu := CASE WHEN v_active_subs > 0 THEN v_total_mrr / v_active_subs ELSE 0 END;

  -- Insert or update MRR tracking
  INSERT INTO public.subscription_mrr_tracking (
    month_year, total_mrr, new_mrr, expansion_mrr, contraction_mrr, 
    churned_mrr, net_new_mrr, active_subscriptions, average_revenue_per_user
  )
  VALUES (
    target_month, v_total_mrr, v_new_mrr, v_expansion_mrr, v_contraction_mrr,
    v_churned_mrr, (v_new_mrr + v_expansion_mrr - v_contraction_mrr - v_churned_mrr),
    v_active_subs, v_arpu
  )
  ON CONFLICT (month_year) DO UPDATE SET
    total_mrr = EXCLUDED.total_mrr,
    new_mrr = EXCLUDED.new_mrr,
    expansion_mrr = EXCLUDED.expansion_mrr,
    contraction_mrr = EXCLUDED.contraction_mrr,
    churned_mrr = EXCLUDED.churned_mrr,
    net_new_mrr = EXCLUDED.net_new_mrr,
    active_subscriptions = EXCLUDED.active_subscriptions,
    average_revenue_per_user = EXCLUDED.average_revenue_per_user,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION public.calculate_monthly_mrr IS 'Calculate and store MRR metrics for a given month';

-- Enable RLS
ALTER TABLE public.subscription_mrr_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_churn_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_ltv_cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_revenue_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_analytics_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Admin only)
CREATE POLICY "Admin can view MRR tracking" ON public.subscription_mrr_tracking
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin can view churn analysis" ON public.subscription_churn_analysis
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin can view LTV cohorts" ON public.subscription_ltv_cohorts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin can view revenue forecasts" ON public.subscription_revenue_forecasts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

CREATE POLICY "Users can view their own subscription events" ON public.subscription_analytics_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admin can view all subscription events" ON public.subscription_analytics_events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );