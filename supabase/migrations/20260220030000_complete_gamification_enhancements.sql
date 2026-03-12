-- =====================================================
-- COMPLETE GAMIFICATION ENHANCEMENTS MIGRATION
-- Feed Quests, Blockchain Logging, Ad Gamification, Jolts VP
-- =====================================================

-- =====================================================
-- 1. FEED QUEST SYSTEM
-- =====================================================

-- Feed Quest Definitions
CREATE TABLE IF NOT EXISTS public.feed_quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_type TEXT NOT NULL CHECK (quest_type IN ('scroll_posts', 'like_jolts', 'comment_posts', 'share_posts', 'mini_game_poll', 'mini_game_trivia', 'mini_game_prediction')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  target_count INTEGER NOT NULL DEFAULT 1,
  vp_reward INTEGER NOT NULL DEFAULT 20,
  quest_frequency TEXT NOT NULL DEFAULT 'daily' CHECK (quest_frequency IN ('daily', 'weekly', 'monthly')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- User Feed Quest Progress
CREATE TABLE IF NOT EXISTS public.user_feed_quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quest_id UUID NOT NULL REFERENCES public.feed_quests(id) ON DELETE CASCADE,
  current_progress INTEGER DEFAULT 0,
  target_count INTEGER NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  quest_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, quest_id, quest_date)
);

-- Feed Progression Levels
CREATE TABLE IF NOT EXISTS public.feed_progression_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level_name TEXT NOT NULL,
  tier TEXT NOT NULL CHECK (tier IN ('bronze', 'silver', 'gold')),
  min_interactions INTEGER NOT NULL,
  max_interactions INTEGER,
  vp_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.00,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- User Feed Progression
CREATE TABLE IF NOT EXISTS public.user_feed_progression (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  total_interactions INTEGER DEFAULT 0,
  current_level_id UUID REFERENCES public.feed_progression_levels(id),
  feed_streak_days INTEGER DEFAULT 0,
  last_feed_activity_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Feed Leaderboards
CREATE TABLE IF NOT EXISTS public.feed_leaderboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  period TEXT NOT NULL CHECK (period IN ('weekly', 'monthly', 'all_time')),
  total_engagements INTEGER DEFAULT 0,
  vp_earned INTEGER DEFAULT 0,
  rank INTEGER,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, period, period_start)
);

-- =====================================================
-- 2. BLOCKCHAIN GAMIFICATION LOGGING
-- =====================================================

-- Blockchain Gamification Transactions
CREATE TABLE IF NOT EXISTS public.blockchain_gamification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('vp_transaction', 'badge_award', 'challenge_completion', 'prediction_resolution')),
  transaction_hash TEXT,
  block_number BIGINT,
  blockchain_network TEXT DEFAULT 'polygon' CHECK (blockchain_network IN ('ethereum', 'polygon')),
  vp_amount INTEGER,
  badge_id UUID,
  challenge_id UUID,
  prediction_pool_id UUID,
  merkle_root TEXT,
  cryptographic_signature TEXT,
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'failed')),
  gas_fee_wei BIGINT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT now(),
  verified_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_blockchain_gamification_logs_user ON public.blockchain_gamification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_gamification_logs_type ON public.blockchain_gamification_logs(transaction_type);
CREATE INDEX IF NOT EXISTS idx_blockchain_gamification_logs_hash ON public.blockchain_gamification_logs(transaction_hash);

-- Add gamification_type to bulletin_board_transactions
ALTER TABLE public.bulletin_board_transactions 
ADD COLUMN IF NOT EXISTS gamification_type TEXT CHECK (gamification_type IN ('vp_transaction', 'badge_award', 'challenge_completion', 'prediction_resolution'));

-- =====================================================
-- 3. PARTICIPATORY ADS GAMIFICATION
-- =====================================================

