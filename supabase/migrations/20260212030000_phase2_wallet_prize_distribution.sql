-- Phase 2: Wallet & Prize Distribution System Migration
-- Timestamp: 20260212030000
-- Description: Wallet management, prize distribution, lottery draws, regional pricing

-- ============================================================
-- 1. TYPES
-- ============================================================

DO $$ BEGIN
  CREATE TYPE public.payout_method AS ENUM (
    'bank_transfer',
    'digital_wallet',
    'cryptocurrency',
    'paypal',
    'stripe'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.lottery_status AS ENUM (
    'scheduled',
    'active',
    'drawing',
    'completed',
    'cancelled'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.payout_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.transaction_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'refunded'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 2. WALLET TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.wallet_balances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  total_balance NUMERIC(12,2) DEFAULT 0.00,
  available_balance NUMERIC(12,2) DEFAULT 0.00,
  pending_balance NUMERIC(12,2) DEFAULT 0.00,
  lifetime_earnings NUMERIC(12,2) DEFAULT 0.00,
  currency TEXT DEFAULT 'USD',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_wallet_balances_user ON public.wallet_balances(user_id);

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  status public.transaction_status DEFAULT 'pending',
  description TEXT,
  reference_id UUID,
  reference_type TEXT,
  stripe_transaction_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_wallet_transactions_user ON public.wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_status ON public.wallet_transactions(status);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created ON public.wallet_transactions(created_at DESC);

-- ============================================================
-- 3. PRIZE DISTRIBUTION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_prizes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  prize_pool NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  winner_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  prize_amount NUMERIC(12,2) DEFAULT 0.00,
  distribution_status public.payout_status DEFAULT 'pending',
  payout_method public.payout_method,
  payout_schedule TIMESTAMPTZ,
  stripe_payout_id TEXT,
  regional_zone public.purchasing_power_zone,
  zone_adjusted_amount NUMERIC(12,2),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  distributed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_election_prizes_election ON public.election_prizes(election_id);
CREATE INDEX IF NOT EXISTS idx_election_prizes_winner ON public.election_prizes(winner_id);
CREATE INDEX IF NOT EXISTS idx_election_prizes_status ON public.election_prizes(distribution_status);

CREATE TABLE IF NOT EXISTS public.payout_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  payout_method public.payout_method NOT NULL,
  status public.payout_status DEFAULT 'pending',
  stripe_payout_id TEXT,
  bank_account_details JSONB,
  wallet_address TEXT,
  processing_fee NUMERIC(8,2) DEFAULT 0.00,
  net_amount NUMERIC(12,2),
  requested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  processed_at TIMESTAMPTZ,
  failure_reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_payout_requests_user ON public.payout_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_status ON public.payout_requests(status);
CREATE INDEX IF NOT EXISTS idx_payout_requests_requested ON public.payout_requests(requested_at DESC);

-- ============================================================
-- 4. LOTTERY SYSTEM TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.lottery_draws (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID REFERENCES public.elections(id) ON DELETE CASCADE,
  draw_name TEXT NOT NULL,
  prize_pool NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  status public.lottery_status DEFAULT 'scheduled',
  scheduled_draw_time TIMESTAMPTZ NOT NULL,
  actual_draw_time TIMESTAMPTZ,
  total_participants INTEGER DEFAULT 0,
  winner_count INTEGER DEFAULT 1,
  rng_seed TEXT,
  cryptographic_proof TEXT,
  blockchain_verification_hash TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lottery_draws_election ON public.lottery_draws(election_id);
CREATE INDEX IF NOT EXISTS idx_lottery_draws_status ON public.lottery_draws(status);
CREATE INDEX IF NOT EXISTS idx_lottery_draws_scheduled ON public.lottery_draws(scheduled_draw_time);

CREATE TABLE IF NOT EXISTS public.lottery_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lottery_id UUID NOT NULL REFERENCES public.lottery_draws(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  entry_count INTEGER DEFAULT 1,
  entry_hash TEXT,
  is_winner BOOLEAN DEFAULT false,
  prize_amount NUMERIC(12,2) DEFAULT 0.00,
  joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(lottery_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_lottery_participants_lottery ON public.lottery_participants(lottery_id);
CREATE INDEX IF NOT EXISTS idx_lottery_participants_user ON public.lottery_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_lottery_participants_winner ON public.lottery_participants(is_winner);

CREATE TABLE IF NOT EXISTS public.lottery_winners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lottery_id UUID NOT NULL REFERENCES public.lottery_draws(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  prize_amount NUMERIC(12,2) NOT NULL,
  winning_position INTEGER,
  verification_hash TEXT,
  blockchain_proof TEXT,
  payout_status public.payout_status DEFAULT 'pending',
  announced_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  paid_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_lottery_winners_lottery ON public.lottery_winners(lottery_id);
CREATE INDEX IF NOT EXISTS idx_lottery_winners_user ON public.lottery_winners(user_id);
CREATE INDEX IF NOT EXISTS idx_lottery_winners_status ON public.lottery_winners(payout_status);

-- ============================================================
-- 5. REGIONAL PRICING TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.regional_pricing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  zone public.purchasing_power_zone NOT NULL,
  base_price NUMERIC(8,2) NOT NULL DEFAULT 0.00,
  adjusted_price NUMERIC(8,2) NOT NULL,
  currency TEXT DEFAULT 'USD',
  conversion_rate NUMERIC(10,4) DEFAULT 1.0000,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, zone)
);

CREATE INDEX IF NOT EXISTS idx_regional_pricing_election ON public.regional_pricing(election_id);
CREATE INDEX IF NOT EXISTS idx_regional_pricing_zone ON public.regional_pricing(zone);

CREATE TABLE IF NOT EXISTS public.zone_fee_structure (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone public.purchasing_power_zone NOT NULL UNIQUE,
  zone_name TEXT NOT NULL,
  base_multiplier NUMERIC(4,2) DEFAULT 1.00,
  transaction_fee_percentage NUMERIC(5,2) DEFAULT 2.50,
  minimum_fee NUMERIC(8,2) DEFAULT 0.50,
  maximum_fee NUMERIC(8,2) DEFAULT 50.00,
  supported_currencies TEXT[] DEFAULT ARRAY['USD']::TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_zone_fee_structure_zone ON public.zone_fee_structure(zone);

-- ============================================================
-- 6. FUNCTIONS
-- ============================================================

-- Update wallet balance
CREATE OR REPLACE FUNCTION public.update_wallet_balance(
  p_user_id UUID,
  p_amount NUMERIC,
  p_transaction_type TEXT
)
RETURNS VOID AS $$
BEGIN
  -- Insert or update wallet balance
  INSERT INTO public.wallet_balances (user_id, total_balance, available_balance, lifetime_earnings)
  VALUES (p_user_id, p_amount, p_amount, CASE WHEN p_amount > 0 THEN p_amount ELSE 0 END)
  ON CONFLICT (user_id) DO UPDATE
  SET total_balance = public.wallet_balances.total_balance + p_amount,
      available_balance = public.wallet_balances.available_balance + p_amount,
      lifetime_earnings = CASE 
        WHEN p_amount > 0 THEN public.wallet_balances.lifetime_earnings + p_amount
        ELSE public.wallet_balances.lifetime_earnings
      END,
      updated_at = CURRENT_TIMESTAMP;
  
  -- Record transaction
  INSERT INTO public.wallet_transactions (
    user_id,
    transaction_type,
    amount,
    status,
    description,
    completed_at
  ) VALUES (
    p_user_id,
    p_transaction_type,
    p_amount,
    'completed',
    p_transaction_type || ' transaction',
    CURRENT_TIMESTAMP
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Process lottery draw
CREATE OR REPLACE FUNCTION public.process_lottery_draw(
  p_lottery_id UUID,
  p_winner_ids UUID[],
  p_prize_amounts NUMERIC[]
)
RETURNS VOID AS $$
DECLARE
  v_winner_id UUID;
  v_prize_amount NUMERIC;
  v_index INTEGER := 1;
BEGIN
  -- Update lottery status
  UPDATE public.lottery_draws
  SET status = 'completed',
      actual_draw_time = CURRENT_TIMESTAMP,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = p_lottery_id;
  
  -- Process each winner
  FOREACH v_winner_id IN ARRAY p_winner_ids
  LOOP
    v_prize_amount := p_prize_amounts[v_index];
    
    -- Mark participant as winner
    UPDATE public.lottery_participants
    SET is_winner = true,
        prize_amount = v_prize_amount
    WHERE lottery_id = p_lottery_id AND user_id = v_winner_id;
    
    -- Insert winner record
    INSERT INTO public.lottery_winners (
      lottery_id,
      user_id,
      prize_amount,
      winning_position
    ) VALUES (
      p_lottery_id,
      v_winner_id,
      v_prize_amount,
      v_index
    );
    
    -- Update wallet balance
    PERFORM public.update_wallet_balance(
      v_winner_id,
      v_prize_amount,
      'lottery_prize'
    );
    
    v_index := v_index + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Calculate regional pricing
CREATE OR REPLACE FUNCTION public.calculate_regional_price(
  p_base_price NUMERIC,
  p_zone public.purchasing_power_zone
)
RETURNS NUMERIC AS $$
DECLARE
  v_multiplier NUMERIC;
  v_adjusted_price NUMERIC;
BEGIN
  SELECT base_multiplier INTO v_multiplier
  FROM public.zone_fee_structure
  WHERE zone = p_zone;
  
  IF v_multiplier IS NULL THEN
    v_multiplier := 1.00;
  END IF;
  
  v_adjusted_price := p_base_price * v_multiplier;
  
  RETURN ROUND(v_adjusted_price, 2);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 7. RLS POLICIES
-- ============================================================

ALTER TABLE public.wallet_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_prizes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lottery_draws ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lottery_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lottery_winners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regional_pricing ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zone_fee_structure ENABLE ROW LEVEL SECURITY;

-- Wallet balances policies
CREATE POLICY "Users can view own wallet balance"
  ON public.wallet_balances FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own wallet balance"
  ON public.wallet_balances FOR UPDATE
  USING (auth.uid() = user_id);

-- Wallet transactions policies
CREATE POLICY "Users can view own transactions"
  ON public.wallet_transactions FOR SELECT
  USING (auth.uid() = user_id);

-- Election prizes policies
CREATE POLICY "Users can view election prizes"
  ON public.election_prizes FOR SELECT
  USING (true);

-- Payout requests policies
CREATE POLICY "Users can manage own payout requests"
  ON public.payout_requests FOR ALL
  USING (auth.uid() = user_id);

-- Lottery draws policies
CREATE POLICY "Users can view lottery draws"
  ON public.lottery_draws FOR SELECT
  USING (true);

-- Lottery participants policies
CREATE POLICY "Users can view lottery participants"
  ON public.lottery_participants FOR SELECT
  USING (true);

CREATE POLICY "Users can join lotteries"
  ON public.lottery_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Lottery winners policies
CREATE POLICY "Users can view lottery winners"
  ON public.lottery_winners FOR SELECT
  USING (true);

-- Regional pricing policies
CREATE POLICY "Users can view regional pricing"
  ON public.regional_pricing FOR SELECT
  USING (true);

-- Zone fee structure policies
CREATE POLICY "Users can view zone fee structure"
  ON public.zone_fee_structure FOR SELECT
  USING (true);

-- ============================================================
-- 8. SEED DATA
-- ============================================================

-- Insert zone fee structure for 8 purchasing power zones
INSERT INTO public.zone_fee_structure (zone, zone_name, base_multiplier, transaction_fee_percentage, minimum_fee, maximum_fee, supported_currencies)
VALUES
  ('zone_1_us_canada', 'US & Canada', 1.00, 2.50, 0.50, 50.00, ARRAY['USD', 'CAD']),
  ('zone_2_western_europe', 'Western Europe', 0.95, 2.30, 0.45, 45.00, ARRAY['EUR', 'GBP']),
  ('zone_3_eastern_europe_russia', 'Eastern Europe & Russia', 0.60, 1.80, 0.30, 30.00, ARRAY['EUR', 'RUB']),
  ('zone_4_africa', 'Africa', 0.40, 1.50, 0.20, 20.00, ARRAY['USD', 'ZAR']),
  ('zone_5_latin_america_caribbean', 'Latin America & Caribbean', 0.50, 1.60, 0.25, 25.00, ARRAY['USD', 'BRL', 'MXN']),
  ('zone_6_middle_east_asia', 'Middle East & Asia', 0.70, 2.00, 0.35, 35.00, ARRAY['USD', 'AED', 'INR']),
  ('zone_7_australasia_advanced_asia', 'Australasia & Advanced Asia', 0.90, 2.20, 0.40, 40.00, ARRAY['AUD', 'NZD', 'SGD']),
  ('zone_8_china_hong_kong_macau', 'China, Hong Kong & Macau', 0.80, 2.10, 0.38, 38.00, ARRAY['CNY', 'HKD'])
ON CONFLICT (zone) DO NOTHING;
