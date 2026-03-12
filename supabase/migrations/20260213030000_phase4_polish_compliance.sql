-- Phase 4: Polish & Compliance Migration
-- Timestamp: 20260213030000
-- Description: Biometric voting toggle, voter permission controls, voice messages, emoji reactions, rich media gallery

-- ============================================================
-- 1. TYPES
-- ============================================================

DO $$ BEGIN
  CREATE TYPE public.voter_permission_type AS ENUM (
    'public',
    'group_only',
    'country_specific',
    'verified_only',
    'invited_only'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.emoji_reaction_type AS ENUM (
    'like',
    'love',
    'laugh',
    'wow',
    'sad',
    'angry',
    'thumbs_up',
    'thumbs_down',
    'fire',
    'heart',
    'clap',
    'thinking'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 2. EXTEND ELECTIONS TABLE FOR BIOMETRIC & PERMISSIONS
-- ============================================================

ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS biometric_required BOOLEAN DEFAULT false;
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS voter_permission_type public.voter_permission_type DEFAULT 'public';
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS allowed_countries TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE public.elections ADD COLUMN IF NOT EXISTS allowed_group_ids UUID[] DEFAULT ARRAY[]::UUID[];

-- ============================================================
-- 3. VOTER GROUPS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.voter_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  group_name TEXT NOT NULL,
  description TEXT,
  member_ids UUID[] DEFAULT ARRAY[]::UUID[],
  created_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.voter_group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.voter_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  added_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(group_id, user_id)
);

-- ============================================================
-- 4. EXTEND MESSAGES TABLE FOR VOICE & MEDIA
-- ============================================================

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_url TEXT;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_duration_seconds INTEGER;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_urls TEXT[] DEFAULT ARRAY[]::TEXT[];
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS media_metadata JSONB DEFAULT '{}'::jsonb;

-- ============================================================
-- 5. MESSAGE REACTIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  emoji public.emoji_reaction_type NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(message_id, user_id, emoji)
);

-- ============================================================
-- 6. CONVERSATION MEDIA GALLERY TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.conversation_media_gallery (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL,
  thumbnail_url TEXT,
  file_size_bytes BIGINT,
  width INTEGER,
  height INTEGER,
  duration_seconds INTEGER,
  uploaded_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 7. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_voter_groups_election_id ON public.voter_groups(election_id);
CREATE INDEX IF NOT EXISTS idx_voter_group_members_group_id ON public.voter_group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_voter_group_members_user_id ON public.voter_group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON public.message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_user_id ON public.message_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_media_gallery_conversation_id ON public.conversation_media_gallery(conversation_id);
CREATE INDEX IF NOT EXISTS idx_conversation_media_gallery_message_id ON public.conversation_media_gallery(message_id);
CREATE INDEX IF NOT EXISTS idx_elections_biometric_required ON public.elections(biometric_required);
CREATE INDEX IF NOT EXISTS idx_elections_voter_permission_type ON public.elections(voter_permission_type);

-- ============================================================
-- 8. FUNCTIONS
-- ============================================================

-- Check voter permission
CREATE OR REPLACE FUNCTION public.check_voter_permission(
  p_user_id UUID,
  p_election_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_election RECORD;
  v_user_country TEXT;
  v_is_member BOOLEAN;
BEGIN
  -- Get election details
  SELECT * INTO v_election
  FROM public.elections
  WHERE id = p_election_id;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Check permission type
  CASE v_election.voter_permission_type
    WHEN 'public' THEN
      RETURN true;
    
    WHEN 'country_specific' THEN
      -- Get user country from profile
      SELECT country INTO v_user_country
      FROM public.user_profiles
      WHERE id = p_user_id;
      
      RETURN v_user_country = ANY(v_election.allowed_countries);
    
    WHEN 'group_only' THEN
      -- Check if user is member of allowed groups
      SELECT EXISTS(
        SELECT 1
        FROM public.voter_group_members vgm
        WHERE vgm.user_id = p_user_id
        AND vgm.group_id = ANY(v_election.allowed_group_ids)
      ) INTO v_is_member;
      
      RETURN v_is_member;
    
    WHEN 'verified_only' THEN
      -- Check if user has verified status
      SELECT is_verified INTO v_is_member
      FROM public.user_profiles
      WHERE id = p_user_id;
      
      RETURN COALESCE(v_is_member, false);
    
    ELSE
      RETURN false;
  END CASE;
END;
$$;

-- Get message reaction counts
CREATE OR REPLACE FUNCTION public.get_message_reaction_counts(
  p_message_id UUID
)
RETURNS TABLE(emoji public.emoji_reaction_type, count BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT mr.emoji, COUNT(*) as count
  FROM public.message_reactions mr
  WHERE mr.message_id = p_message_id
  GROUP BY mr.emoji
  ORDER BY count DESC;
END;
$$;

-- ============================================================
-- 9. ENABLE RLS
-- ============================================================

ALTER TABLE public.voter_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voter_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_media_gallery ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 10. RLS POLICIES
-- ============================================================

-- Voter groups policies
DROP POLICY IF EXISTS "creators_manage_voter_groups" ON public.voter_groups;
CREATE POLICY "creators_manage_voter_groups"
ON public.voter_groups
FOR ALL
USING (auth.uid() = created_by);

DROP POLICY IF EXISTS "members_view_voter_groups" ON public.voter_groups;
CREATE POLICY "members_view_voter_groups"
ON public.voter_groups
FOR SELECT
USING (
  auth.uid() = created_by OR
  auth.uid() = ANY(member_ids)
);

-- Voter group members policies
DROP POLICY IF EXISTS "members_view_group_members" ON public.voter_group_members;
CREATE POLICY "members_view_group_members"
ON public.voter_group_members
FOR SELECT
USING (
  EXISTS(
    SELECT 1 FROM public.voter_groups vg
    WHERE vg.id = group_id
    AND (vg.created_by = auth.uid() OR auth.uid() = ANY(vg.member_ids))
  )
);

-- Message reactions policies
DROP POLICY IF EXISTS "users_view_message_reactions" ON public.message_reactions;
CREATE POLICY "users_view_message_reactions"
ON public.message_reactions
FOR SELECT
USING (
  EXISTS(
    SELECT 1 FROM public.messages m
    JOIN public.conversations c ON m.conversation_id = c.id
    WHERE m.id = message_id
    AND auth.uid() = ANY(c.participant_ids)
  )
);

DROP POLICY IF EXISTS "users_manage_own_reactions" ON public.message_reactions;
CREATE POLICY "users_manage_own_reactions"
ON public.message_reactions
FOR ALL
USING (auth.uid() = user_id);

-- Conversation media gallery policies
DROP POLICY IF EXISTS "participants_view_media_gallery" ON public.conversation_media_gallery;
CREATE POLICY "participants_view_media_gallery"
ON public.conversation_media_gallery
FOR SELECT
USING (
  EXISTS(
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id
    AND auth.uid() = ANY(c.participant_ids)
  )
);

DROP POLICY IF EXISTS "participants_insert_media" ON public.conversation_media_gallery;
CREATE POLICY "participants_insert_media"
ON public.conversation_media_gallery
FOR INSERT
WITH CHECK (
  auth.uid() = uploaded_by AND
  EXISTS(
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id
    AND auth.uid() = ANY(c.participant_ids)
  )
);

COMMENT ON TABLE public.voter_groups IS 'Voter permission groups for group-only elections';
COMMENT ON TABLE public.message_reactions IS 'Emoji reactions for direct messages';
COMMENT ON TABLE public.conversation_media_gallery IS 'Rich media gallery for conversations with image/video sharing';