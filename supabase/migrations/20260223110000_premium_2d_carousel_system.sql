-- Premium 2D Carousel System Migration
-- Implements database schema for 6 carousel content types

-- ============================================
-- CAROUSEL TYPE 1: HORIZONTAL SNAP CAROUSEL
-- ============================================

-- Table: Jolts (Short-form Videos)
CREATE TABLE IF NOT EXISTS public.carousel_content_jolts (
  jolt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  video_url VARCHAR(500) NOT NULL,
  thumbnail_url VARCHAR(500) NOT NULL,
  title VARCHAR(200) NOT NULL,
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0 AND duration_seconds <= 180),
  views_count INTEGER DEFAULT 0,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  shares_count INTEGER DEFAULT 0,
  hashtags VARCHAR[] DEFAULT '{}',
  trending_score DECIMAL(5,2) DEFAULT 0.0 CHECK (trending_score >= 0 AND trending_score <= 100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_jolts_creator ON public.carousel_content_jolts(creator_id);
CREATE INDEX IF NOT EXISTS idx_jolts_trending ON public.carousel_content_jolts(trending_score DESC) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_jolts_created ON public.carousel_content_jolts(created_at DESC);

-- Table: Live Moments (24-hour Stories)
CREATE TABLE IF NOT EXISTS public.carousel_content_moments (
  moment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  frames JSONB NOT NULL DEFAULT '[]', -- Array of moment frames with URLs
  first_frame_url VARCHAR(500) NOT NULL,
  moments_count INTEGER DEFAULT 1 CHECK (moments_count > 0),
  engagement_count INTEGER DEFAULT 0,
  has_poll BOOLEAN DEFAULT false,
  has_vote BOOLEAN DEFAULT false,
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_moments_creator ON public.carousel_content_moments(creator_id);
CREATE INDEX IF NOT EXISTS idx_moments_active ON public.carousel_content_moments(expires_at DESC) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_moments_created ON public.carousel_content_moments(created_at DESC);

-- Table: Moment Views (Track user viewing status)
CREATE TABLE IF NOT EXISTS public.carousel_moment_views (
  view_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID REFERENCES public.carousel_content_moments(moment_id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(moment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_moment_views_user ON public.carousel_moment_views(user_id);
CREATE INDEX IF NOT EXISTS idx_moment_views_moment ON public.carousel_moment_views(moment_id);

-- Table: Featured Elections Carousel
CREATE TABLE IF NOT EXISTS public.carousel_featured_elections (
  featured_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL, -- References elections table
  featured_reason VARCHAR(200),
  display_priority INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  featured_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_featured_elections_priority ON public.carousel_featured_elections(display_priority DESC) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_featured_elections_active ON public.carousel_featured_elections(featured_at DESC) WHERE is_active = true;

-- ============================================
-- CAROUSEL TYPE 2: VERTICAL CARD STACK
-- ============================================

-- Table: Recommended Groups
CREATE TABLE IF NOT EXISTS public.carousel_content_groups (
  group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  cover_image_url VARCHAR(500),
  member_count INTEGER DEFAULT 0,
  active_elections_count INTEGER DEFAULT 0,
  category VARCHAR(50),
  privacy VARCHAR(20) DEFAULT 'public' CHECK (privacy IN ('public', 'private', 'secret')),
  is_trending BOOLEAN DEFAULT false,
  recent_activity VARCHAR(100),
  top_topics VARCHAR[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_groups_trending ON public.carousel_content_groups(is_trending DESC, member_count DESC) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_groups_category ON public.carousel_content_groups(category);
CREATE INDEX IF NOT EXISTS idx_groups_created ON public.carousel_content_groups(created_at DESC);

-- Table: Group Mutual Members (for personalization)
CREATE TABLE IF NOT EXISTS public.carousel_group_mutual_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES public.carousel_content_groups(group_id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  mutual_count INTEGER DEFAULT 0,
  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_group_mutual_user ON public.carousel_group_mutual_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_mutual_group ON public.carousel_group_mutual_members(group_id);

-- Table: Recommended Elections (Personalized)
CREATE TABLE IF NOT EXISTS public.carousel_content_elections_recommended (
  recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL, -- References elections table
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  match_score DECIMAL(5,2) DEFAULT 0.0 CHECK (match_score >= 0 AND match_score <= 100),
  recommended_reason TEXT,
  is_active BOOLEAN DEFAULT true,
  recommended_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '7 days'
);

CREATE INDEX IF NOT EXISTS idx_recommended_elections_user ON public.carousel_content_elections_recommended(user_id, match_score DESC) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_recommended_elections_score ON public.carousel_content_elections_recommended(match_score DESC);
CREATE INDEX IF NOT EXISTS idx_recommended_elections_active ON public.carousel_content_elections_recommended(recommended_at DESC) WHERE is_active = true;

-- ============================================
-- CAROUSEL TYPE 3: GRADIENT FLOW CAROUSEL
-- ============================================

-- Table: Trending Topics/Hashtags
CREATE TABLE IF NOT EXISTS public.carousel_content_trending_topics (
  topic_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hashtag VARCHAR(100) NOT NULL UNIQUE,
  trend_score DECIMAL(5,2) DEFAULT 0.0 CHECK (trend_score >= 0 AND trend_score <= 100),
  total_posts INTEGER DEFAULT 0,
  growth_rate VARCHAR(20), -- e.g., "+342%"
  top_election_id UUID, -- References elections table
  related_topics VARCHAR[] DEFAULT '{}',
  time_period VARCHAR(50) DEFAULT 'Last 24 hours',
  trending_since TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trending_topics_score ON public.carousel_content_trending_topics(trend_score DESC) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_trending_topics_hashtag ON public.carousel_content_trending_topics(hashtag);
CREATE INDEX IF NOT EXISTS idx_trending_topics_updated ON public.carousel_content_trending_topics(updated_at DESC);

-- Table: Top Earners Leaderboard
CREATE TABLE IF NOT EXISTS public.carousel_content_top_earners (
  leaderboard_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  rank_position INTEGER NOT NULL CHECK (rank_position > 0),
  earnings_this_month DECIMAL(10,2) DEFAULT 0.0,
  earnings_growth VARCHAR(20), -- e.g., "+23%"
  top_content_title VARCHAR(200),
  total_followers INTEGER DEFAULT 0,
  leaderboard_date DATE DEFAULT CURRENT_DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, leaderboard_date)
);

CREATE INDEX IF NOT EXISTS idx_top_earners_rank ON public.carousel_content_top_earners(rank_position ASC) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_top_earners_date ON public.carousel_content_top_earners(leaderboard_date DESC);
CREATE INDEX IF NOT EXISTS idx_top_earners_user ON public.carousel_content_top_earners(user_id);

-- ============================================
-- USER PREFERENCES & CONFIGURATION
-- ============================================

-- Table: User Carousel Preferences
CREATE TABLE IF NOT EXISTS public.user_carousel_preferences (
  preference_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  carousel_type VARCHAR(50) NOT NULL CHECK (carousel_type IN ('jolts', 'moments', 'featured_elections', 'groups', 'recommended_elections', 'trending_topics', 'top_earners')),
  is_visible BOOLEAN DEFAULT true,
  position_order INTEGER DEFAULT 0,
  last_interaction TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, carousel_type)
);

CREATE INDEX IF NOT EXISTS idx_carousel_prefs_user ON public.user_carousel_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_carousel_prefs_visible ON public.user_carousel_preferences(user_id, position_order) WHERE is_visible = true;

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE public.carousel_content_jolts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_content_moments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_moment_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_featured_elections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_content_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_group_mutual_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_content_elections_recommended ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_content_trending_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_content_top_earners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_carousel_preferences ENABLE ROW LEVEL SECURITY;

-- Jolts Policies
CREATE POLICY "Jolts are viewable by authenticated users" ON public.carousel_content_jolts
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);

CREATE POLICY "Creators can insert their own jolts" ON public.carousel_content_jolts
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update their own jolts" ON public.carousel_content_jolts
  FOR UPDATE USING (auth.uid() = creator_id);

-- Moments Policies (expiry check moved to application layer)
CREATE POLICY "Moments are viewable by authenticated users" ON public.carousel_content_moments
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);

CREATE POLICY "Creators can insert their own moments" ON public.carousel_content_moments
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update their own moments" ON public.carousel_content_moments
  FOR UPDATE USING (auth.uid() = creator_id);

-- Moment Views Policies
CREATE POLICY "Users can view their own moment views" ON public.carousel_moment_views
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own moment views" ON public.carousel_moment_views
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Featured Elections Policies
CREATE POLICY "Featured elections are viewable by authenticated users" ON public.carousel_featured_elections
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);

-- Groups Policies
CREATE POLICY "Groups are viewable by authenticated users" ON public.carousel_content_groups
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);

-- Group Mutual Members Policies
CREATE POLICY "Users can view their own mutual members" ON public.carousel_group_mutual_members
  FOR SELECT USING (auth.uid() = user_id);

-- Recommended Elections Policies (expiry check moved to application layer)
CREATE POLICY "Users can view their own recommendations" ON public.carousel_content_elections_recommended
  FOR SELECT USING (auth.uid() = user_id AND is_active = true);

-- Trending Topics Policies
CREATE POLICY "Trending topics are viewable by authenticated users" ON public.carousel_content_trending_topics
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);

-- Top Earners Policies
CREATE POLICY "Top earners are viewable by authenticated users" ON public.carousel_content_top_earners
  FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);

-- User Preferences Policies
CREATE POLICY "Users can view their own carousel preferences" ON public.user_carousel_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own carousel preferences" ON public.user_carousel_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own carousel preferences" ON public.user_carousel_preferences
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_carousel_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_jolts_timestamp
  BEFORE UPDATE ON public.carousel_content_jolts
  FOR EACH ROW EXECUTE FUNCTION public.update_carousel_updated_at();

CREATE TRIGGER update_groups_timestamp
  BEFORE UPDATE ON public.carousel_content_groups
  FOR EACH ROW EXECUTE FUNCTION public.update_carousel_updated_at();

CREATE TRIGGER update_topics_timestamp
  BEFORE UPDATE ON public.carousel_content_trending_topics
  FOR EACH ROW EXECUTE FUNCTION public.update_carousel_updated_at();

CREATE TRIGGER update_preferences_timestamp
  BEFORE UPDATE ON public.user_carousel_preferences
  FOR EACH ROW EXECUTE FUNCTION public.update_carousel_updated_at();

-- Function: Increment jolt engagement counts
CREATE OR REPLACE FUNCTION public.increment_jolt_engagement(
  p_jolt_id UUID,
  p_engagement_type VARCHAR
)
RETURNS VOID AS $$
BEGIN
  CASE p_engagement_type
    WHEN 'view' THEN
      UPDATE public.carousel_content_jolts SET views_count = views_count + 1 WHERE jolt_id = p_jolt_id;
    WHEN 'like' THEN
      UPDATE public.carousel_content_jolts SET likes_count = likes_count + 1 WHERE jolt_id = p_jolt_id;
    WHEN 'comment' THEN
      UPDATE public.carousel_content_jolts SET comments_count = comments_count + 1 WHERE jolt_id = p_jolt_id;
    WHEN 'share' THEN
      UPDATE public.carousel_content_jolts SET shares_count = shares_count + 1 WHERE jolt_id = p_jolt_id;
  END CASE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Calculate trending score for jolts (marked as STABLE for better performance)
CREATE OR REPLACE FUNCTION public.calculate_jolt_trending_score(p_jolt_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  v_score DECIMAL;
  v_age_hours DECIMAL;
  v_engagement INTEGER;
BEGIN
  SELECT 
    EXTRACT(EPOCH FROM (NOW() - created_at)) / 3600,
    (views_count * 1) + (likes_count * 3) + (comments_count * 5) + (shares_count * 10)
  INTO v_age_hours, v_engagement
  FROM public.carousel_content_jolts
  WHERE jolt_id = p_jolt_id;
  
  -- Trending score formula: engagement / (age + 2)^1.5
  v_score := v_engagement / POWER(v_age_hours + 2, 1.5);
  
  -- Normalize to 0-100 scale
  v_score := LEAST(v_score, 100);
  
  UPDATE public.carousel_content_jolts SET trending_score = v_score WHERE jolt_id = p_jolt_id;
  
  RETURN v_score;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SAMPLE DATA (FOR TESTING)
-- ============================================

-- Insert sample jolts (only if user_profiles exist)
DO $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM public.user_profiles LIMIT 1;
  
  IF v_user_id IS NOT NULL THEN
    INSERT INTO public.carousel_content_jolts (creator_id, video_url, thumbnail_url, title, duration_seconds, views_count, likes_count, trending_score, hashtags)
    VALUES 
      (v_user_id, 'https://example.com/jolt1.mp4', 'https://images.pexels.com/photos/3184291/pexels-photo-3184291.jpeg', 'My Bold Political Take 🔥', 45, 234500, 12400, 94.2, ARRAY['#politics', '#trending']),
      (v_user_id, 'https://example.com/jolt2.mp4', 'https://images.unsplash.com/photo-1557804506-669a67965ba0', 'Election Day Vibes', 30, 156000, 8900, 87.5, ARRAY['#election', '#vote'])
    ON CONFLICT DO NOTHING;
  END IF;
END $$;

-- Insert sample trending topics
INSERT INTO public.carousel_content_trending_topics (hashtag, trend_score, total_posts, growth_rate, time_period)
VALUES 
  ('#Election2024', 94.2, 12847, '+342%', 'Last 24 hours'),
  ('#Democracy', 87.5, 8934, '+215%', 'Last 24 hours'),
  ('#VoteNow', 82.1, 6721, '+189%', 'Last 24 hours')
ON CONFLICT (hashtag) DO UPDATE SET
  trend_score = EXCLUDED.trend_score,
  total_posts = EXCLUDED.total_posts,
  growth_rate = EXCLUDED.growth_rate,
  updated_at = NOW();

-- Insert sample groups
INSERT INTO public.carousel_content_groups (name, description, cover_image_url, member_count, active_elections_count, category, is_trending, top_topics)
VALUES 
  ('Political Debate Club', 'Discuss elections, vote on policies', 'https://images.pixabay.com/photo/2016/11/18/15/44/audience-1835431_1280.jpg', 12847, 23, 'Politics', true, ARRAY['Healthcare', 'Economy', 'Education']),
  ('Sports Fans United', 'Vote on best teams and players', 'https://images.pexels.com/photos/274506/pexels-photo-274506.jpeg', 8934, 15, 'Sports', true, ARRAY['Football', 'Basketball', 'Soccer'])
ON CONFLICT DO NOTHING;

COMMIT;