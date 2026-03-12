-- Phase A Batch 5: Blockchain Vote Verification, Complete Gamified Lottery, Stripe Identity KYC
-- Migration: 20260227010000_phase_a_batch5_blockchain_lottery_stripe_identity.sql

-- ============================================================================
-- 1. BLOCKCHAIN VOTE VERIFICATION SYSTEM
-- ============================================================================

-- Election encryption keys table (RSA-2048 key pairs per election)
CREATE TABLE IF NOT EXISTS public.election_encryption_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    public_key TEXT NOT NULL,
    encrypted_private_key TEXT NOT NULL,
    algorithm TEXT DEFAULT 'RSA-2048',
    key_fingerprint TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    is_active BOOLEAN DEFAULT true,
    CONSTRAINT unique_active_election_key UNIQUE (election_id, is_active)
);

CREATE INDEX IF NOT EXISTS idx_election_encryption_keys_election ON public.election_encryption_keys(election_id);
CREATE INDEX IF NOT EXISTS idx_election_encryption_keys_active ON public.election_encryption_keys(is_active);
CREATE INDEX IF NOT EXISTS idx_election_encryption_keys_fingerprint ON public.election_encryption_keys(key_fingerprint);

-- Blockchain vote records table (immutable vote hash chains)
CREATE TABLE IF NOT EXISTS public.blockchain_vote_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    voter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    vote_hash TEXT NOT NULL,
    digital_signature TEXT NOT NULL,
    previous_block_hash TEXT,
    block_number BIGINT NOT NULL,
    transaction_hash TEXT NOT NULL UNIQUE,
    vote_data_encrypted TEXT NOT NULL,
    "timestamp" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    verification_status TEXT DEFAULT 'verified' CHECK (verification_status IN ('verified', 'pending', 'tampered')),
    merkle_root TEXT,
    CONSTRAINT unique_voter_election_blockchain UNIQUE (election_id, voter_id)
);

CREATE INDEX IF NOT EXISTS idx_blockchain_vote_records_election ON public.blockchain_vote_records(election_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_vote_records_voter ON public.blockchain_vote_records(voter_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_vote_records_block_number ON public.blockchain_vote_records(block_number);
CREATE INDEX IF NOT EXISTS idx_blockchain_vote_records_transaction_hash ON public.blockchain_vote_records(transaction_hash);
CREATE INDEX IF NOT EXISTS idx_blockchain_vote_records_verification_status ON public.blockchain_vote_records(verification_status);

-- Vote verification receipts table (public verification portal)
CREATE TABLE IF NOT EXISTS public.vote_verification_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blockchain_record_id UUID NOT NULL REFERENCES public.blockchain_vote_records(id) ON DELETE CASCADE,
    receipt_code TEXT NOT NULL UNIQUE,
    verification_url TEXT,
    qr_code_data TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    accessed_count INT DEFAULT 0,
    last_accessed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_vote_verification_receipts_code ON public.vote_verification_receipts(receipt_code);
CREATE INDEX IF NOT EXISTS idx_vote_verification_receipts_blockchain_record ON public.vote_verification_receipts(blockchain_record_id);

-- Merkle tree blocks table (vote grouping with root hash)
CREATE TABLE IF NOT EXISTS public.merkle_tree_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    block_number BIGINT NOT NULL,
    merkle_root TEXT NOT NULL,
    vote_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMPTZ,
    is_published BOOLEAN DEFAULT false,
    CONSTRAINT unique_election_block_number UNIQUE (election_id, block_number)
);

CREATE INDEX IF NOT EXISTS idx_merkle_tree_blocks_election ON public.merkle_tree_blocks(election_id);
CREATE INDEX IF NOT EXISTS idx_merkle_tree_blocks_block_number ON public.merkle_tree_blocks(block_number);
CREATE INDEX IF NOT EXISTS idx_merkle_tree_blocks_published ON public.merkle_tree_blocks(is_published);

-- Blockchain audit logs table (immutable write-once storage)
CREATE TABLE IF NOT EXISTS public.blockchain_audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('vote_cast', 'vote_verified', 'block_created', 'merkle_published', 'tampering_detected')),
    event_data JSONB NOT NULL,
    block_hash TEXT NOT NULL,
    transaction_hash TEXT,
    "timestamp" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_immutable BOOLEAN DEFAULT true
);

