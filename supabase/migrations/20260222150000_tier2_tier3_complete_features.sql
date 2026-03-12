-- TIER 2 & TIER 3 Complete Features Migration
-- User Feedback Portal, Direct Messaging System, Dynamic CPE Pricing Engine, Hive Offline-First Architecture

-- =====================================================
-- TIER 2 FEATURE 4: USER FEEDBACK PORTAL
-- =====================================================

-- User feedback votes table (separate from feature_votes)
CREATE TABLE IF NOT EXISTS user_feedback_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feedback_id UUID NOT NULL REFERENCES feature_requests(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(feedback_id, user_id)
);

-- Feedback comments table
CREATE TABLE IF NOT EXISTS feedback_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feedback_id UUID NOT NULL REFERENCES feature_requests(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_comment_id UUID REFERENCES feedback_comments(id) ON DELETE CASCADE,
  comment_text TEXT NOT NULL,
  helpful_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feedback status history table
CREATE TABLE IF NOT EXISTS feedback_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feedback_id UUID NOT NULL REFERENCES feature_requests(id) ON DELETE CASCADE,
  old_status TEXT,
  new_status TEXT NOT NULL,
  changed_by UUID REFERENCES auth.users(id),
  change_reason TEXT,
  estimated_completion_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feedback attachments table
CREATE TABLE IF NOT EXISTS feedback_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feedback_id UUID NOT NULL REFERENCES feature_requests(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size INT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns to feature_requests
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feature_requests' AND column_name = 'request_type') THEN
    ALTER TABLE feature_requests ADD COLUMN request_type TEXT DEFAULT 'feature_request';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feature_requests' AND column_name = 'priority') THEN
    ALTER TABLE feature_requests ADD COLUMN priority TEXT DEFAULT 'medium';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feature_requests' AND column_name = 'problem_statement') THEN
    ALTER TABLE feature_requests ADD COLUMN problem_statement TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feature_requests' AND column_name = 'proposed_solution') THEN
    ALTER TABLE feature_requests ADD COLUMN proposed_solution TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feature_requests' AND column_name = 'use_case') THEN
    ALTER TABLE feature_requests ADD COLUMN use_case TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feature_requests' AND column_name = 'vote_count') THEN
    ALTER TABLE feature_requests ADD COLUMN vote_count INT DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feature_requests' AND column_name = 'view_count') THEN
    ALTER TABLE feature_requests ADD COLUMN view_count INT DEFAULT 0;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feature_requests' AND column_name = 'sentiment_score') THEN
    ALTER TABLE feature_requests ADD COLUMN sentiment_score DECIMAL(3,2);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'feature_requests' AND column_name = 'urgency_classification') THEN
    ALTER TABLE feature_requests ADD COLUMN urgency_classification TEXT;
  END IF;
END $$;

-- Trending score calculation function
CREATE OR REPLACE FUNCTION calculate_trending_score(feedback_id UUID)
RETURNS DECIMAL AS $$
DECLARE
  recent_votes INT;
  recent_comments INT;
  days_old DECIMAL;
  trending_score DECIMAL;
BEGIN
  SELECT COUNT(*) INTO recent_votes
  FROM user_feedback_votes
  WHERE feedback_id = calculate_trending_score.feedback_id
    AND created_at > NOW() - INTERVAL '7 days';
  
  SELECT COUNT(*) INTO recent_comments
  FROM feedback_comments
  WHERE feedback_id = calculate_trending_score.feedback_id
    AND created_at > NOW() - INTERVAL '7 days';
  
  SELECT EXTRACT(DAY FROM NOW() - created_at) INTO days_old
  FROM feature_requests
  WHERE id = calculate_trending_score.feedback_id;
  
  trending_score := (recent_votes * 10 + recent_comments * 5) / POWER(days_old + 2, 1.5);
  
  RETURN trending_score;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TIER 2 FEATURE 5: DIRECT MESSAGING SYSTEM
-- =====================================================

-- Message reactions table
CREATE TABLE IF NOT EXISTS message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji_code TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji_code)
);

-- Unread messages tracking
CREATE TABLE IF NOT EXISTS unread_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  message_id UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns to messages table
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'reply_to_id') THEN
    ALTER TABLE messages ADD COLUMN reply_to_id UUID REFERENCES messages(id);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'edited_at') THEN
    ALTER TABLE messages ADD COLUMN edited_at TIMESTAMPTZ;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'messages' AND column_name = 'deleted_at') THEN
    ALTER TABLE messages ADD COLUMN deleted_at TIMESTAMPTZ;
  END IF;
