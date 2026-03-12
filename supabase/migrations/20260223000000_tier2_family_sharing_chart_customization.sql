-- TIER 2 Feature 1: Premium Subscription Enhancements - Family Sharing

-- Family members table
CREATE TABLE IF NOT EXISTS family_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  primary_account_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  member_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  relationship TEXT CHECK (relationship IN ('Spouse', 'Partner', 'Parent', 'Child', 'Sibling', 'Other')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'expired', 'revoked')),
  invitation_token TEXT UNIQUE,
  invitation_expires_at TIMESTAMPTZ,
  permissions JSONB DEFAULT '{"full_premium_access": false, "ad_free": false, "priority_support": false, "creator_tools": false, "analytics_dashboard": false, "api_access": false}'::jsonb,
  joined_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_family_members_primary ON family_members(primary_account_id);
CREATE INDEX idx_family_members_member ON family_members(member_user_id);
CREATE INDEX idx_family_members_status ON family_members(status);
CREATE INDEX idx_family_members_token ON family_members(invitation_token);

-- Family usage analytics table
CREATE TABLE IF NOT EXISTS family_usage_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  api_calls_count INTEGER DEFAULT 0,
  storage_used_mb NUMERIC(10,2) DEFAULT 0,
  active_features JSONB DEFAULT '[]'::jsonb,
  usage_time_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(subscription_id, user_id, date)
);

CREATE INDEX idx_family_usage_subscription ON family_usage_analytics(subscription_id);
CREATE INDEX idx_family_usage_user ON family_usage_analytics(user_id);
CREATE INDEX idx_family_usage_date ON family_usage_analytics(date);

-- Churn predictions table
CREATE TABLE IF NOT EXISTS churn_predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_id UUID,
  prediction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  churn_probability NUMERIC(5,4) NOT NULL CHECK (churn_probability >= 0 AND churn_probability <= 1),
  contributing_factors JSONB DEFAULT '[]'::jsonb,
  recommended_interventions JSONB DEFAULT '[]'::jsonb,
  days_since_last_login INTEGER,
  feature_usage_frequency NUMERIC(5,2),
  support_tickets_submitted INTEGER DEFAULT 0,
  billing_issues_count INTEGER DEFAULT 0,
  subscription_duration_days INTEGER,
  feature_adoption_rate NUMERIC(5,4),
  engagement_score NUMERIC(5,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, prediction_date)
);

CREATE INDEX idx_churn_predictions_user ON churn_predictions(user_id);
CREATE INDEX idx_churn_predictions_probability ON churn_predictions(churn_probability);
CREATE INDEX idx_churn_predictions_date ON churn_predictions(prediction_date);

-- Retention offers table
CREATE TABLE IF NOT EXISTS retention_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  churn_prediction_id UUID REFERENCES churn_predictions(id) ON DELETE SET NULL,
  offer_type TEXT NOT NULL,
  discount_percentage INTEGER CHECK (discount_percentage >= 10 AND discount_percentage <= 50),
  offer_duration_months INTEGER CHECK (offer_duration_months >= 1 AND offer_duration_months <= 6),
  personalized_message TEXT,
  personalized_benefits JSONB DEFAULT '[]'::jsonb,
  urgency_factor TEXT,
  original_price NUMERIC(10,2),
  discounted_price NUMERIC(10,2),
  offer_expires_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
  accepted_at TIMESTAMPTZ,
  churn_risk_before NUMERIC(5,4),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_retention_offers_user ON retention_offers(user_id);
CREATE INDEX idx_retention_offers_status ON retention_offers(status);
CREATE INDEX idx_retention_offers_expires ON retention_offers(offer_expires_at);

-- TIER 2 Feature 2: Interactive Data Visualization Enhancement

-- User chart preferences table
CREATE TABLE IF NOT EXISTS user_chart_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chart_id TEXT NOT NULL,
  preferences JSONB NOT NULL DEFAULT '{"chart_type": "line", "color_scheme": "default", "axis_config": {}, "data_point_labels": false, "legend_config": {"position": "top"}}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, chart_id)
);

CREATE INDEX idx_chart_preferences_user ON user_chart_preferences(user_id);
CREATE INDEX idx_chart_preferences_chart ON user_chart_preferences(chart_id);

-- Chart anomalies table (AI-powered anomaly detection)
CREATE TABLE IF NOT EXISTS chart_anomalies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chart_id TEXT NOT NULL,
  data_point_timestamp TIMESTAMPTZ NOT NULL,
  data_point_value NUMERIC(15,4) NOT NULL,
  z_score NUMERIC(10,4),
  anomaly_type TEXT CHECK (anomaly_type IN ('spike', 'drop', 'trend_change', 'outlier')),
  explanation TEXT,
  confidence NUMERIC(5,4) CHECK (confidence >= 0 AND confidence <= 1),
  recommended_action TEXT,
  business_context TEXT,
  investigated BOOLEAN DEFAULT FALSE,
  investigated_at TIMESTAMPTZ,
  investigated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_chart_anomalies_chart ON chart_anomalies(chart_id);
