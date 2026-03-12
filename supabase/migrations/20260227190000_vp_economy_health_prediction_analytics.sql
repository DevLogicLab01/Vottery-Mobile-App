-- VP Economy Health Monitor tables
-- Creates vp_economy_metrics and vp_economy_incidents tables

CREATE TABLE IF NOT EXISTS public.vp_economy_metrics (
  metric_id DATE PRIMARY KEY DEFAULT CURRENT_DATE,
  total_vp_earned BIGINT DEFAULT 0,
  total_vp_spent BIGINT DEFAULT 0,
  circulation_velocity DECIMAL(8, 4) DEFAULT 0,
  inflation_rate DECIMAL(8, 4) DEFAULT 0,
  earning_spending_ratio DECIMAL(8, 4) DEFAULT 0,
  zone_redemption_rates JSONB DEFAULT '{}',
  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.vp_economy_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name VARCHAR(100) NOT NULL,
  current_value DECIMAL(12, 4) NOT NULL,
  threshold_value DECIMAL(12, 4) NOT NULL,
  deviation_percentage DECIMAL(8, 2) DEFAULT 0,
  alert_severity VARCHAR(20) DEFAULT 'medium' CHECK (alert_severity IN ('low', 'medium', 'high', 'critical')),
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved')),
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vp_economy_incidents_status ON public.vp_economy_incidents(status);
CREATE INDEX IF NOT EXISTS idx_vp_economy_incidents_created ON public.vp_economy_incidents(created_at DESC);

-- Prediction analytics table
CREATE TABLE IF NOT EXISTS public.prediction_pool_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID,
  total_predictions INTEGER DEFAULT 0,
  unique_predictors INTEGER DEFAULT 0,
  avg_brier_score DECIMAL(6, 4) DEFAULT 0,
  total_vp_distributed INTEGER DEFAULT 0,
  fraud_alerts_count INTEGER DEFAULT 0,
  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prediction_pool_analytics_pool ON public.prediction_pool_analytics(pool_id);

-- RLS Policies
ALTER TABLE public.vp_economy_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vp_economy_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prediction_pool_analytics ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'vp_economy_metrics' AND policyname = 'admin_vp_economy_metrics'
  ) THEN
    CREATE POLICY admin_vp_economy_metrics ON public.vp_economy_metrics
      FOR ALL USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'vp_economy_incidents' AND policyname = 'admin_vp_economy_incidents'
  ) THEN
    CREATE POLICY admin_vp_economy_incidents ON public.vp_economy_incidents
      FOR ALL USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'prediction_pool_analytics' AND policyname = 'admin_prediction_pool_analytics'
  ) THEN
    CREATE POLICY admin_prediction_pool_analytics ON public.prediction_pool_analytics
      FOR ALL USING (true);
  END IF;
END $$;
