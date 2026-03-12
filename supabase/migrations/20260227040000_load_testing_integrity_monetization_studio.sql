-- Migration: Load Testing, Election Integrity, Creator Monetization Studio tables
-- Timestamp: 20260227040000

-- ============================================================
-- FEATURE 1: Production Load Testing Suite
-- ============================================================

CREATE TABLE IF NOT EXISTS public.load_test_execution_history (
  test_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_tier BIGINT NOT NULL DEFAULT 10000,
  test_duration_seconds INTEGER DEFAULT 0,
  websocket_success_rate DECIMAL(5,2) DEFAULT 0,
  avg_websocket_latency_ms INTEGER DEFAULT 0,
  blockchain_tps INTEGER DEFAULT 0,
  blockchain_success_rate DECIMAL(5,2) DEFAULT 0,
  regressions_detected JSONB DEFAULT '[]'::jsonb,
  test_status VARCHAR(20) DEFAULT 'completed' CHECK (test_status IN ('running', 'completed', 'failed')),
  executed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_load_test_history_executed
  ON public.load_test_execution_history (executed_at DESC, user_tier);

CREATE TABLE IF NOT EXISTS public.load_test_websocket_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id UUID REFERENCES public.load_test_execution_history(test_id) ON DELETE CASCADE,
  concurrent_connections INTEGER DEFAULT 0,
  successful_connections INTEGER DEFAULT 0,
  failed_connections INTEGER DEFAULT 0,
  avg_latency_ms INTEGER DEFAULT 0,
  max_latency_ms INTEGER DEFAULT 0,
  messages_per_second INTEGER DEFAULT 0,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.load_test_blockchain_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id UUID REFERENCES public.load_test_execution_history(test_id) ON DELETE CASCADE,
  transactions_submitted INTEGER DEFAULT 0,
  transactions_confirmed INTEGER DEFAULT 0,
  transactions_failed INTEGER DEFAULT 0,
  avg_tps INTEGER DEFAULT 0,
  avg_block_propagation_ms INTEGER DEFAULT 0,
  avg_gas_cost DECIMAL(18,8) DEFAULT 0,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for load testing tables
ALTER TABLE public.load_test_execution_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.load_test_websocket_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.load_test_blockchain_metrics ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'load_test_execution_history'
    AND policyname = 'load_test_history_select'
  ) THEN
    CREATE POLICY load_test_history_select ON public.load_test_execution_history
      FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'load_test_execution_history'
    AND policyname = 'load_test_history_insert'
  ) THEN
    CREATE POLICY load_test_history_insert ON public.load_test_execution_history
      FOR INSERT WITH CHECK (true);
  END IF;
END $$;

-- ============================================================
-- FEATURE 2: Election Integrity Monitoring Hub
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_voting_anomalies (
  anomaly_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID,
  anomaly_type VARCHAR(50) CHECK (anomaly_type IN (
    'vote_spike', 'geographic_concentration', 'demographic_anomaly',
    'timing_burst', 'blockchain_mismatch'
  )),
  severity VARCHAR(20) CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  details JSONB DEFAULT '{}'::jsonb,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  resolved BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_voting_anomalies_detected
  ON public.election_voting_anomalies (detected_at DESC, severity)
  WHERE resolved = false;

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

CREATE INDEX IF NOT EXISTS idx_integrity_metrics_election
  ON public.election_integrity_metrics (election_id, recorded_at DESC);

-- RLS for election integrity tables
ALTER TABLE public.election_voting_anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_integrity_metrics ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'election_voting_anomalies'
    AND policyname = 'anomalies_select'
  ) THEN
    CREATE POLICY anomalies_select ON public.election_voting_anomalies
      FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'election_voting_anomalies'
    AND policyname = 'anomalies_insert'
  ) THEN
    CREATE POLICY anomalies_insert ON public.election_voting_anomalies
      FOR INSERT WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'election_integrity_metrics'
    AND policyname = 'integrity_metrics_select'
  ) THEN
    CREATE POLICY integrity_metrics_select ON public.election_integrity_metrics
      FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'election_integrity_metrics'
    AND policyname = 'integrity_metrics_insert'
  ) THEN
    CREATE POLICY integrity_metrics_insert ON public.election_integrity_metrics
      FOR INSERT WITH CHECK (true);
  END IF;
