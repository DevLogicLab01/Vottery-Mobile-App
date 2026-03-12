-- Phase 1: High-Impact Enhancements Migration
-- Timestamp: 20260212020000
-- Description: Sponsored elections tracking, advertiser analytics, participatory ads studio, social activity timeline

-- ============================================================
-- 0. DROP EXISTING TABLES (if they exist with wrong structure)
-- ============================================================

DROP TABLE IF EXISTS public.campaign_analytics CASCADE;
DROP TABLE IF EXISTS public.audience_targeting CASCADE;
DROP TABLE IF EXISTS public.user_activity_timeline CASCADE;
DROP TABLE IF EXISTS public.sponsored_elections CASCADE;
DROP TABLE IF EXISTS public.user_demographics CASCADE;

-- ============================================================
-- 1. TYPES
-- ============================================================

DO $$ BEGIN
  CREATE TYPE public.sponsored_election_type AS ENUM (
    'market_research',
    'hype_prediction',
    'csr_vote',
    'product_feedback',
    'brand_awareness'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.sponsored_election_status AS ENUM (
    'draft',
    'active',
    'paused',
    'completed',
    'cancelled'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.purchasing_power_zone AS ENUM (
    'zone_1_us_canada',
    'zone_2_western_europe',
    'zone_3_eastern_europe_russia',
    'zone_4_africa',
    'zone_5_latin_america_caribbean',
    'zone_6_middle_east_asia',
    'zone_7_australasia_advanced_asia',
    'zone_8_china_hong_kong_macau'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.activity_type AS ENUM (
    'friend_voted',
    'election_update',
    'achievement_unlocked',
    'post_liked',
    'post_commented',
    'post_shared',
    'friend_joined',
    'milestone_reached'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 2. SPONSORED ELECTIONS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.sponsored_elections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  brand_partnership_id UUID NOT NULL REFERENCES public.brand_partnerships(id) ON DELETE CASCADE,
  brand_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  sponsored_type public.sponsored_election_type NOT NULL,
  status public.sponsored_election_status DEFAULT 'draft',
  total_budget NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  spent_budget NUMERIC(12,2) DEFAULT 0.00,
  cost_per_participant NUMERIC(8,2) NOT NULL DEFAULT 0.00,
  target_participants INTEGER DEFAULT 0,
  actual_participants INTEGER DEFAULT 0,
  zone_specific_budget JSONB DEFAULT '{}'::jsonb,
  zone_specific_participants JSONB DEFAULT '{}'::jsonb,
  engagement_metrics JSONB DEFAULT '{}'::jsonb,
  conversion_rate NUMERIC(5,2) DEFAULT 0.00,
  roi_percentage NUMERIC(8,2) DEFAULT 0.00,
  is_featured BOOLEAN DEFAULT false,
  double_xp_enabled BOOLEAN DEFAULT true,
  special_badge_id UUID REFERENCES public.achievements(id) ON DELETE SET NULL,
  paused_at TIMESTAMPTZ,
  paused_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  pause_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sponsored_elections_election ON public.sponsored_elections(election_id);
CREATE INDEX IF NOT EXISTS idx_sponsored_elections_partnership ON public.sponsored_elections(brand_partnership_id);
CREATE INDEX IF NOT EXISTS idx_sponsored_elections_brand ON public.sponsored_elections(brand_id);
CREATE INDEX IF NOT EXISTS idx_sponsored_elections_status ON public.sponsored_elections(status);
CREATE INDEX IF NOT EXISTS idx_sponsored_elections_type ON public.sponsored_elections(sponsored_type);

-- ============================================================
-- 3. CAMPAIGN ANALYTICS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.campaign_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_partnership_id UUID NOT NULL REFERENCES public.brand_partnerships(id) ON DELETE CASCADE,
  sponsored_election_id UUID REFERENCES public.sponsored_elections(id) ON DELETE CASCADE,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_impressions INTEGER DEFAULT 0,
  total_clicks INTEGER DEFAULT 0,
  total_participants INTEGER DEFAULT 0,
  cost_per_participant NUMERIC(8,2) DEFAULT 0.00,
  conversion_rate NUMERIC(5,2) DEFAULT 0.00,
  engagement_rate NUMERIC(5,2) DEFAULT 0.00,
  zone_1_reach INTEGER DEFAULT 0,
  zone_2_reach INTEGER DEFAULT 0,
  zone_3_reach INTEGER DEFAULT 0,
  zone_4_reach INTEGER DEFAULT 0,
  zone_5_reach INTEGER DEFAULT 0,
  zone_6_reach INTEGER DEFAULT 0,
  zone_7_reach INTEGER DEFAULT 0,
  zone_8_reach INTEGER DEFAULT 0,
  zone_1_conversions INTEGER DEFAULT 0,
  zone_2_conversions INTEGER DEFAULT 0,
  zone_3_conversions INTEGER DEFAULT 0,
  zone_4_conversions INTEGER DEFAULT 0,
  zone_5_conversions INTEGER DEFAULT 0,
  zone_6_conversions INTEGER DEFAULT 0,
  zone_7_conversions INTEGER DEFAULT 0,
  zone_8_conversions INTEGER DEFAULT 0,
  roi_percentage NUMERIC(8,2) DEFAULT 0.00,
  revenue_generated NUMERIC(12,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(brand_partnership_id, date)
);

CREATE INDEX IF NOT EXISTS idx_campaign_analytics_partnership ON public.campaign_analytics(brand_partnership_id);
CREATE INDEX IF NOT EXISTS idx_campaign_analytics_date ON public.campaign_analytics(date DESC);
CREATE INDEX IF NOT EXISTS idx_campaign_analytics_sponsored_election ON public.campaign_analytics(sponsored_election_id);

-- ============================================================
-- 4. AUDIENCE TARGETING TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.audience_targeting (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_partnership_id UUID NOT NULL REFERENCES public.brand_partnerships(id) ON DELETE CASCADE,
  target_zones public.purchasing_power_zone[] DEFAULT ARRAY[]::public.purchasing_power_zone[],
  target_age_min INTEGER DEFAULT 18,
  target_age_max INTEGER DEFAULT 65,
  target_interests TEXT[] DEFAULT ARRAY[]::TEXT[],
  target_countries TEXT[] DEFAULT ARRAY[]::TEXT[],
  estimated_reach INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audience_targeting_partnership ON public.audience_targeting(brand_partnership_id);

-- ============================================================
-- 5. SOCIAL ACTIVITY TIMELINE TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_activity_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  activity_type public.activity_type NOT NULL,
  activity_title TEXT NOT NULL,
  activity_description TEXT,
  reference_id UUID,
  reference_type TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_activity_timeline_user ON public.user_activity_timeline(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_timeline_actor ON public.user_activity_timeline(actor_id);
CREATE INDEX IF NOT EXISTS idx_activity_timeline_type ON public.user_activity_timeline(activity_type);
CREATE INDEX IF NOT EXISTS idx_activity_timeline_created ON public.user_activity_timeline(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_timeline_unread ON public.user_activity_timeline(user_id, is_read);

-- ============================================================
-- 6. USER DEMOGRAPHICS TABLE (for zone assignment)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_demographics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  purchasing_power_zone public.purchasing_power_zone DEFAULT 'zone_1_us_canada',
  country_code TEXT,
  age INTEGER,
  interests TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_demographics_user ON public.user_demographics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_demographics_zone ON public.user_demographics(purchasing_power_zone);

-- ============================================================
-- 7. RLS POLICIES
-- ============================================================

ALTER TABLE public.sponsored_elections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audience_targeting ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_activity_timeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_demographics ENABLE ROW LEVEL SECURITY;

-- Sponsored Elections Policies
DROP POLICY IF EXISTS "Brands can view their sponsored elections" ON public.sponsored_elections;
CREATE POLICY "Brands can view their sponsored elections"
  ON public.sponsored_elections
  FOR SELECT
  USING (auth.uid() = brand_id);

DROP POLICY IF EXISTS "Public can view active sponsored elections" ON public.sponsored_elections;
CREATE POLICY "Public can view active sponsored elections"
  ON public.sponsored_elections
  FOR SELECT
  USING (status = 'active');

-- Campaign Analytics Policies
DROP POLICY IF EXISTS "Brands can view their campaign analytics" ON public.campaign_analytics;
CREATE POLICY "Brands can view their campaign analytics"
  ON public.campaign_analytics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.brand_partnerships
      WHERE brand_partnerships.id = campaign_analytics.brand_partnership_id
      AND brand_partnerships.brand_id = auth.uid()
    )
  );

-- Audience Targeting Policies
DROP POLICY IF EXISTS "Brands can manage their audience targeting" ON public.audience_targeting;
CREATE POLICY "Brands can manage their audience targeting"
  ON public.audience_targeting
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.brand_partnerships
      WHERE brand_partnerships.id = audience_targeting.brand_partnership_id
      AND brand_partnerships.brand_id = auth.uid()
    )
  );

-- Activity Timeline Policies
DROP POLICY IF EXISTS "Users can view their own activity timeline" ON public.user_activity_timeline;
CREATE POLICY "Users can view their own activity timeline"
  ON public.user_activity_timeline
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their activity read status" ON public.user_activity_timeline;
CREATE POLICY "Users can update their activity read status"
  ON public.user_activity_timeline
  FOR UPDATE
  USING (auth.uid() = user_id);

-- User Demographics Policies
DROP POLICY IF EXISTS "Users can view their own demographics" ON public.user_demographics;
CREATE POLICY "Users can view their own demographics"
  ON public.user_demographics
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own demographics" ON public.user_demographics;
CREATE POLICY "Users can update their own demographics"
  ON public.user_demographics
  FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================================
-- 8. FUNCTIONS
-- ============================================================

-- Function to update sponsored election metrics
CREATE OR REPLACE FUNCTION public.update_sponsored_election_metrics()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only update if the election is a sponsored election
  IF EXISTS (SELECT 1 FROM public.sponsored_elections WHERE election_id = NEW.election_id) THEN
    UPDATE public.sponsored_elections
    SET 
      actual_participants = (
        SELECT COUNT(*) FROM public.votes
        WHERE votes.election_id = NEW.election_id
      ),
      spent_budget = actual_participants * cost_per_participant,
      updated_at = CURRENT_TIMESTAMP
    WHERE election_id = NEW.election_id;
  END IF;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_sponsored_election_metrics ON public.votes;
CREATE TRIGGER trigger_update_sponsored_election_metrics
AFTER INSERT ON public.votes
FOR EACH ROW
EXECUTE FUNCTION public.update_sponsored_election_metrics();

-- Function to create activity timeline entry
CREATE OR REPLACE FUNCTION public.create_activity_timeline_entry(
  p_user_id UUID,
  p_actor_id UUID,
  p_activity_type TEXT,
  p_activity_title TEXT,
  p_activity_description TEXT,
  p_reference_id UUID,
  p_reference_type TEXT,
  p_metadata JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_activity_id UUID;
BEGIN
  INSERT INTO public.user_activity_timeline (
    user_id,
    actor_id,
    activity_type,
    activity_title,
    activity_description,
    reference_id,
    reference_type,
    metadata
  ) VALUES (
    p_user_id,
    p_actor_id,
    p_activity_type::public.activity_type,
    p_activity_title,
    p_activity_description,
    p_reference_id,
    p_reference_type,
    p_metadata
  )
  RETURNING id INTO v_activity_id;
  
  RETURN v_activity_id;
END;
$$;

-- ============================================================
-- 9. MOCK DATA
-- ============================================================

DO $$
DECLARE
  brand_user_id UUID;
  creator_user_id UUID;
  election_id UUID;
  partnership_id UUID;
  sponsored_election_id UUID;
  partnership_exists BOOLEAN;
BEGIN
  -- Check if brand_partnerships table exists and has data
  SELECT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_partnerships'
  ) INTO partnership_exists;

  IF NOT partnership_exists THEN
    RAISE NOTICE 'brand_partnerships table does not exist yet. Skipping mock data insertion.';
    RETURN;
  END IF;

  -- Get first user as brand
  SELECT id INTO brand_user_id FROM public.user_profiles LIMIT 1;
  
  -- Get second user as creator
  SELECT id INTO creator_user_id FROM public.user_profiles OFFSET 1 LIMIT 1;
  
  IF brand_user_id IS NULL THEN
    RAISE NOTICE 'No users found. Skipping mock data insertion.';
    RETURN;
  END IF;

  -- Insert user demographics for brand
  INSERT INTO public.user_demographics (user_id, purchasing_power_zone, country_code, age, interests)
  VALUES (
    brand_user_id,
    'zone_1_us_canada',
    'US',
    35,
    ARRAY['technology', 'business', 'marketing']
  )
  ON CONFLICT (user_id) DO NOTHING;
  
  -- Get existing partnership
  SELECT id INTO partnership_id FROM public.brand_partnerships WHERE brand_id = brand_user_id LIMIT 1;
  
  -- Get existing election
  SELECT id INTO election_id FROM public.elections LIMIT 1;
  
  IF partnership_id IS NULL THEN
    RAISE NOTICE 'No brand partnerships found for user. Skipping sponsored election mock data.';
  ELSIF election_id IS NULL THEN
    RAISE NOTICE 'No elections found. Skipping sponsored election mock data.';
  ELSE
    -- Insert sponsored election
    INSERT INTO public.sponsored_elections (
      election_id,
      brand_partnership_id,
      brand_id,
      sponsored_type,
      status,
      total_budget,
      spent_budget,
      cost_per_participant,
      target_participants,
      actual_participants,
      zone_specific_budget,
      zone_specific_participants,
      engagement_metrics,
      conversion_rate,
      roi_percentage,
      double_xp_enabled
    ) VALUES (
      election_id,
      partnership_id,
      brand_user_id,
      'market_research',
      'active',
      50000.00,
      12500.00,
      2.50,
      20000,
      5000,
      jsonb_build_object(
        'zone_1_us_canada', 15000,
        'zone_2_western_europe', 10000,
        'zone_3_eastern_europe_russia', 5000,
        'zone_4_africa', 3000,
        'zone_5_latin_america_caribbean', 4000,
        'zone_6_middle_east_asia', 6000,
        'zone_7_australasia_advanced_asia', 5000,
        'zone_8_china_hong_kong_macau', 2000
      ),
      jsonb_build_object(
        'zone_1_us_canada', 1200,
        'zone_2_western_europe', 950,
        'zone_3_eastern_europe_russia', 780,
        'zone_4_africa', 520,
        'zone_5_latin_america_caribbean', 640,
        'zone_6_middle_east_asia', 890,
        'zone_7_australasia_advanced_asia', 720,
        'zone_8_china_hong_kong_macau', 300
      ),
      jsonb_build_object(
        'total_views', 25000,
        'total_clicks', 8500,
        'avg_time_spent_seconds', 45,
        'completion_rate', 0.68
      ),
      25.50,
      150.00,
      true
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO sponsored_election_id;
    
    -- Insert campaign analytics
    IF sponsored_election_id IS NOT NULL THEN
      INSERT INTO public.campaign_analytics (
        brand_partnership_id,
        sponsored_election_id,
        date,
        total_impressions,
        total_clicks,
        total_participants,
        cost_per_participant,
        conversion_rate,
        engagement_rate,
        zone_1_reach, zone_2_reach, zone_3_reach, zone_4_reach,
        zone_5_reach, zone_6_reach, zone_7_reach, zone_8_reach,
        zone_1_conversions, zone_2_conversions, zone_3_conversions, zone_4_conversions,
        zone_5_conversions, zone_6_conversions, zone_7_conversions, zone_8_conversions,
        roi_percentage,
        revenue_generated
      ) VALUES (
        partnership_id,
        sponsored_election_id,
        CURRENT_DATE,
        25000,
        8500,
        5000,
        2.50,
        25.50,
        34.00,
        3500, 2800, 2200, 1500, 1800, 2500, 2000, 900,
        1200, 950, 780, 520, 640, 890, 720, 300,
        150.00,
        75000.00
      )
      ON CONFLICT (brand_partnership_id, date) DO NOTHING;
    END IF;
    
    -- Insert audience targeting
    INSERT INTO public.audience_targeting (
      brand_partnership_id,
      target_zones,
      target_age_min,
      target_age_max,
      target_interests,
      target_countries,
      estimated_reach
    ) VALUES (
      partnership_id,
      ARRAY['zone_1_us_canada', 'zone_2_western_europe', 'zone_7_australasia_advanced_asia']::public.purchasing_power_zone[],
      25,
      45,
      ARRAY['technology', 'innovation', 'business', 'sustainability'],
      ARRAY['US', 'CA', 'GB', 'DE', 'FR', 'AU', 'NZ'],
      50000
    )
    ON CONFLICT DO NOTHING;
  END IF;
  
  -- Insert activity timeline entries
  IF creator_user_id IS NOT NULL AND election_id IS NOT NULL THEN
    INSERT INTO public.user_activity_timeline (
      user_id,
      actor_id,
      activity_type,
      activity_title,
      activity_description,
      reference_id,
      reference_type,
      metadata
    ) VALUES
    (
      brand_user_id,
      creator_user_id,
      'friend_voted',
      'Friend voted on Climate Action Poll',
      'Your friend Sarah voted on the Climate Action Poll',
      election_id,
      'election',
      jsonb_build_object('election_title', 'Climate Action Poll', 'friend_name', 'Sarah')
    ),
    (
      brand_user_id,
      brand_user_id,
      'achievement_unlocked',
      'Achievement Unlocked: Super Voter',
      'You have unlocked the Super Voter achievement for voting 50 times',
      NULL,
      'achievement',
      jsonb_build_object('achievement_name', 'Super Voter', 'vp_reward', 500)
    ),
    (
      brand_user_id,
      creator_user_id,
      'post_liked',
      'Friend liked your post',
      'John liked your post about sustainable living',
      NULL,
      'post',
      jsonb_build_object('post_title', 'Sustainable Living Tips', 'friend_name', 'John')
    )
    ON CONFLICT DO NOTHING;
  END IF;
  
  RAISE NOTICE 'Phase 1 mock data insertion completed successfully.';
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error during mock data insertion: %', SQLERRM;
    -- Continue execution, don't fail the migration
END;
$$;