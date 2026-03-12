-- =====================================================
-- PHASE 3: FEATURE FLAG MANAGEMENT + CI/CD + DATADOG APM
-- =====================================================

-- Drop existing tables if they exist to ensure clean state
DROP TABLE IF EXISTS public.flag_experiments CASCADE;
DROP TABLE IF EXISTS public.flag_dependencies CASCADE;
DROP TABLE IF EXISTS public.flag_audit_log CASCADE;
DROP TABLE IF EXISTS public.flag_usage_log CASCADE;
DROP TABLE IF EXISTS public.feature_flags CASCADE;

-- Feature Flags Table (Enhanced)
CREATE TABLE public.feature_flags (
  flag_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_key VARCHAR(200) UNIQUE NOT NULL,
  flag_name VARCHAR(200) NOT NULL,
  description TEXT,
  flag_type VARCHAR(50) DEFAULT 'boolean' CHECK (flag_type IN ('boolean', 'string', 'number', 'json')),
  default_value TEXT,
  is_enabled BOOLEAN DEFAULT false,
  rollout_strategy VARCHAR(50) DEFAULT 'percentage' CHECK (rollout_strategy IN ('percentage', 'whitelist', 'targeting', 'all')),
  rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  whitelist_user_ids UUID[] DEFAULT '{}',
  targeting_rules JSONB DEFAULT '{}'::jsonb,
  experiment_config JSONB,
  environment VARCHAR(20) DEFAULT 'production' CHECK (environment IN ('production', 'staging', 'development')),
  owner_team VARCHAR(100),
  created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deprecated_at TIMESTAMPTZ
);

CREATE INDEX idx_flags_key ON public.feature_flags(flag_key);
CREATE INDEX idx_flags_enabled ON public.feature_flags(is_enabled);
CREATE INDEX idx_flags_environment ON public.feature_flags(environment);

-- Flag Usage Log Table
CREATE TABLE public.flag_usage_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_key VARCHAR(200) NOT NULL,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  evaluated_value TEXT,
  evaluation_result BOOLEAN,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_usage_flag_key ON public.flag_usage_log(flag_key, timestamp DESC);
CREATE INDEX idx_usage_user ON public.flag_usage_log(user_id);

-- Flag Audit Log Table
CREATE TABLE public.flag_audit_log (
  audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_id UUID REFERENCES public.feature_flags(flag_id) ON DELETE CASCADE,
  action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('create', 'update', 'delete', 'enable', 'disable', 'rollout_change')),
  changed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  old_value JSONB,
  new_value JSONB,
  change_reason TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_flag ON public.flag_audit_log(flag_id, timestamp DESC);
CREATE INDEX idx_audit_user ON public.flag_audit_log(changed_by);

