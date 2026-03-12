-- Phase B Batch 1: Election Integrity and Community Features
-- Migration: 20260228010000_phase_b_batch1_tie_handling_abstentions_communities.sql
-- Description: Tie handling workflow, abstentions tracking, community elections hub

-- ============================================================================
-- 1. TIE HANDLING & RESOLUTION SYSTEM
-- ============================================================================

-- Tie results table (stores tied election outcomes)
CREATE TABLE IF NOT EXISTS public.tie_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    tied_candidates JSONB NOT NULL DEFAULT '[]'::jsonb, -- Array of {option_id, option_title, vote_count}
    tied_vote_count INTEGER NOT NULL,
    resolution_status TEXT NOT NULL DEFAULT 'unresolved' CHECK (resolution_status IN ('unresolved', 'runoff_scheduled', 'manual_override', 'lottery_resolved')),
    runoff_election_id UUID REFERENCES public.elections(id) ON DELETE SET NULL,
    manual_winner_id UUID REFERENCES public.election_options(id) ON DELETE SET NULL,
    manual_justification TEXT,
    resolved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    detected_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMPTZ,
    resolution_method TEXT CHECK (resolution_method IN ('runoff', 'manual', 'lottery', 'pending')),
    CONSTRAINT unique_election_tie UNIQUE (election_id)
);

CREATE INDEX IF NOT EXISTS idx_tie_results_election ON public.tie_results(election_id);
CREATE INDEX IF NOT EXISTS idx_tie_results_status ON public.tie_results(resolution_status);
CREATE INDEX IF NOT EXISTS idx_tie_results_runoff ON public.tie_results(runoff_election_id);

-- Tie analytics table (tracking tie frequency per voting method)
CREATE TABLE IF NOT EXISTS public.tie_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    voting_method TEXT NOT NULL,
    total_ties INTEGER DEFAULT 0,
    runoff_resolutions INTEGER DEFAULT 0,
    manual_resolutions INTEGER DEFAULT 0,
    lottery_resolutions INTEGER DEFAULT 0,
    average_resolution_time_hours NUMERIC(10, 2),
    last_tie_detected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_voting_method_analytics UNIQUE (voting_method)
);

CREATE INDEX IF NOT EXISTS idx_tie_analytics_voting_method ON public.tie_analytics(voting_method);

-- Tie notifications table (alert tracking)
CREATE TABLE IF NOT EXISTS public.tie_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tie_result_id UUID NOT NULL REFERENCES public.tie_results(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('email', 'push', 'in_app')),
    notification_status TEXT DEFAULT 'pending' CHECK (notification_status IN ('pending', 'sent', 'delivered', 'failed')),
    sent_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tie_notifications_tie_result ON public.tie_notifications(tie_result_id);
CREATE INDEX IF NOT EXISTS idx_tie_notifications_recipient ON public.tie_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_tie_notifications_status ON public.tie_notifications(notification_status);

-- ============================================================================
-- 2. ABSTENTIONS TRACKING SYSTEM
-- ============================================================================

-- Abstention votes table (separate from regular votes)
CREATE TABLE IF NOT EXISTS public.abstention_votes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    reason TEXT, -- Optional: lack of information, neutral stance, protest vote
    abstained_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_election_abstention UNIQUE (election_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_abstention_votes_election ON public.abstention_votes(election_id);
CREATE INDEX IF NOT EXISTS idx_abstention_votes_user ON public.abstention_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_abstention_votes_abstained_at ON public.abstention_votes(abstained_at);

-- Abstention analytics table (per election tracking)
CREATE TABLE IF NOT EXISTS public.abstention_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    election_id UUID NOT NULL UNIQUE REFERENCES public.elections(id) ON DELETE CASCADE,
    total_abstentions INTEGER DEFAULT 0,
    abstention_rate NUMERIC(5, 2) DEFAULT 0.00, -- Percentage
    reason_lack_of_info INTEGER DEFAULT 0,
    reason_neutral_stance INTEGER DEFAULT 0,
    reason_protest_vote INTEGER DEFAULT 0,
    reason_unspecified INTEGER DEFAULT 0,
    alert_sent BOOLEAN DEFAULT false,
    alert_sent_at TIMESTAMPTZ,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_abstention_analytics_election ON public.abstention_analytics(election_id);
CREATE INDEX IF NOT EXISTS idx_abstention_analytics_rate ON public.abstention_analytics(abstention_rate);

-- Abstention trends table (time-series tracking)
CREATE TABLE IF NOT EXISTS public.abstention_trends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    date DATE NOT NULL,
    total_elections INTEGER DEFAULT 0,
    elections_with_abstentions INTEGER DEFAULT 0,
    average_abstention_rate NUMERIC(5, 2) DEFAULT 0.00,
    high_abstention_elections INTEGER DEFAULT 0, -- Rate > 20%
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_abstention_date UNIQUE (date)
);