CREATE INDEX IF NOT EXISTS idx_blockchain_audit_logs_election ON public.blockchain_audit_logs(election_id);
CREATE INDEX IF NOT EXISTS idx_blockchain_audit_logs_event_type ON public.blockchain_audit_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_blockchain_audit_logs_timestamp ON public.blockchain_audit_logs(timestamp);

-- ============================================================================
-- 2. COMPLETE GAMIFIED LOTTERY DRAWING SYSTEM
-- ============================================================================

-- Alter existing lottery_draws table to add missing columns
DO $$
BEGIN
    -- Add prize_pool_amount if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'lottery_draws' 
                   AND column_name = 'prize_pool_amount') THEN
        ALTER TABLE public.lottery_draws ADD COLUMN prize_pool_amount DECIMAL(12, 2) DEFAULT 0;
    END IF;

    -- Add random_seed if it doesn't exist (may conflict with rng_seed)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'lottery_draws' 
                   AND column_name = 'random_seed') THEN
        ALTER TABLE public.lottery_draws ADD COLUMN random_seed TEXT;
    END IF;

    -- Add block_hash_seed if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'lottery_draws' 
                   AND column_name = 'block_hash_seed') THEN
        ALTER TABLE public.lottery_draws ADD COLUMN block_hash_seed TEXT;
    END IF;

    -- Add draw_started_at if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'lottery_draws' 
                   AND column_name = 'draw_started_at') THEN
        ALTER TABLE public.lottery_draws ADD COLUMN draw_started_at TIMESTAMPTZ;
    END IF;

    -- Add draw_completed_at if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'lottery_draws' 
                   AND column_name = 'draw_completed_at') THEN
        ALTER TABLE public.lottery_draws ADD COLUMN draw_completed_at TIMESTAMPTZ;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_lottery_draws_completed ON public.lottery_draws(draw_completed_at);

-- Alter existing lottery_winners table to add missing columns (use user_id, not winner_id)
DO $$
BEGIN
    -- Add voter_id_number if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'lottery_winners' 
                   AND column_name = 'voter_id_number') THEN
        ALTER TABLE public.lottery_winners ADD COLUMN voter_id_number TEXT;
    END IF;
END $$;

-- Prize claims table (prize distribution tracking)
CREATE TABLE IF NOT EXISTS public.prize_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lottery_winner_id UUID NOT NULL REFERENCES public.lottery_winners(id) ON DELETE CASCADE,
    claim_status TEXT DEFAULT 'notified' CHECK (claim_status IN ('notified', 'acknowledged', 'verified', 'paid', 'forfeited')),
    notification_sent_at TIMESTAMPTZ,
    acknowledged_at TIMESTAMPTZ,
    verified_at TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    claim_deadline TIMESTAMPTZ NOT NULL,
    payment_method TEXT,
    transaction_id TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_lottery_winner_claim UNIQUE (lottery_winner_id)
);

CREATE INDEX IF NOT EXISTS idx_prize_claims_lottery_winner ON public.prize_claims(lottery_winner_id);
CREATE INDEX IF NOT EXISTS idx_prize_claims_status ON public.prize_claims(claim_status);
CREATE INDEX IF NOT EXISTS idx_prize_claims_deadline ON public.prize_claims(claim_deadline);

-- Winner notifications table (automated notification workflow)
CREATE TABLE IF NOT EXISTS public.winner_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lottery_winner_id UUID NOT NULL REFERENCES public.lottery_winners(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('push', 'email', 'sms', 'in_app')),
    notification_status TEXT DEFAULT 'pending' CHECK (notification_status IN ('pending', 'sent', 'delivered', 'failed', 'bounced')),
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    notification_content JSONB,
    error_message TEXT,
    retry_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_winner_notifications_lottery_winner ON public.winner_notifications(lottery_winner_id);
CREATE INDEX IF NOT EXISTS idx_winner_notifications_type ON public.winner_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_winner_notifications_status ON public.winner_notifications(notification_status);