-- Ad Mini-Games
CREATE TABLE IF NOT EXISTS public.ad_mini_games (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_campaign_id UUID NOT NULL,
  game_type TEXT NOT NULL CHECK (game_type IN ('spin_wheel', 'memory_match', 'scratch_card')),
  reward_config JSONB NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- User Ad Mini-Game Plays
CREATE TABLE IF NOT EXISTS public.user_ad_mini_game_plays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mini_game_id UUID NOT NULL REFERENCES public.ad_mini_games(id) ON DELETE CASCADE,
  vp_reward INTEGER NOT NULL,
  played_at TIMESTAMPTZ DEFAULT now(),
  game_result JSONB
);

-- Campaign Quest Chains
CREATE TABLE IF NOT EXISTS public.campaign_quest_chains (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chain_name TEXT NOT NULL,
  brand_name TEXT NOT NULL,
  required_ad_votes INTEGER DEFAULT 3,
  badge_reward TEXT DEFAULT 'Brand Master',
  vp_reward INTEGER DEFAULT 200,
  ad_campaign_ids UUID[] NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- User Campaign Quest Progress
CREATE TABLE IF NOT EXISTS public.user_campaign_quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quest_chain_id UUID NOT NULL REFERENCES public.campaign_quest_chains(id) ON DELETE CASCADE,
  completed_ad_votes INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, quest_chain_id)
);

-- Ad-Specific Leaderboards
CREATE TABLE IF NOT EXISTS public.ad_leaderboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_campaign_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  prediction_accuracy DECIMAL(5,2) DEFAULT 0.00,
  total_predictions INTEGER DEFAULT 0,
  vp_earned INTEGER DEFAULT 0,
  rank INTEGER,
  prize_awarded TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(ad_campaign_id, user_id)
);

-- CSR Impact Meters
CREATE TABLE IF NOT EXISTS public.csr_impact_meters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  csr_ad_id UUID NOT NULL,
  donation_goal_amount DECIMAL(12,2) NOT NULL,
  current_donation_amount DECIMAL(12,2) DEFAULT 0.00,
  total_votes INTEGER DEFAULT 0,
  impact_percentage DECIMAL(5,2) DEFAULT 0.00,
  badge_unlock_threshold DECIMAL(5,2) DEFAULT 50.00,
  badge_name TEXT DEFAULT 'Earth Hero',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- User CSR Contributions
CREATE TABLE IF NOT EXISTS public.user_csr_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  csr_impact_meter_id UUID NOT NULL REFERENCES public.csr_impact_meters(id) ON DELETE CASCADE,
  vote_contribution INTEGER DEFAULT 1,
  impact_percentage DECIMAL(5,2),
  badge_earned BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, csr_impact_meter_id)
);

-- Ad Streaks
CREATE TABLE IF NOT EXISTS public.user_ad_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  current_streak_days INTEGER DEFAULT 0,
  longest_streak_days INTEGER DEFAULT 0,
  last_ad_vote_date DATE DEFAULT CURRENT_DATE,
  streak_multiplier DECIMAL(4,2) DEFAULT 2.00,
  streak_saver_available BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- 4. JOLTS VP INTEGRATION
-- =====================================================

-- Jolts VP Earnings
CREATE TABLE IF NOT EXISTS public.jolts_vp_earnings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  jolt_id UUID NOT NULL,
  earning_type TEXT NOT NULL CHECK (earning_type IN ('creation', 'viewing', 'voting', 'sharing')),
  vp_amount INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_jolts_vp_earnings_user ON public.jolts_vp_earnings(user_id);
CREATE INDEX IF NOT EXISTS idx_jolts_vp_earnings_jolt ON public.jolts_vp_earnings(jolt_id);

-- Jolts Creator Badges
CREATE TABLE IF NOT EXISTS public.jolts_creator_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  badge_name TEXT NOT NULL UNIQUE,
  badge_description TEXT NOT NULL,
  requirement_type TEXT NOT NULL,
  requirement_threshold INTEGER NOT NULL,
  vp_reward INTEGER DEFAULT 100,
  badge_icon_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Drop existing CHECK constraint if it exists and recreate with all values
