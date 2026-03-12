-- Comprehensive Feature Implementation Migration
-- Onboarding, Feedback Portal, Compliance, Monitoring, Revenue Sharing

-- Feature Requests Table (align with existing schema)
CREATE TABLE IF NOT EXISTS feature_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('elections', 'analytics', 'payments', 'security', 'ai', 'communication', 'gamification', 'other')),
  status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'under_review', 'planned', 'in_progress', 'implemented', 'rejected')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  vote_count INTEGER DEFAULT 0,
  implementation_date TIMESTAMPTZ,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feature_requests_status ON feature_requests(status);
CREATE INDEX IF NOT EXISTS idx_feature_requests_category ON feature_requests(category);
CREATE INDEX IF NOT EXISTS idx_feature_requests_created_at ON feature_requests(created_at DESC);

-- Feature Votes Table
CREATE TABLE IF NOT EXISTS feature_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_request_id UUID REFERENCES feature_requests(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('upvote', 'downvote')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(feature_request_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_feature_votes_feature_id ON feature_votes(feature_request_id);
CREATE INDEX IF NOT EXISTS idx_feature_votes_user_id ON feature_votes(user_id);

-- Compliance Audit Logs Table
CREATE TABLE IF NOT EXISTS compliance_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  compliance_type TEXT NOT NULL CHECK (compliance_type IN ('GDPR', 'PCI-DSS', 'SOC2', 'HIPAA')),
  action_type TEXT NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  resource_type TEXT,
  resource_id TEXT,
  details JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_compliance_logs_type ON compliance_audit_logs(compliance_type);
CREATE INDEX IF NOT EXISTS idx_compliance_logs_user ON compliance_audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_compliance_logs_created_at ON compliance_audit_logs(created_at DESC);

-- GDPR Data Requests Table
CREATE TABLE IF NOT EXISTS gdpr_data_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  request_type TEXT NOT NULL CHECK (request_type IN ('export', 'deletion', 'rectification', 'portability')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  data_url TEXT,
  notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_gdpr_requests_user ON gdpr_data_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_gdpr_requests_status ON gdpr_data_requests(status);

-- System Monitoring Table
CREATE TABLE IF NOT EXISTS system_monitoring (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name TEXT NOT NULL,
  service_type TEXT NOT NULL CHECK (service_type IN ('database', 'api', 'ai_service', 'payment', 'notification', 'storage')),
  status TEXT NOT NULL CHECK (status IN ('healthy', 'degraded', 'down', 'maintenance')),
  latency_ms INTEGER,
  error_rate DECIMAL(5,2),
  uptime_percentage DECIMAL(5,2),
  last_check TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_system_monitoring_service ON system_monitoring(service_name);
CREATE INDEX IF NOT EXISTS idx_system_monitoring_status ON system_monitoring(status);
CREATE INDEX IF NOT EXISTS idx_system_monitoring_last_check ON system_monitoring(last_check DESC);

-- Integration Health Checks Table
CREATE TABLE IF NOT EXISTS integration_health_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  integration_name TEXT NOT NULL,
  integration_type TEXT NOT NULL,
  is_healthy BOOLEAN DEFAULT true,
  response_time_ms INTEGER,
  error_message TEXT,
  last_successful_check TIMESTAMPTZ,
  consecutive_failures INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_integration_health_name ON integration_health_checks(integration_name);
CREATE INDEX IF NOT EXISTS idx_integration_health_status ON integration_health_checks(is_healthy);

-- Revenue Sharing Configuration Table
CREATE TABLE IF NOT EXISTS revenue_share_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_name TEXT NOT NULL,
  creator_percentage DECIMAL(5,2) NOT NULL DEFAULT 70.00,
  platform_percentage DECIMAL(5,2) NOT NULL DEFAULT 30.00,
  is_active BOOLEAN DEFAULT false,
  campaign_name TEXT,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  applicable_to_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CHECK (creator_percentage + platform_percentage = 100.00)
);

CREATE INDEX IF NOT EXISTS idx_revenue_configs_active ON revenue_share_configs(is_active);
CREATE INDEX IF NOT EXISTS idx_revenue_configs_dates ON revenue_share_configs(start_date, end_date);

-- Onboarding Progress Table
CREATE TABLE IF NOT EXISTS onboarding_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  current_step INTEGER DEFAULT 0,
  completed_steps INTEGER[] DEFAULT ARRAY[]::INTEGER[],
  is_completed BOOLEAN DEFAULT false,
  skipped BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_onboarding_user ON onboarding_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_completed ON onboarding_progress(is_completed);

-- RLS Policies
ALTER TABLE feature_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE gdpr_data_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE integration_health_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE revenue_share_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE onboarding_progress ENABLE ROW LEVEL SECURITY;

-- Feature Requests Policies
DROP POLICY IF EXISTS "Users can view all feature requests" ON feature_requests;
CREATE POLICY "Users can view all feature requests"
  ON feature_requests FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can create feature requests" ON feature_requests;
CREATE POLICY "Authenticated users can create feature requests"
  ON feature_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own feature requests" ON feature_requests;
CREATE POLICY "Users can update their own feature requests"
  ON feature_requests FOR UPDATE
  USING (auth.uid() = user_id);

-- Feature Votes Policies
DROP POLICY IF EXISTS "Users can view all feature votes" ON feature_votes;
CREATE POLICY "Users can view all feature votes"
  ON feature_votes FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can vote on features" ON feature_votes;
CREATE POLICY "Authenticated users can vote on features"
  ON feature_votes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own votes" ON feature_votes;
CREATE POLICY "Users can update their own votes"
  ON feature_votes FOR UPDATE
  USING (auth.uid() = user_id);

-- Compliance Audit Logs Policies (Admin only)
DROP POLICY IF EXISTS "Only admins can view compliance logs" ON compliance_audit_logs;
CREATE POLICY "Only admins can view compliance logs"
  ON compliance_audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- GDPR Data Requests Policies
DROP POLICY IF EXISTS "Users can view their own GDPR requests" ON gdpr_data_requests;
CREATE POLICY "Users can view their own GDPR requests"
  ON gdpr_data_requests FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their own GDPR requests" ON gdpr_data_requests;
CREATE POLICY "Users can create their own GDPR requests"
  ON gdpr_data_requests FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- System Monitoring Policies (Admin only)
DROP POLICY IF EXISTS "Only admins can view system monitoring" ON system_monitoring;
CREATE POLICY "Only admins can view system monitoring"
  ON system_monitoring FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Only admins can insert system monitoring" ON system_monitoring;
CREATE POLICY "Only admins can insert system monitoring"
  ON system_monitoring FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Integration Health Checks Policies (Admin only)
DROP POLICY IF EXISTS "Only admins can view integration health" ON integration_health_checks;
CREATE POLICY "Only admins can view integration health"
  ON integration_health_checks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Only admins can insert integration health" ON integration_health_checks;
CREATE POLICY "Only admins can insert integration health"
  ON integration_health_checks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Revenue Share Configs Policies (Admin only)
DROP POLICY IF EXISTS "Only admins can view revenue configs" ON revenue_share_configs;
CREATE POLICY "Only admins can view revenue configs"
  ON revenue_share_configs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Only admins can manage revenue configs" ON revenue_share_configs;
CREATE POLICY "Only admins can manage revenue configs"
  ON revenue_share_configs FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Onboarding Progress Policies
DROP POLICY IF EXISTS "Users can view their own onboarding progress" ON onboarding_progress;
CREATE POLICY "Users can view their own onboarding progress"
  ON onboarding_progress FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own onboarding progress" ON onboarding_progress;
CREATE POLICY "Users can update their own onboarding progress"
  ON onboarding_progress FOR ALL
  USING (auth.uid() = user_id);

-- Functions

-- Function to update feature request vote count
CREATE OR REPLACE FUNCTION update_feature_request_vote_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE feature_requests
    SET vote_count = vote_count + CASE WHEN NEW.vote_type = 'upvote' THEN 1 ELSE -1 END
    WHERE id = NEW.feature_request_id;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE feature_requests
    SET vote_count = vote_count + 
      CASE 
        WHEN NEW.vote_type = 'upvote' AND OLD.vote_type = 'downvote' THEN 2
        WHEN NEW.vote_type = 'downvote' AND OLD.vote_type = 'upvote' THEN -2
        ELSE 0
      END
    WHERE id = NEW.feature_request_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE feature_requests
    SET vote_count = vote_count - CASE WHEN OLD.vote_type = 'upvote' THEN 1 ELSE -1 END
    WHERE id = OLD.feature_request_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for feature vote count
DROP TRIGGER IF EXISTS trigger_update_feature_vote_count ON feature_votes;
CREATE TRIGGER trigger_update_feature_vote_count
AFTER INSERT OR UPDATE OR DELETE ON feature_votes
FOR EACH ROW
EXECUTE FUNCTION update_feature_request_vote_count();

-- Function to log compliance actions
CREATE OR REPLACE FUNCTION log_compliance_action(
  p_compliance_type TEXT,
  p_action_type TEXT,
  p_resource_type TEXT DEFAULT NULL,
  p_resource_id TEXT DEFAULT NULL,
  p_details JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
BEGIN
  INSERT INTO compliance_audit_logs (
    compliance_type,
    action_type,
    user_id,
    resource_type,
    resource_id,
    details
  )
  VALUES (
    p_compliance_type,
    p_action_type,
    auth.uid(),
    p_resource_type,
    p_resource_id,
    p_details
  )
  RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get active revenue share config
CREATE OR REPLACE FUNCTION get_active_revenue_share_config(p_user_id UUID DEFAULT NULL)
RETURNS TABLE (
  id UUID,
  config_name TEXT,
  creator_percentage DECIMAL,
  platform_percentage DECIMAL,
  campaign_name TEXT
) AS $$
BEGIN
  -- Check for user-specific config first
  IF p_user_id IS NOT NULL THEN
    RETURN QUERY
    SELECT 
      rsc.id,
      rsc.config_name,
      rsc.creator_percentage,
      rsc.platform_percentage,
      rsc.campaign_name
    FROM revenue_share_configs rsc
    WHERE rsc.is_active = true
      AND rsc.applicable_to_user_id = p_user_id
      AND (rsc.start_date IS NULL OR rsc.start_date <= NOW())
      AND (rsc.end_date IS NULL OR rsc.end_date >= NOW())
    ORDER BY rsc.created_at DESC
    LIMIT 1;
    
    IF FOUND THEN
      RETURN;
    END IF;
  END IF;
  
  -- Fall back to global config
  RETURN QUERY
  SELECT 
    rsc.id,
    rsc.config_name,
    rsc.creator_percentage,
    rsc.platform_percentage,
    rsc.campaign_name
  FROM revenue_share_configs rsc
  WHERE rsc.is_active = true
    AND rsc.applicable_to_user_id IS NULL
    AND (rsc.start_date IS NULL OR rsc.start_date <= NOW())
    AND (rsc.end_date IS NULL OR rsc.end_date >= NOW())
  ORDER BY rsc.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update onboarding progress
CREATE OR REPLACE FUNCTION update_onboarding_progress(
  p_user_id UUID,
  p_step INTEGER,
  p_completed BOOLEAN DEFAULT false,
  p_skipped BOOLEAN DEFAULT false
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO onboarding_progress (
    user_id,
    current_step,
    completed_steps,
    is_completed,
    skipped,
    completed_at
  )
  VALUES (
    p_user_id,
    p_step,
    ARRAY[p_step],
    p_completed,
    p_skipped,
    CASE WHEN p_completed THEN NOW() ELSE NULL END
  )
  ON CONFLICT (user_id) DO UPDATE
  SET
    current_step = p_step,
    completed_steps = array_append(onboarding_progress.completed_steps, p_step),
    is_completed = p_completed,
    skipped = p_skipped,
    completed_at = CASE WHEN p_completed THEN NOW() ELSE onboarding_progress.completed_at END,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
