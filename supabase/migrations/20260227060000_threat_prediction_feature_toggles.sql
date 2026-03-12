-- Migration: Unified Threat Predictions and Feature Toggles
-- Created: 2026-02-27

-- Create unified_threat_predictions table
CREATE TABLE IF NOT EXISTS public.unified_threat_predictions (
  prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  threat_category VARCHAR(50) NOT NULL,
  prediction_horizon_days INTEGER NOT NULL DEFAULT 30,
  predicted_severity VARCHAR(20) NOT NULL DEFAULT 'low',
  confidence_score DECIMAL(3,2) NOT NULL DEFAULT 0.75,
  zone_id INTEGER,
  mitigation_recommendations JSONB DEFAULT '[]'::jsonb,
  predicted_for_date DATE NOT NULL DEFAULT CURRENT_DATE,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for efficient querying
CREATE INDEX IF NOT EXISTS idx_threat_predictions_date_category
  ON public.unified_threat_predictions (predicted_for_date, threat_category);

CREATE INDEX IF NOT EXISTS idx_threat_predictions_zone
  ON public.unified_threat_predictions (zone_id);

CREATE INDEX IF NOT EXISTS idx_threat_predictions_severity
  ON public.unified_threat_predictions (predicted_severity);

-- Create feature_toggles table for enhanced admin panel
CREATE TABLE IF NOT EXISTS public.feature_toggles (
  toggle_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  toggle_name VARCHAR(100) UNIQUE NOT NULL,
  toggle_category VARCHAR(50) NOT NULL DEFAULT 'general',
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_feature_toggles_category
  ON public.feature_toggles (toggle_category);

CREATE INDEX IF NOT EXISTS idx_feature_toggles_name
  ON public.feature_toggles (toggle_name);

-- Insert default gamification feature toggles
INSERT INTO public.feature_toggles (toggle_name, toggle_category, is_enabled)
VALUES
  ('enable_prediction_pools', 'prediction_pools', true),
  ('enable_private_pools', 'prediction_pools', true),
  ('enable_oracle_auto_resolution', 'prediction_pools', true),
  ('enable_brier_scoring', 'prediction_pools', true),
  ('enable_prediction_leaderboards', 'prediction_pools', true),
  ('enable_ad_mini_games', 'participatory_ads_gamification', true),
  ('enable_spin_wheel', 'participatory_ads_gamification', true),
  ('enable_ad_quests', 'participatory_ads_gamification', true),
  ('enable_campaign_chains', 'participatory_ads_gamification', true),
  ('enable_impact_meters', 'participatory_ads_gamification', true),
  ('enable_feed_quests', 'feed_gamification', true),
  ('enable_feed_progression_levels', 'feed_gamification', true),
  ('enable_feed_streaks', 'feed_gamification', true),
  ('enable_feed_power_ups', 'feed_gamification', true),
  ('enable_adventure_paths', 'feed_gamification', true),
  ('platform_perks_redeemable', 'vp_redemption_categories', true),
  ('election_enhancements_redeemable', 'vp_redemption_categories', true),
  ('social_rewards_redeemable', 'vp_redemption_categories', true),
  ('real_world_rewards_redeemable', 'vp_redemption_categories', true),
  ('vip_tiers_redeemable', 'vp_redemption_categories', true),
  ('enable_daily_quests', 'quest_system', true),
  ('enable_weekly_quests', 'quest_system', true),
  ('enable_ai_quest_generation', 'quest_system', true),
  ('enable_quest_chains', 'quest_system', true)
ON CONFLICT (toggle_name) DO NOTHING;

-- Enable RLS
ALTER TABLE public.unified_threat_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_toggles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for unified_threat_predictions
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'unified_threat_predictions' AND policyname = 'Admins can manage threat predictions'
  ) THEN
    CREATE POLICY "Admins can manage threat predictions"
      ON public.unified_threat_predictions
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

-- RLS Policies for feature_toggles
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'feature_toggles' AND policyname = 'Admins can manage feature toggles'
  ) THEN
    CREATE POLICY "Admins can manage feature toggles"
      ON public.feature_toggles
      FOR ALL
      USING (true)
      WITH CHECK (true);
  END IF;
END $$;

-- Insert sample threat predictions for testing
INSERT INTO public.unified_threat_predictions (threat_category, prediction_horizon_days, predicted_severity, confidence_score, zone_id, predicted_for_date)
VALUES
  ('fraud', 30, 'high', 0.87, 1, CURRENT_DATE + INTERVAL '3 days'),
  ('payment_anomaly', 30, 'medium', 0.79, 2, CURRENT_DATE + INTERVAL '7 days'),
  ('security_breach', 60, 'critical', 0.92, 6, CURRENT_DATE + INTERVAL '14 days'),
  ('account_takeover', 30, 'high', 0.84, 3, CURRENT_DATE + INTERVAL '5 days'),
  ('fraud', 90, 'medium', 0.76, 4, CURRENT_DATE + INTERVAL '25 days'),
  ('payment_anomaly', 60, 'high', 0.88, 5, CURRENT_DATE + INTERVAL '18 days')
ON CONFLICT DO NOTHING;
