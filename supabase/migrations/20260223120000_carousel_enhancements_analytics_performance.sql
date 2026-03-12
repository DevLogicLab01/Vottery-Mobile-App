-- Carousel Enhancements: Analytics & Performance Monitoring Migration
-- Implements database schema for carousel interaction tracking, FPS monitoring, battery impact analysis

-- ============================================
-- FEATURE 3: CAROUSEL ANALYTICS TABLES
-- ============================================

-- Table: Carousel Interactions (Track all user interactions)
CREATE TABLE IF NOT EXISTS public.carousel_interactions (
  interaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  carousel_type VARCHAR(50) NOT NULL CHECK (carousel_type IN ('horizontal_snap', 'vertical_card_stack', 'gradient_flow')),
  content_type VARCHAR(50) NOT NULL CHECK (content_type IN ('jolts', 'moments', 'featured_elections', 'groups', 'recommended_elections', 'trending_topics', 'top_earners')),
  content_id UUID NOT NULL,
  interaction_type VARCHAR(50) NOT NULL CHECK (interaction_type IN ('swipe', 'view', 'tap', 'conversion')),
  swipe_direction VARCHAR(20) CHECK (swipe_direction IN ('left', 'right', 'up', 'down')),
  swipe_velocity DECIMAL(5,2),
  view_duration_seconds DECIMAL(6,2),
  scroll_position INTEGER,
  viewport_percentage DECIMAL(5,2),
  tap_location JSONB,
  action_taken VARCHAR(100),
  converted BOOLEAN DEFAULT false,
  interaction_timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_carousel_interactions_user ON public.carousel_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_carousel_interactions_type ON public.carousel_interactions(carousel_type, content_type);
CREATE INDEX IF NOT EXISTS idx_carousel_interactions_timestamp ON public.carousel_interactions(interaction_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_carousel_interactions_converted ON public.carousel_interactions(converted) WHERE converted = true;

-- Table: Carousel Performance Aggregated (Hourly metrics)
CREATE TABLE IF NOT EXISTS public.carousel_performance_aggregated (
  agg_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carousel_type VARCHAR(50) NOT NULL,
  content_type VARCHAR(50) NOT NULL,
  date DATE NOT NULL,
  hour INTEGER CHECK (hour >= 0 AND hour <= 23),
  total_views INTEGER DEFAULT 0,
  total_swipes INTEGER DEFAULT 0,
  total_conversions INTEGER DEFAULT 0,
  avg_view_duration DECIMAL(6,2) DEFAULT 0.0,
  engagement_rate DECIMAL(5,2) DEFAULT 0.0,
  conversion_rate DECIMAL(5,2) DEFAULT 0.0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(carousel_type, content_type, date, hour)
);

CREATE INDEX IF NOT EXISTS idx_carousel_agg_type_date ON public.carousel_performance_aggregated(carousel_type, date DESC);
CREATE INDEX IF NOT EXISTS idx_carousel_agg_date ON public.carousel_performance_aggregated(date DESC);

-- ============================================
-- FEATURE 2: PERFORMANCE MONITORING TABLES
-- ============================================

-- Table: FPS Performance Metrics
CREATE TABLE IF NOT EXISTS public.performance_metrics_fps (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  screen_name VARCHAR(100) NOT NULL,
  carousel_type VARCHAR(50),
  avg_fps DECIMAL(5,2) NOT NULL,
  frame_drops_count INTEGER DEFAULT 0,
  session_duration_seconds INTEGER,
  device_model VARCHAR(100),
  quality_level VARCHAR(20) CHECK (quality_level IN ('high', 'medium', 'low')),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fps_metrics_user ON public.performance_metrics_fps(user_id);
CREATE INDEX IF NOT EXISTS idx_fps_metrics_screen ON public.performance_metrics_fps(screen_name, carousel_type);
CREATE INDEX IF NOT EXISTS idx_fps_metrics_recorded ON public.performance_metrics_fps(recorded_at DESC);

-- Table: Battery Impact Metrics
CREATE TABLE IF NOT EXISTS public.battery_impact_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  carousel_type VARCHAR(50) NOT NULL,
  battery_drain_rate DECIMAL(5,2) NOT NULL,
  usage_duration_minutes INTEGER NOT NULL,
  device_model VARCHAR(100),
  quality_level VARCHAR(20) CHECK (quality_level IN ('high', 'medium', 'low')),
  battery_level_start INTEGER CHECK (battery_level_start >= 0 AND battery_level_start <= 100),
  battery_level_end INTEGER CHECK (battery_level_end >= 0 AND battery_level_end <= 100),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_battery_metrics_user ON public.battery_impact_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_battery_metrics_carousel ON public.battery_impact_metrics(carousel_type);
CREATE INDEX IF NOT EXISTS idx_battery_metrics_recorded ON public.battery_impact_metrics(recorded_at DESC);

-- Table: Performance Events (Alerts and anomalies)
CREATE TABLE IF NOT EXISTS public.performance_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('low_fps', 'high_battery_drain', 'thermal_throttle', 'quality_degradation')),
  severity VARCHAR(20) NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  device_info JSONB,
  metrics JSONB,
  action_taken VARCHAR(200),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_performance_events_user ON public.performance_events(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_events_type ON public.performance_events(event_type, severity);
CREATE INDEX IF NOT EXISTS idx_performance_events_created ON public.performance_events(created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE public.carousel_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_performance_aggregated ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_metrics_fps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.battery_impact_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_events ENABLE ROW LEVEL SECURITY;

-- Carousel Interactions Policies
DROP POLICY IF EXISTS "users_can_view_own_interactions" ON public.carousel_interactions;
CREATE POLICY "users_can_view_own_interactions" ON public.carousel_interactions
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_can_insert_own_interactions" ON public.carousel_interactions;
CREATE POLICY "users_can_insert_own_interactions" ON public.carousel_interactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Aggregated Performance Policies (viewable by all authenticated users)
DROP POLICY IF EXISTS "authenticated_users_view_aggregated_performance" ON public.carousel_performance_aggregated;
CREATE POLICY "authenticated_users_view_aggregated_performance" ON public.carousel_performance_aggregated
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- FPS Metrics Policies
DROP POLICY IF EXISTS "users_manage_own_fps_metrics" ON public.performance_metrics_fps;
CREATE POLICY "users_manage_own_fps_metrics" ON public.performance_metrics_fps
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Battery Impact Policies
DROP POLICY IF EXISTS "users_manage_own_battery_metrics" ON public.battery_impact_metrics;
CREATE POLICY "users_manage_own_battery_metrics" ON public.battery_impact_metrics
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Performance Events Policies
DROP POLICY IF EXISTS "users_manage_own_performance_events" ON public.performance_events;
CREATE POLICY "users_manage_own_performance_events" ON public.performance_events
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- FUNCTIONS FOR ANALYTICS
-- ============================================

-- Function: Calculate trending score for content
CREATE OR REPLACE FUNCTION public.calculate_trending_score(
  views_count INTEGER,
  engagement_count INTEGER,
  hours_since_created INTEGER
)
RETURNS DECIMAL(5,2)
LANGUAGE plpgsql
AS $$
DECLARE
  engagement_rate DECIMAL(5,2);
  recency_factor DECIMAL(5,2);
  trending_score DECIMAL(5,2);
BEGIN
  -- Calculate engagement rate (avoid division by zero)
  IF views_count > 0 THEN
    engagement_rate := (engagement_count::DECIMAL / views_count::DECIMAL) * 100;
  ELSE
    engagement_rate := 0.0;
  END IF;
  
  -- Calculate recency factor (decays over 7 days = 168 hours)
  recency_factor := 100.0 - ((hours_since_created::DECIMAL / 168.0) * 100.0);
  recency_factor := GREATEST(recency_factor, 0.0);
  
  -- Weighted algorithm: views (30%) + engagement (40%) + recency (30%)
  trending_score := (views_count * 0.3) + (engagement_rate * 0.4) + (recency_factor * 0.3);
  trending_score := LEAST(trending_score, 100.0);
  
  RETURN trending_score;
END;
$$;

-- ============================================
-- MOCK DATA FOR TESTING
-- ============================================

DO $$
DECLARE
  existing_user_id UUID;
  jolt_id UUID;
BEGIN
  -- Get existing user
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) THEN
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
    
    IF existing_user_id IS NOT NULL THEN
      -- Get existing jolt
      SELECT jolt_id INTO jolt_id FROM public.carousel_content_jolts LIMIT 1;
      
      IF jolt_id IS NOT NULL THEN
        -- Insert sample carousel interactions
        INSERT INTO public.carousel_interactions (
          user_id, carousel_type, content_type, content_id, 
          interaction_type, swipe_direction, view_duration_seconds, converted
        ) VALUES
          (existing_user_id, 'horizontal_snap', 'jolts', jolt_id, 'view', NULL, 15.5, false),
          (existing_user_id, 'horizontal_snap', 'jolts', jolt_id, 'swipe', 'left', NULL, false),
          (existing_user_id, 'horizontal_snap', 'jolts', jolt_id, 'tap', NULL, NULL, true)
        ON CONFLICT (interaction_id) DO NOTHING;
      END IF;
      
      -- Insert sample FPS metrics
      INSERT INTO public.performance_metrics_fps (
        user_id, screen_name, carousel_type, avg_fps, frame_drops_count, quality_level
      ) VALUES
        (existing_user_id, 'social_media_home_feed', 'horizontal_snap', 58.5, 12, 'high'),
        (existing_user_id, 'social_media_home_feed', 'vertical_card_stack', 60.0, 0, 'high')
      ON CONFLICT (metric_id) DO NOTHING;
      
      -- Insert sample battery metrics
      INSERT INTO public.battery_impact_metrics (
        user_id, carousel_type, battery_drain_rate, usage_duration_minutes, 
        quality_level, battery_level_start, battery_level_end
      ) VALUES
        (existing_user_id, 'horizontal_snap', 2.5, 30, 'high', 85, 80),
        (existing_user_id, 'gradient_flow', 1.8, 20, 'medium', 80, 78)
      ON CONFLICT (metric_id) DO NOTHING;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;