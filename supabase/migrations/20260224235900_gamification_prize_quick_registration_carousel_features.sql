-- =====================================================
-- MIGRATION: Gamification Prize, Quick Registration, Carousel Filters, Creator Spotlights
-- Features: Multiple prize winners, third-party registration, advanced filters, creator showcase
-- =====================================================

-- FEATURE 1: Gamification Prize Configuration with Multiple Winners
-- =====================================================

-- Prize configuration table
CREATE TABLE IF NOT EXISTS gamification_prize_config (
  config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
  prize_type VARCHAR(20) NOT NULL CHECK (prize_type IN ('monetary', 'non_monetary', 'revenue_sharing')),
  
  -- Monetary prize config
  monetary_config JSONB DEFAULT NULL,
  -- Structure: {"amount": 10000, "currency": "USD", "regional_pricing": {"zone_1": 10000, "zone_2": 8500}}
  
  -- Non-monetary prize config
  non_monetary_config JSONB DEFAULT NULL,
  -- Structure: {"title": "Dubai Holiday", "description": "...", "value": 5000, "image_urls": [...]}
  
  -- Revenue sharing config
  revenue_share_config JSONB DEFAULT NULL,
  -- Structure: {"projected_revenue": 1000000, "share_percentage": 50}
  
  -- Multiple winners settings
  multiple_winners_enabled BOOLEAN DEFAULT FALSE,
  winner_count INTEGER DEFAULT 1 CHECK (winner_count >= 1 AND winner_count <= 100),
  
  -- Sequential reveal settings
  sequential_reveal_enabled BOOLEAN DEFAULT TRUE,
  reveal_delay_seconds INTEGER DEFAULT 5 CHECK (reveal_delay_seconds >= 2 AND reveal_delay_seconds <= 10),
  animation_style VARCHAR(20) DEFAULT 'dramatic' CHECK (animation_style IN ('dramatic', 'fast', 'smooth')),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prize_config_election ON gamification_prize_config(election_id);

-- Prize winner slots table
CREATE TABLE IF NOT EXISTS prize_winner_slots (
  slot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_id UUID NOT NULL REFERENCES gamification_prize_config(config_id) ON DELETE CASCADE,
  winner_rank INTEGER NOT NULL CHECK (winner_rank >= 1),
  prize_percentage DECIMAL(5,2) NOT NULL CHECK (prize_percentage > 0 AND prize_percentage <= 100),
  calculated_amount DECIMAL(12,2),
  winner_user_id UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
  drawn_at TIMESTAMPTZ,
  CONSTRAINT unique_config_rank UNIQUE (config_id, winner_rank)
);

CREATE INDEX IF NOT EXISTS idx_slots_config ON prize_winner_slots(config_id, winner_rank);
CREATE INDEX IF NOT EXISTS idx_slots_winner ON prize_winner_slots(winner_user_id);

-- FEATURE 2: Third-Party Registration Flow
-- =====================================================

-- Quick registrations table
CREATE TABLE IF NOT EXISTS quick_registrations (
  quick_reg_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  election_id UUID REFERENCES elections(id) ON DELETE SET NULL,
  registration_source VARCHAR(50),
  registered_at TIMESTAMPTZ DEFAULT NOW(),
  converted_to_full BOOLEAN DEFAULT FALSE,
  converted_at TIMESTAMPTZ,
  CONSTRAINT unique_user_election_quick_reg UNIQUE (user_id, election_id)
);

CREATE INDEX IF NOT EXISTS idx_quick_reg_user ON quick_registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_quick_reg_election ON quick_registrations(election_id);
CREATE INDEX IF NOT EXISTS idx_quick_reg_source ON quick_registrations(registration_source);

-- FEATURE 3: Advanced Carousel Filters
-- =====================================================

-- User filter preferences table
CREATE TABLE IF NOT EXISTS user_filter_preferences (
  pref_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  carousel_type VARCHAR(50) NOT NULL,
  filter_config JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- Structure: {"categories": [...], "trending_enabled": true, "price_range": {"min": 0, "max": 500}, "rating_min": 4, "date_range": {...}}
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_user_carousel_filter UNIQUE (user_id, carousel_type)
);

CREATE INDEX IF NOT EXISTS idx_filter_prefs_user ON user_filter_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_filter_prefs_carousel ON user_filter_preferences(carousel_type);

-- FEATURE 4: Creator Spotlights UI Enhancement
-- =====================================================
-- Note: creator_spotlights table already exists, we'll add missing columns

-- Add carousel_type column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'carousel_type'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN carousel_type VARCHAR(50) DEFAULT 'general' NOT NULL;
  END IF;
END $$;

-- Add slot_position column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'slot_position'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN slot_position INTEGER DEFAULT 0 NOT NULL;
  END IF;
END $$;

-- Add priority column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'priority'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN priority INTEGER DEFAULT 0;
  END IF;
END $$;

-- Add start_date column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'start_date'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN start_date TIMESTAMPTZ DEFAULT NOW();
  END IF;
END $$;

-- Add end_date column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'end_date'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN end_date TIMESTAMPTZ;
  END IF;
END $$;

-- Add is_sponsored column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'is_sponsored'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN is_sponsored BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- Add sponsor_amount column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'sponsor_amount'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN sponsor_amount DECIMAL(10,2);
  END IF;
END $$;

-- Add impression_count column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'impression_count'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN impression_count INTEGER DEFAULT 0;
  END IF;
END $$;

-- Add click_count column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'click_count'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN click_count INTEGER DEFAULT 0;
  END IF;
END $$;

-- Add follow_count column if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'creator_spotlights' 
    AND column_name = 'follow_count'
  ) THEN
    ALTER TABLE creator_spotlights ADD COLUMN follow_count INTEGER DEFAULT 0;
  END IF;
