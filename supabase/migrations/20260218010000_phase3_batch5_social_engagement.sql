-- Phase 3-4 Batch 5: Social Engagement & UX Enhancement Migration
-- Timestamp: 20260218010000
-- Description: Election comments, social reactions, notification batching, priority queuing, analytics

-- ============================================================
-- 1. ELECTION COMMENTS SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  comment_text TEXT NOT NULL,
  parent_comment_id UUID REFERENCES public.election_comments(id) ON DELETE CASCADE,
  depth_level INTEGER DEFAULT 0 CHECK (depth_level <= 3),
  upvote_count INTEGER DEFAULT 0,
  downvote_count INTEGER DEFAULT 0,
  is_edited BOOLEAN DEFAULT false,
  edited_at TIMESTAMPTZ,
  is_deleted BOOLEAN DEFAULT false,
  deleted_at TIMESTAMPTZ,
  is_flagged BOOLEAN DEFAULT false,
  flag_reason TEXT,
  flagged_at TIMESTAMPTZ,
  is_approved BOOLEAN DEFAULT true,
  approved_by UUID REFERENCES public.user_profiles(id),
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Add missing columns to existing election_comments table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'depth_level'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN depth_level INTEGER DEFAULT 0 CHECK (depth_level <= 3);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'upvote_count'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN upvote_count INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'downvote_count'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN downvote_count INTEGER DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'is_edited'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN is_edited BOOLEAN DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'edited_at'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN edited_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'is_deleted'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN is_deleted BOOLEAN DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN deleted_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'is_flagged'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN is_flagged BOOLEAN DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'flag_reason'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN flag_reason TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'flagged_at'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN flagged_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'is_approved'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN is_approved BOOLEAN DEFAULT true;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'approved_by'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN approved_by UUID REFERENCES public.user_profiles(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'election_comments'
      AND column_name = 'approved_at'
  ) THEN
    ALTER TABLE public.election_comments ADD COLUMN approved_at TIMESTAMPTZ;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_election_comments_election ON public.election_comments(election_id);
CREATE INDEX IF NOT EXISTS idx_election_comments_user ON public.election_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_election_comments_parent ON public.election_comments(parent_comment_id);
CREATE INDEX IF NOT EXISTS idx_election_comments_created ON public.election_comments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_election_comments_approved ON public.election_comments(is_approved);

-- Comment voting table
CREATE TABLE IF NOT EXISTS public.election_comment_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES public.election_comments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  vote_type TEXT NOT NULL CHECK (vote_type IN ('upvote', 'downvote')),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(comment_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_election_comment_votes_comment ON public.election_comment_votes(comment_id);
CREATE INDEX IF NOT EXISTS idx_election_comment_votes_user ON public.election_comment_votes(user_id);

-- Comment mentions table
CREATE TABLE IF NOT EXISTS public.election_comment_mentions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID NOT NULL REFERENCES public.election_comments(id) ON DELETE CASCADE,
  mentioned_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(comment_id, mentioned_user_id)
);

CREATE INDEX IF NOT EXISTS idx_election_comment_mentions_user ON public.election_comment_mentions(mentioned_user_id);

-- ============================================================
-- 2. ELECTION SOCIAL REACTIONS SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS public.election_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  reaction_type TEXT NOT NULL CHECK (reaction_type IN ('like', 'love', 'wow', 'angry', 'sad', 'celebrate')),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(election_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_election_reactions_election ON public.election_reactions(election_id);
CREATE INDEX IF NOT EXISTS idx_election_reactions_user ON public.election_reactions(user_id);
CREATE INDEX IF NOT EXISTS idx_election_reactions_type ON public.election_reactions(reaction_type);

-- Reaction aggregation table for performance
CREATE TABLE IF NOT EXISTS public.election_reaction_counts (
  election_id UUID PRIMARY KEY REFERENCES public.elections(id) ON DELETE CASCADE,
  like_count INTEGER DEFAULT 0,
  love_count INTEGER DEFAULT 0,
  wow_count INTEGER DEFAULT 0,
  angry_count INTEGER DEFAULT 0,
  sad_count INTEGER DEFAULT 0,
  celebrate_count INTEGER DEFAULT 0,
  total_reactions INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. ELECTION SETTINGS EXTENSION
-- ============================================================

-- Add comments_enabled column to elections table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'elections'
      AND column_name = 'comments_enabled'
  ) THEN
    ALTER TABLE public.elections ADD COLUMN comments_enabled BOOLEAN DEFAULT true;
  END IF;
END $$;

-- Add comment_count column to elections table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'elections'
      AND column_name = 'comment_count'
  ) THEN
    ALTER TABLE public.elections ADD COLUMN comment_count INTEGER DEFAULT 0;
  END IF;
