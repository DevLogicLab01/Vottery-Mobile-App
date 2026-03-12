-- =====================================================
-- CAROUSEL ENTERPRISE FEATURES COMPLETE MIGRATION
-- Features: Real-Time Monitoring, Feed Orchestration, Creator Studio, 
-- ROI Analytics, Marketplace, Claude Agent, Community, Forecasting, 
-- Perplexity Intelligence, Health Dashboard
-- =====================================================

-- ============================================================================
-- SCHEMA ENHANCEMENTS: Add missing columns to existing tables
-- ============================================================================

-- Add creator_user_id to carousel_interactions if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'carousel_interactions' 
        AND column_name = 'creator_user_id'
    ) THEN
        ALTER TABLE public.carousel_interactions 
        ADD COLUMN creator_user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL;
        
        CREATE INDEX IF NOT EXISTS idx_carousel_interactions_creator 
        ON public.carousel_interactions(creator_user_id);
    END IF;
END $$;

-- ============================================================================
-- FEATURE 1: REAL-TIME CAROUSEL MONITORING HUB
-- ============================================================================

-- Real-time metrics tracking
CREATE TABLE IF NOT EXISTS carousel_realtime_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carousel_type VARCHAR(50) NOT NULL CHECK (carousel_type IN ('horizontal','vertical','gradient')),
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(10,2) NOT NULL,
    user_segment JSONB,
    geographic_zone VARCHAR(20),
    device_type VARCHAR(20),
    recorded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_metrics_carousel_time ON carousel_realtime_metrics(carousel_type, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_metrics_name_time ON carousel_realtime_metrics(metric_name, recorded_at DESC);

-- Performance snapshots
CREATE TABLE IF NOT EXISTS carousel_performance_snapshots (
    snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carousel_type VARCHAR(50) NOT NULL,
    content_type VARCHAR(50),
    swipes_per_second DECIMAL(5,2),
    engagement_rate DECIMAL(5,2) CHECK (engagement_rate >= 0 AND engagement_rate <= 100),
    conversion_rate DECIMAL(5,2) CHECK (conversion_rate >= 0 AND engagement_rate <= 100),
    revenue DECIMAL(10,2) DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    snapshot_time TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_snapshots_type_time ON carousel_performance_snapshots(carousel_type, snapshot_time DESC);

-- Active carousel sessions
CREATE TABLE IF NOT EXISTS active_carousel_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    carousel_type VARCHAR(50) NOT NULL,
    session_started TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    last_activity TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    interactions_count INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON active_carousel_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_activity ON active_carousel_sessions(last_activity DESC);

-- Engagement heatmap materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS carousel_engagement_by_time AS
SELECT 
    EXTRACT(DOW FROM interaction_timestamp) as day_of_week,
    EXTRACT(HOUR FROM interaction_timestamp) as hour_of_day,
    carousel_type,
    AVG(CASE WHEN interaction_type IN ('swipe_right','tap','hold') THEN 1 ELSE 0 END) * 100 as engagement_rate,
    COUNT(DISTINCT user_id) as user_count
FROM carousel_interactions
WHERE interaction_timestamp >= NOW() - INTERVAL '7 days'
GROUP BY day_of_week, hour_of_day, carousel_type;

CREATE UNIQUE INDEX IF NOT EXISTS idx_engagement_heatmap ON carousel_engagement_by_time(day_of_week, hour_of_day, carousel_type);

-- ============================================================================
-- FEATURE 2: FEED ORCHESTRATION ENGINE
-- ============================================================================

-- Content orchestration scores
CREATE TABLE IF NOT EXISTS content_orchestration_scores (
    score_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL,
    content_type VARCHAR(50) NOT NULL,
    base_engagement_score DECIMAL(5,2),
    recency_score DECIMAL(5,2),
    social_proof_score DECIMAL(5,2),
    personalization_score DECIMAL(5,2),
    diversity_penalty DECIMAL(5,2),
    viral_boost_score DECIMAL(5,2),
    final_score DECIMAL(6,2) NOT NULL,
    assigned_carousel VARCHAR(50),
    position_in_carousel INTEGER,
    scored_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_scores_content ON content_orchestration_scores(content_id, content_type);
CREATE INDEX IF NOT EXISTS idx_scores_carousel ON content_orchestration_scores(assigned_carousel, final_score DESC);
CREATE INDEX IF NOT EXISTS idx_scores_expires ON content_orchestration_scores(expires_at);

-- Feed sequence state per user
CREATE TABLE IF NOT EXISTS feed_sequence_state (
    state_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES user_profiles(id) ON DELETE CASCADE,
    current_sequence_position INTEGER DEFAULT 0,
    last_carousel_type VARCHAR(50),
    carousel_rotation_queue JSONB,
    last_updated TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feed_state_user ON feed_sequence_state(user_id);

-- Orchestration performance metrics
CREATE TABLE IF NOT EXISTS orchestration_performance_metrics (
    metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    time_period TIMESTAMPTZ NOT NULL,
    carousel_type VARCHAR(50),
    content_type VARCHAR(50),
    avg_final_score DECIMAL(6,2),
    total_impressions BIGINT,
    total_engagements BIGINT,
    engagement_rate DECIMAL(5,2),
    revenue_generated DECIMAL(10,2)
);

CREATE INDEX IF NOT EXISTS idx_perf_metrics_time ON orchestration_performance_metrics(time_period DESC);

-- ============================================================================
-- FEATURE 3: CREATOR OPTIMIZATION STUDIO
-- ============================================================================

-- Creator carousel analytics
CREATE TABLE IF NOT EXISTS creator_carousel_analytics (
    analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    content_id UUID,
    carousel_type VARCHAR(50),
    swipe_left_count INTEGER DEFAULT 0,
    swipe_right_count INTEGER DEFAULT 0,
    swipe_velocity_avg DECIMAL(6,2),
    engagement_time_avg INTEGER,
    conversion_count INTEGER DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0,
    analyzed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_creator_analytics_user ON creator_carousel_analytics(creator_user_id, analyzed_at DESC);
CREATE INDEX IF NOT EXISTS idx_creator_analytics_content ON creator_carousel_analytics(content_id);

-- AI optimization recommendations
CREATE TABLE IF NOT EXISTS creator_optimization_recommendations (
    recommendation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    recommendation_category VARCHAR(50) NOT NULL,
    recommendation_text TEXT NOT NULL,
    priority VARCHAR(20) CHECK (priority IN ('high','medium','low')),
    expected_impact VARCHAR(100),
    action_items JSONB,
    generated_by VARCHAR(50) DEFAULT 'claude',
    generated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    implemented BOOLEAN DEFAULT false,
    implemented_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_recommendations_creator ON creator_optimization_recommendations(creator_user_id, generated_at DESC);

-- Creator engagement by time materialized view
CREATE MATERIALIZED VIEW IF NOT EXISTS creator_engagement_by_time AS
SELECT 
    ci.creator_user_id,
    EXTRACT(DOW FROM ci.interaction_timestamp) as day_of_week,
    EXTRACT(HOUR FROM ci.interaction_timestamp) as hour_of_day,
    ci.carousel_type,
    AVG(CASE WHEN ci.interaction_type IN ('swipe_right','tap','hold') THEN 1 ELSE 0 END) * 100 as engagement_rate,
    COUNT(DISTINCT ci.user_id) as user_count
FROM carousel_interactions ci
WHERE ci.interaction_timestamp >= NOW() - INTERVAL '30 days' AND ci.creator_user_id IS NOT NULL
GROUP BY ci.creator_user_id, day_of_week, hour_of_day, ci.carousel_type;

CREATE UNIQUE INDEX IF NOT EXISTS idx_creator_engagement_heatmap ON creator_engagement_by_time(creator_user_id, day_of_week, hour_of_day, carousel_type);

-- ============================================================================
-- FEATURE 4: ADVANCED CAROUSEL ROI ANALYTICS
-- ============================================================================

-- ROI analytics by zone
CREATE TABLE IF NOT EXISTS carousel_roi_analytics (
    roi_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carousel_type VARCHAR(50) NOT NULL,
    content_type VARCHAR(50),
    purchasing_power_zone INTEGER CHECK (purchasing_power_zone BETWEEN 1 AND 8),
    time_period TIMESTAMPTZ NOT NULL,
    impressions BIGINT DEFAULT 0,
    engagements BIGINT DEFAULT 0,
    conversions BIGINT DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0,
    ad_spend DECIMAL(10,2) DEFAULT 0,
    roi_percentage DECIMAL(6,2),
    creator_payouts DECIMAL(10,2) DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_roi_carousel_zone ON carousel_roi_analytics(carousel_type, purchasing_power_zone, time_period DESC);

-- Sponsorship performance
CREATE TABLE IF NOT EXISTS carousel_sponsorship_performance (
    sponsorship_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carousel_type VARCHAR(50) NOT NULL,
    sponsor_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
    campaign_name VARCHAR(200),
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    budget DECIMAL(10,2),
    spent DECIMAL(10,2) DEFAULT 0,
    impressions BIGINT DEFAULT 0,
    clicks BIGINT DEFAULT 0,
    conversions BIGINT DEFAULT 0,
    revenue_generated DECIMAL(10,2) DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_sponsorship_carousel ON carousel_sponsorship_performance(carousel_type, start_date DESC);

-- ============================================================================
-- FEATURE 5: CREATOR CAROUSEL MARKETPLACE
-- ============================================================================

-- Marketplace service listings
CREATE TABLE IF NOT EXISTS creator_carousel_marketplace_services (
    service_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    service_title VARCHAR(200) NOT NULL,
    service_description TEXT,
    service_type VARCHAR(50) CHECK (service_type IN ('sponsored_content','collaboration','exclusive_access','consultation')),
    carousel_type VARCHAR(50),
    pricing_tier JSONB,
    deliverables JSONB,
    availability_status VARCHAR(20) DEFAULT 'available',
    total_bookings INTEGER DEFAULT 0,
    average_rating DECIMAL(3,2),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_marketplace_creator ON creator_carousel_marketplace_services(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_type ON creator_carousel_marketplace_services(service_type, availability_status);

-- Marketplace bookings
CREATE TABLE IF NOT EXISTS carousel_marketplace_bookings (
    booking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES creator_carousel_marketplace_services(service_id) ON DELETE CASCADE,
    buyer_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    booking_status VARCHAR(20) DEFAULT 'pending' CHECK (booking_status IN ('pending','confirmed','in_progress','completed','cancelled')),
    amount DECIMAL(10,2) NOT NULL,
    payment_status VARCHAR(20) DEFAULT 'pending',
    booked_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_bookings_service ON carousel_marketplace_bookings(service_id, booking_status);
CREATE INDEX IF NOT EXISTS idx_bookings_buyer ON carousel_marketplace_bookings(buyer_user_id);

-- ============================================================================
-- FEATURE 6: CLAUDE CREATOR SUCCESS AGENT
-- ============================================================================

-- Creator health monitoring
CREATE TABLE IF NOT EXISTS creator_health_monitoring (
    monitoring_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    health_score DECIMAL(5,2) CHECK (health_score >= 0 AND health_score <= 100),
    engagement_trend VARCHAR(20),
    revenue_trend VARCHAR(20),
    churn_risk_score DECIMAL(5,2),
    at_risk BOOLEAN DEFAULT false,
    last_analyzed TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    claude_recommendations JSONB
);

CREATE INDEX IF NOT EXISTS idx_creator_health_user ON creator_health_monitoring(creator_user_id, last_analyzed DESC);
CREATE INDEX IF NOT EXISTS idx_creator_health_risk ON creator_health_monitoring(at_risk, churn_risk_score DESC);

-- Claude agent interventions
CREATE TABLE IF NOT EXISTS claude_agent_interventions (
    intervention_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    intervention_type VARCHAR(50) NOT NULL,
    trigger_reason TEXT,
    claude_analysis JSONB,
    recommended_actions JSONB,
    intervention_status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_interventions_creator ON claude_agent_interventions(creator_user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_interventions_status ON claude_agent_interventions(intervention_status);

-- ============================================================================
-- FEATURE 7: CREATOR COMMUNITY HUB
-- ============================================================================

-- Community forums
CREATE TABLE IF NOT EXISTS creator_community_forums (
    forum_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    forum_title VARCHAR(200) NOT NULL,
    forum_description TEXT,
    category VARCHAR(50),
    created_by UUID REFERENCES user_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    post_count INTEGER DEFAULT 0,
    member_count INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_forums_category ON creator_community_forums(category, created_at DESC);

-- Forum posts
CREATE TABLE IF NOT EXISTS creator_community_posts (
    post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    forum_id UUID NOT NULL REFERENCES creator_community_forums(forum_id) ON DELETE CASCADE,
    author_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    post_title VARCHAR(200),
    post_content TEXT NOT NULL,
    post_type VARCHAR(20) DEFAULT 'discussion',
    upvotes INTEGER DEFAULT 0,
    reply_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_posts_forum ON creator_community_posts(forum_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_author ON creator_community_posts(author_user_id);

-- Partnership matching
CREATE TABLE IF NOT EXISTS creator_partnership_matches (
    match_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_a_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    creator_b_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    match_score DECIMAL(5,2),
    match_reason JSONB,
    match_status VARCHAR(20) DEFAULT 'suggested',
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_matches_creator_a ON creator_partnership_matches(creator_a_id, match_status);
CREATE INDEX IF NOT EXISTS idx_matches_creator_b ON creator_partnership_matches(creator_b_id, match_status);

-- ============================================================================
-- FEATURE 8: CREATOR REVENUE FORECASTING
-- ============================================================================

-- Revenue forecasts
CREATE TABLE IF NOT EXISTS creator_revenue_forecasts (
    forecast_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    forecast_period VARCHAR(20) CHECK (forecast_period IN ('30_days','60_days','90_days')),
    predicted_revenue DECIMAL(10,2),
    confidence_level DECIMAL(5,2),
    zone_breakdown JSONB,
    carousel_breakdown JSONB,
    generated_by VARCHAR(20) DEFAULT 'openai',
    generated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    actual_revenue DECIMAL(10,2)
);

CREATE INDEX IF NOT EXISTS idx_forecasts_creator ON creator_revenue_forecasts(creator_user_id, generated_at DESC);

-- Zone-specific payout optimization
CREATE TABLE IF NOT EXISTS zone_payout_optimization (
    optimization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    purchasing_power_zone INTEGER CHECK (purchasing_power_zone BETWEEN 1 AND 8),
    recommended_pricing DECIMAL(10,2),
    optimal_content_type VARCHAR(50),
    expected_conversion_rate DECIMAL(5,2),
    generated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_zone_optimization_creator ON zone_payout_optimization(creator_user_id, purchasing_power_zone);

-- ============================================================================
-- FEATURE 9: PERPLEXITY CAROUSEL INTELLIGENCE
-- ============================================================================

-- Competitive benchmarking
CREATE TABLE IF NOT EXISTS carousel_competitive_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carousel_type VARCHAR(50) NOT NULL,
    content_type VARCHAR(50),
    industry_avg_engagement DECIMAL(5,2),
    industry_avg_conversion DECIMAL(5,2),
    industry_avg_revenue DECIMAL(10,2),
    top_performer_metrics JSONB,
    market_trends JSONB,
    analyzed_by VARCHAR(20) DEFAULT 'perplexity',
    analyzed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_benchmarks_carousel ON carousel_competitive_benchmarks(carousel_type, analyzed_at DESC);

-- Market trend analysis
CREATE TABLE IF NOT EXISTS carousel_market_trends (
    trend_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carousel_type VARCHAR(50) NOT NULL,
    trend_category VARCHAR(50),
    trend_description TEXT,
    trend_impact VARCHAR(20),
    actionable_insights JSONB,
    confidence_score DECIMAL(5,2),
    analyzed_by VARCHAR(20) DEFAULT 'perplexity',
    analyzed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_trends_carousel ON carousel_market_trends(carousel_type, analyzed_at DESC);

-- ============================================================================
-- FEATURE 10: CAROUSEL HEALTH & SCALING DASHBOARD
-- ============================================================================

-- System capacity metrics
CREATE TABLE IF NOT EXISTS carousel_system_capacity (
    capacity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carousel_type VARCHAR(50) NOT NULL,
    current_load DECIMAL(5,2),
    max_capacity DECIMAL(10,2),
    utilization_percentage DECIMAL(5,2),
    auto_scaling_status VARCHAR(20),
    scaling_triggers JSONB,
    recorded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_capacity_carousel ON carousel_system_capacity(carousel_type, recorded_at DESC);

-- Infrastructure optimization
CREATE TABLE IF NOT EXISTS carousel_infrastructure_optimization (
    optimization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    carousel_type VARCHAR(50) NOT NULL,
    optimization_type VARCHAR(50),
    current_performance JSONB,
    recommended_changes JSONB,
    expected_improvement DECIMAL(5,2),
    implementation_priority VARCHAR(20),
    analyzed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_infra_optimization ON carousel_infrastructure_optimization(carousel_type, implementation_priority);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Refresh engagement heatmap
CREATE OR REPLACE FUNCTION refresh_engagement_heatmap()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY carousel_engagement_by_time;
    REFRESH MATERIALIZED VIEW CONCURRENTLY creator_engagement_by_time;
END;
$$;

-- Calculate content orchestration score
CREATE OR REPLACE FUNCTION calculate_content_score(
    p_content_id UUID,
    p_content_type VARCHAR,
    p_user_id UUID
)
RETURNS DECIMAL
LANGUAGE plpgsql
AS $$
DECLARE
    v_base_score DECIMAL := 0;
    v_recency_score DECIMAL := 0;
    v_social_score DECIMAL := 0;
    v_personalization_score DECIMAL := 0;
    v_final_score DECIMAL := 0;
BEGIN
    -- Base engagement score (simplified)
    SELECT COALESCE(AVG(CASE WHEN interaction_type IN ('swipe_right','tap') THEN 50 ELSE 0 END), 0)
    INTO v_base_score
    FROM carousel_interactions
    WHERE content_id = p_content_id;
    
    -- Recency score (100 for new, decays over time)
    v_recency_score := 100;
    
    -- Social proof score (simplified)
    v_social_score := 50;
    
    -- Personalization score (simplified)
    v_personalization_score := 60;
    
    -- Weighted final score
    v_final_score := (v_base_score * 0.25) + (v_recency_score * 0.20) + 
                     (v_social_score * 0.15) + (v_personalization_score * 0.30);
    
    RETURN v_final_score;
END;
$$;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE carousel_realtime_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_performance_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE active_carousel_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_orchestration_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_sequence_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE orchestration_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_carousel_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_optimization_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_roi_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_sponsorship_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_carousel_marketplace_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_marketplace_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_health_monitoring ENABLE ROW LEVEL SECURITY;
ALTER TABLE claude_agent_interventions ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_community_forums ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_partnership_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_revenue_forecasts ENABLE ROW LEVEL SECURITY;
ALTER TABLE zone_payout_optimization ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_competitive_benchmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_market_trends ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_system_capacity ENABLE ROW LEVEL SECURITY;
ALTER TABLE carousel_infrastructure_optimization ENABLE ROW LEVEL SECURITY;

-- Admin-only policies for monitoring and analytics
DO $$
BEGIN
    -- Real-time metrics (admin only)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'carousel_realtime_metrics' AND policyname = 'admin_full_access') THEN
        CREATE POLICY admin_full_access ON carousel_realtime_metrics FOR ALL
        USING ((SELECT role FROM user_profiles WHERE id = auth.uid()) = 'admin');
    END IF;

    -- Performance snapshots (admin only)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'carousel_performance_snapshots' AND policyname = 'admin_full_access') THEN
        CREATE POLICY admin_full_access ON carousel_performance_snapshots FOR ALL
        USING ((SELECT role FROM user_profiles WHERE id = auth.uid()) = 'admin');
    END IF;

    -- Active sessions (users can see own)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'active_carousel_sessions' AND policyname = 'users_own_sessions') THEN
        CREATE POLICY users_own_sessions ON active_carousel_sessions FOR ALL
        USING (user_id = auth.uid());
    END IF;

    -- Creator analytics (creators see own)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'creator_carousel_analytics' AND policyname = 'creators_own_analytics') THEN
        CREATE POLICY creators_own_analytics ON creator_carousel_analytics FOR ALL
        USING (creator_user_id = auth.uid());
    END IF;

    -- Creator recommendations (creators see own)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'creator_optimization_recommendations' AND policyname = 'creators_own_recommendations') THEN
        CREATE POLICY creators_own_recommendations ON creator_optimization_recommendations FOR ALL
        USING (creator_user_id = auth.uid());
    END IF;

    -- Marketplace services (public read, creators manage own)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'creator_carousel_marketplace_services' AND policyname = 'public_read_services') THEN
        CREATE POLICY public_read_services ON creator_carousel_marketplace_services FOR SELECT
        USING (true);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'creator_carousel_marketplace_services' AND policyname = 'creators_manage_own') THEN
        CREATE POLICY creators_manage_own ON creator_carousel_marketplace_services FOR ALL
        USING (creator_user_id = auth.uid());
    END IF;

    -- Marketplace bookings (buyers and sellers see own)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'carousel_marketplace_bookings' AND policyname = 'users_own_bookings') THEN
        CREATE POLICY users_own_bookings ON carousel_marketplace_bookings FOR ALL
        USING (
            buyer_user_id = auth.uid() OR 
            EXISTS (
                SELECT 1 FROM creator_carousel_marketplace_services 
                WHERE service_id = carousel_marketplace_bookings.service_id 
                AND creator_user_id = auth.uid()
            )
        );
    END IF;

    -- Community forums (public read, authenticated write)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'creator_community_forums' AND policyname = 'public_read_forums') THEN
        CREATE POLICY public_read_forums ON creator_community_forums FOR SELECT
        USING (true);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'creator_community_forums' AND policyname = 'authenticated_create_forums') THEN
        CREATE POLICY authenticated_create_forums ON creator_community_forums FOR INSERT
        WITH CHECK (auth.uid() IS NOT NULL);
    END IF;

    -- Community posts (public read, authors manage own)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'creator_community_posts' AND policyname = 'public_read_posts') THEN
        CREATE POLICY public_read_posts ON creator_community_posts FOR SELECT
        USING (true);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'creator_community_posts' AND policyname = 'authors_manage_own') THEN
        CREATE POLICY authors_manage_own ON creator_community_posts FOR ALL
        USING (author_user_id = auth.uid());
    END IF;

    -- Revenue forecasts (creators see own)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'creator_revenue_forecasts' AND policyname = 'creators_own_forecasts') THEN
        CREATE POLICY creators_own_forecasts ON creator_revenue_forecasts FOR ALL
        USING (creator_user_id = auth.uid());
    END IF;

    -- Benchmarks (public read)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'carousel_competitive_benchmarks' AND policyname = 'public_read_benchmarks') THEN
        CREATE POLICY public_read_benchmarks ON carousel_competitive_benchmarks FOR SELECT
        USING (true);
    END IF;

    -- Market trends (public read)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'carousel_market_trends' AND policyname = 'public_read_trends') THEN
        CREATE POLICY public_read_trends ON carousel_market_trends FOR SELECT
        USING (true);
    END IF;

    RAISE NOTICE 'Carousel enterprise features migration completed successfully';
END $$;