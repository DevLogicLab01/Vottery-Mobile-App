-- Phase A Batch 2: Anonymous Voting, Vote Change Controls, Multi-Role Admin System
-- Migration: 20260224010000_phase_a_batch2_anonymous_voting_vote_changes_multi_role.sql

-- ============================================================================
-- ENUM UPDATES (MUST BE FIRST)
-- ============================================================================

-- Add new role values to user_role enum if they don't exist
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'manager' AND enumtypid = 'user_role'::regtype) THEN
    ALTER TYPE user_role ADD VALUE 'manager';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'auditor' AND enumtypid = 'user_role'::regtype) THEN
    ALTER TYPE user_role ADD VALUE 'auditor';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'editor' AND enumtypid = 'user_role'::regtype) THEN
    ALTER TYPE user_role ADD VALUE 'editor';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'advertiser' AND enumtypid = 'user_role'::regtype) THEN
    ALTER TYPE user_role ADD VALUE 'advertiser';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'analyst' AND enumtypid = 'user_role'::regtype) THEN
    ALTER TYPE user_role ADD VALUE 'analyst';
  END IF;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- PART 1: ANONYMOUS VOTING SYSTEM
-- ============================================================================

-- Note: elections table already has allow_anonymous_voting column from previous migration

-- Anonymous votes table (hashed voter tracking)
CREATE TABLE IF NOT EXISTS public.anonymous_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    voter_hash TEXT NOT NULL, -- SHA-256 hash of user_id + election_id + salt
    anonymous_voter_id TEXT NOT NULL, -- ANON-{election_id}-{hash}
    selected_option_id UUID REFERENCES public.election_options(id) ON DELETE CASCADE,
    ranked_choices JSONB DEFAULT '[]'::jsonb,
    selected_options JSONB DEFAULT '[]'::jsonb,
    vote_scores JSONB DEFAULT '{}'::jsonb,
    blockchain_hash TEXT,
    vote_hash TEXT,
    lottery_ticket_id TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(voter_hash, election_id)
);

CREATE INDEX IF NOT EXISTS idx_anonymous_votes_election_id ON public.anonymous_votes(election_id);
CREATE INDEX IF NOT EXISTS idx_anonymous_votes_voter_hash ON public.anonymous_votes(voter_hash);
CREATE INDEX IF NOT EXISTS idx_anonymous_votes_anonymous_voter_id ON public.anonymous_votes(anonymous_voter_id);

-- Anonymous voter receipts (for vote verification without identity)
CREATE TABLE IF NOT EXISTS public.anonymous_voter_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    anonymous_voter_id TEXT NOT NULL,
    receipt_code TEXT NOT NULL UNIQUE,
    verification_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_anonymous_voter_receipts_election_id ON public.anonymous_voter_receipts(election_id);
CREATE INDEX IF NOT EXISTS idx_anonymous_voter_receipts_receipt_code ON public.anonymous_voter_receipts(receipt_code);

