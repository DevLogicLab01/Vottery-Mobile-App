-- Direct Messaging Enhancements Migration
-- Timestamp: 20260208010000
-- Description: Typing indicators, user presence, media sharing, offline queue support

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.user_presence_status CASCADE;
CREATE TYPE public.user_presence_status AS ENUM (
  'online',
  'offline',
  'away'
);

-- ============================================================
-- 2. USER PRESENCE TRACKING
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_presence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  status public.user_presence_status NOT NULL DEFAULT 'offline',
  last_seen_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX idx_user_presence_user ON public.user_presence(user_id);
CREATE INDEX idx_user_presence_status ON public.user_presence(status);

-- ============================================================
-- 3. TYPING INDICATORS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.typing_indicators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT true,
  started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(conversation_id, user_id)
);

CREATE INDEX idx_typing_indicators_conversation ON public.typing_indicators(conversation_id);
CREATE INDEX idx_typing_indicators_started ON public.typing_indicators(started_at);

-- ============================================================
-- 4. OFFLINE MESSAGE QUEUE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.offline_message_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  message_content TEXT NOT NULL,
  message_type public.message_type DEFAULT 'text',
  media_url TEXT,
  retry_count INTEGER DEFAULT 0,
  queued_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  last_retry_at TIMESTAMPTZ
);

CREATE INDEX idx_offline_queue_user ON public.offline_message_queue(user_id);
CREATE INDEX idx_offline_queue_conversation ON public.offline_message_queue(conversation_id);
CREATE INDEX idx_offline_queue_queued ON public.offline_message_queue(queued_at);

-- ============================================================
-- 5. CONVERSATION METADATA
-- ============================================================

ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT false;
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS archived_by UUID[] DEFAULT ARRAY[]::UUID[];
ALTER TABLE public.conversations ADD COLUMN IF NOT EXISTS conversation_name TEXT;

CREATE INDEX IF NOT EXISTS idx_conversations_archived ON public.conversations(is_archived);

-- ============================================================
-- 6. FUNCTIONS
-- ============================================================

-- Update user presence
CREATE OR REPLACE FUNCTION public.update_user_presence(
  p_user_id UUID,
  p_status public.user_presence_status
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.user_presence (user_id, status, last_seen_at, updated_at)
  VALUES (p_user_id, p_status, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  ON CONFLICT (user_id) DO UPDATE
  SET status = EXCLUDED.status,
      last_seen_at = CURRENT_TIMESTAMP,
      updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set typing indicator
CREATE OR REPLACE FUNCTION public.set_typing_indicator(
  p_conversation_id UUID,
  p_user_id UUID,
  p_is_typing BOOLEAN
)
RETURNS VOID AS $$
BEGIN
  IF p_is_typing THEN
    INSERT INTO public.typing_indicators (conversation_id, user_id, is_typing, started_at)
    VALUES (p_conversation_id, p_user_id, true, CURRENT_TIMESTAMP)
    ON CONFLICT (conversation_id, user_id) DO UPDATE
    SET is_typing = true,
        started_at = CURRENT_TIMESTAMP;
  ELSE
    DELETE FROM public.typing_indicators
    WHERE conversation_id = p_conversation_id AND user_id = p_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Clean old typing indicators (older than 10 seconds)
CREATE OR REPLACE FUNCTION public.clean_old_typing_indicators()
RETURNS VOID AS $$
BEGIN
  DELETE FROM public.typing_indicators
  WHERE started_at < (CURRENT_TIMESTAMP - INTERVAL '10 seconds');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get unread message count for conversation
CREATE OR REPLACE FUNCTION public.get_unread_count(
  p_conversation_id UUID,
  p_user_id UUID
)
RETURNS INTEGER AS $$
DECLARE
  unread_count INTEGER;
BEGIN
  SELECT COUNT(*)
  INTO unread_count
  FROM public.messages
  WHERE conversation_id = p_conversation_id
    AND sender_id != p_user_id
    AND NOT (p_user_id = ANY(read_by));
  
  RETURN unread_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 7. RLS POLICIES
-- ============================================================

ALTER TABLE public.user_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offline_message_queue ENABLE ROW LEVEL SECURITY;

-- User presence policies
CREATE POLICY "Users can view all presence"
  ON public.user_presence FOR SELECT
  USING (true);

CREATE POLICY "Users can update own presence"
  ON public.user_presence FOR ALL
  USING (auth.uid() = user_id);

-- Typing indicators policies
CREATE POLICY "Users can view typing in their conversations"
  ON public.typing_indicators FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.conversations
      WHERE id = conversation_id
        AND auth.uid() = ANY(participant_ids)
    )
  );

CREATE POLICY "Users can manage own typing indicators"
  ON public.typing_indicators FOR ALL
  USING (auth.uid() = user_id);

-- Offline queue policies
CREATE POLICY "Users can manage own offline queue"
  ON public.offline_message_queue FOR ALL
  USING (auth.uid() = user_id);

-- ============================================================
-- 8. TRIGGERS
-- ============================================================

-- Auto-clean typing indicators
CREATE OR REPLACE FUNCTION public.trigger_clean_typing_indicators()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM public.clean_old_typing_indicators();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS auto_clean_typing_indicators ON public.typing_indicators;
CREATE TRIGGER auto_clean_typing_indicators
  AFTER INSERT ON public.typing_indicators
  EXECUTE FUNCTION public.trigger_clean_typing_indicators();