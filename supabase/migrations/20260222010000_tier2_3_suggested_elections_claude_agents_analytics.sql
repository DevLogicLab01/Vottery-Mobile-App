-- =====================================================
-- TIER 2 & 3 FEATURES: SUGGESTED ELECTIONS + CLAUDE AGENTS + CROSS-DOMAIN ANALYTICS
-- =====================================================

-- =====================================================
-- SUGGESTED ELECTIONS DISCOVERY SYSTEM
-- =====================================================

-- Suggested elections tracking table
CREATE TABLE IF NOT EXISTS public.suggested_elections_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    recommendation_reason TEXT NOT NULL,
    recommendation_score DECIMAL(5,2) NOT NULL DEFAULT 0.0,
    trending_badge TEXT CHECK (trending_badge IN ('hot', 'rising', 'new')),
    shown_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    clicked_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ,
    dismiss_reason TEXT,
    voted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, election_id, shown_at)
);

CREATE INDEX IF NOT EXISTS idx_suggested_elections_user ON public.suggested_elections_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_suggested_elections_election ON public.suggested_elections_tracking(election_id);
CREATE INDEX IF NOT EXISTS idx_suggested_elections_shown ON public.suggested_elections_tracking(shown_at DESC);

-- User election dismissals for feedback loop
CREATE TABLE IF NOT EXISTS public.election_dismissals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    dismiss_reason TEXT NOT NULL,
    dismissed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, election_id)
);

CREATE INDEX IF NOT EXISTS idx_election_dismissals_user ON public.election_dismissals(user_id);

-- =====================================================
-- CLAUDE AUTONOMOUS AGENTS SYSTEM
-- =====================================================

-- Claude autonomous actions log
CREATE TABLE IF NOT EXISTS public.claude_autonomous_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type TEXT NOT NULL CHECK (action_type IN ('fraud_response', 'content_moderation', 'winner_verification')),
    target_id UUID NOT NULL,
    target_type TEXT NOT NULL,
    action_taken TEXT NOT NULL,
    confidence_score DECIMAL(5,2) NOT NULL,
    reasoning TEXT NOT NULL,
    automated BOOLEAN NOT NULL DEFAULT TRUE,
    requires_review BOOLEAN NOT NULL DEFAULT FALSE,
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id),
    override_action TEXT,
    override_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_claude_actions_type ON public.claude_autonomous_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_claude_actions_target ON public.claude_autonomous_actions(target_id);
CREATE INDEX IF NOT EXISTS idx_claude_actions_review ON public.claude_autonomous_actions(requires_review) WHERE requires_review = TRUE;
CREATE INDEX IF NOT EXISTS idx_claude_actions_created ON public.claude_autonomous_actions(created_at DESC);

-- Claude confidence thresholds configuration
CREATE TABLE IF NOT EXISTS public.claude_confidence_thresholds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action_type TEXT NOT NULL UNIQUE,
    automation_threshold DECIMAL(5,2) NOT NULL DEFAULT 90.0,
    review_threshold DECIMAL(5,2) NOT NULL DEFAULT 70.0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id)
);

-- Insert default thresholds
INSERT INTO public.claude_confidence_thresholds (action_type, automation_threshold, review_threshold)
VALUES 
    ('fraud_response', 90.0, 70.0),
    ('content_moderation', 95.0, 70.0),
    ('winner_verification', 90.0, 75.0)
ON CONFLICT (action_type) DO NOTHING;

-- Claude moderation queue
CREATE TABLE IF NOT EXISTS public.claude_moderation_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_id UUID NOT NULL,
    content_type TEXT NOT NULL,
    content_text TEXT,
    claude_analysis JSONB NOT NULL,
    confidence_score DECIMAL(5,2) NOT NULL,
    flagged_violations TEXT[],
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'escalated')),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id),
    moderator_feedback TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_claude_queue_status ON public.claude_moderation_queue(status);
CREATE INDEX IF NOT EXISTS idx_claude_queue_created ON public.claude_moderation_queue(created_at DESC);

-- =====================================================
-- CROSS-DOMAIN INTELLIGENCE ANALYTICS
-- =====================================================

