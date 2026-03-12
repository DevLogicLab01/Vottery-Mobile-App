-- Migration: Enhanced Prediction Integration, Threat Dashboard, Feature Toggles, Private Pools, Adventure Paths
-- Timestamp: 20260227180000

-- ============================================================
-- FEATURE 1: Unified Threat Predictions Table
-- ============================================================
CREATE TABLE IF NOT EXISTS unified_threat_predictions (
  prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  threat_category VARCHAR(50) NOT NULL,
  prediction_horizon_days INTEGER NOT NULL DEFAULT 30,
  predicted_severity VARCHAR(20) NOT NULL DEFAULT 'medium',
  confidence_score DECIMAL(3,2) NOT NULL DEFAULT 0.75,
  zone_id INTEGER,
  mitigation_recommendations JSONB DEFAULT '[]'::jsonb,
  predicted_for_date DATE NOT NULL DEFAULT CURRENT_DATE,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  composite_threat_score DECIMAL(5,2) DEFAULT 0.0,
  real_time_data JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_threat_predictions_date_category
  ON unified_threat_predictions(predicted_for_date, threat_category);

CREATE INDEX IF NOT EXISTS idx_threat_predictions_zone
  ON unified_threat_predictions(zone_id, predicted_severity);

CREATE INDEX IF NOT EXISTS idx_threat_predictions_horizon
  ON unified_threat_predictions(prediction_horizon_days, confidence_score);

-- ============================================================
-- FEATURE 2: Feature Toggles Table (granular gamification toggles)
-- ============================================================
CREATE TABLE IF NOT EXISTS feature_toggles (
  toggle_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  toggle_name VARCHAR(100) NOT NULL,
  toggle_category VARCHAR(50) NOT NULL DEFAULT 'general',
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  description TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  CONSTRAINT unique_toggle_name UNIQUE (toggle_name)
);

CREATE INDEX IF NOT EXISTS idx_feature_toggles_category
  ON feature_toggles(toggle_category, is_enabled);

-- Seed default gamification toggles
INSERT INTO feature_toggles (toggle_name, toggle_category, is_enabled, description) VALUES
  -- Prediction Pools
  ('enable_prediction_pools', 'prediction_pools', true, 'Enable Prediction Pools feature'),
  ('enable_private_pools', 'prediction_pools', true, 'Enable Private Prediction Pools in groups'),
  ('enable_oracle_auto_resolution', 'prediction_pools', true, 'Enable Oracle Auto-Resolution for pools'),
  ('enable_brier_scoring', 'prediction_pools', true, 'Enable Brier Score calculation'),
  ('enable_prediction_leaderboards', 'prediction_pools', true, 'Enable Prediction Leaderboards'),
  -- Participatory Ads Gamification
  ('enable_ad_mini_games', 'participatory_ads', true, 'Enable Ad Mini-Games'),
  ('enable_spin_wheel', 'participatory_ads', true, 'Enable Spin Wheel in ads'),
  ('enable_ad_quests', 'participatory_ads', true, 'Enable Ad Quests'),
  ('enable_campaign_chains', 'participatory_ads', true, 'Enable Campaign Quest Chains'),
  ('enable_impact_meters', 'participatory_ads', true, 'Enable CSR Impact Meters'),
  -- Feed Gamification
  ('enable_feed_quests', 'feed_gamification', true, 'Enable Feed Quests'),
  ('enable_feed_progression_levels', 'feed_gamification', true, 'Enable Feed Progression Levels'),
  ('enable_feed_streaks', 'feed_gamification', true, 'Enable Feed Streaks'),
  ('enable_feed_power_ups', 'feed_gamification', true, 'Enable Feed Power-Ups'),
  ('enable_adventure_paths', 'feed_gamification', true, 'Enable Adventure Paths'),
  -- VP Redemption Categories
  ('platform_perks_redeemable', 'vp_redemption', true, 'Platform Perks Redeemable'),
  ('election_enhancements_redeemable', 'vp_redemption', true, 'Election Enhancements Redeemable'),
  ('social_rewards_redeemable', 'vp_redemption', true, 'Social Rewards Redeemable'),
  ('real_world_rewards_redeemable', 'vp_redemption', true, 'Real-World Rewards Redeemable'),
  ('vip_tiers_redeemable', 'vp_redemption', true, 'VIP Tiers Redeemable'),
  -- Quest System
  ('enable_daily_quests', 'quest_system', true, 'Enable Daily Quests'),
  ('enable_weekly_quests', 'quest_system', true, 'Enable Weekly Quests'),
  ('enable_ai_quest_generation', 'quest_system', true, 'Enable AI Quest Generation'),
  ('enable_quest_chains', 'quest_system', true, 'Enable Quest Chains')
ON CONFLICT (toggle_name) DO NOTHING;

-- Toggle audit log
CREATE TABLE IF NOT EXISTS feature_toggle_audit_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  toggle_name VARCHAR(100) NOT NULL,
  previous_state BOOLEAN,
  new_state BOOLEAN NOT NULL,
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reason TEXT
);