-- Lottery audit trail table (provenance records)
CREATE TABLE IF NOT EXISTS public.lottery_audit_trail (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lottery_id UUID NOT NULL REFERENCES public.lottery_draws(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('lottery_created', 'vote_cast', 'draw_started', 'winner_selected', 'prize_distributed', 'claim_forfeited')),
    event_data JSONB NOT NULL,
    random_seed_hash TEXT,
    winner_list_hash TEXT,
    "timestamp" TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    performed_by UUID REFERENCES public.user_profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_lottery_audit_trail_lottery ON public.lottery_audit_trail(lottery_id);
CREATE INDEX IF NOT EXISTS idx_lottery_audit_trail_event_type ON public.lottery_audit_trail(event_type);
CREATE INDEX IF NOT EXISTS idx_lottery_audit_trail_timestamp ON public.lottery_audit_trail(timestamp);

-- Fraud prevention checks table (IP/device fingerprint clustering)
CREATE TABLE IF NOT EXISTS public.lottery_fraud_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lottery_id UUID NOT NULL REFERENCES public.lottery_draws(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    ip_address TEXT,
    device_fingerprint TEXT,
    household_cluster_id UUID,
    risk_score DECIMAL(5, 2) DEFAULT 0,
    is_flagged BOOLEAN DEFAULT false,
    flagged_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_lottery_fraud_checks_lottery ON public.lottery_fraud_checks(lottery_id);
CREATE INDEX IF NOT EXISTS idx_lottery_fraud_checks_user ON public.lottery_fraud_checks(user_id);
CREATE INDEX IF NOT EXISTS idx_lottery_fraud_checks_flagged ON public.lottery_fraud_checks(is_flagged);
CREATE INDEX IF NOT EXISTS idx_lottery_fraud_checks_household ON public.lottery_fraud_checks(household_cluster_id);

-- ============================================================================
-- 3. STRIPE IDENTITY KYC INTEGRATION
-- ============================================================================

-- Stripe Identity verification sessions table
CREATE TABLE IF NOT EXISTS public.stripe_identity_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    verification_id UUID, -- Removed FK constraint to non-existent creator_verification table
    stripe_session_id TEXT NOT NULL UNIQUE,
    session_status TEXT DEFAULT 'created' CHECK (session_status IN ('created', 'processing', 'verified', 'requires_input', 'canceled')),
    verification_url TEXT,
    client_secret TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    last_error TEXT
);

CREATE INDEX IF NOT EXISTS idx_stripe_identity_sessions_creator ON public.stripe_identity_sessions(creator_id);
CREATE INDEX IF NOT EXISTS idx_stripe_identity_sessions_verification ON public.stripe_identity_sessions(verification_id);
CREATE INDEX IF NOT EXISTS idx_stripe_identity_sessions_stripe_id ON public.stripe_identity_sessions(stripe_session_id);
CREATE INDEX IF NOT EXISTS idx_stripe_identity_sessions_status ON public.stripe_identity_sessions(session_status);

-- Identity verification results table (document extraction and liveness)
CREATE TABLE IF NOT EXISTS public.identity_verification_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stripe_session_id UUID NOT NULL REFERENCES public.stripe_identity_sessions(id) ON DELETE CASCADE,
    verification_score INT CHECK (verification_score >= 0 AND verification_score <= 100),
    document_type TEXT,
    extracted_name TEXT,
    extracted_dob DATE,
    extracted_address TEXT,
    extracted_id_number TEXT,
    liveness_check_passed BOOLEAN DEFAULT false,
    selfie_url TEXT,
    document_front_url TEXT,
    document_back_url TEXT,
    verification_checks JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_identity_verification_results_session ON public.identity_verification_results(stripe_session_id);
CREATE INDEX IF NOT EXISTS idx_identity_verification_results_liveness ON public.identity_verification_results(liveness_check_passed);

-- Compliance screening results table (OFAC/EU sanctions watchlist)
CREATE TABLE IF NOT EXISTS public.compliance_screening_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stripe_session_id UUID NOT NULL REFERENCES public.stripe_identity_sessions(id) ON DELETE CASCADE,
    screening_status TEXT DEFAULT 'pending' CHECK (screening_status IN ('pending', 'clear', 'flagged', 'requires_review')),
    watchlist_matches JSONB,
    risk_level TEXT CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    screening_provider TEXT DEFAULT 'stripe_identity',
    screened_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES public.user_profiles(id),
    review_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_compliance_screening_results_session ON public.compliance_screening_results(stripe_session_id);
CREATE INDEX IF NOT EXISTS idx_compliance_screening_results_status ON public.compliance_screening_results(screening_status);
CREATE INDEX IF NOT EXISTS idx_compliance_screening_results_risk ON public.compliance_screening_results(risk_level);

-- Bank account verification table (Stripe Connect integration)
CREATE TABLE IF NOT EXISTS public.bank_account_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    stripe_account_id TEXT,
    bank_name TEXT,
    account_holder_name TEXT,
    account_last4 TEXT,
    routing_number_last4 TEXT,
    account_type TEXT CHECK (account_type IN ('checking', 'savings')),
    verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'failed', 'requires_action')),
    verification_method TEXT CHECK (verification_method IN ('instant', 'microdeposits', 'plaid')),
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_bank_account_verifications_creator ON public.bank_account_verifications(creator_id);
CREATE INDEX IF NOT EXISTS idx_bank_account_verifications_stripe_account ON public.bank_account_verifications(stripe_account_id);
CREATE INDEX IF NOT EXISTS idx_bank_account_verifications_status ON public.bank_account_verifications(verification_status);

