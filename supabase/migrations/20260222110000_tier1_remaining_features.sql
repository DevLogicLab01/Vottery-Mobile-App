-- Predictive Incident Prevention Engine Tables

-- Incident predictions table
CREATE TABLE IF NOT EXISTS public.incident_predictions (
  prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  predicted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  prediction_horizon_hours INT NOT NULL CHECK (prediction_horizon_hours IN (24, 48)),
  predictions JSONB NOT NULL,
  model_version TEXT NOT NULL,
  confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_incident_predictions_predicted_at ON public.incident_predictions(predicted_at DESC);
CREATE INDEX IF NOT EXISTS idx_incident_predictions_horizon ON public.incident_predictions(prediction_horizon_hours);

-- Preventive actions log
CREATE TABLE IF NOT EXISTS public.preventive_actions_log (
  action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID REFERENCES public.incident_predictions(prediction_id),
  action_type TEXT NOT NULL CHECK (action_type IN ('scale_resources', 'enable_rate_limiting', 'alert_teams', 'schedule_maintenance', 'backup_data', 'restart_services', 'increase_monitoring')),
  description TEXT NOT NULL,
  executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'executing', 'completed', 'failed')),
  outcome TEXT,
  prevented_incident BOOLEAN DEFAULT FALSE,
  effectiveness_score INT CHECK (effectiveness_score >= 0 AND effectiveness_score <= 100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_preventive_actions_executed_at ON public.preventive_actions_log(executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_preventive_actions_status ON public.preventive_actions_log(status);

-- Prediction accuracy metrics
CREATE TABLE IF NOT EXISTS public.prediction_accuracy_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  prediction_horizon INT NOT NULL,
  accuracy_percentage DECIMAL(5,2),
  precision_score DECIMAL(3,2),
  recall_score DECIMAL(3,2),
  f1_score DECIMAL(3,2),
  true_positives INT DEFAULT 0,
  false_positives INT DEFAULT 0,
  false_negatives INT DEFAULT 0,
  true_negatives INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(date, prediction_horizon)
);

CREATE INDEX IF NOT EXISTS idx_prediction_accuracy_date ON public.prediction_accuracy_metrics(date DESC);

-- Revenue Fraud Detection Engine Tables

-- Alter existing fraud_alerts table to add missing columns for Revenue Fraud Detection
DO $$
BEGIN
  -- Add detected_at column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'detected_at') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;

  -- Add affected_creator_id column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'affected_creator_id') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN affected_creator_id UUID;
  END IF;

  -- Add affected_campaign_id column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'affected_campaign_id') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN affected_campaign_id UUID;
  END IF;

  -- Add transaction_id column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'transaction_id') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN transaction_id UUID;
  END IF;

  -- Add transaction_amount column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'transaction_amount') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN transaction_amount DECIMAL(10,2);
  END IF;

  -- Add fraud_indicators column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'fraud_indicators') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN fraud_indicators JSONB;
  END IF;

  -- Add risk_score column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'risk_score') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN risk_score INT CHECK (risk_score >= 0 AND risk_score <= 100);
  END IF;

  -- Add risk_level column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'risk_level') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high', 'critical'));
  END IF;

  -- Add confidence_level column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'confidence_level') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN confidence_level TEXT CHECK (confidence_level IN ('low', 'medium', 'high'));
  END IF;

  -- Add assigned_investigator_id column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'assigned_investigator_id') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN assigned_investigator_id UUID;
  END IF;

  -- Add resolution_explanation column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'resolution_explanation') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN resolution_explanation TEXT;
  END IF;

  -- Add updated_at column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'fraud_alerts' AND column_name = 'updated_at') THEN
    ALTER TABLE public.fraud_alerts ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
  END IF;
