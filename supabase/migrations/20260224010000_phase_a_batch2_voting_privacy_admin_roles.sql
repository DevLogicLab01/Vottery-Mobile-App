-- =====================================================
-- Phase A Batch 2: Voting Privacy & Admin Role Expansion
-- =====================================================
-- Features:
-- 1. Anonymous Voting System
-- 2. Vote Change Controls
-- 3. Multi-Role Admin System
-- =====================================================

-- =====================================================
-- 1. ANONYMOUS VOTING SYSTEM
-- =====================================================

-- Add anonymous voting toggle to elections
ALTER TABLE public.elections 
ADD COLUMN IF NOT EXISTS allow_anonymous_voting BOOLEAN DEFAULT false;

-- Anonymous votes table (stores votes without revealing voter identity)
CREATE TABLE IF NOT EXISTS public.anonymous_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  hashed_voter_id TEXT NOT NULL, -- SHA-256 hash of user_id + election_id + salt
  anonymous_voter_code TEXT NOT NULL UNIQUE, -- ANON-{election_id}-{hash}
  option_id UUID NOT NULL,
  vote_data JSONB NOT NULL,
  blockchain_hash TEXT,
  voted_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_anonymous_votes_election ON public.anonymous_votes(election_id);
CREATE INDEX IF NOT EXISTS idx_anonymous_votes_hashed_voter ON public.anonymous_votes(hashed_voter_id);
CREATE INDEX IF NOT EXISTS idx_anonymous_votes_code ON public.anonymous_votes(anonymous_voter_code);

-- Anonymous voter tracking (for preventing duplicate votes)
CREATE TABLE IF NOT EXISTS public.anonymous_voter_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  hashed_voter_id TEXT NOT NULL,
  anonymous_voter_code TEXT NOT NULL,
  has_voted BOOLEAN DEFAULT true,
  voted_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(election_id, hashed_voter_id)
);

CREATE INDEX IF NOT EXISTS idx_anonymous_tracking_election ON public.anonymous_voter_tracking(election_id);

-- RLS Policies for anonymous votes
ALTER TABLE public.anonymous_votes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'anonymous_votes' AND policyname = 'anonymous_votes_insert_policy') THEN
    CREATE POLICY anonymous_votes_insert_policy ON public.anonymous_votes
      FOR INSERT WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'anonymous_votes' AND policyname = 'anonymous_votes_select_policy') THEN
    CREATE POLICY anonymous_votes_select_policy ON public.anonymous_votes
      FOR SELECT USING (
        election_id IN (
          SELECT id FROM public.elections WHERE created_by = auth.uid()
        ) OR
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('admin', 'manager', 'auditor')
        )
      );
  END IF;
END $$;

-- RLS Policies for anonymous voter tracking
ALTER TABLE public.anonymous_voter_tracking ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'anonymous_voter_tracking' AND policyname = 'anonymous_tracking_insert_policy') THEN
    CREATE POLICY anonymous_tracking_insert_policy ON public.anonymous_voter_tracking
      FOR INSERT WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'anonymous_voter_tracking' AND policyname = 'anonymous_tracking_select_policy') THEN
    CREATE POLICY anonymous_tracking_select_policy ON public.anonymous_voter_tracking
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('admin', 'manager', 'auditor')
        )
      );
  END IF;
END $$;

-- =====================================================
-- 2. VOTE CHANGE CONTROLS
-- =====================================================

-- Add vote change toggle to elections
ALTER TABLE public.elections 
ADD COLUMN IF NOT EXISTS allow_vote_changes BOOLEAN DEFAULT false;

-- Vote change history table
CREATE TABLE IF NOT EXISTS public.vote_change_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  original_vote_data JSONB NOT NULL,
  new_vote_data JSONB NOT NULL,
  change_reason TEXT,
  changed_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vote_change_history_election ON public.vote_change_history(election_id);
CREATE INDEX IF NOT EXISTS idx_vote_change_history_voter ON public.vote_change_history(voter_id);

-- Pending vote changes (requiring approval)
CREATE TABLE IF NOT EXISTS public.pending_vote_changes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  original_vote_data JSONB NOT NULL,
  new_vote_data JSONB NOT NULL,
  change_reason TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'auto_approved')),
  requested_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.user_profiles(id),
  creator_notified BOOLEAN DEFAULT false,
  auto_approve_at TIMESTAMPTZ, -- 24 hours from request
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(election_id, voter_id, status)
);

CREATE INDEX IF NOT EXISTS idx_pending_changes_election ON public.pending_vote_changes(election_id);
CREATE INDEX IF NOT EXISTS idx_pending_changes_voter ON public.pending_vote_changes(voter_id);
CREATE INDEX IF NOT EXISTS idx_pending_changes_status ON public.pending_vote_changes(status);