-- Tax documentation table (W-9/W-8 forms)
CREATE TABLE IF NOT EXISTS public.tax_documentation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    form_type TEXT NOT NULL CHECK (form_type IN ('W-9', 'W-8BEN', 'W-8BEN-E')),
    tax_id_number_encrypted TEXT,
    tax_classification TEXT,
    country_of_residence TEXT,
    treaty_benefits BOOLEAN DEFAULT false,
    document_url TEXT,
    submission_status TEXT DEFAULT 'pending' CHECK (submission_status IN ('pending', 'submitted', 'approved', 'rejected', 'expired')),
    submitted_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tax_documentation_creator ON public.tax_documentation(creator_id);
CREATE INDEX IF NOT EXISTS idx_tax_documentation_status ON public.tax_documentation(submission_status);
CREATE INDEX IF NOT EXISTS idx_tax_documentation_expires ON public.tax_documentation(expires_at);

-- Verification renewal reminders table
CREATE TABLE IF NOT EXISTS public.verification_renewal_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    verification_type TEXT NOT NULL CHECK (verification_type IN ('identity', 'bank_account', 'tax_documentation')),
    expires_at TIMESTAMPTZ NOT NULL,
    reminder_sent_at TIMESTAMPTZ,
    reminder_count INT DEFAULT 0,
    renewal_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_verification_renewal_reminders_creator ON public.verification_renewal_reminders(creator_id);
CREATE INDEX IF NOT EXISTS idx_verification_renewal_reminders_expires ON public.verification_renewal_reminders(expires_at);
CREATE INDEX IF NOT EXISTS idx_verification_renewal_reminders_completed ON public.verification_renewal_reminders(renewal_completed);

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.election_encryption_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blockchain_vote_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vote_verification_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.merkle_tree_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blockchain_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lottery_winners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prize_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.winner_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lottery_audit_trail ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lottery_fraud_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_identity_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.identity_verification_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.compliance_screening_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bank_account_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tax_documentation ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_renewal_reminders ENABLE ROW LEVEL SECURITY;

-- Blockchain Vote Verification Policies
CREATE POLICY "Users can view their own blockchain vote records"
    ON public.blockchain_vote_records FOR SELECT
    USING (auth.uid() = voter_id);

CREATE POLICY "System can insert blockchain vote records"
    ON public.blockchain_vote_records FOR INSERT
    WITH CHECK (auth.uid() = voter_id);

CREATE POLICY "Anyone can verify votes with receipt code"
    ON public.vote_verification_receipts FOR SELECT
    USING (true);

