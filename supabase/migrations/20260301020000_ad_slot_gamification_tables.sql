-- Ad Slot Manager & Gamification Tables Migration
-- Ensures all required tables exist for Ad Slot Orchestration and Real-time Gamification

-- ─── sponsored_elections: ensure required columns exist ─────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'sponsored_elections'
  ) THEN
    CREATE TABLE public.sponsored_elections (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      campaign_name TEXT NOT NULL,
      description TEXT,
      image_url TEXT,
      ad_format_type TEXT DEFAULT 'market_research',
      status TEXT DEFAULT 'draft',
      target_zones JSONB DEFAULT '[]'::jsonb,
      bid_amount NUMERIC(10,2) DEFAULT 0,
      engagement_metrics JSONB DEFAULT '{}'::jsonb,
      election_id UUID,
      budget_config JSONB DEFAULT '{}'::jsonb,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    );
  END IF;
END $$;

-- ─── ad_impressions ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ad_impressions (
  impression_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  ad_id UUID NOT NULL,
  slot_id TEXT NOT NULL,
  impression_timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ad_impressions_user_ad_date
  ON public.ad_impressions (user_id, ad_id, impression_timestamp);

-- ─── ad_clicks ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ad_clicks (
  click_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  ad_id UUID NOT NULL,
  clicked_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ad_clicks_user_ad
  ON public.ad_clicks (user_id, ad_id);

-- ─── user_vp_transactions ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_vp_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  amount INTEGER NOT NULL DEFAULT 0,
  source TEXT NOT NULL DEFAULT 'activity',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_vp_transactions_user_id
  ON public.user_vp_transactions (user_id);

-- ─── user_quests ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_quests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  quest_name TEXT NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_quests_user_id
  ON public.user_quests (user_id);

-- ─── user_achievements ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  badge_name TEXT NOT NULL,
  badge_icon TEXT DEFAULT '🏆',
  awarded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id
  ON public.user_achievements (user_id);

-- ─── user_streaks ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_activity_date DATE,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_streaks_user_id
  ON public.user_streaks (user_id);

-- ─── leaderboard_positions ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.leaderboard_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  leaderboard_name TEXT NOT NULL,
  rank INTEGER NOT NULL DEFAULT 0,
  score NUMERIC DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, leaderboard_name)
);

CREATE INDEX IF NOT EXISTS idx_leaderboard_positions_user_id
  ON public.leaderboard_positions (user_id);

-- ─── RLS Policies ────────────────────────────────────────────────────────────
ALTER TABLE public.ad_impressions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_clicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_vp_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard_positions ENABLE ROW LEVEL SECURITY;

-- ad_impressions policies
DROP POLICY IF EXISTS "Users can insert own impressions" ON public.ad_impressions;
CREATE POLICY "Users can insert own impressions"
  ON public.ad_impressions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can read own impressions" ON public.ad_impressions;
CREATE POLICY "Users can read own impressions"
  ON public.ad_impressions FOR SELECT
  USING (auth.uid() = user_id);

-- ad_clicks policies
DROP POLICY IF EXISTS "Users can insert own clicks" ON public.ad_clicks;
CREATE POLICY "Users can insert own clicks"
  ON public.ad_clicks FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- user_vp_transactions policies
DROP POLICY IF EXISTS "Users can read own vp transactions" ON public.user_vp_transactions;
CREATE POLICY "Users can read own vp transactions"
  ON public.user_vp_transactions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service can insert vp transactions" ON public.user_vp_transactions;
CREATE POLICY "Service can insert vp transactions"
  ON public.user_vp_transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- user_quests policies
DROP POLICY IF EXISTS "Users can read own quests" ON public.user_quests;
CREATE POLICY "Users can read own quests"
  ON public.user_quests FOR SELECT
  USING (auth.uid() = user_id);

-- user_achievements policies
DROP POLICY IF EXISTS "Users can read own achievements" ON public.user_achievements;
CREATE POLICY "Users can read own achievements"
  ON public.user_achievements FOR SELECT
  USING (auth.uid() = user_id);

-- user_streaks policies
DROP POLICY IF EXISTS "Users can read own streaks" ON public.user_streaks;
CREATE POLICY "Users can read own streaks"
  ON public.user_streaks FOR SELECT
  USING (auth.uid() = user_id);

-- leaderboard_positions policies
DROP POLICY IF EXISTS "Users can read own leaderboard positions" ON public.leaderboard_positions;
CREATE POLICY "Users can read own leaderboard positions"
  ON public.leaderboard_positions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can read leaderboard" ON public.leaderboard_positions;
CREATE POLICY "Public can read leaderboard"
  ON public.leaderboard_positions FOR SELECT
  USING (true);

-- Enable realtime for gamification tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_vp_transactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_quests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_achievements;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_streaks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.leaderboard_positions;
