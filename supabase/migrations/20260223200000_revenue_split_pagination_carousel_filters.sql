-- =====================================================
-- FEATURE 1: REVENUE SPLIT ADMIN CONTROLS
-- Complete admin management system for creator revenue splits
-- =====================================================

-- Revenue Split Configuration Table (Global Splits)
CREATE TABLE IF NOT EXISTS revenue_split_config (
  config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  split_type VARCHAR(50) NOT NULL DEFAULT 'global',
  creator_percentage INTEGER NOT NULL CHECK (creator_percentage BETWEEN 50 AND 90),
  platform_percentage INTEGER NOT NULL CHECK (platform_percentage BETWEEN 10 AND 50),
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  reason TEXT,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT split_totals_100 CHECK (creator_percentage + platform_percentage = 100)
);

-- Revenue Split Campaigns Table (Campaign-Based Overrides)
CREATE TABLE IF NOT EXISTS revenue_split_campaigns (
  campaign_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_name VARCHAR(200) NOT NULL,
  campaign_description TEXT,
  campaign_type VARCHAR(50) NOT NULL CHECK (campaign_type IN ('temporary', 'permanent')),
  creator_split_percentage INTEGER NOT NULL CHECK (creator_split_percentage BETWEEN 50 AND 95),
  eligibility_criteria JSONB NOT NULL DEFAULT '{}'::jsonb,
  start_date DATE NOT NULL,
  end_date DATE,
  auto_end_conditions JSONB,
  status VARCHAR(50) NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'active', 'paused', 'ended')),
  enrolled_creator_count INTEGER DEFAULT 0,
  total_extra_paid DECIMAL(10,2) DEFAULT 0.00,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ
);

-- Campaign Enrollments Table
CREATE TABLE IF NOT EXISTS campaign_enrollments (
  enrollment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES revenue_split_campaigns(campaign_id) ON DELETE CASCADE,
  creator_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  total_earned DECIMAL(10,2) DEFAULT 0.00,
  extra_earned DECIMAL(10,2) DEFAULT 0.00,
  is_active BOOLEAN DEFAULT true,
  UNIQUE(campaign_id, creator_user_id)
);

-- Transaction Split Log Table
CREATE TABLE IF NOT EXISTS transaction_split_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL,
  transaction_type VARCHAR(50) NOT NULL CHECK (transaction_type IN ('election', 'marketplace', 'ad')),
  creator_user_id UUID REFERENCES auth.users(id),
  split_config_id UUID REFERENCES revenue_split_config(config_id),
  campaign_id UUID REFERENCES revenue_split_campaigns(campaign_id),
  transaction_amount DECIMAL(10,2) NOT NULL,
  creator_amount DECIMAL(10,2) NOT NULL,
  platform_amount DECIMAL(10,2) NOT NULL,
  creator_percentage INTEGER NOT NULL,
  applied_at TIMESTAMPTZ DEFAULT NOW()
);

