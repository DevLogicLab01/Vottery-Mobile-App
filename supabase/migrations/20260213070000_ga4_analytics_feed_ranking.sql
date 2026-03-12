-- ============================================================
-- GA4 Analytics + Feed Ranking Engine Migration
-- Batch 4: Google Analytics GA4 Integration + OpenAI Embeddings + Real-Time Feed Ranking
-- ============================================================

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.analytics_event_type CASCADE;
CREATE TYPE public.analytics_event_type AS ENUM (
  'vote_cast', 'vote_verified', 'vote_audited',
  'quest_complete', 'quest_start',
  'vp_earned', 'vp_spent', 'vp_purchase',
  'post_like', 'comment_added', 'share_clicked', 'jolt_viewed', 'moment_viewed',
  'screen_view', 'session_start', 'session_end',
  'registration', 'email_verification', 'first_vote', 'gamification_participation', 'subscription_upgrade',
  'transaction', 'purchase', 'refund',
  'app_crash', 'app_error'
);

DROP TYPE IF EXISTS public.purchasing_power_zone CASCADE;
CREATE TYPE public.purchasing_power_zone AS ENUM (
  'US_Canada', 'Western_Europe', 'Eastern_Europe', 'Africa',
  'Latin_America', 'Middle_East_Asia', 'Australasia', 'China_Hong_Kong'
);

DROP TYPE IF EXISTS public.ab_test_group CASCADE;
CREATE TYPE public.ab_test_group AS ENUM ('control', 'algorithm_v1', 'algorithm_v2');

DROP TYPE IF EXISTS public.content_type CASCADE;
CREATE TYPE public.content_type AS ENUM ('election', 'post', 'ad', 'jolt', 'moment', 'quest');

DROP TYPE IF EXISTS public.engagement_signal_type CASCADE;
CREATE TYPE public.engagement_signal_type AS ENUM (
  'view', 'reaction', 'comment', 'share', 'vote_participation', 'quest_completion'
);

-- ============================================================
-- 2. ANALYTICS EVENTS TABLES
-- ============================================================

-- GA4 Analytics Events (with offline queuing support)
CREATE TABLE IF NOT EXISTS public.ga4_analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  event_type public.analytics_event_type NOT NULL,
  event_name TEXT NOT NULL,
  event_params JSONB DEFAULT '{}'::jsonb,
  user_properties JSONB DEFAULT '{}'::jsonb,
  session_id TEXT,
  client_id TEXT NOT NULL,
  timestamp_micros BIGINT NOT NULL,
  is_synced BOOLEAN DEFAULT false,
  sync_attempts INTEGER DEFAULT 0,
  last_sync_attempt TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  synced_at TIMESTAMPTZ
);

-- Screen View Tracking
CREATE TABLE IF NOT EXISTS public.ga4_screen_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  screen_name TEXT NOT NULL,
  previous_screen TEXT,
  time_spent_seconds INTEGER,
  entry_point TEXT,
  session_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Conversion Funnel Tracking
CREATE TABLE IF NOT EXISTS public.ga4_conversion_funnels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  funnel_stage TEXT NOT NULL,
  completed BOOLEAN DEFAULT false,
  completion_time TIMESTAMPTZ,
  session_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User Properties (for GA4 custom dimensions)
CREATE TABLE IF NOT EXISTS public.ga4_user_properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  subscription_tier TEXT,
  user_level INTEGER DEFAULT 1,
  total_vp_balance INTEGER DEFAULT 0,
  voting_frequency TEXT,
  preferred_categories TEXT[],
  account_age_days INTEGER,
  country TEXT,
  purchasing_power_zone public.purchasing_power_zone,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

-- Session Tracking
CREATE TABLE IF NOT EXISTS public.ga4_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  session_id TEXT NOT NULL UNIQUE,
  session_start TIMESTAMPTZ NOT NULL,
  session_end TIMESTAMPTZ,
  session_duration_seconds INTEGER,
  screen_views_count INTEGER DEFAULT 0,
  events_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- E-commerce Transactions
