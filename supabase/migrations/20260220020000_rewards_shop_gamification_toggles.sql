-- =====================================================
-- Rewards Shop & Gamification Toggles Migration
-- Creates rewards shop items, VP redemptions, and gamification feature flags
-- Timestamp: 20260220020000
-- =====================================================

-- ============================================================================
-- 1. TYPES
-- ============================================================================

DROP TYPE IF EXISTS public.reward_category CASCADE;
CREATE TYPE public.reward_category AS ENUM (
  'platform_perks',
  'election_enhancements',
  'social_rewards',
  'real_world_rewards',
  'vip_tiers'
);

DROP TYPE IF EXISTS public.redemption_status CASCADE;
CREATE TYPE public.redemption_status AS ENUM (
  'pending',
  'processing',
  'completed',
  'failed',
  'refunded'
);

-- ============================================================================
-- 2. TABLES
-- ============================================================================

-- Rewards Shop Items Table
CREATE TABLE IF NOT EXISTS public.rewards_shop_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category public.reward_category NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  vp_cost INTEGER NOT NULL CHECK (vp_cost > 0),
  cash_equivalent_usd DECIMAL(10, 2) DEFAULT 0,
  icon_name TEXT DEFAULT 'card_giftcard',
  is_available BOOLEAN DEFAULT true,
  stock_quantity INTEGER,
  requires_stripe BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}'::jsonb,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- VP Redemptions Table
CREATE TABLE IF NOT EXISTS public.vp_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reward_item_id UUID NOT NULL REFERENCES public.rewards_shop_items(id) ON DELETE RESTRICT,
  vp_spent INTEGER NOT NULL,
  cash_paid_usd DECIMAL(10, 2) DEFAULT 0,
  status public.redemption_status DEFAULT 'pending'::public.redemption_status,
  stripe_payment_intent_id TEXT,
  fulfillment_details JSONB DEFAULT '{}'::jsonb,
  redeemed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 3. INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_rewards_shop_items_category ON public.rewards_shop_items(category);
CREATE INDEX IF NOT EXISTS idx_rewards_shop_items_available ON public.rewards_shop_items(is_available);
CREATE INDEX IF NOT EXISTS idx_vp_redemptions_user_id ON public.vp_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_vp_redemptions_status ON public.vp_redemptions(status);
CREATE INDEX IF NOT EXISTS idx_vp_redemptions_reward_item_id ON public.vp_redemptions(reward_item_id);

-- ============================================================================
-- 4. ENABLE RLS
-- ============================================================================

ALTER TABLE public.rewards_shop_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vp_redemptions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. RLS POLICIES
-- ============================================================================

-- Rewards Shop Items: Public read, admin write
DROP POLICY IF EXISTS "public_can_view_rewards_shop_items" ON public.rewards_shop_items;
CREATE POLICY "public_can_view_rewards_shop_items"
ON public.rewards_shop_items
FOR SELECT
TO public
USING (is_available = true);

-- VP Redemptions: Users manage own redemptions
DROP POLICY IF EXISTS "users_manage_own_vp_redemptions" ON public.vp_redemptions;
CREATE POLICY "users_manage_own_vp_redemptions"
ON public.vp_redemptions
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- 6. GAMIFICATION FEATURE FLAGS
-- ============================================================================