END $$;

-- ============================================================
-- 4. NOTIFICATION BATCHING & PRIORITY SYSTEM
-- ============================================================

DROP TYPE IF EXISTS public.notification_priority CASCADE;
CREATE TYPE public.notification_priority AS ENUM (
  'critical',
  'high',
  'normal',
  'low'
);

DROP TYPE IF EXISTS public.notification_category CASCADE;
CREATE TYPE public.notification_category AS ENUM (
  'fraud_alert',
  'security',
  'new_vote',
  'winner_announcement',
  'comment',
  'reaction',
  'suggestion',
  'system'
);

DROP TYPE IF EXISTS public.notification_delivery_status CASCADE;
CREATE TYPE public.notification_delivery_status AS ENUM (
  'pending',
  'batched',
  'sent',
  'delivered',
  'failed',
  'dismissed'
);

-- Enhanced notifications table
CREATE TABLE IF NOT EXISTS public.enhanced_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  category public.notification_category NOT NULL,
  priority public.notification_priority DEFAULT 'normal',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  deep_link TEXT,
  deep_link_params JSONB,
  batch_id UUID,
  delivery_status public.notification_delivery_status DEFAULT 'pending',
  scheduled_for TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  dismissed_at TIMESTAMPTZ,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  action_buttons JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_enhanced_notifications_user ON public.enhanced_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_enhanced_notifications_priority ON public.enhanced_notifications(priority);
CREATE INDEX IF NOT EXISTS idx_enhanced_notifications_category ON public.enhanced_notifications(category);
CREATE INDEX IF NOT EXISTS idx_enhanced_notifications_status ON public.enhanced_notifications(delivery_status);
CREATE INDEX IF NOT EXISTS idx_enhanced_notifications_batch ON public.enhanced_notifications(batch_id);
CREATE INDEX IF NOT EXISTS idx_enhanced_notifications_scheduled ON public.enhanced_notifications(scheduled_for);

-- Notification batches table
CREATE TABLE IF NOT EXISTS public.notification_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  category public.notification_category NOT NULL,
  notification_count INTEGER DEFAULT 0,
  batch_title TEXT NOT NULL,
  batch_body TEXT NOT NULL,
  scheduled_for TIMESTAMPTZ NOT NULL,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notification_batches_user ON public.notification_batches(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_batches_scheduled ON public.notification_batches(scheduled_for);

-- Notification preferences table
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  user_id UUID PRIMARY KEY REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  critical_priority BOOLEAN DEFAULT true,
  high_priority BOOLEAN DEFAULT true,
  normal_priority BOOLEAN DEFAULT true,
  low_priority BOOLEAN DEFAULT false,
  enable_batching BOOLEAN DEFAULT true,
  batch_times TEXT[] DEFAULT ARRAY['09:00', '12:00', '18:00'],
  quiet_hours_start TIME DEFAULT '22:00',
  quiet_hours_end TIME DEFAULT '08:00',
  enable_quiet_hours BOOLEAN DEFAULT true,
  fraud_alert_enabled BOOLEAN DEFAULT true,
  security_enabled BOOLEAN DEFAULT true,
  new_vote_enabled BOOLEAN DEFAULT true,
  winner_announcement_enabled BOOLEAN DEFAULT true,
  comment_enabled BOOLEAN DEFAULT true,
  reaction_enabled BOOLEAN DEFAULT true,
  suggestion_enabled BOOLEAN DEFAULT false,
  system_enabled BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. GOOGLE ANALYTICS INTEGRATION
-- ============================================================

CREATE TABLE IF NOT EXISTS public.notification_analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_id UUID NOT NULL REFERENCES public.enhanced_notifications(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('received', 'clicked', 'dismissed', 'action_taken')),
  category public.notification_category NOT NULL,
  priority public.notification_priority NOT NULL,
  deep_link TEXT,
  action_button_id TEXT,
  session_id TEXT,
  ga4_event_sent BOOLEAN DEFAULT false,
  ga4_sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notification_analytics_notification ON public.notification_analytics_events(notification_id);
CREATE INDEX IF NOT EXISTS idx_notification_analytics_user ON public.notification_analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_notification_analytics_event_type ON public.notification_analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_notification_analytics_ga4 ON public.notification_analytics_events(ga4_event_sent);

-- Notification engagement metrics table
CREATE TABLE IF NOT EXISTS public.notification_engagement_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category public.notification_category NOT NULL,
  priority public.notification_priority NOT NULL,
  date DATE NOT NULL,
  total_sent INTEGER DEFAULT 0,
  total_delivered INTEGER DEFAULT 0,
  total_clicked INTEGER DEFAULT 0,
  total_dismissed INTEGER DEFAULT 0,
  open_rate NUMERIC(5,2) DEFAULT 0,
  click_through_rate NUMERIC(5,2) DEFAULT 0,
  avg_time_to_click_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(category, priority, date)
);