CREATE TABLE IF NOT EXISTS public.ga4_ecommerce_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  transaction_id TEXT NOT NULL UNIQUE,
  transaction_type TEXT NOT NULL,
  revenue DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  payment_method TEXT,
  items JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Crash Analytics
CREATE TABLE IF NOT EXISTS public.ga4_crash_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  crash_type TEXT NOT NULL,
  stack_trace TEXT,
  device_info JSONB DEFAULT '{}'::jsonb,
  app_version TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. FEED RANKING ENGINE TABLES
-- ============================================================

-- Content Embeddings (OpenAI 1536-dimensional vectors)
CREATE TABLE IF NOT EXISTS public.content_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL,
  content_type public.content_type NOT NULL,
  embedding_vector FLOAT8[] NOT NULL,
  text_content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(content_id, content_type)
);

-- User Taste Profiles (for collaborative filtering)
CREATE TABLE IF NOT EXISTS public.user_taste_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  preference_vector JSONB NOT NULL DEFAULT '{}'::jsonb,
  engagement_history JSONB NOT NULL DEFAULT '[]'::jsonb,
  last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

-- Engagement Signals (weighted scoring)
CREATE TABLE IF NOT EXISTS public.engagement_signals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content_id UUID NOT NULL,
  content_type public.content_type NOT NULL,
  signal_type public.engagement_signal_type NOT NULL,
  signal_weight INTEGER NOT NULL,
  view_duration_seconds INTEGER,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Personalized Rankings (cached scores)
CREATE TABLE IF NOT EXISTS public.personalized_rankings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content_id UUID NOT NULL,
  content_type public.content_type NOT NULL,
  semantic_similarity_score FLOAT8 DEFAULT 0.0,
  collaborative_filtering_score FLOAT8 DEFAULT 0.0,
  recency_boost FLOAT8 DEFAULT 0.0,
  popularity_boost FLOAT8 DEFAULT 0.0,
  diversity_penalty FLOAT8 DEFAULT 0.0,
  final_ranking_score FLOAT8 NOT NULL,
  ranking_explanation JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMPTZ DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 seconds')
);

-- Collaborative Filtering Matrix (user-item interactions)
CREATE TABLE IF NOT EXISTS public.collaborative_filtering_matrix (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content_id UUID NOT NULL,
  content_type public.content_type NOT NULL,
  interaction_score FLOAT8 NOT NULL DEFAULT 0.0,
  last_interaction TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, content_id, content_type)
);

-- Similar Users (for user-based filtering)
CREATE TABLE IF NOT EXISTS public.similar_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  similar_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  similarity_score FLOAT8 NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, similar_user_id)
);

-- ============================================================
-- 4. A/B TESTING FRAMEWORK TABLES
-- ============================================================

-- A/B Test Assignments
CREATE TABLE IF NOT EXISTS public.ab_test_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  test_group public.ab_test_group NOT NULL,
  assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

-- Feed Performance Metrics
CREATE TABLE IF NOT EXISTS public.feed_performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_group public.ab_test_group NOT NULL,
  metric_date DATE NOT NULL,
  ctr FLOAT8 DEFAULT 0.0,
  engagement_rate FLOAT8 DEFAULT 0.0,
  avg_time_spent_seconds FLOAT8 DEFAULT 0.0,
  conversion_rate FLOAT8 DEFAULT 0.0,
  impressions_count INTEGER DEFAULT 0,
  clicks_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(test_group, metric_date)
);

-- Ranking Strategy Performance
CREATE TABLE IF NOT EXISTS public.ranking_strategy_performance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  strategy_name TEXT NOT NULL,
  test_group public.ab_test_group NOT NULL,
  avg_ranking_score FLOAT8 DEFAULT 0.0,
  user_satisfaction_score FLOAT8 DEFAULT 0.0,
  statistical_significance FLOAT8 DEFAULT 0.0,
  sample_size INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_ga4_events_user_id ON public.ga4_analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_ga4_events_type ON public.ga4_analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_ga4_events_synced ON public.ga4_analytics_events(is_synced);
CREATE INDEX IF NOT EXISTS idx_ga4_events_timestamp ON public.ga4_analytics_events(timestamp_micros);

