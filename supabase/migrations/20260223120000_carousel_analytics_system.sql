-- Carousel Analytics System Migration
-- Implements comprehensive tracking for carousel interactions, performance, and analytics

-- ============================================
-- CAROUSEL INTERACTIONS TRACKING
-- ============================================

CREATE TABLE IF NOT EXISTS public.carousel_interactions (
  interaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  carousel_type VARCHAR(50) NOT NULL CHECK (carousel_type IN ('horizontal_snap', 'kinetic_spindle', 'isometric_deck', 'gradient_flow')),
  content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('jolts', 'moments', 'groups', 'elections', 'topics', 'earners')),
  content_id UUID NOT NULL,
  interaction_type VARCHAR(50) NOT NULL CHECK (interaction_type IN ('swipe', 'view', 'tap', 'conversion')),
  swipe_direction VARCHAR(20) CHECK (swipe_direction IN ('left', 'right', 'up', 'down')),
  swipe_velocity DECIMAL(5,2),
  view_duration_seconds DECIMAL(6,2),
  converted BOOLEAN DEFAULT false,
  interaction_timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_carousel_interactions_user ON public.carousel_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_carousel_interactions_carousel_type ON public.carousel_interactions(carousel_type);
CREATE INDEX IF NOT EXISTS idx_carousel_interactions_content ON public.carousel_interactions(content_type, content_id);
CREATE INDEX IF NOT EXISTS idx_carousel_interactions_timestamp ON public.carousel_interactions(interaction_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_carousel_interactions_type ON public.carousel_interactions(interaction_type);

-- ============================================
-- PERFORMANCE METRICS - FPS TRACKING
-- ============================================

CREATE TABLE IF NOT EXISTS public.performance_metrics_fps (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name VARCHAR(100) NOT NULL,
  carousel_type VARCHAR(50) NOT NULL,
  avg_fps DECIMAL(5,2) NOT NULL CHECK (avg_fps >= 0 AND avg_fps <= 120),
  frame_drops_count INTEGER DEFAULT 0,
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_performance_fps_screen ON public.performance_metrics_fps(screen_name);
CREATE INDEX IF NOT EXISTS idx_performance_fps_carousel ON public.performance_metrics_fps(carousel_type);
CREATE INDEX IF NOT EXISTS idx_performance_fps_recorded ON public.performance_metrics_fps(recorded_at DESC);

-- ============================================
-- BATTERY IMPACT METRICS
-- ============================================

CREATE TABLE IF NOT EXISTS public.battery_impact_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50) NOT NULL,
  battery_drain_rate DECIMAL(5,2) NOT NULL,
  usage_duration_minutes INTEGER NOT NULL CHECK (usage_duration_minutes > 0),
  device_model VARCHAR(100),
  quality_level VARCHAR(20) CHECK (quality_level IN ('high', 'medium', 'low', 'auto')),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_battery_impact_carousel ON public.battery_impact_metrics(carousel_type);
CREATE INDEX IF NOT EXISTS idx_battery_impact_device ON public.battery_impact_metrics(device_model);
CREATE INDEX IF NOT EXISTS idx_battery_impact_recorded ON public.battery_impact_metrics(recorded_at DESC);

-- ============================================
-- CAROUSEL PERFORMANCE AGGREGATED
-- ============================================

CREATE TABLE IF NOT EXISTS public.carousel_performance_aggregated (
  agg_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50) NOT NULL,
  content_type VARCHAR(50) NOT NULL,
  date DATE NOT NULL,
  total_views INTEGER DEFAULT 0,
  total_swipes INTEGER DEFAULT 0,
  total_conversions INTEGER DEFAULT 0,
  avg_view_duration DECIMAL(6,2) DEFAULT 0.0,
  engagement_rate DECIMAL(5,2) DEFAULT 0.0,
  conversion_rate DECIMAL(5,2) DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(carousel_type, content_type, date)
);