CREATE INDEX idx_chart_anomalies_timestamp ON chart_anomalies(data_point_timestamp);
CREATE INDEX idx_chart_anomalies_investigated ON chart_anomalies(investigated);

-- Chart drill-down filters table
CREATE TABLE IF NOT EXISTS chart_drill_down_filters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,
  chart_id TEXT NOT NULL,
  filter_path JSONB NOT NULL DEFAULT '[]'::jsonb,
  current_level TEXT,
  applied_filters JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '24 hours'
);

CREATE INDEX idx_drill_down_filters_user ON chart_drill_down_filters(user_id);
CREATE INDEX idx_drill_down_filters_session ON chart_drill_down_filters(session_id);
CREATE INDEX idx_drill_down_filters_expires ON chart_drill_down_filters(expires_at);

-- Chart exports table
CREATE TABLE IF NOT EXISTS chart_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chart_id TEXT NOT NULL,
  export_format TEXT NOT NULL CHECK (export_format IN ('png', 'svg', 'csv', 'pdf', 'json')),
  resolution TEXT,
  include_title BOOLEAN DEFAULT TRUE,
  include_legend BOOLEAN DEFAULT TRUE,
  date_range_start TIMESTAMPTZ,
  date_range_end TIMESTAMPTZ,
  file_url TEXT,
  file_size_kb INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_chart_exports_user ON chart_exports(user_id);
CREATE INDEX idx_chart_exports_chart ON chart_exports(chart_id);
CREATE INDEX idx_chart_exports_created ON chart_exports(created_at);

-- Enable Row Level Security
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_usage_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE churn_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE retention_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_chart_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE chart_anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE chart_drill_down_filters ENABLE ROW LEVEL SECURITY;
ALTER TABLE chart_exports ENABLE ROW LEVEL SECURITY;

-- RLS Policies for family_members
CREATE POLICY "Users can view their own family members"
  ON family_members FOR SELECT
  USING (auth.uid() = primary_account_id OR auth.uid() = member_user_id);

CREATE POLICY "Primary account can manage family members"
  ON family_members FOR ALL
  USING (auth.uid() = primary_account_id);

-- RLS Policies for family_usage_analytics
CREATE POLICY "Users can view family usage analytics"
  ON family_usage_analytics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM family_members
      WHERE (primary_account_id = auth.uid() OR member_user_id = auth.uid())
      AND subscription_id = family_usage_analytics.subscription_id
    )
  );

CREATE POLICY "System can insert usage analytics"
  ON family_usage_analytics FOR INSERT
  WITH CHECK (TRUE);

-- RLS Policies for churn_predictions
CREATE POLICY "Users can view their own churn predictions"
  ON churn_predictions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage churn predictions"
  ON churn_predictions FOR ALL
  USING (TRUE);

-- RLS Policies for retention_offers
CREATE POLICY "Users can view their own retention offers"
  ON retention_offers FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update their retention offer status"
  ON retention_offers FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for user_chart_preferences
CREATE POLICY "Users can manage their own chart preferences"
  ON user_chart_preferences FOR ALL
  USING (auth.uid() = user_id);

-- RLS Policies for chart_anomalies
CREATE POLICY "Users can view chart anomalies"
  ON chart_anomalies FOR SELECT
  USING (TRUE);

CREATE POLICY "Authenticated users can update anomaly investigations"
  ON chart_anomalies FOR UPDATE
  USING (auth.uid() IS NOT NULL);

-- RLS Policies for chart_drill_down_filters
CREATE POLICY "Users can manage their own drill-down filters"
  ON chart_drill_down_filters FOR ALL
  USING (auth.uid() = user_id);

-- RLS Policies for chart_exports
CREATE POLICY "Users can manage their own chart exports"
  ON chart_exports FOR ALL
  USING (auth.uid() = user_id);

-- Functions and Triggers

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_family_members_updated_at
  BEFORE UPDATE ON family_members
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chart_preferences_updated_at
  BEFORE UPDATE ON user_chart_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate churn risk score
CREATE OR REPLACE FUNCTION calculate_churn_risk_score(
  p_days_since_last_login INTEGER,
  p_feature_usage_frequency NUMERIC,
  p_support_tickets INTEGER,
  p_billing_issues INTEGER,
  p_subscription_duration_days INTEGER,
  p_feature_adoption_rate NUMERIC,
  p_engagement_score NUMERIC
)
RETURNS NUMERIC AS $$
DECLARE
  risk_score NUMERIC := 0;
