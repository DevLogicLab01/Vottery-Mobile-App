-- Phase 1: Election Creation Full Feature Set + Creator Payout Dashboard + Winner Reveal Ceremony
-- Timestamp: 20260223140000
-- Description: Comprehensive election creation with MCQ, multiple prize types, multiple winners, edit restrictions, creator payout infrastructure, and winner reveal system

-- ============================================================
-- 1. ELECTION CREATION ENHANCEMENTS
-- ============================================================

-- Add MCQ questions storage to elections table
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS mcq_questions JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS prize_type VARCHAR(50) DEFAULT 'monetary';
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS prize_amount DECIMAL(12,2);
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS prize_description TEXT;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS non_monetary_prize_details JSONB;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS projected_revenue_amount DECIMAL(12,2);
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS multiple_winners BOOLEAN DEFAULT false;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS winner_count INTEGER DEFAULT 1;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS prize_distribution JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS vote_count INTEGER DEFAULT 0;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS is_editable BOOLEAN DEFAULT true;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS first_vote_at TIMESTAMPTZ;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS max_end_date DATE;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS max_deadline_extension_months INTEGER DEFAULT 6;

-- Create index for vote count tracking
CREATE INDEX IF NOT EXISTS idx_elections_vote_count ON public.elections(vote_count);
CREATE INDEX IF NOT EXISTS idx_elections_is_editable ON public.elections(is_editable);
CREATE INDEX IF NOT EXISTS idx_elections_first_vote ON public.elections(first_vote_at);

-- Function to update vote count and edit restrictions
CREATE OR REPLACE FUNCTION public.update_election_vote_count()
RETURNS TRIGGER AS $$
BEGIN
  -- Increment vote count and lock editing after first vote
  UPDATE public.elections
  SET 
    vote_count = vote_count + 1,
    is_editable = false,
    first_vote_at = COALESCE(first_vote_at, NEW.created_at)
  WHERE id = NEW.election_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for vote count tracking
DROP TRIGGER IF EXISTS trigger_update_election_vote_count ON public.votes;
CREATE TRIGGER trigger_update_election_vote_count
  AFTER INSERT ON public.votes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_election_vote_count();

-- ============================================================
-- 2. ELECTION WINNERS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_winners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  winner_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  winner_position INTEGER NOT NULL,
  prize_amount DECIMAL(12,2) NOT NULL,
  prize_type VARCHAR(50) DEFAULT 'monetary',
  prize_description TEXT,
  revealed_at TIMESTAMPTZ,
  notification_sent BOOLEAN DEFAULT false,
  notification_sent_at TIMESTAMPTZ,
  claim_status VARCHAR(50) DEFAULT 'pending',
  claimed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, winner_user_id)
);

CREATE INDEX IF NOT EXISTS idx_election_winners_election ON public.election_winners(election_id);
CREATE INDEX IF NOT EXISTS idx_election_winners_user ON public.election_winners(winner_user_id);
CREATE INDEX IF NOT EXISTS idx_election_winners_position ON public.election_winners(winner_position);
CREATE INDEX IF NOT EXISTS idx_election_winners_revealed ON public.election_winners(revealed_at);

-- ============================================================
-- 3. CREATOR PAYOUT INFRASTRUCTURE
-- ============================================================

-- Drop creator_accounts table if it exists to ensure clean schema
DROP TABLE IF EXISTS public.settlement_reconciliation CASCADE;
DROP TABLE IF EXISTS public.tax_documents CASCADE;
DROP TABLE IF EXISTS public.bank_accounts CASCADE;
DROP TABLE IF EXISTS public.creator_payouts CASCADE;
DROP TABLE IF EXISTS public.creator_accounts CASCADE;

-- Creator Accounts Table (with inline UNIQUE constraint)
CREATE TABLE public.creator_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL UNIQUE REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  stripe_account_id VARCHAR(255),
  stripe_account_status VARCHAR(50) DEFAULT 'pending',
  pending_balance DECIMAL(12,2) DEFAULT 0.00,
  total_earnings DECIMAL(12,2) DEFAULT 0.00,
  lifetime_payouts DECIMAL(12,2) DEFAULT 0.00,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_creator_accounts_user ON public.creator_accounts(creator_user_id);