CREATE INDEX IF NOT EXISTS idx_carousel_agg_carousel_type ON public.carousel_performance_aggregated(carousel_type);
CREATE INDEX IF NOT EXISTS idx_carousel_agg_content_type ON public.carousel_performance_aggregated(content_type);
CREATE INDEX IF NOT EXISTS idx_carousel_agg_date ON public.carousel_performance_aggregated(date DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

ALTER TABLE public.carousel_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_metrics_fps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.battery_impact_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_performance_aggregated ENABLE ROW LEVEL SECURITY;

-- Carousel Interactions Policies
CREATE POLICY "Users can view their own interactions" ON public.carousel_interactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own interactions" ON public.carousel_interactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Admins can view all interactions" ON public.carousel_interactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Performance Metrics FPS Policies
CREATE POLICY "Anyone can insert FPS metrics" ON public.performance_metrics_fps
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can view FPS metrics" ON public.performance_metrics_fps
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Battery Impact Metrics Policies
CREATE POLICY "Anyone can insert battery metrics" ON public.battery_impact_metrics
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Admins can view battery metrics" ON public.battery_impact_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Carousel Performance Aggregated Policies
CREATE POLICY "Admins can view aggregated performance" ON public.carousel_performance_aggregated
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can insert aggregated performance" ON public.carousel_performance_aggregated
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "System can update aggregated performance" ON public.carousel_performance_aggregated
  FOR UPDATE USING (auth.uid() IS NOT NULL);

-- ============================================
-- HELPER FUNCTIONS FOR ANALYTICS
-- ============================================

-- Function: Get engagement summary
CREATE OR REPLACE FUNCTION public.get_engagement_summary(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'total_swipes', COUNT(*) FILTER (WHERE interaction_type = 'swipe'),
    'total_views', COUNT(*) FILTER (WHERE interaction_type = 'view'),
    'total_conversions', COUNT(*) FILTER (WHERE interaction_type = 'conversion'),
    'avg_view_duration', AVG(view_duration_seconds) FILTER (WHERE interaction_type = 'view'),
    'conversion_rate', 
      CASE 
        WHEN COUNT(*) FILTER (WHERE interaction_type = 'view') > 0 THEN
          (COUNT(*) FILTER (WHERE interaction_type = 'conversion')::DECIMAL / 
           COUNT(*) FILTER (WHERE interaction_type = 'view')::DECIMAL * 100)
        ELSE 0
      END
  )
  INTO v_result
  FROM public.carousel_interactions
  WHERE interaction_timestamp >= p_start_date
    AND interaction_timestamp <= p_end_date;

  RETURN v_result;
END;
$$;

-- Function: Get conversion funnel
CREATE OR REPLACE FUNCTION public.get_conversion_funnel(
  p_carousel_type VARCHAR
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'views', COUNT(*) FILTER (WHERE interaction_type = 'view'),
    'interactions', COUNT(*) FILTER (WHERE interaction_type IN ('swipe', 'tap')),
    'conversions', COUNT(*) FILTER (WHERE interaction_type = 'conversion')
  )
  INTO v_result
  FROM public.carousel_interactions
  WHERE carousel_type = p_carousel_type
    AND interaction_timestamp >= NOW() - INTERVAL '7 days';

  RETURN v_result;
END;
$$;

-- Function: Get top performing content
CREATE OR REPLACE FUNCTION public.get_top_performing_content(
  p_content_type VARCHAR,
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  content_id UUID,
  views_count BIGINT,
  interactions_count BIGINT,
  conversions_count BIGINT,
  engagement_rate DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ci.content_id,
    COUNT(*) FILTER (WHERE ci.interaction_type = 'view') AS views_count,
    COUNT(*) FILTER (WHERE ci.interaction_type IN ('swipe', 'tap')) AS interactions_count,
    COUNT(*) FILTER (WHERE ci.interaction_type = 'conversion') AS conversions_count,
    CASE 
      WHEN COUNT(*) FILTER (WHERE ci.interaction_type = 'view') > 0 THEN
        (COUNT(*) FILTER (WHERE ci.interaction_type IN ('swipe', 'tap', 'conversion'))::DECIMAL / 
         COUNT(*) FILTER (WHERE ci.interaction_type = 'view')::DECIMAL * 100)
      ELSE 0
    END AS engagement_rate
  FROM public.carousel_interactions ci
  WHERE ci.content_type = p_content_type
    AND ci.interaction_timestamp >= NOW() - INTERVAL '7 days'
  GROUP BY ci.content_id
  ORDER BY engagement_rate DESC, views_count DESC
  LIMIT p_limit;
END;
$$;

-- ============================================
-- MATERIALIZED VIEW FOR AGGREGATED METRICS
-- ============================================

CREATE MATERIALIZED VIEW IF NOT EXISTS public.carousel_metrics_daily AS
SELECT 
  carousel_type,
  content_type,
  DATE(interaction_timestamp) as date,
  COUNT(*) FILTER (WHERE interaction_type = 'view') as total_views,
  COUNT(*) FILTER (WHERE interaction_type = 'swipe') as total_swipes,
  COUNT(*) FILTER (WHERE interaction_type = 'conversion') as total_conversions,
  AVG(view_duration_seconds) FILTER (WHERE interaction_type = 'view') as avg_view_duration,
  CASE 
    WHEN COUNT(*) FILTER (WHERE interaction_type = 'view') > 0 THEN
      (COUNT(*) FILTER (WHERE interaction_type IN ('swipe', 'tap'))::DECIMAL / 
       COUNT(*) FILTER (WHERE interaction_type = 'view')::DECIMAL * 100)
    ELSE 0
  END as engagement_rate,
  CASE 
    WHEN COUNT(*) FILTER (WHERE interaction_type = 'view') > 0 THEN
      (COUNT(*) FILTER (WHERE interaction_type = 'conversion')::DECIMAL / 
       COUNT(*) FILTER (WHERE interaction_type = 'view')::DECIMAL * 100)
    ELSE 0
  END as conversion_rate
FROM public.carousel_interactions
GROUP BY carousel_type, content_type, DATE(interaction_timestamp);

CREATE UNIQUE INDEX IF NOT EXISTS idx_carousel_metrics_daily_unique 
  ON public.carousel_metrics_daily(carousel_type, content_type, date);

-- Refresh materialized view function (call hourly via cron)
CREATE OR REPLACE FUNCTION public.refresh_carousel_metrics()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.carousel_metrics_daily;
END;
$$;
