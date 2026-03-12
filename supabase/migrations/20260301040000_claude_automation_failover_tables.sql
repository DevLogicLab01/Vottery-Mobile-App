-- Claude Decision Reasoning Hub & Admin Automation Control Panel Tables
-- Migration: 20260301040000_claude_automation_failover_tables.sql

-- Disputes table
CREATE TABLE IF NOT EXISTS public.disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(50) NOT NULL DEFAULT 'chargeback',
  claim TEXT,
  evidence TEXT,
  user_history TEXT,
  transaction_details TEXT,
  status VARCHAR(30) DEFAULT 'pending',
  user_id UUID,
  user_name VARCHAR(200),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_disputes_status ON public.disputes(status);
CREATE INDEX IF NOT EXISTS idx_disputes_type ON public.disputes(type);
CREATE INDEX IF NOT EXISTS idx_disputes_created_at ON public.disputes(created_at DESC);

-- Dispute resolution analysis table
CREATE TABLE IF NOT EXISTS public.dispute_resolution_analysis (
  analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_id UUID,
  reasoning_chain JSONB DEFAULT '[]'::jsonb,
  confidence_scores JSONB DEFAULT '{}'::jsonb,
  recommended_resolution VARCHAR(50),
  policy_citations JSONB DEFAULT '[]'::jsonb,
  appeal_risk VARCHAR(20) DEFAULT 'medium',
  analyzed_by VARCHAR(100) DEFAULT 'claude-sonnet-4-5-20250929',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dispute_analysis_dispute_id ON public.dispute_resolution_analysis(dispute_id);

-- Automation rules table
CREATE TABLE IF NOT EXISTS public.automation_rules (
  rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_type VARCHAR(50) NOT NULL,
  rule_name VARCHAR(200) NOT NULL,
  conditions JSONB DEFAULT '{}'::jsonb,
  actions JSONB DEFAULT '[]'::jsonb,
  schedule VARCHAR(100) DEFAULT 'manual',
  is_enabled BOOLEAN DEFAULT false,
  last_executed_at TIMESTAMPTZ,
  override_until TIMESTAMPTZ,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_automation_rules_type ON public.automation_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_automation_rules_enabled ON public.automation_rules(is_enabled);

-- Automation execution log table
CREATE TABLE IF NOT EXISTS public.automation_execution_log (
  execution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_id UUID,
  rule_name VARCHAR(200),
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(30) DEFAULT 'success',
  conditions_met BOOLEAN DEFAULT true,
  actions_taken JSONB DEFAULT '[]'::jsonb,
  affected_count INTEGER DEFAULT 0,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_execution_log_rule_id ON public.automation_execution_log(rule_id);
CREATE INDEX IF NOT EXISTS idx_execution_log_executed_at ON public.automation_execution_log(executed_at DESC);

-- Performance baselines table (for regression detection)
CREATE TABLE IF NOT EXISTS public.performance_baselines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name VARCHAR(200) NOT NULL,
  baseline_load_time NUMERIC(10,2),
  baseline_memory NUMERIC(10,2),
  baseline_fps NUMERIC(5,2),
  baseline_date DATE DEFAULT CURRENT_DATE,
  sample_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
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

CREATE UNIQUE INDEX IF NOT EXISTS idx_performance_baselines_screen_date 
  ON public.performance_baselines(screen_name, baseline_date);

-- Performance regression alerts table
CREATE TABLE IF NOT EXISTS public.performance_regression_alerts (
  alert_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name VARCHAR(200),
  metric_name VARCHAR(100),
  baseline_value NUMERIC(10,2),
  current_value NUMERIC(10,2),
  deviation_percentage NUMERIC(5,2),
  severity VARCHAR(20) DEFAULT 'medium',
  status VARCHAR(30) DEFAULT 'open',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_regression_alerts_severity ON public.performance_regression_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_regression_alerts_created_at ON public.performance_regression_alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_regression_alerts_status ON public.performance_regression_alerts(status);

-- Subscription pricing A/B tests table
CREATE TABLE IF NOT EXISTS public.subscription_pricing_ab_tests (
  test_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_zones JSONB DEFAULT '[]'::jsonb,
  variants JSONB DEFAULT '{}'::jsonb,
  traffic_split NUMERIC(5,2) DEFAULT 50.0,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  status VARCHAR(30) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Campaign profitability log table
CREATE TABLE IF NOT EXISTS public.campaign_profitability_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID,
  campaign_name VARCHAR(200),
  revenue NUMERIC(12,2) DEFAULT 0,
  cost NUMERIC(12,2) DEFAULT 0,
  profit_margin NUMERIC(5,2) DEFAULT 0,
  status VARCHAR(30) DEFAULT 'active',
  paused_reason TEXT,
  checked_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campaign_profitability_campaign_id ON public.campaign_profitability_log(campaign_id);

-- RLS Policies
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispute_resolution_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.automation_execution_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_baselines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_regression_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_pricing_ab_tests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_profitability_log ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'disputes' AND policyname = 'disputes_read_policy') THEN
    CREATE POLICY disputes_read_policy ON public.disputes FOR SELECT TO authenticated USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'dispute_resolution_analysis' AND policyname = 'analysis_read_policy') THEN
    CREATE POLICY analysis_read_policy ON public.dispute_resolution_analysis FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'automation_rules' AND policyname = 'automation_rules_policy') THEN
    CREATE POLICY automation_rules_policy ON public.automation_rules FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'automation_execution_log' AND policyname = 'execution_log_policy') THEN
    CREATE POLICY execution_log_policy ON public.automation_execution_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'performance_baselines' AND policyname = 'baselines_policy') THEN
    CREATE POLICY baselines_policy ON public.performance_baselines FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'performance_regression_alerts' AND policyname = 'regression_alerts_policy') THEN
    CREATE POLICY regression_alerts_policy ON public.performance_regression_alerts FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'subscription_pricing_ab_tests' AND policyname = 'ab_tests_policy') THEN
    CREATE POLICY ab_tests_policy ON public.subscription_pricing_ab_tests FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'campaign_profitability_log' AND policyname = 'campaign_profitability_policy') THEN
    CREATE POLICY campaign_profitability_policy ON public.campaign_profitability_log FOR ALL TO authenticated USING (true) WITH CHECK (true);
  END IF;
END $$;

-- Insert sample disputes for testing
INSERT INTO public.disputes (id, type, claim, evidence, user_history, transaction_details, status, user_name)
SELECT 
  gen_random_uuid(),
  'chargeback',
  'Unauthorized charge of $49.99 on my account',
  'Bank statement showing no transaction, IP logs from different country',
  'Account in good standing for 2 years, no previous disputes',
  'Transaction ID: TXN_20260301_001, Amount: $49.99, Date: 2026-03-01',
  'pending',
  'Alice Johnson'
WHERE NOT EXISTS (SELECT 1 FROM public.disputes WHERE user_name = 'Alice Johnson' LIMIT 1);

INSERT INTO public.disputes (id, type, claim, evidence, user_history, transaction_details, status, user_name)
SELECT 
  gen_random_uuid(),
  'refund_request',
  'Service not delivered as promised within 24 hours',
  'Order confirmation email, support chat transcript',
  'First-time user, registered 30 days ago',
  'Transaction ID: TXN_20260228_042, Amount: $19.99, Date: 2026-02-28',
  'pending',
  'Bob Smith'
WHERE NOT EXISTS (SELECT 1 FROM public.disputes WHERE user_name = 'Bob Smith' LIMIT 1);
