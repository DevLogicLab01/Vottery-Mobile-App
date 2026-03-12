-- Unified Carousel Operations Hub + Claude Carousel Optimization Coach
-- Implements comprehensive monitoring center and AI-powered creator coaching

-- =====================================================
-- 1. TYPES
-- =====================================================

DROP TYPE IF EXISTS public.carousel_system_name CASCADE;
CREATE TYPE public.carousel_system_name AS ENUM (
  'openai_ranking',
  'monitoring_hub',
  'fraud_detection',
  'feed_orchestration',
  'roi_analytics',
  'creator_studio',
  'marketplace',
  'claude_agent',
  'community_hub',
  'forecasting',
  'perplexity_intel',
  'health_scaling'
);

DROP TYPE IF EXISTS public.system_health_status CASCADE;
CREATE TYPE public.system_health_status AS ENUM ('healthy', 'degraded', 'critical', 'offline');

DROP TYPE IF EXISTS public.incident_severity CASCADE;
CREATE TYPE public.incident_severity AS ENUM ('critical', 'high', 'medium', 'low');

DROP TYPE IF EXISTS public.incident_status CASCADE;
CREATE TYPE public.incident_status AS ENUM ('new', 'acknowledged', 'investigating', 'resolved', 'false_positive');

DROP TYPE IF EXISTS public.anomaly_severity CASCADE;
CREATE TYPE public.anomaly_severity AS ENUM ('critical', 'high', 'medium', 'low');

DROP TYPE IF EXISTS public.action_result CASCADE;
CREATE TYPE public.action_result AS ENUM ('success', 'failed', 'partial');

DROP TYPE IF EXISTS public.coaching_action_status CASCADE;
CREATE TYPE public.coaching_action_status AS ENUM ('pending', 'in_progress', 'completed', 'skipped');

