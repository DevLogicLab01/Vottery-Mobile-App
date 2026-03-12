-- Claude Decision Reasoning Hub & Admin Automation Control Panel Tables
-- Migration: 20260301040000_claude_decision_automation_tables.sql

-- Disputes table
CREATE TABLE IF NOT EXISTS public.disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  user_name VARCHAR(200),
  dispute_type VARCHAR(50) DEFAULT 'chargeback',
  evidence_summary TEXT,
  evidence_files JSONB DEFAULT '[]',
  user_history JSONB DEFAULT '{}',
  transaction_details JSONB DEFAULT '{}',
  claim TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_disputes_status ON public.disputes(status);
CREATE INDEX IF NOT EXISTS idx_disputes_created_at ON public.disputes(created_at DESC);

-- Dispute resolution analysis table
CREATE TABLE IF NOT EXISTS public.dispute_resolution_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_id UUID,
  reasoning_chain JSONB DEFAULT '[]',
  confidence_scores JSONB DEFAULT '{}',
  recommended_resolution VARCHAR(50),
  policy_citations JSONB DEFAULT '[]',
  appeal_risk VARCHAR(20) DEFAULT 'medium',
  appeal_overturned BOOLEAN DEFAULT FALSE,
  analyzed_by VARCHAR(100) DEFAULT 'claude-sonnet-4',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dispute_analysis_dispute_id ON public.dispute_resolution_analysis(dispute_id);

-- Dispute appeals table
CREATE TABLE IF NOT EXISTS public.dispute_appeals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_id UUID,
  original_decision VARCHAR(50),
  user_appeal_reason TEXT,
  appeal_evidence TEXT,
  original_dispute_analysis JSONB DEFAULT '{}',
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dispute_appeals_status ON public.dispute_appeals(status);

-- Automation rules table
CREATE TABLE IF NOT EXISTS public.automation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id VARCHAR(100) UNIQUE,
  rule_type VARCHAR(50) NOT NULL,
  rule_name VARCHAR(200) NOT NULL,
  conditions JSONB DEFAULT '{}',
  actions JSONB DEFAULT '[]',
  schedule VARCHAR(100),
  is_enabled BOOLEAN DEFAULT FALSE,
  last_executed_at TIMESTAMPTZ,
  override_until TIMESTAMPTZ,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_automation_rules_type_enabled ON public.automation_rules(rule_type, is_enabled);

-- Automation execution log table
CREATE TABLE IF NOT EXISTS public.automation_execution_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_id VARCHAR(100),
  rule_id VARCHAR(100),
  rule_name VARCHAR(200),
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(50) DEFAULT 'success',
  conditions_met BOOLEAN DEFAULT TRUE,
  actions_taken JSONB DEFAULT '[]',
  affected_count INTEGER DEFAULT 0,
  triggered_by VARCHAR(50) DEFAULT 'scheduled',
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_automation_exec_log_executed_at ON public.automation_execution_log(executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_automation_exec_log_rule_id ON public.automation_execution_log(rule_id);

-- Subscription pricing A/B tests table (for Revenue Optimization Engine)
CREATE TABLE IF NOT EXISTS public.subscription_pricing_ab_tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_id VARCHAR(100) UNIQUE,
  target_zones JSONB DEFAULT '[]',
  variants JSONB DEFAULT '{}',
  traffic_split FLOAT DEFAULT 0.5,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  status VARCHAR(50) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- A/B test assignments
CREATE TABLE IF NOT EXISTS public.ab_test_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  test_id VARCHAR(100),
  variant_assigned VARCHAR(50),
  assigned_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add test_id column if table already exists without it
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'ab_test_assignments'
      AND column_name = 'test_id'
  ) THEN
    ALTER TABLE public.ab_test_assignments ADD COLUMN test_id VARCHAR(100);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_ab_test_assignments_user ON public.ab_test_assignments(user_id, test_id);

