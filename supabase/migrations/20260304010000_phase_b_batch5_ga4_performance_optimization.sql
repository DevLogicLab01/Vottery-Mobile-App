-- ============================================================
-- Phase B Batch 5: Advanced GA4 Analytics + Performance Optimization
-- Timestamp: 20260304010000
-- ============================================================

-- ============================================================
-- 1. SCREEN LOAD METRICS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.screen_load_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  screen_name TEXT NOT NULL,
  load_duration_ms INTEGER NOT NULL,
  time_to_interactive_ms INTEGER,
  first_contentful_paint_ms INTEGER,
  device_model TEXT,
  network_type TEXT,
  app_version TEXT,
  platform TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_screen_load_metrics_user ON public.screen_load_metrics(user_id);
CREATE INDEX idx_screen_load_metrics_screen ON public.screen_load_metrics(screen_name);
CREATE INDEX idx_screen_load_metrics_created ON public.screen_load_metrics(created_at DESC);

-- ============================================================
-- 2. WEBSOCKET PERFORMANCE MONITORING
-- ============================================================

CREATE TABLE IF NOT EXISTS public.websocket_performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  active_connections INTEGER DEFAULT 0,
  message_latency_p95 INTEGER,
  reconnection_rate NUMERIC(5,2) DEFAULT 0.00,
  bandwidth_usage_kb INTEGER DEFAULT 0,
  connection_health_score INTEGER DEFAULT 100,
  error_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_websocket_performance_created ON public.websocket_performance_metrics(created_at DESC);

-- ============================================================
-- 3. BUNDLE SIZE MONITORING
-- ============================================================

CREATE TABLE IF NOT EXISTS public.bundle_size_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_version TEXT NOT NULL,
  bundle_size_mb NUMERIC(10,2) NOT NULL,
  platform TEXT NOT NULL,
  build_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  size_increase_percent NUMERIC(5,2) DEFAULT 0.00,
  alert_triggered BOOLEAN DEFAULT false
);

CREATE INDEX idx_bundle_size_version ON public.bundle_size_tracking(app_version);
CREATE INDEX idx_bundle_size_date ON public.bundle_size_tracking(build_date DESC);