CREATE INDEX idx_creator_accounts_stripe ON public.creator_accounts(stripe_account_id);
CREATE INDEX idx_creator_accounts_status ON public.creator_accounts(stripe_account_status);

-- Creator Payouts Table
CREATE TABLE public.creator_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.creator_accounts(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL,
  fee DECIMAL(12,2) DEFAULT 0.00,
  net_amount DECIMAL(12,2) NOT NULL,
  destination_account VARCHAR(255),
  destination_account_last4 VARCHAR(4),
  status VARCHAR(50) DEFAULT 'requested',
  requested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  processing_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  failure_reason TEXT,
  stripe_transfer_id VARCHAR(255),
  estimated_arrival_date DATE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_creator_payouts_creator ON public.creator_payouts(creator_id);
CREATE INDEX idx_creator_payouts_status ON public.creator_payouts(status);
CREATE INDEX idx_creator_payouts_requested ON public.creator_payouts(requested_at DESC);
CREATE INDEX idx_creator_payouts_stripe ON public.creator_payouts(stripe_transfer_id);

-- Bank Accounts Table
CREATE TABLE public.bank_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.creator_accounts(id) ON DELETE CASCADE,
  account_holder_name VARCHAR(255) NOT NULL,
  country VARCHAR(2) NOT NULL,
  currency VARCHAR(3) NOT NULL,
  routing_number_encrypted TEXT,
  account_number_last4 VARCHAR(4) NOT NULL,
  iban_encrypted TEXT,
  swift_code VARCHAR(11),
  account_type VARCHAR(20),
  is_verified BOOLEAN DEFAULT false,
  is_primary BOOLEAN DEFAULT false,
  verification_method VARCHAR(50),
  verified_at TIMESTAMPTZ,
  added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bank_accounts_creator ON public.bank_accounts(creator_id);
CREATE INDEX idx_bank_accounts_primary ON public.bank_accounts(is_primary) WHERE is_primary = true;
CREATE INDEX idx_bank_accounts_verified ON public.bank_accounts(is_verified);

-- Tax Documents Table
CREATE TABLE public.tax_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.creator_accounts(id) ON DELETE CASCADE,
  document_type VARCHAR(50) NOT NULL,
  document_url TEXT NOT NULL,
  tax_id_encrypted TEXT,
  tax_id_last4 VARCHAR(4),
  full_name VARCHAR(255),
  address_line1 VARCHAR(255),
  address_line2 VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  country VARCHAR(2),
  status VARCHAR(50) DEFAULT 'pending_review',
  uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.user_profiles(id),
  rejection_reason TEXT,
  expires_at DATE
);

CREATE INDEX idx_tax_documents_creator ON public.tax_documents(creator_id);
CREATE INDEX idx_tax_documents_status ON public.tax_documents(status);
CREATE INDEX idx_tax_documents_type ON public.tax_documents(document_type);

-- Settlement Reconciliation Table
CREATE TABLE public.settlement_reconciliation (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.creator_accounts(id) ON DELETE CASCADE,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  gross_amount DECIMAL(12,2) NOT NULL,
  platform_fee DECIMAL(12,2) NOT NULL,
  platform_fee_percentage DECIMAL(5,2) DEFAULT 30.00,
  net_amount DECIMAL(12,2) NOT NULL,
  status VARCHAR(50) DEFAULT 'pending',
  payout_date DATE,
  stripe_payout_id VARCHAR(255),
  discrepancy_detected BOOLEAN DEFAULT false,
  discrepancy_amount DECIMAL(12,2),
  discrepancy_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  reconciled_at TIMESTAMPTZ
);

CREATE INDEX idx_settlement_reconciliation_creator ON public.settlement_reconciliation(creator_id);
CREATE INDEX idx_settlement_reconciliation_period ON public.settlement_reconciliation(period_start, period_end);
CREATE INDEX idx_settlement_reconciliation_status ON public.settlement_reconciliation(status);

-- ============================================================
-- 4. RLS POLICIES
-- ============================================================

-- Election Winners RLS
ALTER TABLE public.election_winners ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view winners of elections they participated in" ON public.election_winners;
CREATE POLICY "Users can view winners of elections they participated in"
  ON public.election_winners FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.votes
      WHERE votes.election_id = election_winners.election_id
      AND votes.user_id = auth.uid()
    )
    OR winner_user_id = auth.uid()
  );