CREATE INDEX IF NOT EXISTS idx_abstention_trends_date ON public.abstention_trends(date);

-- ============================================================================
-- 3. COMMUNITY ELECTIONS HUB
-- ============================================================================

-- Communities table (topic-based spaces)
CREATE TABLE IF NOT EXISTS public.communities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    topic TEXT NOT NULL CHECK (topic IN ('Politics', 'Sports', 'Entertainment', 'Technology', 'Education', 'Environment', 'Social Issues', 'Local Government')),
    description TEXT,
    creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    member_count INTEGER DEFAULT 1,
    privacy_level TEXT NOT NULL DEFAULT 'public' CHECK (privacy_level IN ('public', 'private', 'invite_only')),
    election_approval_required BOOLEAN DEFAULT false,
    posting_permissions TEXT DEFAULT 'all_members' CHECK (posting_permissions IN ('all_members', 'moderators_only', 'admin_only')),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    featured BOOLEAN DEFAULT false,
    banner_image_url TEXT,
    avatar_image_url TEXT
);

CREATE INDEX IF NOT EXISTS idx_communities_creator ON public.communities(creator_id);
CREATE INDEX IF NOT EXISTS idx_communities_topic ON public.communities(topic);
CREATE INDEX IF NOT EXISTS idx_communities_privacy ON public.communities(privacy_level);
CREATE INDEX IF NOT EXISTS idx_communities_featured ON public.communities(featured);
CREATE INDEX IF NOT EXISTS idx_communities_active ON public.communities(is_active);