END $$;

-- =====================================================
-- TIER 3 FEATURE 1: DYNAMIC CPE PRICING ENGINE
-- =====================================================

-- CPE price history table
CREATE TABLE IF NOT EXISTS cpe_price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id INT NOT NULL,
  zone_name TEXT NOT NULL,
  old_price DECIMAL(10,2),
  new_price DECIMAL(10,2) NOT NULL,
  change_percentage DECIMAL(5,2),
  demand_score DECIMAL(5,4),
  quality_score DECIMAL(5,2),
  change_reason TEXT,
  ai_recommendation TEXT,
  adjusted_at TIMESTAMPTZ DEFAULT NOW(),
  adjusted_by UUID REFERENCES auth.users(id)
);

-- Ad engagement metrics table
CREATE TABLE IF NOT EXISTS ad_engagement_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id INT NOT NULL,
  campaign_id UUID,
  impressions INT DEFAULT 0,
  clicks INT DEFAULT 0,
  engagements INT DEFAULT 0,
  completions INT DEFAULT 0,
  total_spend DECIMAL(10,2) DEFAULT 0,
  engagement_rate DECIMAL(5,4),
  click_through_rate DECIMAL(5,4),
  completion_rate DECIMAL(5,4),
  average_time_spent INT,
  ad_requests INT DEFAULT 0,
  available_slots INT DEFAULT 100,
  demand_score DECIMAL(5,4),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- User activity logs for audience quality scoring
CREATE TABLE IF NOT EXISTS user_activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  zone_id INT,
  session_duration INT,
  feature_usage_count INT DEFAULT 0,
  content_created_count INT DEFAULT 0,
  engagement_frequency DECIMAL(5,4),
  vp_balance DECIMAL(10,2) DEFAULT 0,
  account_age_days INT,
  quality_score DECIMAL(5,2),
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- Campaign performance history
CREATE TABLE IF NOT EXISTS campaign_performance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL,
  zone_id INT NOT NULL,
  total_engagements INT DEFAULT 0,
  total_spend DECIMAL(10,2) DEFAULT 0,
  average_engagement_per_dollar DECIMAL(10,4),
  roi DECIMAL(10,4),
  price_elasticity DECIMAL(5,4),
  performance_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- TIER 3 FEATURE 2: HIVE OFFLINE-FIRST ARCHITECTURE
-- =====================================================

-- Sync conflicts table
CREATE TABLE IF NOT EXISTS sync_conflicts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  client_value JSONB NOT NULL,
  server_value JSONB NOT NULL,
  ancestor_value JSONB,
  resolution_strategy TEXT,
  resolved_value JSONB,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sync queue tracking
CREATE TABLE IF NOT EXISTS sync_queue_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  data JSONB NOT NULL,
  priority INT DEFAULT 5,
  retry_count INT DEFAULT 0,
  synced BOOLEAN DEFAULT FALSE,
  synced_at TIMESTAMPTZ,
  queued_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add missing columns to existing sync tables if they exist
DO $$ 
BEGIN
  -- Check if sync_conflicts exists and add entity_type if missing
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sync_conflicts') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sync_conflicts' AND column_name = 'entity_type') THEN
      ALTER TABLE sync_conflicts ADD COLUMN entity_type TEXT NOT NULL DEFAULT 'unknown';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sync_conflicts' AND column_name = 'entity_id') THEN
      ALTER TABLE sync_conflicts ADD COLUMN entity_id TEXT NOT NULL DEFAULT '';
    END IF;
  END IF;
  
  -- Check if sync_queue_tracking exists and add entity_type if missing
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sync_queue_tracking') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sync_queue_tracking' AND column_name = 'entity_type') THEN
      ALTER TABLE sync_queue_tracking ADD COLUMN entity_type TEXT NOT NULL DEFAULT 'unknown';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sync_queue_tracking' AND column_name = 'entity_id') THEN
      ALTER TABLE sync_queue_tracking ADD COLUMN entity_id TEXT NOT NULL DEFAULT '';
    END IF;
  END IF;