-- Voter audit flags (for attempted changes when not allowed)
CREATE TABLE IF NOT EXISTS public.voter_audit_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  flag_reason TEXT NOT NULL,
  attempted_action TEXT,
  ip_address TEXT,
  device_fingerprint TEXT,
  flagged_at TIMESTAMPTZ DEFAULT now(),
  reviewed BOOLEAN DEFAULT false,
  reviewed_by UUID REFERENCES public.user_profiles(id),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_voter_audit_flags_election ON public.voter_audit_flags(election_id);
CREATE INDEX IF NOT EXISTS idx_voter_audit_flags_voter ON public.voter_audit_flags(voter_id);
CREATE INDEX IF NOT EXISTS idx_voter_audit_flags_reviewed ON public.voter_audit_flags(reviewed);

-- RLS Policies for vote change history
ALTER TABLE public.vote_change_history ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vote_change_history' AND policyname = 'vote_change_history_insert_policy') THEN
    CREATE POLICY vote_change_history_insert_policy ON public.vote_change_history
      FOR INSERT WITH CHECK (voter_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vote_change_history' AND policyname = 'vote_change_history_select_policy') THEN
    CREATE POLICY vote_change_history_select_policy ON public.vote_change_history
      FOR SELECT USING (
        voter_id = auth.uid() OR
        election_id IN (
          SELECT id FROM public.elections WHERE created_by = auth.uid()
        ) OR
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('admin', 'manager', 'auditor')
        )
      );
  END IF;
END $$;

-- RLS Policies for pending vote changes
ALTER TABLE public.pending_vote_changes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'pending_vote_changes' AND policyname = 'pending_changes_insert_policy') THEN
    CREATE POLICY pending_changes_insert_policy ON public.pending_vote_changes
      FOR INSERT WITH CHECK (voter_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'pending_vote_changes' AND policyname = 'pending_changes_select_policy') THEN
    CREATE POLICY pending_changes_select_policy ON public.pending_vote_changes
      FOR SELECT USING (
        voter_id = auth.uid() OR
        election_id IN (
          SELECT id FROM public.elections WHERE created_by = auth.uid()
        ) OR
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('admin', 'manager', 'moderator')
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'pending_vote_changes' AND policyname = 'pending_changes_update_policy') THEN
    CREATE POLICY pending_changes_update_policy ON public.pending_vote_changes
      FOR UPDATE USING (
        election_id IN (
          SELECT id FROM public.elections WHERE created_by = auth.uid()
        ) OR
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('admin', 'manager')
        )
      );
  END IF;
END $$;

-- RLS Policies for voter audit flags
ALTER TABLE public.voter_audit_flags ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'voter_audit_flags' AND policyname = 'audit_flags_insert_policy') THEN
    CREATE POLICY audit_flags_insert_policy ON public.voter_audit_flags
      FOR INSERT WITH CHECK (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'voter_audit_flags' AND policyname = 'audit_flags_select_policy') THEN
    CREATE POLICY audit_flags_select_policy ON public.voter_audit_flags
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('admin', 'manager', 'auditor', 'moderator')
        )
      );
  END IF;
END $$;

-- =====================================================
-- 3. MULTI-ROLE ADMIN SYSTEM
-- =====================================================

-- Update user_profiles role enum to include new roles
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role_enum') THEN
    CREATE TYPE user_role_enum AS ENUM ('user', 'admin', 'manager', 'moderator', 'auditor', 'editor', 'advertiser', 'analyst');
  ELSE
    -- Add new enum values if they don't exist
    ALTER TYPE user_role_enum ADD VALUE IF NOT EXISTS 'manager';
    ALTER TYPE user_role_enum ADD VALUE IF NOT EXISTS 'moderator';
    ALTER TYPE user_role_enum ADD VALUE IF NOT EXISTS 'auditor';
    ALTER TYPE user_role_enum ADD VALUE IF NOT EXISTS 'editor';
    ALTER TYPE user_role_enum ADD VALUE IF NOT EXISTS 'advertiser';
    ALTER TYPE user_role_enum ADD VALUE IF NOT EXISTS 'analyst';
  END IF;
END $$;

-- Permission matrices table (defines capabilities per role)
CREATE TABLE IF NOT EXISTS public.permission_matrices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role TEXT NOT NULL UNIQUE,
  permissions JSONB NOT NULL DEFAULT '{}',
  description TEXT,
  color_code TEXT, -- For UI badge colors
  hierarchy_level INTEGER DEFAULT 0, -- Higher = more privileges
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_permission_matrices_role ON public.permission_matrices(role);