END $$;

-- ============================================================
-- FEATURE 3: Creator Monetization Studio
-- ============================================================

CREATE TABLE IF NOT EXISTS public.creator_onboarding_progress (
  progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID UNIQUE,
  current_step INTEGER DEFAULT 1 CHECK (current_step BETWEEN 1 AND 7),
  profile_completed BOOLEAN DEFAULT false,
  payout_configured BOOLEAN DEFAULT false,
  tier_selected BOOLEAN DEFAULT false,
  onboarding_status VARCHAR(20) DEFAULT 'in_progress'
    CHECK (onboarding_status IN ('in_progress', 'completed', 'skipped')),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_onboarding_progress_user
  ON public.creator_onboarding_progress (creator_user_id, onboarding_status);

CREATE TABLE IF NOT EXISTS public.creator_sponsorship_opportunities (
  opportunity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_name VARCHAR(100) NOT NULL,
  campaign_title VARCHAR(200) NOT NULL,
  campaign_description TEXT,
  payout_amount DECIMAL(10,2) DEFAULT 0,
  eligibility_tier VARCHAR(20) DEFAULT 'bronze'
    CHECK (eligibility_tier IN ('bronze', 'silver', 'gold', 'platinum')),
  minimum_followers INTEGER DEFAULT 0,
  application_deadline DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sponsorship_opportunities_active
  ON public.creator_sponsorship_opportunities (is_active, eligibility_tier);

-- RLS for creator monetization tables
ALTER TABLE public.creator_onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_sponsorship_opportunities ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'creator_onboarding_progress'
    AND policyname = 'onboarding_select'
  ) THEN
    CREATE POLICY onboarding_select ON public.creator_onboarding_progress
      FOR SELECT USING (auth.uid() = creator_user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'creator_onboarding_progress'
    AND policyname = 'onboarding_upsert'
  ) THEN
    CREATE POLICY onboarding_upsert ON public.creator_onboarding_progress
      FOR ALL USING (auth.uid() = creator_user_id)
      WITH CHECK (auth.uid() = creator_user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'creator_sponsorship_opportunities'
    AND policyname = 'sponsorships_select'
  ) THEN
    CREATE POLICY sponsorships_select ON public.creator_sponsorship_opportunities
      FOR SELECT USING (is_active = true);
  END IF;
END $$;

-- Seed sample sponsorship opportunities
INSERT INTO public.creator_sponsorship_opportunities
  (brand_name, campaign_title, campaign_description, payout_amount, eligibility_tier, minimum_followers, application_deadline, is_active)
SELECT
  'VoteNation Media', 'Election Coverage Campaign',
  'Partner with us to cover major elections and earn per campaign.',
  150.00, 'bronze', 0, NOW() + INTERVAL '30 days', true
WHERE NOT EXISTS (
  SELECT 1 FROM public.creator_sponsorship_opportunities
  WHERE brand_name = 'VoteNation Media'
);

INSERT INTO public.creator_sponsorship_opportunities
  (brand_name, campaign_title, campaign_description, payout_amount, eligibility_tier, minimum_followers, application_deadline, is_active)
SELECT
  'PoliticsNow', 'Premium Election Series',
  'Exclusive premium sponsorship for Gold+ creators covering political elections.',
  800.00, 'gold', 1000, NOW() + INTERVAL '60 days', true
WHERE NOT EXISTS (
  SELECT 1 FROM public.creator_sponsorship_opportunities
  WHERE brand_name = 'PoliticsNow'
);