END $$;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_user_feedback_votes_feedback_id ON user_feedback_votes(feedback_id);
CREATE INDEX IF NOT EXISTS idx_user_feedback_votes_user_id ON user_feedback_votes(user_id);
CREATE INDEX IF NOT EXISTS idx_feedback_comments_feedback_id ON feedback_comments(feedback_id);
CREATE INDEX IF NOT EXISTS idx_feedback_comments_parent_id ON feedback_comments(parent_comment_id);
CREATE INDEX IF NOT EXISTS idx_feedback_status_history_feedback_id ON feedback_status_history(feedback_id);
CREATE INDEX IF NOT EXISTS idx_message_reactions_message_id ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_unread_messages_user_conversation ON unread_messages(user_id, conversation_id);
CREATE INDEX IF NOT EXISTS idx_cpe_price_history_zone_id ON cpe_price_history(zone_id);
CREATE INDEX IF NOT EXISTS idx_cpe_price_history_adjusted_at ON cpe_price_history(adjusted_at DESC);
CREATE INDEX IF NOT EXISTS idx_ad_engagement_metrics_zone_id ON ad_engagement_metrics(zone_id);
CREATE INDEX IF NOT EXISTS idx_ad_engagement_metrics_recorded_at ON ad_engagement_metrics(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_user_id ON user_activity_logs(user_id);

-- Only create index if entity_type column exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'sync_conflicts' AND column_name = 'entity_type') THEN
    CREATE INDEX IF NOT EXISTS idx_sync_conflicts_user_entity ON sync_conflicts(user_id, entity_type, entity_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sync_queue_user_synced ON sync_queue_tracking(user_id, synced);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- User feedback votes policies
ALTER TABLE user_feedback_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all feedback votes" ON user_feedback_votes;
CREATE POLICY "Users can view all feedback votes"
  ON user_feedback_votes FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Users can insert their own votes" ON user_feedback_votes;
CREATE POLICY "Users can insert their own votes"
  ON user_feedback_votes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own votes" ON user_feedback_votes;
CREATE POLICY "Users can delete their own votes"
  ON user_feedback_votes FOR DELETE
  USING (auth.uid() = user_id);

-- Feedback comments policies
ALTER TABLE feedback_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all comments" ON feedback_comments;
CREATE POLICY "Users can view all comments"
  ON feedback_comments FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert comments" ON feedback_comments;
CREATE POLICY "Authenticated users can insert comments"
  ON feedback_comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own comments" ON feedback_comments;
CREATE POLICY "Users can update their own comments"
  ON feedback_comments FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own comments" ON feedback_comments;
CREATE POLICY "Users can delete their own comments"
  ON feedback_comments FOR DELETE
  USING (auth.uid() = user_id);

-- Message reactions policies
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view reactions on their messages" ON message_reactions;
CREATE POLICY "Users can view reactions on their messages"
  ON message_reactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM messages m
      JOIN conversations c ON m.conversation_id = c.id
      WHERE m.id = message_reactions.message_id
        AND auth.uid() = ANY(c.participant_ids)
    )
  );

DROP POLICY IF EXISTS "Users can add reactions" ON message_reactions;
CREATE POLICY "Users can add reactions"
  ON message_reactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can remove their reactions" ON message_reactions;
CREATE POLICY "Users can remove their reactions"
  ON message_reactions FOR DELETE
  USING (auth.uid() = user_id);

-- CPE price history policies
ALTER TABLE cpe_price_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view price history" ON cpe_price_history;
CREATE POLICY "Admins can view price history"
  ON cpe_price_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "Admins can insert price changes" ON cpe_price_history;
CREATE POLICY "Admins can insert price changes"
  ON cpe_price_history FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
        AND role IN ('admin', 'super_admin')
    )
  );

-- Ad engagement metrics policies
ALTER TABLE ad_engagement_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins and advertisers can view metrics" ON ad_engagement_metrics;
CREATE POLICY "Admins and advertisers can view metrics"
  ON ad_engagement_metrics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
        AND role IN ('admin', 'super_admin', 'advertiser')
    )
  );

-- Sync conflicts policies
ALTER TABLE sync_conflicts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own conflicts" ON sync_conflicts;
CREATE POLICY "Users can view their own conflicts"
  ON sync_conflicts FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own conflicts" ON sync_conflicts;
CREATE POLICY "Users can update their own conflicts"
  ON sync_conflicts FOR UPDATE
  USING (auth.uid() = user_id);

-- Sync queue tracking policies
ALTER TABLE sync_queue_tracking ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own sync queue" ON sync_queue_tracking;
CREATE POLICY "Users can view their own sync queue"
  ON sync_queue_tracking FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert to their sync queue" ON sync_queue_tracking;
CREATE POLICY "Users can insert to their sync queue"
  ON sync_queue_tracking FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their sync queue" ON sync_queue_tracking;
CREATE POLICY "Users can update their sync queue"
  ON sync_queue_tracking FOR UPDATE
  USING (auth.uid() = user_id);