-- Flag Dependencies Table
CREATE TABLE public.flag_dependencies (
  dependency_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_id UUID REFERENCES public.feature_flags(flag_id) ON DELETE CASCADE,
  depends_on_flag_id UUID REFERENCES public.feature_flags(flag_id) ON DELETE CASCADE,
  dependency_type VARCHAR(20) DEFAULT 'required' CHECK (dependency_type IN ('required', 'optional')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_dependencies_flag ON public.flag_dependencies(flag_id);
CREATE INDEX idx_dependencies_depends ON public.flag_dependencies(depends_on_flag_id);

-- Flag Experiments Table (A/B Testing)
CREATE TABLE public.flag_experiments (
  experiment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_id UUID REFERENCES public.feature_flags(flag_id) ON DELETE CASCADE,
  experiment_name VARCHAR(200) NOT NULL,
  variant_configs JSONB NOT NULL,
  traffic_split JSONB NOT NULL,
  success_metric VARCHAR(100),
  tracking_events TEXT[] DEFAULT '{}',
  min_sample_size INTEGER DEFAULT 1000,
  significance_level DECIMAL(3,2) DEFAULT 0.95,
  start_date TIMESTAMPTZ DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  status VARCHAR(20) DEFAULT 'running' CHECK (status IN ('running', 'paused', 'completed')),
  winner_variant VARCHAR(100),
  statistical_results JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_experiments_flag ON public.flag_experiments(flag_id);
CREATE INDEX idx_experiments_status ON public.flag_experiments(status);

-- CI/CD Deployment Logs Table
CREATE TABLE IF NOT EXISTS public.cicd_deployment_logs (
  deployment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_name VARCHAR(200) NOT NULL,
  environment VARCHAR(50) NOT NULL CHECK (environment IN ('staging', 'production')),
  status VARCHAR(50) NOT NULL CHECK (status IN ('pending', 'running', 'success', 'failed', 'cancelled')),
  version VARCHAR(100),
  commit_sha VARCHAR(100),
  triggered_by VARCHAR(200),
  start_time TIMESTAMPTZ DEFAULT NOW(),
  end_time TIMESTAMPTZ,
  duration_seconds INTEGER,
  artifacts JSONB DEFAULT '{}'::jsonb,
  error_message TEXT,
  rollback_from UUID REFERENCES public.cicd_deployment_logs(deployment_id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_deployments_env ON public.cicd_deployment_logs(environment, start_time DESC);
CREATE INDEX IF NOT EXISTS idx_deployments_status ON public.cicd_deployment_logs(status);

-- Datadog APM Traces Table (Local Caching)
CREATE TABLE IF NOT EXISTS public.datadog_apm_traces (
  trace_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  span_id UUID NOT NULL,
  parent_span_id UUID,
  service_name VARCHAR(100) NOT NULL,
  operation_name VARCHAR(200) NOT NULL,
  resource_name VARCHAR(200),
  start_time TIMESTAMPTZ NOT NULL,
  duration_ms INTEGER NOT NULL,
  tags JSONB DEFAULT '{}'::jsonb,
  error BOOLEAN DEFAULT false,
  error_message TEXT,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_apm_service ON public.datadog_apm_traces(service_name, start_time DESC);
CREATE INDEX IF NOT EXISTS idx_apm_operation ON public.datadog_apm_traces(operation_name);
CREATE INDEX IF NOT EXISTS idx_apm_error ON public.datadog_apm_traces(error) WHERE error = true;
CREATE INDEX IF NOT EXISTS idx_apm_duration ON public.datadog_apm_traces(duration_ms DESC);

-- Datadog Performance Metrics Table
CREATE TABLE IF NOT EXISTS public.datadog_performance_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name VARCHAR(200) NOT NULL,
  metric_type VARCHAR(50) NOT NULL CHECK (metric_type IN ('gauge', 'count', 'histogram', 'rate')),
  value DECIMAL(20,4) NOT NULL,
  tags JSONB DEFAULT '{}'::jsonb,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_metrics_name ON public.datadog_performance_metrics(metric_name, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_type ON public.datadog_performance_metrics(metric_type);

-- ============================================
-- RLS POLICIES
-- ============================================

-- Feature Flags RLS (Admin only)
ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage feature flags" ON public.feature_flags;
CREATE POLICY "Admins can manage feature flags"
  ON public.feature_flags FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Users can read enabled flags" ON public.feature_flags;
CREATE POLICY "Users can read enabled flags"
  ON public.feature_flags FOR SELECT
  USING (is_enabled = true);

-- Flag Usage Log RLS
ALTER TABLE public.flag_usage_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can insert usage logs" ON public.flag_usage_log;
CREATE POLICY "Anyone can insert usage logs"
  ON public.flag_usage_log FOR INSERT
  WITH CHECK (true);

DROP POLICY IF EXISTS "Admins can view usage logs" ON public.flag_usage_log;
CREATE POLICY "Admins can view usage logs"
  ON public.flag_usage_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Flag Audit Log RLS (Admin only)
ALTER TABLE public.flag_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage audit logs" ON public.flag_audit_log;
CREATE POLICY "Admins can manage audit logs"
  ON public.flag_audit_log FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Flag Dependencies RLS (Admin only)
ALTER TABLE public.flag_dependencies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage dependencies" ON public.flag_dependencies;
CREATE POLICY "Admins can manage dependencies"
  ON public.flag_dependencies FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Flag Experiments RLS (Admin only)
ALTER TABLE public.flag_experiments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage experiments" ON public.flag_experiments;
CREATE POLICY "Admins can manage experiments"
  ON public.flag_experiments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- CI/CD Deployment Logs RLS (Admin only)
ALTER TABLE public.cicd_deployment_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view deployment logs" ON public.cicd_deployment_logs;
CREATE POLICY "Admins can view deployment logs"
  ON public.cicd_deployment_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "System can insert deployment logs" ON public.cicd_deployment_logs;
CREATE POLICY "System can insert deployment logs"
  ON public.cicd_deployment_logs FOR INSERT
  WITH CHECK (true);

-- Datadog APM Traces RLS (Admin only)
ALTER TABLE public.datadog_apm_traces ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view APM traces" ON public.datadog_apm_traces;
CREATE POLICY "Admins can view APM traces"
  ON public.datadog_apm_traces FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "System can insert APM traces" ON public.datadog_apm_traces;
CREATE POLICY "System can insert APM traces"
  ON public.datadog_apm_traces FOR INSERT
  WITH CHECK (true);

-- Datadog Performance Metrics RLS (Admin only)
ALTER TABLE public.datadog_performance_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view performance metrics" ON public.datadog_performance_metrics;
CREATE POLICY "Admins can view performance metrics"
  ON public.datadog_performance_metrics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "System can insert performance metrics" ON public.datadog_performance_metrics;
CREATE POLICY "System can insert performance metrics"
  ON public.datadog_performance_metrics FOR INSERT
  WITH CHECK (true);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to evaluate feature flag for user
CREATE OR REPLACE FUNCTION public.evaluate_feature_flag(
  p_flag_key VARCHAR,
  p_user_id UUID DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_flag RECORD;
  v_result BOOLEAN := false;
  v_random_value INTEGER;
BEGIN
  -- Get flag configuration
  SELECT * INTO v_flag
  FROM public.feature_flags
  WHERE flag_key = p_flag_key AND is_enabled = true;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Evaluate based on rollout strategy
  CASE v_flag.rollout_strategy
    WHEN 'all' THEN
      v_result := true;
    
    WHEN 'percentage' THEN
      v_random_value := floor(random() * 100);
      v_result := v_random_value < v_flag.rollout_percentage;
    
    WHEN 'whitelist' THEN
      IF p_user_id IS NOT NULL THEN
        v_result := p_user_id = ANY(v_flag.whitelist_user_ids);
      END IF;
    
    WHEN 'targeting' THEN
      -- Simplified targeting (can be enhanced)
      v_result := true;
    
    ELSE
      v_result := false;
  END CASE;

  -- Log usage
  INSERT INTO public.flag_usage_log (flag_key, user_id, evaluated_value, evaluation_result)
  VALUES (p_flag_key, p_user_id, v_flag.default_value, v_result);

  RETURN v_result;
END;
$$;

-- Function to calculate A/B test statistical significance
CREATE OR REPLACE FUNCTION public.calculate_ab_test_significance(
  p_experiment_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_variant_a_conversions INTEGER;
  v_variant_a_total INTEGER;
  v_variant_b_conversions INTEGER;
  v_variant_b_total INTEGER;
  v_p_value DECIMAL;
  v_result JSONB;
BEGIN
  -- Get conversion data (simplified)
  SELECT 
    COUNT(*) FILTER (WHERE evaluation_result = true AND evaluated_value = 'A'),
    COUNT(*) FILTER (WHERE evaluated_value = 'A'),
    COUNT(*) FILTER (WHERE evaluation_result = true AND evaluated_value = 'B'),
    COUNT(*) FILTER (WHERE evaluated_value = 'B')
  INTO v_variant_a_conversions, v_variant_a_total, v_variant_b_conversions, v_variant_b_total
  FROM public.flag_usage_log
  WHERE flag_key = (
    SELECT f.flag_key 
    FROM public.feature_flags f 
    JOIN public.flag_experiments e ON f.flag_id = e.flag_id 
    WHERE e.experiment_id = p_experiment_id
  );

  -- Simple chi-square approximation (for demonstration)
  v_p_value := CASE
    WHEN v_variant_a_total > 0 AND v_variant_b_total > 0 THEN
      ABS((v_variant_a_conversions::DECIMAL / v_variant_a_total) - 
          (v_variant_b_conversions::DECIMAL / v_variant_b_total))
    ELSE 1.0
  END;

  v_result := jsonb_build_object(
    'variant_a', jsonb_build_object(
      'conversions', v_variant_a_conversions,
      'total', v_variant_a_total,
      'rate', CASE WHEN v_variant_a_total > 0 THEN v_variant_a_conversions::DECIMAL / v_variant_a_total ELSE 0 END
    ),
    'variant_b', jsonb_build_object(
      'conversions', v_variant_b_conversions,
      'total', v_variant_b_total,
      'rate', CASE WHEN v_variant_b_total > 0 THEN v_variant_b_conversions::DECIMAL / v_variant_b_total ELSE 0 END
    ),
    'p_value', v_p_value,
    'is_significant', v_p_value < 0.05
  );

  -- Update experiment results
  UPDATE public.flag_experiments
  SET statistical_results = v_result
  WHERE experiment_id = p_experiment_id;

  RETURN v_result;
END;
$$;

-- Trigger to update feature_flags.updated_at
CREATE OR REPLACE FUNCTION public.update_feature_flag_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_feature_flag_timestamp ON public.feature_flags;
CREATE TRIGGER trigger_update_feature_flag_timestamp
  BEFORE UPDATE ON public.feature_flags
  FOR EACH ROW
  EXECUTE FUNCTION public.update_feature_flag_timestamp();

-- Trigger to log flag changes to audit log
CREATE OR REPLACE FUNCTION public.log_feature_flag_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_action_type VARCHAR(50);
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_action_type := 'create';
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.is_enabled != NEW.is_enabled THEN
      v_action_type := CASE WHEN NEW.is_enabled THEN 'enable' ELSE 'disable' END;
    ELSIF OLD.rollout_percentage != NEW.rollout_percentage THEN
      v_action_type := 'rollout_change';
    ELSE
      v_action_type := 'update';
    END IF;
  ELSIF TG_OP = 'DELETE' THEN
    v_action_type := 'delete';
  END IF;

  INSERT INTO public.flag_audit_log (flag_id, action_type, changed_by, old_value, new_value)
  VALUES (
    COALESCE(NEW.flag_id, OLD.flag_id),
    v_action_type,
    auth.uid(),
    CASE WHEN TG_OP != 'INSERT' THEN row_to_json(OLD) ELSE NULL END,
    CASE WHEN TG_OP != 'DELETE' THEN row_to_json(NEW) ELSE NULL END
  );

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trigger_log_feature_flag_changes ON public.feature_flags;
CREATE TRIGGER trigger_log_feature_flag_changes
  AFTER INSERT OR UPDATE OR DELETE ON public.feature_flags
  FOR EACH ROW
  EXECUTE FUNCTION public.log_feature_flag_changes();
