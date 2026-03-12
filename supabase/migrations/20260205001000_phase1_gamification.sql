-- Phase 1: Core Voting & Gamification Features Migration
-- Timestamp: 20260205001000
-- Description: VP economy, achievements, levels, streaks, and enhanced voting types

-- ============================================================
-- 1. TYPES (with idempotency)
-- ============================================================

DROP TYPE IF EXISTS public.vp_transaction_type CASCADE;
CREATE TYPE public.vp_transaction_type AS ENUM (
  'voting',
  'social_interaction',
  'challenge_completion',
  'prediction_reward',
  'streak_bonus',
  'achievement_unlock',
  'spending',
  'refund',
  'admin_adjustment'
);

DROP TYPE IF EXISTS public.achievement_category CASCADE;
CREATE TYPE public.achievement_category AS ENUM (
  'voting',
  'social',
  'challenge',
  'prediction',
  'streak',
  'vp',
  'level',
  'special'
);

DROP TYPE IF EXISTS public.vote_type CASCADE;
CREATE TYPE public.vote_type AS ENUM (
  'plurality',
  'ranked_choice',
  'approval',
  'plus_minus'
);

-- ============================================================
-- 2. CORE TABLES (with IF NOT EXISTS)
-- ============================================================

-- VP Balance Table (extends existing wallet functionality)
CREATE TABLE IF NOT EXISTS public.vp_balance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  available_vp INTEGER NOT NULL DEFAULT 0,
  lifetime_earned INTEGER NOT NULL DEFAULT 0,
  lifetime_spent INTEGER NOT NULL DEFAULT 0,
  current_streak_days INTEGER NOT NULL DEFAULT 0,
  longest_streak_days INTEGER NOT NULL DEFAULT 0,
  last_activity_date DATE,
  vp_multiplier NUMERIC(3,2) NOT NULL DEFAULT 1.00,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

-- VP Transactions Table
CREATE TABLE IF NOT EXISTS public.vp_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  transaction_type public.vp_transaction_type NOT NULL,
  amount INTEGER NOT NULL,
  balance_before INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  description TEXT,
  reference_id UUID,
  reference_type TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Achievements Table
CREATE TABLE IF NOT EXISTS public.achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  achievement_key TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category public.achievement_category NOT NULL,
  icon_name TEXT NOT NULL,
  vp_reward INTEGER NOT NULL DEFAULT 0,
  xp_reward INTEGER NOT NULL DEFAULT 0,
  requirement_value INTEGER NOT NULL DEFAULT 1,
  requirement_description TEXT,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User Achievements Table
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES public.achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  progress_value INTEGER DEFAULT 0,
  is_completed BOOLEAN DEFAULT false,
  UNIQUE(user_id, achievement_id)
);

-- User Levels Table
CREATE TABLE IF NOT EXISTS public.user_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  current_level INTEGER NOT NULL DEFAULT 1,
  current_xp INTEGER NOT NULL DEFAULT 0,
  total_xp INTEGER NOT NULL DEFAULT 0,
  level_title TEXT NOT NULL DEFAULT 'Bronze Voter',
  vp_multiplier NUMERIC(3,2) NOT NULL DEFAULT 1.00,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

-- Streaks Table
CREATE TABLE IF NOT EXISTS public.user_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  last_activity_date DATE,
  streak_multiplier NUMERIC(3,2) NOT NULL DEFAULT 1.00,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

-- ============================================================
-- 3. INDEXES (with IF NOT EXISTS)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_vp_balance_user_id ON public.vp_balance(user_id);
CREATE INDEX IF NOT EXISTS idx_vp_transactions_user_id ON public.vp_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_vp_transactions_created_at ON public.vp_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_completed ON public.user_achievements(user_id, is_completed);
CREATE INDEX IF NOT EXISTS idx_user_levels_user_id ON public.user_levels(user_id);
CREATE INDEX IF NOT EXISTS idx_user_streaks_user_id ON public.user_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_category ON public.achievements(category);

-- ============================================================
-- 4. FUNCTIONS (BEFORE RLS POLICIES)
-- ============================================================

