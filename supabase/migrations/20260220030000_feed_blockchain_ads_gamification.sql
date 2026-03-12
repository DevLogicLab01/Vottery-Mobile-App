-- Feed Gamification, Blockchain Logging, and Participatory Ads Gamification Migration
-- Creates tables for feed quests, blockchain gamification logs, and ad gamification features

-- =====================================================
-- FEED GAMIFICATION TABLES
-- =====================================================

-- Feed Quests Table
CREATE TABLE IF NOT EXISTS public.feed_quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_type TEXT NOT NULL CHECK (quest_type IN ('scroll_posts', 'like_jolts', 'comment_posts', 'share_posts', 'mini_game', 'trivia_quiz', 'prediction_card')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  target_count INTEGER NOT NULL DEFAULT 1,
  vp_reward INTEGER NOT NULL DEFAULT 20,
  quest_frequency TEXT NOT NULL CHECK (quest_frequency IN ('daily', 'weekly', 'monthly')) DEFAULT 'daily',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Feed Quest Progress Table
CREATE TABLE IF NOT EXISTS public.user_feed_quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quest_id UUID NOT NULL REFERENCES public.feed_quests(id) ON DELETE CASCADE,
  current_progress INTEGER DEFAULT 0,
  target_count INTEGER NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  quest_date DATE NOT NULL DEFAULT CURRENT_DATE,
  vp_earned INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, quest_id, quest_date)
);

-- Feed Progression Levels Table
CREATE TABLE IF NOT EXISTS public.feed_progression_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  level_tier TEXT NOT NULL CHECK (level_tier IN ('bronze_explorer', 'silver_engager', 'gold_influencer')) DEFAULT 'bronze_explorer',
  total_interactions INTEGER DEFAULT 0,
  vp_multiplier NUMERIC(3,2) DEFAULT 1.00,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feed Streaks Table
CREATE TABLE IF NOT EXISTS public.feed_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_interaction_date DATE DEFAULT CURRENT_DATE,
  streak_bonus_multiplier NUMERIC(3,2) DEFAULT 1.00,
  seven_day_bonus_unlocked BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feed Mini-Games Results Table
CREATE TABLE IF NOT EXISTS public.feed_mini_game_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  game_type TEXT NOT NULL CHECK (game_type IN ('quick_poll', 'trivia_quiz', 'prediction_card')),
  post_id UUID,
  score INTEGER DEFAULT 0,
  vp_earned INTEGER DEFAULT 0,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feed Leaderboards Table
CREATE TABLE IF NOT EXISTS public.feed_leaderboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  leaderboard_type TEXT NOT NULL CHECK (leaderboard_type IN ('global', 'friends', 'groups', 'weekly', 'monthly')) DEFAULT 'global',
  total_vp_earned INTEGER DEFAULT 0,
  total_interactions INTEGER DEFAULT 0,
  rank INTEGER,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, leaderboard_type, period_start, period_end)
);

-- =====================================================
-- BLOCKCHAIN GAMIFICATION LOGGING TABLES
-- =====================================================

-- Blockchain Gamification Transactions Table
CREATE TABLE IF NOT EXISTS public.blockchain_gamification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('vp_transaction', 'badge_award', 'challenge_completion', 'prediction_resolution')),
  transaction_hash TEXT NOT NULL UNIQUE,
  block_number BIGINT,
  merkle_root TEXT,
  cryptographic_signature TEXT,
  transaction_data JSONB NOT NULL,
  vp_amount INTEGER,
  badge_id UUID,
  challenge_id UUID,
  prediction_pool_id UUID,
  blockchain_network TEXT DEFAULT 'polygon',
  verification_status TEXT CHECK (verification_status IN ('pending', 'verified', 'failed')) DEFAULT 'pending',
  gas_fee_wei BIGINT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  verified_at TIMESTAMPTZ
);