CREATE INDEX IF NOT EXISTS idx_notification_engagement_date ON public.notification_engagement_metrics(date DESC);
CREATE INDEX IF NOT EXISTS idx_notification_engagement_category ON public.notification_engagement_metrics(category);

-- ============================================================
-- 6. FUNCTIONS & TRIGGERS
-- ============================================================

-- Function to update comment count on election
CREATE OR REPLACE FUNCTION update_election_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.elections
    SET comment_count = comment_count + 1
    WHERE id = NEW.election_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.elections
    SET comment_count = GREATEST(comment_count - 1, 0)
    WHERE id = OLD.election_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_election_comment_count ON public.election_comments;
CREATE TRIGGER trigger_update_election_comment_count
AFTER INSERT OR DELETE ON public.election_comments
FOR EACH ROW
EXECUTE FUNCTION update_election_comment_count();

-- Function to update reaction counts
CREATE OR REPLACE FUNCTION update_election_reaction_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.election_reaction_counts (election_id)
    VALUES (NEW.election_id)
    ON CONFLICT (election_id) DO NOTHING;
    
    UPDATE public.election_reaction_counts
    SET 
      like_count = CASE WHEN NEW.reaction_type = 'like' THEN like_count + 1 ELSE like_count END,
      love_count = CASE WHEN NEW.reaction_type = 'love' THEN love_count + 1 ELSE love_count END,
      wow_count = CASE WHEN NEW.reaction_type = 'wow' THEN wow_count + 1 ELSE wow_count END,
      angry_count = CASE WHEN NEW.reaction_type = 'angry' THEN angry_count + 1 ELSE angry_count END,
      sad_count = CASE WHEN NEW.reaction_type = 'sad' THEN sad_count + 1 ELSE sad_count END,
      celebrate_count = CASE WHEN NEW.reaction_type = 'celebrate' THEN celebrate_count + 1 ELSE celebrate_count END,
      total_reactions = total_reactions + 1,
      updated_at = CURRENT_TIMESTAMP
    WHERE election_id = NEW.election_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.election_reaction_counts
    SET 
      like_count = CASE WHEN OLD.reaction_type = 'like' THEN GREATEST(like_count - 1, 0) ELSE like_count END,
      love_count = CASE WHEN OLD.reaction_type = 'love' THEN GREATEST(love_count - 1, 0) ELSE love_count END,
      wow_count = CASE WHEN OLD.reaction_type = 'wow' THEN GREATEST(wow_count - 1, 0) ELSE wow_count END,
      angry_count = CASE WHEN OLD.reaction_type = 'angry' THEN GREATEST(angry_count - 1, 0) ELSE angry_count END,
      sad_count = CASE WHEN OLD.reaction_type = 'sad' THEN GREATEST(sad_count - 1, 0) ELSE sad_count END,
      celebrate_count = CASE WHEN OLD.reaction_type = 'celebrate' THEN GREATEST(celebrate_count - 1, 0) ELSE celebrate_count END,
      total_reactions = GREATEST(total_reactions - 1, 0),
      updated_at = CURRENT_TIMESTAMP
    WHERE election_id = OLD.election_id;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.election_reaction_counts
    SET 
      like_count = like_count + CASE WHEN NEW.reaction_type = 'like' THEN 1 ELSE 0 END - CASE WHEN OLD.reaction_type = 'like' THEN 1 ELSE 0 END,
      love_count = love_count + CASE WHEN NEW.reaction_type = 'love' THEN 1 ELSE 0 END - CASE WHEN OLD.reaction_type = 'love' THEN 1 ELSE 0 END,
      wow_count = wow_count + CASE WHEN NEW.reaction_type = 'wow' THEN 1 ELSE 0 END - CASE WHEN OLD.reaction_type = 'wow' THEN 1 ELSE 0 END,
      angry_count = angry_count + CASE WHEN NEW.reaction_type = 'angry' THEN 1 ELSE 0 END - CASE WHEN OLD.reaction_type = 'angry' THEN 1 ELSE 0 END,
      sad_count = sad_count + CASE WHEN NEW.reaction_type = 'sad' THEN 1 ELSE 0 END - CASE WHEN OLD.reaction_type = 'sad' THEN 1 ELSE 0 END,
      celebrate_count = celebrate_count + CASE WHEN NEW.reaction_type = 'celebrate' THEN 1 ELSE 0 END - CASE WHEN OLD.reaction_type = 'celebrate' THEN 1 ELSE 0 END,
      updated_at = CURRENT_TIMESTAMP
    WHERE election_id = NEW.election_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_election_reaction_counts ON public.election_reactions;
