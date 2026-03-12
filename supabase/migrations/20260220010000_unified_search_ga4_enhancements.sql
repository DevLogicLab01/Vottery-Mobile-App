-- ============================================================
-- UNIFIED SEARCH SYSTEM MIGRATION
-- ============================================================

-- Search Analytics Table (using existing structure)
CREATE TABLE IF NOT EXISTS public.search_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  query TEXT NOT NULL,
  results_count INTEGER DEFAULT 0,
  search_count INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_search_analytics_user_id ON public.search_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_search_analytics_created_at ON public.search_analytics(created_at);
CREATE INDEX IF NOT EXISTS idx_search_analytics_query ON public.search_analytics(query);

-- Enable RLS
ALTER TABLE public.search_analytics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own search analytics" ON public.search_analytics;
CREATE POLICY "Users can view their own search analytics"
  ON public.search_analytics FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own search analytics" ON public.search_analytics;
CREATE POLICY "Users can insert their own search analytics"
  ON public.search_analytics FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- POSTGRESQL TRIGRAM SEARCH FUNCTIONS
-- ============================================================

-- Enable pg_trgm extension for trigram similarity search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Search Posts Function
CREATE OR REPLACE FUNCTION public.search_posts_trigram(
  query_text TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  content TEXT,
  author TEXT,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sp.id,
    sp.title,
    sp.content,
    up.username AS author,
    sp.created_at,
    GREATEST(
      similarity(sp.title, query_text),
      similarity(sp.content, query_text)
    ) AS similarity_score
  FROM public.social_posts sp
  LEFT JOIN public.user_profiles up ON sp.user_id = up.id
  WHERE 
    sp.title % query_text OR
    sp.content % query_text
  ORDER BY similarity_score DESC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search Users Function
CREATE OR REPLACE FUNCTION public.search_users_trigram(
  query_text TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  username TEXT,
  bio TEXT,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    up.id,
    up.full_name AS name,
    up.username,
    up.bio,
    up.created_at,
    GREATEST(
      similarity(up.username, query_text),
      similarity(up.full_name, query_text),
      similarity(COALESCE(up.bio, ''), query_text)
    ) AS similarity_score
  FROM public.user_profiles up
  WHERE 
    up.username % query_text OR
    up.full_name % query_text OR
    COALESCE(up.bio, '') % query_text
  ORDER BY similarity_score DESC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search Groups Function
CREATE OR REPLACE FUNCTION public.search_groups_trigram(
  query_text TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  name TEXT,
  description TEXT,
  created_at TIMESTAMPTZ,
  member_count INTEGER,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    g.id,
    g.name,
    g.description,
    g.created_at,
    g.member_count,
    GREATEST(
      similarity(g.name, query_text),
      similarity(COALESCE(g.description, ''), query_text)
    ) AS similarity_score
  FROM public.groups g
  WHERE 
    g.name % query_text OR
    COALESCE(g.description, '') % query_text
  ORDER BY similarity_score DESC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search Elections Function
CREATE OR REPLACE FUNCTION public.search_elections_trigram(
  query_text TEXT,
  result_limit INTEGER DEFAULT 20,
  result_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  creator TEXT,
  created_at TIMESTAMPTZ,
  similarity_score REAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.title,
    e.description,
    up.username AS creator,
    e.created_at,
    GREATEST(
      similarity(e.title, query_text),
      similarity(COALESCE(e.description, ''), query_text)
    ) AS similarity_score
  FROM public.elections e
  LEFT JOIN public.user_profiles up ON e.creator_id = up.id
  WHERE 
    e.title % query_text OR
    COALESCE(e.description, '') % query_text
  ORDER BY similarity_score DESC
  LIMIT result_limit
  OFFSET result_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Trending Searches Function (FIXED: using 'query' column)
CREATE OR REPLACE FUNCTION public.get_trending_searches(
  days_back INTEGER DEFAULT 7
)
RETURNS TABLE (
  query TEXT,
  search_count BIGINT,
  last_searched TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sa.query,
    SUM(sa.search_count)::BIGINT AS search_count,
    MAX(sa.created_at) AS last_searched
  FROM public.search_analytics sa
  WHERE 
    sa.created_at >= NOW() - (days_back || ' days')::INTERVAL
    AND sa.results_count > 0
  GROUP BY sa.query
  ORDER BY SUM(sa.search_count) DESC, MAX(sa.created_at) DESC
  LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Top Searches Function (FIXED: using 'query' column)
CREATE OR REPLACE FUNCTION public.get_top_searches(
  result_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  query TEXT,
  search_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    sa.query,
    SUM(sa.search_count)::BIGINT AS search_count
  FROM public.search_analytics sa
  GROUP BY sa.query
  ORDER BY SUM(sa.search_count) DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- GOOGLE ANALYTICS ENHANCED TRACKING TABLES
-- ============================================================

-- Creator Earnings Tracking Table
CREATE TABLE IF NOT EXISTS public.ga4_creator_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  earnings_type TEXT NOT NULL, -- jolt, election, prediction, marketplace
  payout_method TEXT NOT NULL, -- stripe, trolley
  revenue_split TEXT NOT NULL, -- 70/30, 80/20, etc.
  zone TEXT,
  currency TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ga4_creator_earnings_creator_id ON public.ga4_creator_earnings(creator_id);
CREATE INDEX IF NOT EXISTS idx_ga4_creator_earnings_created_at ON public.ga4_creator_earnings(created_at);
CREATE INDEX IF NOT EXISTS idx_ga4_creator_earnings_type ON public.ga4_creator_earnings(earnings_type);

-- AI Feature Adoption Tracking Table
CREATE TABLE IF NOT EXISTS public.ga4_ai_feature_adoption (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  feature_name TEXT NOT NULL, -- quest_generation, feed_ranking, threat_detection
  ai_provider TEXT NOT NULL, -- claude, openai, perplexity, gemini
  execution_time_ms INTEGER NOT NULL,
  success_status BOOLEAN NOT NULL,
  error_message TEXT,
  additional_params JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ga4_ai_adoption_user_id ON public.ga4_ai_feature_adoption(user_id);
CREATE INDEX IF NOT EXISTS idx_ga4_ai_adoption_feature ON public.ga4_ai_feature_adoption(feature_name);
CREATE INDEX IF NOT EXISTS idx_ga4_ai_adoption_provider ON public.ga4_ai_feature_adoption(ai_provider);
CREATE INDEX IF NOT EXISTS idx_ga4_ai_adoption_created_at ON public.ga4_ai_feature_adoption(created_at);

-- Enable RLS
ALTER TABLE public.ga4_creator_earnings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_ai_feature_adoption ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view all creator earnings" ON public.ga4_creator_earnings;
CREATE POLICY "Admins can view all creator earnings"
  ON public.ga4_creator_earnings FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  ));

DROP POLICY IF EXISTS "Admins can view all AI feature adoption" ON public.ga4_ai_feature_adoption;
CREATE POLICY "Admins can view all AI feature adoption"
  ON public.ga4_ai_feature_adoption FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  ));

-- ============================================================
-- REAL-TIME ENGAGEMENT DASHBOARD FUNCTIONS
-- ============================================================

-- Get Live Engagement Metrics Function
CREATE OR REPLACE FUNCTION public.get_live_engagement_metrics()
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'active_users_5min', (
      SELECT COUNT(DISTINCT user_id)
      FROM public.ga4_sessions
      WHERE session_start >= NOW() - INTERVAL '5 minutes'
    ),
    'active_users_trend', 0.0, -- TODO: Calculate trend
    'votes_last_hour', (
      SELECT COUNT(*)
      FROM public.votes
      WHERE created_at >= NOW() - INTERVAL '1 hour'
    ),
    'vote_velocity', (
      SELECT COUNT(*)::DECIMAL / 60
      FROM public.votes
      WHERE created_at >= NOW() - INTERVAL '1 hour'
    ),
    'vp_earned_last_hour', (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.vp_transactions
      WHERE created_at >= NOW() - INTERVAL '1 hour'
      AND transaction_type = 'earned'
    ),
    'vp_breakdown', '{}'::JSONB,
    'quests_last_hour', (
      SELECT COUNT(*)
      FROM public.quest_completions
      WHERE completed_at >= NOW() - INTERVAL '1 hour'
    ),
    'quest_completion_rate', 0.0 -- TODO: Calculate rate
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Top Active Elections Function
CREATE OR REPLACE FUNCTION public.get_top_active_elections(
  result_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  participation_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.id,
    e.title,
    COUNT(v.id) AS participation_count
  FROM public.elections e
  LEFT JOIN public.votes v ON e.id = v.election_id
  WHERE v.created_at >= NOW() - INTERVAL '1 hour'
  GROUP BY e.id, e.title
  ORDER BY participation_count DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Top Active Creators Function
CREATE OR REPLACE FUNCTION public.get_top_active_creators(
  result_limit INTEGER DEFAULT 5
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  engagement_level BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    up.id,
    up.username,
    COUNT(*) AS engagement_level
  FROM public.user_profiles up
  LEFT JOIN public.elections e ON up.id = e.creator_id
  WHERE e.created_at >= NOW() - INTERVAL '24 hours'
  GROUP BY up.id, up.username
  ORDER BY engagement_level DESC
  LIMIT result_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get Conversion Funnel Metrics Function
CREATE OR REPLACE FUNCTION public.get_conversion_funnel_metrics()
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'kyc_funnel', jsonb_build_object(
      'steps', '[]'::JSONB,
      'conversion_rate', 0.0
    ),
    'voting_funnel', jsonb_build_object(
      'steps', '[]'::JSONB,
      'conversion_rate', 0.0
    ),
    'creator_funnel', jsonb_build_object(
      'steps', '[]'::JSONB,
      'conversion_rate', 0.0
    ),
    'subscription_funnel', jsonb_build_object(
      'steps', '[]'::JSONB,
      'conversion_rate', 0.0
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.search_posts_trigram TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_users_trigram TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_groups_trigram TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_elections_trigram TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_trending_searches TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_top_searches TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_live_engagement_metrics TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_top_active_elections TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_top_active_creators TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_conversion_funnel_metrics TO authenticated;