-- Blockchain Audit Trail Table
CREATE TABLE IF NOT EXISTS public.blockchain_audit_trail (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gamification_log_id UUID NOT NULL REFERENCES public.blockchain_gamification_logs(id) ON DELETE CASCADE,
  audit_event TEXT NOT NULL,
  auditor_id UUID REFERENCES auth.users(id),
  audit_data JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Merkle Tree Batches Table
CREATE TABLE IF NOT EXISTS public.merkle_tree_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_number INTEGER NOT NULL UNIQUE,
  merkle_root TEXT NOT NULL,
  transaction_count INTEGER DEFAULT 0,
  total_vp_distributed INTEGER DEFAULT 0,
  batch_status TEXT CHECK (batch_status IN ('pending', 'processing', 'completed', 'failed')) DEFAULT 'pending',
  blockchain_tx_hash TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- =====================================================
-- PARTICIPATORY ADS GAMIFICATION TABLES
-- =====================================================

-- Ad Mini-Games Table
CREATE TABLE IF NOT EXISTS public.ad_mini_games (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_campaign_id UUID NOT NULL,
  game_type TEXT NOT NULL CHECK (game_type IN ('spin_wheel', 'memory_match', 'scratch_card')),
  game_config JSONB NOT NULL,
  min_vp_reward INTEGER DEFAULT 10,
  max_vp_reward INTEGER DEFAULT 100,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Ad Mini-Game Results Table
CREATE TABLE IF NOT EXISTS public.user_ad_mini_game_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ad_mini_game_id UUID NOT NULL REFERENCES public.ad_mini_games(id) ON DELETE CASCADE,
  game_result JSONB,
  vp_earned INTEGER DEFAULT 0,
  played_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Campaign Quest Chains Table
CREATE TABLE IF NOT EXISTS public.campaign_quest_chains (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chain_name TEXT NOT NULL,
  brand_name TEXT NOT NULL,
  required_ad_votes INTEGER DEFAULT 3,
  badge_reward TEXT DEFAULT 'Brand Master',
  vp_reward INTEGER DEFAULT 200,
  related_ad_ids UUID[] NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Campaign Quest Progress Table
CREATE TABLE IF NOT EXISTS public.user_campaign_quest_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quest_chain_id UUID NOT NULL REFERENCES public.campaign_quest_chains(id) ON DELETE CASCADE,
  ads_voted_count INTEGER DEFAULT 0,
  required_votes INTEGER NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  badge_awarded TEXT,
  vp_earned INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, quest_chain_id)
);

-- Ad Leaderboards Table
CREATE TABLE IF NOT EXISTS public.ad_leaderboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ad_category TEXT NOT NULL CHECK (ad_category IN ('movie', 'product', 'csr')),
  prediction_accuracy NUMERIC(5,2) DEFAULT 0.00,
  total_ad_votes INTEGER DEFAULT 0,
  rank INTEGER,
  prizes_won JSONB DEFAULT '[]'::jsonb,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, ad_category, period_start, period_end)
);

-- CSR Impact Meters Table
CREATE TABLE IF NOT EXISTS public.csr_impact_meters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_campaign_id UUID NOT NULL,
  charity_name TEXT NOT NULL,
  donation_goal NUMERIC(12,2) NOT NULL,
  current_donations NUMERIC(12,2) DEFAULT 0.00,
  total_votes INTEGER DEFAULT 0,
  goal_percentage NUMERIC(5,2) DEFAULT 0.00,
  badge_reward TEXT DEFAULT 'Earth Hero',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User CSR Contributions Table
CREATE TABLE IF NOT EXISTS public.user_csr_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  csr_impact_meter_id UUID NOT NULL REFERENCES public.csr_impact_meters(id) ON DELETE CASCADE,
  contribution_percentage NUMERIC(5,2) DEFAULT 0.00,
  votes_contributed INTEGER DEFAULT 0,
  badge_earned TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, csr_impact_meter_id)
);

-- Ad Streaks Table
CREATE TABLE IF NOT EXISTS public.ad_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_ad_vote_date DATE DEFAULT CURRENT_DATE,
  streak_multiplier NUMERIC(3,2) DEFAULT 2.00,
  streak_saver_used BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_user_feed_quest_progress_user_id ON public.user_feed_quest_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_feed_quest_progress_quest_date ON public.user_feed_quest_progress(quest_date);