-- Community members table (membership tracking)
CREATE TABLE IF NOT EXISTS public.community_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member')),
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_banned BOOLEAN DEFAULT false,
    banned_at TIMESTAMPTZ,
    banned_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    ban_reason TEXT,
    CONSTRAINT unique_community_user UNIQUE (community_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_community_members_community ON public.community_members(community_id);
CREATE INDEX IF NOT EXISTS idx_community_members_user ON public.community_members(user_id);
CREATE INDEX IF NOT EXISTS idx_community_members_role ON public.community_members(role);

-- Community elections table (links elections to communities)
CREATE TABLE IF NOT EXISTS public.community_elections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    election_id UUID NOT NULL UNIQUE REFERENCES public.elections(id) ON DELETE CASCADE,
    posted_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    approval_status TEXT DEFAULT 'approved' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    approved_at TIMESTAMPTZ,
    rejection_reason TEXT,
    posted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_community_elections_community ON public.community_elections(community_id);
CREATE INDEX IF NOT EXISTS idx_community_elections_election ON public.community_elections(election_id);
CREATE INDEX IF NOT EXISTS idx_community_elections_posted_by ON public.community_elections(posted_by);
CREATE INDEX IF NOT EXISTS idx_community_elections_approval_status ON public.community_elections(approval_status);

-- Community join requests table (for private/invite-only communities)
CREATE TABLE IF NOT EXISTS public.community_join_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    message TEXT,
    requested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reviewed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    CONSTRAINT unique_community_join_request UNIQUE (community_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_community_join_requests_community ON public.community_join_requests(community_id);
CREATE INDEX IF NOT EXISTS idx_community_join_requests_user ON public.community_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_community_join_requests_status ON public.community_join_requests(status);

-- Community analytics table (growth and engagement metrics)
CREATE TABLE IF NOT EXISTS public.community_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL UNIQUE REFERENCES public.communities(id) ON DELETE CASCADE,
    total_elections INTEGER DEFAULT 0,
    total_votes INTEGER DEFAULT 0,
    active_members_7d INTEGER DEFAULT 0,
    active_members_30d INTEGER DEFAULT 0,
    growth_rate_7d NUMERIC(5, 2) DEFAULT 0.00,
    engagement_rate NUMERIC(5, 2) DEFAULT 0.00,
    last_election_posted_at TIMESTAMPTZ,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_community_analytics_community ON public.community_analytics(community_id);

-- Community moderation logs table (content flagging and actions)
CREATE TABLE IF NOT EXISTS public.community_moderation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
    moderator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL CHECK (action_type IN ('content_flagged', 'member_warned', 'member_banned', 'election_removed', 'election_approved', 'election_rejected')),
    target_user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    target_election_id UUID REFERENCES public.elections(id) ON DELETE SET NULL,
    reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_community_moderation_logs_community ON public.community_moderation_logs(community_id);
CREATE INDEX IF NOT EXISTS idx_community_moderation_logs_moderator ON public.community_moderation_logs(moderator_id);
CREATE INDEX IF NOT EXISTS idx_community_moderation_logs_action_type ON public.community_moderation_logs(action_type);

-- ============================================================================
-- 4. RLS POLICIES
-- ============================================================================

-- Tie results policies
ALTER TABLE public.tie_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view tie results for elections they can access"
  ON public.tie_results FOR SELECT
  USING (true);

CREATE POLICY "Election creators can update tie results"
  ON public.tie_results FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = tie_results.election_id
      AND elections.created_by = auth.uid()
    )
  );

CREATE POLICY "System can insert tie results"
  ON public.tie_results FOR INSERT
  WITH CHECK (true);

-- Abstention votes policies
ALTER TABLE public.abstention_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert their own abstentions"
  ON public.abstention_votes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view their own abstentions"
  ON public.abstention_votes FOR SELECT
  USING (auth.uid() = user_id);

-- Abstention analytics policies
ALTER TABLE public.abstention_analytics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view abstention analytics"
  ON public.abstention_analytics FOR SELECT
  USING (true);

CREATE POLICY "System can manage abstention analytics"
  ON public.abstention_analytics FOR ALL
  USING (true)
  WITH CHECK (true);

-- Communities policies
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view public communities"
  ON public.communities FOR SELECT
  USING (privacy_level = 'public' OR auth.uid() = creator_id OR
    EXISTS (
      SELECT 1 FROM public.community_members
      WHERE community_members.community_id = communities.id
      AND community_members.user_id = auth.uid()
    )
  );

CREATE POLICY "Authenticated users can create communities"
  ON public.communities FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Community admins can update communities"
  ON public.communities FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.community_members
      WHERE community_members.community_id = communities.id
      AND community_members.user_id = auth.uid()
      AND community_members.role = 'admin'
    )
  );

-- Community members policies
ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view community members"
  ON public.community_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.communities
      WHERE communities.id = community_members.community_id
      AND (communities.privacy_level = 'public' OR
        EXISTS (
          SELECT 1 FROM public.community_members cm
          WHERE cm.community_id = communities.id
          AND cm.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Users can join public communities"
  ON public.community_members FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
      SELECT 1 FROM public.communities
      WHERE communities.id = community_members.community_id
      AND communities.privacy_level = 'public'
    )
  );

CREATE POLICY "Admins and moderators can manage members"
  ON public.community_members FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.community_members cm
      WHERE cm.community_id = community_members.community_id
      AND cm.user_id = auth.uid()
      AND cm.role IN ('admin', 'moderator')
    )
  );

