-- Phase 2: Social Features & Predictions Migration
-- Timestamp: 20260205002000
-- Description: Friend connections, Jolts video content, prediction pools, messaging, leaderboards

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.connection_status CASCADE;
CREATE TYPE public.connection_status AS ENUM (
  'pending',
  'accepted',
  'blocked'
);

DROP TYPE IF EXISTS public.jolt_status CASCADE;
CREATE TYPE public.jolt_status AS ENUM (
  'draft',
  'published',
  'archived',
  'flagged'
);

DROP TYPE IF EXISTS public.prediction_status CASCADE;
CREATE TYPE public.prediction_status AS ENUM (
  'open',
  'closed',
  'resolved',
  'cancelled'
);

DROP TYPE IF EXISTS public.message_type CASCADE;
CREATE TYPE public.message_type AS ENUM (
  'text',
  'image',
  'video',
  'system'
);

-- ============================================================
-- 2. SOCIAL CONNECTIONS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  status public.connection_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(requester_id, addressee_id),
  CHECK (requester_id != addressee_id)
);

CREATE TABLE IF NOT EXISTS public.user_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  topic TEXT,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  member_count INTEGER DEFAULT 0,
  is_public BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.user_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(group_id, user_id)
);

-- ============================================================
-- 3. JOLTS VIDEO CONTENT TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.jolts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  duration_seconds INTEGER,
  election_id UUID REFERENCES public.elections(id) ON DELETE SET NULL,
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  share_count INTEGER DEFAULT 0,
  status public.jolt_status DEFAULT 'published',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.jolt_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jolt_id UUID NOT NULL REFERENCES public.jolts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  interaction_type TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(jolt_id, user_id, interaction_type)
);

