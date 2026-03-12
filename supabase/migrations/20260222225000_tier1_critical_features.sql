-- TIER 1 CRITICAL FEATURES: Error Recovery, Error Tracking, Privacy Controls, Advanced Search
-- Migration: 20260222225000_tier1_critical_features.sql

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USER PRIVACY SETTINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.user_privacy_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Activity Privacy
  online_status_visibility TEXT DEFAULT 'everyone' CHECK (online_status_visibility IN ('everyone', 'friends', 'nobody')),
  last_seen_visibility TEXT DEFAULT 'everyone' CHECK (last_seen_visibility IN ('everyone', 'friends', 'nobody')),
  activity_status BOOLEAN DEFAULT true,
  read_receipts BOOLEAN DEFAULT true,
  typing_indicators BOOLEAN DEFAULT true,
  
  -- Profile Visibility
  profile_photo_visibility TEXT DEFAULT 'public' CHECK (profile_photo_visibility IN ('public', 'friends', 'private')),
  cover_photo_visibility TEXT DEFAULT 'public' CHECK (cover_photo_visibility IN ('public', 'friends', 'private')),
  bio_visibility TEXT DEFAULT 'public' CHECK (bio_visibility IN ('public', 'friends', 'private')),
  dob_visibility TEXT DEFAULT 'friends' CHECK (dob_visibility IN ('public', 'friends', 'private')),
  phone_visibility TEXT DEFAULT 'private' CHECK (phone_visibility IN ('public', 'friends', 'private')),
  email_visibility TEXT DEFAULT 'private' CHECK (email_visibility IN ('public', 'friends', 'private')),
  location_visibility TEXT DEFAULT 'friends' CHECK (location_visibility IN ('public', 'friends', 'private')),
  
  -- Contact Preferences
  who_can_message TEXT DEFAULT 'everyone' CHECK (who_can_message IN ('everyone', 'friends', 'friends_of_friends', 'nobody')),
  who_can_call TEXT DEFAULT 'friends' CHECK (who_can_call IN ('everyone', 'friends', 'friends_of_friends', 'nobody')),
  require_approval_for_tags BOOLEAN DEFAULT true,
  who_can_comment TEXT DEFAULT 'everyone' CHECK (who_can_comment IN ('everyone', 'friends', 'friends_of_friends', 'nobody')),
  allow_content_sharing BOOLEAN DEFAULT true,
  require_group_approval BOOLEAN DEFAULT true,
  
  -- Data Sharing
  share_with_advertisers BOOLEAN DEFAULT false,
  share_with_analytics BOOLEAN DEFAULT true,
  share_location_data BOOLEAN DEFAULT false,
  share_device_info BOOLEAN DEFAULT true,
  share_contacts BOOLEAN DEFAULT false,
  share_usage_patterns BOOLEAN DEFAULT true,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_privacy_settings_user_id ON public.user_privacy_settings(user_id);

-- ============================================================================
-- SEARCH HISTORY TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.search_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  query TEXT NOT NULL,
  search_domain TEXT, -- posts, users, groups, elections, all
  result_count INTEGER DEFAULT 0,
  clicked_result_id UUID,
  clicked_result_domain TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_search_history_user_id ON public.search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_search_history_created_at ON public.search_history(created_at DESC);

-- ============================================================================
-- SAVED SEARCHES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.saved_searches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  query TEXT NOT NULL,
  name TEXT,
  search_domain TEXT,
  filters JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_executed_at TIMESTAMPTZ,
  
  UNIQUE(user_id, query)
);

CREATE INDEX IF NOT EXISTS idx_saved_searches_user_id ON public.saved_searches(user_id);

-- ============================================================================
-- TRENDING SEARCHES TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.trending_searches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  query TEXT NOT NULL UNIQUE,
  search_count INTEGER DEFAULT 1,
  last_searched_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trending_searches_count ON public.trending_searches(search_count DESC);
CREATE INDEX IF NOT EXISTS idx_trending_searches_updated ON public.trending_searches(updated_at DESC);

