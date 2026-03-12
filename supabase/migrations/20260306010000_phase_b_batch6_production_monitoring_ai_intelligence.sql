-- ============================================================
-- Phase B Batch 6 Final: Production Monitoring + AI Intelligence
-- Timestamp: 20260306010000
-- ============================================================

-- ============================================================
-- ENUMS
-- ============================================================

DO $$ BEGIN
  CREATE TYPE public.metric_type_enum AS ENUM (
    'crash_rate',
    'api_latency',
    'session_stability',
    'screen_errors',
    'network_failures'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.severity_enum AS ENUM ('low', 'medium', 'high', 'critical');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.breakdown_by_enum AS ENUM (
    'content_type',
    'audience_location',
    'partnership',
    'subscription_tier'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.remediation_action_type_enum AS ENUM (
    'service_restart',
    'fallback_api_activation',
    'circuit_breaker_engagement',
    'rate_limiting_adjustment',
    'alert_notification'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- PRODUCTION PERFORMANCE METRICS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.production_performance_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_type public.metric_type_enum NOT NULL,
  metric_value NUMERIC NOT NULL,
  screen_name TEXT,
  service_name TEXT,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  severity public.severity_enum NOT NULL DEFAULT 'low',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_production_metrics_type ON public.production_performance_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_production_metrics_timestamp ON public.production_performance_metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_production_metrics_severity ON public.production_performance_metrics(severity);
CREATE INDEX IF NOT EXISTS idx_production_metrics_screen ON public.production_performance_metrics(screen_name);

-- ============================================================
-- REMEDIATION ACTIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.remediation_actions (
  action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action_type public.remediation_action_type_enum NOT NULL,
  trigger_metric_id UUID REFERENCES public.production_performance_metrics(metric_id) ON DELETE SET NULL,
  action_result TEXT,
  execution_time NUMERIC,
  executed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_remediation_actions_type ON public.remediation_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_remediation_actions_executed ON public.remediation_actions(executed_at DESC);

-- ============================================================
-- EARNINGS BREAKDOWN ANALYTICS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.earnings_breakdown_analytics (
  breakdown_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  breakdown_by public.breakdown_by_enum NOT NULL,
  breakdown_key TEXT NOT NULL,
  revenue_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  transaction_count INTEGER NOT NULL DEFAULT 0,
  time_period TEXT NOT NULL,
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_earnings_breakdown_creator ON public.earnings_breakdown_analytics(creator_id);
CREATE INDEX IF NOT EXISTS idx_earnings_breakdown_type ON public.earnings_breakdown_analytics(breakdown_by);
CREATE INDEX IF NOT EXISTS idx_earnings_breakdown_period ON public.earnings_breakdown_analytics(period_start DESC);

-- ============================================================
-- REVENUE FORECASTS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.revenue_forecasts (
  forecast_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  forecast_date DATE NOT NULL,
  predicted_amount NUMERIC(12,2) NOT NULL,
  confidence_level NUMERIC(5,2) NOT NULL,
  forecast_method TEXT NOT NULL DEFAULT 'ARIMA',
  forecast_horizon_days INTEGER NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_revenue_forecasts_creator ON public.revenue_forecasts(creator_id);
CREATE INDEX IF NOT EXISTS idx_revenue_forecasts_date ON public.revenue_forecasts(forecast_date DESC);

-- ============================================================
-- TRANSCRIPT ANALYSIS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.transcript_analysis (
  analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  transcript_text TEXT NOT NULL,
  sentiment_score NUMERIC(5,2),
  key_themes TEXT[],
  trending_topics TEXT[],
  content_quality_score NUMERIC(5,2),
  viral_potential_score NUMERIC(5,2),
  controversy_level NUMERIC(5,2),
  analyzed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_transcript_analysis_election ON public.transcript_analysis(election_id);
CREATE INDEX IF NOT EXISTS idx_transcript_analysis_analyzed ON public.transcript_analysis(analyzed_at DESC);
CREATE INDEX IF NOT EXISTS idx_transcript_analysis_viral ON public.transcript_analysis(viral_potential_score DESC);

-- ============================================================
-- TRENDING ELECTIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.trending_elections (
  trending_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  trending_score NUMERIC(10,2) NOT NULL,
  vote_velocity NUMERIC(10,2),
  comment_engagement NUMERIC(10,2),
  semantic_relevance NUMERIC(5,2),
  trending_rank INTEGER,
  calculated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_trending_elections_election ON public.trending_elections(election_id);
CREATE INDEX IF NOT EXISTS idx_trending_elections_score ON public.trending_elections(trending_score DESC);
CREATE INDEX IF NOT EXISTS idx_trending_elections_calculated ON public.trending_elections(calculated_at DESC);

-- ============================================================
-- SEMANTIC SIMILARITY CACHE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.semantic_similarity_cache (
  similarity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_a_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  election_b_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  similarity_score NUMERIC(5,4) NOT NULL,
  embedding_vector JSONB,
  calculated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_a_id, election_b_id)
);

CREATE INDEX IF NOT EXISTS idx_semantic_similarity_a ON public.semantic_similarity_cache(election_a_id);
CREATE INDEX IF NOT EXISTS idx_semantic_similarity_b ON public.semantic_similarity_cache(election_b_id);
CREATE INDEX IF NOT EXISTS idx_semantic_similarity_score ON public.semantic_similarity_cache(similarity_score DESC);

-- ============================================================
-- MONETIZATION OPTIMIZATION RECOMMENDATIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.monetization_optimization_recommendations (
  recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recommendation_text TEXT NOT NULL,
  recommendation_category TEXT NOT NULL,
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  potential_impact NUMERIC(12,2),
  implemented BOOLEAN DEFAULT FALSE,
  implemented_at TIMESTAMPTZ,
  impact_measured NUMERIC(12,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_monetization_recommendations_creator ON public.monetization_optimization_recommendations(creator_id);
CREATE INDEX IF NOT EXISTS idx_monetization_recommendations_priority ON public.monetization_optimization_recommendations(priority);

-- ============================================================
-- RLS POLICIES
-- ============================================================

-- Production Performance Metrics
ALTER TABLE public.production_performance_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view production metrics" ON public.production_performance_metrics;
CREATE POLICY "Admins can view production metrics"
ON public.production_performance_metrics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'system_admin')
    )
  );

-- Remediation Actions
ALTER TABLE public.remediation_actions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view remediation actions" ON public.remediation_actions;
CREATE POLICY "Admins can view remediation actions"
ON public.remediation_actions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'system_admin')
    )
  );

-- Earnings Breakdown Analytics
ALTER TABLE public.earnings_breakdown_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view their own earnings breakdown" ON public.earnings_breakdown_analytics;
CREATE POLICY "Creators can view their own earnings breakdown"
ON public.earnings_breakdown_analytics
  FOR SELECT
  USING (creator_id = auth.uid());

-- Revenue Forecasts
ALTER TABLE public.revenue_forecasts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view their own forecasts" ON public.revenue_forecasts;
CREATE POLICY "Creators can view their own forecasts"
ON public.revenue_forecasts
  FOR SELECT
  USING (creator_id = auth.uid());

-- Transcript Analysis
ALTER TABLE public.transcript_analysis ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view transcript analysis" ON public.transcript_analysis;
CREATE POLICY "Users can view transcript analysis"
ON public.transcript_analysis
  FOR SELECT
  USING (true);

-- Trending Elections
ALTER TABLE public.trending_elections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view trending elections" ON public.trending_elections;
CREATE POLICY "Users can view trending elections"
ON public.trending_elections
  FOR SELECT
  USING (true);

-- Semantic Similarity Cache
ALTER TABLE public.semantic_similarity_cache ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view semantic similarity" ON public.semantic_similarity_cache;
CREATE POLICY "Users can view semantic similarity"
ON public.semantic_similarity_cache
  FOR SELECT
  USING (true);

-- Monetization Optimization Recommendations
ALTER TABLE public.monetization_optimization_recommendations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view their own recommendations" ON public.monetization_optimization_recommendations;
CREATE POLICY "Creators can view their own recommendations"
ON public.monetization_optimization_recommendations
  FOR SELECT
  USING (creator_id = auth.uid());

-- ============================================================
-- DATABASE FUNCTIONS
-- ============================================================

-- Calculate crash rate percentage
CREATE OR REPLACE FUNCTION public.calculate_crash_rate(
  p_screen_name TEXT,
  p_hours INTEGER DEFAULT 24
)
RETURNS NUMERIC AS $$
DECLARE
  v_crashes INTEGER;
  v_sessions INTEGER;
  v_crash_rate NUMERIC;
BEGIN
  SELECT COUNT(*)
  INTO v_crashes
  FROM public.production_performance_metrics
  WHERE metric_type = 'crash_rate'
    AND screen_name = p_screen_name
    AND timestamp >= NOW() - (p_hours || ' hours')::INTERVAL;

  SELECT COUNT(*)
  INTO v_sessions
  FROM public.production_performance_metrics
  WHERE metric_type = 'session_stability'
    AND screen_name = p_screen_name
    AND timestamp >= NOW() - (p_hours || ' hours')::INTERVAL;

  IF v_sessions = 0 THEN
    RETURN 0;
  END IF;

  v_crash_rate := (v_crashes::NUMERIC / v_sessions::NUMERIC) * 100;
  RETURN ROUND(v_crash_rate, 2);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get trending elections with scoring
CREATE OR REPLACE FUNCTION public.get_trending_elections(
  p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
  election_id UUID,
  title TEXT,
  trending_score NUMERIC,
  vote_velocity NUMERIC,
  comment_engagement NUMERIC,
  semantic_relevance NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.title,
    te.trending_score,
    te.vote_velocity,
    te.comment_engagement,
    te.semantic_relevance
  FROM public.trending_elections te
  JOIN public.elections e ON te.election_id = e.id
  WHERE te.calculated_at >= NOW() - INTERVAL '1 hour'
  ORDER BY te.trending_score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get semantic similar elections
CREATE OR REPLACE FUNCTION public.get_similar_elections(
  p_election_id UUID,
  p_similarity_threshold NUMERIC DEFAULT 0.8,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  election_id UUID,
  title TEXT,
  similarity_score NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.title,
    ssc.similarity_score
  FROM public.semantic_similarity_cache ssc
  JOIN public.elections e ON ssc.election_b_id = e.id
  WHERE ssc.election_a_id = p_election_id
    AND ssc.similarity_score >= p_similarity_threshold
  ORDER BY ssc.similarity_score DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get earnings breakdown by type
CREATE OR REPLACE FUNCTION public.get_earnings_breakdown(
  p_creator_id UUID,
  p_breakdown_by TEXT,
  p_days INTEGER DEFAULT 30
)
RETURNS TABLE (
  breakdown_key TEXT,
  revenue_amount NUMERIC,
  transaction_count INTEGER,
  avg_revenue_per_transaction NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    eba.breakdown_key,
    SUM(eba.revenue_amount) as revenue_amount,
    SUM(eba.transaction_count) as transaction_count,
    CASE 
      WHEN SUM(eba.transaction_count) > 0 THEN 
        ROUND(SUM(eba.revenue_amount) / SUM(eba.transaction_count), 2)
      ELSE 0
    END as avg_revenue_per_transaction
  FROM public.earnings_breakdown_analytics eba
  WHERE eba.creator_id = p_creator_id
    AND eba.breakdown_by = p_breakdown_by::public.breakdown_by_enum
    AND eba.period_start >= NOW() - (p_days || ' days')::INTERVAL
  GROUP BY eba.breakdown_key
  ORDER BY revenue_amount DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;