DO $$
BEGIN
  -- Drop the constraint if it exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'jolts_creator_badges_requirement_type_check' 
    AND conrelid = 'public.jolts_creator_badges'::regclass
  ) THEN
    ALTER TABLE public.jolts_creator_badges DROP CONSTRAINT jolts_creator_badges_requirement_type_check;
  END IF;
  
  -- Add the constraint with all requirement_type values
  ALTER TABLE public.jolts_creator_badges 
    ADD CONSTRAINT jolts_creator_badges_requirement_type_check 
    CHECK (requirement_type IN ('total_jolts_created', 'total_views', 'total_vp_earned', 'viral_jolts', 'consecutive_days', 'monthly_rank', 'rising_star', 'total_likes'));
END $$;

-- User Jolts Creator Badges
CREATE TABLE IF NOT EXISTS public.user_jolts_creator_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES public.jolts_creator_badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, badge_id)
);

-- =====================================================
-- 5. SEED DATA
-- =====================================================

-- Insert Feed Progression Levels
INSERT INTO public.feed_progression_levels (level_name, tier, min_interactions, max_interactions, vp_multiplier) VALUES
('Bronze Feed Explorer', 'bronze', 0, 500, 1.00),
('Silver Engager', 'silver', 500, 2000, 1.50),
('Gold Influencer', 'gold', 2000, NULL, 2.00)
ON CONFLICT DO NOTHING;

-- Insert Default Feed Quests
INSERT INTO public.feed_quests (quest_type, title, description, target_count, vp_reward, quest_frequency) VALUES
('scroll_posts', 'Daily Scroller', 'Scroll through 10 posts', 10, 20, 'daily'),
('like_jolts', 'Jolt Enthusiast', 'Like 5 Jolts', 5, 30, 'daily'),
('comment_posts', 'Conversation Starter', 'Comment on 3 posts', 3, 40, 'daily'),
('share_posts', 'Content Sharer', 'Share 2 posts', 2, 50, 'daily'),
('mini_game_poll', 'Quick Poll Master', 'Complete 3 quick polls', 3, 15, 'daily'),
('mini_game_trivia', 'Trivia Champion', 'Complete 2 trivia quizzes', 2, 20, 'daily'),
('mini_game_prediction', 'Prediction Pro', 'Make 1 prediction card vote', 1, 20, 'daily')
ON CONFLICT DO NOTHING;

-- Insert Jolts Creator Badges
INSERT INTO public.jolts_creator_badges (badge_name, badge_description, requirement_type, requirement_threshold, vp_reward) VALUES
('Jolt Rookie', 'Create your first 5 Jolts', 'total_jolts_created', 5, 50),
('Jolt Creator', 'Create 25 Jolts', 'total_jolts_created', 25, 100),
('Jolt Master', 'Create 100 Jolts', 'total_jolts_created', 100, 250),
('Viral Sensation', 'Get 10,000 total views', 'total_views', 10000, 500),
('VP Millionaire', 'Earn 1,000 VP from Jolts', 'total_vp_earned', 1000, 200)
ON CONFLICT (badge_name) DO NOTHING;

-- Insert Comprehensive Jolts Creator Badges (5+ badges)
INSERT INTO public.jolts_creator_badges (badge_name, badge_description, requirement_type, requirement_threshold, vp_reward) VALUES
('Creator Streak', '7-day consecutive Jolts uploads', 'consecutive_days', 7, 100),
('Viral Video', '1000+ views on a single Jolt', 'viral_jolts', 1, 500),
('Top Creator', 'Monthly rank top 10', 'monthly_rank', 10, 1000),
('Rising Star', '100+ views in first 24 hours', 'rising_star', 1, 200),
('Engagement Master', '500+ likes across all Jolts', 'total_likes', 500, 300)
ON CONFLICT (badge_name) DO NOTHING;