CREATE INDEX IF NOT EXISTS idx_toggle_audit_log_name
  ON feature_toggle_audit_log(toggle_name, changed_at DESC);

-- ============================================================
-- FEATURE 3: Election Predictions Table (for in-election prediction)
-- ============================================================
CREATE TABLE IF NOT EXISTS election_predictions (
  prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  prediction_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  brier_score DECIMAL(5,4),
  final_brier_score DECIMAL(5,4),
  vp_reward INTEGER DEFAULT 0,
  accuracy_multiplier DECIMAL(4,2) DEFAULT 1.0,
  streak_bonus DECIMAL(4,2) DEFAULT 1.0,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'partial', 'resolved')),
  CONSTRAINT unique_election_user_prediction UNIQUE (election_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_election_predictions_election
  ON election_predictions(election_id, status);

CREATE INDEX IF NOT EXISTS idx_election_predictions_user
  ON election_predictions(user_id, submitted_at DESC);

-- ============================================================
-- FEATURE 4: Private Prediction Pools in Groups
-- ============================================================
CREATE TABLE IF NOT EXISTS private_prediction_pools (
  pool_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL,
  election_id UUID NOT NULL,
  creator_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  pool_name VARCHAR(200) NOT NULL,
  vp_stake INTEGER NOT NULL DEFAULT 50 CHECK (vp_stake >= 10),
  invited_members JSONB NOT NULL DEFAULT '[]'::jsonb,
  participants JSONB NOT NULL DEFAULT '[]'::jsonb,
  pool_rules TEXT,
  pool_status VARCHAR(20) NOT NULL DEFAULT 'open'
    CHECK (pool_status IN ('open', 'closed', 'resolved')),
  prize_distribution_type VARCHAR(20) NOT NULL DEFAULT 'top_three'
    CHECK (prize_distribution_type IN ('top_three', 'winner_takes_all')),
  is_private BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_private_pools_group_status
  ON private_prediction_pools(group_id, pool_status);

CREATE INDEX IF NOT EXISTS idx_private_pools_election
  ON private_prediction_pools(election_id, pool_status);

-- Private pool participants
CREATE TABLE IF NOT EXISTS private_pool_participants (
  participant_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID NOT NULL REFERENCES private_prediction_pools(pool_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prediction_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  brier_score DECIMAL(5,4),
  vp_earned INTEGER DEFAULT 0,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_pool_participant UNIQUE (pool_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_pool_participants_pool
  ON private_pool_participants(pool_id);

CREATE INDEX IF NOT EXISTS idx_pool_participants_user
  ON private_pool_participants(user_id);

-- ============================================================
-- FEATURE 5: User Adventure Paths (AI-curated feed sections)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_adventure_paths (
  path_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  path_name VARCHAR(200) NOT NULL,
  theme_description TEXT,
  content_items JSONB NOT NULL DEFAULT '[]'::jsonb,
  progress_percentage INTEGER NOT NULL DEFAULT 0,
  status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'completed', 'skipped')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_user_paths_user_status
  ON user_adventure_paths(user_id, status);

-- Adventure path analytics
CREATE TABLE IF NOT EXISTS adventure_path_analytics (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  path_id UUID NOT NULL REFERENCES user_adventure_paths(path_id) ON DELETE CASCADE,
  completion_rate DECIMAL(5,2) DEFAULT 0.0,
  avg_time_to_complete_seconds INTEGER DEFAULT 0,
  items_completed_count INTEGER DEFAULT 0,
  total_vp_earned INTEGER DEFAULT 0,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_adventure_analytics_path
  ON adventure_path_analytics(path_id, recorded_at DESC);

-- ============================================================
-- RLS Policies
-- ============================================================
ALTER TABLE unified_threat_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_toggles ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_toggle_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE election_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE private_prediction_pools ENABLE ROW LEVEL SECURITY;
ALTER TABLE private_pool_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_adventure_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE adventure_path_analytics ENABLE ROW LEVEL SECURITY;

-- Threat predictions: admins can manage, authenticated users can read
DROP POLICY IF EXISTS "threat_predictions_read" ON unified_threat_predictions;
CREATE POLICY "threat_predictions_read" ON unified_threat_predictions
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "threat_predictions_write" ON unified_threat_predictions;
CREATE POLICY "threat_predictions_write" ON unified_threat_predictions
  FOR ALL USING (auth.role() = 'authenticated');

-- Feature toggles: authenticated users can read
DROP POLICY IF EXISTS "feature_toggles_read" ON feature_toggles;
CREATE POLICY "feature_toggles_read" ON feature_toggles
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "feature_toggles_write" ON feature_toggles;
CREATE POLICY "feature_toggles_write" ON feature_toggles
  FOR ALL USING (auth.role() = 'authenticated');

-- Toggle audit log
DROP POLICY IF EXISTS "toggle_audit_read" ON feature_toggle_audit_log;
CREATE POLICY "toggle_audit_read" ON feature_toggle_audit_log
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "toggle_audit_insert" ON feature_toggle_audit_log;
CREATE POLICY "toggle_audit_insert" ON feature_toggle_audit_log
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Election predictions: users manage own predictions
DROP POLICY IF EXISTS "election_predictions_own" ON election_predictions;
CREATE POLICY "election_predictions_own" ON election_predictions
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "election_predictions_read_all" ON election_predictions;
CREATE POLICY "election_predictions_read_all" ON election_predictions
  FOR SELECT USING (auth.role() = 'authenticated');

-- Private pools: group members can read, creators can write
DROP POLICY IF EXISTS "private_pools_read" ON private_prediction_pools;
CREATE POLICY "private_pools_read" ON private_prediction_pools
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "private_pools_write" ON private_prediction_pools;
CREATE POLICY "private_pools_write" ON private_prediction_pools
  FOR ALL USING (auth.uid() = creator_id);

-- Pool participants: own records
DROP POLICY IF EXISTS "pool_participants_own" ON private_pool_participants;
CREATE POLICY "pool_participants_own" ON private_pool_participants
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "pool_participants_read" ON private_pool_participants;
CREATE POLICY "pool_participants_read" ON private_pool_participants
  FOR SELECT USING (auth.role() = 'authenticated');

-- Adventure paths: own records
DROP POLICY IF EXISTS "adventure_paths_own" ON user_adventure_paths;
CREATE POLICY "adventure_paths_own" ON user_adventure_paths
  FOR ALL USING (auth.uid() = user_id);

-- Adventure analytics: own records
DROP POLICY IF EXISTS "adventure_analytics_own" ON adventure_path_analytics;
CREATE POLICY "adventure_analytics_own" ON adventure_path_analytics
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM user_adventure_paths
      WHERE path_id = adventure_path_analytics.path_id
        AND user_id = auth.uid()
    )
  );
