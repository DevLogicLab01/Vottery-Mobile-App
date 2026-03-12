-- =====================================================
-- BATCH 5: UNIFIED ALERT MANAGEMENT & ELECTION INSIGHTS
-- =====================================================
-- Migration: 20260213080000_unified_alerts_election_insights.sql
-- Features: Unified alert management center, election insights analytics

-- =====================================================
-- UNIFIED ALERT MANAGEMENT TABLES
-- =====================================================

-- Alert preferences per user per category
CREATE TABLE IF NOT EXISTS public.alert_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('votes', 'messages', 'achievements', 'elections', 'campaigns', 'security', 'payments', 'system')),
  enabled BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT true,
  email_enabled BOOLEAN DEFAULT true,
  sms_enabled BOOLEAN DEFAULT false,
  sound_enabled BOOLEAN DEFAULT true,
  vibration_enabled BOOLEAN DEFAULT true,
  priority_level TEXT DEFAULT 'normal' CHECK (priority_level IN ('low', 'normal', 'high', 'critical')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, category)
);

-- Quiet hours scheduling
CREATE TABLE IF NOT EXISTS public.quiet_hours (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  enabled BOOLEAN DEFAULT false,
  start_time TIME NOT NULL DEFAULT '22:00:00',
  end_time TIME NOT NULL DEFAULT '08:00:00',
  days_of_week INTEGER[] DEFAULT ARRAY[0,1,2,3,4,5,6], -- 0=Sunday, 6=Saturday
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- Alert history with comprehensive search
CREATE TABLE IF NOT EXISTS public.alert_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_id UUID REFERENCES public.unified_notifications(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('delivered', 'opened', 'dismissed', 'clicked', 'grouped')),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Alert grouping for similar notifications
CREATE TABLE IF NOT EXISTS public.alert_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  group_key TEXT NOT NULL, -- e.g., 'vote_election_123', 'message_user_456'
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  count INTEGER DEFAULT 1,
  latest_notification_id UUID REFERENCES public.unified_notifications(id) ON DELETE CASCADE,
  notification_ids UUID[] DEFAULT ARRAY[]::UUID[],
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, group_key)
);

-- Alert delivery analytics
CREATE TABLE IF NOT EXISTS public.alert_delivery_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_sent INTEGER DEFAULT 0,
  total_delivered INTEGER DEFAULT 0,
  total_opened INTEGER DEFAULT 0,
  total_clicked INTEGER DEFAULT 0,
  total_dismissed INTEGER DEFAULT 0,
  engagement_rate DECIMAL(5,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, category, date)
);

-- =====================================================
-- ELECTION INSIGHTS ANALYTICS TABLES
-- =====================================================

-- Election predictions from OpenAI GPT-5
CREATE TABLE IF NOT EXISTS public.election_predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL,
  prediction_data JSONB NOT NULL, -- outcome probabilities, confidence intervals
  confidence_score DECIMAL(5,2) NOT NULL,
  accuracy_metrics JSONB DEFAULT '{}'::jsonb,
  model_version TEXT DEFAULT 'gpt-5',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Voting trends over time
CREATE TABLE IF NOT EXISTS public.voting_trends (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  vote_count INTEGER DEFAULT 0,
  momentum_score DECIMAL(5,2) DEFAULT 0.00, -- rate of change
  trend_direction TEXT CHECK (trend_direction IN ('up', 'down', 'stable')),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Demographic breakdown
CREATE TABLE IF NOT EXISTS public.demographic_breakdown (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL,
  demographic_type TEXT NOT NULL CHECK (demographic_type IN ('age', 'gender', 'location', 'zone')),
  demographic_value TEXT NOT NULL,
  vote_count INTEGER DEFAULT 0,
  percentage DECIMAL(5,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(election_id, demographic_type, demographic_value)
);

-- Swing voter identification
CREATE TABLE IF NOT EXISTS public.swing_voters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vote_switching_pattern JSONB DEFAULT '{}'::jsonb,
  undecided_score DECIMAL(5,2) DEFAULT 0.00,
  targeting_suggestions JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(election_id, user_id)
);

-- Strategic recommendations from AI
CREATE TABLE IF NOT EXISTS public.strategic_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL,
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('posting_time', 'target_demographics', 'engagement_tactics', 'content_strategy')),
  recommendation_text TEXT NOT NULL,
  confidence_score DECIMAL(5,2) DEFAULT 0.00,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Voter engagement heatmap