-- Function to update VP balance
CREATE OR REPLACE FUNCTION public.update_vp_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.vp_balance
  SET 
    available_vp = NEW.balance_after,
    lifetime_earned = CASE 
      WHEN NEW.amount > 0 THEN lifetime_earned + NEW.amount 
      ELSE lifetime_earned 
    END,
    lifetime_spent = CASE 
      WHEN NEW.amount < 0 THEN lifetime_spent + ABS(NEW.amount) 
      ELSE lifetime_spent 
    END,
    updated_at = CURRENT_TIMESTAMP
  WHERE user_id = NEW.user_id;
  
  RETURN NEW;
END;
$$;

-- Function to update user level
CREATE OR REPLACE FUNCTION public.calculate_level_from_xp(xp_amount INTEGER)
RETURNS TABLE(level INTEGER, title TEXT, multiplier NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
  calculated_level INTEGER;
  level_title TEXT;
  vp_mult NUMERIC;
BEGIN
  -- 10-tier level system
  CASE
    WHEN xp_amount >= 50000 THEN 
      calculated_level := 10;
      level_title := 'Elite Master';
      vp_mult := 5.00;
    WHEN xp_amount >= 25000 THEN 
      calculated_level := 9;
      level_title := 'Platinum Champion';
      vp_mult := 4.00;
    WHEN xp_amount >= 15000 THEN 
      calculated_level := 8;
      level_title := 'Gold Expert';
      vp_mult := 3.50;
    WHEN xp_amount >= 10000 THEN 
      calculated_level := 7;
      level_title := 'Gold Advocate';
      vp_mult := 3.00;
    WHEN xp_amount >= 5000 THEN 
      calculated_level := 6;
      level_title := 'Silver Leader';
      vp_mult := 2.50;
    WHEN xp_amount >= 2500 THEN 
      calculated_level := 5;
      level_title := 'Silver Contributor';
      vp_mult := 2.00;
    WHEN xp_amount >= 1000 THEN 
      calculated_level := 4;
      level_title := 'Bronze Activist';
      vp_mult := 1.75;
    WHEN xp_amount >= 500 THEN 
      calculated_level := 3;
      level_title := 'Bronze Participant';
      vp_mult := 1.50;
    WHEN xp_amount >= 100 THEN 
      calculated_level := 2;
      level_title := 'Bronze Voter';
      vp_mult := 1.25;
    ELSE 
      calculated_level := 1;
      level_title := 'Novice';
      vp_mult := 1.00;
  END CASE;
  
  RETURN QUERY SELECT calculated_level, level_title, vp_mult;
END;
$$;

-- ============================================================
-- 5. ENABLE RLS
-- ============================================================

ALTER TABLE public.vp_balance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vp_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_levels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 6. RLS POLICIES (AFTER functions)
-- ============================================================

-- VP Balance Policies
DROP POLICY IF EXISTS "users_view_own_vp_balance" ON public.vp_balance;
CREATE POLICY "users_view_own_vp_balance"
ON public.vp_balance
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_update_own_vp_balance" ON public.vp_balance;
CREATE POLICY "users_update_own_vp_balance"
ON public.vp_balance
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- VP Transactions Policies
DROP POLICY IF EXISTS "users_view_own_vp_transactions" ON public.vp_transactions;
CREATE POLICY "users_view_own_vp_transactions"
ON public.vp_transactions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_insert_own_vp_transactions" ON public.vp_transactions;
CREATE POLICY "users_insert_own_vp_transactions"
ON public.vp_transactions
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Achievements Policies (public read)
DROP POLICY IF EXISTS "public_read_achievements" ON public.achievements;
CREATE POLICY "public_read_achievements"
ON public.achievements
FOR SELECT
TO public
USING (is_active = true);

-- User Achievements Policies
DROP POLICY IF EXISTS "users_manage_own_achievements" ON public.user_achievements;
CREATE POLICY "users_manage_own_achievements"
ON public.user_achievements
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- User Levels Policies
DROP POLICY IF EXISTS "users_view_own_level" ON public.user_levels;
CREATE POLICY "users_view_own_level"
ON public.user_levels
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_update_own_level" ON public.user_levels;
CREATE POLICY "users_update_own_level"
ON public.user_levels
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- User Streaks Policies
DROP POLICY IF EXISTS "users_manage_own_streaks" ON public.user_streaks;
CREATE POLICY "users_manage_own_streaks"
ON public.user_streaks
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================
-- 7. TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS update_vp_balance_trigger ON public.vp_transactions;
CREATE TRIGGER update_vp_balance_trigger
AFTER INSERT ON public.vp_transactions
FOR EACH ROW
EXECUTE FUNCTION public.update_vp_balance();

-- ============================================================
-- 8. MOCK DATA (with safety patterns)
-- ============================================================

-- Insert achievements
DO $$
BEGIN
  INSERT INTO public.achievements (achievement_key, title, description, category, icon_name, vp_reward, xp_reward, requirement_value, requirement_description, display_order) VALUES
    ('first_vote', 'First Vote', 'Cast your first vote', 'voting'::public.achievement_category, 'how_to_vote', 50, 10, 1, 'Cast 1 vote', 1),
    ('vote_streak_7', '7-Day Streak', 'Vote for 7 consecutive days', 'streak'::public.achievement_category, 'local_fire_department', 100, 50, 7, 'Maintain 7-day voting streak', 2),
    ('vote_streak_30', '30-Day Streak', 'Vote for 30 consecutive days', 'streak'::public.achievement_category, 'whatshot', 500, 200, 30, 'Maintain 30-day voting streak', 3),
    ('social_butterfly', 'Social Butterfly', 'Interact with 50 other users', 'social'::public.achievement_category, 'groups', 200, 100, 50, 'Interact with 50 users', 4),
    ('prediction_master', 'Prediction Master', 'Win 10 prediction pools', 'prediction'::public.achievement_category, 'psychology', 1000, 500, 10, 'Win 10 predictions', 5),
    ('vp_millionaire', 'VP Millionaire', 'Earn 1,000,000 lifetime VP', 'vp'::public.achievement_category, 'diamond', 5000, 1000, 1000000, 'Earn 1M VP', 6),
    ('level_5', 'Silver Contributor', 'Reach level 5', 'level'::public.achievement_category, 'military_tech', 300, 150, 5, 'Reach level 5', 7),
    ('level_10', 'Elite Master', 'Reach level 10', 'level'::public.achievement_category, 'emoji_events', 2000, 1000, 10, 'Reach level 10', 8),
    ('challenge_complete_10', 'Challenge Champion', 'Complete 10 challenges', 'challenge'::public.achievement_category, 'flag', 500, 250, 10, 'Complete 10 challenges', 9),
    ('early_adopter', 'Early Adopter', 'Join during beta period', 'special'::public.achievement_category, 'star', 1000, 500, 1, 'Join during beta', 10)
  ON CONFLICT (achievement_key) DO NOTHING;
END $$;

-- Initialize VP balance, levels, and streaks for existing users
DO $$
DECLARE
  existing_user_id UUID;
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) THEN
    FOR existing_user_id IN SELECT id FROM public.user_profiles LIMIT 3
    LOOP
      -- Initialize VP balance
      INSERT INTO public.vp_balance (user_id, available_vp, lifetime_earned)
      VALUES (existing_user_id, 100, 100)
      ON CONFLICT (user_id) DO NOTHING;
      
      -- Initialize user level
      INSERT INTO public.user_levels (user_id, current_level, current_xp, total_xp, level_title, vp_multiplier)
      VALUES (existing_user_id, 1, 0, 0, 'Novice', 1.00)
      ON CONFLICT (user_id) DO NOTHING;
      
      -- Initialize streak
      INSERT INTO public.user_streaks (user_id, current_streak, longest_streak, last_activity_date)
      VALUES (existing_user_id, 0, 0, CURRENT_DATE)
      ON CONFLICT (user_id) DO NOTHING;
      
      -- Award first achievement
      INSERT INTO public.user_achievements (user_id, achievement_id, is_completed, progress_value)
      SELECT existing_user_id, id, true, 1
      FROM public.achievements
      WHERE achievement_key = 'first_vote'
      ON CONFLICT (user_id, achievement_id) DO NOTHING;
    END LOOP;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data initialization failed: %', SQLERRM;
END $$;
