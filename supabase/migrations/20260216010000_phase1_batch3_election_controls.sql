-- Phase 1 Batch 3: Election Controls - Permission Controls, Biometric Voting, Vote Totals Visibility
-- Adds audit logging, visibility change tracking, and permission validation functions

-- ============================================================================
-- 1. AUDIT LOGGING FOR VOTE VISIBILITY CHANGES
-- ============================================================================

CREATE TABLE IF NOT EXISTS vote_visibility_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
  changed_by UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  previous_state TEXT NOT NULL CHECK (previous_state IN ('hidden', 'visible', 'visible_after_vote')),
  new_state TEXT NOT NULL CHECK (new_state IN ('hidden', 'visible', 'visible_after_vote')),
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_vote_visibility_audit_election ON vote_visibility_audit(election_id);
CREATE INDEX IF NOT EXISTS idx_vote_visibility_audit_changed_at ON vote_visibility_audit(changed_at DESC);

-- ============================================================================
-- 2. BIOMETRIC AUTHENTICATION ATTEMPTS TRACKING
-- ============================================================================

CREATE TABLE IF NOT EXISTS biometric_auth_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES elections(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL DEFAULT 1,
  success BOOLEAN NOT NULL,
  biometric_type TEXT NOT NULL CHECK (biometric_type IN ('fingerprint', 'face_id', 'any', 'fallback_pin')),
  device_info JSONB DEFAULT '{}'::jsonb,
  attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_biometric_attempts_user ON biometric_auth_attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_biometric_attempts_election ON biometric_auth_attempts(election_id);
CREATE INDEX IF NOT EXISTS idx_biometric_attempts_attempted_at ON biometric_auth_attempts(attempted_at DESC);

-- ============================================================================
-- 3. PERMISSION VALIDATION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION check_election_permission(
  p_election_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
  v_permission_type permission_type;
  v_allowed_countries JSONB;
  v_group_id TEXT;
  v_user_country TEXT;
  v_is_member BOOLEAN;
BEGIN
  -- Get election permission settings
  SELECT permission_type, allowed_countries, group_id
  INTO v_permission_type, v_allowed_countries, v_group_id
  FROM elections
  WHERE id = p_election_id;

  -- If election not found, deny access
  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  -- Public elections: everyone can vote
  IF v_permission_type = 'public' THEN
    RETURN TRUE;
  END IF;

  -- Country-specific elections: check user's country
  IF v_permission_type = 'country_specific' THEN
    -- Get user's country from profile location field
    SELECT location INTO v_user_country
    FROM user_profiles
    WHERE id = p_user_id;

    -- Check if user's country is in allowed list
    IF v_user_country IS NOT NULL AND v_allowed_countries ? v_user_country THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
  END IF;

  -- Group-only elections: check membership
  IF v_permission_type = 'group_only' THEN
    -- Check if user is member of the specified group
    SELECT EXISTS(
      SELECT 1 FROM group_members
      WHERE group_id = v_group_id::UUID
      AND user_id = p_user_id
    ) INTO v_is_member;

    RETURN v_is_member;
  END IF;

  -- Default: deny access
  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. BIOMETRIC VERIFICATION TRACKING FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION log_biometric_attempt(
  p_user_id UUID,
  p_election_id UUID,
  p_attempt_number INTEGER,
  p_success BOOLEAN,
  p_biometric_type TEXT,
  p_device_info JSONB DEFAULT '{}'::jsonb
) RETURNS UUID AS $$
DECLARE
  v_attempt_id UUID;
BEGIN
  INSERT INTO biometric_auth_attempts (
    user_id,
    election_id,
    attempt_number,
    success,
    biometric_type,
    device_info
  ) VALUES (
    p_user_id,
    p_election_id,
    p_attempt_number,
    p_success,
    p_biometric_type,
    p_device_info
  ) RETURNING id INTO v_attempt_id;

  RETURN v_attempt_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. VOTE VISIBILITY CHANGE AUDIT FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION log_visibility_change(
  p_election_id UUID,
  p_changed_by UUID,
  p_previous_state TEXT,
  p_new_state TEXT,
  p_reason TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_audit_id UUID;
BEGIN
  -- Enforce one-way toggle rule: hidden -> visible only
  IF p_previous_state = 'visible' AND p_new_state = 'hidden' THEN
    RAISE EXCEPTION 'Cannot change visibility from visible back to hidden';
  END IF;

  INSERT INTO vote_visibility_audit (
    election_id,
    changed_by,
    previous_state,
    new_state,
    reason
  ) VALUES (
    p_election_id,
    p_changed_by,
    p_previous_state,
    p_new_state,
    p_reason
  ) RETURNING id INTO v_audit_id;

  RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. RLS POLICIES
-- ============================================================================

-- Vote visibility audit policies
ALTER TABLE vote_visibility_audit ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS vote_visibility_audit_select_policy ON vote_visibility_audit;
CREATE POLICY vote_visibility_audit_select_policy ON vote_visibility_audit
  FOR SELECT USING (
    -- Election creators can see audit logs
    EXISTS (
      SELECT 1 FROM elections
      WHERE elections.id = vote_visibility_audit.election_id
      AND elections.created_by = auth.uid()
    )
    OR
    -- Admins can see all audit logs
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS vote_visibility_audit_insert_policy ON vote_visibility_audit;
CREATE POLICY vote_visibility_audit_insert_policy ON vote_visibility_audit
  FOR INSERT WITH CHECK (
    -- Only election creators can log visibility changes
    EXISTS (
      SELECT 1 FROM elections
      WHERE elections.id = vote_visibility_audit.election_id
      AND elections.created_by = auth.uid()
    )
  );

-- Biometric auth attempts policies
ALTER TABLE biometric_auth_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS biometric_attempts_select_policy ON biometric_auth_attempts;
CREATE POLICY biometric_attempts_select_policy ON biometric_auth_attempts
  FOR SELECT USING (
    -- Users can see their own attempts
    user_id = auth.uid()
    OR
    -- Admins can see all attempts
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

DROP POLICY IF EXISTS biometric_attempts_insert_policy ON biometric_auth_attempts;
CREATE POLICY biometric_attempts_insert_policy ON biometric_auth_attempts
  FOR INSERT WITH CHECK (
    -- Users can only log their own attempts
    user_id = auth.uid()
  );

-- ============================================================================
-- 7. INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_elections_permission_type ON elections(permission_type);
CREATE INDEX IF NOT EXISTS idx_elections_group_id ON elections(group_id) WHERE group_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_elections_biometric_required ON elections(biometric_required);
CREATE INDEX IF NOT EXISTS idx_elections_vote_visibility ON elections(vote_visibility);

-- ============================================================================
-- 8. COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE vote_visibility_audit IS 'Audit trail for vote visibility changes with one-way toggle enforcement';
COMMENT ON TABLE biometric_auth_attempts IS 'Security log tracking biometric authentication attempts for voting';
COMMENT ON FUNCTION check_election_permission IS 'Validates user eligibility to vote based on election permission settings';
COMMENT ON FUNCTION log_biometric_attempt IS 'Records biometric authentication attempts with device info';
COMMENT ON FUNCTION log_visibility_change IS 'Logs vote visibility changes with one-way toggle enforcement';