-- Anonymity audit trail (maintains integrity without voter identity)
CREATE TABLE IF NOT EXISTS public.anonymity_audit_trail (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    voter_hash TEXT NOT NULL,
    action_type TEXT NOT NULL CHECK (action_type IN ('vote_cast', 'vote_verified', 'receipt_generated', 'anonymity_breach_attempt')),
    blockchain_verification_hash TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_anonymity_audit_trail_election_id ON public.anonymity_audit_trail(election_id);
CREATE INDEX IF NOT EXISTS idx_anonymity_audit_trail_voter_hash ON public.anonymity_audit_trail(voter_hash);
CREATE INDEX IF NOT EXISTS idx_anonymity_audit_trail_action_type ON public.anonymity_audit_trail(action_type);

-- ============================================================================
-- PART 2: VOTE CHANGE CONTROLS
-- ============================================================================

-- Note: elections table already has allow_vote_changes column from previous migration

-- Vote change requests (approval workflow)
CREATE TABLE IF NOT EXISTS public.vote_change_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    original_vote_id UUID REFERENCES public.votes(id) ON DELETE SET NULL,
    new_selected_option_id UUID REFERENCES public.election_options(id) ON DELETE CASCADE,
    new_ranked_choices JSONB DEFAULT '[]'::jsonb,
    new_selected_options JSONB DEFAULT '[]'::jsonb,
    new_vote_scores JSONB DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    reason TEXT,
    requested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    review_notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_vote_change_requests_election_id ON public.vote_change_requests(election_id);
CREATE INDEX IF NOT EXISTS idx_vote_change_requests_user_id ON public.vote_change_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_vote_change_requests_status ON public.vote_change_requests(status);

-- Vote change history (complete audit trail)
CREATE TABLE IF NOT EXISTS public.vote_change_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    vote_id UUID REFERENCES public.votes(id) ON DELETE SET NULL,
    change_type TEXT NOT NULL CHECK (change_type IN ('initial_vote', 'vote_changed', 'vote_change_approved', 'vote_change_rejected', 'unauthorized_attempt')),
    previous_option_id UUID REFERENCES public.election_options(id) ON DELETE SET NULL,
    new_option_id UUID REFERENCES public.election_options(id) ON DELETE SET NULL,
    previous_data JSONB DEFAULT '{}'::jsonb,
    new_data JSONB DEFAULT '{}'::jsonb,
    change_request_id UUID REFERENCES public.vote_change_requests(id) ON DELETE SET NULL,
    blockchain_hash TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_vote_change_history_election_id ON public.vote_change_history(election_id);
CREATE INDEX IF NOT EXISTS idx_vote_change_history_user_id ON public.vote_change_history(user_id);
CREATE INDEX IF NOT EXISTS idx_vote_change_history_change_type ON public.vote_change_history(change_type);
CREATE INDEX IF NOT EXISTS idx_vote_change_history_created_at ON public.vote_change_history(created_at);

-- Vote change analytics (track patterns)
CREATE TABLE IF NOT EXISTS public.vote_change_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL UNIQUE REFERENCES public.elections(id) ON DELETE CASCADE,
    total_change_requests INTEGER DEFAULT 0,
    approved_changes INTEGER DEFAULT 0,
    rejected_changes INTEGER DEFAULT 0,
    expired_changes INTEGER DEFAULT 0,
    unauthorized_attempts INTEGER DEFAULT 0,
    most_changed_from_option_id UUID REFERENCES public.election_options(id) ON DELETE SET NULL,
    most_changed_to_option_id UUID REFERENCES public.election_options(id) ON DELETE SET NULL,
    average_change_time_hours NUMERIC(10, 2),
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_vote_change_analytics_election_id ON public.vote_change_analytics(election_id);

-- ============================================================================
-- PART 3: MULTI-ROLE ADMIN SYSTEM
-- ============================================================================

-- Note: admin_roles table already exists with roles: super_admin, manager, admin, moderator, auditor, editor, advertiser, analyst

-- Permission matrices (granular capabilities per role)
-- Using TEXT instead of enum reference to avoid transaction commit issue
CREATE TABLE IF NOT EXISTS public.permission_matrices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name TEXT NOT NULL,
    permission_category TEXT NOT NULL CHECK (permission_category IN ('user_management', 'election_management', 'content_moderation', 'financial_oversight', 'system_settings', 'analytics_access', 'audit_access', 'ad_management')),
    can_create BOOLEAN DEFAULT false,
    can_read BOOLEAN DEFAULT false,
    can_update BOOLEAN DEFAULT false,
    can_delete BOOLEAN DEFAULT false,
    can_export BOOLEAN DEFAULT false,
    can_approve BOOLEAN DEFAULT false,
    additional_permissions JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(role_name, permission_category)
);

CREATE INDEX IF NOT EXISTS idx_permission_matrices_role_name ON public.permission_matrices(role_name);
CREATE INDEX IF NOT EXISTS idx_permission_matrices_permission_category ON public.permission_matrices(permission_category);

