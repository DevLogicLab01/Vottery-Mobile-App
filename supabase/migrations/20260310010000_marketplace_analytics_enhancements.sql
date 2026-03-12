-- Marketplace Analytics Enhancements
-- Service conversion rates, buyer demographics, demand forecasting, revenue optimization

-- =====================================================
-- 1. ENSURE REQUIRED DEPENDENCIES EXIST
-- =====================================================

-- Create ENUMs if they don't exist
DO $$ BEGIN
  CREATE TYPE public.marketplace_service_type AS ENUM ('consultation', 'sponsored_content', 'exclusive_access', 'custom');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.marketplace_transaction_status AS ENUM ('pending', 'in_progress', 'delivered', 'completed', 'disputed', 'refunded', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Ensure marketplace_services table exists
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

-- Ensure marketplace_transactions table exists
CREATE TABLE IF NOT EXISTS public.marketplace_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES public.service_bookings(id) ON DELETE CASCADE,
  tier_selected TEXT,
  amount_paid DECIMAL(10, 2),
  platform_fee DECIMAL(10, 2),
  creator_earnings DECIMAL(10, 2),
  stripe_payment_intent_id TEXT,
  deliverables JSONB DEFAULT '[]'::JSONB,
  delivery_date TIMESTAMPTZ,
  buyer_approved_at TIMESTAMPTZ,
  dispute_reason TEXT,
  dispute_resolved_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_marketplace_transactions_booking_id ON public.marketplace_transactions(booking_id);

-- CRITICAL FIX: Ensure transaction_status column exists in marketplace_transactions
-- This must run BEFORE any functions reference this column
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'marketplace_transactions' 
    AND column_name = 'transaction_status'
  ) THEN
    ALTER TABLE public.marketplace_transactions 
      ADD COLUMN transaction_status public.marketplace_transaction_status DEFAULT 'pending'::public.marketplace_transaction_status;
    
    CREATE INDEX idx_marketplace_transactions_status ON public.marketplace_transactions(transaction_status);
  END IF;
END $$;

-- CRITICAL FIX: Add service_id column to existing marketplace_transactions table
-- This must run BEFORE any functions reference this column
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'marketplace_transactions' 
    AND column_name = 'service_id'
  ) THEN
    ALTER TABLE public.marketplace_transactions 
      ADD COLUMN service_id UUID REFERENCES public.marketplace_services(id) ON DELETE CASCADE;
    
    CREATE INDEX idx_marketplace_transactions_service_id ON public.marketplace_transactions(service_id);
  END IF;
END $$;

-- CRITICAL FIX: Ensure seller_id column exists in marketplace_transactions
-- This must run BEFORE any functions reference this column
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'marketplace_transactions' 
    AND column_name = 'seller_id'
  ) THEN
    ALTER TABLE public.marketplace_transactions 
      ADD COLUMN seller_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE;
    
    CREATE INDEX idx_marketplace_transactions_seller_id ON public.marketplace_transactions(seller_id);
  END IF;
END $$;

-- CRITICAL FIX: Ensure buyer_id column exists in marketplace_transactions
-- This must run BEFORE any functions reference this column
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'marketplace_transactions' 
    AND column_name = 'buyer_id'
  ) THEN
    ALTER TABLE public.marketplace_transactions 
      ADD COLUMN buyer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE;
    
    CREATE INDEX idx_marketplace_transactions_buyer_id ON public.marketplace_transactions(buyer_id);
  END IF;
END $$;

-- Ensure marketplace_reviews table exists
CREATE TABLE IF NOT EXISTS public.marketplace_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES public.marketplace_transactions(id) ON DELETE CASCADE,
  service_id UUID NOT NULL REFERENCES public.marketplace_services(id) ON DELETE CASCADE,
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

-- CRITICAL FIX: Ensure buyer_id column exists in marketplace_reviews
-- This runs BEFORE any trigger creation to prevent parse-time validation errors
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'marketplace_reviews' 
    AND column_name = 'buyer_id'
  ) THEN
    ALTER TABLE public.marketplace_reviews 
      ADD COLUMN buyer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE;
    
    CREATE INDEX idx_marketplace_reviews_buyer_id ON public.marketplace_reviews(buyer_id);
    
    -- Backfill buyer_id from transactions for existing reviews
    UPDATE public.marketplace_reviews mr
    SET buyer_id = mt.buyer_id
    FROM public.marketplace_transactions mt
    WHERE mr.transaction_id = mt.id
      AND mr.buyer_id IS NULL;
  END IF;
END $$;

-- =====================================================
-- 2. MARKETPLACE ANALYTICS ENHANCEMENTS
-- =====================================================

