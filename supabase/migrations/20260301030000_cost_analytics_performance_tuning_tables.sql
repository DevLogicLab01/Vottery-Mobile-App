-- Infrastructure costs tracking
CREATE TABLE IF NOT EXISTS public.infrastructure_costs (
  cost_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name VARCHAR(50) NOT NULL,
  monthly_cost DECIMAL(10, 2) NOT NULL DEFAULT 0,
  usage_metrics JSONB DEFAULT '{}',
  recorded_month DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(service_name, recorded_month)
);

CREATE INDEX IF NOT EXISTS idx_costs_month ON public.infrastructure_costs (recorded_month, service_name);

-- Cache ROI metrics
CREATE TABLE IF NOT EXISTS public.cache_roi_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  queries_eliminated INTEGER DEFAULT 0,
  cache_hits INTEGER DEFAULT 0,
  cache_misses INTEGER DEFAULT 0,
  cost_savings DECIMAL(10, 2) DEFAULT 0,
  roi_percentage DECIMAL(5, 2) DEFAULT 0,
  recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cache_roi_date ON public.cache_roi_metrics (recorded_date DESC);

-- Performance tuning recommendations from Perplexity
CREATE TABLE IF NOT EXISTS public.performance_tuning_recommendations (
  recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  patterns JSONB DEFAULT '[]',
  recommendations JSONB DEFAULT '[]',
  indexes JSONB DEFAULT '[]',
  predictions JSONB DEFAULT '{}',
  costs JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_perf_tuning_date ON public.performance_tuning_recommendations (created_at DESC);

-- Incident response log for Datadog-triggered actions
CREATE TABLE IF NOT EXISTS public.incident_response_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type VARCHAR(100),
  action VARCHAR(200),
  threshold DECIMAL(10, 4),
  actual_value DECIMAL(10, 4),
  consecutive_breaches INTEGER DEFAULT 0,
  actions_taken JSONB DEFAULT '[]',
  details JSONB DEFAULT '{}',
  service VARCHAR(100),
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_incident_log_created ON public.incident_response_log (created_at DESC);

-- Circuit breaker state
CREATE TABLE IF NOT EXISTS public.circuit_breaker_state (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service VARCHAR(100) UNIQUE NOT NULL,
  is_open BOOLEAN DEFAULT FALSE,
  activated_at TIMESTAMPTZ,
  activated_by VARCHAR(100),
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Database config for connection pool management
CREATE TABLE IF NOT EXISTS public.database_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key VARCHAR(100) UNIQUE NOT NULL,
  max_connections INTEGER DEFAULT 100,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by VARCHAR(100)
);

-- RLS Policies
ALTER TABLE public.infrastructure_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cache_roi_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_tuning_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_response_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.circuit_breaker_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.database_config ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'infrastructure_costs' AND policyname = 'infrastructure_costs_admin_all'
  ) THEN
    CREATE POLICY infrastructure_costs_admin_all ON public.infrastructure_costs FOR ALL USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'cache_roi_metrics' AND policyname = 'cache_roi_metrics_admin_all'
  ) THEN
    CREATE POLICY cache_roi_metrics_admin_all ON public.cache_roi_metrics FOR ALL USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'performance_tuning_recommendations' AND policyname = 'perf_tuning_admin_all'
  ) THEN
    CREATE POLICY perf_tuning_admin_all ON public.performance_tuning_recommendations FOR ALL USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'incident_response_log' AND policyname = 'incident_log_admin_all'
  ) THEN
    CREATE POLICY incident_log_admin_all ON public.incident_response_log FOR ALL USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'circuit_breaker_state' AND policyname = 'circuit_breaker_admin_all'
  ) THEN
    CREATE POLICY circuit_breaker_admin_all ON public.circuit_breaker_state FOR ALL USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'database_config' AND policyname = 'database_config_admin_all'
  ) THEN
    CREATE POLICY database_config_admin_all ON public.database_config FOR ALL USING (true);
  END IF;
END $$;