-- Role invitations (invite team members)
-- Using TEXT instead of enum reference to avoid transaction commit issue
CREATE TABLE IF NOT EXISTS public.role_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invited_email TEXT NOT NULL,
    role_name TEXT NOT NULL,
    invited_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    invitation_token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    accepted BOOLEAN DEFAULT false,
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_role_invitations_invited_email ON public.role_invitations(invited_email);
CREATE INDEX IF NOT EXISTS idx_role_invitations_invitation_token ON public.role_invitations(invitation_token);

-- Role audit log (track all role-based actions)
CREATE TABLE IF NOT EXISTS public.role_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    actor_role TEXT NOT NULL,
    action_type TEXT NOT NULL CHECK (action_type IN ('role_assigned', 'role_revoked', 'permission_used', 'data_accessed', 'data_modified', 'data_exported', 'approval_granted', 'approval_denied')),
    target_resource TEXT NOT NULL,
    target_resource_id UUID,
    action_details JSONB DEFAULT '{}'::jsonb,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_role_audit_log_actor_id ON public.role_audit_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_role_audit_log_action_type ON public.role_audit_log(action_type);
CREATE INDEX IF NOT EXISTS idx_role_audit_log_created_at ON public.role_audit_log(created_at);

-- Role analytics (active team members per role)
-- Using TEXT instead of enum reference to avoid transaction commit issue
CREATE TABLE IF NOT EXISTS public.role_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name TEXT NOT NULL UNIQUE,
    active_members INTEGER DEFAULT 0,
    total_actions_today INTEGER DEFAULT 0,
    total_actions_week INTEGER DEFAULT 0,
    total_actions_month INTEGER DEFAULT 0,
    average_response_time_minutes NUMERIC(10, 2),
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_role_analytics_role_name ON public.role_analytics(role_name);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to generate anonymous voter hash
CREATE OR REPLACE FUNCTION public.generate_anonymous_voter_hash(
    p_user_id UUID,
    p_election_id UUID,
    p_salt TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN encode(digest(p_user_id::text || p_election_id::text || p_salt, 'sha256'), 'hex');
END;
$$;

-- Function to generate anonymous voter ID
CREATE OR REPLACE FUNCTION public.generate_anonymous_voter_id(
    p_election_id UUID,
    p_voter_hash TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN 'ANON-' || p_election_id::text || '-' || substring(p_voter_hash, 1, 8);
END;
$$;

-- Function to generate receipt code
CREATE OR REPLACE FUNCTION public.generate_receipt_code(
    p_election_id UUID,
    p_anonymous_voter_id TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN 'RECEIPT-' || substring(p_election_id::text, 1, 8) || '-' || substring(encode(digest(p_anonymous_voter_id, 'sha256'), 'hex'), 1, 12);
END;
$$;

-- Function to auto-expire vote change requests
CREATE OR REPLACE FUNCTION public.expire_vote_change_requests()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.vote_change_requests
    SET status = 'expired'
    WHERE status = 'pending'
      AND expires_at < CURRENT_TIMESTAMP;
END;
$$;

-- Function to check role permissions
CREATE OR REPLACE FUNCTION public.check_role_permission(
    p_role_name TEXT,
    p_permission_category TEXT,
    p_action TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_has_permission BOOLEAN;
BEGIN
    SELECT CASE p_action
        WHEN 'create' THEN can_create
        WHEN 'read' THEN can_read
        WHEN 'update' THEN can_update
        WHEN 'delete' THEN can_delete
        WHEN 'export' THEN can_export
        WHEN 'approve' THEN can_approve
        ELSE false
    END INTO v_has_permission
    FROM public.permission_matrices
    WHERE role_name = p_role_name
      AND permission_category = p_permission_category;

    RETURN COALESCE(v_has_permission, false);
END;
$$;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Anonymous votes RLS
ALTER TABLE public.anonymous_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create anonymous votes"
    ON public.anonymous_votes
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Users can view anonymous votes for elections they created"
    ON public.anonymous_votes
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.elections
            WHERE elections.id = anonymous_votes.election_id
              AND elections.created_by = auth.uid()
        )
    );

-- Anonymous voter receipts RLS
ALTER TABLE public.anonymous_voter_receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can verify receipts"
    ON public.anonymous_voter_receipts
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "System can create receipts"
    ON public.anonymous_voter_receipts
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Anonymity audit trail RLS
ALTER TABLE public.anonymity_audit_trail ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can view anonymity audit trail"
    ON public.anonymity_audit_trail
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.elections
            WHERE elections.id = anonymity_audit_trail.election_id
              AND elections.created_by = auth.uid()
        )
    );

