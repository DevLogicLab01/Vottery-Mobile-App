-- Social Posts System Migration
-- Timestamp: 20260208000000
-- Description: Dedicated social posts with multi-media support, comment threads, share functionality

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.post_type CASCADE;
CREATE TYPE public.post_type AS ENUM (
  'text',
  'image',
  'video',
  'poll'
);

DROP TYPE IF EXISTS public.post_status CASCADE;
CREATE TYPE public.post_status AS ENUM (
  'draft',
  'published',
  'archived',
  'flagged'
);

-- ============================================================
-- 2. SOCIAL POSTS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.social_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  post_type public.post_type NOT NULL DEFAULT 'text',
  content TEXT,
  media_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
  hashtags TEXT[] DEFAULT ARRAY[]::TEXT[],
  mentions UUID[] DEFAULT ARRAY[]::UUID[],
  location TEXT,
  privacy_level TEXT DEFAULT 'public',
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  engagement_score NUMERIC(10,2) DEFAULT 0,
  vp_earned INTEGER DEFAULT 0,
  status public.post_status DEFAULT 'published',
  scheduled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(post_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.post_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  parent_comment_id UUID REFERENCES public.post_comments(id) ON DELETE CASCADE,
  like_count INTEGER DEFAULT 0,
  reply_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.post_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.social_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  share_message TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(post_id, user_id)
);

-- ============================================================
-- 3. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_social_posts_author ON public.social_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_social_posts_type ON public.social_posts(post_type);
CREATE INDEX IF NOT EXISTS idx_social_posts_status ON public.social_posts(status);
CREATE INDEX IF NOT EXISTS idx_social_posts_created_at ON public.social_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_social_posts_engagement ON public.social_posts(engagement_score DESC);

CREATE INDEX IF NOT EXISTS idx_post_comments_post ON public.post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_author ON public.post_comments(author_id);
CREATE INDEX IF NOT EXISTS idx_post_comments_parent ON public.post_comments(parent_comment_id);

-- ============================================================
-- 4. FUNCTIONS
-- ============================================================

-- Update post engagement score
CREATE OR REPLACE FUNCTION public.update_post_engagement_score()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.social_posts
  SET engagement_score = (
    (like_count * 1.0) + 
    (comment_count * 2.0) + 
    (share_count * 3.0) + 
    (view_count * 0.1)
  ),
  updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Increment post like count
CREATE OR REPLACE FUNCTION public.increment_post_like_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.social_posts
  SET like_count = like_count + 1,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Decrement post like count
CREATE OR REPLACE FUNCTION public.decrement_post_like_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.social_posts
  SET like_count = GREATEST(0, like_count - 1),
      updated_at = CURRENT_TIMESTAMP
  WHERE id = OLD.post_id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Increment post comment count
CREATE OR REPLACE FUNCTION public.increment_post_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.social_posts
  SET comment_count = comment_count + 1,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Increment post share count
CREATE OR REPLACE FUNCTION public.increment_post_share_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.social_posts
  SET share_count = share_count + 1,
      updated_at = CURRENT_TIMESTAMP
  WHERE id = NEW.post_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 5. TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS trigger_update_post_engagement ON public.social_posts;
CREATE TRIGGER trigger_update_post_engagement
  AFTER UPDATE OF like_count, comment_count, share_count, view_count
  ON public.social_posts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_post_engagement_score();

DROP TRIGGER IF EXISTS trigger_increment_post_like_count ON public.post_likes;
CREATE TRIGGER trigger_increment_post_like_count
  AFTER INSERT ON public.post_likes
  FOR EACH ROW
  EXECUTE FUNCTION public.increment_post_like_count();

DROP TRIGGER IF EXISTS trigger_decrement_post_like_count ON public.post_likes;
CREATE TRIGGER trigger_decrement_post_like_count
  AFTER DELETE ON public.post_likes
  FOR EACH ROW
  EXECUTE FUNCTION public.decrement_post_like_count();

DROP TRIGGER IF EXISTS trigger_increment_post_comment_count ON public.post_comments;
CREATE TRIGGER trigger_increment_post_comment_count
  AFTER INSERT ON public.post_comments
  FOR EACH ROW
  EXECUTE FUNCTION public.increment_post_comment_count();

DROP TRIGGER IF EXISTS trigger_increment_post_share_count ON public.post_shares;
CREATE TRIGGER trigger_increment_post_share_count
  AFTER INSERT ON public.post_shares
  FOR EACH ROW
  EXECUTE FUNCTION public.increment_post_share_count();

-- ============================================================
-- 6. RLS POLICIES
-- ============================================================

ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_shares ENABLE ROW LEVEL SECURITY;

-- Social posts policies
DROP POLICY IF EXISTS "Users can view public posts" ON public.social_posts;
CREATE POLICY "Users can view public posts"
  ON public.social_posts FOR SELECT
  USING (privacy_level = 'public' OR author_id = auth.uid());

DROP POLICY IF EXISTS "Users can create their own posts" ON public.social_posts;
CREATE POLICY "Users can create their own posts"
  ON public.social_posts FOR INSERT
  WITH CHECK (author_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own posts" ON public.social_posts;
CREATE POLICY "Users can update their own posts"
  ON public.social_posts FOR UPDATE
  USING (author_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete their own posts" ON public.social_posts;
CREATE POLICY "Users can delete their own posts"
  ON public.social_posts FOR DELETE
  USING (author_id = auth.uid());

-- Post likes policies
DROP POLICY IF EXISTS "Users can view all likes" ON public.post_likes;
CREATE POLICY "Users can view all likes"
  ON public.post_likes FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can like posts" ON public.post_likes;
CREATE POLICY "Users can like posts"
  ON public.post_likes FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can unlike posts" ON public.post_likes;
CREATE POLICY "Users can unlike posts"
  ON public.post_likes FOR DELETE
  USING (user_id = auth.uid());

-- Post comments policies
DROP POLICY IF EXISTS "Users can view all comments" ON public.post_comments;
CREATE POLICY "Users can view all comments"
  ON public.post_comments FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can create comments" ON public.post_comments;
CREATE POLICY "Users can create comments"
  ON public.post_comments FOR INSERT
  WITH CHECK (author_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own comments" ON public.post_comments;
CREATE POLICY "Users can update their own comments"
  ON public.post_comments FOR UPDATE
  USING (author_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete their own comments" ON public.post_comments;
CREATE POLICY "Users can delete their own comments"
  ON public.post_comments FOR DELETE
  USING (author_id = auth.uid());

-- Post shares policies
DROP POLICY IF EXISTS "Users can view all shares" ON public.post_shares;
CREATE POLICY "Users can view all shares"
  ON public.post_shares FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can share posts" ON public.post_shares;
CREATE POLICY "Users can share posts"
  ON public.post_shares FOR INSERT
  WITH CHECK (user_id = auth.uid());
