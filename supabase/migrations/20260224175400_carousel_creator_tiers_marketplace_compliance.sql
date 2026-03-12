-- =====================================================
-- CAROUSEL CREATOR TIERS, TEMPLATE MARKETPLACE & SECURITY AUDIT
-- Migration: 20260224175400
-- =====================================================

-- =====================================================
-- FEATURE 1: CAROUSEL CREATOR TIERS
-- =====================================================

-- Carousel Creator Tiers Table
CREATE TABLE IF NOT EXISTS carousel_creator_tiers (
  tier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_name VARCHAR(50) NOT NULL CHECK (tier_name IN ('starter', 'pro', 'business', 'enterprise')),
  tier_level INTEGER NOT NULL CHECK (tier_level BETWEEN 1 AND 4),
  monthly_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  annual_price DECIMAL(10, 2),
  features JSONB NOT NULL DEFAULT '[]'::jsonb,
  benefits JSONB NOT NULL DEFAULT '[]'::jsonb,
  max_featured_placements INTEGER,
  max_templates INTEGER,
  priority_level INTEGER DEFAULT 1,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_tier_name UNIQUE (tier_name),
  CONSTRAINT unique_tier_level UNIQUE (tier_level)
);

CREATE INDEX idx_carousel_tiers_active ON carousel_creator_tiers(is_active, tier_level);

