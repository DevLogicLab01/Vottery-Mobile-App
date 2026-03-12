-- AI-Powered Predictive Analytics & Prevention Hub Migration
-- Created: 2026-02-22

-- Predictive Recommendations Table
CREATE TABLE IF NOT EXISTS public.predictive_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  forecast_date DATE NOT NULL,
  recommendation_text TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('traffic', 'fraud', 'infrastructure', 'security', 'performance')),
  priority TEXT NOT NULL CHECK (priority IN ('critical', 'high', 'medium', 'low')),
  estimated_implementation_time TEXT,
  expected_benefit TEXT,
  implementation_steps JSONB DEFAULT '[]'::jsonb,
  implementation_status TEXT DEFAULT 'pending' CHECK (implementation_status IN ('pending', 'in_progress', 'completed', 'dismissed')),
  implemented_at TIMESTAMPTZ,
  dismissed_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Traffic Forecasts Table
CREATE TABLE IF NOT EXISTS public.traffic_forecasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  forecast_date DATE NOT NULL,
  forecast_period INT NOT NULL CHECK (forecast_period IN (30, 60, 90)),
  expected_daily_traffic INT NOT NULL,
  confidence_interval_low INT NOT NULL,
  confidence_interval_high INT NOT NULL,
  peak_concurrent_users INT NOT NULL,
  recommended_server_capacity TEXT,
  scaling_triggers JSONB DEFAULT '[]'::jsonb,
  seasonal_factors JSONB DEFAULT '{}'::jsonb,
  confidence_score DECIMAL(5,4) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Fraud Forecasts Table
CREATE TABLE IF NOT EXISTS public.fraud_forecasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  forecast_date DATE NOT NULL,
  forecast_period INT NOT NULL CHECK (forecast_period IN (30, 60, 90)),
  predicted_fraud_attempts_per_day INT NOT NULL,
  predicted_financial_impact DECIMAL(12,2) NOT NULL,
  emerging_attack_types JSONB DEFAULT '[]'::jsonb,
  vulnerable_systems JSONB DEFAULT '[]'::jsonb,
  prevention_recommendations JSONB DEFAULT '[]'::jsonb,
  confidence_score DECIMAL(5,4) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Infrastructure Scaling Forecasts Table
CREATE TABLE IF NOT EXISTS public.infrastructure_forecasts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  forecast_date DATE NOT NULL,
  forecast_period INT NOT NULL CHECK (forecast_period IN (30, 60, 90)),
  scaling_timeline JSONB DEFAULT '[]'::jsonb,
  total_estimated_cost DECIMAL(12,2) NOT NULL,
  resource_requirements JSONB DEFAULT '{}'::jsonb,
  confidence_score DECIMAL(5,4) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Alert Thresholds Table
CREATE TABLE IF NOT EXISTS public.alert_thresholds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL,
  threshold_config JSONB NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Active Security Policies Table
CREATE TABLE IF NOT EXISTS public.active_security_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id TEXT NOT NULL UNIQUE,
  rule_name TEXT NOT NULL,
  rule_type TEXT NOT NULL CHECK (rule_type IN ('rate_limit', 'ip_block', 'pattern_block', 'auth_requirement', 'input_validation')),
  rule_definition JSONB NOT NULL,
  policy_status TEXT DEFAULT 'enabled' CHECK (policy_status IN ('enabled', 'disabled', 'testing')),
  effectiveness_rate DECIMAL(5,2) DEFAULT 0,
  false_positive_rate DECIMAL(5,2) DEFAULT 0,
  attacks_prevented_count INT DEFAULT 0,
  created_by TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Policy Audit Log Table
CREATE TABLE IF NOT EXISTS public.policy_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id TEXT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('created', 'modified', 'enabled', 'disabled', 'deleted', 'tested')),
  actor TEXT NOT NULL,
  changes JSONB,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Compliance Policies Table
CREATE TABLE IF NOT EXISTS public.compliance_policies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  regulation_reference TEXT NOT NULL,
  policy_description TEXT NOT NULL,
  implementation_steps JSONB DEFAULT '[]'::jsonb,
  compliance_verification_method TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'blocked')),
  assigned_to UUID REFERENCES auth.users(id),
  due_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- False Positive Reports Table