CREATE TABLE IF NOT EXISTS public.voter_engagement_heatmap (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL,
  hour_of_day INTEGER NOT NULL CHECK (hour_of_day >= 0 AND hour_of_day <= 23),
  day_of_week INTEGER NOT NULL CHECK (day_of_week >= 0 AND day_of_week <= 6),
  engagement_count INTEGER DEFAULT 0,
  intensity_score DECIMAL(5,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(election_id, hour_of_day, day_of_week)
);

-- Demographic correlation analysis
CREATE TABLE IF NOT EXISTS public.demographic_correlations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL,
  demographic_group TEXT NOT NULL,
  engagement_rate DECIMAL(5,2) DEFAULT 0.00,
  vote_rate DECIMAL(5,2) DEFAULT 0.00,
  insights JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(election_id, demographic_group)
);

-- Historical election comparisons
CREATE TABLE IF NOT EXISTS public.election_historical_comparisons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL,
  comparison_metric TEXT NOT NULL,
  current_value DECIMAL(10,2) DEFAULT 0.00,
  historical_average DECIMAL(10,2) DEFAULT 0.00,
  variance_percentage DECIMAL(5,2) DEFAULT 0.00,
  benchmark_category TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(election_id, comparison_metric)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_alert_preferences_user_id ON public.alert_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_preferences_category ON public.alert_preferences(category);
