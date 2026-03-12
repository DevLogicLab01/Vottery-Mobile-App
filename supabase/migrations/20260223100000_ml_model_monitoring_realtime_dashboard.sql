-- ML Model Monitoring Tables
CREATE TABLE IF NOT EXISTS model_predictions (
  prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name VARCHAR(50) NOT NULL,
  operation_type VARCHAR(50) NOT NULL,
  input_text TEXT,
  predicted_output TEXT NOT NULL,
  actual_output TEXT,
  prediction_confidence DECIMAL(3,2),
  accuracy_score DECIMAL(3,2),
  prediction_timestamp TIMESTAMPTZ DEFAULT NOW(),
  verified_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS model_latency_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name VARCHAR(50) NOT NULL,
  operation_type VARCHAR(50) NOT NULL,
  latency_ms INTEGER NOT NULL,
  input_tokens INTEGER,
  output_tokens INTEGER,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS model_cost_tracking (
  cost_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name VARCHAR(50) NOT NULL,
  operation_type VARCHAR(50) NOT NULL,
  input_tokens INTEGER,
  output_tokens INTEGER,
  cost_usd DECIMAL(10,4) NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS model_health_status (
  status_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  model_name VARCHAR(50) NOT NULL UNIQUE,
  status VARCHAR(20) NOT NULL DEFAULT 'healthy',
  error_rate DECIMAL(5,2) DEFAULT 0.0,
  avg_latency_ms INTEGER DEFAULT 0,
  last_check TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_model_predictions_model_timestamp 
  ON model_predictions(model_name, prediction_timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_model_latency_model_timestamp 
  ON model_latency_metrics(model_name, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_model_cost_model_timestamp 
  ON model_cost_tracking(model_name, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_model_cost_user 
  ON model_cost_tracking(user_id, timestamp DESC);

-- RLS Policies
ALTER TABLE model_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_latency_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_cost_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE model_health_status ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read model monitoring data
CREATE POLICY model_predictions_read_policy ON model_predictions
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY model_predictions_insert_policy ON model_predictions
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY model_latency_read_policy ON model_latency_metrics
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY model_latency_insert_policy ON model_latency_metrics
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY model_cost_read_policy ON model_cost_tracking
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY model_cost_insert_policy ON model_cost_tracking
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY model_health_read_policy ON model_health_status
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY model_health_write_policy ON model_health_status
  FOR ALL USING (auth.uid() IS NOT NULL);

-- Real-time Dashboard Refresh Tables
-- Note: Using existing tables with realtime_metadata enhancement
DO $$
BEGIN
  -- Add realtime_metadata to existing tables if not exists
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'metrics_updates' AND column_name = 'realtime_metadata') THEN
    ALTER TABLE metrics_updates ADD COLUMN realtime_metadata JSONB DEFAULT '{}'::jsonb;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'incident_updates' AND column_name = 'realtime_metadata') THEN
    ALTER TABLE incident_updates ADD COLUMN realtime_metadata JSONB DEFAULT '{}'::jsonb;
  END IF;
EXCEPTION
  WHEN undefined_table THEN
    -- Tables don't exist, create them
    CREATE TABLE IF NOT EXISTS metrics_updates (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      metric_type VARCHAR(50),
      metric_value JSONB,
      realtime_metadata JSONB DEFAULT '{}'::jsonb,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );
    
    CREATE TABLE IF NOT EXISTS incident_updates (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      incident_type VARCHAR(50),
      severity VARCHAR(20),
      details JSONB,
      realtime_metadata JSONB DEFAULT '{}'::jsonb,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );
END$$;

-- Enable Supabase Realtime on dashboard tables
ALTER TABLE model_predictions REPLICA IDENTITY FULL;
ALTER TABLE model_latency_metrics REPLICA IDENTITY FULL;
ALTER TABLE model_cost_tracking REPLICA IDENTITY FULL;
ALTER TABLE model_health_status REPLICA IDENTITY FULL;

-- Create realtime publication for dashboard updates
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'dashboard_updates') THEN
    CREATE PUBLICATION dashboard_updates FOR TABLE 
      model_predictions,
      model_latency_metrics,
      model_cost_tracking,
      model_health_status;
  END IF;
END$$;