-- Service views and conversion tracking
CREATE TABLE IF NOT EXISTS public.marketplace_service_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES public.marketplace_services(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  view_type TEXT NOT NULL DEFAULT 'listing', -- listing, detail, click
  session_id TEXT,
  referrer TEXT,
  device_type TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_marketplace_service_views_service_id ON public.marketplace_service_views(service_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_service_views_viewer_id ON public.marketplace_service_views(viewer_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_service_views_created_at ON public.marketplace_service_views(created_at);

-- Service conversion metrics
CREATE TABLE IF NOT EXISTS public.marketplace_conversion_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES public.marketplace_services(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  analysis_period TEXT NOT NULL, -- 30_days, 60_days, 90_days
  total_views INTEGER DEFAULT 0,
  total_clicks INTEGER DEFAULT 0,
  total_purchases INTEGER DEFAULT 0,
  total_completions INTEGER DEFAULT 0,
  conversion_rate DECIMAL(5, 2) DEFAULT 0.00,
  click_through_rate DECIMAL(5, 2) DEFAULT 0.00,
  completion_rate DECIMAL(5, 2) DEFAULT 0.00,
  funnel_data JSONB DEFAULT '{}'::JSONB,
  trend_direction TEXT, -- up, down, stable
  trend_percentage DECIMAL(5, 2) DEFAULT 0.00,
  analysis_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(service_id, analysis_period, analysis_date)
);

CREATE INDEX IF NOT EXISTS idx_marketplace_conversion_metrics_service_id ON public.marketplace_conversion_metrics(service_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_conversion_metrics_creator_id ON public.marketplace_conversion_metrics(creator_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_conversion_metrics_analysis_date ON public.marketplace_conversion_metrics(analysis_date);

-- Buyer demographics
CREATE TABLE IF NOT EXISTS public.marketplace_buyer_demographics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  analysis_date DATE NOT NULL DEFAULT CURRENT_DATE,
  age_distribution JSONB DEFAULT '{}'::JSONB, -- {"18-24": 25, "25-34": 40, ...}
  gender_split JSONB DEFAULT '{}'::JSONB, -- {"male": 60, "female": 35, "other": 5}
  geographic_locations JSONB DEFAULT '{}'::JSONB, -- {"US": 45, "UK": 20, ...}
  device_types JSONB DEFAULT '{}'::JSONB, -- {"mobile": 70, "desktop": 25, "tablet": 5}
  spending_patterns JSONB DEFAULT '{}'::JSONB, -- {"low": 30, "medium": 50, "high": 20}
  total_buyers INTEGER DEFAULT 0,
  repeat_buyer_rate DECIMAL(5, 2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_id, analysis_date)
);

CREATE INDEX IF NOT EXISTS idx_marketplace_buyer_demographics_creator_id ON public.marketplace_buyer_demographics(creator_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_buyer_demographics_analysis_date ON public.marketplace_buyer_demographics(analysis_date);

-- Demand forecasting
CREATE TABLE IF NOT EXISTS public.marketplace_demand_forecasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  service_category TEXT NOT NULL,
  forecast_period TEXT NOT NULL, -- 30_days, 60_days, 90_days
  predicted_demand INTEGER DEFAULT 0,
  confidence_score DECIMAL(5, 2) DEFAULT 0.00,
  historical_trend TEXT, -- increasing, decreasing, stable
  seasonal_factors JSONB DEFAULT '{}'::JSONB,
  market_conditions JSONB DEFAULT '{}'::JSONB,
  forecast_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_id, service_category, forecast_period, forecast_date)
);

CREATE INDEX IF NOT EXISTS idx_marketplace_demand_forecasts_creator_id ON public.marketplace_demand_forecasts(creator_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_demand_forecasts_category ON public.marketplace_demand_forecasts(service_category);
CREATE INDEX IF NOT EXISTS idx_marketplace_demand_forecasts_date ON public.marketplace_demand_forecasts(forecast_date);

-- Revenue optimization recommendations
CREATE TABLE IF NOT EXISTS public.marketplace_revenue_optimizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  service_id UUID REFERENCES public.marketplace_services(id) ON DELETE CASCADE,
  optimization_type TEXT NOT NULL, -- pricing, delivery_time, description, portfolio
  current_value TEXT,
  recommended_value TEXT,
  expected_impact_percentage DECIMAL(5, 2) DEFAULT 0.00,
  confidence_level TEXT, -- high, medium, low
  reasoning TEXT,
  status TEXT DEFAULT 'pending', -- pending, applied, dismissed
  applied_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_marketplace_revenue_optimizations_creator_id ON public.marketplace_revenue_optimizations(creator_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_revenue_optimizations_service_id ON public.marketplace_revenue_optimizations(service_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_revenue_optimizations_status ON public.marketplace_revenue_optimizations(status);

-- =====================================================
-- 3. RLS POLICIES
-- =====================================================

-- marketplace_service_views policies
ALTER TABLE public.marketplace_service_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own service views"
  ON public.marketplace_service_views
  FOR SELECT
  USING (
    viewer_id = auth.uid()
    OR service_id IN (
      SELECT id FROM public.marketplace_services WHERE creator_id = auth.uid()
    )
  );

CREATE POLICY "Anyone can insert service views"
  ON public.marketplace_service_views
  FOR INSERT
  WITH CHECK (true);

-- marketplace_conversion_metrics policies
ALTER TABLE public.marketplace_conversion_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their own conversion metrics"
  ON public.marketplace_conversion_metrics
  FOR SELECT
  USING (creator_id = auth.uid());

CREATE POLICY "System can manage conversion metrics"
  ON public.marketplace_conversion_metrics
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- marketplace_buyer_demographics policies
ALTER TABLE public.marketplace_buyer_demographics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their own buyer demographics"
  ON public.marketplace_buyer_demographics
  FOR SELECT
  USING (creator_id = auth.uid());

CREATE POLICY "System can manage buyer demographics"
  ON public.marketplace_buyer_demographics
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- marketplace_demand_forecasts policies
ALTER TABLE public.marketplace_demand_forecasts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their own demand forecasts"
  ON public.marketplace_demand_forecasts
  FOR SELECT
  USING (creator_id = auth.uid());

CREATE POLICY "System can manage demand forecasts"
  ON public.marketplace_demand_forecasts
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- marketplace_revenue_optimizations policies
ALTER TABLE public.marketplace_revenue_optimizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their own revenue optimizations"
  ON public.marketplace_revenue_optimizations
  FOR SELECT
  USING (creator_id = auth.uid());

CREATE POLICY "Creators can update their own revenue optimizations"
  ON public.marketplace_revenue_optimizations
  FOR UPDATE
  USING (creator_id = auth.uid())
  WITH CHECK (creator_id = auth.uid());

CREATE POLICY "System can manage revenue optimizations"
  ON public.marketplace_revenue_optimizations
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- 4. ANALYTICS FUNCTIONS
-- =====================================================

-- Function to calculate service conversion metrics
CREATE OR REPLACE FUNCTION public.calculate_service_conversion_metrics(
  p_service_id UUID,
  p_analysis_period TEXT DEFAULT '30_days'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_creator_id UUID;
  v_total_views INTEGER;
  v_total_clicks INTEGER;
  v_total_purchases INTEGER;
  v_total_completions INTEGER;
  v_conversion_rate DECIMAL(5, 2);
  v_click_through_rate DECIMAL(5, 2);
  v_completion_rate DECIMAL(5, 2);
  v_period_interval INTERVAL;
BEGIN
  -- Get creator_id
  SELECT creator_id INTO v_creator_id
  FROM public.marketplace_services
  WHERE id = p_service_id;

  -- Determine period interval
  v_period_interval := CASE p_analysis_period
    WHEN '30_days' THEN INTERVAL '30 days'
    WHEN '60_days' THEN INTERVAL '60 days'
    WHEN '90_days' THEN INTERVAL '90 days'
    ELSE INTERVAL '30 days'
  END;

  -- Calculate views
  SELECT COUNT(*)
  INTO v_total_views
  FROM public.marketplace_service_views
  WHERE service_id = p_service_id
    AND created_at >= CURRENT_TIMESTAMP - v_period_interval;

  -- Calculate clicks (detail views)
  SELECT COUNT(*)
  INTO v_total_clicks
  FROM public.marketplace_service_views
  WHERE service_id = p_service_id
    AND view_type = 'detail'
    AND created_at >= CURRENT_TIMESTAMP - v_period_interval;

  -- Calculate purchases
  SELECT COUNT(*)
  INTO v_total_purchases
  FROM public.marketplace_transactions
  WHERE service_id = p_service_id
    AND created_at >= CURRENT_TIMESTAMP - v_period_interval;

  -- Calculate completions
  SELECT COUNT(*)
  INTO v_total_completions
  FROM public.marketplace_transactions
  WHERE service_id = p_service_id
    AND transaction_status = 'completed'
    AND created_at >= CURRENT_TIMESTAMP - v_period_interval;

  -- Calculate rates
  v_conversion_rate := CASE WHEN v_total_views > 0 
    THEN (v_total_purchases::DECIMAL / v_total_views) * 100 
    ELSE 0 
  END;

  v_click_through_rate := CASE WHEN v_total_views > 0 
    THEN (v_total_clicks::DECIMAL / v_total_views) * 100 
    ELSE 0 
  END;

  v_completion_rate := CASE WHEN v_total_purchases > 0 
    THEN (v_total_completions::DECIMAL / v_total_purchases) * 100 
    ELSE 0 
  END;

  -- Insert or update metrics
  INSERT INTO public.marketplace_conversion_metrics (
    service_id,
    creator_id,
    analysis_period,
    total_views,
    total_clicks,
    total_purchases,
    total_completions,
    conversion_rate,
    click_through_rate,
    completion_rate,
    analysis_date
  )
  VALUES (
    p_service_id,
    v_creator_id,
    p_analysis_period,
    v_total_views,
    v_total_clicks,
    v_total_purchases,
    v_total_completions,
    v_conversion_rate,
    v_click_through_rate,
    v_completion_rate,
    CURRENT_DATE
  )
  ON CONFLICT (service_id, analysis_period, analysis_date)
  DO UPDATE SET
    total_views = EXCLUDED.total_views,
    total_clicks = EXCLUDED.total_clicks,
    total_purchases = EXCLUDED.total_purchases,
    total_completions = EXCLUDED.total_completions,
    conversion_rate = EXCLUDED.conversion_rate,
    click_through_rate = EXCLUDED.click_through_rate,
    completion_rate = EXCLUDED.completion_rate;
END;
$$;

-- Function to calculate buyer demographics
CREATE OR REPLACE FUNCTION public.calculate_buyer_demographics(
  p_creator_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_total_buyers INTEGER;
  v_repeat_buyer_rate DECIMAL(5, 2);
BEGIN
  -- Calculate total unique buyers
  SELECT COUNT(DISTINCT buyer_id)
  INTO v_total_buyers
  FROM public.marketplace_transactions
  WHERE seller_id = p_creator_id
    AND created_at >= CURRENT_TIMESTAMP - INTERVAL '90 days';

  -- Calculate repeat buyer rate
  WITH buyer_counts AS (
    SELECT buyer_id, COUNT(*) as purchase_count
    FROM public.marketplace_transactions
    WHERE seller_id = p_creator_id
      AND created_at >= CURRENT_TIMESTAMP - INTERVAL '90 days'
    GROUP BY buyer_id
  )
  SELECT 
    CASE WHEN v_total_buyers > 0 
      THEN (COUNT(*) FILTER (WHERE purchase_count > 1)::DECIMAL / v_total_buyers) * 100 
      ELSE 0 
    END
  INTO v_repeat_buyer_rate
  FROM buyer_counts;

  -- Insert or update demographics
  INSERT INTO public.marketplace_buyer_demographics (
    creator_id,
    analysis_date,
    total_buyers,
    repeat_buyer_rate
  )
  VALUES (
    p_creator_id,
    CURRENT_DATE,
    v_total_buyers,
    v_repeat_buyer_rate
  )
  ON CONFLICT (creator_id, analysis_date)
  DO UPDATE SET
    total_buyers = EXCLUDED.total_buyers,
    repeat_buyer_rate = EXCLUDED.repeat_buyer_rate;
END;
$$;

-- =====================================================
-- 5. TRIGGER FUNCTIONS (Create functions first)
-- =====================================================

-- Function to update service stats on transaction
CREATE OR REPLACE FUNCTION public.update_marketplace_service_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.service_id IS NOT NULL THEN
    UPDATE public.marketplace_services
    SET total_orders = total_orders + 1
    WHERE id = NEW.service_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Function to update service rating on review
CREATE OR REPLACE FUNCTION public.update_marketplace_service_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_avg_rating DECIMAL(3, 2);
  v_total_reviews INTEGER;
BEGIN
  SELECT AVG(rating), COUNT(*)
  INTO v_avg_rating, v_total_reviews
  FROM public.marketplace_reviews
  WHERE service_id = NEW.service_id;

  UPDATE public.marketplace_services
  SET 
    average_rating = v_avg_rating,
    total_reviews = v_total_reviews
  WHERE id = NEW.service_id;
  
  RETURN NEW;
END;
$$;

-- =====================================================
-- 6. CREATE TRIGGERS (After all schema changes complete)
-- =====================================================

DROP TRIGGER IF EXISTS trigger_update_marketplace_service_stats ON public.marketplace_transactions;
CREATE TRIGGER trigger_update_marketplace_service_stats
  AFTER INSERT ON public.marketplace_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_marketplace_service_stats();

DROP TRIGGER IF EXISTS trigger_update_marketplace_service_rating ON public.marketplace_reviews;
CREATE TRIGGER trigger_update_marketplace_service_rating
  AFTER INSERT OR UPDATE ON public.marketplace_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.update_marketplace_service_rating();