CREATE INDEX IF NOT EXISTS idx_quiet_hours_user_id ON public.quiet_hours(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_history_user_id ON public.alert_history(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_history_created_at ON public.alert_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_alert_groups_user_id ON public.alert_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_groups_group_key ON public.alert_groups(group_key);
CREATE INDEX IF NOT EXISTS idx_alert_delivery_analytics_user_id ON public.alert_delivery_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_alert_delivery_analytics_date ON public.alert_delivery_analytics(date DESC);

CREATE INDEX IF NOT EXISTS idx_election_predictions_election_id ON public.election_predictions(election_id);
CREATE INDEX IF NOT EXISTS idx_voting_trends_election_id ON public.voting_trends(election_id);
CREATE INDEX IF NOT EXISTS idx_voting_trends_timestamp ON public.voting_trends(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_demographic_breakdown_election_id ON public.demographic_breakdown(election_id);
CREATE INDEX IF NOT EXISTS idx_swing_voters_election_id ON public.swing_voters(election_id);
CREATE INDEX IF NOT EXISTS idx_strategic_recommendations_election_id ON public.strategic_recommendations(election_id);
CREATE INDEX IF NOT EXISTS idx_voter_engagement_heatmap_election_id ON public.voter_engagement_heatmap(election_id);
CREATE INDEX IF NOT EXISTS idx_demographic_correlations_election_id ON public.demographic_correlations(election_id);
CREATE INDEX IF NOT EXISTS idx_election_historical_comparisons_election_id ON public.election_historical_comparisons(election_id);

-- =====================================================
-- ROW LEVEL SECURITY POLICIES
-- =====================================================

ALTER TABLE public.alert_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiet_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_delivery_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voting_trends ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demographic_breakdown ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swing_voters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.strategic_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voter_engagement_heatmap ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.demographic_correlations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_historical_comparisons ENABLE ROW LEVEL SECURITY;

-- Alert Preferences Policies
CREATE POLICY "Users can view their own alert preferences"
  ON public.alert_preferences FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own alert preferences"
  ON public.alert_preferences FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own alert preferences"
  ON public.alert_preferences FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own alert preferences"
  ON public.alert_preferences FOR DELETE
  USING (auth.uid() = user_id);

-- Quiet Hours Policies
CREATE POLICY "Users can view their own quiet hours"
  ON public.quiet_hours FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own quiet hours"
  ON public.quiet_hours FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own quiet hours"
  ON public.quiet_hours FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own quiet hours"
  ON public.quiet_hours FOR DELETE
  USING (auth.uid() = user_id);

-- Alert History Policies
CREATE POLICY "Users can view their own alert history"
  ON public.alert_history FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own alert history"
  ON public.alert_history FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Alert Groups Policies
CREATE POLICY "Users can view their own alert groups"
  ON public.alert_groups FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own alert groups"
  ON public.alert_groups FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own alert groups"
  ON public.alert_groups FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own alert groups"
  ON public.alert_groups FOR DELETE
  USING (auth.uid() = user_id);

-- Alert Delivery Analytics Policies
CREATE POLICY "Users can view their own alert analytics"
  ON public.alert_delivery_analytics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "System can insert alert analytics"
  ON public.alert_delivery_analytics FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update alert analytics"
  ON public.alert_delivery_analytics FOR UPDATE
  USING (true);

-- Election Predictions Policies (public read, system write)
CREATE POLICY "Anyone can view election predictions"
  ON public.election_predictions FOR SELECT
  USING (true);

CREATE POLICY "System can insert election predictions"
  ON public.election_predictions FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update election predictions"
  ON public.election_predictions FOR UPDATE
  USING (true);

-- Voting Trends Policies
CREATE POLICY "Anyone can view voting trends"
  ON public.voting_trends FOR SELECT
  USING (true);

CREATE POLICY "System can insert voting trends"
  ON public.voting_trends FOR INSERT
  WITH CHECK (true);

-- Demographic Breakdown Policies
CREATE POLICY "Anyone can view demographic breakdown"
  ON public.demographic_breakdown FOR SELECT
  USING (true);

CREATE POLICY "System can insert demographic breakdown"
  ON public.demographic_breakdown FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update demographic breakdown"
  ON public.demographic_breakdown FOR UPDATE
  USING (true);

-- Swing Voters Policies (private to election creator)
CREATE POLICY "Election creators can view swing voters"
  ON public.swing_voters FOR SELECT
  USING (
    auth.uid() IS NOT NULL
  );

CREATE POLICY "System can insert swing voters"
  ON public.swing_voters FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update swing voters"
  ON public.swing_voters FOR UPDATE
  USING (true);

-- Strategic Recommendations Policies
CREATE POLICY "Creators can view their own recommendations"
  ON public.strategic_recommendations FOR SELECT
  USING (auth.uid() = creator_id);

CREATE POLICY "System can insert recommendations"
  ON public.strategic_recommendations FOR INSERT
  WITH CHECK (true);

-- Voter Engagement Heatmap Policies
CREATE POLICY "Anyone can view engagement heatmap"
  ON public.voter_engagement_heatmap FOR SELECT
  USING (true);

CREATE POLICY "System can insert engagement heatmap"
  ON public.voter_engagement_heatmap FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update engagement heatmap"
  ON public.voter_engagement_heatmap FOR UPDATE
  USING (true);

-- Demographic Correlations Policies
CREATE POLICY "Anyone can view demographic correlations"
  ON public.demographic_correlations FOR SELECT
  USING (true);

CREATE POLICY "System can insert demographic correlations"
  ON public.demographic_correlations FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update demographic correlations"
  ON public.demographic_correlations FOR UPDATE
  USING (true);

-- Historical Comparisons Policies
CREATE POLICY "Anyone can view historical comparisons"
  ON public.election_historical_comparisons FOR SELECT
  USING (true);

CREATE POLICY "System can insert historical comparisons"
  ON public.election_historical_comparisons FOR INSERT
  WITH CHECK (true);

CREATE POLICY "System can update historical comparisons"
  ON public.election_historical_comparisons FOR UPDATE
  USING (true);

-- =====================================================
-- TRIGGERS FOR AUTOMATED UPDATES
-- =====================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_alert_preferences_updated_at BEFORE UPDATE ON public.alert_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_quiet_hours_updated_at BEFORE UPDATE ON public.quiet_hours
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alert_groups_updated_at BEFORE UPDATE ON public.alert_groups
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_alert_delivery_analytics_updated_at BEFORE UPDATE ON public.alert_delivery_analytics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_election_predictions_updated_at BEFORE UPDATE ON public.election_predictions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_demographic_breakdown_updated_at BEFORE UPDATE ON public.demographic_breakdown
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_swing_voters_updated_at BEFORE UPDATE ON public.swing_voters
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_voter_engagement_heatmap_updated_at BEFORE UPDATE ON public.voter_engagement_heatmap
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_demographic_correlations_updated_at BEFORE UPDATE ON public.demographic_correlations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_election_historical_comparisons_updated_at BEFORE UPDATE ON public.election_historical_comparisons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- MOCK DATA FOR TESTING
-- =====================================================

-- Insert default alert preferences for existing users
DO $$
DECLARE
  sample_user_id UUID;
BEGIN
  -- Get first user or create sample
  SELECT id INTO sample_user_id FROM auth.users LIMIT 1;
  
  IF sample_user_id IS NOT NULL THEN
    -- Insert default preferences for all categories
    INSERT INTO public.alert_preferences (user_id, category, enabled, push_enabled, email_enabled, priority_level)
    VALUES 
      (sample_user_id, 'votes', true, true, true, 'normal'),
      (sample_user_id, 'messages', true, true, false, 'high'),
      (sample_user_id, 'achievements', true, true, false, 'normal'),
      (sample_user_id, 'elections', true, true, true, 'high'),
      (sample_user_id, 'campaigns', true, false, true, 'normal'),
      (sample_user_id, 'security', true, true, true, 'critical'),
      (sample_user_id, 'payments', true, true, true, 'high'),
      (sample_user_id, 'system', true, false, false, 'low')
    ON CONFLICT (user_id, category) DO NOTHING;
    
    -- Insert quiet hours
    INSERT INTO public.quiet_hours (user_id, enabled, start_time, end_time)
    VALUES (sample_user_id, false, '22:00:00', '08:00:00')
    ON CONFLICT (user_id) DO NOTHING;
  END IF;
END $$;

-- Insert sample election predictions
DO $$
DECLARE
  sample_election_id UUID;
BEGIN
  -- Get first election
  SELECT id INTO sample_election_id FROM public.elections LIMIT 1;
  
  IF sample_election_id IS NOT NULL THEN
    INSERT INTO public.election_predictions (election_id, prediction_data, confidence_score, accuracy_metrics)
    VALUES (
      sample_election_id,
      '{"outcome_probabilities": {"option_1": 0.45, "option_2": 0.35, "option_3": 0.20}, "confidence_intervals": {"option_1": [0.40, 0.50], "option_2": [0.30, 0.40], "option_3": [0.15, 0.25]}}'::jsonb,
      85.50,
      '{"accuracy": 0.92, "precision": 0.88, "recall": 0.90}'::jsonb
    );
    
    -- Insert voting trends
    INSERT INTO public.voting_trends (election_id, vote_count, momentum_score, trend_direction)
    VALUES 
      (sample_election_id, 150, 12.5, 'up'),
      (sample_election_id, 175, 16.7, 'up'),
      (sample_election_id, 180, 2.9, 'stable');
    
    -- Insert demographic breakdown
    INSERT INTO public.demographic_breakdown (election_id, demographic_type, demographic_value, vote_count, percentage)
    VALUES 
      (sample_election_id, 'age', '18-24', 45, 25.00),
      (sample_election_id, 'age', '25-34', 60, 33.33),
      (sample_election_id, 'age', '35-44', 40, 22.22),
      (sample_election_id, 'age', '45+', 35, 19.45),
      (sample_election_id, 'gender', 'male', 90, 50.00),
      (sample_election_id, 'gender', 'female', 85, 47.22),
      (sample_election_id, 'gender', 'other', 5, 2.78)
    ON CONFLICT (election_id, demographic_type, demographic_value) DO NOTHING;
    
    -- Insert voter engagement heatmap
    INSERT INTO public.voter_engagement_heatmap (election_id, hour_of_day, day_of_week, engagement_count, intensity_score)
    VALUES 
      (sample_election_id, 9, 1, 25, 65.00),
      (sample_election_id, 12, 1, 45, 85.00),
      (sample_election_id, 18, 1, 60, 95.00),
      (sample_election_id, 21, 1, 40, 75.00),
      (sample_election_id, 9, 5, 15, 45.00),
      (sample_election_id, 12, 5, 20, 55.00),
      (sample_election_id, 18, 5, 35, 70.00)
    ON CONFLICT (election_id, hour_of_day, day_of_week) DO NOTHING;
  END IF;
END $$;