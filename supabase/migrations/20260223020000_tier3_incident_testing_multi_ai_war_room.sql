-- TIER 3 Features: Incident Testing Suite, Multi-AI Threat Orchestration, Team Incident War Room
-- Migration: 20260223020000_tier3_incident_testing_multi_ai_war_room.sql

-- ============================================================================
-- FEATURE 1: INCIDENT TESTING SUITE
-- ============================================================================

-- Synthetic Incidents Table
CREATE TABLE IF NOT EXISTS synthetic_incidents (
  synthetic_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_type VARCHAR(50) NOT NULL CHECK (incident_type IN ('fraud', 'ai_failover', 'security', 'performance', 'health', 'compliance')),
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  parameters JSONB NOT NULL,
  detection_time TIMESTAMPTZ,
  response_time_ms INTEGER,
  is_detected BOOLEAN DEFAULT FALSE,
  created_by UUID REFERENCES user_profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_synthetic_incidents_type ON synthetic_incidents(incident_type);
CREATE INDEX idx_synthetic_incidents_generated_at ON synthetic_incidents(generated_at);
CREATE INDEX idx_synthetic_incidents_detection ON synthetic_incidents(is_detected);

-- Incident Response Benchmarks Table
CREATE TABLE IF NOT EXISTS incident_response_benchmarks (
  benchmark_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_type VARCHAR(50) NOT NULL,
  detection_time_ms INTEGER NOT NULL,
  acknowledgment_time_ms INTEGER,
  resolution_time_ms INTEGER,
  benchmark_date DATE NOT NULL DEFAULT CURRENT_DATE,
  test_scenario VARCHAR(200),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_benchmarks_type_date ON incident_response_benchmarks(incident_type, benchmark_date);
CREATE INDEX idx_benchmarks_date ON incident_response_benchmarks(benchmark_date DESC);

-- Benchmark Targets Table
CREATE TABLE IF NOT EXISTS benchmark_targets (
  target_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_type VARCHAR(50) NOT NULL UNIQUE,
  target_mttd_ms INTEGER NOT NULL,
  target_mtta_ms INTEGER NOT NULL,
  target_mttr_ms INTEGER NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Stress Test Results Table
CREATE TABLE IF NOT EXISTS stress_test_results (
  test_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  test_scenario VARCHAR(100) NOT NULL,
  test_duration_minutes INTEGER NOT NULL,
  incidents_generated INTEGER NOT NULL,
  peak_cpu_percent DECIMAL(5,2),
  peak_memory_mb INTEGER,
  avg_response_time_ms INTEGER,
  errors_encountered INTEGER DEFAULT 0,
  test_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  test_configuration JSONB,
  performance_metrics JSONB,
  bottlenecks_identified TEXT[],
  recommendations TEXT[]
);

CREATE INDEX idx_stress_tests_date ON stress_test_results(test_date DESC);
CREATE INDEX idx_stress_tests_scenario ON stress_test_results(test_scenario);

-- ============================================================================
-- FEATURE 2: MULTI-AI THREAT ORCHESTRATION
-- ============================================================================

-- Multi-AI Threat Analysis Table
CREATE TABLE IF NOT EXISTS multi_ai_threat_analysis (
  analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  threat_id UUID,
  threat_description TEXT NOT NULL,
  openai_analysis JSONB,
  anthropic_analysis JSONB,
  perplexity_analysis JSONB,
  gemini_analysis JSONB,
  consensus_score DECIMAL(3,1) NOT NULL,
  agreement_level VARCHAR(20) CHECK (agreement_level IN ('high', 'medium', 'low')),
  priority_level VARCHAR(5) CHECK (priority_level IN ('P0', 'P1', 'P2', 'P3')),
  unified_summary TEXT,
  analyzed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES user_profiles(id)
);

CREATE INDEX idx_threat_analysis_priority ON multi_ai_threat_analysis(priority_level, analyzed_at DESC);
CREATE INDEX idx_threat_analysis_consensus ON multi_ai_threat_analysis(consensus_score DESC);
CREATE INDEX idx_threat_analysis_date ON multi_ai_threat_analysis(analyzed_at DESC);

-- Threat IOCs (Indicators of Compromise) Table
CREATE TABLE IF NOT EXISTS threat_iocs (
  ioc_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_id UUID REFERENCES multi_ai_threat_analysis(analysis_id) ON DELETE CASCADE,
  ioc_type VARCHAR(50) NOT NULL,
  ioc_value VARCHAR(500) NOT NULL,
  source_providers VARCHAR[] NOT NULL,
  confidence DECIMAL(3,2) CHECK (confidence >= 0 AND confidence <= 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_iocs_analysis ON threat_iocs(analysis_id);
CREATE INDEX idx_iocs_type ON threat_iocs(ioc_type);
CREATE INDEX idx_iocs_value ON threat_iocs(ioc_value);

-- AI Provider Performance Tracking
CREATE TABLE IF NOT EXISTS ai_provider_performance (
  performance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_name VARCHAR(50) NOT NULL,
  analysis_type VARCHAR(50) NOT NULL,
  response_time_ms INTEGER NOT NULL,
  accuracy_score DECIMAL(3,2),
  cost_usd DECIMAL(10,4),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_provider_performance_name ON ai_provider_performance(provider_name, timestamp DESC);

-- ============================================================================
-- FEATURE 3: TEAM INCIDENT WAR ROOM
-- ============================================================================

-- War Rooms Table
CREATE TABLE IF NOT EXISTS war_rooms (
  room_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID,
  room_name VARCHAR(200) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closed_at TIMESTAMPTZ,
  resolution_summary TEXT,
  lessons_learned TEXT,
  post_mortem_scheduled_at TIMESTAMPTZ
);

CREATE INDEX idx_war_rooms_status ON war_rooms(status, created_at DESC);
CREATE INDEX idx_war_rooms_incident ON war_rooms(incident_id);

-- War Room Members Table
CREATE TABLE IF NOT EXISTS war_room_members (
  member_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES war_rooms(room_id) ON DELETE CASCADE,
  user_id UUID REFERENCES user_profiles(id) ON DELETE CASCADE,
  role VARCHAR(50) NOT NULL,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status VARCHAR(20) DEFAULT 'online' CHECK (status IN ('online', 'offline', 'busy')),
  current_task VARCHAR(200),
  UNIQUE(room_id, user_id)
);

CREATE INDEX idx_war_room_members_room ON war_room_members(room_id, status);
CREATE INDEX idx_war_room_members_user ON war_room_members(user_id);

-- War Room Messages Table
CREATE TABLE IF NOT EXISTS war_room_messages (
  message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES war_rooms(room_id) ON DELETE CASCADE,
  sender_id UUID REFERENCES user_profiles(id),
  message_text TEXT NOT NULL,
  attachments JSONB,
  mentions UUID[],
  is_pinned BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_war_room_messages_room ON war_room_messages(room_id, created_at DESC);
CREATE INDEX idx_war_room_messages_sender ON war_room_messages(sender_id);
CREATE INDEX idx_war_room_messages_mentions ON war_room_messages USING GIN(mentions);

-- War Room Tasks Table (Kanban Board)
CREATE TABLE IF NOT EXISTS war_room_tasks (
  task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES war_rooms(room_id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  assigned_to UUID REFERENCES user_profiles(id),
  priority VARCHAR(20) CHECK (priority IN ('critical', 'high', 'medium', 'low')),
  status VARCHAR(20) NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'blocked', 'done')),
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_by UUID REFERENCES user_profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  subtasks JSONB
);

CREATE INDEX idx_war_room_tasks_room ON war_room_tasks(room_id, status);
CREATE INDEX idx_war_room_tasks_assigned ON war_room_tasks(assigned_to);
CREATE INDEX idx_war_room_tasks_priority ON war_room_tasks(priority, status);

-- War Room Decisions Table
CREATE TABLE IF NOT EXISTS war_room_decisions (
  decision_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES war_rooms(room_id) ON DELETE CASCADE,
  decision_text TEXT NOT NULL,
  made_by UUID REFERENCES user_profiles(id),
  rationale TEXT,
  approved_by UUID REFERENCES user_profiles(id),
  approval_status VARCHAR(20) DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  impact_assessment TEXT,
  decided_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_war_room_decisions_room ON war_room_decisions(room_id, decided_at DESC);
CREATE INDEX idx_war_room_decisions_approval ON war_room_decisions(approval_status);

-- War Room Evidence Table
CREATE TABLE IF NOT EXISTS war_room_evidence (
  evidence_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES war_rooms(room_id) ON DELETE CASCADE,
  file_name VARCHAR(200) NOT NULL,
  file_url VARCHAR(500) NOT NULL,
  file_type VARCHAR(50),
  uploaded_by UUID REFERENCES user_profiles(id),
  tags VARCHAR[],
  linked_task_id UUID REFERENCES war_room_tasks(task_id),
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_war_room_evidence_room ON war_room_evidence(room_id, uploaded_at DESC);
CREATE INDEX idx_war_room_evidence_tags ON war_room_evidence USING GIN(tags);

-- War Room Activity Timeline Table
CREATE TABLE IF NOT EXISTS war_room_activity (
  activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES war_rooms(room_id) ON DELETE CASCADE,
  activity_type VARCHAR(50) NOT NULL,
  user_id UUID REFERENCES user_profiles(id),
  description TEXT NOT NULL,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_war_room_activity_room ON war_room_activity(room_id, created_at DESC);

-- Escalation Notifications Table
CREATE TABLE IF NOT EXISTS war_room_escalations (
  escalation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES war_rooms(room_id) ON DELETE CASCADE,
  escalation_type VARCHAR(50) NOT NULL,
  reason TEXT NOT NULL,
  escalated_to UUID[],
  notification_sent BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_war_room_escalations_room ON war_room_escalations(room_id, created_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE synthetic_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE incident_response_benchmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE benchmark_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE stress_test_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE multi_ai_threat_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE threat_iocs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_provider_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE war_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE war_room_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE war_room_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE war_room_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE war_room_decisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE war_room_evidence ENABLE ROW LEVEL SECURITY;
ALTER TABLE war_room_activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE war_room_escalations ENABLE ROW LEVEL SECURITY;

-- Security team access policies (admin and security_admin roles)
CREATE POLICY "Security team can manage synthetic incidents"
  ON synthetic_incidents FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

CREATE POLICY "Security team can view benchmarks"
  ON incident_response_benchmarks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin', 'analyst')
    )
  );

CREATE POLICY "Security team can manage benchmarks"
  ON incident_response_benchmarks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

CREATE POLICY "Security team can manage targets"
  ON benchmark_targets FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

CREATE POLICY "Security team can manage stress tests"
  ON stress_test_results FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

CREATE POLICY "Security team can manage threat analysis"
  ON multi_ai_threat_analysis FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin', 'analyst')
    )
  );

CREATE POLICY "Security team can view IOCs"
  ON threat_iocs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin', 'analyst')
    )
  );

CREATE POLICY "Security team can view provider performance"
  ON ai_provider_performance FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

-- War room access policies (members only)
CREATE POLICY "War room members can view their rooms"
  ON war_rooms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM war_room_members
      WHERE war_room_members.room_id = war_rooms.room_id
      AND war_room_members.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

CREATE POLICY "Security team can create war rooms"
  ON war_rooms FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

CREATE POLICY "War room members can update their rooms"
  ON war_rooms FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM war_room_members
      WHERE war_room_members.room_id = war_rooms.room_id
      AND war_room_members.user_id = auth.uid()
    )
  );

CREATE POLICY "War room members can view members"
  ON war_room_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM war_room_members wm
      WHERE wm.room_id = war_room_members.room_id
      AND wm.user_id = auth.uid()
    )
  );

CREATE POLICY "War room members can manage messages"
  ON war_room_messages FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM war_room_members
      WHERE war_room_members.room_id = war_room_messages.room_id
      AND war_room_members.user_id = auth.uid()
    )
  );