-- Campaign profitability log
CREATE TABLE IF NOT EXISTS public.campaign_profitability_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID,
  campaign_name VARCHAR(200),
  current_margin FLOAT,
  threshold FLOAT DEFAULT 0.10,
  action_taken VARCHAR(50),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance baselines table (for Performance Regression Detection)
CREATE TABLE IF NOT EXISTS public.performance_baselines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name VARCHAR(200) NOT NULL,
  baseline_load_time FLOAT,
  baseline_memory FLOAT,
  baseline_fps FLOAT,
  baseline_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add screen_name column if table already existed without it
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'performance_baselines'
      AND column_name = 'screen_name'
  ) THEN
    ALTER TABLE public.performance_baselines ADD COLUMN screen_name VARCHAR(200);
  END IF;
END $$;

-- Add baseline_date column if table already existed without it
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'performance_baselines'
      AND column_name = 'baseline_date'
  ) THEN
    ALTER TABLE public.performance_baselines ADD COLUMN baseline_date DATE DEFAULT CURRENT_DATE;
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_performance_baselines_screen_date ON public.performance_baselines(screen_name, baseline_date);

-- Multi-region health checks table (for Multi-Region Failover)
CREATE TABLE IF NOT EXISTS public.region_health_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  region VARCHAR(50) NOT NULL,
  health_score FLOAT DEFAULT 100,
  cpu_usage FLOAT,
  memory_usage FLOAT,
  api_latency FLOAT,
  active_connections INTEGER DEFAULT 0,
  checked_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_region_health_checks_region ON public.region_health_checks(region, checked_at DESC);

-- Failover history table
CREATE TABLE IF NOT EXISTS public.failover_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_region VARCHAR(50),
  to_region VARCHAR(50),
  reason VARCHAR(200),
  trigger_type VARCHAR(50) DEFAULT 'automatic',
  health_score_at_failover FLOAT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispute_resolution_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispute_appeals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_execution_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_pricing_ab_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ab_test_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_profitability_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_baselines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.region_health_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.failover_history ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read/write
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'disputes' AND policyname = 'disputes_auth_policy') THEN
    CREATE POLICY disputes_auth_policy ON public.disputes FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'dispute_resolution_analysis' AND policyname = 'dispute_analysis_auth_policy') THEN
    CREATE POLICY dispute_analysis_auth_policy ON public.dispute_resolution_analysis FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'dispute_appeals' AND policyname = 'dispute_appeals_auth_policy') THEN
    CREATE POLICY dispute_appeals_auth_policy ON public.dispute_appeals FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'automation_rules' AND policyname = 'automation_rules_auth_policy') THEN
    CREATE POLICY automation_rules_auth_policy ON public.automation_rules FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'automation_execution_log' AND policyname = 'automation_exec_log_auth_policy') THEN
    CREATE POLICY automation_exec_log_auth_policy ON public.automation_execution_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscription_pricing_ab_tests' AND policyname = 'ab_tests_auth_policy') THEN
    CREATE POLICY ab_tests_auth_policy ON public.subscription_pricing_ab_tests FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'ab_test_assignments' AND policyname = 'ab_assignments_auth_policy') THEN
    CREATE POLICY ab_assignments_auth_policy ON public.ab_test_assignments FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'campaign_profitability_log' AND policyname = 'campaign_profit_auth_policy') THEN
    CREATE POLICY campaign_profit_auth_policy ON public.campaign_profitability_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'performance_baselines' AND policyname = 'perf_baselines_auth_policy') THEN
    CREATE POLICY perf_baselines_auth_policy ON public.performance_baselines FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'region_health_checks' AND policyname = 'region_health_auth_policy') THEN
    CREATE POLICY region_health_auth_policy ON public.region_health_checks FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'failover_history' AND policyname = 'failover_history_auth_policy') THEN
    CREATE POLICY failover_history_auth_policy ON public.failover_history FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;