END $$;

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS idx_spotlights_carousel_active ON creator_spotlights(is_active, carousel_type, priority);
CREATE INDEX IF NOT EXISTS idx_spotlights_dates ON creator_spotlights(start_date, end_date);

-- Creator spotlight analytics table
CREATE TABLE IF NOT EXISTS creator_spotlight_analytics (
  analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  spotlight_id UUID NOT NULL REFERENCES creator_spotlights(spotlight_id) ON DELETE CASCADE,
  date DATE NOT NULL,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  follows INTEGER DEFAULT 0,
  click_through_rate DECIMAL(5,2),
  follow_conversion_rate DECIMAL(5,2),
  CONSTRAINT unique_spotlight_date UNIQUE (spotlight_id, date)
);

CREATE INDEX IF NOT EXISTS idx_spotlight_analytics ON creator_spotlight_analytics(spotlight_id, date);

-- RLS POLICIES
-- =====================================================

-- Gamification Prize Config RLS
ALTER TABLE gamification_prize_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view prize configs for elections they have access to" ON gamification_prize_config;
CREATE POLICY "Users can view prize configs for elections they have access to"
  ON gamification_prize_config FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Election creators can manage prize configs" ON gamification_prize_config;
CREATE POLICY "Election creators can manage prize configs"
  ON gamification_prize_config FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM elections
      WHERE elections.id = gamification_prize_config.election_id
      AND elections.created_by = auth.uid()
    )
  );

-- Prize Winner Slots RLS
ALTER TABLE prize_winner_slots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view winner slots" ON prize_winner_slots;
CREATE POLICY "Users can view winner slots"
  ON prize_winner_slots FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "System can manage winner slots" ON prize_winner_slots;
CREATE POLICY "System can manage winner slots"
  ON prize_winner_slots FOR ALL
  USING (true);

-- Quick Registrations RLS
ALTER TABLE quick_registrations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own quick registrations" ON quick_registrations;
CREATE POLICY "Users can view their own quick registrations"
  ON quick_registrations FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create quick registrations" ON quick_registrations;
CREATE POLICY "Users can create quick registrations"
  ON quick_registrations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own quick registrations" ON quick_registrations;
CREATE POLICY "Users can update their own quick registrations"
  ON quick_registrations FOR UPDATE
  USING (auth.uid() = user_id);

-- User Filter Preferences RLS
ALTER TABLE user_filter_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own filter preferences" ON user_filter_preferences;
CREATE POLICY "Users can manage their own filter preferences"
  ON user_filter_preferences FOR ALL
  USING (auth.uid() = user_id);