CREATE POLICY "System can create anonymity audit entries"
    ON public.anonymity_audit_trail
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Vote change requests RLS
ALTER TABLE public.vote_change_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can create their own vote change requests"
    ON public.vote_change_requests
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view their own vote change requests"
    ON public.vote_change_requests
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Election creators can view and update vote change requests"
    ON public.vote_change_requests
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.elections
            WHERE elections.id = vote_change_requests.election_id
              AND elections.created_by = auth.uid()
        )
    );

-- Vote change history RLS
ALTER TABLE public.vote_change_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own vote change history"
    ON public.vote_change_history
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY "Election creators can view vote change history"
    ON public.vote_change_history
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.elections
            WHERE elections.id = vote_change_history.election_id
              AND elections.created_by = auth.uid()
        )
    );

CREATE POLICY "System can create vote change history entries"
    ON public.vote_change_history
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Vote change analytics RLS
ALTER TABLE public.vote_change_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Election creators can view vote change analytics"
    ON public.vote_change_analytics
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.elections
            WHERE elections.id = vote_change_analytics.election_id
              AND elections.created_by = auth.uid()
        )
    );

CREATE POLICY "System can manage vote change analytics"
    ON public.vote_change_analytics
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Permission matrices RLS
ALTER TABLE public.permission_matrices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view permission matrices"
    ON public.permission_matrices
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_role_assignments ura
            JOIN public.admin_roles ar ON ar.id = ura.role_id
            WHERE ura.user_id = auth.uid()
              AND ar.role_name IN ('super_admin', 'admin')
              AND ura.is_active = true
        )
    );

CREATE POLICY "Super admins can manage permission matrices"
    ON public.permission_matrices
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_role_assignments ura
            JOIN public.admin_roles ar ON ar.id = ura.role_id
            WHERE ura.user_id = auth.uid()
              AND ar.role_name = 'super_admin'
              AND ura.is_active = true
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_role_assignments ura
            JOIN public.admin_roles ar ON ar.id = ura.role_id
            WHERE ura.user_id = auth.uid()
              AND ar.role_name = 'super_admin'
              AND ura.is_active = true
        )
    );

-- Role invitations RLS
ALTER TABLE public.role_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can create role invitations"
    ON public.role_invitations
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.user_role_assignments ura
            JOIN public.admin_roles ar ON ar.id = ura.role_id
            WHERE ura.user_id = auth.uid()
              AND ar.role_name IN ('super_admin', 'admin', 'manager')
              AND ura.is_active = true
        )
    );

CREATE POLICY "Admins can view role invitations"
    ON public.role_invitations
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_role_assignments ura
            JOIN public.admin_roles ar ON ar.id = ura.role_id
            WHERE ura.user_id = auth.uid()
              AND ar.role_name IN ('super_admin', 'admin', 'manager')
              AND ura.is_active = true
        )
    );