-- Community elections policies
ALTER TABLE public.community_elections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view community elections"
  ON public.community_elections FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.communities
      WHERE communities.id = community_elections.community_id
      AND (communities.privacy_level = 'public' OR
        EXISTS (
          SELECT 1 FROM public.community_members
          WHERE community_members.community_id = communities.id
          AND community_members.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "Community members can post elections"
  ON public.community_elections FOR INSERT
  WITH CHECK (
    auth.uid() = posted_by AND
    EXISTS (
      SELECT 1 FROM public.community_members
      WHERE community_members.community_id = community_elections.community_id
      AND community_members.user_id = auth.uid()
    )
  );

-- ============================================================================
-- 5. FUNCTIONS
-- ============================================================================

-- Function to detect ties in election results
CREATE OR REPLACE FUNCTION public.detect_election_tie(
  p_election_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_voting_method TEXT;
  v_vote_counts JSONB;
  v_max_votes INTEGER;
  v_tied_options JSONB;
  v_tie_exists BOOLEAN := false;
BEGIN
  -- Get election voting method
  SELECT voting_method INTO v_voting_method
  FROM public.elections
  WHERE id = p_election_id;

  -- Count votes per option
  SELECT jsonb_agg(
    jsonb_build_object(
      'option_id', eo.id,
      'option_title', eo.option_text,
      'vote_count', COALESCE(vote_count, 0)
    ) ORDER BY COALESCE(vote_count, 0) DESC
  )
  INTO v_vote_counts
  FROM public.election_options eo
  LEFT JOIN (
    SELECT selected_option_id, COUNT(*) as vote_count
    FROM public.votes
    WHERE election_id = p_election_id
    GROUP BY selected_option_id
  ) v ON v.selected_option_id = eo.id
  WHERE eo.election_id = p_election_id;

  -- Get max vote count
  SELECT MAX((item->>'vote_count')::INTEGER)
  INTO v_max_votes
  FROM jsonb_array_elements(v_vote_counts) item;

  -- Find all options with max votes
  SELECT jsonb_agg(item)
  INTO v_tied_options
  FROM jsonb_array_elements(v_vote_counts) item
  WHERE (item->>'vote_count')::INTEGER = v_max_votes;

  -- Check if tie exists (more than one option with max votes)
  IF jsonb_array_length(v_tied_options) > 1 THEN
    v_tie_exists := true;

    -- Insert tie result
    INSERT INTO public.tie_results (
      election_id,
      tied_candidates,
      tied_vote_count,
      resolution_status,
      resolution_method
    )
    VALUES (
      p_election_id,
      v_tied_options,
      v_max_votes,
      'unresolved',
      'pending'
    )
    ON CONFLICT (election_id) DO UPDATE
    SET tied_candidates = EXCLUDED.tied_candidates,
        tied_vote_count = EXCLUDED.tied_vote_count,
        detected_at = CURRENT_TIMESTAMP;

    -- Update tie analytics
    INSERT INTO public.tie_analytics (voting_method, total_ties, last_tie_detected_at)
    VALUES (v_voting_method, 1, CURRENT_TIMESTAMP)
    ON CONFLICT (voting_method) DO UPDATE
    SET total_ties = tie_analytics.total_ties + 1,
        last_tie_detected_at = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP;
  END IF;

  RETURN v_tie_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update abstention analytics
CREATE OR REPLACE FUNCTION public.update_abstention_analytics(
  p_election_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_total_abstentions INTEGER;
  v_total_participants INTEGER;
  v_abstention_rate NUMERIC(5, 2);
  v_reason_counts RECORD;
BEGIN
  -- Count total abstentions
  SELECT COUNT(*) INTO v_total_abstentions
  FROM public.abstention_votes
  WHERE election_id = p_election_id;

  -- Count total participants (votes + abstentions)
  SELECT 
    (SELECT COUNT(*) FROM public.votes WHERE election_id = p_election_id) +
    v_total_abstentions
  INTO v_total_participants;

  -- Calculate abstention rate
  IF v_total_participants > 0 THEN
    v_abstention_rate := (v_total_abstentions::NUMERIC / v_total_participants::NUMERIC) * 100;
  ELSE
    v_abstention_rate := 0;
  END IF;

  -- Count reasons
  SELECT 
    COUNT(*) FILTER (WHERE reason ILIKE '%lack of information%') as lack_of_info,
    COUNT(*) FILTER (WHERE reason ILIKE '%neutral%') as neutral_stance,
    COUNT(*) FILTER (WHERE reason ILIKE '%protest%') as protest_vote,
    COUNT(*) FILTER (WHERE reason IS NULL OR reason = '') as unspecified
  INTO v_reason_counts
  FROM public.abstention_votes
  WHERE election_id = p_election_id;

  -- Update analytics
  INSERT INTO public.abstention_analytics (
    election_id,
    total_abstentions,
    abstention_rate,
    reason_lack_of_info,
    reason_neutral_stance,
    reason_protest_vote,
    reason_unspecified,
    last_updated
  )
  VALUES (
    p_election_id,
    v_total_abstentions,
    v_abstention_rate,
    v_reason_counts.lack_of_info,
    v_reason_counts.neutral_stance,
    v_reason_counts.protest_vote,
    v_reason_counts.unspecified,
    CURRENT_TIMESTAMP
  )
  ON CONFLICT (election_id) DO UPDATE
  SET total_abstentions = EXCLUDED.total_abstentions,
      abstention_rate = EXCLUDED.abstention_rate,
      reason_lack_of_info = EXCLUDED.reason_lack_of_info,
      reason_neutral_stance = EXCLUDED.reason_neutral_stance,
      reason_protest_vote = EXCLUDED.reason_protest_vote,
      reason_unspecified = EXCLUDED.reason_unspecified,
      last_updated = CURRENT_TIMESTAMP;

  -- Send alert if abstention rate exceeds 20%
  IF v_abstention_rate > 20 AND NOT EXISTS (
    SELECT 1 FROM public.abstention_analytics
    WHERE election_id = p_election_id AND alert_sent = true
  ) THEN
    UPDATE public.abstention_analytics
    SET alert_sent = true, alert_sent_at = CURRENT_TIMESTAMP
    WHERE election_id = p_election_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update community member count
CREATE OR REPLACE FUNCTION public.update_community_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.communities
    SET member_count = member_count + 1,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.community_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.communities
    SET member_count = GREATEST(member_count - 1, 0),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = OLD.community_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for community member count
DROP TRIGGER IF EXISTS trigger_update_community_member_count ON public.community_members;
CREATE TRIGGER trigger_update_community_member_count
  AFTER INSERT OR DELETE ON public.community_members
  FOR EACH ROW
  EXECUTE FUNCTION public.update_community_member_count();

-- ============================================================================
-- 6. MOCK DATA
-- ============================================================================

-- Mock tie results (only if elections exist)
DO $$
DECLARE
  v_election_id UUID;
  v_option1_id UUID;
  v_option2_id UUID;
BEGIN
  -- Get a sample election
  SELECT id INTO v_election_id FROM public.elections LIMIT 1;
  
  IF v_election_id IS NOT NULL THEN
    -- Get two options from that election
    SELECT id INTO v_option1_id FROM public.election_options WHERE election_id = v_election_id LIMIT 1;
    SELECT id INTO v_option2_id FROM public.election_options WHERE election_id = v_election_id OFFSET 1 LIMIT 1;
    
    IF v_option1_id IS NOT NULL AND v_option2_id IS NOT NULL THEN
      INSERT INTO public.tie_results (election_id, tied_candidates, tied_vote_count, resolution_status, resolution_method)
      VALUES (
        v_election_id,
        jsonb_build_array(
          jsonb_build_object('option_id', v_option1_id, 'option_title', 'Option A', 'vote_count', 125),
          jsonb_build_object('option_id', v_option2_id, 'option_title', 'Option B', 'vote_count', 125)
        ),
        125,
        'unresolved',
        'pending'
      )
      ON CONFLICT (election_id) DO NOTHING;
    END IF;
  END IF;
END $$;

-- Mock tie analytics
INSERT INTO public.tie_analytics (voting_method, total_ties, runoff_resolutions, manual_resolutions, lottery_resolutions, average_resolution_time_hours, last_tie_detected_at)
VALUES 
  ('plurality', 5, 3, 1, 1, 24.5, CURRENT_TIMESTAMP - INTERVAL '2 days'),
  ('ranked_choice', 2, 1, 1, 0, 18.0, CURRENT_TIMESTAMP - INTERVAL '5 days'),
  ('approval', 1, 0, 1, 0, 12.0, CURRENT_TIMESTAMP - INTERVAL '10 days')
ON CONFLICT (voting_method) DO NOTHING;

-- Mock communities
DO $$
DECLARE
  v_user_id UUID;
  v_community1_id UUID;
  v_community2_id UUID;
  v_community3_id UUID;
BEGIN
  -- Get a sample user
  SELECT id INTO v_user_id FROM public.user_profiles LIMIT 1;
  
  IF v_user_id IS NOT NULL THEN
    -- Insert first community
    INSERT INTO public.communities (name, topic, description, creator_id, privacy_level, featured)
    VALUES ('Tech Innovators Hub', 'Technology', 'Discuss latest tech trends and innovations', v_user_id, 'public', true)
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_community1_id;
    
    -- Insert second community
    INSERT INTO public.communities (name, topic, description, creator_id, privacy_level, featured)
    VALUES ('Local Government Watch', 'Local Government', 'Community oversight of local government decisions', v_user_id, 'public', true)
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_community2_id;
    
    -- Insert third community
    INSERT INTO public.communities (name, topic, description, creator_id, privacy_level, featured)
    VALUES ('Environmental Action Group', 'Environment', 'Vote on environmental initiatives and policies', v_user_id, 'private', false)
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_community3_id;
    
    -- Add creator as admin member
    IF v_community1_id IS NOT NULL THEN
      INSERT INTO public.community_members (community_id, user_id, role)
      VALUES (v_community1_id, v_user_id, 'admin')
      ON CONFLICT (community_id, user_id) DO NOTHING;
    END IF;
    
    IF v_community2_id IS NOT NULL THEN
      INSERT INTO public.community_members (community_id, user_id, role)
      VALUES (v_community2_id, v_user_id, 'admin')
      ON CONFLICT (community_id, user_id) DO NOTHING;
    END IF;
    
    IF v_community3_id IS NOT NULL THEN
      INSERT INTO public.community_members (community_id, user_id, role)
      VALUES (v_community3_id, v_user_id, 'admin')
      ON CONFLICT (community_id, user_id) DO NOTHING;
    END IF;
    
    -- Initialize community analytics
    IF v_community1_id IS NOT NULL THEN
      INSERT INTO public.community_analytics (community_id, total_elections, total_votes, active_members_7d, engagement_rate)
      VALUES (v_community1_id, 12, 487, 45, 78.5)
      ON CONFLICT (community_id) DO NOTHING;
    END IF;
  END IF;
END $$;

-- Mock abstention trends
INSERT INTO public.abstention_trends (date, total_elections, elections_with_abstentions, average_abstention_rate, high_abstention_elections)
VALUES 
  (CURRENT_DATE - INTERVAL '7 days', 25, 18, 12.5, 3),
  (CURRENT_DATE - INTERVAL '6 days', 30, 22, 14.2, 4),
  (CURRENT_DATE - INTERVAL '5 days', 28, 20, 11.8, 2),
  (CURRENT_DATE - INTERVAL '4 days', 32, 24, 15.6, 5),
  (CURRENT_DATE - INTERVAL '3 days', 27, 19, 13.1, 3),
  (CURRENT_DATE - INTERVAL '2 days', 29, 21, 12.9, 4),
  (CURRENT_DATE - INTERVAL '1 day', 31, 23, 14.5, 4)
ON CONFLICT (date) DO NOTHING;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
