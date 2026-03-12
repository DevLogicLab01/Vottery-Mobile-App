-- Phase 2: Monetization & Security Migration
-- Timestamp: 20260213010000
-- Description: Wallet system, prize distribution, lottery automation, regional pricing, Stripe payment processing

-- ============================================================
-- 1. TYPES
-- ============================================================

DO $$ BEGIN
  CREATE TYPE public.wallet_transaction_type AS ENUM (
    'deposit',
    'withdrawal',
    'prize_payout',
    'lottery_entry',
    'refund',
    'admin_adjustment'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.lottery_status AS ENUM (
    'pending',
    'drawing',
    'completed',
    'cancelled'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.prize_distribution_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 2. WALLET SYSTEM TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  balance_usd NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  lifetime_deposits NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  lifetime_withdrawals NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  lifetime_prizes NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  purchasing_power_zone public.purchasing_power_zone NOT NULL DEFAULT 'zone_1_us_canada',
  stripe_customer_id TEXT,
  stripe_account_id TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  transaction_type public.wallet_transaction_type NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  balance_before NUMERIC(12,2) NOT NULL,
  balance_after NUMERIC(12,2) NOT NULL,
  description TEXT,
  reference_id UUID,
  reference_type TEXT,
  stripe_payment_intent_id TEXT,
  stripe_transfer_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. PRIZE DISTRIBUTION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.prizes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  total_prize_pool NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  zone_specific_amounts JSONB DEFAULT '{}'::jsonb,
  winner_count INTEGER DEFAULT 1,
  distribution_method TEXT DEFAULT 'winner_takes_all',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.prize_distributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prize_id UUID NOT NULL REFERENCES public.prizes(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  winner_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  status public.prize_distribution_status DEFAULT 'pending',
  stripe_transfer_id TEXT,
  processing_started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  error_message TEXT,
  retry_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 4. LOTTERY SYSTEM TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.lottery_draws (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  prize_id UUID NOT NULL REFERENCES public.prizes(id) ON DELETE CASCADE,
  status public.lottery_status DEFAULT 'pending',
  total_entries INTEGER DEFAULT 0,
  rng_seed TEXT NOT NULL,
  rng_hash TEXT NOT NULL,
  winner_ids UUID[] DEFAULT ARRAY[]::UUID[],
  draw_algorithm TEXT DEFAULT 'cryptographic_rng',
  draw_started_at TIMESTAMPTZ,
  draw_completed_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.lottery_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lottery_draw_id UUID NOT NULL REFERENCES public.lottery_draws(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  entry_number INTEGER NOT NULL,
  is_winner BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(lottery_draw_id, user_id)
);

-- ============================================================
-- 5. REGIONAL PRICING TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.regional_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone public.purchasing_power_zone NOT NULL,
  base_price_usd NUMERIC(8,2) NOT NULL,
  local_price NUMERIC(8,2) NOT NULL,
  currency_code TEXT NOT NULL,
  vp_amount INTEGER NOT NULL,
  discount_percentage NUMERIC(5,2) DEFAULT 0.00,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(zone, vp_amount)
);

-- ============================================================
-- 6. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallets_zone ON public.wallets(purchasing_power_zone);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON public.wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user_id ON public.wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON public.wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_prizes_election_id ON public.prizes(election_id);
CREATE INDEX IF NOT EXISTS idx_prize_distributions_prize_id ON public.prize_distributions(prize_id);
CREATE INDEX IF NOT EXISTS idx_prize_distributions_winner_id ON public.prize_distributions(winner_id);
CREATE INDEX IF NOT EXISTS idx_prize_distributions_status ON public.prize_distributions(status);
CREATE INDEX IF NOT EXISTS idx_lottery_draws_election_id ON public.lottery_draws(election_id);
CREATE INDEX IF NOT EXISTS idx_lottery_draws_status ON public.lottery_draws(status);
CREATE INDEX IF NOT EXISTS idx_lottery_entries_draw_id ON public.lottery_entries(lottery_draw_id);
CREATE INDEX IF NOT EXISTS idx_lottery_entries_user_id ON public.lottery_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_regional_pricing_zone ON public.regional_pricing(zone);

-- ============================================================
-- 7. FUNCTIONS
-- ============================================================

-- Update wallet balance
CREATE OR REPLACE FUNCTION public.update_wallet_balance()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.wallets
  SET 
    balance_usd = NEW.balance_after,
    lifetime_deposits = CASE 
      WHEN NEW.transaction_type IN ('deposit', 'prize_payout') THEN lifetime_deposits + NEW.amount 
      ELSE lifetime_deposits 
    END,
    lifetime_withdrawals = CASE 
      WHEN NEW.transaction_type = 'withdrawal' THEN lifetime_withdrawals + NEW.amount 
      ELSE lifetime_withdrawals 
    END,
    lifetime_prizes = CASE 
      WHEN NEW.transaction_type = 'prize_payout' THEN lifetime_prizes + NEW.amount 
      ELSE lifetime_prizes 
    END,
    updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.wallet_id;
  
  RETURN NEW;
END;
$$;

-- Automated prize distribution
CREATE OR REPLACE FUNCTION public.distribute_prizes(
  p_election_id UUID
)
RETURNS TABLE(success BOOLEAN, message TEXT, winner_ids UUID[])
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_prize_record RECORD;
  v_winner_id UUID;
  v_winner_ids UUID[] := ARRAY[]::UUID[];
  v_amount_per_winner NUMERIC;
BEGIN
  -- Get prize configuration
  SELECT * INTO v_prize_record
  FROM public.prizes
  WHERE election_id = p_election_id AND is_active = true
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'No active prize found for election', ARRAY[]::UUID[];
    RETURN;
  END IF;

  -- Get winners from lottery draw
  SELECT winner_ids INTO v_winner_ids
  FROM public.lottery_draws
  WHERE election_id = p_election_id AND status = 'completed'
  ORDER BY draw_completed_at DESC
  LIMIT 1;

  IF array_length(v_winner_ids, 1) IS NULL THEN
    RETURN QUERY SELECT false, 'No winners found', ARRAY[]::UUID[];
    RETURN;
  END IF;

  -- Calculate amount per winner
  v_amount_per_winner := v_prize_record.total_prize_pool / array_length(v_winner_ids, 1);

  -- Create prize distribution records
  FOREACH v_winner_id IN ARRAY v_winner_ids
  LOOP
    INSERT INTO public.prize_distributions (
      prize_id,
      election_id,
      winner_id,
      amount,
      status
    ) VALUES (
      v_prize_record.id,
      p_election_id,
      v_winner_id,
      v_amount_per_winner,
      'pending'
    );
  END LOOP;

  RETURN QUERY SELECT true, 'Prize distributions created', v_winner_ids;
END;
$$;

-- ============================================================
-- 8. ENABLE RLS
-- ============================================================

ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prize_distributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lottery_draws ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lottery_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regional_pricing ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 9. RLS POLICIES
-- ============================================================

-- Wallets policies
DROP POLICY IF EXISTS "users_view_own_wallet" ON public.wallets;
CREATE POLICY "users_view_own_wallet"
ON public.wallets
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_update_own_wallet" ON public.wallets;
CREATE POLICY "users_update_own_wallet"
ON public.wallets
FOR UPDATE
USING (auth.uid() = user_id);

-- Wallet transactions policies
DROP POLICY IF EXISTS "users_view_own_transactions" ON public.wallet_transactions;
CREATE POLICY "users_view_own_transactions"
ON public.wallet_transactions
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_insert_own_transactions" ON public.wallet_transactions;
CREATE POLICY "users_insert_own_transactions"
ON public.wallet_transactions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Prizes policies
DROP POLICY IF EXISTS "anyone_view_prizes" ON public.prizes;
CREATE POLICY "anyone_view_prizes"
ON public.prizes
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "creators_manage_prizes" ON public.prizes;
CREATE POLICY "creators_manage_prizes"
ON public.prizes
FOR ALL
USING (auth.uid() = creator_id);

-- Prize distributions policies
DROP POLICY IF EXISTS "winners_view_own_prizes" ON public.prize_distributions;
CREATE POLICY "winners_view_own_prizes"
ON public.prize_distributions
FOR SELECT
USING (auth.uid() = winner_id);

-- Lottery draws policies
DROP POLICY IF EXISTS "anyone_view_lottery_draws" ON public.lottery_draws;
CREATE POLICY "anyone_view_lottery_draws"
ON public.lottery_draws
FOR SELECT
USING (true);

-- Lottery entries policies
DROP POLICY IF EXISTS "users_view_own_entries" ON public.lottery_entries;
CREATE POLICY "users_view_own_entries"
ON public.lottery_entries
FOR SELECT
USING (auth.uid() = user_id);

-- Regional pricing policies
DROP POLICY IF EXISTS "anyone_view_regional_pricing" ON public.regional_pricing;
CREATE POLICY "anyone_view_regional_pricing"
ON public.regional_pricing
FOR SELECT
USING (true);

-- ============================================================
-- 10. TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS wallet_balance_update_trigger ON public.wallet_transactions;
CREATE TRIGGER wallet_balance_update_trigger
AFTER INSERT ON public.wallet_transactions
FOR EACH ROW
EXECUTE FUNCTION public.update_wallet_balance();

-- ============================================================
-- 11. MOCK DATA
-- ============================================================

-- Insert regional pricing for all 8 zones
INSERT INTO public.regional_pricing (zone, base_price_usd, local_price, currency_code, vp_amount, discount_percentage) VALUES
  ('zone_1_us_canada', 9.99, 9.99, 'USD', 1000, 0.00),
  ('zone_2_western_europe', 9.99, 8.99, 'EUR', 1000, 10.00),
  ('zone_3_eastern_europe_russia', 9.99, 4.99, 'USD', 1000, 50.00),
  ('zone_4_africa', 9.99, 2.99, 'USD', 1000, 70.00),
  ('zone_5_latin_america_caribbean', 9.99, 3.99, 'USD', 1000, 60.00),
  ('zone_6_middle_east_asia', 9.99, 5.99, 'USD', 1000, 40.00),
  ('zone_7_australasia_advanced_asia', 9.99, 9.99, 'AUD', 1000, 0.00),
  ('zone_8_china_hong_kong_macau', 9.99, 6.99, 'CNY', 1000, 30.00)
ON CONFLICT (zone, vp_amount) DO NOTHING;

COMMENT ON TABLE public.wallets IS 'User wallet system for prize payouts and deposits';
COMMENT ON TABLE public.prizes IS 'Prize pool configuration for gamified elections';
COMMENT ON TABLE public.lottery_draws IS 'Automated lottery draws with cryptographic RNG';
COMMENT ON TABLE public.regional_pricing IS 'Zone-specific pricing across 8 purchasing power regions';