CREATE POLICY "Invited users can view their invitations"
    ON public.role_invitations
    FOR SELECT
    TO authenticated
    USING (
        invited_email = (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    );

CREATE POLICY "Invited users can accept invitations"
    ON public.role_invitations
    FOR UPDATE
    TO authenticated
    USING (
        invited_email = (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    )
    WITH CHECK (
        invited_email = (
            SELECT email FROM auth.users WHERE id = auth.uid()
        )
    );

-- Role audit log RLS
ALTER TABLE public.role_audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins and auditors can view role audit log"
    ON public.role_audit_log
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_role_assignments ura
            JOIN public.admin_roles ar ON ar.id = ura.role_id
            WHERE ura.user_id = auth.uid()
              AND ar.role_name IN ('super_admin', 'admin', 'auditor')
              AND ura.is_active = true
        )
    );

CREATE POLICY "System can create role audit log entries"
    ON public.role_audit_log
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Role analytics RLS
ALTER TABLE public.role_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view role analytics"
    ON public.role_analytics
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.user_role_assignments ura
            JOIN public.admin_roles ar ON ar.id = ura.role_id
            WHERE ura.user_id = auth.uid()
              AND ar.role_name IN ('super_admin', 'admin', 'manager')
              AND ura.is_active = true
        )
    );

CREATE POLICY "System can manage role analytics"
    ON public.role_analytics
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- SEED DATA FOR PERMISSION MATRICES
-- ============================================================================

-- Super Admin permissions (full access)
INSERT INTO public.permission_matrices (role_name, permission_category, can_create, can_read, can_update, can_delete, can_export, can_approve)
VALUES 
    ('super_admin', 'user_management', true, true, true, true, true, true),
    ('super_admin', 'election_management', true, true, true, true, true, true),
    ('super_admin', 'content_moderation', true, true, true, true, true, true),
    ('super_admin', 'financial_oversight', true, true, true, true, true, true),
    ('super_admin', 'system_settings', true, true, true, true, true, true),
    ('super_admin', 'analytics_access', true, true, true, true, true, true),
    ('super_admin', 'audit_access', true, true, true, true, true, true),
    ('super_admin', 'ad_management', true, true, true, true, true, true)
ON CONFLICT (role_name, permission_category) DO NOTHING;

-- Manager permissions
INSERT INTO public.permission_matrices (role_name, permission_category, can_create, can_read, can_update, can_delete, can_export, can_approve)
VALUES 
    ('manager', 'user_management', true, true, true, false, true, true),
    ('manager', 'election_management', true, true, true, false, true, true),
    ('manager', 'content_moderation', true, true, true, false, true, true),
    ('manager', 'financial_oversight', false, true, false, false, true, false),
    ('manager', 'system_settings', false, true, true, false, false, false),
    ('manager', 'analytics_access', false, true, false, false, true, false),
    ('manager', 'audit_access', false, true, false, false, true, false),
    ('manager', 'ad_management', true, true, true, false, true, true)
ON CONFLICT (role_name, permission_category) DO NOTHING;

-- Admin permissions
INSERT INTO public.permission_matrices (role_name, permission_category, can_create, can_read, can_update, can_delete, can_export, can_approve)
VALUES 
    ('admin', 'user_management', true, true, true, true, true, true),
    ('admin', 'election_management', true, true, true, true, true, true),
    ('admin', 'content_moderation', true, true, true, true, true, true),
    ('admin', 'financial_oversight', false, true, true, false, true, true),
    ('admin', 'system_settings', true, true, true, false, true, false),
    ('admin', 'analytics_access', false, true, false, false, true, false),
    ('admin', 'audit_access', false, true, false, false, true, false),
    ('admin', 'ad_management', true, true, true, true, true, true)
ON CONFLICT (role_name, permission_category) DO NOTHING;

-- Moderator permissions
INSERT INTO public.permission_matrices (role_name, permission_category, can_create, can_read, can_update, can_delete, can_export, can_approve)
VALUES 
    ('moderator', 'user_management', false, true, true, false, false, false),
    ('moderator', 'election_management', false, true, true, false, false, true),
    ('moderator', 'content_moderation', true, true, true, true, false, true),
    ('moderator', 'financial_oversight', false, false, false, false, false, false),
    ('moderator', 'system_settings', false, false, false, false, false, false),
    ('moderator', 'analytics_access', false, true, false, false, false, false),
    ('moderator', 'audit_access', false, false, false, false, false, false),
    ('moderator', 'ad_management', false, true, false, false, false, true)