-- Cross-domain intelligence metrics
CREATE TABLE IF NOT EXISTS public.cross_domain_intelligence_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_type TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    metric_value DECIMAL(10,2) NOT NULL,
    ai_service TEXT NOT NULL,
    correlation_data JSONB,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cdi_metrics_type ON public.cross_domain_intelligence_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_cdi_metrics_timestamp ON public.cross_domain_intelligence_metrics(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_cdi_metrics_service ON public.cross_domain_intelligence_metrics(ai_service);

-- Predictive alerts
CREATE TABLE IF NOT EXISTS public.predictive_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_type TEXT NOT NULL,
    alert_severity TEXT NOT NULL CHECK (alert_severity IN ('low', 'medium', 'high', 'critical')),
    predicted_event TEXT NOT NULL,
    confidence_interval DECIMAL(5,2) NOT NULL,
    prediction_window_hours INT NOT NULL,
    ai_consensus_score DECIMAL(5,2) NOT NULL,
    contributing_services TEXT[],
    alert_data JSONB NOT NULL,
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_predictive_alerts_type ON public.predictive_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_predictive_alerts_severity ON public.predictive_alerts(alert_severity);
CREATE INDEX IF NOT EXISTS idx_predictive_alerts_triggered ON public.predictive_alerts(triggered_at DESC);
CREATE INDEX IF NOT EXISTS idx_predictive_alerts_unresolved ON public.predictive_alerts(resolved_at) WHERE resolved_at IS NULL;

-- Multi-AI consensus results
CREATE TABLE IF NOT EXISTS public.multi_ai_consensus_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    analysis_type TEXT NOT NULL,
    target_id UUID NOT NULL,
    openai_result JSONB,
    claude_result JSONB,
    gemini_result JSONB,
    perplexity_result JSONB,
    consensus_score DECIMAL(5,2) NOT NULL,
    agreement_count INT NOT NULL,
    final_decision TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_consensus_type ON public.multi_ai_consensus_results(analysis_type);
CREATE INDEX IF NOT EXISTS idx_consensus_target ON public.multi_ai_consensus_results(target_id);
CREATE INDEX IF NOT EXISTS idx_consensus_created ON public.multi_ai_consensus_results(created_at DESC);

-- Correlation matrix for metrics
CREATE TABLE IF NOT EXISTS public.metric_correlations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_a TEXT NOT NULL,
    metric_b TEXT NOT NULL,
    correlation_coefficient DECIMAL(5,2) NOT NULL,
    sample_size INT NOT NULL,
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(metric_a, metric_b)
);

CREATE INDEX IF NOT EXISTS idx_correlations_metrics ON public.metric_correlations(metric_a, metric_b);

-- =====================================================
-- RPC FUNCTIONS
-- =====================================================