BEGIN
  -- Days since last login (weight: 0.20)
  IF p_days_since_last_login > 30 THEN
    risk_score := risk_score + 0.20;
  ELSIF p_days_since_last_login > 14 THEN
    risk_score := risk_score + 0.15;
  ELSIF p_days_since_last_login > 7 THEN
    risk_score := risk_score + 0.10;
  END IF;

  -- Feature usage frequency (weight: 0.25)
  IF p_feature_usage_frequency < 1 THEN
    risk_score := risk_score + 0.25;
  ELSIF p_feature_usage_frequency < 3 THEN
    risk_score := risk_score + 0.15;
  ELSIF p_feature_usage_frequency < 5 THEN
    risk_score := risk_score + 0.05;
  END IF;

  -- Support tickets (weight: 0.15)
  IF p_support_tickets > 5 THEN
    risk_score := risk_score + 0.15;
  ELSIF p_support_tickets > 2 THEN
    risk_score := risk_score + 0.10;
  END IF;

  -- Billing issues (weight: 0.20)
  IF p_billing_issues > 2 THEN
    risk_score := risk_score + 0.20;
  ELSIF p_billing_issues > 0 THEN
    risk_score := risk_score + 0.10;
  END IF;

  -- Feature adoption rate (weight: 0.10)
  IF p_feature_adoption_rate < 0.2 THEN
    risk_score := risk_score + 0.10;
  ELSIF p_feature_adoption_rate < 0.4 THEN
    risk_score := risk_score + 0.05;
  END IF;

  -- Engagement score (weight: 0.10)
  IF p_engagement_score < 20 THEN
    risk_score := risk_score + 0.10;
  ELSIF p_engagement_score < 40 THEN
    risk_score := risk_score + 0.05;
  END IF;

  RETURN LEAST(risk_score, 1.0);
END;
$$ LANGUAGE plpgsql;

-- Insert mock data for testing

-- Mock family members
INSERT INTO family_members (primary_account_id, email, relationship, status, permissions, joined_at)
SELECT 
  (SELECT id FROM auth.users LIMIT 1),
  'family.member' || generate_series || '@example.com',
  CASE (generate_series % 5)
    WHEN 0 THEN 'Spouse'
    WHEN 1 THEN 'Child'
    WHEN 2 THEN 'Parent'
    WHEN 3 THEN 'Sibling'
    ELSE 'Other'
  END,
  CASE (generate_series % 3)
    WHEN 0 THEN 'active'
    WHEN 1 THEN 'pending'
    ELSE 'active'
  END,
  jsonb_build_object(
    'full_premium_access', (generate_series % 2 = 0),
    'ad_free', TRUE,
    'priority_support', (generate_series % 3 = 0),
    'creator_tools', (generate_series % 2 = 0),
    'analytics_dashboard', TRUE,
    'api_access', (generate_series % 4 = 0)
  ),
  NOW() - (generate_series || ' days')::INTERVAL
FROM generate_series(1, 3)
ON CONFLICT DO NOTHING;

-- Mock chart preferences
INSERT INTO user_chart_preferences (user_id, chart_id, preferences)
SELECT 
  (SELECT id FROM auth.users LIMIT 1),
  'chart_' || chart_type,
  jsonb_build_object(
    'chart_type', chart_type,
    'color_scheme', color_scheme,
    'axis_config', jsonb_build_object(
      'x_axis', jsonb_build_object('label_rotation', 45, 'grid_lines', TRUE),
      'y_axis', jsonb_build_object('scale_type', 'linear', 'grid_lines', TRUE)
    ),
    'data_point_labels', TRUE,
    'legend_config', jsonb_build_object('position', 'top', 'font_size', 12)
  )
FROM (
  VALUES 
    ('line', 'default'),
    ('bar', 'colorblind_friendly'),
    ('pie', 'dark_mode')
) AS charts(chart_type, color_scheme)
ON CONFLICT DO NOTHING;

-- Mock chart anomalies
INSERT INTO chart_anomalies (chart_id, data_point_timestamp, data_point_value, z_score, anomaly_type, explanation, confidence, recommended_action)
VALUES
  ('revenue_chart', NOW() - INTERVAL '2 days', 15420.50, 3.2, 'spike', 'Unusual spike in revenue detected, 3.2 standard deviations above mean. Possible marketing campaign impact.', 0.92, 'Verify marketing campaign results and check for data quality issues'),
  ('user_engagement_chart', NOW() - INTERVAL '5 days', 234.00, -2.8, 'drop', 'Significant drop in user engagement, 2.8 standard deviations below mean. May indicate technical issues.', 0.87, 'Investigate system performance and user feedback'),
  ('api_calls_chart', NOW() - INTERVAL '1 day', 8920.00, 2.5, 'outlier', 'API call volume outlier detected. Possible bot activity or legitimate traffic surge.', 0.78, 'Review API logs and implement rate limiting if necessary')
ON CONFLICT DO NOTHING;