CREATE INDEX IF NOT EXISTS idx_screen_views_user_id ON public.ga4_screen_views(user_id);
CREATE INDEX IF NOT EXISTS idx_screen_views_session ON public.ga4_screen_views(session_id);

CREATE INDEX IF NOT EXISTS idx_conversion_funnels_user_id ON public.ga4_conversion_funnels(user_id);
CREATE INDEX IF NOT EXISTS idx_conversion_funnels_stage ON public.ga4_conversion_funnels(funnel_stage);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON public.ga4_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_session_id ON public.ga4_sessions(session_id);

CREATE INDEX IF NOT EXISTS idx_embeddings_content ON public.content_embeddings(content_id, content_type);
CREATE INDEX IF NOT EXISTS idx_embeddings_type ON public.content_embeddings(content_type);

CREATE INDEX IF NOT EXISTS idx_taste_profiles_user_id ON public.user_taste_profiles(user_id);

CREATE INDEX IF NOT EXISTS idx_engagement_signals_user_id ON public.engagement_signals(user_id);
CREATE INDEX IF NOT EXISTS idx_engagement_signals_content ON public.engagement_signals(content_id, content_type);

CREATE INDEX IF NOT EXISTS idx_rankings_user_id ON public.personalized_rankings(user_id);
CREATE INDEX IF NOT EXISTS idx_rankings_content ON public.personalized_rankings(content_id, content_type);
CREATE INDEX IF NOT EXISTS idx_rankings_expires ON public.personalized_rankings(expires_at);

CREATE INDEX IF NOT EXISTS idx_cf_matrix_user_id ON public.collaborative_filtering_matrix(user_id);
CREATE INDEX IF NOT EXISTS idx_cf_matrix_content ON public.collaborative_filtering_matrix(content_id, content_type);

CREATE INDEX IF NOT EXISTS idx_similar_users_user_id ON public.similar_users(user_id);
CREATE INDEX IF NOT EXISTS idx_similar_users_similarity ON public.similar_users(similarity_score DESC);

CREATE INDEX IF NOT EXISTS idx_ab_assignments_user_id ON public.ab_test_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_ab_assignments_group ON public.ab_test_assignments(test_group);

CREATE INDEX IF NOT EXISTS idx_feed_metrics_group ON public.feed_performance_metrics(test_group);
CREATE INDEX IF NOT EXISTS idx_feed_metrics_date ON public.feed_performance_metrics(metric_date);

-- ============================================================
-- 6. FUNCTIONS
-- ============================================================

-- Calculate personalized ranking score
CREATE OR REPLACE FUNCTION public.calculate_ranking_score(
  p_semantic_score FLOAT8,
  p_collaborative_score FLOAT8,
  p_recency_boost FLOAT8,
  p_popularity_boost FLOAT8,
  p_diversity_penalty FLOAT8
)
RETURNS FLOAT8
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN (
    (p_semantic_score * 0.3) +
    (p_collaborative_score * 0.3) +
    (p_recency_boost * 0.2) +
    (p_popularity_boost * 0.1) -
    (p_diversity_penalty * 0.1)
  );
END;
$$;

-- Update user taste profile based on engagement
CREATE OR REPLACE FUNCTION public.update_user_taste_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.user_taste_profiles (user_id, preference_vector, engagement_history, last_updated)
  VALUES (
    NEW.user_id,
    jsonb_build_object('signal_type', NEW.signal_type, 'content_type', NEW.content_type),
    jsonb_build_array(jsonb_build_object(
      'content_id', NEW.content_id,
      'signal_type', NEW.signal_type,
      'timestamp', NEW.created_at
    )),
    CURRENT_TIMESTAMP
  )
  ON CONFLICT (user_id) DO UPDATE SET
    engagement_history = public.user_taste_profiles.engagement_history || jsonb_build_array(jsonb_build_object(
      'content_id', NEW.content_id,
      'signal_type', NEW.signal_type,
      'timestamp', NEW.created_at
    )),
    last_updated = CURRENT_TIMESTAMP;
  
  RETURN NEW;
END;
$$;