CREATE TRIGGER trigger_update_election_reaction_counts
AFTER INSERT OR UPDATE OR DELETE ON public.election_reactions
FOR EACH ROW
EXECUTE FUNCTION update_election_reaction_counts();

-- Function to track notification analytics
CREATE OR REPLACE FUNCTION track_notification_event(
  p_notification_id UUID,
  p_event_type TEXT
)
RETURNS VOID AS $$
DECLARE
  v_notification RECORD;
BEGIN
  SELECT user_id, category, priority, deep_link
  INTO v_notification
  FROM public.enhanced_notifications
  WHERE id = p_notification_id;
  
  IF FOUND THEN
    INSERT INTO public.notification_analytics_events (
      notification_id,
      user_id,
      event_type,
      category,
      priority,
      deep_link
    ) VALUES (
      p_notification_id,
      v_notification.user_id,
      p_event_type,
      v_notification.category,
      v_notification.priority,
      v_notification.deep_link
    );
    
    -- Update notification status
    IF p_event_type = 'clicked' THEN
      UPDATE public.enhanced_notifications
      SET clicked_at = CURRENT_TIMESTAMP, is_read = true, read_at = CURRENT_TIMESTAMP
      WHERE id = p_notification_id;
    ELSIF p_event_type = 'dismissed' THEN
      UPDATE public.enhanced_notifications
      SET dismissed_at = CURRENT_TIMESTAMP, delivery_status = 'dismissed'
      WHERE id = p_notification_id;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- 7. ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.election_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_comment_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_comment_mentions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_reaction_counts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enhanced_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_engagement_metrics ENABLE ROW LEVEL SECURITY;

-- Election comments policies
DROP POLICY IF EXISTS "Users can view approved comments" ON public.election_comments;
CREATE POLICY "Users can view approved comments" ON public.election_comments
  FOR SELECT USING (is_approved = true AND is_deleted = false);

DROP POLICY IF EXISTS "Users can create comments" ON public.election_comments;
CREATE POLICY "Users can create comments" ON public.election_comments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own comments" ON public.election_comments;
CREATE POLICY "Users can update own comments" ON public.election_comments
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Creators can moderate comments" ON public.election_comments;
CREATE POLICY "Creators can moderate comments" ON public.election_comments
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = election_comments.election_id
      AND elections.created_by = auth.uid()
    )
  );

-- Comment votes policies
DROP POLICY IF EXISTS "Users can view comment votes" ON public.election_comment_votes;
CREATE POLICY "Users can view comment votes" ON public.election_comment_votes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own comment votes" ON public.election_comment_votes;
CREATE POLICY "Users can manage own comment votes" ON public.election_comment_votes
  FOR ALL USING (auth.uid() = user_id);

-- Reactions policies
DROP POLICY IF EXISTS "Users can view reactions" ON public.election_reactions;
CREATE POLICY "Users can view reactions" ON public.election_reactions
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage own reactions" ON public.election_reactions;
CREATE POLICY "Users can manage own reactions" ON public.election_reactions
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view reaction counts" ON public.election_reaction_counts;
CREATE POLICY "Users can view reaction counts" ON public.election_reaction_counts
  FOR SELECT USING (true);

-- Notifications policies
DROP POLICY IF EXISTS "Users can view own notifications" ON public.enhanced_notifications;
CREATE POLICY "Users can view own notifications" ON public.enhanced_notifications
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.enhanced_notifications;
CREATE POLICY "Users can update own notifications" ON public.enhanced_notifications
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own notification preferences" ON public.notification_preferences;
CREATE POLICY "Users can view own notification preferences" ON public.notification_preferences
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own notification preferences" ON public.notification_preferences;
CREATE POLICY "Users can manage own notification preferences" ON public.notification_preferences
  FOR ALL USING (auth.uid() = user_id);

-- Analytics policies
DROP POLICY IF EXISTS "Users can view own analytics" ON public.notification_analytics_events;
CREATE POLICY "Users can view own analytics" ON public.notification_analytics_events
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view engagement metrics" ON public.notification_engagement_metrics;
CREATE POLICY "Users can view engagement metrics" ON public.notification_engagement_metrics
  FOR SELECT USING (true);

-- ============================================================
-- 8. INITIAL DATA
-- ============================================================

-- Create default notification preferences for existing users
INSERT INTO public.notification_preferences (user_id)
SELECT id FROM public.user_profiles
ON CONFLICT (user_id) DO NOTHING;

COMMIT;