END $$;

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_detected_at ON public.fraud_alerts(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_risk_level ON public.fraud_alerts(risk_level);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_creator ON public.fraud_alerts(affected_creator_id);

-- Creator accounts table (for fraud prevention actions)
CREATE TABLE IF NOT EXISTS public.creator_accounts (
  creator_id UUID PRIMARY KEY,
  payouts_enabled BOOLEAN DEFAULT TRUE,
  enhanced_monitoring BOOLEAN DEFAULT FALSE,
  daily_payout_limit DECIMAL(10,2),
  fraud_investigation_required BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_creator_accounts_fraud_flag ON public.creator_accounts(fraud_investigation_required) WHERE fraud_investigation_required = TRUE;

-- Creator overrides table (for fraud detection)
CREATE TABLE IF NOT EXISTS public.creator_overrides (
  override_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL,
  override_amount DECIMAL(10,2),
  justification TEXT,
  approver_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_creator_overrides_creator ON public.creator_overrides(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_overrides_created_at ON public.creator_overrides(created_at DESC);

-- Campaign revenue splits table (for fraud detection)
CREATE TABLE IF NOT EXISTS public.campaign_revenue_splits (
  split_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL,
  creator_allocation_percentage INT CHECK (creator_allocation_percentage >= 0 AND creator_allocation_percentage <= 100),
  platform_allocation_percentage INT CHECK (platform_allocation_percentage >= 0 AND platform_allocation_percentage <= 100),
  reported_revenue DECIMAL(10,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_campaign_splits_campaign ON public.campaign_revenue_splits(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_splits_updated_at ON public.campaign_revenue_splits(updated_at DESC);

-- Business Intelligence Supporting Tables

-- VP economy metrics
CREATE TABLE IF NOT EXISTS public.vp_economy_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL UNIQUE,
  health_score INT CHECK (health_score >= 0 AND health_score <= 100),
  circulation_rate DECIMAL(5,2),
  inflation_rate DECIMAL(5,2),
  total_vp_supply BIGINT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vp_economy_date ON public.vp_economy_metrics(date DESC);

-- SLA metrics
CREATE TABLE IF NOT EXISTS public.sla_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL UNIQUE,
  uptime_percentage DECIMAL(5,2),
  downtime_minutes INT DEFAULT 0,
  incident_count INT DEFAULT 0,
  mttr_minutes INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sla_metrics_date ON public.sla_metrics(date DESC);

-- Customer satisfaction
CREATE TABLE IF NOT EXISTS public.customer_satisfaction (
  csat_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  score DECIMAL(2,1) CHECK (score >= 1 AND score <= 5),
  user_id UUID,
  feedback TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_csat_date ON public.customer_satisfaction(date DESC);

-- User activity logs (for DAU calculation)
CREATE TABLE IF NOT EXISTS public.user_activity_logs (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  activity_type TEXT NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata JSONB
);

CREATE INDEX IF NOT EXISTS idx_user_activity_timestamp ON public.user_activity_logs(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_user ON public.user_activity_logs(user_id);

-- Enable Row Level Security
ALTER TABLE public.incident_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.preventive_actions_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prediction_accuracy_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_revenue_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vp_economy_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sla_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_satisfaction ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activity_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Admin-only access for sensitive data)
CREATE POLICY "Admin full access to incident_predictions" ON public.incident_predictions
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to preventive_actions_log" ON public.preventive_actions_log
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to prediction_accuracy_metrics" ON public.prediction_accuracy_metrics
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to creator_accounts" ON public.creator_accounts
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to creator_overrides" ON public.creator_overrides
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to campaign_revenue_splits" ON public.campaign_revenue_splits
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to vp_economy_metrics" ON public.vp_economy_metrics
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Admin full access to sla_metrics" ON public.sla_metrics
  FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Users can view own CSAT" ON public.customer_satisfaction
  FOR SELECT USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "Users can insert own CSAT" ON public.customer_satisfaction
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own activity logs" ON public.user_activity_logs
  FOR SELECT USING (auth.uid() = user_id OR auth.jwt() ->> 'role' = 'admin');

CREATE POLICY "System can insert activity logs" ON public.user_activity_logs
  FOR INSERT WITH CHECK (TRUE);