-- User Carousel Subscriptions Table
CREATE TABLE IF NOT EXISTS user_carousel_subscriptions (
  subscription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  tier_id UUID NOT NULL REFERENCES carousel_creator_tiers(tier_id),
  stripe_subscription_id VARCHAR(100) UNIQUE,
  subscription_status VARCHAR(20) DEFAULT 'active' CHECK (subscription_status IN ('active', 'canceled', 'past_due', 'trialing', 'incomplete')),
  current_period_start TIMESTAMPTZ NOT NULL,
  current_period_end TIMESTAMPTZ NOT NULL,
  cancel_at_period_end BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_carousel_subscription ON user_carousel_subscriptions(user_id, subscription_status);
CREATE INDEX IF NOT EXISTS idx_subscription_status ON user_carousel_subscriptions(subscription_status, current_period_end);

-- Carousel Feature Flags Table
CREATE TABLE IF NOT EXISTS carousel_feature_flags (
  flag_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_name VARCHAR(100) NOT NULL UNIQUE,
  feature_description TEXT,
  enabled_globally BOOLEAN DEFAULT true,
  enabled_for_tiers INTEGER[] DEFAULT ARRAY[1, 2, 3, 4],
  requires_minimum_tier INTEGER DEFAULT 1 CHECK (requires_minimum_tier BETWEEN 1 AND 4),
  created_by UUID REFERENCES user_profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_carousel_feature_flags ON carousel_feature_flags(feature_name, enabled_globally);

-- Function: Check if carousel feature is enabled for user
CREATE OR REPLACE FUNCTION is_carousel_feature_enabled(
  p_user_id UUID,
  p_feature_name VARCHAR
) RETURNS BOOLEAN AS $$
DECLARE
  v_flag RECORD;
  v_user_tier INTEGER;
BEGIN
  -- Get feature flag
  SELECT * INTO v_flag
  FROM carousel_feature_flags
  WHERE feature_name = p_feature_name;

  -- Feature doesn't exist or globally disabled
  IF NOT FOUND OR v_flag.enabled_globally = false THEN
    RETURN false;
  END IF;

  -- Get user's current tier level
  SELECT ct.tier_level INTO v_user_tier
  FROM user_carousel_subscriptions ucs
  JOIN carousel_creator_tiers ct ON ucs.tier_id = ct.tier_id
  WHERE ucs.user_id = p_user_id
    AND ucs.subscription_status = 'active'
    AND ucs.current_period_end > NOW()
  ORDER BY ct.tier_level DESC
  LIMIT 1;

  -- No active subscription (default to tier 1 - starter/free)
  IF NOT FOUND THEN
    v_user_tier := 1;
  END IF;

  -- Check if user's tier meets minimum requirement
  IF v_user_tier >= v_flag.requires_minimum_tier THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- FEATURE 2: CAROUSEL TEMPLATE MARKETPLACE
-- =====================================================

-- Carousel Templates Table
CREATE TABLE IF NOT EXISTS carousel_templates (
  template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  template_name VARCHAR(200) NOT NULL,
  template_description TEXT,
  category VARCHAR(50) CHECK (category IN ('engagement', 'conversion', 'revenue', 'viral')),
  price DECIMAL(10, 2) NOT NULL CHECK (price >= 5 AND price <= 500),
  template_data JSONB NOT NULL,
  preview_images JSONB DEFAULT '[]'::jsonb,
  sales_count INTEGER DEFAULT 0,
  average_rating DECIMAL(3, 2),
  review_count INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_templates_creator ON carousel_templates(creator_user_id, status);
CREATE INDEX IF NOT EXISTS idx_templates_category ON carousel_templates(category, status);
CREATE INDEX IF NOT EXISTS idx_templates_sales ON carousel_templates(sales_count DESC);

-- Template Purchases Table
CREATE TABLE IF NOT EXISTS template_purchases (
  purchase_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES carousel_templates(template_id) ON DELETE CASCADE,
  buyer_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  purchase_amount DECIMAL(10, 2) NOT NULL,
  stripe_payment_intent_id VARCHAR(100),
  purchase_status VARCHAR(20) DEFAULT 'completed' CHECK (purchase_status IN ('pending', 'completed', 'refunded')),
  purchased_at TIMESTAMPTZ DEFAULT NOW(),
  refunded_at TIMESTAMPTZ,
  CONSTRAINT unique_buyer_template UNIQUE (buyer_user_id, template_id)
);

CREATE INDEX IF NOT EXISTS idx_purchases_buyer ON template_purchases(buyer_user_id, purchased_at DESC);
CREATE INDEX IF NOT EXISTS idx_purchases_template ON template_purchases(template_id, purchase_status);

-- Template Revenue Splits Table
CREATE TABLE IF NOT EXISTS template_revenue_splits (
  split_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id UUID NOT NULL REFERENCES template_purchases(purchase_id) ON DELETE CASCADE,
  creator_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  gross_amount DECIMAL(10, 2) NOT NULL,
  creator_amount DECIMAL(10, 2) NOT NULL,
  platform_fee DECIMAL(10, 2) NOT NULL,
  split_percentage DECIMAL(5, 2) DEFAULT 70.00,
  payout_status VARCHAR(20) DEFAULT 'pending' CHECK (payout_status IN ('pending', 'paid', 'failed')),
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_splits_creator ON template_revenue_splits(creator_user_id, payout_status);
CREATE INDEX IF NOT EXISTS idx_splits_purchase ON template_revenue_splits(purchase_id);

-- Template Reviews Table
CREATE TABLE IF NOT EXISTS template_reviews (
  review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  template_id UUID NOT NULL REFERENCES carousel_templates(template_id) ON DELETE CASCADE,
  buyer_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  helpful_votes INTEGER DEFAULT 0,
  reviewed_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_buyer_review UNIQUE (template_id, buyer_user_id)
);

CREATE INDEX IF NOT EXISTS idx_reviews_template ON template_reviews(template_id, reviewed_at DESC);

-- Function: Calculate template revenue split (70% creator / 30% platform)
CREATE OR REPLACE FUNCTION calculate_template_revenue_split(
  p_purchase_id UUID,
  p_gross_amount DECIMAL
) RETURNS VOID AS $$
DECLARE
  v_creator_id UUID;
  v_creator_percentage DECIMAL := 70.00;
  v_platform_percentage DECIMAL := 30.00;
  v_creator_amount DECIMAL;
  v_platform_fee DECIMAL;
BEGIN
  -- Get creator ID from template
  SELECT ct.creator_user_id INTO v_creator_id
  FROM template_purchases tp
  JOIN carousel_templates ct ON tp.template_id = ct.template_id
  WHERE tp.purchase_id = p_purchase_id;

  -- Calculate split amounts
  v_creator_amount := ROUND(p_gross_amount * (v_creator_percentage / 100), 2);
  v_platform_fee := ROUND(p_gross_amount * (v_platform_percentage / 100), 2);

  -- Insert revenue split record
  INSERT INTO template_revenue_splits (
    purchase_id,
    creator_user_id,
    gross_amount,
    creator_amount,
    platform_fee,
    split_percentage,
    payout_status
  ) VALUES (
    p_purchase_id,
    v_creator_id,
    p_gross_amount,
    v_creator_amount,
    v_platform_fee,
    v_creator_percentage,
    'pending'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Auto-calculate revenue split on purchase
CREATE OR REPLACE FUNCTION trigger_calculate_template_split()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.purchase_status = 'completed' THEN
    PERFORM calculate_template_revenue_split(NEW.purchase_id, NEW.purchase_amount);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER template_purchase_split_trigger
AFTER INSERT OR UPDATE OF purchase_status ON template_purchases
FOR EACH ROW
EXECUTE FUNCTION trigger_calculate_template_split();

-- =====================================================
-- FEATURE 3: CAROUSEL SECURITY AUDIT
-- =====================================================

-- Carousel Compliance Policies Table
CREATE TABLE IF NOT EXISTS carousel_compliance_policies (
  policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_name VARCHAR(100) NOT NULL UNIQUE,
  policy_category VARCHAR(50) NOT NULL CHECK (policy_category IN ('data_privacy', 'content_policy', 'financial_compliance', 'ai_ethics', 'accessibility')),
  description TEXT NOT NULL,
  requirements JSONB NOT NULL DEFAULT '{}'::jsonb,
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_compliance_policies ON carousel_compliance_policies(policy_category, is_active);

-- Carousel Compliance Violations Table
CREATE TABLE IF NOT EXISTS carousel_compliance_violations (
  violation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  policy_id UUID REFERENCES carousel_compliance_policies(policy_id),
  system_name VARCHAR(100) NOT NULL,
  violation_type VARCHAR(100) NOT NULL,
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  description TEXT NOT NULL,
  evidence JSONB DEFAULT '{}'::jsonb,
  detection_method VARCHAR(50) CHECK (detection_method IN ('automated', 'manual')),
  detected_by UUID REFERENCES user_profiles(id),
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'remediated', 'dismissed', 'false_positive')),
  remediated_at TIMESTAMPTZ,
  remediation_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_violations_status ON carousel_compliance_violations(status, severity, detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_violations_system ON carousel_compliance_violations(system_name, status);

-- Carousel Compliance Scores Table
CREATE TABLE IF NOT EXISTS carousel_compliance_scores (
  score_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  system_name VARCHAR(100) NOT NULL,
  compliance_score INTEGER NOT NULL CHECK (compliance_score BETWEEN 0 AND 100),
  policy_adherence_rate DECIMAL(5, 2),
  violation_count INTEGER DEFAULT 0,
  risk_level VARCHAR(20) NOT NULL CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_carousel_compliance_scores_system ON carousel_compliance_scores(system_name, calculated_at DESC);

-- Carousel Remediation Actions Table
CREATE TABLE IF NOT EXISTS carousel_remediation_actions (
  action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  violation_id UUID NOT NULL REFERENCES carousel_compliance_violations(violation_id) ON DELETE CASCADE,
  action_type VARCHAR(100) NOT NULL,
  action_description TEXT,
  automated BOOLEAN DEFAULT false,
  executed_by UUID REFERENCES user_profiles(id),
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  result VARCHAR(20) CHECK (result IN ('success', 'failed', 'partial')),
  result_details TEXT
);

CREATE INDEX IF NOT EXISTS idx_carousel_remediation_actions_violation ON carousel_remediation_actions(violation_id, executed_at DESC);

-- Function: Calculate compliance score for system
CREATE OR REPLACE FUNCTION calculate_carousel_compliance_score(
  p_system_name VARCHAR
) RETURNS INTEGER AS $$
DECLARE
  v_total_violations INTEGER;
  v_critical_violations INTEGER;
  v_high_violations INTEGER;
  v_score INTEGER;
BEGIN
  -- Count violations by severity
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE severity = 'critical'),
    COUNT(*) FILTER (WHERE severity = 'high')
  INTO v_total_violations, v_critical_violations, v_high_violations
  FROM carousel_compliance_violations
  WHERE system_name = p_system_name
    AND status IN ('open', 'investigating');

  -- Calculate score: 100 - (critical * 20) - (high * 10) - (others * 5)
  v_score := 100 - (v_critical_violations * 20) - (v_high_violations * 10) - ((v_total_violations - v_critical_violations - v_high_violations) * 5);
  
  -- Clamp between 0 and 100
  v_score := GREATEST(0, LEAST(100, v_score));

  RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE carousel_creator_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_carousel_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE template_purchases ENABLE ROW LEVEL SECURITY;
ALTER TABLE template_revenue_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE template_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_compliance_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_compliance_violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_compliance_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_remediation_actions ENABLE ROW LEVEL SECURITY;

-- Carousel Creator Tiers: Public read, admin write
CREATE POLICY "Tiers are viewable by everyone" ON carousel_creator_tiers FOR SELECT USING (true);
CREATE POLICY "Tiers are manageable by admins" ON carousel_creator_tiers FOR ALL USING (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);

-- User Subscriptions: Users see own, admins see all
CREATE POLICY "Users can view own subscriptions" ON user_carousel_subscriptions FOR SELECT USING (
  auth.uid() = user_id OR
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users can manage own subscriptions" ON user_carousel_subscriptions FOR ALL USING (auth.uid() = user_id);

-- Feature Flags: Public read, admin write
CREATE POLICY "Feature flags viewable by all" ON carousel_feature_flags FOR SELECT USING (true);
CREATE POLICY "Feature flags manageable by admins" ON carousel_feature_flags FOR ALL USING (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Templates: Public read approved, creators manage own
CREATE POLICY "Approved templates viewable by all" ON carousel_templates FOR SELECT USING (
  status = 'approved' OR creator_user_id = auth.uid() OR
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Creators can manage own templates" ON carousel_templates FOR ALL USING (auth.uid() = creator_user_id);

-- Purchases: Buyers and creators see relevant purchases
CREATE POLICY "Users see own purchases" ON template_purchases FOR SELECT USING (
  auth.uid() = buyer_user_id OR
  EXISTS (SELECT 1 FROM carousel_templates WHERE template_id = template_purchases.template_id AND creator_user_id = auth.uid()) OR
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Users can create purchases" ON template_purchases FOR INSERT WITH CHECK (auth.uid() = buyer_user_id);

-- Revenue Splits: Creators see own splits, admins see all
CREATE POLICY "Creators see own revenue splits" ON template_revenue_splits FOR SELECT USING (
  auth.uid() = creator_user_id OR
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Reviews: Public read, buyers write
CREATE POLICY "Reviews viewable by all" ON template_reviews FOR SELECT USING (true);
CREATE POLICY "Buyers can write reviews" ON template_reviews FOR INSERT WITH CHECK (
  auth.uid() = buyer_user_id AND
  EXISTS (SELECT 1 FROM template_purchases WHERE template_id = template_reviews.template_id AND buyer_user_id = auth.uid() AND purchase_status = 'completed')
);

-- Compliance: Admin only
CREATE POLICY "Compliance policies admin only" ON carousel_compliance_policies FOR ALL USING (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Compliance violations admin only" ON carousel_compliance_violations FOR ALL USING (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Compliance scores admin only" ON carousel_compliance_scores FOR ALL USING (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);
CREATE POLICY "Remediation actions admin only" ON carousel_remediation_actions FOR ALL USING (
  EXISTS (SELECT 1 FROM user_profiles WHERE id = auth.uid() AND role = 'admin')
);

-- =====================================================
-- SEED DATA
-- =====================================================

-- Insert default tiers
INSERT INTO carousel_creator_tiers (tier_name, tier_level, monthly_price, annual_price, features, benefits, max_featured_placements, max_templates, priority_level)
VALUES
  ('starter', 1, 0, 0, 
   '["basic_carousel_access", "standard_analytics"]'::jsonb,
   '["2 featured placements per month", "Max 10 templates"]'::jsonb,
   2, 10, 1),
  ('pro', 2, 29, 290,
   '["priority_sponsorship", "advanced_analytics", "premium_support"]'::jsonb,
   '["10 featured placements per month", "Max 50 templates", "Advanced personalization controls"]'::jsonb,
   10, 50, 2),
  ('business', 3, 99, 990,
   '["vip_sponsorship_priority", "enterprise_analytics", "custom_branding", "dedicated_account_manager"]'::jsonb,
   '["Unlimited featured placements", "Max 200 templates", "Exclusive creator tools", "A/B testing framework"]'::jsonb,
   999999, 200, 3),
  ('enterprise', 4, 299, 2990,
   '["exclusive_sponsorship_channels", "white_label_analytics", "api_access", "custom_integrations", "priority_development"]'::jsonb,
   '["Unlimited everything", "Custom workflows", "ML-powered recommendations", "Bulk operations"]'::jsonb,
   999999, 999999, 4)
ON CONFLICT (tier_name) DO NOTHING;

-- Insert default feature flags
INSERT INTO carousel_feature_flags (feature_name, feature_description, enabled_globally, enabled_for_tiers, requires_minimum_tier)
VALUES
  ('vip_sponsorship_priority', 'VIP sponsorship priority in bidding auctions', true, ARRAY[3, 4], 3),
  ('premium_analytics', 'Advanced metrics, funnel analysis, cohort segmentation', true, ARRAY[2, 3, 4], 2),
  ('exclusive_creator_tools', 'ML-powered recommendations, bulk operations, A/B testing', true, ARRAY[3, 4], 3),
  ('advanced_personalization', 'Custom carousel sequencing, advanced filtering, dynamic pricing', true, ARRAY[2, 3, 4], 2)
ON CONFLICT (feature_name) DO NOTHING;

-- Insert default compliance policies
INSERT INTO carousel_compliance_policies (policy_name, policy_category, description, requirements, severity)
VALUES
  ('GDPR Compliance', 'data_privacy', 'User consent and data deletion requirements', '{"user_consent": true, "data_deletion": true}'::jsonb, 'critical'),
  ('Content Policy', 'content_policy', 'Hate speech, violence, copyright infringement prevention', '{"hate_speech": false, "violence": false, "copyright": true}'::jsonb, 'high'),
  ('PCI-DSS Compliance', 'financial_compliance', 'Payment card industry data security standards', '{"encryption": true, "secure_transmission": true}'::jsonb, 'critical'),
  ('AI Ethics', 'ai_ethics', 'Transparency, explainability, bias prevention', '{"transparency": true, "bias_prevention": true}'::jsonb, 'high'),
  ('WCAG Accessibility', 'accessibility', 'Web Content Accessibility Guidelines compliance', '{"wcag_level": "AA"}'::jsonb, 'medium')
ON CONFLICT (policy_name) DO NOTHING;