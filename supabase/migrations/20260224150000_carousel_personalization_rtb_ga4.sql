-- Carousel Personalization Engine + Real-Time Bidding + GA4 Tracking Migration
-- Created: 2026-02-24
-- Features: ML-powered personalization, RTB auctions, comprehensive GA4 event tracking

-- ============================================
-- CAROUSEL PERSONALIZATION ENGINE TABLES
-- ============================================

-- User Carousel Behavior Tracking
CREATE TABLE IF NOT EXISTS user_carousel_behavior (
  behavior_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  swipe_patterns JSONB DEFAULT '{}'::jsonb,
  engagement_patterns JSONB DEFAULT '{}'::jsonb,
  content_preferences JSONB DEFAULT '{}'::jsonb,
  device_info JSONB DEFAULT '{}'::jsonb,
  last_interaction TIMESTAMPTZ DEFAULT NOW(),
  behavior_score DECIMAL(5,2) DEFAULT 0.0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_behavior UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_behavior_user ON user_carousel_behavior(user_id);
CREATE INDEX IF NOT EXISTS idx_behavior_score ON user_carousel_behavior(behavior_score DESC);

-- User Segments
CREATE TABLE IF NOT EXISTS user_segments (
  segment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  segment_name VARCHAR(100) NOT NULL CHECK (segment_name IN ('high_engagement','content_creators','price_sensitive','early_adopters','power_users','casual_browsers')),
  segment_score DECIMAL(5,2) DEFAULT 0.0,
  segment_features JSONB DEFAULT '{}'::jsonb,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  CONSTRAINT unique_user_segment UNIQUE(user_id, segment_name)
);

CREATE INDEX IF NOT EXISTS idx_segments_user ON user_segments(user_id, assigned_at DESC);
CREATE INDEX IF NOT EXISTS idx_segments_name ON user_segments(segment_name);

-- ML Predictions
CREATE TABLE IF NOT EXISTS carousel_ml_predictions (
  prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  session_id UUID,
  input_features JSONB NOT NULL DEFAULT '{}'::jsonb,
  predicted_carousel_type VARCHAR(50) NOT NULL,
  confidence_score DECIMAL(3,2) DEFAULT 0.0,
  actual_engagement DECIMAL(5,2),
  was_accurate BOOLEAN,
  predicted_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_predictions_user ON carousel_ml_predictions(user_id, predicted_at DESC);
CREATE INDEX IF NOT EXISTS idx_predictions_accuracy ON carousel_ml_predictions(was_accurate) WHERE was_accurate IS NOT NULL;

-- Personalization A/B Tests
CREATE TABLE IF NOT EXISTS personalization_ab_tests (
  test_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_name VARCHAR(200) NOT NULL,
  model_a_version VARCHAR(50),
  model_b_version VARCHAR(50),
  users_assigned_a INTEGER DEFAULT 0,
  users_assigned_b INTEGER DEFAULT 0,
  engagement_a DECIMAL(5,2) DEFAULT 0.0,
  engagement_b DECIMAL(5,2) DEFAULT 0.0,
  conversions_a INTEGER DEFAULT 0,
  conversions_b INTEGER DEFAULT 0,
  winner VARCHAR(10),
  test_start TIMESTAMPTZ DEFAULT NOW(),
  test_end TIMESTAMPTZ,
  CONSTRAINT unique_test_name UNIQUE(test_name)
);

CREATE INDEX IF NOT EXISTS idx_ab_tests_dates ON personalization_ab_tests(test_start, test_end);

-- User Devices
CREATE TABLE IF NOT EXISTS user_devices (
  device_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  device_type VARCHAR(50),
  device_tier VARCHAR(20) CHECK (device_tier IN ('high_end','mid_range','low_end')),
  total_memory_gb DECIMAL(5,2),
  screen_width INTEGER,
  screen_height INTEGER,
  pixel_ratio DECIMAL(3,2),
  capabilities JSONB DEFAULT '{}'::jsonb,
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_device UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_devices_user ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_tier ON user_devices(device_tier);

-- ============================================
-- REAL-TIME BIDDING SYSTEM TABLES
-- ============================================

-- Carousel Ad Inventory
CREATE TABLE IF NOT EXISTS carousel_ad_inventory (
  inventory_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50) NOT NULL,
  slot_name VARCHAR(100) NOT NULL,
  estimated_daily_impressions INTEGER DEFAULT 0,
  min_bid DECIMAL(10,2) NOT NULL CHECK (min_bid >= 0),
  max_bid DECIMAL(10,2),
  avg_engagement_rate DECIMAL(5,2) DEFAULT 0.0,
  status VARCHAR(20) DEFAULT 'available' CHECK (status IN ('available','reserved','occupied')),
  CONSTRAINT unique_carousel_slot UNIQUE(carousel_type, slot_name)
);

CREATE INDEX IF NOT EXISTS idx_inventory_available ON carousel_ad_inventory(carousel_type, status);

-- Carousel Bids
CREATE TABLE IF NOT EXISTS carousel_bids (
  bid_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id UUID NOT NULL,
  advertiser_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  slot_id UUID NOT NULL REFERENCES carousel_ad_inventory(inventory_id) ON DELETE CASCADE,
  bid_amount DECIMAL(10,2) NOT NULL CHECK (bid_amount > 0),
  targeting_params JSONB DEFAULT '{}'::jsonb,
  bid_status VARCHAR(20) DEFAULT 'pending' CHECK (bid_status IN ('pending','won','lost','cancelled')),
  submitted_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bids_auction ON carousel_bids(auction_id, bid_amount DESC);
CREATE INDEX IF NOT EXISTS idx_bids_advertiser ON carousel_bids(advertiser_id, submitted_at DESC);

-- Carousel Auctions
CREATE TABLE IF NOT EXISTS carousel_auctions (
  auction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slot_id UUID NOT NULL REFERENCES carousel_ad_inventory(inventory_id) ON DELETE CASCADE,
  auction_start TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  auction_end TIMESTAMPTZ NOT NULL,
  reserve_price DECIMAL(10,2),
  winning_bid_id UUID REFERENCES carousel_bids(bid_id),
  winner_price DECIMAL(10,2),
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active','closed','cancelled')),
  CONSTRAINT valid_auction_dates CHECK (auction_end > auction_start)
);

CREATE INDEX IF NOT EXISTS idx_auctions_dates ON carousel_auctions(auction_start, auction_end);
CREATE INDEX IF NOT EXISTS idx_auctions_status ON carousel_auctions(status);

-- Advertiser Campaigns
CREATE TABLE IF NOT EXISTS advertiser_campaigns (
  campaign_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  advertiser_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  campaign_name VARCHAR(200) NOT NULL,
  total_budget DECIMAL(10,2) NOT NULL CHECK (total_budget > 0),
  daily_budget DECIMAL(10,2),
  budget_spent DECIMAL(10,2) DEFAULT 0,
  target_cpe DECIMAL(10,2),
  target_roas DECIMAL(5,2),
  auto_bidding_strategy VARCHAR(50),
  carousel_targets JSONB DEFAULT '[]'::jsonb,
  zone_targets JSONB DEFAULT '[]'::jsonb,
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('draft','active','paused','completed','cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_campaigns_advertiser ON advertiser_campaigns(advertiser_id, status);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON advertiser_campaigns(status);

-- Zone Pricing Multipliers
CREATE TABLE IF NOT EXISTS zone_pricing_multipliers (
  zone_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_name VARCHAR(100) NOT NULL UNIQUE,
  zone_number INTEGER NOT NULL CHECK (zone_number >= 1 AND zone_number <= 8),
  base_multiplier DECIMAL(4,2) NOT NULL DEFAULT 1.0,
  dynamic_multiplier DECIMAL(4,2),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_zone_number ON zone_pricing_multipliers(zone_number);

-- ============================================
-- GA4 CAROUSEL TRACKING TABLES
-- ============================================

-- GA4 Event Log
CREATE TABLE IF NOT EXISTS ga4_event_log (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  event_name VARCHAR(100) NOT NULL,
  event_parameters JSONB NOT NULL DEFAULT '{}'::jsonb,
  event_timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  synced_to_ga4 BOOLEAN DEFAULT false,
  sync_error TEXT
);

CREATE INDEX IF NOT EXISTS idx_ga4_events ON ga4_event_log(user_id, event_name, event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ga4_sync ON ga4_event_log(synced_to_ga4) WHERE synced_to_ga4 = false;

-- Carousel Attribution
CREATE TABLE IF NOT EXISTS carousel_attribution (
  attribution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  conversion_event_id UUID NOT NULL,
  attributed_carousel_type VARCHAR(50),
  attributed_content_id UUID,
  impression_timestamp TIMESTAMPTZ NOT NULL,
  conversion_timestamp TIMESTAMPTZ NOT NULL,
  attribution_model VARCHAR(50),
  contribution_percentage DECIMAL(5,2),
  CONSTRAINT valid_attribution_window CHECK (conversion_timestamp >= impression_timestamp)
);

CREATE INDEX IF NOT EXISTS idx_attribution_user ON carousel_attribution(user_id, conversion_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_attribution_model ON carousel_attribution(attribution_model);

-- Carousel Funnel Tracking
CREATE TABLE IF NOT EXISTS carousel_funnel_tracking (
  tracking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  funnel_name VARCHAR(100) NOT NULL,
  current_stage VARCHAR(50) NOT NULL,
  stage_timestamps JSONB DEFAULT '{}'::jsonb,
  completed BOOLEAN DEFAULT false,
  conversion_value DECIMAL(10,2),
  started_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_funnel_user ON carousel_funnel_tracking(user_id, funnel_name, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_funnel_completed ON carousel_funnel_tracking(completed);

-- ============================================
-- RLS POLICIES
-- ============================================

-- User Carousel Behavior
ALTER TABLE user_carousel_behavior ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own behavior"
  ON user_carousel_behavior FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert behavior"
  ON user_carousel_behavior FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update behavior"
  ON user_carousel_behavior FOR UPDATE
  USING (true);

-- User Segments
ALTER TABLE user_segments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own segments"
  ON user_segments FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage segments"
  ON user_segments FOR ALL
  USING (true);

-- ML Predictions
ALTER TABLE carousel_ml_predictions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own predictions"
  ON carousel_ml_predictions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert predictions"
  ON carousel_ml_predictions FOR INSERT
  WITH CHECK (true);

-- Personalization A/B Tests
ALTER TABLE personalization_ab_tests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view tests"
  ON personalization_ab_tests FOR SELECT
  USING (true);

CREATE POLICY "System can manage tests"
  ON personalization_ab_tests FOR ALL
  USING (true);

-- User Devices
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own devices"
  ON user_devices FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage devices"
  ON user_devices FOR ALL
  USING (true);

-- Carousel Ad Inventory
ALTER TABLE carousel_ad_inventory ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view inventory"
  ON carousel_ad_inventory FOR SELECT
  USING (true);

CREATE POLICY "System can manage inventory"
  ON carousel_ad_inventory FOR ALL
  USING (true);

-- Carousel Bids
ALTER TABLE carousel_bids ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Advertisers can view own bids"
  ON carousel_bids FOR SELECT
  USING (auth.uid() = advertiser_id);

CREATE POLICY "Advertisers can insert bids"
  ON carousel_bids FOR INSERT
  WITH CHECK (auth.uid() = advertiser_id);

-- Carousel Auctions
ALTER TABLE carousel_auctions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view auctions"
  ON carousel_auctions FOR SELECT
  USING (true);

CREATE POLICY "System can manage auctions"
  ON carousel_auctions FOR ALL
  USING (true);

-- Advertiser Campaigns
ALTER TABLE advertiser_campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Advertisers can view own campaigns"
  ON advertiser_campaigns FOR SELECT
  USING (auth.uid() = advertiser_id);

CREATE POLICY "Advertisers can manage own campaigns"
  ON advertiser_campaigns FOR ALL
  USING (auth.uid() = advertiser_id);

-- Zone Pricing Multipliers
ALTER TABLE zone_pricing_multipliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view zone pricing"
  ON zone_pricing_multipliers FOR SELECT
  USING (true);

CREATE POLICY "System can manage zone pricing"
  ON zone_pricing_multipliers FOR ALL
  USING (true);

-- GA4 Event Log
ALTER TABLE ga4_event_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own events"
  ON ga4_event_log FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert events"
  ON ga4_event_log FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update events"
  ON ga4_event_log FOR UPDATE
  USING (true);

-- Carousel Attribution
ALTER TABLE carousel_attribution ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own attribution"
  ON carousel_attribution FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage attribution"
  ON carousel_attribution FOR ALL
  USING (true);

-- Carousel Funnel Tracking
ALTER TABLE carousel_funnel_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own funnels"
  ON carousel_funnel_tracking FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can manage funnels"
  ON carousel_funnel_tracking FOR ALL
  USING (true);

-- ============================================
-- INITIAL DATA
-- ============================================

-- Insert default zone pricing multipliers
INSERT INTO zone_pricing_multipliers (zone_name, zone_number, base_multiplier) VALUES
  ('US & Canada', 1, 2.0),
  ('Western Europe', 2, 1.5),
  ('Asia', 3, 1.3),
  ('Africa', 4, 0.8),
  ('Latin America', 5, 0.9),
  ('Middle East', 6, 1.0),
  ('Eastern Europe', 7, 1.1),
  ('Oceania', 8, 1.2)
ON CONFLICT (zone_name) DO NOTHING;

-- Insert default carousel ad inventory
INSERT INTO carousel_ad_inventory (carousel_type, slot_name, estimated_daily_impressions, min_bid, avg_engagement_rate) VALUES
  ('horizontal_snap', 'featured_slot', 10000, 5.00, 12.5),
  ('horizontal_snap', 'premium_slot', 8000, 3.50, 10.2),
  ('horizontal_snap', 'standard_slot', 5000, 2.00, 8.5),
  ('vertical_stack', 'top_card', 12000, 6.00, 15.3),
  ('vertical_stack', 'middle_card', 7000, 3.00, 9.8),
  ('gradient_flow', 'trending_spot', 15000, 8.00, 18.7),
  ('gradient_flow', 'top_banner', 9000, 4.50, 11.4)
ON CONFLICT (carousel_type, slot_name) DO NOTHING;