CREATE INDEX IF NOT EXISTS idx_feed_progression_levels_user_id ON public.feed_progression_levels(user_id);
CREATE INDEX IF NOT EXISTS idx_feed_streaks_user_id ON public.feed_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_gamification_logs_user_id ON public.blockchain_gamification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_gamification_logs_transaction_hash ON public.blockchain_gamification_logs(transaction_hash);
CREATE INDEX IF NOT EXISTS idx_user_campaign_quest_progress_user_id ON public.user_campaign_quest_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_ad_leaderboards_user_id ON public.ad_leaderboards(user_id);
CREATE INDEX IF NOT EXISTS idx_ad_leaderboards_ad_category ON public.ad_leaderboards(ad_category);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Feed Quests (Public Read)
ALTER TABLE public.feed_quests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Feed quests are viewable by everyone" ON public.feed_quests FOR SELECT USING (true);

-- User Feed Quest Progress (User-specific)
ALTER TABLE public.user_feed_quest_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own feed quest progress" ON public.user_feed_quest_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own feed quest progress" ON public.user_feed_quest_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own feed quest progress" ON public.user_feed_quest_progress FOR UPDATE USING (auth.uid() = user_id);

-- Feed Progression Levels (User-specific)
ALTER TABLE public.feed_progression_levels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own feed progression" ON public.feed_progression_levels FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own feed progression" ON public.feed_progression_levels FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own feed progression" ON public.feed_progression_levels FOR UPDATE USING (auth.uid() = user_id);

-- Feed Streaks (User-specific)
ALTER TABLE public.feed_streaks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own feed streaks" ON public.feed_streaks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own feed streaks" ON public.feed_streaks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own feed streaks" ON public.feed_streaks FOR UPDATE USING (auth.uid() = user_id);

-- Blockchain Gamification Logs (User-specific read, system write)
ALTER TABLE public.blockchain_gamification_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own blockchain logs" ON public.blockchain_gamification_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can insert blockchain logs" ON public.blockchain_gamification_logs FOR INSERT WITH CHECK (true);

-- User Campaign Quest Progress (User-specific)
ALTER TABLE public.user_campaign_quest_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own campaign quest progress" ON public.user_campaign_quest_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own campaign quest progress" ON public.user_campaign_quest_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own campaign quest progress" ON public.user_campaign_quest_progress FOR UPDATE USING (auth.uid() = user_id);

-- Ad Leaderboards (Public read)
ALTER TABLE public.ad_leaderboards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Ad leaderboards are viewable by everyone" ON public.ad_leaderboards FOR SELECT USING (true);

-- Ad Streaks (User-specific)
ALTER TABLE public.ad_streaks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own ad streaks" ON public.ad_streaks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own ad streaks" ON public.ad_streaks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own ad streaks" ON public.ad_streaks FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update feed progression level
CREATE OR REPLACE FUNCTION update_feed_progression_level()
RETURNS TRIGGER AS $$
BEGIN
  -- Update total interactions
  UPDATE public.feed_progression_levels
  SET 
    total_interactions = total_interactions + 1,
    level_tier = CASE
      WHEN total_interactions + 1 >= 2000 THEN 'gold_influencer'
      WHEN total_interactions + 1 >= 500 THEN 'silver_engager'
      ELSE 'bronze_explorer'
    END,
    vp_multiplier = CASE
      WHEN total_interactions + 1 >= 2000 THEN 2.00
      WHEN total_interactions + 1 >= 500 THEN 1.50
      ELSE 1.00
    END,
    updated_at = NOW()
  WHERE user_id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update feed streak
CREATE OR REPLACE FUNCTION update_feed_streak(p_user_id UUID)
RETURNS void AS $$
DECLARE
  v_last_date DATE;
  v_current_streak INTEGER;