-- =====================================================
-- 2. UNIFIED OPERATIONS METRICS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.unified_ops_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_system public.carousel_system_name NOT NULL,
  metric_category VARCHAR(50) NOT NULL,
  metric_name VARCHAR(100) NOT NULL,
  metric_value DECIMAL(12,4) NOT NULL,
  health_score INTEGER CHECK (health_score >= 0 AND health_score <= 100),
  status public.system_health_status DEFAULT 'healthy'::public.system_health_status,
  recorded_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_ops_metrics_system ON public.unified_ops_metrics(source_system, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_ops_metrics_status ON public.unified_ops_metrics(status, recorded_at DESC);

-- =====================================================
-- 3. UNIFIED INCIDENTS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.unified_incidents (
  incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_system public.carousel_system_name NOT NULL,
  incident_type VARCHAR(100) NOT NULL,
  severity public.incident_severity NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  affected_components JSONB DEFAULT '[]'::jsonb,
  impact_assessment TEXT,
  status public.incident_status DEFAULT 'new'::public.incident_status,
  detected_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  acknowledged_by UUID REFERENCES public.user_profiles(id),
  acknowledged_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES public.user_profiles(id),
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  escalated BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_incidents_status ON public.unified_incidents(status, severity, detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_system ON public.unified_incidents(source_system, detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_unresolved ON public.unified_incidents(detected_at DESC) WHERE status IN ('new', 'acknowledged', 'investigating');

-- =====================================================
-- 4. ANOMALY DETECTIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.anomaly_detections (
  anomaly_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  affected_systems public.carousel_system_name[] NOT NULL,
  anomaly_type VARCHAR(100) NOT NULL,
  metric_affected VARCHAR(100) NOT NULL,
  current_value DECIMAL(12,4),
  expected_value DECIMAL(12,4),
  deviation_percentage DECIMAL(6,2),
  baseline_period_start TIMESTAMPTZ,
  baseline_period_end TIMESTAMPTZ,
  likely_cause TEXT,
  correlation_evidence JSONB DEFAULT '{}'::jsonb,
  severity public.anomaly_severity NOT NULL,
  detected_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_anomalies_detected ON public.anomaly_detections(detected_at DESC) WHERE resolved_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_anomalies_severity ON public.anomaly_detections(severity, detected_at DESC);

-- =====================================================
-- 5. OPERATIONS ACTION LOG
-- =====================================================

CREATE TABLE IF NOT EXISTS public.ops_action_log (
  action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  action_type VARCHAR(100) NOT NULL,
  target_system public.carousel_system_name,
  executed_by UUID NOT NULL REFERENCES public.user_profiles(id),
  action_parameters JSONB DEFAULT '{}'::jsonb,
  result public.action_result NOT NULL,
  execution_time_ms INTEGER,
  error_message TEXT,
  executed_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_actions_log ON public.ops_action_log(executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_actions_system ON public.ops_action_log(target_system, executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_actions_user ON public.ops_action_log(executed_by, executed_at DESC);

-- =====================================================
-- 6. CAROUSEL COACHING SESSIONS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.carousel_coaching_sessions (
  session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  performance_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  claude_analysis JSONB NOT NULL DEFAULT '{}'::jsonb,
  coaching_plan JSONB NOT NULL DEFAULT '{}'::jsonb,
  priority_recommendations JSONB DEFAULT '[]'::jsonb,
  session_date TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_coaching_creator ON public.carousel_coaching_sessions(creator_user_id, session_date DESC);

-- =====================================================
-- 7. COACHING ACTION ITEMS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.coaching_action_items (
  action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.carousel_coaching_sessions(session_id) ON DELETE CASCADE,
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  week_number INTEGER NOT NULL,
  action_category VARCHAR(50) CHECK (action_category IN ('content', 'timing', 'audience', 'revenue')),
  action_description TEXT NOT NULL,
  expected_outcome TEXT,
  priority VARCHAR(20) CHECK (priority IN ('high', 'medium', 'low')),
  status public.coaching_action_status DEFAULT 'pending'::public.coaching_action_status,
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_actions_creator ON public.coaching_action_items(creator_user_id, status);
CREATE INDEX IF NOT EXISTS idx_actions_session ON public.coaching_action_items(session_id);

-- =====================================================
-- 8. COACHING PROGRESS TRACKING
-- =====================================================

CREATE TABLE IF NOT EXISTS public.coaching_progress_tracking (
  progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  session_id UUID REFERENCES public.carousel_coaching_sessions(session_id),
  metric_name VARCHAR(100) NOT NULL,
  baseline_value DECIMAL(10,4),
  target_value DECIMAL(10,4),
  current_value DECIMAL(10,4),
  improvement_percentage DECIMAL(6,2),
  tracked_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_progress_creator ON public.coaching_progress_tracking(creator_user_id, tracked_at DESC);

-- =====================================================
-- 9. COACH CHAT HISTORY
-- =====================================================

CREATE TABLE IF NOT EXISTS public.coach_chat_history (
  chat_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  claude_response TEXT NOT NULL,
  conversation_context JSONB DEFAULT '{}'::jsonb,
  asked_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_chat_creator ON public.coach_chat_history(creator_user_id, asked_at DESC);

-- =====================================================
-- 10. RLS POLICIES
-- =====================================================

-- Unified Ops Metrics (Admin only)
ALTER TABLE public.unified_ops_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view all ops metrics" ON public.unified_ops_metrics;
CREATE POLICY "Admin can view all ops metrics" ON public.unified_ops_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS "System can insert ops metrics" ON public.unified_ops_metrics;
CREATE POLICY "System can insert ops metrics" ON public.unified_ops_metrics
  FOR INSERT WITH CHECK (true);

-- Unified Incidents (Admin only)
ALTER TABLE public.unified_incidents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can manage incidents" ON public.unified_incidents;
CREATE POLICY "Admin can manage incidents" ON public.unified_incidents
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Anomaly Detections (Admin only)
ALTER TABLE public.anomaly_detections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can view anomalies" ON public.anomaly_detections;
CREATE POLICY "Admin can view anomalies" ON public.anomaly_detections
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Ops Action Log (Admin only)
ALTER TABLE public.ops_action_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin can manage action log" ON public.ops_action_log;
CREATE POLICY "Admin can manage action log" ON public.ops_action_log
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Coaching Sessions (Creator owns their sessions)
ALTER TABLE public.carousel_coaching_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own coaching sessions" ON public.carousel_coaching_sessions;
CREATE POLICY "Creators can view own coaching sessions" ON public.carousel_coaching_sessions
  FOR SELECT USING (creator_user_id = auth.uid());

DROP POLICY IF EXISTS "System can insert coaching sessions" ON public.carousel_coaching_sessions;
CREATE POLICY "System can insert coaching sessions" ON public.carousel_coaching_sessions
  FOR INSERT WITH CHECK (creator_user_id = auth.uid());

-- Coaching Action Items (Creator owns their actions)
ALTER TABLE public.coaching_action_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can manage own action items" ON public.coaching_action_items;
CREATE POLICY "Creators can manage own action items" ON public.coaching_action_items
  FOR ALL USING (creator_user_id = auth.uid());

-- Coaching Progress Tracking (Creator owns their progress)
ALTER TABLE public.coaching_progress_tracking ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own progress" ON public.coaching_progress_tracking;
CREATE POLICY "Creators can view own progress" ON public.coaching_progress_tracking
  FOR SELECT USING (creator_user_id = auth.uid());

DROP POLICY IF EXISTS "System can insert progress" ON public.coaching_progress_tracking;
CREATE POLICY "System can insert progress" ON public.coaching_progress_tracking
  FOR INSERT WITH CHECK (creator_user_id = auth.uid());

-- Coach Chat History (Creator owns their chat)
ALTER TABLE public.coach_chat_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can manage own chat history" ON public.coach_chat_history;
CREATE POLICY "Creators can manage own chat history" ON public.coach_chat_history
  FOR ALL USING (creator_user_id = auth.uid());