-- Sync offline analytics events
CREATE OR REPLACE FUNCTION public.sync_offline_analytics_events()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  synced_count INTEGER := 0;
BEGIN
  UPDATE public.ga4_analytics_events
  SET is_synced = true,
      synced_at = CURRENT_TIMESTAMP,
      sync_attempts = sync_attempts + 1
  WHERE is_synced = false
    AND sync_attempts < 3;
  
  GET DIAGNOSTICS synced_count = ROW_COUNT;
  RETURN synced_count;
END;
$$;

-- ============================================================
-- 7. ENABLE RLS
-- ============================================================

ALTER TABLE public.ga4_analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_screen_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_conversion_funnels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_user_properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_ecommerce_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_crash_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_taste_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.engagement_signals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personalized_rankings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaborative_filtering_matrix ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.similar_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ab_test_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ranking_strategy_performance ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 8. RLS POLICIES
-- ============================================================

-- GA4 Analytics Events
DROP POLICY IF EXISTS "users_manage_own_ga4_analytics_events" ON public.ga4_analytics_events;
CREATE POLICY "users_manage_own_ga4_analytics_events"
ON public.ga4_analytics_events
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Screen Views
DROP POLICY IF EXISTS "users_manage_own_ga4_screen_views" ON public.ga4_screen_views;
CREATE POLICY "users_manage_own_ga4_screen_views"
ON public.ga4_screen_views
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Conversion Funnels
DROP POLICY IF EXISTS "users_manage_own_ga4_conversion_funnels" ON public.ga4_conversion_funnels;
CREATE POLICY "users_manage_own_ga4_conversion_funnels"
ON public.ga4_conversion_funnels
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- User Properties
DROP POLICY IF EXISTS "users_manage_own_ga4_user_properties" ON public.ga4_user_properties;
CREATE POLICY "users_manage_own_ga4_user_properties"
ON public.ga4_user_properties
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Sessions
DROP POLICY IF EXISTS "users_manage_own_ga4_sessions" ON public.ga4_sessions;
CREATE POLICY "users_manage_own_ga4_sessions"
ON public.ga4_sessions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- E-commerce Transactions
DROP POLICY IF EXISTS "users_manage_own_ga4_ecommerce_transactions" ON public.ga4_ecommerce_transactions;
CREATE POLICY "users_manage_own_ga4_ecommerce_transactions"
ON public.ga4_ecommerce_transactions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Crash Reports
DROP POLICY IF EXISTS "users_manage_own_ga4_crash_reports" ON public.ga4_crash_reports;
CREATE POLICY "users_manage_own_ga4_crash_reports"
ON public.ga4_crash_reports
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Content Embeddings (public read, authenticated write)
DROP POLICY IF EXISTS "public_read_content_embeddings" ON public.content_embeddings;
CREATE POLICY "public_read_content_embeddings"
ON public.content_embeddings
FOR SELECT
TO public
USING (true);

DROP POLICY IF EXISTS "authenticated_write_content_embeddings" ON public.content_embeddings;
CREATE POLICY "authenticated_write_content_embeddings"
ON public.content_embeddings
FOR INSERT
TO authenticated
WITH CHECK (true);

-- User Taste Profiles
DROP POLICY IF EXISTS "users_manage_own_user_taste_profiles" ON public.user_taste_profiles;
CREATE POLICY "users_manage_own_user_taste_profiles"
ON public.user_taste_profiles
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Engagement Signals
DROP POLICY IF EXISTS "users_manage_own_engagement_signals" ON public.engagement_signals;
CREATE POLICY "users_manage_own_engagement_signals"
ON public.engagement_signals
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Personalized Rankings
DROP POLICY IF EXISTS "users_manage_own_personalized_rankings" ON public.personalized_rankings;
CREATE POLICY "users_manage_own_personalized_rankings"
ON public.personalized_rankings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Collaborative Filtering Matrix
DROP POLICY IF EXISTS "users_manage_own_collaborative_filtering_matrix" ON public.collaborative_filtering_matrix;
CREATE POLICY "users_manage_own_collaborative_filtering_matrix"
ON public.collaborative_filtering_matrix
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Similar Users
DROP POLICY IF EXISTS "users_view_own_similar_users" ON public.similar_users;
CREATE POLICY "users_view_own_similar_users"
ON public.similar_users
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- A/B Test Assignments
DROP POLICY IF EXISTS "users_view_own_ab_test_assignments" ON public.ab_test_assignments;
CREATE POLICY "users_view_own_ab_test_assignments"
ON public.ab_test_assignments
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Feed Performance Metrics (public read)
DROP POLICY IF EXISTS "public_read_feed_performance_metrics" ON public.feed_performance_metrics;
CREATE POLICY "public_read_feed_performance_metrics"
ON public.feed_performance_metrics
FOR SELECT
TO public
USING (true);