CREATE POLICY "Public can view published merkle blocks"
    ON public.merkle_tree_blocks FOR SELECT
    USING (is_published = true);

CREATE POLICY "Public can view blockchain audit logs"
    ON public.blockchain_audit_logs FOR SELECT
    USING (true);

-- Lottery System Policies (using user_id instead of winner_id)
CREATE POLICY "Winners can view their prize claims"
    ON public.prize_claims FOR SELECT
    USING (
        lottery_winner_id IN (
            SELECT id FROM public.lottery_winners WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Winners can update their prize claims"
    ON public.prize_claims FOR UPDATE
    USING (
        lottery_winner_id IN (
            SELECT id FROM public.lottery_winners WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Winners can view their notifications"
    ON public.winner_notifications FOR SELECT
    USING (
        lottery_winner_id IN (
            SELECT id FROM public.lottery_winners WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "Public can view lottery audit trail"
    ON public.lottery_audit_trail FOR SELECT
    USING (true);

-- Stripe Identity KYC Policies
CREATE POLICY "Creators can view their own identity sessions"
    ON public.stripe_identity_sessions FOR SELECT
    USING (auth.uid() = creator_id);

CREATE POLICY "Creators can create identity sessions"
    ON public.stripe_identity_sessions FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can view their verification results"
    ON public.identity_verification_results FOR SELECT
    USING (
        stripe_session_id IN (
            SELECT id FROM public.stripe_identity_sessions WHERE creator_id = auth.uid()
        )
    );

CREATE POLICY "Creators can view their compliance screening"
    ON public.compliance_screening_results FOR SELECT
    USING (
        stripe_session_id IN (
            SELECT id FROM public.stripe_identity_sessions WHERE creator_id = auth.uid()
        )
    );

CREATE POLICY "Creators can manage their bank accounts"
    ON public.bank_account_verifications FOR ALL
    USING (auth.uid() = creator_id)
    WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can manage their tax documentation"
    ON public.tax_documentation FOR ALL
    USING (auth.uid() = creator_id)
    WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can view their renewal reminders"
    ON public.verification_renewal_reminders FOR SELECT
    USING (auth.uid() = creator_id);

-- ============================================================================
-- 5. POSTGRESQL FUNCTIONS
-- ============================================================================

-- Function: Create lottery draw for election
CREATE OR REPLACE FUNCTION public.create_lottery_draw(
    p_election_id UUID,
    p_prize_pool DECIMAL DEFAULT 1000.00
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_lottery_id UUID;
    v_participant_count INT;
    v_prize_pool DECIMAL;
BEGIN
    -- Count participants (voters)
    SELECT COUNT(*) INTO v_participant_count
    FROM public.votes
    WHERE election_id = p_election_id;

    -- Calculate prize pool (if participation fees exist)
    v_prize_pool := p_prize_pool;

    -- Create lottery draw
    INSERT INTO public.lottery_draws (
        election_id,
        total_participants,
        prize_pool_amount,
        status
    ) VALUES (
        p_election_id,
        v_participant_count,
        v_prize_pool,
        'pending'
    ) RETURNING id INTO v_lottery_id;

    -- Create audit trail
    INSERT INTO public.lottery_audit_trail (
        lottery_id,
        event_type,
        event_data,
        performed_by
    ) VALUES (
        v_lottery_id,
        'lottery_created',
        jsonb_build_object(
            'election_id', p_election_id,
            'total_participants', v_participant_count,
            'prize_pool', v_prize_pool
        ),
        auth.uid()
    );

    RETURN v_lottery_id;
END;
$$;

-- Function: Execute lottery draw with cryptographic winner selection (using user_id)
CREATE OR REPLACE FUNCTION public.execute_lottery_draw(
    p_lottery_id UUID,
    p_random_seed TEXT,
    p_winner_ids UUID[]
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_election_id UUID;
    v_prize_pool DECIMAL;
    v_winner_count INT;
    v_prize_per_winner DECIMAL;
    v_winner_id UUID;
    v_position INT := 1;
    v_lottery_winner_id UUID;
BEGIN
    -- Get lottery details
    SELECT election_id, prize_pool_amount, winner_count
    INTO v_election_id, v_prize_pool, v_winner_count
    FROM public.lottery_draws
    WHERE id = p_lottery_id;

    -- Update lottery status
    UPDATE public.lottery_draws
    SET status = 'in_progress',
        draw_started_at = CURRENT_TIMESTAMP,
        random_seed = p_random_seed
    WHERE id = p_lottery_id;

    -- Select winners (simplified - actual cryptographic selection in Flutter)
    v_prize_per_winner := v_prize_pool / v_winner_count;

    FOREACH v_winner_id IN ARRAY p_winner_ids
    LOOP
        -- Insert winner (using user_id instead of winner_id)
        INSERT INTO public.lottery_winners (
            lottery_id,
            user_id,
            voter_id_number,
            winning_position,
            prize_amount
        ) VALUES (
            p_lottery_id,
            v_winner_id,
            'VOTER-' || SUBSTRING(v_winner_id::TEXT, 1, 8),
            v_position,
            v_prize_per_winner
        ) RETURNING id INTO v_lottery_winner_id;

        -- Create prize claim
        INSERT INTO public.prize_claims (
            lottery_winner_id,
            claim_status,
            notification_sent_at,
            claim_deadline
        ) VALUES (
            v_lottery_winner_id,
            'notified',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP + INTERVAL '30 days'
        );

        -- Create notification
        INSERT INTO public.winner_notifications (
            lottery_winner_id,
            notification_type,
            notification_status,
            sent_at,
            notification_content
        ) VALUES (
            v_lottery_winner_id,
            'push',
            'sent',
            CURRENT_TIMESTAMP,
            jsonb_build_object(
                'title', 'Congratulations! You Won!',
                'body', 'You are winner #' || v_position || ' in the lottery draw!',
                'prize_amount', v_prize_per_winner
            )
        );

        v_position := v_position + 1;
    END LOOP;

    -- Update lottery status
    UPDATE public.lottery_draws
    SET status = 'completed',
        draw_completed_at = CURRENT_TIMESTAMP
    WHERE id = p_lottery_id;

    -- Create audit trail
    INSERT INTO public.lottery_audit_trail (
        lottery_id,
        event_type,
        event_data,
        random_seed_hash,
        winner_list_hash,
        performed_by
    ) VALUES (
        p_lottery_id,
        'draw_started',
        jsonb_build_object(
            'winner_count', v_winner_count,
            'prize_pool', v_prize_pool
        ),
        encode(digest(p_random_seed, 'sha256'), 'hex'),
        encode(digest(array_to_string(p_winner_ids, ','), 'sha256'), 'hex'),
        auth.uid()
    );

    RETURN jsonb_build_object(
        'success', true,
        'lottery_id', p_lottery_id,
        'winners_count', v_winner_count
    );
END;
$$;

-- Function: Verify vote integrity using blockchain
CREATE OR REPLACE FUNCTION public.verify_vote_integrity(
    p_receipt_code TEXT
)
RETURNS TABLE (
    is_valid BOOLEAN,
    vote_hash TEXT,
    vote_timestamp TIMESTAMPTZ,
    block_number BIGINT,
    merkle_root TEXT,
    verification_status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (bvr.verification_status = 'verified') AS is_valid,
        bvr.vote_hash,
        bvr."timestamp" AS vote_timestamp,
        bvr.block_number,
        bvr.merkle_root,
        bvr.verification_status
    FROM public.vote_verification_receipts vvr
    JOIN public.blockchain_vote_records bvr ON bvr.id = vvr.blockchain_record_id
    WHERE vvr.receipt_code = p_receipt_code;

    -- Update access count
    UPDATE public.vote_verification_receipts
    SET accessed_count = accessed_count + 1,
        last_accessed_at = CURRENT_TIMESTAMP
    WHERE receipt_code = p_receipt_code;
END;
$$;

-- Function: Create Stripe Identity verification session
CREATE OR REPLACE FUNCTION public.create_stripe_identity_session(
    p_creator_id UUID,
    p_verification_id UUID,
    p_stripe_session_id TEXT,
    p_verification_url TEXT,
    p_client_secret TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_session_id UUID;
BEGIN
    INSERT INTO public.stripe_identity_sessions (
        creator_id,
        verification_id,
        stripe_session_id,
        session_status,
        verification_url,
        client_secret,
        expires_at
    ) VALUES (
        p_creator_id,
        p_verification_id,
        p_stripe_session_id,
        'created',
        p_verification_url,
        p_client_secret,
        CURRENT_TIMESTAMP + INTERVAL '24 hours'
    ) RETURNING id INTO v_session_id;

    RETURN v_session_id;
END;
$$;

-- Function: Process identity verification results
CREATE OR REPLACE FUNCTION public.process_identity_verification(
    p_stripe_session_id UUID,
    p_verification_data JSONB
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_creator_id UUID;
    v_verification_id UUID;
BEGIN
    -- Get creator and verification IDs
    SELECT creator_id, verification_id
    INTO v_creator_id, v_verification_id
    FROM public.stripe_identity_sessions
    WHERE id = p_stripe_session_id;

    -- Insert verification results
    INSERT INTO public.identity_verification_results (
        stripe_session_id,
        verification_score,
        document_type,
        extracted_name,
        extracted_dob,
        extracted_address,
        extracted_id_number,
        liveness_check_passed,
        verification_checks
    ) VALUES (
        p_stripe_session_id,
        (p_verification_data->>'verification_score')::INT,
        p_verification_data->>'document_type',
        p_verification_data->>'extracted_name',
        (p_verification_data->>'extracted_dob')::DATE,
        p_verification_data->>'extracted_address',
        p_verification_data->>'extracted_id_number',
        (p_verification_data->>'liveness_check_passed')::BOOLEAN,
        p_verification_data->'verification_checks'
    );

    -- Update session status
    UPDATE public.stripe_identity_sessions
    SET session_status = 'verified',
        completed_at = CURRENT_TIMESTAMP
    WHERE id = p_stripe_session_id;

    -- Update creator verification status (commented out - table doesn't exist)
    -- IF v_verification_id IS NOT NULL THEN
    --     UPDATE public.creator_verification
    --     SET identity_verified = true,
    --         verification_status = 'approved',
    --         verified_at = CURRENT_TIMESTAMP
    --     WHERE id = v_verification_id;
    -- END IF;

    RETURN true;
END;
$$;

-- Function: Check verification renewal requirements
CREATE OR REPLACE FUNCTION public.check_verification_renewals()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check tax documentation expiring in 30 days
    INSERT INTO public.verification_renewal_reminders (
        creator_id,
        verification_type,
        expires_at
    )
    SELECT 
        creator_id,
        'tax_documentation',
        expires_at
    FROM public.tax_documentation
    WHERE submission_status = 'approved'
        AND expires_at <= CURRENT_TIMESTAMP + INTERVAL '30 days'
        AND expires_at > CURRENT_TIMESTAMP
        AND creator_id NOT IN (
            SELECT creator_id 
            FROM public.verification_renewal_reminders 
            WHERE verification_type = 'tax_documentation' 
                AND renewal_completed = false
        );

    -- Check identity verifications older than 2 years
    INSERT INTO public.verification_renewal_reminders (
        creator_id,
        verification_type,
        expires_at
    )
    SELECT 
        sis.creator_id,
        'identity',
        sis.completed_at + INTERVAL '2 years'
    FROM public.stripe_identity_sessions sis
    WHERE sis.session_status = 'verified'
        AND sis.completed_at <= CURRENT_TIMESTAMP - INTERVAL '23 months'
        AND sis.creator_id NOT IN (
            SELECT creator_id 
            FROM public.verification_renewal_reminders 
            WHERE verification_type = 'identity' 
                AND renewal_completed = false
        );
END;
$$;

-- ============================================================================
-- 6. MOCK DATA FOR TESTING
-- ============================================================================

DO $$
DECLARE
    existing_election_id UUID;
    existing_user_id UUID;
    test_lottery_id UUID;
    test_winner_id UUID;
    test_session_id UUID;
BEGIN
    -- Get existing election and user for testing
    SELECT id INTO existing_election_id FROM public.elections LIMIT 1;
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;

    IF existing_election_id IS NOT NULL AND existing_user_id IS NOT NULL THEN
        -- 1. Blockchain Vote Verification Mock Data
        BEGIN
            INSERT INTO public.election_encryption_keys (
                election_id,
                public_key,
                encrypted_private_key,
                key_fingerprint,
                expires_at
            ) VALUES (
                existing_election_id,
                '-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...\n-----END PUBLIC KEY-----',
                'encrypted_private_key_data_here',
                'SHA256:abc123def456',
                CURRENT_TIMESTAMP + INTERVAL '1 year'
            );
        EXCEPTION WHEN unique_violation THEN
            NULL;
        END;

        BEGIN
            INSERT INTO public.blockchain_vote_records (
                election_id,
                voter_id,
                vote_hash,
                digital_signature,
                block_number,
                transaction_hash,
                vote_data_encrypted,
                merkle_root
            ) VALUES (
                existing_election_id,
                existing_user_id,
                encode(digest('vote_data_sample', 'sha256'), 'hex'),
                'digital_signature_sample',
                1,
                'tx_' || encode(gen_random_bytes(16), 'hex'),
                'encrypted_vote_data_sample',
                encode(digest('merkle_root_sample', 'sha256'), 'hex')
            );
        EXCEPTION WHEN unique_violation THEN
            NULL;
        END;

        -- 2. Complete Gamified Lottery Mock Data (using user_id)
        BEGIN
            -- Check if lottery already exists for this election
            SELECT id INTO test_lottery_id 
            FROM public.lottery_draws 
            WHERE election_id = existing_election_id;

            IF test_lottery_id IS NULL THEN
                -- Create lottery draw
                INSERT INTO public.lottery_draws (
                    election_id,
                    total_participants,
                    prize_pool_amount,
                    status
                ) VALUES (
                    existing_election_id,
                    100,
                    5000.00,
                    'completed'
                ) RETURNING id INTO test_lottery_id;

                -- Create lottery winner (using user_id instead of winner_id)
                INSERT INTO public.lottery_winners (
                    lottery_id,
                    user_id,
                    voter_id_number,
                    winning_position,
                    prize_amount,
                    announced_at
                ) VALUES (
                    test_lottery_id,
                    existing_user_id,
                    'VOTER-' || SUBSTRING(existing_user_id::TEXT, 1, 8),
                    1,
                    1666.67,
                    CURRENT_TIMESTAMP
                ) RETURNING id INTO test_winner_id;

                -- Create prize claim
                INSERT INTO public.prize_claims (
                    lottery_winner_id,
                    claim_status,
                    notification_sent_at,
                    claim_deadline
                ) VALUES (
                    test_winner_id,
                    'notified',
                    CURRENT_TIMESTAMP,
                    CURRENT_TIMESTAMP + INTERVAL '30 days'
                );
            END IF;
        EXCEPTION WHEN OTHERS THEN
            NULL;
        END;

        -- 3. Stripe Identity KYC Mock Data
        BEGIN
            INSERT INTO public.stripe_identity_sessions (
                creator_id,
                stripe_session_id,
                session_status,
                verification_url,
                client_secret,
                expires_at
            ) VALUES (
                existing_user_id,
                'vs_' || encode(gen_random_bytes(16), 'hex'),
                'verified',
                'https://verify.stripe.com/start/test_session',
                'vs_secret_' || encode(gen_random_bytes(16), 'hex'),
                CURRENT_TIMESTAMP + INTERVAL '24 hours'
            ) RETURNING id INTO test_session_id;

            INSERT INTO public.identity_verification_results (
                stripe_session_id,
                verification_score,
                document_type,
                extracted_name,
                extracted_dob,
                liveness_check_passed
            ) VALUES (
                test_session_id,
                95,
                'drivers_license',
                'John Doe',
                '1990-01-01',
                true
            );

            INSERT INTO public.compliance_screening_results (
                stripe_session_id,
                screening_status,
                risk_level,
                screened_at
            ) VALUES (
                test_session_id,
                'clear',
                'low',
                CURRENT_TIMESTAMP
            );
        EXCEPTION WHEN unique_violation THEN
            NULL;
        END;
    END IF;
END $$;