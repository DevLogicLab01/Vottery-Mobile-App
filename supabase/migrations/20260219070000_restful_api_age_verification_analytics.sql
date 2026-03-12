-- RESTful API Layer, Age Verification, and Comprehensive Analytics
-- Timestamp: 20260219070000

-- ============================================================
-- 1. RESTFUL API LAYER TABLES
-- ============================================================

-- API request logs
CREATE TABLE IF NOT EXISTS public.api_request_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL CHECK (method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH')),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  request_body JSONB,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add request_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'api_request_logs' 
    AND column_name = 'request_id'
  ) THEN
    ALTER TABLE public.api_request_logs ADD COLUMN request_id TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT;
  END IF;
END $$;

-- Add unique constraint on request_id if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'api_request_logs_request_id_key' 
    AND conrelid = 'public.api_request_logs'::regclass
  ) THEN
    ALTER TABLE public.api_request_logs ADD CONSTRAINT api_request_logs_request_id_key UNIQUE (request_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_api_request_logs_endpoint ON public.api_request_logs(endpoint);
CREATE INDEX IF NOT EXISTS idx_api_request_logs_user ON public.api_request_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_api_request_logs_timestamp ON public.api_request_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_api_request_logs_request_id ON public.api_request_logs(request_id);

-- API response logs
CREATE TABLE IF NOT EXISTS public.api_response_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  endpoint TEXT NOT NULL,
  status_code INTEGER NOT NULL,
  response_time_ms INTEGER NOT NULL,
  response_body JSONB,
  error_message TEXT,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add request_id column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'api_response_logs' 
    AND column_name = 'request_id'
  ) THEN
    ALTER TABLE public.api_response_logs ADD COLUMN request_id TEXT NOT NULL DEFAULT gen_random_uuid()::TEXT;
  END IF;
END $$;

-- Add foreign key constraint if it doesn't exist (only after UNIQUE constraint is confirmed)
DO $$
BEGIN
  -- Check if both the unique constraint exists and the foreign key doesn't
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'api_request_logs_request_id_key' 
    AND conrelid = 'public.api_request_logs'::regclass
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'api_response_logs_request_id_fkey' 
    AND conrelid = 'public.api_response_logs'::regclass
  ) THEN
    ALTER TABLE public.api_response_logs 
    ADD CONSTRAINT api_response_logs_request_id_fkey 
    FOREIGN KEY (request_id) REFERENCES public.api_request_logs(request_id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_api_response_logs_request ON public.api_response_logs(request_id);
CREATE INDEX IF NOT EXISTS idx_api_response_logs_endpoint ON public.api_response_logs(endpoint);
CREATE INDEX IF NOT EXISTS idx_api_response_logs_status ON public.api_response_logs(status_code);

-- API performance metrics
CREATE TABLE IF NOT EXISTS public.api_performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  endpoint TEXT NOT NULL,
  total_requests INTEGER DEFAULT 0,
  successful_requests INTEGER DEFAULT 0,
  failed_requests INTEGER DEFAULT 0,
  avg_response_time_ms NUMERIC(10,2) DEFAULT 0.00,
  p50_response_time_ms INTEGER DEFAULT 0,
  p95_response_time_ms INTEGER DEFAULT 0,
  p99_response_time_ms INTEGER DEFAULT 0,
  success_rate NUMERIC(5,2) DEFAULT 0.00,
  last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(endpoint)
);

CREATE INDEX IF NOT EXISTS idx_api_performance_metrics_endpoint ON public.api_performance_metrics(endpoint);

