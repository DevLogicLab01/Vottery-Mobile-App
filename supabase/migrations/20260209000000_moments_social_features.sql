-- Moments & Social Features Migration
-- Timestamp: 20260209000000
-- Description: Moments (Stories), Follow/Unfollow, Social Posts, Notifications, Recommendations

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.moment_status CASCADE;
CREATE TYPE public.moment_status AS ENUM (
  'active',
  'expired',
  'archived',
  'flagged'
);

DROP TYPE IF EXISTS public.post_type CASCADE;
CREATE TYPE public.post_type AS ENUM (
  'text',
  'image',
  'video',
  'poll',
  'live'
);

DROP TYPE IF EXISTS public.notification_type CASCADE;
CREATE TYPE public.notification_type AS ENUM (
  'friend_request',
  'friend_accepted',
  'follow',
  'like',
  'comment',
  'share',
  'mention',
  'message',
  'election',
  'system'
);

-- ============================================================
-- 2. FOLLOW/UNFOLLOW SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_followers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

CREATE INDEX IF NOT EXISTS idx_user_followers_follower ON public.user_followers(follower_id);
CREATE INDEX IF NOT EXISTS idx_user_followers_following ON public.user_followers(following_id);

-- ============================================================
-- 3. MOMENTS (STORIES) SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.moments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL DEFAULT 'image',
  thumbnail_url TEXT,
  caption TEXT,
  duration_seconds INTEGER DEFAULT 5,
  background_color TEXT,
  text_overlay JSONB,
  music_url TEXT,
  view_count INTEGER DEFAULT 0,
  status public.moment_status DEFAULT 'active',
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Ensure creator_id column exists in moments table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'moments'
      AND column_name = 'creator_id'
  ) THEN
    ALTER TABLE public.moments ADD COLUMN creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_moments_creator ON public.moments(creator_id);
CREATE INDEX IF NOT EXISTS idx_moments_status ON public.moments(status);
CREATE INDEX IF NOT EXISTS idx_moments_expires ON public.moments(expires_at);

CREATE TABLE IF NOT EXISTS public.moment_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID NOT NULL REFERENCES public.moments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  interaction_type TEXT NOT NULL,
  emoji TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(moment_id, user_id, interaction_type)
);

CREATE INDEX IF NOT EXISTS idx_moment_interactions_moment ON public.moment_interactions(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_interactions_user ON public.moment_interactions(user_id);

CREATE TABLE IF NOT EXISTS public.moment_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID NOT NULL REFERENCES public.moments(id) ON DELETE CASCADE,
  viewer_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(moment_id, viewer_id)
);

CREATE INDEX IF NOT EXISTS idx_moment_views_moment ON public.moment_views(moment_id);

-- ============================================================
-- 4. SOCIAL POSTS SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.social_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  post_type public.post_type DEFAULT 'text',
  content TEXT,
  media_urls TEXT[],
  poll_options JSONB,
  location TEXT,
  tagged_users UUID[],
  visibility TEXT DEFAULT 'public',
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Ensure creator_id column exists in social_posts table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'social_posts'
      AND column_name = 'creator_id'
  ) THEN
    ALTER TABLE public.social_posts ADD COLUMN creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_social_posts_creator ON public.social_posts(creator_id);
CREATE INDEX IF NOT EXISTS idx_social_posts_created ON public.social_posts(created_at DESC);

-- Ensure visibility column exists in social_posts table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'social_posts'
      AND column_name = 'visibility'
  ) THEN
    ALTER TABLE public.social_posts ADD COLUMN visibility TEXT DEFAULT 'public';
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.post_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  interaction_type TEXT NOT NULL,
  emoji TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(post_id, user_id, interaction_type)
);

CREATE INDEX IF NOT EXISTS idx_post_interactions_post ON public.post_interactions(post_id);

CREATE TABLE IF NOT EXISTS public.post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  comment_text TEXT NOT NULL,
  parent_comment_id UUID REFERENCES public.post_comments(id) ON DELETE CASCADE,
  like_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_post_comments_post ON public.post_comments(post_id);

-- ============================================================
-- 5. NOTIFICATIONS SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  notification_type public.notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  actor_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reference_id UUID,
  reference_type TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON public.notifications(created_at DESC);

-- ============================================================
-- 6. RECOMMENDATIONS SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.suggested_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  suggested_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reason TEXT,
  mutual_friends_count INTEGER DEFAULT 0,
  score NUMERIC(5,2) DEFAULT 0,
  dismissed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, suggested_user_id)
);

CREATE INDEX IF NOT EXISTS idx_suggested_connections_user ON public.suggested_connections(user_id);
CREATE INDEX IF NOT EXISTS idx_suggested_connections_score ON public.suggested_connections(score DESC);

CREATE TABLE IF NOT EXISTS public.recommended_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  group_id UUID NOT NULL REFERENCES public.user_groups(id) ON DELETE CASCADE,
  reason TEXT,
  score NUMERIC(5,2) DEFAULT 0,
  dismissed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, group_id)
);

CREATE INDEX IF NOT EXISTS idx_recommended_groups_user ON public.recommended_groups(user_id);
CREATE INDEX IF NOT EXISTS idx_recommended_groups_score ON public.recommended_groups(score DESC);

CREATE TABLE IF NOT EXISTS public.recommended_elections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  reason TEXT,
  score NUMERIC(5,2) DEFAULT 0,
  dismissed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, election_id)
);

CREATE INDEX IF NOT EXISTS idx_recommended_elections_user ON public.recommended_elections(user_id);
CREATE INDEX IF NOT EXISTS idx_recommended_elections_score ON public.recommended_elections(score DESC);

-- ============================================================
-- 7. RLS POLICIES
-- ============================================================