-- Creator Spotlight Analytics RLS
ALTER TABLE creator_spotlight_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view their own spotlight analytics" ON creator_spotlight_analytics;
CREATE POLICY "Creators can view their own spotlight analytics"
  ON creator_spotlight_analytics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM creator_spotlights
      WHERE creator_spotlights.spotlight_id = creator_spotlight_analytics.spotlight_id
      AND creator_spotlights.creator_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "System can insert analytics" ON creator_spotlight_analytics;
CREATE POLICY "System can insert analytics"
  ON creator_spotlight_analytics FOR INSERT
  WITH CHECK (true);

-- FUNCTIONS
-- =====================================================

-- Function to validate total prize percentage
CREATE OR REPLACE FUNCTION validate_prize_percentages(p_config_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  total_percentage DECIMAL(5,2);
BEGIN
  SELECT COALESCE(SUM(prize_percentage), 0)
  INTO total_percentage
  FROM prize_winner_slots
  WHERE config_id = p_config_id;
  
  RETURN total_percentage <= 100;
END;
$$ LANGUAGE plpgsql;

-- Function to update spotlight analytics
CREATE OR REPLACE FUNCTION update_spotlight_analytics(
  p_spotlight_id UUID,
  p_event_type VARCHAR(20)
)
RETURNS VOID AS $$
BEGIN
  -- Update spotlight counters
  IF p_event_type = 'impression' THEN
    UPDATE creator_spotlights
    SET impression_count = impression_count + 1
    WHERE spotlight_id = p_spotlight_id;
  ELSIF p_event_type = 'click' THEN
    UPDATE creator_spotlights
    SET click_count = click_count + 1
    WHERE spotlight_id = p_spotlight_id;
  ELSIF p_event_type = 'follow' THEN
    UPDATE creator_spotlights
    SET follow_count = follow_count + 1
    WHERE spotlight_id = p_spotlight_id;
  END IF;
  
  -- Update daily analytics
  INSERT INTO creator_spotlight_analytics (
    spotlight_id,
    date,
    impressions,
    clicks,
    follows
  )
  VALUES (
    p_spotlight_id,
    CURRENT_DATE,
    CASE WHEN p_event_type = 'impression' THEN 1 ELSE 0 END,
    CASE WHEN p_event_type = 'click' THEN 1 ELSE 0 END,
    CASE WHEN p_event_type = 'follow' THEN 1 ELSE 0 END
  )
  ON CONFLICT (spotlight_id, date)
  DO UPDATE SET
    impressions = creator_spotlight_analytics.impressions + EXCLUDED.impressions,
    clicks = creator_spotlight_analytics.clicks + EXCLUDED.clicks,
    follows = creator_spotlight_analytics.follows + EXCLUDED.follows,
    click_through_rate = CASE
      WHEN (creator_spotlight_analytics.impressions + EXCLUDED.impressions) > 0
      THEN ((creator_spotlight_analytics.clicks + EXCLUDED.clicks)::DECIMAL / (creator_spotlight_analytics.impressions + EXCLUDED.impressions)) * 100
      ELSE 0
    END,
    follow_conversion_rate = CASE
      WHEN (creator_spotlight_analytics.clicks + EXCLUDED.clicks) > 0
      THEN ((creator_spotlight_analytics.follows + EXCLUDED.follows)::DECIMAL / (creator_spotlight_analytics.clicks + EXCLUDED.clicks)) * 100
      ELSE 0
    END;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_prize_config_timestamp ON gamification_prize_config;
CREATE TRIGGER update_prize_config_timestamp
  BEFORE UPDATE ON gamification_prize_config
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_filter_prefs_timestamp ON user_filter_preferences;
CREATE TRIGGER update_filter_prefs_timestamp
  BEFORE UPDATE ON user_filter_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- COMMENTS
-- =====================================================

COMMENT ON TABLE gamification_prize_config IS 'Stores prize configuration for gamified elections with support for multiple winners';
COMMENT ON TABLE prize_winner_slots IS 'Defines prize distribution slots for multiple winners with percentage allocation';
COMMENT ON TABLE quick_registrations IS 'Tracks lightweight registrations from external election links';
COMMENT ON TABLE user_filter_preferences IS 'Stores user filter preferences for carousel content with cross-device sync';
COMMENT ON TABLE creator_spotlight_analytics IS 'Tracks daily analytics for creator spotlight performance';