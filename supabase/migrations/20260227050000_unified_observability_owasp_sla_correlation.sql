-- Unified Carousel Observability Hub tables
-- unified_carousel_metrics table
CREATE TABLE IF NOT EXISTS public.unified_carousel_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50),
  performance_data JSONB DEFAULT '{}',
  claude_metrics JSONB DEFAULT '{}',
  accuracy_metrics JSONB DEFAULT '{}',
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure carousel_type column exists (handles case where table was created without it)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'unified_carousel_metrics'
      AND column_name = 'carousel_type'
  ) THEN
    ALTER TABLE public.unified_carousel_metrics ADD COLUMN carousel_type VARCHAR(50);
  END IF;
END;
$$;

-- Ensure recorded_at column exists in unified_carousel_metrics
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'unified_carousel_metrics'
      AND column_name = 'recorded_at'
  ) THEN
    ALTER TABLE public.unified_carousel_metrics ADD COLUMN recorded_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_unified_carousel_metrics_carousel_type
  ON public.unified_carousel_metrics (carousel_type);
CREATE INDEX IF NOT EXISTS idx_unified_carousel_metrics_recorded_at
  ON public.unified_carousel_metrics (recorded_at DESC);

-- carousel_observability_alerts table
CREATE TABLE IF NOT EXISTS public.carousel_observability_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type VARCHAR(50) NOT NULL,
  affected_carousel VARCHAR(100),
  severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  threshold_breached TEXT,
  resolved BOOLEAN DEFAULT FALSE,
  acknowledged BOOLEAN DEFAULT FALSE,
  acknowledged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_carousel_observability_alerts_resolved
  ON public.carousel_observability_alerts (resolved, created_at DESC);

-- carousel_recommendation_accuracy table
CREATE TABLE IF NOT EXISTS public.carousel_recommendation_accuracy (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50),
  recommended_items INTEGER DEFAULT 0,
  engaged_items INTEGER DEFAULT 0,
  accuracy_pct FLOAT DEFAULT 0,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ensure carousel_type column exists in carousel_recommendation_accuracy
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'carousel_recommendation_accuracy'
      AND column_name = 'carousel_type'
  ) THEN
    ALTER TABLE public.carousel_recommendation_accuracy ADD COLUMN carousel_type VARCHAR(50);
  END IF;
END;
$$;

-- Ensure recorded_at column exists in carousel_recommendation_accuracy
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'carousel_recommendation_accuracy'
      AND column_name = 'recorded_at'
  ) THEN
    ALTER TABLE public.carousel_recommendation_accuracy ADD COLUMN recorded_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_carousel_recommendation_accuracy_type
  ON public.carousel_recommendation_accuracy (carousel_type, recorded_at DESC);

-- OWASP Security Testing tables
CREATE TABLE IF NOT EXISTS public.owasp_test_runs (
  test_run_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_type VARCHAR(50) NOT NULL,
  findings_count INTEGER DEFAULT 0,
  critical_count INTEGER DEFAULT 0,
  high_count INTEGER DEFAULT 0,
  medium_count INTEGER DEFAULT 0,
  low_count INTEGER DEFAULT 0,
  test_results JSONB DEFAULT '{}',
  run_date TIMESTAMPTZ DEFAULT NOW(),
  remediation_status VARCHAR(20) DEFAULT 'pending' CHECK (remediation_status IN ('pending', 'in_progress', 'completed'))
);

CREATE INDEX IF NOT EXISTS idx_owasp_runs_run_date
  ON public.owasp_test_runs (run_date DESC, test_type);

-- dependency_vulnerabilities table
CREATE TABLE IF NOT EXISTS public.dependency_vulnerabilities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  package_name VARCHAR(100) NOT NULL,
  version VARCHAR(50),
  vulnerability_cve VARCHAR(50),
  severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  fix_version VARCHAR(50),
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  resolved BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_dependency_vulnerabilities_severity
  ON public.dependency_vulnerabilities (severity, resolved);

-- SLA Violation Correlations table (for Datadog cross-screen correlation)
CREATE TABLE IF NOT EXISTS public.sla_violation_correlations (
  correlation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  affected_screens JSONB DEFAULT '[]',
  common_root_cause TEXT,
  confidence_score FLOAT DEFAULT 0,
  correlation_data JSONB DEFAULT '{}',
  detected_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sla_violation_correlations_detected_at
  ON public.sla_violation_correlations (detected_at DESC);

-- RLS Policies
ALTER TABLE public.unified_carousel_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_observability_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_recommendation_accuracy ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.owasp_test_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dependency_vulnerabilities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sla_violation_correlations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role full access unified_carousel_metrics" ON public.unified_carousel_metrics;
CREATE POLICY "Service role full access unified_carousel_metrics"
  ON public.unified_carousel_metrics FOR ALL
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access carousel_observability_alerts" ON public.carousel_observability_alerts;
CREATE POLICY "Service role full access carousel_observability_alerts"
  ON public.carousel_observability_alerts FOR ALL
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access carousel_recommendation_accuracy" ON public.carousel_recommendation_accuracy;
CREATE POLICY "Service role full access carousel_recommendation_accuracy"
  ON public.carousel_recommendation_accuracy FOR ALL
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access owasp_test_runs" ON public.owasp_test_runs;
CREATE POLICY "Service role full access owasp_test_runs"
  ON public.owasp_test_runs FOR ALL
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access dependency_vulnerabilities" ON public.dependency_vulnerabilities;
CREATE POLICY "Service role full access dependency_vulnerabilities"
  ON public.dependency_vulnerabilities FOR ALL
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Service role full access sla_violation_correlations" ON public.sla_violation_correlations;
CREATE POLICY "Service role full access sla_violation_correlations"
  ON public.sla_violation_correlations FOR ALL
  USING (true) WITH CHECK (true);