-- Ranking Strategy Performance (public read)
DROP POLICY IF EXISTS "public_read_ranking_strategy_performance" ON public.ranking_strategy_performance;
CREATE POLICY "public_read_ranking_strategy_performance"
ON public.ranking_strategy_performance
FOR SELECT
TO public
USING (true);

-- ============================================================
-- 9. TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS update_taste_profile_on_engagement ON public.engagement_signals;
CREATE TRIGGER update_taste_profile_on_engagement
  AFTER INSERT ON public.engagement_signals
  FOR EACH ROW
  EXECUTE FUNCTION public.update_user_taste_profile();

-- ============================================================
-- 10. MOCK DATA
-- ============================================================

DO $$
DECLARE
  existing_user_id UUID;
  test_session_id TEXT := 'session_' || gen_random_uuid()::TEXT;
  test_client_id TEXT := 'client_' || gen_random_uuid()::TEXT;
BEGIN
  -- Get existing user
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) THEN
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
    
    IF existing_user_id IS NOT NULL THEN
      -- Insert GA4 user properties
      INSERT INTO public.ga4_user_properties (
        user_id, subscription_tier, user_level, total_vp_balance,
        voting_frequency, preferred_categories, account_age_days,
        country, purchasing_power_zone
      ) VALUES (
        existing_user_id, 'premium', 5, 1500,
        'daily', ARRAY['politics', 'technology', 'sports'],
        30, 'US', 'US_Canada'::public.purchasing_power_zone
      )
      ON CONFLICT (user_id) DO NOTHING;

      -- Insert sample analytics events
      INSERT INTO public.ga4_analytics_events (
        user_id, event_type, event_name, event_params,
        session_id, client_id, timestamp_micros, is_synced
      ) VALUES
        (existing_user_id, 'vote_cast'::public.analytics_event_type, 'vote_cast',
         jsonb_build_object('election_id', gen_random_uuid(), 'category', 'politics'),
         test_session_id, test_client_id, EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::BIGINT * 1000000, true),
        (existing_user_id, 'quest_complete'::public.analytics_event_type, 'quest_complete',
         jsonb_build_object('quest_id', gen_random_uuid(), 'vp_earned', 100),
         test_session_id, test_client_id, EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::BIGINT * 1000000, true)
      ON CONFLICT (id) DO NOTHING;

      -- Insert session
      INSERT INTO public.ga4_sessions (
        user_id, session_id, session_start, screen_views_count, events_count
      ) VALUES (
        existing_user_id, test_session_id, CURRENT_TIMESTAMP, 5, 10
      )
      ON CONFLICT (session_id) DO NOTHING;

      -- Insert A/B test assignment
      INSERT INTO public.ab_test_assignments (user_id, test_group)
      VALUES (existing_user_id, 'algorithm_v1'::public.ab_test_group)
      ON CONFLICT (user_id) DO NOTHING;

      -- Insert user taste profile
      INSERT INTO public.user_taste_profiles (user_id, preference_vector)
      VALUES (
        existing_user_id,
        jsonb_build_object('politics', 0.8, 'technology', 0.6, 'sports', 0.4)
      )
      ON CONFLICT (user_id) DO NOTHING;

      RAISE NOTICE 'GA4 analytics and feed ranking mock data created successfully';
    ELSE
      RAISE NOTICE 'No users found in user_profiles';
    END IF;
  ELSE
    RAISE NOTICE 'Table user_profiles does not exist';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;