CREATE POLICY "War room members can manage tasks"
  ON war_room_tasks FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM war_room_members
      WHERE war_room_members.room_id = war_room_tasks.room_id
      AND war_room_members.user_id = auth.uid()
    )
  );

CREATE POLICY "War room members can manage decisions"
  ON war_room_decisions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM war_room_members
      WHERE war_room_members.room_id = war_room_decisions.room_id
      AND war_room_members.user_id = auth.uid()
    )
  );

CREATE POLICY "War room members can manage evidence"
  ON war_room_evidence FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM war_room_members
      WHERE war_room_members.room_id = war_room_evidence.room_id
      AND war_room_members.user_id = auth.uid()
    )
  );

CREATE POLICY "War room members can view activity"
  ON war_room_activity FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM war_room_members
      WHERE war_room_members.room_id = war_room_activity.room_id
      AND war_room_members.user_id = auth.uid()
    )
  );

CREATE POLICY "War room members can view escalations"
  ON war_room_escalations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM war_room_members
      WHERE war_room_members.room_id = war_room_escalations.room_id
      AND war_room_members.user_id = auth.uid()
    )
  );

-- SQL comment for migration tracking
-- TIER 3 Features Migration: Incident Testing Suite, Multi-AI Threat Orchestration, Team Incident War Room