-- Create function for Jolts creator leaderboard
CREATE OR REPLACE FUNCTION get_jolts_creator_leaderboard(
  time_period TEXT DEFAULT 'monthly',
  limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
  user_id UUID,
  total_jolts INTEGER,
  total_views BIGINT,
  total_likes BIGINT,
  total_shares BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    j.creator_id AS user_id,
    COUNT(j.id)::INTEGER AS total_jolts,
    COALESCE(SUM(j.view_count), 0)::BIGINT AS total_views,
    COALESCE(SUM(j.like_count), 0)::BIGINT AS total_likes,
    COALESCE(SUM(j.share_count), 0)::BIGINT AS total_shares
  FROM public.jolts j
  WHERE 
    CASE 
      WHEN time_period = 'monthly' THEN j.created_at >= DATE_TRUNC('month', NOW())
      WHEN time_period = 'weekly' THEN j.created_at >= DATE_TRUNC('week', NOW())
      ELSE TRUE
    END
  GROUP BY j.creator_id
  ORDER BY total_views DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 6. RLS POLICIES
-- =====================================================

-- Feed Quests (Public Read)
ALTER TABLE public.feed_quests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Feed quests are viewable by everyone" ON public.feed_quests;
CREATE POLICY "Feed quests are viewable by everyone" ON public.feed_quests FOR SELECT USING (true);
DROP POLICY IF EXISTS "Only admins can manage feed quests" ON public.feed_quests;
CREATE POLICY "Only admins can manage feed quests" ON public.feed_quests FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- User Feed Quest Progress
ALTER TABLE public.user_feed_quest_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own feed quest progress" ON public.user_feed_quest_progress;
CREATE POLICY "Users can view own feed quest progress" ON public.user_feed_quest_progress FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own feed quest progress" ON public.user_feed_quest_progress;
CREATE POLICY "Users can update own feed quest progress" ON public.user_feed_quest_progress FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own feed quest progress" ON public.user_feed_quest_progress;
CREATE POLICY "Users can insert own feed quest progress" ON public.user_feed_quest_progress FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Feed Progression Levels (Public Read)
ALTER TABLE public.feed_progression_levels ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Feed progression levels are viewable by everyone" ON public.feed_progression_levels;
CREATE POLICY "Feed progression levels are viewable by everyone" ON public.feed_progression_levels FOR SELECT USING (true);

-- User Feed Progression
ALTER TABLE public.user_feed_progression ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own feed progression" ON public.user_feed_progression;
CREATE POLICY "Users can view own feed progression" ON public.user_feed_progression FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own feed progression" ON public.user_feed_progression;
CREATE POLICY "Users can update own feed progression" ON public.user_feed_progression FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own feed progression" ON public.user_feed_progression;
CREATE POLICY "Users can insert own feed progression" ON public.user_feed_progression FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Feed Leaderboards (Public Read)
ALTER TABLE public.feed_leaderboards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Feed leaderboards are viewable by everyone" ON public.feed_leaderboards;
CREATE POLICY "Feed leaderboards are viewable by everyone" ON public.feed_leaderboards FOR SELECT USING (true);

-- Blockchain Gamification Logs
ALTER TABLE public.blockchain_gamification_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own blockchain logs" ON public.blockchain_gamification_logs;
CREATE POLICY "Users can view own blockchain logs" ON public.blockchain_gamification_logs FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Admins can view all blockchain logs" ON public.blockchain_gamification_logs;
CREATE POLICY "Admins can view all blockchain logs" ON public.blockchain_gamification_logs FOR SELECT USING (auth.jwt() ->> 'role' = 'admin');
DROP POLICY IF EXISTS "System can insert blockchain logs" ON public.blockchain_gamification_logs;
CREATE POLICY "System can insert blockchain logs" ON public.blockchain_gamification_logs FOR INSERT WITH CHECK (true);

-- Ad Mini-Games (Public Read)
ALTER TABLE public.ad_mini_games ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Ad mini-games are viewable by everyone" ON public.ad_mini_games;
CREATE POLICY "Ad mini-games are viewable by everyone" ON public.ad_mini_games FOR SELECT USING (true);

-- User Ad Mini-Game Plays
ALTER TABLE public.user_ad_mini_game_plays ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own ad mini-game plays" ON public.user_ad_mini_game_plays;
CREATE POLICY "Users can view own ad mini-game plays" ON public.user_ad_mini_game_plays FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own ad mini-game plays" ON public.user_ad_mini_game_plays;
CREATE POLICY "Users can insert own ad mini-game plays" ON public.user_ad_mini_game_plays FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Campaign Quest Chains (Public Read)
ALTER TABLE public.campaign_quest_chains ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Campaign quest chains are viewable by everyone" ON public.campaign_quest_chains;
CREATE POLICY "Campaign quest chains are viewable by everyone" ON public.campaign_quest_chains FOR SELECT USING (true);

-- User Campaign Quest Progress
ALTER TABLE public.user_campaign_quest_progress ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own campaign quest progress" ON public.user_campaign_quest_progress;
CREATE POLICY "Users can view own campaign quest progress" ON public.user_campaign_quest_progress FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own campaign quest progress" ON public.user_campaign_quest_progress;
CREATE POLICY "Users can update own campaign quest progress" ON public.user_campaign_quest_progress FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own campaign quest progress" ON public.user_campaign_quest_progress;
CREATE POLICY "Users can insert own campaign quest progress" ON public.user_campaign_quest_progress FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Ad Leaderboards (Public Read)
ALTER TABLE public.ad_leaderboards ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Ad leaderboards are viewable by everyone" ON public.ad_leaderboards;
CREATE POLICY "Ad leaderboards are viewable by everyone" ON public.ad_leaderboards FOR SELECT USING (true);

-- CSR Impact Meters (Public Read)
ALTER TABLE public.csr_impact_meters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "CSR impact meters are viewable by everyone" ON public.csr_impact_meters;
CREATE POLICY "CSR impact meters are viewable by everyone" ON public.csr_impact_meters FOR SELECT USING (true);

-- User CSR Contributions
ALTER TABLE public.user_csr_contributions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own CSR contributions" ON public.user_csr_contributions;
CREATE POLICY "Users can view own CSR contributions" ON public.user_csr_contributions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own CSR contributions" ON public.user_csr_contributions;
CREATE POLICY "Users can insert own CSR contributions" ON public.user_csr_contributions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User Ad Streaks
ALTER TABLE public.user_ad_streaks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own ad streaks" ON public.user_ad_streaks;
CREATE POLICY "Users can view own ad streaks" ON public.user_ad_streaks FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own ad streaks" ON public.user_ad_streaks;
CREATE POLICY "Users can update own ad streaks" ON public.user_ad_streaks FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own ad streaks" ON public.user_ad_streaks;
CREATE POLICY "Users can insert own ad streaks" ON public.user_ad_streaks FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Jolts VP Earnings
ALTER TABLE public.jolts_vp_earnings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own jolts VP earnings" ON public.jolts_vp_earnings;
CREATE POLICY "Users can view own jolts VP earnings" ON public.jolts_vp_earnings FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "System can insert jolts VP earnings" ON public.jolts_vp_earnings;
CREATE POLICY "System can insert jolts VP earnings" ON public.jolts_vp_earnings FOR INSERT WITH CHECK (true);

-- Jolts Creator Badges (Public Read)
ALTER TABLE public.jolts_creator_badges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Jolts creator badges are viewable by everyone" ON public.jolts_creator_badges;
CREATE POLICY "Jolts creator badges are viewable by everyone" ON public.jolts_creator_badges FOR SELECT USING (true);

-- User Jolts Creator Badges
ALTER TABLE public.user_jolts_creator_badges ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own jolts creator badges" ON public.user_jolts_creator_badges;
CREATE POLICY "Users can view own jolts creator badges" ON public.user_jolts_creator_badges FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can view others jolts creator badges" ON public.user_jolts_creator_badges;
CREATE POLICY "Users can view others jolts creator badges" ON public.user_jolts_creator_badges FOR SELECT USING (true);
DROP POLICY IF EXISTS "System can insert jolts creator badges" ON public.user_jolts_creator_badges;
CREATE POLICY "System can insert jolts creator badges" ON public.user_jolts_creator_badges FOR INSERT WITH CHECK (true);

-- =====================================================
-- 7. FUNCTIONS
-- =====================================================

-- Function to update feed quest progress
CREATE OR REPLACE FUNCTION public.update_feed_quest_progress(
  p_user_id UUID,
  p_quest_type TEXT,
  p_increment INTEGER DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_quest_id UUID;
  v_target_count INTEGER;
  v_vp_reward INTEGER;
  v_current_progress INTEGER;
  v_is_completed BOOLEAN;
  v_result JSONB;
BEGIN
  -- Get active quest of this type
  SELECT id, target_count, vp_reward INTO v_quest_id, v_target_count, v_vp_reward
  FROM public.feed_quests
  WHERE quest_type = p_quest_type AND is_active = true AND quest_frequency = 'daily'
  LIMIT 1;

  IF v_quest_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'message', 'No active quest found');
  END IF;

  -- Insert or update progress
  INSERT INTO public.user_feed_quest_progress (user_id, quest_id, current_progress, target_count, quest_date)
  VALUES (p_user_id, v_quest_id, p_increment, v_target_count, CURRENT_DATE)
  ON CONFLICT (user_id, quest_id, quest_date)
  DO UPDATE SET 
    current_progress = user_feed_quest_progress.current_progress + p_increment,
    updated_at = now()
  RETURNING current_progress, is_completed INTO v_current_progress, v_is_completed;

  -- Check if quest completed
  IF v_current_progress >= v_target_count AND NOT v_is_completed THEN
    UPDATE public.user_feed_quest_progress
    SET is_completed = true, completed_at = now()
    WHERE user_id = p_user_id AND quest_id = v_quest_id AND quest_date = CURRENT_DATE;

    -- Award VP
    INSERT INTO public.vp_transactions (user_id, transaction_type, vp_amount, description)
    VALUES (p_user_id, 'earn', v_vp_reward, 'Feed Quest Completed: ' || p_quest_type);

    v_result := jsonb_build_object(
      'success', true,
      'quest_completed', true,
      'vp_earned', v_vp_reward,
      'progress', v_current_progress,
      'target', v_target_count
    );
  ELSE
    v_result := jsonb_build_object(
      'success', true,
      'quest_completed', false,
      'progress', v_current_progress,
      'target', v_target_count
    );
  END IF;

  RETURN v_result;
END;
$$;

-- Function to award Jolts VP
CREATE OR REPLACE FUNCTION public.award_jolts_vp(
  p_user_id UUID,
  p_jolt_id UUID,
  p_earning_type TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_vp_amount INTEGER;
  v_description TEXT;
BEGIN
  -- Determine VP amount based on earning type
  CASE p_earning_type
    WHEN 'creation' THEN
      v_vp_amount := 50;
      v_description := 'Jolt Created';
    WHEN 'viewing' THEN
      v_vp_amount := 2;
      v_description := 'Jolt Viewed';
    WHEN 'voting' THEN
      v_vp_amount := 5;
      v_description := 'Jolt Vote Cast';
    WHEN 'sharing' THEN
      v_vp_amount := 10;
      v_description := 'Jolt Shared';
    ELSE
      RETURN jsonb_build_object('success', false, 'message', 'Invalid earning type');
  END CASE;

  -- Insert VP earning record
  INSERT INTO public.jolts_vp_earnings (user_id, jolt_id, earning_type, vp_amount)
  VALUES (p_user_id, p_jolt_id, p_earning_type, v_vp_amount);

  -- Add to VP balance
  INSERT INTO public.vp_transactions (user_id, transaction_type, vp_amount, description)
  VALUES (p_user_id, 'earn', v_vp_amount, v_description);

  RETURN jsonb_build_object(
    'success', true,
    'vp_earned', v_vp_amount,
    'earning_type', p_earning_type
  );
END;
$$;

-- =====================================================
-- 8. TRIGGERS
-- =====================================================

-- Update feed progression on interaction
CREATE OR REPLACE FUNCTION public.update_feed_progression_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_feed_progression (user_id, total_interactions, last_feed_activity_date)
  VALUES (NEW.user_id, 1, CURRENT_DATE)
  ON CONFLICT (user_id)
  DO UPDATE SET
    total_interactions = user_feed_progression.total_interactions + 1,
    last_feed_activity_date = CURRENT_DATE,
    updated_at = now();
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_feed_progression ON public.user_feed_quest_progress;
CREATE TRIGGER trigger_update_feed_progression
AFTER INSERT ON public.user_feed_quest_progress
FOR EACH ROW
EXECUTE FUNCTION public.update_feed_progression_trigger();

-- =====================================================
-- 9. FEATURE FLAGS FOR GAMIFICATION
-- =====================================================

-- Ensure feature_flags table exists with all required columns
CREATE TABLE IF NOT EXISTS public.feature_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  flag_key TEXT NOT NULL,
  feature_name TEXT NOT NULL UNIQUE,
  is_enabled BOOLEAN DEFAULT false,
  category TEXT NOT NULL,
  description TEXT,
  usage_count INTEGER DEFAULT 0,
  rollout_percentage INTEGER DEFAULT 100 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  scheduled_enable_at TIMESTAMPTZ,
  scheduled_disable_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Add dependencies column if it doesn't exist (for compatibility with later migrations)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'feature_flags'
    AND column_name = 'dependencies'
  ) THEN
    ALTER TABLE public.feature_flags ADD COLUMN dependencies TEXT[] DEFAULT ARRAY[]::TEXT[];
  END IF;
END $$;

-- Insert gamification feature flags
INSERT INTO public.feature_flags (flag_key, flag_name, feature_name, category, is_enabled, description, dependencies) VALUES
('vp_system', 'vp_system', 'vp_system', 'gamification', true, 'Vottery Points universal currency system', ARRAY[]::TEXT[]),
('progression_levels', 'progression_levels', 'progression_levels', 'gamification', true, 'User progression levels with VP multipliers', ARRAY['vp_system']),
('badges_achievements', 'badges_achievements', 'badges_achievements', 'gamification', true, 'Badge and achievement system', ARRAY['vp_system']),
('streaks_system', 'streaks_system', 'streaks_system', 'gamification', true, 'Daily/weekly streak tracking with multipliers', ARRAY['vp_system']),
('leaderboards', 'leaderboards', 'leaderboards', 'gamification', true, 'Global/regional/friends leaderboards', ARRAY['vp_system']),
('prediction_pools', 'prediction_pools', 'prediction_pools', 'gamification', true, 'Election prediction pools with Brier scoring', ARRAY['vp_system']),
('daily_weekly_challenges', 'daily_weekly_challenges', 'daily_weekly_challenges', 'gamification', true, 'Daily and weekly challenge quests', ARRAY['vp_system']),
('rewards_shop', 'rewards_shop', 'rewards_shop', 'gamification', true, 'VP redemption rewards shop', ARRAY['vp_system']),
('feed_gamification', 'feed_gamification', 'feed_gamification', 'gamification', true, 'Feed quest dashboard with daily challenges', ARRAY['vp_system', 'daily_weekly_challenges']),
('ad_gamification', 'ad_gamification', 'ad_gamification', 'gamification', true, 'Participatory ads gamification with mini-games', ARRAY['vp_system']),
('jolts_gamification', 'jolts_gamification', 'jolts_gamification', 'gamification', true, 'Jolts VP earnings and creator badges', ARRAY['vp_system', 'badges_achievements'])
ON CONFLICT (feature_name) DO UPDATE SET
  flag_key = EXCLUDED.flag_key,
  flag_name = EXCLUDED.flag_name,
  category = EXCLUDED.category,
  description = EXCLUDED.description,
  dependencies = EXCLUDED.dependencies;