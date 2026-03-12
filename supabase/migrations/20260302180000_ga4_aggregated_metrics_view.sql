-- ============================================================
-- GA4 Aggregated Metrics View (single-row platform rollup)
-- Consumed by Flutter GA4 Enhanced Analytics Dashboard.
-- ============================================================

DROP VIEW IF EXISTS public.ga4_aggregated_metrics_view;

CREATE VIEW public.ga4_aggregated_metrics_view AS
WITH
  session_users AS (
    SELECT COUNT(DISTINCT user_id) AS cnt
    FROM public.ga4_sessions
    WHERE session_start >= NOW() - INTERVAL '30 days'
  ),
  voting_users AS (
    SELECT COUNT(DISTINCT user_id) AS cnt
    FROM public.ga4_analytics_events
    WHERE event_type::text = 'vote_cast'
      AND created_at >= NOW() - INTERVAL '30 days'
  ),
  funnel_total AS (
    SELECT COUNT(*) AS cnt
    FROM public.ga4_conversion_funnels
    WHERE created_at >= NOW() - INTERVAL '30 days'
  ),
  funnel_completed AS (
    SELECT COUNT(*) AS cnt
    FROM public.ga4_conversion_funnels
    WHERE completed = true
      AND created_at >= NOW() - INTERVAL '30 days'
  ),
  share_events AS (
    SELECT COUNT(*) AS cnt
    FROM public.ga4_analytics_events
    WHERE event_type::text = 'share_clicked'
      AND created_at >= NOW() - INTERVAL '30 days'
  ),
  watch_time AS (
    SELECT COALESCE(AVG(time_spent_seconds), 0)::FLOAT8 AS avg_sec
    FROM public.ga4_screen_views
    WHERE time_spent_seconds IS NOT NULL
      AND created_at >= NOW() - INTERVAL '30 days'
  ),
  transactions_count AS (
    SELECT COUNT(DISTINCT user_id) AS cnt
    FROM public.ga4_ecommerce_transactions
    WHERE created_at >= NOW() - INTERVAL '30 days'
  ),
  post_likes AS (
    SELECT COUNT(*) AS cnt
    FROM public.ga4_analytics_events
    WHERE event_type::text = 'post_like'
      AND created_at >= NOW() - INTERVAL '30 days'
  ),
  feed_ctr AS (
    SELECT COALESCE(AVG(ctr), 0)::FLOAT8 AS val
    FROM public.feed_performance_metrics
    WHERE metric_date >= (CURRENT_DATE - INTERVAL '30 days')
  ),
  engagement_sessions AS (
    SELECT COUNT(DISTINCT s.user_id) AS cnt
    FROM public.ga4_sessions s
    WHERE s.session_start >= NOW() - INTERVAL '30 days'
      AND (s.events_count > 0 OR s.screen_views_count > 0)
  )
SELECT
  -- Participation: voters / users with sessions (30d)
  ROUND(
    (SELECT v.cnt FROM voting_users v)::NUMERIC
    / NULLIF((SELECT s.cnt FROM session_users s), 0) * 100,
    2
  )::FLOAT8 AS participation_rate,

  -- Vote funnel: completed / total steps (30d)
  ROUND(
    (SELECT c.cnt FROM funnel_completed c)::NUMERIC
    / NULLIF((SELECT f.cnt FROM funnel_total f), 0) * 100,
    2
  )::FLOAT8 AS vote_funnel_completion,

  -- Engagement: sessions with activity / total sessions
  ROUND(
    (SELECT e.cnt FROM engagement_sessions e)::NUMERIC
    / NULLIF((SELECT s.cnt FROM session_users s), 0) * 100,
    2
  )::FLOAT8 AS engagement_rate,

  -- Retention: placeholder (could use cohort in future)
  0.0::FLOAT8 AS retention_rate,

  -- Virality: share events count (raw score)
  COALESCE((SELECT sh.cnt FROM share_events sh), 0)::FLOAT8 AS virality_score,

  -- Audience growth: placeholder (would need user_profiles signup curve)
  0.0::FLOAT8 AS audience_growth_rate,

  -- Share of voice / brand: placeholders
  0.0::FLOAT8 AS share_of_voice,
  0.0::FLOAT8 AS brand_mentions,

  -- Content & watch time
  COALESCE((SELECT avg_sec FROM watch_time), 0)::FLOAT8 AS avg_watch_time_seconds,
  0::BIGINT::FLOAT8 AS video_views,
  0.0::FLOAT8 AS story_completion_rate,
  COALESCE((SELECT p.cnt FROM post_likes p), 0)::FLOAT8 AS saved_posts,

  -- Acquisition & ROI
  COALESCE((SELECT val FROM feed_ctr), 0)::FLOAT8 * 100 AS click_through_rate,
  ROUND(
    (SELECT t.cnt FROM transactions_count t)::NUMERIC
    / NULLIF((SELECT s.cnt FROM session_users s), 0) * 100,
    2
  )::FLOAT8 AS conversion_rate_overall,
  NULL::FLOAT8 AS customer_acquisition_cost,
  NULL::FLOAT8 AS cost_per_click;

-- Grant read to authenticated (dashboard is behind auth)
GRANT SELECT ON public.ga4_aggregated_metrics_view TO authenticated;
GRANT SELECT ON public.ga4_aggregated_metrics_view TO service_role;

COMMENT ON VIEW public.ga4_aggregated_metrics_view IS
  'Single-row platform rollup for GA4 Enhanced Analytics Dashboard (participation, funnel, engagement, virality, watch time, conversions).';
