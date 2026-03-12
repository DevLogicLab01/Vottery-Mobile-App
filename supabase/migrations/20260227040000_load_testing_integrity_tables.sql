-- Load Test Execution History
CREATE TABLE IF NOT EXISTS public.load_test_execution_history (
  test_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_tier BIGINT NOT NULL,
  test_duration_seconds INTEGER,
  websocket_success_rate DECIMAL(5,2),
  avg_websocket_latency_ms INTEGER,
  blockchain_tps INTEGER,
  blockchain_success_rate DECIMAL(5,2),
  regressions_detected JSONB DEFAULT '[]'::jsonb,
  test_status VARCHAR(20) CHECK (test_status IN ('running', 'completed', 'failed')) DEFAULT 'completed',
  executed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_load_test_history ON public.load_test_execution_history (executed_at DESC, user_tier);

-- Load Test WebSocket Metrics
CREATE TABLE IF NOT EXISTS public.load_test_websocket_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id UUID REFERENCES public.load_test_execution_history(test_id) ON DELETE CASCADE,
  concurrent_connections INTEGER,
  successful_connections INTEGER,
  failed_connections INTEGER,
  avg_latency_ms INTEGER,
  max_latency_ms INTEGER,
  messages_per_second INTEGER,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ws_metrics_test ON public.load_test_websocket_metrics (test_id, recorded_at DESC);

-- Load Test Blockchain Metrics
CREATE TABLE IF NOT EXISTS public.load_test_blockchain_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id UUID REFERENCES public.load_test_execution_history(test_id) ON DELETE CASCADE,
  transactions_submitted INTEGER,
  transactions_confirmed INTEGER,
  transactions_failed INTEGER,
  avg_tps INTEGER,
  avg_block_propagation_ms INTEGER,
  avg_gas_cost DECIMAL(18,8),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_blockchain_metrics_test ON public.load_test_blockchain_metrics (test_id, recorded_at DESC);

-- Election Voting Anomalies
CREATE TABLE IF NOT EXISTS public.election_voting_anomalies (
  anomaly_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID,
  anomaly_type VARCHAR(50) CHECK (anomaly_type IN ('vote_spike', 'geographic_concentration', 'demographic_anomaly', 'timing_burst', 'blockchain_mismatch')),
  severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  details JSONB DEFAULT '{}'::jsonb,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  resolved BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_voting_anomalies ON public.election_voting_anomalies (detected_at DESC, severity) WHERE resolved = false;

-- Election Integrity Metrics
CREATE TABLE IF NOT EXISTS public.election_integrity_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID,
  total_votes INTEGER DEFAULT 0,
  verified_votes INTEGER DEFAULT 0,
  blockchain_sync_lag_ms INTEGER DEFAULT 0,
  anomaly_count INTEGER DEFAULT 0,
  integrity_score DECIMAL(5,2) DEFAULT 100.0,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_integrity_metrics ON public.election_integrity_metrics (election_id, recorded_at DESC);

-- RLS Policies
ALTER TABLE public.load_test_execution_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.load_test_websocket_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.load_test_blockchain_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_voting_anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_integrity_metrics ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'load_test_execution_history' AND policyname = 'load_test_history_all'
  ) THEN
    CREATE POLICY load_test_history_all ON public.load_test_execution_history
      FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'load_test_websocket_metrics' AND policyname = 'ws_metrics_all'
  ) THEN
    CREATE POLICY ws_metrics_all ON public.load_test_websocket_metrics
      FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'load_test_blockchain_metrics' AND policyname = 'blockchain_metrics_all'
  ) THEN
    CREATE POLICY blockchain_metrics_all ON public.load_test_blockchain_metrics
      FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'election_voting_anomalies' AND policyname = 'anomalies_all'
  ) THEN
    CREATE POLICY anomalies_all ON public.election_voting_anomalies
      FOR ALL USING (true) WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'election_integrity_metrics' AND policyname = 'integrity_metrics_all'
  ) THEN
    CREATE POLICY integrity_metrics_all ON public.election_integrity_metrics
      FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;
