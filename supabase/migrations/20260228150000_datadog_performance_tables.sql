-- Migration: Datadog Performance Metrics & Optimization Recommendations
-- Timestamp: 20260228150000

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

-- Add threshold_exceeded column if it doesn't exist (for idempotency)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'datadog_performance_metrics'
      AND column_name = 'threshold_exceeded'
  ) THEN
    ALTER TABLE public.datadog_performance_metrics
      ADD COLUMN threshold_exceeded BOOLEAN DEFAULT false;
  END IF;
END;
$$;

-- Add recorded_at column if it doesn't exist (for idempotency)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'datadog_performance_metrics'
      AND column_name = 'recorded_at'
  ) THEN
    ALTER TABLE public.datadog_performance_metrics
      ADD COLUMN recorded_at TIMESTAMPTZ DEFAULT NOW();
  END IF;
END;
$$;

-- Add screen_name column if it doesn't exist (idempotency guard for pre-existing tables)
-- and create idx_perf_metrics_screen only after column is guaranteed to exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'datadog_performance_metrics'
      AND column_name = 'screen_name'
  ) THEN
    ALTER TABLE public.datadog_performance_metrics
      ADD COLUMN screen_name VARCHAR(200);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'datadog_performance_metrics'
      AND indexname = 'idx_perf_metrics_screen'
  ) THEN
    EXECUTE 'CREATE INDEX idx_perf_metrics_screen
      ON public.datadog_performance_metrics (screen_name, recorded_at DESC)';
  END IF;
END;
$$;

-- Index for efficient querying by type and time with threshold filter
CREATE INDEX IF NOT EXISTS idx_perf_metrics_type_time
  ON public.datadog_performance_metrics (metric_type, recorded_at DESC)
  WHERE threshold_exceeded = true;

-- Create performance_optimization_recommendations table
-- screen_name is included directly in the table definition to ensure
-- it exists before idx_recommendations_screen_severity is created
CREATE TABLE IF NOT EXISTS public.performance_optimization_recommendations (
  recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  issue_type VARCHAR(50) NOT NULL,
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  recommendation_text TEXT NOT NULL,
  implementation_guide TEXT,
  estimated_impact VARCHAR(50),
  screen_name VARCHAR(200),
  applied BOOLEAN DEFAULT false,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  applied_at TIMESTAMPTZ
);

-- Add screen_name column if it doesn't exist (idempotency guard for pre-existing tables)
-- Also creates the index on screen_name inside this block to guarantee column exists first
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'performance_optimization_recommendations'
      AND column_name = 'screen_name'
  ) THEN
    ALTER TABLE public.performance_optimization_recommendations
      ADD COLUMN screen_name VARCHAR(200);
  END IF;

  -- Ensure severity column exists (guard for tables created before this column was added)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'performance_optimization_recommendations'
      AND column_name = 'severity'
  ) THEN
    ALTER TABLE public.performance_optimization_recommendations
      ADD COLUMN severity VARCHAR(20) NOT NULL DEFAULT 'medium'
        CHECK (severity IN ('critical', 'high', 'medium', 'low'));
  END IF;

  -- Create index only after ensuring screen_name and severity columns exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'performance_optimization_recommendations'
      AND indexname = 'idx_recommendations_screen_severity'
  ) THEN
    EXECUTE 'CREATE INDEX idx_recommendations_screen_severity
      ON public.performance_optimization_recommendations (screen_name, severity)';
  END IF;
END;
$$;

-- Create sla_compliance_log table
CREATE TABLE IF NOT EXISTS public.sla_compliance_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sla_name VARCHAR(100) NOT NULL,
  threshold_value DECIMAL(10, 4) NOT NULL,
  actual_value DECIMAL(10, 4) NOT NULL,
  compliant BOOLEAN NOT NULL,
  violation_duration_seconds INTEGER,
  checked_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sla_log_name_time
  ON public.sla_compliance_log (sla_name, checked_at DESC);

-- Enable RLS
ALTER TABLE public.datadog_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_optimization_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sla_compliance_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies: admin read/write, authenticated read
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'datadog_performance_metrics'
      AND policyname = 'admin_all_perf_metrics'
  ) THEN
    CREATE POLICY admin_all_perf_metrics ON public.datadog_performance_metrics
      FOR ALL TO authenticated
      USING (true)
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'performance_optimization_recommendations'
      AND policyname = 'admin_all_recommendations'
  ) THEN
    CREATE POLICY admin_all_recommendations ON public.performance_optimization_recommendations
      FOR ALL TO authenticated
      USING (true)
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'sla_compliance_log'
      AND policyname = 'admin_all_sla_log'
  ) THEN
    CREATE POLICY admin_all_sla_log ON public.sla_compliance_log
      FOR ALL TO authenticated
      USING (true)
      WITH CHECK (true);
  END IF;
END;
$$;