-- Split Audit Log Table
CREATE TABLE IF NOT EXISTS split_audit_log (
  audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action_type VARCHAR(100) NOT NULL CHECK (action_type IN ('config_change', 'campaign_create', 'campaign_modify', 'campaign_end')),
  action_by UUID REFERENCES auth.users(id),
  action_details JSONB NOT NULL DEFAULT '{}'::jsonb,
  affected_creators_count INTEGER DEFAULT 0,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for Revenue Split Features (FIXED: Added IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_split_config_active ON revenue_split_config(is_active, effective_date DESC);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON revenue_split_campaigns(status, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_campaigns_dates ON revenue_split_campaigns(start_date, end_date) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_enrollments_creator ON campaign_enrollments(creator_user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_transaction_log_creator ON transaction_split_log(creator_user_id, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON split_audit_log(timestamp DESC);

-- =====================================================
-- FEATURE 2: CURSOR-BASED PAGINATION
-- High-performance pagination for large datasets
-- =====================================================

-- Pagination Metadata Table
CREATE TABLE IF NOT EXISTS pagination_metadata (
  metadata_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_type VARCHAR(50) NOT NULL UNIQUE CHECK (content_type IN ('jolts', 'moments', 'groups', 'elections', 'posts')),
  total_count INTEGER DEFAULT 0,
  avg_page_size INTEGER DEFAULT 20,
  last_updated TIMESTAMPTZ DEFAULT NOW()
);

-- Pagination Analytics Table
CREATE TABLE IF NOT EXISTS pagination_analytics (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  content_type VARCHAR(50) NOT NULL,
  page_load_time_ms INTEGER,
  cache_hit BOOLEAN DEFAULT false,
  scroll_depth_percent INTEGER,
  session_id UUID,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Composite indexes for cursor pagination (created_at DESC, id DESC)
CREATE INDEX IF NOT EXISTS idx_jolts_pagination ON carousel_content_jolts(created_at DESC, jolt_id DESC);
CREATE INDEX IF NOT EXISTS idx_moments_pagination ON carousel_content_moments(created_at DESC, moment_id DESC);
CREATE INDEX IF NOT EXISTS idx_posts_pagination ON social_posts(created_at DESC, id DESC) WHERE status = 'published';

-- Index for pagination analytics (FIXED: Added IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_pagination_analytics_user ON pagination_analytics(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_pagination_analytics_content ON pagination_analytics(content_type, recorded_at DESC);

-- =====================================================
-- FEATURE 3: CAROUSEL FILTERS FOR CONTENT DISCOVERY
-- Comprehensive filtering system with analytics
-- =====================================================

-- Add category column to carousel tables if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'carousel_content_jolts' AND column_name = 'category') THEN
    ALTER TABLE carousel_content_jolts ADD COLUMN category VARCHAR(100) DEFAULT 'general';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'carousel_content_moments' AND column_name = 'category') THEN
    ALTER TABLE carousel_content_moments ADD COLUMN category VARCHAR(100) DEFAULT 'general';
  END IF;
END $$;

-- User Filter Presets Table
CREATE TABLE IF NOT EXISTS user_filter_presets (
  preset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  preset_name VARCHAR(100) NOT NULL,
  content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('jolts', 'moments', 'groups', 'elections', 'posts', 'marketplace')),
  filter_config JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_default BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, preset_name, content_type)
);

-- Filter Analytics Table
CREATE TABLE IF NOT EXISTS filter_analytics (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  content_type VARCHAR(50) NOT NULL,
  filter_applied JSONB NOT NULL DEFAULT '{}'::jsonb,
  results_count INTEGER DEFAULT 0,
  engagement_time_seconds INTEGER,
  action_taken VARCHAR(50),
  session_id UUID,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for filter queries (now that category column exists)
CREATE INDEX IF NOT EXISTS idx_jolts_category ON carousel_content_jolts(category) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_jolts_trending ON carousel_content_jolts(trending_score) WHERE trending_score > 80;
CREATE INDEX IF NOT EXISTS idx_moments_category ON carousel_content_moments(category) WHERE is_active = true;

-- Indexes for filter analytics (FIXED: Added IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_filter_analytics_user ON filter_analytics(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_filter_analytics_content ON filter_analytics(content_type, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_presets_user ON user_filter_presets(user_id, content_type);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Revenue Split Config Policies (Admin Only)
ALTER TABLE revenue_split_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Super admins can view split configs" ON revenue_split_config;
CREATE POLICY "Super admins can view split configs"
  ON revenue_split_config FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('super_admin', 'admin')
    )
  );

DROP POLICY IF EXISTS "Super admins can insert split configs" ON revenue_split_config;
CREATE POLICY "Super admins can insert split configs"
  ON revenue_split_config FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'super_admin'
    )
  );

DROP POLICY IF EXISTS "Super admins can update split configs" ON revenue_split_config;
CREATE POLICY "Super admins can update split configs"
  ON revenue_split_config FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'super_admin'
    )
  );

-- Revenue Split Campaigns Policies (Admin Only)
ALTER TABLE revenue_split_campaigns ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view campaigns" ON revenue_split_campaigns;
CREATE POLICY "Admins can view campaigns"
  ON revenue_split_campaigns FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('super_admin', 'admin')
    )
  );

DROP POLICY IF EXISTS "Admins can manage campaigns" ON revenue_split_campaigns;
CREATE POLICY "Admins can manage campaigns"
  ON revenue_split_campaigns FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('super_admin', 'admin')
    )
  );

