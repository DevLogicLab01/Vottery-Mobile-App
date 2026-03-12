-- ============================================================
-- QUERY OPTIMIZATION: Fix slow queries and N+1 patterns
-- Addresses: 36 Slow Queries, 2.2 Avg Rows Per Call
-- ============================================================

-- ============================================================
-- SECTION 1: Optimized functions to replace N+1 query patterns
-- ============================================================

-- Batch fetch user profiles (replaces N+1 per-user queries)
CREATE OR REPLACE FUNCTION public.get_user_profiles_batch(user_ids UUID[])
RETURNS TABLE (
  id UUID,
  username TEXT,
  display_name TEXT,
  avatar_url TEXT,
  vp_balance NUMERIC,
  tier TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    up.id,
    up.username,
    up.display_name,
    up.avatar_url,
    COALESCE(up.vp_balance, 0)::NUMERIC,
    COALESCE(up.tier, 'bronze')::TEXT,
    up.created_at
  FROM public.user_profiles up
  WHERE up.id = ANY(user_ids);
$$;

-- Batch fetch election details (replaces N+1 per-election queries)
CREATE OR REPLACE FUNCTION public.get_elections_batch(election_ids UUID[])
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  status TEXT,
  creator_id UUID,
  vote_count BIGINT,
  created_at TIMESTAMPTZ,
  end_time TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    e.id,
    e.title,
    e.description,
    e.status::TEXT,
    e.creator_id,
    COALESCE(v.vote_count, 0)::BIGINT,
    e.created_at,
    e.end_time
  FROM public.elections e
  LEFT JOIN (
    SELECT election_id, COUNT(*) AS vote_count
    FROM public.votes
    WHERE election_id = ANY(election_ids)
    GROUP BY election_id
  ) v ON e.id = v.election_id
  WHERE e.id = ANY(election_ids);
$$;

-- Get user dashboard data in single query (replaces 5+ separate queries)
CREATE OR REPLACE FUNCTION public.get_user_dashboard_data(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'profile', (
      SELECT row_to_json(up.*)
      FROM public.user_profiles up
      WHERE up.id = p_user_id
      LIMIT 1
    ),
    'vp_balance', (
      SELECT COALESCE(vp_balance, 0)
      FROM public.user_profiles
      WHERE id = p_user_id
      LIMIT 1
    ),
    'level', (
      SELECT row_to_json(ul.*)
      FROM public.user_levels ul
      WHERE ul.user_id = p_user_id
      LIMIT 1
    ),
    'unread_notifications', (
      SELECT COUNT(*)
      FROM public.notifications
      WHERE user_id = p_user_id AND is_read = false
    ),
    'recent_votes', (
      SELECT COALESCE(json_agg(v.* ORDER BY v.created_at DESC), '[]'::json)
      FROM (
        SELECT * FROM public.votes
        WHERE user_id = p_user_id
        ORDER BY created_at DESC
        LIMIT 5
      ) v
    )
  ) INTO result;

  RETURN result;
END;
$$;

-- Get election feed with vote counts in single query
CREATE OR REPLACE FUNCTION public.get_election_feed(
  p_limit INT DEFAULT 20,
  p_offset INT DEFAULT 0,
  p_status TEXT DEFAULT 'active'
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  status TEXT,
  creator_id UUID,
  creator_username TEXT,
  creator_avatar TEXT,
  vote_count BIGINT,
  created_at TIMESTAMPTZ,
  end_time TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    e.id,
    e.title,
    e.description,
    e.status::TEXT,
    e.creator_id,
    up.username AS creator_username,
    up.avatar_url AS creator_avatar,
    COALESCE(vc.vote_count, 0)::BIGINT,
    e.created_at,
    e.end_time
  FROM public.elections e
  LEFT JOIN public.user_profiles up ON e.creator_id = up.id
  LEFT JOIN (
    SELECT election_id, COUNT(*) AS vote_count
    FROM public.votes
    GROUP BY election_id
  ) vc ON e.id = vc.election_id
  WHERE e.status = p_status
  ORDER BY e.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
$$;

-- Get creator analytics in single query (replaces 8+ separate queries)
CREATE OR REPLACE FUNCTION public.get_creator_analytics_summary(p_creator_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_elections', (
      SELECT COUNT(*) FROM public.elections WHERE creator_id = p_creator_id
    ),
    'active_elections', (
      SELECT COUNT(*) FROM public.elections
      WHERE creator_id = p_creator_id AND status = 'active'
    ),
    'total_votes_received', (
      SELECT COUNT(*)
      FROM public.votes v
      JOIN public.elections e ON v.election_id = e.id
      WHERE e.creator_id = p_creator_id
    ),
    'total_earnings', (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.creator_earnings
      WHERE creator_id = p_creator_id
    ),
    'follower_count', (
      SELECT COUNT(*)
      FROM public.follows
      WHERE following_id = p_creator_id
    ),
    'recent_earnings', (
      SELECT COALESCE(json_agg(ce.* ORDER BY ce.created_at DESC), '[]'::json)
      FROM (
        SELECT * FROM public.creator_earnings
        WHERE creator_id = p_creator_id
        ORDER BY created_at DESC
        LIMIT 10
      ) ce
    )
  ) INTO result;

  RETURN result;
END;
$$;

-- ============================================================
-- SECTION 2: Covering indexes for common SELECT patterns
-- ============================================================

-- Elections feed covering index (avoids table heap access)
CREATE INDEX IF NOT EXISTS idx_elections_feed_covering
  ON public.elections(status, created_at DESC)
  INCLUDE (id, title, creator_id, end_time);

-- Votes covering index for election results
CREATE INDEX IF NOT EXISTS idx_votes_election_covering
  ON public.votes(election_id)
  INCLUDE (user_id, option_id, created_at);

-- Notifications covering index
CREATE INDEX IF NOT EXISTS idx_notifications_user_covering
  ON public.notifications(user_id, is_read, created_at DESC)
  INCLUDE (id, title, type);

-- VP transactions covering index
CREATE INDEX IF NOT EXISTS idx_vp_transactions_user_covering
  ON public.vp_transactions(user_id, created_at DESC)
  INCLUDE (id, amount, transaction_type, description);

-- Creator earnings covering index
CREATE INDEX IF NOT EXISTS idx_creator_earnings_covering
  ON public.creator_earnings(creator_id, created_at DESC)
  INCLUDE (id, amount, source_type);

-- ============================================================
-- SECTION 3: Materialized view for leaderboard (expensive aggregation)
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_creator_leaderboard AS
SELECT
  up.id AS creator_id,
  up.username,
  up.avatar_url,
  up.tier,
  COUNT(DISTINCT e.id) AS total_elections,
  COUNT(DISTINCT v.id) AS total_votes_received,
  COALESCE(SUM(ce.amount), 0) AS total_earnings,
  COUNT(DISTINCT f.follower_id) AS follower_count,
  MAX(e.created_at) AS last_election_at
FROM public.user_profiles up
LEFT JOIN public.elections e ON e.creator_id = up.id
LEFT JOIN public.votes v ON v.election_id = e.id
LEFT JOIN public.creator_earnings ce ON ce.creator_id = up.id
LEFT JOIN public.follows f ON f.following_id = up.id
GROUP BY up.id, up.username, up.avatar_url, up.tier
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_creator_leaderboard_creator_id
  ON public.mv_creator_leaderboard(creator_id);

CREATE INDEX IF NOT EXISTS idx_mv_creator_leaderboard_earnings
  ON public.mv_creator_leaderboard(total_earnings DESC);

CREATE INDEX IF NOT EXISTS idx_mv_creator_leaderboard_votes
  ON public.mv_creator_leaderboard(total_votes_received DESC);

-- ============================================================
-- SECTION 4: Materialized view for election stats (slow aggregation)
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_election_stats AS
SELECT
  e.id AS election_id,
  e.title,
  e.status,
  e.creator_id,
  COUNT(DISTINCT v.id) AS vote_count,
  COUNT(DISTINCT v.user_id) AS unique_voters,
  MAX(v.created_at) AS last_vote_at,
  e.created_at,
  e.end_time
FROM public.elections e
LEFT JOIN public.votes v ON v.election_id = e.id
GROUP BY e.id, e.title, e.status, e.creator_id, e.created_at, e.end_time
WITH DATA;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_election_stats_election_id
  ON public.mv_election_stats(election_id);

CREATE INDEX IF NOT EXISTS idx_mv_election_stats_status
  ON public.mv_election_stats(status, vote_count DESC);

CREATE INDEX IF NOT EXISTS idx_mv_election_stats_creator
  ON public.mv_election_stats(creator_id, created_at DESC);

-- ============================================================
-- SECTION 5: Function to refresh materialized views
-- ============================================================
CREATE OR REPLACE FUNCTION public.refresh_materialized_views()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_creator_leaderboard;
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_election_stats;
END;
$$;

-- ============================================================
-- SECTION 6: Optimized RLS policies using indexes
-- (Replace expensive function-based policies with direct comparisons)
-- ============================================================

-- Ensure user_profiles policy uses indexed column directly
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
  ON public.user_profiles
  FOR ALL
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Admin read-all policy for user_profiles
DROP POLICY IF EXISTS "admin_read_all_user_profiles" ON public.user_profiles;
CREATE POLICY "admin_read_all_user_profiles"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid() OR public.is_admin_user());

-- ============================================================
-- SECTION 7: Statistics update for query planner
-- ============================================================
DO $$
BEGIN
  -- Analyze key tables to update query planner statistics
  ANALYZE public.user_profiles;
  ANALYZE public.elections;
  ANALYZE public.votes;
  ANALYZE public.notifications;
  ANALYZE public.vp_transactions;
  ANALYZE public.creator_earnings;
  ANALYZE public.follows;
  ANALYZE public.messages;
  ANALYZE public.conversations;
  ANALYZE public.fraud_alerts;
  ANALYZE public.payouts;
  ANALYZE public.audit_logs;
  ANALYZE public.security_events;
  RAISE NOTICE 'Query optimization migration applied: batch functions, covering indexes, materialized views, statistics updated';
END $$;