CREATE TABLE IF NOT EXISTS public.false_positive_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id TEXT NOT NULL,
  request_details JSONB NOT NULL,
  reported_by UUID REFERENCES auth.users(id),
  verified BOOLEAN DEFAULT false,
  resolution TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Batch Operations Log Table
CREATE TABLE IF NOT EXISTS public.batch_operations_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_type TEXT NOT NULL,
  target_entity TEXT NOT NULL,
  affected_count INT NOT NULL,
  operator UUID REFERENCES auth.users(id),
  operation_details JSONB,
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Blocked Requests Table (for prevention tracking)
CREATE TABLE IF NOT EXISTS public.blocked_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id TEXT NOT NULL,
  request_ip TEXT,
  request_path TEXT,
  request_method TEXT,
  block_reason TEXT NOT NULL,
  blocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_predictive_recommendations_date ON public.predictive_recommendations(forecast_date);
CREATE INDEX IF NOT EXISTS idx_predictive_recommendations_status ON public.predictive_recommendations(implementation_status);
CREATE INDEX IF NOT EXISTS idx_traffic_forecasts_date ON public.traffic_forecasts(forecast_date);
CREATE INDEX IF NOT EXISTS idx_fraud_forecasts_date ON public.fraud_forecasts(forecast_date);
CREATE INDEX IF NOT EXISTS idx_infrastructure_forecasts_date ON public.infrastructure_forecasts(forecast_date);
CREATE INDEX IF NOT EXISTS idx_alert_thresholds_user ON public.alert_thresholds(user_id);
CREATE INDEX IF NOT EXISTS idx_active_security_policies_status ON public.active_security_policies(policy_status);
CREATE INDEX IF NOT EXISTS idx_policy_audit_log_policy ON public.policy_audit_log(policy_id);
CREATE INDEX IF NOT EXISTS idx_blocked_requests_policy ON public.blocked_requests(policy_id);
CREATE INDEX IF NOT EXISTS idx_blocked_requests_date ON public.blocked_requests(blocked_at);

-- Enable RLS
ALTER TABLE public.predictive_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.traffic_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fraud_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.infrastructure_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_thresholds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.active_security_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.policy_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compliance_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.false_positive_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batch_operations_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blocked_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies (Admin-only access)
CREATE POLICY "Admin full access to predictive_recommendations" ON public.predictive_recommendations
  FOR ALL USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin', 'devops_admin'));

CREATE POLICY "Admin full access to traffic_forecasts" ON public.traffic_forecasts
  FOR ALL USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin', 'devops_admin'));

CREATE POLICY "Admin full access to fraud_forecasts" ON public.fraud_forecasts
  FOR ALL USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin', 'devops_admin'));

CREATE POLICY "Admin full access to infrastructure_forecasts" ON public.infrastructure_forecasts
  FOR ALL USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin', 'devops_admin'));

CREATE POLICY "Users can manage their alert_thresholds" ON public.alert_thresholds
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admin full access to active_security_policies" ON public.active_security_policies
  FOR ALL USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin'));

CREATE POLICY "Admin full access to policy_audit_log" ON public.policy_audit_log
  FOR ALL USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin'));

CREATE POLICY "Admin full access to compliance_policies" ON public.compliance_policies
  FOR ALL USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin'));

CREATE POLICY "Users can report false_positives" ON public.false_positive_reports
  FOR INSERT WITH CHECK (auth.uid() = reported_by);

CREATE POLICY "Admin read false_positive_reports" ON public.false_positive_reports
  FOR SELECT USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin'));

CREATE POLICY "Admin full access to batch_operations_log" ON public.batch_operations_log
  FOR ALL USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin', 'devops_admin'));

CREATE POLICY "Admin full access to blocked_requests" ON public.blocked_requests
  FOR ALL USING (auth.jwt() ->> 'role'::text IN ('super_admin', 'security_admin'));