BEGIN
  SELECT last_interaction_date, current_streak INTO v_last_date, v_current_streak
  FROM public.feed_streaks
  WHERE user_id = p_user_id;
  
  IF v_last_date = CURRENT_DATE THEN
    -- Already interacted today, no change
    RETURN;
  ELSIF v_last_date = CURRENT_DATE - INTERVAL '1 day' THEN
    -- Consecutive day, increment streak
    UPDATE public.feed_streaks
    SET 
      current_streak = current_streak + 1,
      longest_streak = GREATEST(longest_streak, current_streak + 1),
      last_interaction_date = CURRENT_DATE,
      streak_bonus_multiplier = CASE WHEN current_streak + 1 >= 7 THEN 2.00 ELSE 1.00 END,
      seven_day_bonus_unlocked = CASE WHEN current_streak + 1 >= 7 THEN true ELSE false END,
      updated_at = NOW()
    WHERE user_id = p_user_id;
  ELSE
    -- Streak broken, reset
    UPDATE public.feed_streaks
    SET 
      current_streak = 1,
      last_interaction_date = CURRENT_DATE,
      streak_bonus_multiplier = 1.00,
      seven_day_bonus_unlocked = false,
      updated_at = NOW()
    WHERE user_id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to log blockchain gamification transaction
CREATE OR REPLACE FUNCTION log_blockchain_gamification(
  p_user_id UUID,
  p_transaction_type TEXT,
  p_transaction_data JSONB,
  p_vp_amount INTEGER DEFAULT NULL,
  p_badge_id UUID DEFAULT NULL,
  p_challenge_id UUID DEFAULT NULL,
  p_prediction_pool_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_log_id UUID;
  v_transaction_hash TEXT;
BEGIN
  -- Generate transaction hash (simplified - in production use proper blockchain hash)
  v_transaction_hash := encode(digest(p_user_id::text || p_transaction_type || NOW()::text || random()::text, 'sha256'), 'hex');
  
  INSERT INTO public.blockchain_gamification_logs (
    user_id,
    transaction_type,
    transaction_hash,
    transaction_data,
    vp_amount,
    badge_id,
    challenge_id,
    prediction_pool_id,
    verification_status
  ) VALUES (
    p_user_id,
    p_transaction_type,
    v_transaction_hash,
    p_transaction_data,
    p_vp_amount,
    p_badge_id,
    p_challenge_id,
    p_prediction_pool_id,
    'pending'
  ) RETURNING id INTO v_log_id;
  
  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- SEED DATA
-- =====================================================

-- Insert default feed quests
INSERT INTO public.feed_quests (quest_type, title, description, target_count, vp_reward, quest_frequency) VALUES
('scroll_posts', 'Feed Explorer', 'Scroll through 10 posts', 10, 20, 'daily'),
('like_jolts', 'Jolt Enthusiast', 'Like 5 Jolts videos', 5, 30, 'daily'),
('comment_posts', 'Conversation Starter', 'Comment on 3 posts', 3, 40, 'daily'),
('share_posts', 'Content Sharer', 'Share 2 posts', 2, 50, 'daily'),
('mini_game', 'Quick Gamer', 'Complete 3 mini-games', 3, 60, 'daily'),
('trivia_quiz', 'Trivia Master', 'Answer 5 trivia questions correctly', 5, 70, 'weekly'),
('prediction_card', 'Prediction Pro', 'Make 3 accurate predictions', 3, 80, 'weekly')
ON CONFLICT DO NOTHING;

-- Insert sample campaign quest chains
INSERT INTO public.campaign_quest_chains (chain_name, brand_name, required_ad_votes, badge_reward, vp_reward, related_ad_ids) VALUES
('Movie Marathon Master', 'Universal Studios', 3, 'Brand Master - Movies', 200, ARRAY[]::UUID[]),
('Product Pioneer', 'Tech Brands', 3, 'Brand Master - Products', 200, ARRAY[]::UUID[]),
('CSR Champion', 'Charity Partners', 3, 'Brand Master - CSR', 200, ARRAY[]::UUID[])
ON CONFLICT DO NOTHING;

-- Add gamification feature flags
INSERT INTO public.feature_flags (feature_key, feature_name, category, is_enabled, description) VALUES
('feed_gamification', 'Feed Gamification', 'gamification', true, 'Enable feed quests, mini-games, and leaderboards'),
('blockchain_gamification_logging', 'Blockchain Gamification Logging', 'gamification', true, 'Enable immutable blockchain logging for VP transactions and badges'),
('ad_gamification', 'Participatory Ads Gamification', 'gamification', true, 'Enable ad mini-games, quest chains, and leaderboards')
ON CONFLICT (feature_key) DO UPDATE SET
  category = EXCLUDED.category,
  description = EXCLUDED.description;