-- Insert default permission matrices
INSERT INTO public.permission_matrices (role, permissions, description, color_code, hierarchy_level)
VALUES 
  ('manager', '{
    "full_platform_control": true,
    "user_management": true,
    "financial_oversight": true,
    "system_settings": true,
    "role_assignment": true,
    "election_management": true,
    "content_moderation": true,
    "analytics_access": true,
    "audit_access": true
  }', 'Full platform control + user management + financial oversight', 'purple', 100),
  
  ('admin', '{
    "election_management": true,
    "content_moderation": true,
    "system_settings": true,
    "user_warnings": true,
    "analytics_access": true,
    "payout_management": true
  }', 'Election management + content moderation + system settings', 'red', 90),
  
  ('moderator', '{
    "content_review": true,
    "user_warnings": true,
    "comment_moderation": true,
    "flag_review": true,
    "basic_analytics": true
  }', 'Content review + user warnings + comment moderation', 'blue', 70),
  
  ('auditor', '{
    "read_only_access": true,
    "export_reports": true,
    "blockchain_verification": true,
    "audit_logs_access": true,
    "compliance_reports": true
  }', 'Read-only access to all data + export reports + blockchain verification', 'green', 60),
  
  ('editor', '{
    "content_curation": true,
    "featured_elections": true,
    "homepage_management": true,
    "content_scheduling": true
  }', 'Content curation + featured elections + homepage management', 'orange', 50),
  
  ('advertiser', '{
    "ad_campaign_management": true,
    "analytics_access": true,
    "revenue_tracking": true,
    "campaign_creation": true
  }', 'Ad campaign management + analytics + revenue tracking', 'yellow', 40),
  
  ('analyst', '{
    "advanced_analytics": true,
    "data_exports": true,
    "prediction_dashboards": true,
    "reporting_tools": true
  }', 'Advanced analytics access + data exports + prediction dashboards', 'teal', 30)
ON CONFLICT (role) DO NOTHING;

-- Role assignments table (for tracking role changes)
CREATE TABLE IF NOT EXISTS public.role_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  assigned_role TEXT NOT NULL,
  assigned_by UUID REFERENCES public.user_profiles(id),
  assignment_reason TEXT,
  expires_at TIMESTAMPTZ, -- For temporary roles
  assigned_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_role_assignments_user ON public.role_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_role_assignments_role ON public.role_assignments(assigned_role);

-- Role invitations table (for inviting team members)
CREATE TABLE IF NOT EXISTS public.role_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  invited_role TEXT NOT NULL,
  invited_by UUID NOT NULL REFERENCES public.user_profiles(id),
  invitation_token TEXT NOT NULL UNIQUE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_role_invitations_email ON public.role_invitations(email);
CREATE INDEX IF NOT EXISTS idx_role_invitations_token ON public.role_invitations(invitation_token);
CREATE INDEX IF NOT EXISTS idx_role_invitations_status ON public.role_invitations(status);

-- Role activity logs (audit trail for role-based actions)
CREATE TABLE IF NOT EXISTS public.role_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID NOT NULL REFERENCES public.user_profiles(id),
  actor_role TEXT NOT NULL,
  action_type TEXT NOT NULL,
  target_resource TEXT,
  target_id UUID,
  action_details JSONB,
  ip_address TEXT,
  user_agent TEXT,
  performed_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_role_activity_logs_actor ON public.role_activity_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_role_activity_logs_role ON public.role_activity_logs(actor_role);
CREATE INDEX IF NOT EXISTS idx_role_activity_logs_action ON public.role_activity_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_role_activity_logs_performed ON public.role_activity_logs(performed_at);

-- Role analytics table (team member activity metrics)
CREATE TABLE IF NOT EXISTS public.role_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role TEXT NOT NULL,
  active_members INTEGER DEFAULT 0,
  total_actions INTEGER DEFAULT 0,
  last_activity TIMESTAMPTZ,
  analytics_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(role, analytics_date)
);

CREATE INDEX IF NOT EXISTS idx_role_analytics_role ON public.role_analytics(role);
CREATE INDEX IF NOT EXISTS idx_role_analytics_date ON public.role_analytics(analytics_date);

-- RLS Policies for permission matrices
ALTER TABLE public.permission_matrices ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'permission_matrices' AND policyname = 'permission_matrices_select_policy') THEN
    CREATE POLICY permission_matrices_select_policy ON public.permission_matrices
      FOR SELECT USING (true); -- Public read for all authenticated users
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'permission_matrices' AND policyname = 'permission_matrices_update_policy') THEN
    CREATE POLICY permission_matrices_update_policy ON public.permission_matrices
      FOR UPDATE USING (
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role = 'manager'
        )
      );
  END IF;
END $$;

-- RLS Policies for role assignments
ALTER TABLE public.role_assignments ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'role_assignments' AND policyname = 'role_assignments_insert_policy') THEN
    CREATE POLICY role_assignments_insert_policy ON public.role_assignments
      FOR INSERT WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('manager', 'admin')
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'role_assignments' AND policyname = 'role_assignments_select_policy') THEN
    CREATE POLICY role_assignments_select_policy ON public.role_assignments
      FOR SELECT USING (
        user_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('manager', 'admin', 'auditor')
        )
      );
  END IF;