-- Get trending elections with velocity calculation
CREATE OR REPLACE FUNCTION public.get_trending_elections(
    user_id_param UUID,
    limit_count INT DEFAULT 20
)
RETURNS TABLE (
    election_id UUID,
    title TEXT,
    description TEXT,
    image_url TEXT,
    vote_count BIGINT,
    comment_count BIGINT,
    reaction_count BIGINT,
    end_date TIMESTAMPTZ,
    prize_pool DECIMAL,
    vote_velocity DECIMAL,
    engagement_rate DECIMAL,
    recency_score DECIMAL,
    trending_score DECIMAL,
    trending_badge TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH election_stats AS (
        SELECT 
            e.id,
            e.title,
            e.description,
            e.image_url,
            e.end_date,
            e.prize_pool,
            COUNT(DISTINCT v.id) AS vote_count,
            COUNT(DISTINCT ec.id) AS comment_count,
            COUNT(DISTINCT er.id) AS reaction_count,
            EXTRACT(EPOCH FROM (NOW() - e.created_at)) / 3600 AS hours_since_creation,
            EXTRACT(EPOCH FROM (e.end_date - NOW())) / 3600 AS hours_until_end
        FROM public.elections e
        LEFT JOIN public.votes v ON e.id = v.election_id AND v.created_at > NOW() - INTERVAL '24 hours'
        LEFT JOIN public.election_comments ec ON e.id = ec.election_id
        LEFT JOIN public.election_reactions er ON e.id = er.election_id
        WHERE e.status = 'active'
        AND e.end_date > NOW()
        GROUP BY e.id
    ),
    calculated_scores AS (
        SELECT 
            id,
            title,
            description,
            image_url,
            vote_count,
            comment_count,
            reaction_count,
            end_date,
            prize_pool,
            CASE WHEN hours_since_creation > 0 THEN vote_count::DECIMAL / hours_since_creation ELSE 0 END AS vote_velocity,
            CASE WHEN vote_count > 0 THEN (comment_count + reaction_count)::DECIMAL / vote_count ELSE 0 END AS engagement_rate,
            CASE WHEN hours_since_creation <= 24 THEN 1.0 ELSE 1.0 / (hours_since_creation / 24) END AS recency_score
        FROM election_stats
    )
    SELECT 
        id AS election_id,
        title,
        description,
        image_url,
        vote_count,
        comment_count,
        reaction_count,
        end_date,
        prize_pool,
        vote_velocity,
        engagement_rate,
        recency_score,
        (vote_velocity * 0.4 + engagement_rate * 0.3 + recency_score * 0.3) AS trending_score,
        CASE 
            WHEN vote_velocity > 10 THEN 'hot'
            WHEN recency_score > 0.8 THEN 'new'
            WHEN engagement_rate > 0.5 THEN 'rising'
            ELSE NULL
        END AS trending_badge
    FROM calculated_scores
    WHERE id NOT IN (
        SELECT election_id FROM public.election_dismissals WHERE user_id = user_id_param
    )
    ORDER BY trending_score DESC
    LIMIT limit_count;
END;
$$;

-- Get personalized election recommendations
CREATE OR REPLACE FUNCTION public.get_personalized_election_recommendations(
    user_id_param UUID,
    limit_count INT DEFAULT 20
)
RETURNS TABLE (
    election_id UUID,
    title TEXT,
    description TEXT,
    image_url TEXT,
    vote_count BIGINT,
    end_date TIMESTAMPTZ,
    prize_pool DECIMAL,
    recommendation_score DECIMAL,
    recommendation_reason TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH user_voting_history AS (
        SELECT DISTINCT e.category, e.topic_tags
        FROM public.votes v
        JOIN public.elections e ON v.election_id = e.id
        WHERE v.user_id = user_id_param
        ORDER BY v.created_at DESC
        LIMIT 50
    ),
    user_preferences AS (
        SELECT topic_category_id, preference_score
        FROM public.topic_preferences
        WHERE user_id = user_id_param
        ORDER BY preference_score DESC
    ),
    similar_users AS (
        SELECT DISTINCT cf.user_id AS similar_user_id
        FROM public.collaborative_filtering_matrix cf
        WHERE cf.content_id IN (
            SELECT election_id FROM public.votes WHERE user_id = user_id_param
        )
        AND cf.user_id != user_id_param
        ORDER BY cf.interaction_score DESC
        LIMIT 100
    ),
    collaborative_recommendations AS (
        SELECT 
            e.id,
            e.title,
            e.description,
            e.image_url,
            COUNT(DISTINCT v.id) AS vote_count,
            e.end_date,
            e.prize_pool,
            COUNT(DISTINCT v.user_id) AS similar_user_votes,
            0.6 AS recommendation_score,
            'Users with similar voting patterns voted on this' AS recommendation_reason
        FROM public.elections e
        JOIN public.votes v ON e.id = v.election_id
        WHERE v.user_id IN (SELECT similar_user_id FROM similar_users)
        AND e.id NOT IN (SELECT election_id FROM public.votes WHERE user_id = user_id_param)
        AND e.status = 'active'
        AND e.end_date > NOW()
        GROUP BY e.id
        ORDER BY similar_user_votes DESC
        LIMIT limit_count / 2
    ),
    content_based_recommendations AS (
        SELECT 
            e.id,
            e.title,
            e.description,
            e.image_url,
            COUNT(DISTINCT v.id) AS vote_count,
            e.end_date,
            e.prize_pool,
            0.7 AS recommendation_score,
            'Matches your interests in ' || e.category AS recommendation_reason
        FROM public.elections e
        LEFT JOIN public.votes v ON e.id = v.election_id
        WHERE e.category IN (SELECT category FROM user_voting_history)
        AND e.id NOT IN (SELECT election_id FROM public.votes WHERE user_id = user_id_param)
        AND e.status = 'active'
        AND e.end_date > NOW()
        GROUP BY e.id
        ORDER BY vote_count DESC
        LIMIT limit_count / 2
    )
    SELECT * FROM collaborative_recommendations
    UNION ALL
    SELECT * FROM content_based_recommendations
    ORDER BY recommendation_score DESC
    LIMIT limit_count;
END;
$$;

-- Get cross-domain intelligence summary
CREATE OR REPLACE FUNCTION public.get_cross_domain_intelligence_summary(
    time_window_hours INT DEFAULT 24
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_build_object(
        'fraud_patterns', (
            SELECT jsonb_agg(jsonb_build_object(
                'metric_name', metric_name,
                'value', metric_value,
                'ai_service', ai_service
            ))
            FROM public.cross_domain_intelligence_metrics
            WHERE metric_type = 'fraud'
            AND timestamp > NOW() - (time_window_hours || ' hours')::INTERVAL
        ),
        'engagement_trends', (
            SELECT jsonb_agg(jsonb_build_object(
                'metric_name', metric_name,
                'value', metric_value,
                'ai_service', ai_service
            ))
            FROM public.cross_domain_intelligence_metrics
            WHERE metric_type = 'engagement'
            AND timestamp > NOW() - (time_window_hours || ' hours')::INTERVAL
        ),
        'monetization_metrics', (
            SELECT jsonb_agg(jsonb_build_object(
                'metric_name', metric_name,
                'value', metric_value,
                'ai_service', ai_service
            ))
            FROM public.cross_domain_intelligence_metrics
            WHERE metric_type = 'monetization'
            AND timestamp > NOW() - (time_window_hours || ' hours')::INTERVAL
        ),
        'predictive_alerts', (
            SELECT jsonb_agg(jsonb_build_object(
                'alert_type', alert_type,
                'severity', alert_severity,
                'predicted_event', predicted_event,
                'confidence', confidence_interval,
                'ai_consensus', ai_consensus_score
            ))
            FROM public.predictive_alerts
            WHERE triggered_at > NOW() - (time_window_hours || ' hours')::INTERVAL
            AND resolved_at IS NULL
        ),
        'correlations', (
            SELECT jsonb_agg(jsonb_build_object(
                'metric_a', metric_a,
                'metric_b', metric_b,
                'correlation', correlation_coefficient
            ))
            FROM public.metric_correlations
            WHERE ABS(correlation_coefficient) > 0.5
            ORDER BY ABS(correlation_coefficient) DESC
            LIMIT 10
        )
    ) INTO result;
    
    RETURN result;
END;
$$;

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Suggested elections tracking policies
ALTER TABLE public.suggested_elections_tracking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own suggested elections"
    ON public.suggested_elections_tracking FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tracking"
    ON public.suggested_elections_tracking FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tracking"
    ON public.suggested_elections_tracking FOR UPDATE
    USING (auth.uid() = user_id);

-- Election dismissals policies
ALTER TABLE public.election_dismissals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own dismissals"
    ON public.election_dismissals FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own dismissals"
    ON public.election_dismissals FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Claude autonomous actions policies
ALTER TABLE public.claude_autonomous_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all Claude actions"
    ON public.claude_autonomous_actions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "System can insert Claude actions"
    ON public.claude_autonomous_actions FOR INSERT
    WITH CHECK (true);

-- Claude moderation queue policies
ALTER TABLE public.claude_moderation_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Moderators can view moderation queue"
    ON public.claude_moderation_queue FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'moderator')
        )
    );

CREATE POLICY "Moderators can update moderation queue"
    ON public.claude_moderation_queue FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role IN ('admin', 'moderator')
        )
    );

-- Cross-domain intelligence policies
ALTER TABLE public.cross_domain_intelligence_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view intelligence metrics"
    ON public.cross_domain_intelligence_metrics FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Predictive alerts policies
ALTER TABLE public.predictive_alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view predictive alerts"
    ON public.predictive_alerts FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "Admins can update predictive alerts"
    ON public.predictive_alerts FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Multi-AI consensus policies
ALTER TABLE public.multi_ai_consensus_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view consensus results"
    ON public.multi_ai_consensus_results FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Metric correlations policies
ALTER TABLE public.metric_correlations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view correlations"
    ON public.metric_correlations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.user_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );