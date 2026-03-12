-- Migration: New features tables for 8 features implementation
-- Features: Prediction Analytics, VP Economy Monitor, Performance Monitoring, Adventure Paths, Mini-Games

-- Prediction pool analytics table
CREATE TABLE IF NOT EXISTS public.prediction_pool_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID,
  election_id UUID,
  total_predictions INTEGER DEFAULT 0,
  unique_predictors INTEGER DEFAULT 0,
  avg_brier_score DECIMAL(5,4) DEFAULT 0,
  total_vp_distributed BIGINT DEFAULT 0,
  participation_rate DECIMAL(5,2) DEFAULT 0,
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- VP Economy metrics table
CREATE TABLE IF NOT EXISTS public.vp_economy_metrics (
  metric_id DATE PRIMARY KEY DEFAULT CURRENT_DATE,
  total_vp_earned BIGINT DEFAULT 0,
  total_vp_spent BIGINT DEFAULT 0,
  circulation_velocity DECIMAL(5,4) DEFAULT 0,
  inflation_rate DECIMAL(5,2) DEFAULT 0,
  earning_spending_ratio DECIMAL(5,2) DEFAULT 1,
  zone_redemption_rates JSONB DEFAULT '{}',
  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

-- VP Economy incidents
CREATE TABLE IF NOT EXISTS public.vp_economy_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name TEXT NOT NULL,
  current_value TEXT,
  threshold_value TEXT,
  deviation DECIMAL(10,4),
  severity TEXT DEFAULT 'warning',
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- VP Zone redemptions
CREATE TABLE IF NOT EXISTS public.vp_zone_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_name TEXT NOT NULL,
  redemption_rate DECIMAL(5,2) DEFAULT 0,
  avg_vp_balance INTEGER DEFAULT 0,
  top_redemption_category TEXT,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Performance metrics table
CREATE TABLE IF NOT EXISTS public.performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_type TEXT NOT NULL, -- 'screen_load', 'memory', 'api'
  screen_name TEXT,
  avg_load_time INTEGER,
  p50 INTEGER,
  p95 INTEGER,
  p99 INTEGER,
  memory_mb INTEGER,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- API performance metrics
CREATE TABLE IF NOT EXISTS public.api_performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  endpoint_name TEXT NOT NULL,
  avg_latency INTEGER DEFAULT 0,
  p95 INTEGER DEFAULT 0,
  p99 INTEGER DEFAULT 0,
  request_count INTEGER DEFAULT 0,
  error_rate DECIMAL(5,2) DEFAULT 0,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crash analytics
CREATE TABLE IF NOT EXISTS public.crash_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crash_rate DECIMAL(8,4) DEFAULT 0,
  crashes_count INTEGER DEFAULT 0,
  sessions_count INTEGER DEFAULT 0,
  recorded_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crash causes
CREATE TABLE IF NOT EXISTS public.crash_causes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  crash_type TEXT NOT NULL,
  occurrence_count INTEGER DEFAULT 0,
  affected_screens TEXT,
  stack_trace_preview TEXT,
  first_seen TIMESTAMPTZ DEFAULT NOW(),
  last_seen TIMESTAMPTZ DEFAULT NOW()
);

-- Performance incidents
CREATE TABLE IF NOT EXISTS public.performance_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  metric_name TEXT NOT NULL,
  current_value TEXT,
  threshold_value TEXT,
  status TEXT DEFAULT 'active',
  severity TEXT DEFAULT 'warning',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- Performance thresholds
CREATE TABLE IF NOT EXISTS public.performance_thresholds (
  id TEXT PRIMARY KEY DEFAULT 'default',
  screen_load_threshold INTEGER DEFAULT 2000,
  memory_threshold INTEGER DEFAULT 500,
  api_p95_threshold INTEGER DEFAULT 3000,
  crash_rate_threshold DECIMAL(5,2) DEFAULT 1.0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User adventure paths
CREATE TABLE IF NOT EXISTS public.user_adventure_paths (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  path_name TEXT NOT NULL,
  theme_description TEXT,
  path_icon TEXT DEFAULT '\U0001F5FA',
  content_items JSONB DEFAULT '[]',
  completed_items INTEGER DEFAULT 0,
  is_started BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Adventure path analytics
CREATE TABLE IF NOT EXISTS public.adventure_path_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  path_id UUID,
  path_name TEXT,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  total_items INTEGER DEFAULT 0,
  time_to_complete_hours DECIMAL(8,2)
);

-- Feed mini-game completions
CREATE TABLE IF NOT EXISTS public.feed_mini_game_completions (
  completion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  game_type VARCHAR(50) NOT NULL, -- 'quick_poll', 'jolts_guess', 'quiz'
  was_correct BOOLEAN DEFAULT FALSE,
  vp_earned INTEGER DEFAULT 0,
  completed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mini_games ON public.feed_mini_game_completions (user_id, completed_at);
CREATE INDEX IF NOT EXISTS idx_adventure_paths_user ON public.user_adventure_paths (user_id);
CREATE INDEX IF NOT EXISTS idx_performance_metrics_type ON public.performance_metrics (metric_type, recorded_at);

-- User notification preferences (for prediction pool webhooks)
CREATE TABLE IF NOT EXISTS public.user_notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  prediction_pool_notifications_enabled BOOLEAN DEFAULT TRUE,
  countdown_reminders_enabled BOOLEAN DEFAULT TRUE,
  leaderboard_alerts_enabled BOOLEAN DEFAULT TRUE,
  notification_channels JSONB DEFAULT '{"push_notification": true, "email": false, "sms": false}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.user_adventure_paths ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feed_mini_game_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own adventure paths" ON public.user_adventure_paths;
CREATE POLICY "Users can manage own adventure paths"
  ON public.user_adventure_paths
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own mini game completions" ON public.feed_mini_game_completions;
CREATE POLICY "Users can manage own mini game completions"
  ON public.feed_mini_game_completions
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own notification preferences" ON public.user_notification_preferences;
CREATE POLICY "Users can manage own notification preferences"
  ON public.user_notification_preferences
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Admin read access for analytics tables
ALTER TABLE public.performance_metrics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin read performance metrics" ON public.performance_metrics;
CREATE POLICY "Admin read performance metrics"
  ON public.performance_metrics
  FOR SELECT
  USING (TRUE);

ALTER TABLE public.prediction_pool_analytics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admin read prediction analytics" ON public.prediction_pool_analytics;
CREATE POLICY "Admin read prediction analytics"
  ON public.prediction_pool_analytics
  FOR SELECT
  USING (TRUE);