-- Campaign Enrollments Policies (Creators can view their own)
ALTER TABLE campaign_enrollments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their enrollments" ON campaign_enrollments;
CREATE POLICY "Users can view their enrollments"
  ON campaign_enrollments FOR SELECT
  USING (creator_user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all enrollments" ON campaign_enrollments;
CREATE POLICY "Admins can view all enrollments"
  ON campaign_enrollments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('super_admin', 'admin')
    )
  );

-- Transaction Split Log Policies
ALTER TABLE transaction_split_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their transaction logs" ON transaction_split_log;
CREATE POLICY "Users can view their transaction logs"
  ON transaction_split_log FOR SELECT
  USING (creator_user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all transaction logs" ON transaction_split_log;
CREATE POLICY "Admins can view all transaction logs"
  ON transaction_split_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('super_admin', 'admin')
    )
  );

-- Split Audit Log Policies (Admin Only)
ALTER TABLE split_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view audit logs" ON split_audit_log;
CREATE POLICY "Admins can view audit logs"
  ON split_audit_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('super_admin', 'admin')
    )
  );

-- Pagination Metadata Policies (Public Read)
ALTER TABLE pagination_metadata ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view pagination metadata" ON pagination_metadata;
CREATE POLICY "Anyone can view pagination metadata"
  ON pagination_metadata FOR SELECT
  USING (true);

-- Pagination Analytics Policies (User-Scoped)
ALTER TABLE pagination_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert their own analytics" ON pagination_analytics;
CREATE POLICY "Users can insert their own analytics"
  ON pagination_analytics FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- User Filter Presets Policies (User-Scoped)
ALTER TABLE user_filter_presets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their filter presets" ON user_filter_presets;
CREATE POLICY "Users can manage their filter presets"
  ON user_filter_presets FOR ALL
  USING (user_id = auth.uid());

-- Filter Analytics Policies (User-Scoped)
ALTER TABLE filter_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert their filter analytics" ON filter_analytics;
CREATE POLICY "Users can insert their filter analytics"
  ON filter_analytics FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- =====================================================
-- MOCK DATA
-- =====================================================

-- Insert initial global split configuration
INSERT INTO revenue_split_config (split_type, creator_percentage, platform_percentage, effective_date, reason, is_active)
VALUES 
  ('global', 70, 30, CURRENT_DATE, 'Standard platform rate', true)
ON CONFLICT DO NOTHING;

-- Insert sample revenue split campaigns
INSERT INTO revenue_split_campaigns (
  campaign_name, 
  campaign_description, 
  campaign_type, 
  creator_split_percentage, 
  eligibility_criteria, 
  start_date, 
  end_date, 
  status
)
VALUES 
  (
    'Gold Tier Bonus',
    'Enhanced split for Gold tier creators',
    'permanent',
    85,
    '{"tier": ["gold", "platinum", "elite"], "category": ["all"], "min_earnings": 1000}'::jsonb,
    CURRENT_DATE,
    NULL,
    'active'
  ),
  (
    'Entertainment Category Boost',
    'Temporary boost for entertainment content',
    'temporary',
    80,
    '{"tier": ["all"], "category": ["entertainment"], "min_earnings": 0}'::jsonb,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '30 days',
    'active'
  ),
  (
    'New Creator Incentive',
    'Welcome bonus for new creators',
    'temporary',
    75,
    '{"tier": ["bronze", "silver"], "category": ["all"], "min_earnings": 0}'::jsonb,
    CURRENT_DATE - INTERVAL '7 days',
    CURRENT_DATE + INTERVAL '23 days',
    'active'
  )
ON CONFLICT DO NOTHING;

-- Insert pagination metadata
INSERT INTO pagination_metadata (content_type, total_count, avg_page_size)
VALUES 
  ('jolts', 0, 20),
  ('moments', 0, 20),
  ('groups', 0, 20),
  ('elections', 0, 20),
  ('posts', 0, 20)
ON CONFLICT (content_type) DO NOTHING;

-- Insert sample filter presets (will be user-specific in production)
-- These are examples of common filter configurations

COMMIT;