DROP POLICY IF EXISTS "Admins can manage all winners" ON public.election_winners;
CREATE POLICY "Admins can manage all winners"
  ON public.election_winners FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- Creator Accounts RLS
ALTER TABLE public.creator_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own account" ON public.creator_accounts;
CREATE POLICY "Creators can view own account"
  ON public.creator_accounts FOR SELECT
  USING (creator_user_id = auth.uid());

DROP POLICY IF EXISTS "Creators can update own account" ON public.creator_accounts;
CREATE POLICY "Creators can update own account"
  ON public.creator_accounts FOR UPDATE
  USING (creator_user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can manage all creator accounts" ON public.creator_accounts;
CREATE POLICY "Admins can manage all creator accounts"
  ON public.creator_accounts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- Creator Payouts RLS
ALTER TABLE public.creator_payouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own payouts" ON public.creator_payouts;
CREATE POLICY "Creators can view own payouts"
  ON public.creator_payouts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.creator_accounts
      WHERE creator_accounts.id = creator_payouts.creator_id
      AND creator_accounts.creator_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage all payouts" ON public.creator_payouts;
CREATE POLICY "Admins can manage all payouts"
  ON public.creator_payouts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- Bank Accounts RLS
ALTER TABLE public.bank_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can manage own bank accounts" ON public.bank_accounts;
CREATE POLICY "Creators can manage own bank accounts"
  ON public.bank_accounts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.creator_accounts
      WHERE creator_accounts.id = bank_accounts.creator_id
      AND creator_accounts.creator_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage all bank accounts" ON public.bank_accounts;
CREATE POLICY "Admins can manage all bank accounts"
  ON public.bank_accounts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- Tax Documents RLS
ALTER TABLE public.tax_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can manage own tax documents" ON public.tax_documents;
CREATE POLICY "Creators can manage own tax documents"
  ON public.tax_documents FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.creator_accounts
      WHERE creator_accounts.id = tax_documents.creator_id
      AND creator_accounts.creator_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage all tax documents" ON public.tax_documents;
CREATE POLICY "Admins can manage all tax documents"
  ON public.tax_documents FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- Settlement Reconciliation RLS
ALTER TABLE public.settlement_reconciliation ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own reconciliation" ON public.settlement_reconciliation;
CREATE POLICY "Creators can view own reconciliation"
  ON public.settlement_reconciliation FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.creator_accounts
      WHERE creator_accounts.id = settlement_reconciliation.creator_id
      AND creator_accounts.creator_user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage all reconciliation" ON public.settlement_reconciliation;
CREATE POLICY "Admins can manage all reconciliation"
  ON public.settlement_reconciliation FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- ============================================================
-- 5. WINNER REVEAL CEREMONY SYSTEM
-- ============================================================

-- Winner Reveal Events Table
CREATE TABLE IF NOT EXISTS public.winner_reveal_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  scheduled_at TIMESTAMPTZ NOT NULL,
  reveal_type VARCHAR(50) DEFAULT 'instant',
  animation_style VARCHAR(50) DEFAULT 'confetti',
  notification_sent BOOLEAN DEFAULT false,
  notification_sent_at TIMESTAMPTZ,
  reveal_completed BOOLEAN DEFAULT false,
  reveal_completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id)
);

CREATE INDEX IF NOT EXISTS idx_winner_reveal_events_election ON public.winner_reveal_events(election_id);
CREATE INDEX IF NOT EXISTS idx_winner_reveal_events_scheduled ON public.winner_reveal_events(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_winner_reveal_events_completed ON public.winner_reveal_events(reveal_completed);

-- Winner Reveal RLS
ALTER TABLE public.winner_reveal_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view reveal events for elections they participated in" ON public.winner_reveal_events;
CREATE POLICY "Users can view reveal events for elections they participated in"
  ON public.winner_reveal_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.votes
      WHERE votes.election_id = winner_reveal_events.election_id
      AND votes.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Election creators can manage reveal events" ON public.winner_reveal_events;
CREATE POLICY "Election creators can manage reveal events"
  ON public.winner_reveal_events FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = winner_reveal_events.election_id
      AND elections.created_by = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage all reveal events" ON public.winner_reveal_events;
CREATE POLICY "Admins can manage all reveal events"
  ON public.winner_reveal_events FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );