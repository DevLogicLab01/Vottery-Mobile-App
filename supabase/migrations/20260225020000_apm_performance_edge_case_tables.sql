-- APM Performance & Edge Case Tables Migration
-- Creates tables for extended outage logging, device profiles, offline cache, and sync queue

-- Extended Outage Log Table
CREATE TABLE IF NOT EXISTS public.extended_outage_log (
  outage_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider VARCHAR(20) NOT NULL,
  outage_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  outage_duration_hours INTEGER NOT NULL DEFAULT 0,
  decision VARCHAR(50),
  admin_approval_id UUID,
  approval_timestamp TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outage_log ON public.extended_outage_log (provider, outage_start);

ALTER TABLE public.extended_outage_log ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'extended_outage_log' AND policyname = 'Admin access extended_outage_log'
  ) THEN
    CREATE POLICY "Admin access extended_outage_log" ON public.extended_outage_log
      FOR ALL USING (true);
  END IF;
END $$;

-- Device Capability Profiles Table
CREATE TABLE IF NOT EXISTS public.device_capability_profiles (
  profile_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id VARCHAR(100) UNIQUE NOT NULL,
  device_model VARCHAR(100),
  total_memory_mb INTEGER,
  supports_advanced_carousels BOOLEAN DEFAULT true,
  preferred_quality_level VARCHAR(20) DEFAULT 'high' CHECK (preferred_quality_level IN ('low', 'medium', 'high')),
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_device_profiles ON public.device_capability_profiles (device_id);

ALTER TABLE public.device_capability_profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'device_capability_profiles' AND policyname = 'Users manage device profiles'
  ) THEN
    CREATE POLICY "Users manage device profiles" ON public.device_capability_profiles
      FOR ALL USING (true);
  END IF;
END $$;

-- Content Offline Cache Table
CREATE TABLE IF NOT EXISTS public.content_offline_cache (
  cache_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content_type VARCHAR(50) NOT NULL,
  content_id UUID NOT NULL,
  content_data JSONB NOT NULL DEFAULT '{}',
  cached_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ,
  is_stale BOOLEAN DEFAULT false,
  expires_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_offline_cache ON public.content_offline_cache (user_id, content_type, cached_at);

ALTER TABLE public.content_offline_cache ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'content_offline_cache' AND policyname = 'Users access own cache'
  ) THEN
    CREATE POLICY "Users access own cache" ON public.content_offline_cache
      FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

-- Offline Sync Queue Table
CREATE TABLE IF NOT EXISTS public.offline_sync_queue (
  queue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  operation_type VARCHAR(50) NOT NULL,
  operation_payload JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  retry_count INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  last_attempted_at TIMESTAMPTZ,
  error_message TEXT
);

CREATE INDEX IF NOT EXISTS idx_sync_queue ON public.offline_sync_queue (user_id, status, created_at)
  WHERE status IN ('pending', 'processing');

ALTER TABLE public.offline_sync_queue ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'offline_sync_queue' AND policyname = 'Users access own sync queue'
  ) THEN
    CREATE POLICY "Users access own sync queue" ON public.offline_sync_queue
      FOR ALL USING (auth.uid() = user_id);
  END IF;
END $$;

-- Datadog Trace Metadata Table (for heatmap)
CREATE TABLE IF NOT EXISTS public.datadog_trace_metadata (
  trace_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_name VARCHAR(200) NOT NULL,
  system_name VARCHAR(100) NOT NULL,
  operation_type VARCHAR(50) DEFAULT 'api_call',
  latency_ms INTEGER NOT NULL DEFAULT 0,
  latency_p50 INTEGER,
  latency_p95 INTEGER,
  latency_p99 INTEGER,
  error_count INTEGER DEFAULT 0,
  call_count INTEGER DEFAULT 1,
  affected_users_estimate INTEGER DEFAULT 0,
  query_text TEXT,
  execution_plan TEXT,
  affected_tables TEXT[],
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trace_metadata ON public.datadog_trace_metadata (system_name, operation_name, recorded_at);
CREATE INDEX IF NOT EXISTS idx_trace_latency ON public.datadog_trace_metadata (latency_ms DESC);

ALTER TABLE public.datadog_trace_metadata ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'datadog_trace_metadata' AND policyname = 'Admin read trace metadata'
  ) THEN
    CREATE POLICY "Admin read trace metadata" ON public.datadog_trace_metadata
      FOR ALL USING (true);
  END IF;
END $$;

-- Insert sample trace data for heatmap visualization
INSERT INTO public.datadog_trace_metadata (operation_name, system_name, operation_type, latency_ms, latency_p50, latency_p95, latency_p99, call_count, affected_users_estimate)
SELECT
  ops.op,
  sys.sys,
  CASE WHEN ops.op LIKE '%query%' OR ops.op LIKE '%fetch%' THEN 'database_query' ELSE 'api_call' END,
  (random() * 1500 + 50)::INTEGER,
  (random() * 300 + 50)::INTEGER,
  (random() * 800 + 200)::INTEGER,
  (random() * 1200 + 400)::INTEGER,
  (random() * 1000 + 100)::INTEGER,
  (random() * 500 + 10)::INTEGER
FROM
  (VALUES
    ('carousel_render'), ('user_query'), ('election_fetch'), ('vote_submit'),
    ('payment_process'), ('ai_inference'), ('media_upload'), ('notification_send')
  ) AS ops(op),
  (VALUES
    ('HorizontalCarousel'), ('VerticalStack'), ('GradientFlow'),
    ('ElectionService'), ('PaymentService'), ('AIService'), ('MediaService'), ('NotificationService')
  ) AS sys(sys)
ON CONFLICT DO NOTHING;