ON CONFLICT (role_name, permission_category) DO NOTHING;

-- Auditor permissions
INSERT INTO public.permission_matrices (role_name, permission_category, can_create, can_read, can_update, can_delete, can_export, can_approve)
VALUES 
    ('auditor', 'user_management', false, true, false, false, true, false),
    ('auditor', 'election_management', false, true, false, false, true, false),
    ('auditor', 'content_moderation', false, true, false, false, true, false),
    ('auditor', 'financial_oversight', false, true, false, false, true, false),
    ('auditor', 'system_settings', false, true, false, false, true, false),
    ('auditor', 'analytics_access', false, true, false, false, true, false),
    ('auditor', 'audit_access', false, true, false, false, true, false),
    ('auditor', 'ad_management', false, true, false, false, true, false)
ON CONFLICT (role_name, permission_category) DO NOTHING;

-- Editor permissions
INSERT INTO public.permission_matrices (role_name, permission_category, can_create, can_read, can_update, can_delete, can_export, can_approve)
VALUES 
    ('editor', 'user_management', false, true, false, false, false, false),
    ('editor', 'election_management', true, true, true, false, false, false),
    ('editor', 'content_moderation', false, true, true, false, false, false),
    ('editor', 'financial_oversight', false, false, false, false, false, false),
    ('editor', 'system_settings', false, false, false, false, false, false),
    ('editor', 'analytics_access', false, true, false, false, false, false),
    ('editor', 'audit_access', false, false, false, false, false, false),
    ('editor', 'ad_management', false, false, false, false, false, false)
ON CONFLICT (role_name, permission_category) DO NOTHING;

-- Advertiser permissions
INSERT INTO public.permission_matrices (role_name, permission_category, can_create, can_read, can_update, can_delete, can_export, can_approve)
VALUES 
    ('advertiser', 'user_management', false, false, false, false, false, false),
    ('advertiser', 'election_management', false, true, false, false, false, false),
    ('advertiser', 'content_moderation', false, false, false, false, false, false),
    ('advertiser', 'financial_oversight', false, true, false, false, true, false),
    ('advertiser', 'system_settings', false, false, false, false, false, false),
    ('advertiser', 'analytics_access', false, true, false, false, true, false),
    ('advertiser', 'audit_access', false, false, false, false, false, false),
    ('advertiser', 'ad_management', true, true, true, true, true, false)
ON CONFLICT (role_name, permission_category) DO NOTHING;

-- Analyst permissions
INSERT INTO public.permission_matrices (role_name, permission_category, can_create, can_read, can_update, can_delete, can_export, can_approve)
VALUES 
    ('analyst', 'user_management', false, true, false, false, true, false),
    ('analyst', 'election_management', false, true, false, false, true, false),
    ('analyst', 'content_moderation', false, true, false, false, true, false),
    ('analyst', 'financial_oversight', false, true, false, false, true, false),
    ('analyst', 'system_settings', false, false, false, false, false, false),
    ('analyst', 'analytics_access', false, true, false, false, true, false),
    ('analyst', 'audit_access', false, true, false, false, true, false),
    ('analyst', 'ad_management', false, true, false, false, true, false)
ON CONFLICT (role_name, permission_category) DO NOTHING;

-- Initialize role analytics
INSERT INTO public.role_analytics (role_name, active_members, total_actions_today, total_actions_week, total_actions_month)
VALUES 
    ('super_admin', 0, 0, 0, 0),
    ('manager', 0, 0, 0, 0),
    ('admin', 0, 0, 0, 0),
    ('moderator', 0, 0, 0, 0),
    ('auditor', 0, 0, 0, 0),
    ('editor', 0, 0, 0, 0),
    ('advertiser', 0, 0, 0, 0),
    ('analyst', 0, 0, 0, 0)
ON CONFLICT (role_name) DO NOTHING;