-- User Followers Policies
ALTER TABLE public.user_followers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all followers" ON public.user_followers;
CREATE POLICY "Users can view all followers"
  ON public.user_followers FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can follow others" ON public.user_followers;
CREATE POLICY "Users can follow others"
  ON public.user_followers FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

DROP POLICY IF EXISTS "Users can unfollow" ON public.user_followers;
CREATE POLICY "Users can unfollow"
  ON public.user_followers FOR DELETE
  USING (auth.uid() = follower_id);

-- Moments Policies
ALTER TABLE public.moments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view active moments" ON public.moments;
CREATE POLICY "Users can view active moments"
  ON public.moments FOR SELECT
  USING (status = 'active' AND expires_at > CURRENT_TIMESTAMP);

DROP POLICY IF EXISTS "Users can create moments" ON public.moments;
CREATE POLICY "Users can create moments"
  ON public.moments FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Users can update own moments" ON public.moments;
CREATE POLICY "Users can update own moments"
  ON public.moments FOR UPDATE
  USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Users can delete own moments" ON public.moments;
CREATE POLICY "Users can delete own moments"
  ON public.moments FOR DELETE
  USING (auth.uid() = creator_id);

-- Moment Interactions Policies
ALTER TABLE public.moment_interactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view moment interactions" ON public.moment_interactions;
CREATE POLICY "Users can view moment interactions"
  ON public.moment_interactions FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can create moment interactions" ON public.moment_interactions;
CREATE POLICY "Users can create moment interactions"
  ON public.moment_interactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Social Posts Policies
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view public posts" ON public.social_posts;
CREATE POLICY "Users can view public posts"
  ON public.social_posts FOR SELECT
  USING (visibility = 'public' OR auth.uid() = creator_id);

DROP POLICY IF EXISTS "Users can create posts" ON public.social_posts;
CREATE POLICY "Users can create posts"
  ON public.social_posts FOR INSERT
  WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Users can update own posts" ON public.social_posts;
CREATE POLICY "Users can update own posts"
  ON public.social_posts FOR UPDATE
  USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Users can delete own posts" ON public.social_posts;
CREATE POLICY "Users can delete own posts"
  ON public.social_posts FOR DELETE
  USING (auth.uid() = creator_id);

-- Notifications Policies
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);

-- Recommendations Policies
ALTER TABLE public.suggested_connections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own suggestions" ON public.suggested_connections;
CREATE POLICY "Users can view own suggestions"
  ON public.suggested_connections FOR SELECT
  USING (auth.uid() = user_id);

ALTER TABLE public.recommended_groups ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view group recommendations" ON public.recommended_groups;
CREATE POLICY "Users can view group recommendations"
  ON public.recommended_groups FOR SELECT
  USING (auth.uid() = user_id);

ALTER TABLE public.recommended_elections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view election recommendations" ON public.recommended_elections;
CREATE POLICY "Users can view election recommendations"
  ON public.recommended_elections FOR SELECT
  USING (auth.uid() = user_id);

-- ============================================================
-- 8. FUNCTIONS & TRIGGERS
-- ============================================================

-- Auto-expire moments after 24 hours
CREATE OR REPLACE FUNCTION public.expire_old_moments()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.moments
  SET status = 'expired'
  WHERE status = 'active'
    AND expires_at <= CURRENT_TIMESTAMP;
END;
$$;

-- Create notification function
CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id UUID,
  p_type public.notification_type,
  p_title TEXT,
  p_message TEXT,
  p_actor_id UUID DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_reference_type TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO public.notifications (
    user_id,
    notification_type,
    title,
    message,
    actor_id,
    reference_id,
    reference_type
  ) VALUES (
    p_user_id,
    p_type,
    p_title,
    p_message,
    p_actor_id,
    p_reference_id,
    p_reference_type
  )
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$;

-- Trigger: Create notification on new follower
CREATE OR REPLACE FUNCTION public.notify_new_follower()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_follower_name TEXT;
BEGIN
  SELECT username INTO v_follower_name
  FROM public.user_profiles
  WHERE id = NEW.follower_id;
  
  PERFORM public.create_notification(
    NEW.following_id,
    'follow',
    'New Follower',
    v_follower_name || ' started following you',
    NEW.follower_id,
    NEW.id,
    'follow'
  );
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_notify_new_follower ON public.user_followers;
CREATE TRIGGER trigger_notify_new_follower
  AFTER INSERT ON public.user_followers
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_follower();

-- Trigger: Update follower counts
CREATE OR REPLACE FUNCTION public.update_follower_counts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.user_profiles
    SET follower_count = follower_count + 1
    WHERE id = NEW.following_id;
    
    UPDATE public.user_profiles
    SET following_count = following_count + 1
    WHERE id = NEW.follower_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.user_profiles
    SET follower_count = GREATEST(0, follower_count - 1)
    WHERE id = OLD.following_id;
    
    UPDATE public.user_profiles
    SET following_count = GREATEST(0, following_count - 1)
    WHERE id = OLD.follower_id;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_follower_counts ON public.user_followers;
CREATE TRIGGER trigger_update_follower_counts
  AFTER INSERT OR DELETE ON public.user_followers
  FOR EACH ROW
  EXECUTE FUNCTION public.update_follower_counts();

-- Add follower/following counts to user_profiles if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'user_profiles'
      AND column_name = 'follower_count'
  ) THEN
    ALTER TABLE public.user_profiles ADD COLUMN follower_count INTEGER DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'user_profiles'
      AND column_name = 'following_count'
  ) THEN
    ALTER TABLE public.user_profiles ADD COLUMN following_count INTEGER DEFAULT 0;
  END IF;
END $$;