-- Insert gamification feature flags
DO $$
BEGIN
  -- Insert gamification category feature flags
  INSERT INTO public.feature_flags (
    id, feature_name, category, description, is_enabled, rollout_percentage,
    dependencies, created_at, updated_at
  ) VALUES
    (gen_random_uuid(), 'vp_system', 'gamification', 'Vottery Points (VP) universal currency system with earning/spending mechanics', true, 100, ARRAY[]::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'progression_levels', 'gamification', '10-tier level progression system with XP multipliers (Novice to Elite Master)', true, 100, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'badges_achievements', 'gamification', 'Achievement system with badges, VP rewards, and XP bonuses', true, 100, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'streaks_system', 'gamification', 'Daily activity streaks with multipliers and streak saver mechanics', true, 100, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'leaderboards', 'gamification', 'Global/regional/friends leaderboards by VP, wins, and accuracy', true, 100, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'prediction_pools', 'gamification', 'Prediction pools with Brier scoring, VP stakes, and accuracy-based rewards', true, 100, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'daily_weekly_challenges', 'gamification', 'Quest system with daily/weekly challenges and VP rewards (50-500 VP)', true, 100, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'rewards_shop', 'gamification', 'Rewards shop with 5 categories: Platform Perks, Election Enhancements, Social Rewards, Real-World Rewards, VIP Tiers', true, 100, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'feed_gamification', 'gamification', 'Feed quest system with progress bars, mini-games, feed progression levels, and streaks', false, 0, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'ad_gamification', 'gamification', 'Participatory ads gamification with mini-games, campaign quest chains, and ad leaderboards', false, 0, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (gen_random_uuid(), 'jolts_gamification', 'gamification', 'Jolts VP integration with creator rewards (50 VP), viewing rewards (2 VP), and voting rewards (5 VP)', false, 0, ARRAY['vp_system']::TEXT[], CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  ON CONFLICT (feature_name) DO UPDATE SET
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    dependencies = EXCLUDED.dependencies,
    updated_at = CURRENT_TIMESTAMP;

  RAISE NOTICE 'Gamification feature flags inserted successfully';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Feature flags insertion failed: %', SQLERRM;
END $$;

-- ============================================================================
-- 7. MOCK DATA - REWARDS SHOP ITEMS
-- ============================================================================

DO $$
BEGIN
  -- Platform Perks
  INSERT INTO public.rewards_shop_items (category, title, description, vp_cost, icon_name, display_order) VALUES
    ('platform_perks', 'Ad-Free 1 Hour', 'Remove all ads for 1 hour', 50, 'block', 1),
    ('platform_perks', 'Ad-Free 24 Hours', 'Remove all ads for 24 hours', 200, 'block', 2),
    ('platform_perks', 'Custom Theme: Epic Voter', 'Unlock exclusive Epic Voter theme with gradient backgrounds', 500, 'palette', 3),
    ('platform_perks', 'Priority Feed Boost', 'Boost your posts to appear higher in feeds for 24 hours', 300, 'trending_up', 4),
    ('platform_perks', 'Storage Upgrade +10GB', 'Extra 10GB storage for Jolts videos and election archives', 400, 'cloud_upload', 5)
  ON CONFLICT (id) DO NOTHING;

  -- Election Enhancements
  INSERT INTO public.rewards_shop_items (category, title, description, vp_cost, icon_name, display_order) VALUES
    ('election_enhancements', 'Bonus Vote', 'Extra vote in non-lotterized elections', 100, 'how_to_vote', 1),
    ('election_enhancements', 'Lottery Luck Boost', 'Multiplier for lottery ticket odds (1.5x)', 150, 'casino', 2),
    ('election_enhancements', 'Premium Election Creation', 'Waive fee for one gamified election creation', 1000, 'create', 3),
    ('election_enhancements', 'Verification Fast Track', 'Skip verification queue for instant audit reports', 50, 'verified', 4)
  ON CONFLICT (id) DO NOTHING;

  -- Social Rewards
  INSERT INTO public.rewards_shop_items (category, title, description, vp_cost, icon_name, display_order) VALUES
    ('social_rewards', 'Elite Voter Club Membership', 'Invite to private voting teams with shared leaderboards (30 days)', 800, 'workspace_premium', 1),
    ('social_rewards', 'Voter of the Week Shoutout', 'Platform-wide highlight in feeds for 7 days', 400, 'campaign', 2),
    ('social_rewards', 'Referral Bonus Multiplier', 'Double VP from friend referrals for 14 days', 200, 'people', 3),
    ('social_rewards', 'Election Emotes Pack', 'Custom emotes for messaging and groups', 100, 'emoji_emotions', 4)
  ON CONFLICT (id) DO NOTHING;

  -- Real-World Rewards (Stripe required)
  INSERT INTO public.rewards_shop_items (category, title, description, vp_cost, cash_equivalent_usd, requires_stripe, icon_name, display_order) VALUES
    ('real_world_rewards', 'Amazon Gift Card $5', 'Redeem for $5 Amazon e-gift card', 1000, 5.00, true, 'card_giftcard', 1),
    ('real_world_rewards', 'Starbucks Gift Card $5', 'Redeem for $5 Starbucks e-gift card', 1000, 5.00, true, 'local_cafe', 2),
    ('real_world_rewards', 'Vottery Branded T-Shirt', 'Official Vottery merchandise (shipping included)', 2000, 15.00, true, 'checkroom', 3),
    ('real_world_rewards', 'Charity Donation $1', 'Donate $1 to ocean cleanup causes', 500, 1.00, true, 'favorite', 4),
    ('real_world_rewards', 'Virtual Event Ticket', 'Entry to partner webinars or gaming sessions', 600, 0, false, 'event', 5)
  ON CONFLICT (id) DO NOTHING;

  -- VIP Tiers
  INSERT INTO public.rewards_shop_items (category, title, description, vp_cost, icon_name, display_order) VALUES
    ('vip_tiers', 'Early Access Beta Features', 'Access new features 1 month before public release', 1500, 'new_releases', 1),
    ('vip_tiers', 'Custom Challenge Pack', 'Personalized quest pack tailored to your interests', 300, 'flag', 2),
    ('vip_tiers', 'Level 10 Elite Master Badge', 'Exclusive badge for reaching Elite Master tier', 5000, 'military_tech', 3)
  ON CONFLICT (id) DO NOTHING;

  RAISE NOTICE 'Rewards shop items inserted successfully';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Rewards shop items insertion failed: %', SQLERRM;
END $$;