CREATE TABLE IF NOT EXISTS public.jolt_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  jolt_id UUID NOT NULL REFERENCES public.jolts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  comment_text TEXT NOT NULL,
  parent_comment_id UUID REFERENCES public.jolt_comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 4. PREDICTION POOLS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.prediction_pools (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  entry_fee_vp INTEGER NOT NULL DEFAULT 100,
  prize_pool_vp INTEGER DEFAULT 0,
  participant_count INTEGER DEFAULT 0,
  status public.prediction_status DEFAULT 'open',
  resolution_date TIMESTAMPTZ,
  actual_outcome JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pool_id UUID NOT NULL REFERENCES public.prediction_pools(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  predicted_outcome JSONB NOT NULL,
  confidence_level NUMERIC(3,2) NOT NULL CHECK (confidence_level >= 0 AND confidence_level <= 1),
  brier_score NUMERIC(5,4),
  vp_reward INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(pool_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.predictor_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  elo_rating INTEGER DEFAULT 1500,
  total_predictions INTEGER DEFAULT 0,
  correct_predictions INTEGER DEFAULT 0,
  average_brier_score NUMERIC(5,4),
  rank_position INTEGER,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

-- ============================================================
-- 5. REAL-TIME MESSAGING TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_ids UUID[] NOT NULL,
  last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  message_type public.message_type DEFAULT 'text',
  content TEXT NOT NULL,
  media_url TEXT,
  vp_reward_given BOOLEAN DEFAULT false,
  read_by UUID[] DEFAULT ARRAY[]::UUID[],
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(message_id, user_id, emoji)
);

-- ============================================================
-- 6. SOCIAL LEADERBOARDS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.leaderboards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  leaderboard_type TEXT NOT NULL,
  scope TEXT NOT NULL,
  time_period TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  score INTEGER NOT NULL,
  rank_position INTEGER,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(leaderboard_type, scope, time_period, user_id)
);

CREATE TABLE IF NOT EXISTS public.social_feed_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL,
  content_id UUID NOT NULL,
  relevance_score NUMERIC(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 7. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_user_connections_requester ON public.user_connections(requester_id);
CREATE INDEX IF NOT EXISTS idx_user_connections_addressee ON public.user_connections(addressee_id);
CREATE INDEX IF NOT EXISTS idx_user_connections_status ON public.user_connections(status);

CREATE INDEX IF NOT EXISTS idx_jolts_creator ON public.jolts(creator_id);
CREATE INDEX IF NOT EXISTS idx_jolts_status ON public.jolts(status);
CREATE INDEX IF NOT EXISTS idx_jolts_created_at ON public.jolts(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_prediction_pools_election ON public.prediction_pools(election_id);
CREATE INDEX IF NOT EXISTS idx_prediction_pools_status ON public.prediction_pools(status);

CREATE INDEX IF NOT EXISTS idx_predictions_pool ON public.predictions(pool_id);
CREATE INDEX IF NOT EXISTS idx_predictions_user ON public.predictions(user_id);

CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_leaderboards_type_scope ON public.leaderboards(leaderboard_type, scope, time_period);
CREATE INDEX IF NOT EXISTS idx_leaderboards_rank ON public.leaderboards(rank_position);

-- ============================================================
-- 8. FUNCTIONS
-- ============================================================

-- Calculate Brier Score
CREATE OR REPLACE FUNCTION public.calculate_brier_score(
  predicted_probability NUMERIC,
  actual_outcome INTEGER
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN POWER(predicted_probability - actual_outcome, 2);
END;
$$;

-- Update predictor rating
CREATE OR REPLACE FUNCTION public.update_predictor_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  total_preds INTEGER;
  correct_preds INTEGER;
  avg_brier NUMERIC;
BEGIN
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE brier_score <= 0.25),
    AVG(brier_score)
  INTO total_preds, correct_preds, avg_brier
  FROM public.predictions
  WHERE user_id = NEW.user_id AND brier_score IS NOT NULL;
  
  INSERT INTO public.predictor_ratings (user_id, total_predictions, correct_predictions, average_brier_score)
  VALUES (NEW.user_id, total_preds, correct_preds, avg_brier)
  ON CONFLICT (user_id) DO UPDATE SET
    total_predictions = total_preds,
    correct_predictions = correct_preds,
    average_brier_score = avg_brier,
    updated_at = CURRENT_TIMESTAMP;
  
  RETURN NEW;
END;
$$;

-- Award VP for messaging engagement
CREATE OR REPLACE FUNCTION public.award_messaging_vp()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  current_balance INTEGER;
BEGIN
  IF NOT NEW.vp_reward_given THEN
    SELECT available_vp INTO current_balance
    FROM public.vp_balance
    WHERE user_id = NEW.sender_id;
    
    INSERT INTO public.vp_transactions (
      user_id,
      transaction_type,
      amount,
      balance_before,
      balance_after,
      description,
      reference_id,
      reference_type
    ) VALUES (
      NEW.sender_id,
      'social_interaction',
      5,
      current_balance,
      current_balance + 5,
      'Messaging engagement reward',
      NEW.id,
      'message'
    );
    
    UPDATE public.messages SET vp_reward_given = true WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- ============================================================
-- 9. TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS trigger_update_predictor_rating ON public.predictions;
CREATE TRIGGER trigger_update_predictor_rating
AFTER INSERT OR UPDATE OF brier_score ON public.predictions
FOR EACH ROW
WHEN (NEW.brier_score IS NOT NULL)
EXECUTE FUNCTION public.update_predictor_rating();

DROP TRIGGER IF EXISTS trigger_award_messaging_vp ON public.messages;
CREATE TRIGGER trigger_award_messaging_vp
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.award_messaging_vp();

-- ============================================================
-- 10. RLS POLICIES
-- ============================================================

ALTER TABLE public.user_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jolts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prediction_pools ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboards ENABLE ROW LEVEL SECURITY;

-- User Connections Policies
DROP POLICY IF EXISTS "users_view_own_connections" ON public.user_connections;
CREATE POLICY "users_view_own_connections"
ON public.user_connections FOR SELECT
USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

DROP POLICY IF EXISTS "users_create_connections" ON public.user_connections;
CREATE POLICY "users_create_connections"
ON public.user_connections FOR INSERT
WITH CHECK (auth.uid() = requester_id);

-- Jolts Policies
DROP POLICY IF EXISTS "users_view_published_jolts" ON public.jolts;
CREATE POLICY "users_view_published_jolts"
ON public.jolts FOR SELECT
USING (status = 'published' OR creator_id = auth.uid());

DROP POLICY IF EXISTS "users_create_jolts" ON public.jolts;
CREATE POLICY "users_create_jolts"
ON public.jolts FOR INSERT
WITH CHECK (auth.uid() = creator_id);

-- Prediction Pools Policies
DROP POLICY IF EXISTS "users_view_prediction_pools" ON public.prediction_pools;
CREATE POLICY "users_view_prediction_pools"
ON public.prediction_pools FOR SELECT
USING (true);

DROP POLICY IF EXISTS "users_view_own_predictions" ON public.predictions;
CREATE POLICY "users_view_own_predictions"
ON public.predictions FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_create_predictions" ON public.predictions;
CREATE POLICY "users_create_predictions"
ON public.predictions FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Messages Policies
DROP POLICY IF EXISTS "users_view_own_messages" ON public.messages;
CREATE POLICY "users_view_own_messages"
ON public.messages FOR SELECT
USING (
  auth.uid() = sender_id OR
  auth.uid() = ANY(SELECT unnest(participant_ids) FROM public.conversations WHERE id = conversation_id)
);

DROP POLICY IF EXISTS "users_send_messages" ON public.messages;
CREATE POLICY "users_send_messages"
ON public.messages FOR INSERT
WITH CHECK (auth.uid() = sender_id);

-- Leaderboards Policies
DROP POLICY IF EXISTS "users_view_leaderboards" ON public.leaderboards;
CREATE POLICY "users_view_leaderboards"
ON public.leaderboards FOR SELECT
USING (true);

-- ============================================================
-- 11. SEED DATA
-- ============================================================

-- Insert default prediction pools for existing elections
INSERT INTO public.prediction_pools (election_id, title, description, entry_fee_vp, status)
SELECT 
  id,
  title || ' - Prediction Pool',
  'Predict the outcome and win VP rewards',
  100,
  'open'
FROM public.elections
WHERE status = 'active'
ON CONFLICT DO NOTHING;