END $$;

-- RLS Policies for role invitations
ALTER TABLE public.role_invitations ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'role_invitations' AND policyname = 'role_invitations_insert_policy') THEN
    CREATE POLICY role_invitations_insert_policy ON public.role_invitations
      FOR INSERT WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('manager', 'admin')
        )
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'role_invitations' AND policyname = 'role_invitations_select_policy') THEN
    CREATE POLICY role_invitations_select_policy ON public.role_invitations
      FOR SELECT USING (
        invited_by = auth.uid() OR
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('manager', 'admin')
        )
      );
  END IF;
END $$;

-- RLS Policies for role activity logs
ALTER TABLE public.role_activity_logs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'role_activity_logs' AND policyname = 'role_activity_logs_insert_policy') THEN
    CREATE POLICY role_activity_logs_insert_policy ON public.role_activity_logs
      FOR INSERT WITH CHECK (actor_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'role_activity_logs' AND policyname = 'role_activity_logs_select_policy') THEN
    CREATE POLICY role_activity_logs_select_policy ON public.role_activity_logs
      FOR SELECT USING (
        actor_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('manager', 'admin', 'auditor')
        )
      );
  END IF;
END $$;

-- RLS Policies for role analytics
ALTER TABLE public.role_analytics ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'role_analytics' AND policyname = 'role_analytics_select_policy') THEN
    CREATE POLICY role_analytics_select_policy ON public.role_analytics
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM public.user_profiles 
          WHERE id = auth.uid() AND role IN ('manager', 'admin', 'analyst')
        )
      );
  END IF;
END $$;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to generate anonymous voter code
CREATE OR REPLACE FUNCTION generate_anonymous_voter_code(
  p_election_id UUID,
  p_user_id UUID
)
RETURNS TEXT AS $$
DECLARE
  v_hash TEXT;
  v_code TEXT;
BEGIN
  -- Generate SHA-256 hash of user_id + election_id + random salt
  v_hash := encode(digest(p_user_id::TEXT || p_election_id::TEXT || gen_random_uuid()::TEXT, 'sha256'), 'hex');
  
  -- Create anonymous voter code
  v_code := 'ANON-' || SUBSTRING(p_election_id::TEXT, 1, 8) || '-' || SUBSTRING(v_hash, 1, 12);
  
  RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has permission
CREATE OR REPLACE FUNCTION check_user_permission(
  p_user_id UUID,
  p_permission TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
  v_user_role TEXT;
  v_permissions JSONB;
BEGIN
  -- Get user role
  SELECT role INTO v_user_role
  FROM public.user_profiles
  WHERE id = p_user_id;
  
  IF v_user_role IS NULL THEN
    RETURN false;
  END IF;
  
  -- Get role permissions
  SELECT permissions INTO v_permissions
  FROM public.permission_matrices
  WHERE role = v_user_role;
  
  IF v_permissions IS NULL THEN
    RETURN false;
  END IF;
  
  -- Check if permission exists and is true
  RETURN COALESCE((v_permissions->p_permission)::BOOLEAN, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to auto-approve pending vote changes after 24 hours
CREATE OR REPLACE FUNCTION auto_approve_pending_vote_changes()
RETURNS void AS $$
BEGIN
  UPDATE public.pending_vote_changes
  SET 
    status = 'auto_approved',
    reviewed_at = now()
  WHERE 
    status = 'pending' 
    AND auto_approve_at <= now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- COMMENTS FOR DOCUMENTATION
-- =====================================================

COMMENT ON TABLE public.anonymous_votes IS 'Stores anonymous votes without revealing voter identity using hashed identifiers';
COMMENT ON TABLE public.anonymous_voter_tracking IS 'Tracks anonymous voters to prevent duplicate voting while maintaining anonymity';
COMMENT ON TABLE public.vote_change_history IS 'Complete history of all vote changes with original and new vote data';
COMMENT ON TABLE public.pending_vote_changes IS 'Vote change requests requiring creator approval';
COMMENT ON TABLE public.voter_audit_flags IS 'Audit flags for voters who attempt unauthorized actions';
COMMENT ON TABLE public.permission_matrices IS 'Defines granular permissions for each admin role';
COMMENT ON TABLE public.role_assignments IS 'Tracks role assignment history and temporary role grants';
COMMENT ON TABLE public.role_invitations IS 'Email invitations for team members with specific roles';
COMMENT ON TABLE public.role_activity_logs IS 'Comprehensive audit trail of all role-based actions';
COMMENT ON TABLE public.role_analytics IS 'Daily analytics of team member activity per role';