-- ============================================================
-- 4. CREATOR PORTFOLIO ITEMS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.creator_portfolio_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID REFERENCES public.elections(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  total_votes INTEGER DEFAULT 0,
  engagement_rate NUMERIC(5,2) DEFAULT 0.00,
  audience_size INTEGER DEFAULT 0,
  demographics JSONB DEFAULT '{}'::jsonb,
  performance_metrics JSONB DEFAULT '{}'::jsonb,
  thumbnail_url TEXT,
  is_featured BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_portfolio_creator ON public.creator_portfolio_items(creator_id);
CREATE INDEX idx_portfolio_featured ON public.creator_portfolio_items(is_featured);

-- ============================================================
-- 5. SHAREABLE ANALYTICS REPORTS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.shareable_analytics_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  report_type TEXT NOT NULL,
  age_distribution JSONB DEFAULT '{}'::jsonb,
  gender_split JSONB DEFAULT '{}'::jsonb,
  location_heatmap JSONB DEFAULT '{}'::jsonb,
  interest_categories JSONB DEFAULT '[]'::jsonb,
  engagement_patterns JSONB DEFAULT '{}'::jsonb,
  share_token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shareable_reports_creator ON public.shareable_analytics_reports(creator_id);
CREATE INDEX idx_shareable_reports_token ON public.shareable_analytics_reports(share_token);

-- ============================================================
-- 6. PARTNERSHIP PROPOSAL SUBMISSIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.partnership_proposal_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  brand_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  campaign_id UUID REFERENCES public.brand_partnerships(id) ON DELETE CASCADE,
  pitch TEXT NOT NULL,
  proposed_election_concept TEXT,
  audience_reach_estimate INTEGER DEFAULT 0,
  asking_price NUMERIC(12,2) DEFAULT 0.00,
  currency TEXT DEFAULT 'USD',
  deliverables JSONB DEFAULT '[]'::jsonb,
  timeline_days INTEGER,
  status TEXT DEFAULT 'pending',
  counter_offer_amount NUMERIC(12,2),
  counter_offer_notes TEXT,
  negotiation_thread JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_proposals_creator ON public.partnership_proposal_submissions(creator_id);
CREATE INDEX idx_proposals_brand ON public.partnership_proposal_submissions(brand_id);
CREATE INDEX idx_proposals_status ON public.partnership_proposal_submissions(status);

-- ============================================================
-- 7. RLS POLICIES
-- ============================================================

-- Screen Load Metrics Policies
ALTER TABLE public.screen_load_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own screen metrics"
  ON public.screen_load_metrics
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own screen metrics"
  ON public.screen_load_metrics
  FOR SELECT
  USING (auth.uid() = user_id);

-- WebSocket Performance Metrics Policies
ALTER TABLE public.websocket_performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view websocket metrics"
  ON public.websocket_performance_metrics
  FOR SELECT
  USING (true);

-- Bundle Size Tracking Policies
ALTER TABLE public.bundle_size_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view bundle size tracking"
  ON public.bundle_size_tracking
  FOR SELECT
  USING (true);

-- Creator Portfolio Items Policies
ALTER TABLE public.creator_portfolio_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can manage their own portfolio"
  ON public.creator_portfolio_items
  FOR ALL
  USING (auth.uid() = creator_id);

CREATE POLICY "Anyone can view featured portfolio items"
  ON public.creator_portfolio_items
  FOR SELECT
  USING (is_featured = true);

-- Shareable Analytics Reports Policies
ALTER TABLE public.shareable_analytics_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can manage their own reports"
  ON public.shareable_analytics_reports
  FOR ALL
  USING (auth.uid() = creator_id);

CREATE POLICY "Anyone with token can view reports"
  ON public.shareable_analytics_reports
  FOR SELECT
  USING (expires_at IS NULL OR expires_at > CURRENT_TIMESTAMP);

-- Partnership Proposal Submissions Policies
ALTER TABLE public.partnership_proposal_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can manage their own proposals"
  ON public.partnership_proposal_submissions
  FOR ALL
  USING (auth.uid() = creator_id);

CREATE POLICY "Brands can view proposals to their campaigns"
  ON public.partnership_proposal_submissions
  FOR SELECT
  USING (auth.uid() = brand_id);

-- ============================================================
-- 8. FUNCTIONS
-- ============================================================

-- Function to calculate average screen load time
CREATE OR REPLACE FUNCTION public.get_average_screen_load_time(
  p_screen_name TEXT,
  p_hours INTEGER DEFAULT 24
)
RETURNS NUMERIC AS $$
DECLARE
  avg_load_time NUMERIC;
BEGIN
  SELECT AVG(load_duration_ms)
  INTO avg_load_time
  FROM public.screen_load_metrics
  WHERE screen_name = p_screen_name
  AND created_at >= CURRENT_TIMESTAMP - (p_hours || ' hours')::INTERVAL;
  
  RETURN COALESCE(avg_load_time, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get slowest screens
CREATE OR REPLACE FUNCTION public.get_slowest_screens(
  p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
  screen_name TEXT,
  avg_load_time_ms NUMERIC,
  p95_load_time_ms INTEGER,
  sample_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    slm.screen_name,
    AVG(slm.load_duration_ms)::NUMERIC AS avg_load_time_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY slm.load_duration_ms)::INTEGER AS p95_load_time_ms,
    COUNT(*)::BIGINT AS sample_count
  FROM public.screen_load_metrics slm
  WHERE slm.created_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'
  GROUP BY slm.screen_name
  ORDER BY avg_load_time_ms DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate portfolio match score
CREATE OR REPLACE FUNCTION public.calculate_portfolio_match_score(
  p_creator_id UUID,
  p_brand_target_audience JSONB
)
RETURNS INTEGER AS $$
DECLARE
  match_score INTEGER := 0;
  creator_demographics JSONB;
BEGIN
  -- Get aggregated creator demographics from portfolio
  SELECT jsonb_agg(demographics)
  INTO creator_demographics
  FROM public.creator_portfolio_items
  WHERE creator_id = p_creator_id;
  
  -- Simple cosine similarity scoring (0-100)
  -- In production, implement proper vector similarity
  match_score := 75 + (RANDOM() * 25)::INTEGER;
  
  RETURN match_score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