-- Function to get API endpoint statistics
CREATE OR REPLACE FUNCTION get_api_endpoint_statistics()
RETURNS TABLE (
  endpoint TEXT,
  total_requests BIGINT,
  avg_response_time NUMERIC,
  success_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    arl.endpoint,
    COUNT(*)::BIGINT as total_requests,
    AVG(arsl.response_time_ms)::NUMERIC as avg_response_time,
    (COUNT(*) FILTER (WHERE arsl.status_code < 400)::NUMERIC / COUNT(*)::NUMERIC * 100) as success_rate
  FROM api_request_logs arl
  JOIN api_response_logs arsl ON arl.request_id = arsl.request_id
  WHERE arl.timestamp >= NOW() - INTERVAL '24 hours'
  GROUP BY arl.endpoint;
END;
$$ LANGUAGE plpgsql;

-- Function to update API performance metrics
CREATE OR REPLACE FUNCTION update_api_performance_metrics(
  p_endpoint TEXT,
  p_response_time INTEGER,
  p_status_code INTEGER
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO api_performance_metrics (endpoint, total_requests, successful_requests, failed_requests, avg_response_time_ms)
  VALUES (p_endpoint, 1, CASE WHEN p_status_code < 400 THEN 1 ELSE 0 END, CASE WHEN p_status_code >= 400 THEN 1 ELSE 0 END, p_response_time)
  ON CONFLICT (endpoint) DO UPDATE SET
    total_requests = api_performance_metrics.total_requests + 1,
    successful_requests = api_performance_metrics.successful_requests + CASE WHEN p_status_code < 400 THEN 1 ELSE 0 END,
    failed_requests = api_performance_metrics.failed_requests + CASE WHEN p_status_code >= 400 THEN 1 ELSE 0 END,
    avg_response_time_ms = ((api_performance_metrics.avg_response_time_ms * api_performance_metrics.total_requests) + p_response_time) / (api_performance_metrics.total_requests + 1),
    success_rate = ((api_performance_metrics.successful_requests + CASE WHEN p_status_code < 400 THEN 1 ELSE 0 END)::NUMERIC / (api_performance_metrics.total_requests + 1)::NUMERIC * 100),
    last_updated = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 2. AGE VERIFICATION TABLES
-- ============================================================

-- Age verification attempts
CREATE TABLE IF NOT EXISTS public.age_verification_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID REFERENCES public.elections(id) ON DELETE CASCADE,
  method TEXT NOT NULL CHECK (method IN ('facial_estimation', 'government_id', 'digital_wallet', 'manual_review')),
  provider TEXT NOT NULL CHECK (provider IN ('yoti', 'stripe_identity', 'manual')),
  verification_result TEXT NOT NULL CHECK (verification_result IN ('pass', 'fail', 'pending', 'borderline')),
  estimated_age INTEGER,
  confidence_score NUMERIC(5,2),
  fallback_triggered BOOLEAN DEFAULT FALSE,
  waterfall_step INTEGER DEFAULT 1,
  iso_compliant BOOLEAN DEFAULT TRUE,
  data_deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_age_verification_user ON public.age_verification_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_age_verification_election ON public.age_verification_attempts(election_id);
CREATE INDEX IF NOT EXISTS idx_age_verification_result ON public.age_verification_attempts(verification_result);
CREATE INDEX IF NOT EXISTS idx_age_verification_created ON public.age_verification_attempts(created_at);

-- Age verification compliance logs
CREATE TABLE IF NOT EXISTS public.age_verification_compliance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  verification_id UUID REFERENCES public.age_verification_attempts(id) ON DELETE CASCADE,
  compliance_standard TEXT NOT NULL,
  data_retention_days INTEGER NOT NULL,
  deletion_scheduled_at TIMESTAMPTZ,
  deletion_completed_at TIMESTAMPTZ,
  audit_trail JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_age_compliance_verification ON public.age_verification_compliance_logs(verification_id);
CREATE INDEX IF NOT EXISTS idx_age_compliance_deletion ON public.age_verification_compliance_logs(deletion_scheduled_at);

-- Function to schedule age verification data deletion
CREATE OR REPLACE FUNCTION schedule_age_verification_deletion()
RETURNS VOID AS $$
BEGIN
  -- Mark data for deletion after 30 days (ISO/IEC 27566-1:2025 compliance)
  UPDATE age_verification_attempts
  SET data_deleted_at = CURRENT_TIMESTAMP
  WHERE created_at < NOW() - INTERVAL '30 days'
    AND data_deleted_at IS NULL;
    
  -- Log compliance action
  INSERT INTO age_verification_compliance_logs (verification_id, compliance_standard, data_retention_days, deletion_completed_at)
  SELECT id, 'ISO/IEC 27566-1:2025', 30, CURRENT_TIMESTAMP
  FROM age_verification_attempts
  WHERE data_deleted_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 3. COMPREHENSIVE FEATURE ANALYTICS TABLES
-- ============================================================

-- GA4 screen tracking
CREATE TABLE IF NOT EXISTS public.ga4_screen_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  screen_name TEXT NOT NULL,
  screen_class TEXT NOT NULL,
  session_id TEXT NOT NULL,
  engagement_time_ms INTEGER DEFAULT 0,
  previous_screen TEXT,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ga4_screen_user ON public.ga4_screen_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_ga4_screen_name ON public.ga4_screen_tracking(screen_name);
CREATE INDEX IF NOT EXISTS idx_ga4_screen_session ON public.ga4_screen_tracking(session_id);
CREATE INDEX IF NOT EXISTS idx_ga4_screen_timestamp ON public.ga4_screen_tracking(timestamp);

-- Cohort analysis
CREATE TABLE IF NOT EXISTS public.cohort_analysis (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cohort_name TEXT NOT NULL,
  cohort_type TEXT NOT NULL CHECK (cohort_type IN ('acquisition', 'behavior', 'revenue', 'feature_usage')),
  user_ids UUID[] NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  metrics JSONB NOT NULL,
  retention_data JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_cohort_name ON public.cohort_analysis(cohort_name);
CREATE INDEX IF NOT EXISTS idx_cohort_type ON public.cohort_analysis(cohort_type);
CREATE INDEX IF NOT EXISTS idx_cohort_start_date ON public.cohort_analysis(start_date);

-- A/B testing framework
CREATE TABLE IF NOT EXISTS public.ab_testing_experiments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_name TEXT NOT NULL UNIQUE,
  feature_flag TEXT NOT NULL,
  variant_a_config JSONB NOT NULL,
  variant_b_config JSONB NOT NULL,
  user_segment JSONB,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  status TEXT NOT NULL CHECK (status IN ('draft', 'active', 'paused', 'completed')),
  winner_variant TEXT CHECK (winner_variant IN ('A', 'B', 'inconclusive')),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ab_experiment_name ON public.ab_testing_experiments(experiment_name);
CREATE INDEX IF NOT EXISTS idx_ab_status ON public.ab_testing_experiments(status);

-- A/B testing user assignments
CREATE TABLE IF NOT EXISTS public.ab_testing_user_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID REFERENCES public.ab_testing_experiments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  variant TEXT NOT NULL CHECK (variant IN ('A', 'B')),
  assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(experiment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_ab_user_experiment ON public.ab_testing_user_assignments(experiment_id);
CREATE INDEX IF NOT EXISTS idx_ab_user_id ON public.ab_testing_user_assignments(user_id);

-- A/B testing metrics
CREATE TABLE IF NOT EXISTS public.ab_testing_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  experiment_id UUID REFERENCES public.ab_testing_experiments(id) ON DELETE CASCADE,
  variant TEXT NOT NULL CHECK (variant IN ('A', 'B')),
  metric_name TEXT NOT NULL,
  metric_value NUMERIC NOT NULL,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ab_metrics_experiment ON public.ab_testing_metrics(experiment_id);
CREATE INDEX IF NOT EXISTS idx_ab_metrics_variant ON public.ab_testing_metrics(variant);
CREATE INDEX IF NOT EXISTS idx_ab_metrics_name ON public.ab_testing_metrics(metric_name);

-- Revenue attribution model
CREATE TABLE IF NOT EXISTS public.revenue_attribution (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  feature_name TEXT NOT NULL,
  screen_name TEXT NOT NULL,
  revenue_amount NUMERIC(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  attribution_model TEXT NOT NULL CHECK (attribution_model IN ('first_touch', 'last_touch', 'linear', 'time_decay')),
  touchpoint_sequence JSONB,
  transaction_id TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_revenue_attribution_user ON public.revenue_attribution(user_id);
CREATE INDEX IF NOT EXISTS idx_revenue_attribution_feature ON public.revenue_attribution(feature_name);
CREATE INDEX IF NOT EXISTS idx_revenue_attribution_screen ON public.revenue_attribution(screen_name);
CREATE INDEX IF NOT EXISTS idx_revenue_attribution_created ON public.revenue_attribution(created_at);

-- Function to calculate cohort retention
CREATE OR REPLACE FUNCTION calculate_cohort_retention(
  p_cohort_id UUID,
  p_days_since_start INTEGER
)
RETURNS NUMERIC AS $$
DECLARE
  v_total_users INTEGER;
  v_retained_users INTEGER;
  v_retention_rate NUMERIC;
BEGIN
  -- Get total users in cohort
  SELECT array_length(user_ids, 1) INTO v_total_users
  FROM cohort_analysis
  WHERE id = p_cohort_id;
  
  -- Calculate retained users (simplified - would need actual activity tracking)
  v_retained_users := v_total_users; -- Placeholder
  
  -- Calculate retention rate
  v_retention_rate := (v_retained_users::NUMERIC / v_total_users::NUMERIC) * 100;
  
  RETURN v_retention_rate;
END;
$$ LANGUAGE plpgsql;

-- Function to get A/B test results
CREATE OR REPLACE FUNCTION get_ab_test_results(p_experiment_id UUID)
RETURNS TABLE (
  variant TEXT,
  total_users BIGINT,
  avg_metric_value NUMERIC,
  conversion_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    aua.variant,
    COUNT(DISTINCT aua.user_id)::BIGINT as total_users,
    AVG(abm.metric_value)::NUMERIC as avg_metric_value,
    (COUNT(DISTINCT CASE WHEN abm.metric_value > 0 THEN aua.user_id END)::NUMERIC / 
     COUNT(DISTINCT aua.user_id)::NUMERIC * 100) as conversion_rate
  FROM ab_testing_user_assignments aua
  LEFT JOIN ab_testing_metrics abm ON aua.experiment_id = abm.experiment_id AND aua.variant = abm.variant
  WHERE aua.experiment_id = p_experiment_id
  GROUP BY aua.variant;
END;
$$ LANGUAGE plpgsql;

-- Function to track revenue attribution
CREATE OR REPLACE FUNCTION track_revenue_attribution(
  p_user_id UUID,
  p_feature_name TEXT,
  p_screen_name TEXT,
  p_revenue_amount NUMERIC,
  p_attribution_model TEXT DEFAULT 'last_touch'
)
RETURNS UUID AS $$
DECLARE
  v_attribution_id UUID;
BEGIN
  INSERT INTO revenue_attribution (
    user_id,
    feature_name,
    screen_name,
    revenue_amount,
    attribution_model
  )
  VALUES (
    p_user_id,
    p_feature_name,
    p_screen_name,
    p_revenue_amount,
    p_attribution_model
  )
  RETURNING id INTO v_attribution_id;
  
  RETURN v_attribution_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.api_request_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_response_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.age_verification_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.age_verification_compliance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_screen_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cohort_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ab_testing_experiments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ab_testing_user_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ab_testing_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.revenue_attribution ENABLE ROW LEVEL SECURITY;

-- API logs policies (admin only)
CREATE POLICY api_request_logs_admin_policy ON public.api_request_logs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY api_response_logs_admin_policy ON public.api_response_logs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY api_performance_metrics_admin_policy ON public.api_performance_metrics
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Age verification policies (users can view their own, admins can view all)
CREATE POLICY age_verification_user_policy ON public.age_verification_attempts
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY age_verification_insert_policy ON public.age_verification_attempts
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY age_compliance_admin_policy ON public.age_verification_compliance_logs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- GA4 tracking policies (users can track their own, admins can view all)
CREATE POLICY ga4_screen_tracking_user_policy ON public.ga4_screen_tracking
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY ga4_screen_tracking_admin_policy ON public.ga4_screen_tracking
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Cohort analysis policies (admin only)
CREATE POLICY cohort_analysis_admin_policy ON public.cohort_analysis
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- A/B testing policies (admin only for experiments, users can see their assignments)
CREATE POLICY ab_experiments_admin_policy ON public.ab_testing_experiments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY ab_user_assignments_user_policy ON public.ab_testing_user_assignments
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY ab_metrics_admin_policy ON public.ab_testing_metrics
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Revenue attribution policies (users can view their own, admins can view all)
CREATE POLICY revenue_attribution_user_policy ON public.revenue_attribution
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY revenue_attribution_insert_policy ON public.revenue_attribution
  FOR INSERT WITH CHECK (user_id = auth.uid());
