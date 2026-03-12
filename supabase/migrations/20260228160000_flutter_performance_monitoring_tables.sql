-- Flutter Performance Monitoring Tables
-- Creates datadog_performance_metrics and performance_optimization_recommendations

-- Create datadog_performance_metrics table
CREATE TABLE IF NOT EXISTS public.datadog_performance_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_type VARCHAR(50) NOT NULL,
  screen_name VARCHAR(200),
  metric_value DECIMAL(10, 2) NOT NULL,
  threshold_value DECIMAL(10, 2),
  threshold_exceeded BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on metric_type and recorded_at, filtered for threshold exceeded
CREATE INDEX IF NOT EXISTS idx_perf_metrics
  ON public.datadog_performance_metrics (metric_type, recorded_at)
  WHERE threshold_exceeded = true;

-- Create index for screen-based queries
CREATE INDEX IF NOT EXISTS idx_perf_metrics_screen
  ON public.datadog_performance_metrics (screen_name, recorded_at);

-- Create performance_optimization_recommendations table
CREATE TABLE IF NOT EXISTS public.performance_optimization_recommendations (
  recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name VARCHAR(200) NOT NULL,
  issue_type VARCHAR(50) NOT NULL,
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  recommendation_text TEXT NOT NULL,
  implementation_guide TEXT,
  estimated_impact VARCHAR(50),
  applied BOOLEAN DEFAULT false,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  applied_at TIMESTAMPTZ
);

-- Create index for screen and severity, filtered for unapplied
CREATE INDEX IF NOT EXISTS idx_recommendations
  ON public.performance_optimization_recommendations (screen_name, severity)
  WHERE applied = false;

-- Enable RLS
ALTER TABLE public.datadog_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_optimization_recommendations ENABLE ROW LEVEL SECURITY;

-- RLS policies for datadog_performance_metrics (admin/service role access)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'datadog_performance_metrics'
    AND policyname = 'Service role can manage performance metrics'
  ) THEN
    CREATE POLICY "Service role can manage performance metrics"
      ON public.datadog_performance_metrics
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'datadog_performance_metrics'
    AND policyname = 'Authenticated users can read performance metrics'
  ) THEN
    CREATE POLICY "Authenticated users can read performance metrics"
      ON public.datadog_performance_metrics
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;

-- RLS policies for performance_optimization_recommendations
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'performance_optimization_recommendations'
    AND policyname = 'Service role can manage recommendations'
  ) THEN
    CREATE POLICY "Service role can manage recommendations"
      ON public.performance_optimization_recommendations
      FOR ALL
      TO service_role
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'performance_optimization_recommendations'
    AND policyname = 'Authenticated users can read recommendations'
  ) THEN
    CREATE POLICY "Authenticated users can read recommendations"
      ON public.performance_optimization_recommendations
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;
END $$;