-- ============================================================================
-- NOTE: search_analytics table already exists from migration 20260220010000
-- We'll work with the existing structure:
-- - id, user_id, query, results_count, search_count, created_at
-- ============================================================================

-- ============================================================================
-- TRIGRAM SEARCH FUNCTIONS
-- ============================================================================

-- Drop existing functions to avoid return type conflicts
DROP FUNCTION IF EXISTS public.search_posts_trigram(TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.search_users_trigram(TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.search_groups_trigram(TEXT, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.search_elections_trigram(TEXT, INTEGER, INTEGER);

-- Search posts using trigram similarity
CREATE FUNCTION public.search_posts_trigram(
  query_text TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  post_id UUID,
  content TEXT,
  author_id UUID,
  author_name TEXT,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id AS post_id,
    p.content,
    p.user_id AS author_id,
    up.username AS author_name,
    p.created_at,
    SIMILARITY(p.content, query_text) AS similarity_score
  FROM public.posts p
  LEFT JOIN public.user_profiles up ON p.user_id = up.id
  WHERE p.content % query_text
  ORDER BY similarity_score DESC, p.created_at DESC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search users using trigram similarity
CREATE FUNCTION public.search_users_trigram(
  query_text TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  full_name TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    up.id AS user_id,
    up.username,
    up.full_name,
    up.bio,
    up.created_at,
    GREATEST(
      SIMILARITY(up.username, query_text),
      SIMILARITY(COALESCE(up.full_name, ''), query_text),
      SIMILARITY(COALESCE(up.bio, ''), query_text)
    ) AS similarity_score
  FROM public.user_profiles up
  WHERE 
    up.username % query_text OR
    COALESCE(up.full_name, '') % query_text OR
    COALESCE(up.bio, '') % query_text
  ORDER BY similarity_score DESC, up.created_at DESC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search groups using trigram similarity
CREATE FUNCTION public.search_groups_trigram(
  query_text TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  group_id UUID,
  name TEXT,
  description TEXT,
  member_count INTEGER,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id AS group_id,
    g.name,
    g.description,
    g.member_count,
    g.created_at,
    GREATEST(
      SIMILARITY(g.name, query_text),
      SIMILARITY(COALESCE(g.description, ''), query_text)
    ) AS similarity_score
  FROM public.groups g
  WHERE 
    g.name % query_text OR
    COALESCE(g.description, '') % query_text
  ORDER BY similarity_score DESC, g.created_at DESC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search elections using trigram similarity
CREATE FUNCTION public.search_elections_trigram(
  query_text TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  election_id UUID,
  title TEXT,
  description TEXT,
  creator_id UUID,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id AS election_id,
    e.title,
    e.description,
    e.creator_id,
    e.created_at,
    GREATEST(
      SIMILARITY(e.title, query_text),
      SIMILARITY(COALESCE(e.description, ''), query_text)
    ) AS similarity_score
  FROM public.elections e
  WHERE 
    e.title % query_text OR
    COALESCE(e.description, '') % query_text
  ORDER BY similarity_score DESC, e.created_at DESC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ERROR TRACKING ENHANCEMENTS
-- ============================================================================

-- Drop existing error tracking functions to avoid return type conflicts
DROP FUNCTION IF EXISTS public.get_recent_error_incidents(INTEGER, TEXT);
DROP FUNCTION IF EXISTS public.get_error_incidents_by_feature_count();

-- Function to get recent error incidents with filters
CREATE OR REPLACE FUNCTION public.get_recent_error_incidents(
  p_limit INTEGER DEFAULT 50,
  p_severity TEXT DEFAULT NULL
)
RETURNS TABLE (
  incident_id UUID,
  error_type TEXT,
  severity TEXT,
  affected_feature TEXT,
  error_message TEXT,
  stack_trace TEXT,
  user_context JSONB,
  device_info JSONB,
  status TEXT,
  occurred_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    eti.incident_id,
    eti.error_type,
    eti.severity,
    eti.affected_feature,
    eti.error_message,
    eti.stack_trace,
    eti.user_context,
    eti.device_info,
    eti.status,
    eti.occurred_at,
    eti.resolved_at
  FROM public.error_tracking_incidents eti
  WHERE (p_severity IS NULL OR eti.severity = p_severity)
  ORDER BY eti.occurred_at DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get error incidents by feature count
CREATE OR REPLACE FUNCTION public.get_error_incidents_by_feature_count()
RETURNS TABLE (
  feature TEXT,
  error_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    eti.affected_feature AS feature,
    COUNT(*) AS error_count
  FROM public.error_tracking_incidents eti
  WHERE eti.occurred_at >= NOW() - INTERVAL '24 hours'
  GROUP BY eti.affected_feature
  ORDER BY error_count DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- User Privacy Settings RLS
ALTER TABLE public.user_privacy_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own privacy settings" ON public.user_privacy_settings;
CREATE POLICY "Users can view own privacy settings"
  ON public.user_privacy_settings
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own privacy settings" ON public.user_privacy_settings;
CREATE POLICY "Users can update own privacy settings"
  ON public.user_privacy_settings
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own privacy settings" ON public.user_privacy_settings;
CREATE POLICY "Users can insert own privacy settings"
  ON public.user_privacy_settings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Search History RLS
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own search history" ON public.search_history;
CREATE POLICY "Users can view own search history"
  ON public.search_history
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own search history" ON public.search_history;
CREATE POLICY "Users can insert own search history"
  ON public.search_history
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own search history" ON public.search_history;
CREATE POLICY "Users can delete own search history"
  ON public.search_history
  FOR DELETE
  USING (auth.uid() = user_id);

-- Saved Searches RLS
ALTER TABLE public.saved_searches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own saved searches" ON public.saved_searches;
CREATE POLICY "Users can view own saved searches"
  ON public.saved_searches
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own saved searches" ON public.saved_searches;
CREATE POLICY "Users can insert own saved searches"
  ON public.saved_searches
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own saved searches" ON public.saved_searches;
CREATE POLICY "Users can update own saved searches"
  ON public.saved_searches
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own saved searches" ON public.saved_searches;
CREATE POLICY "Users can delete own saved searches"
  ON public.saved_searches
  FOR DELETE
  USING (auth.uid() = user_id);

-- Trending Searches RLS (Public read, admin write)
ALTER TABLE public.trending_searches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view trending searches" ON public.trending_searches;
CREATE POLICY "Anyone can view trending searches"
  ON public.trending_searches
  FOR SELECT
  USING (true);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update trending searches on new search
CREATE OR REPLACE FUNCTION public.update_trending_searches()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.trending_searches (query, search_count, last_searched_at, updated_at)
  VALUES (NEW.query, 1, NOW(), NOW())
  ON CONFLICT (query) DO UPDATE
  SET 
    search_count = public.trending_searches.search_count + 1,
    last_searched_at = NOW(),
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_trending_searches ON public.search_history;
CREATE TRIGGER trigger_update_trending_searches
  AFTER INSERT ON public.search_history
  FOR EACH ROW
  EXECUTE FUNCTION public.update_trending_searches();

-- Update search analytics (adapted to existing table structure)
CREATE OR REPLACE FUNCTION public.update_search_analytics_tier1()
RETURNS TRIGGER AS $$
BEGIN
  -- Update existing search_analytics table with results_count and search_count
  INSERT INTO public.search_analytics (
    user_id,
    query,
    results_count,
    search_count,
    created_at
  )
  VALUES (
    NEW.user_id,
    NEW.query,
    NEW.result_count,
    1,
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_update_search_analytics_tier1 ON public.search_history;
CREATE TRIGGER trigger_update_search_analytics_tier1
  AFTER INSERT ON public.search_history
  FOR EACH ROW
  EXECUTE FUNCTION public.update_search_analytics_tier1();

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_privacy_settings TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.search_history TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.saved_searches TO authenticated;
GRANT SELECT ON public.trending_searches TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.search_posts_trigram TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_users_trigram TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_groups_trigram TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_elections_trigram TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_recent_error_incidents TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_error_incidents_by_feature_count TO authenticated;
