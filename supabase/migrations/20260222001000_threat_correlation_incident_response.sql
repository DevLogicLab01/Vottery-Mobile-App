-- Real-Time Threat Correlation & Automated Incident Response Migration
-- Created: 2026-02-22

-- Add enum values using DO block with existence check
-- This avoids the "unsafe use of new value" error
DO $$ 
BEGIN
  -- Check and add super_admin if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'user_role' AND e.enumlabel = 'super_admin'
  ) THEN
    ALTER TYPE user_role ADD VALUE 'super_admin';
  END IF;
  
  -- Check and add security_admin if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'user_role' AND e.enumlabel = 'security_admin'
  ) THEN
    ALTER TYPE user_role ADD VALUE 'security_admin';
  END IF;
  
  -- Check and add devops_admin if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'user_role' AND e.enumlabel = 'devops_admin'
  ) THEN
    ALTER TYPE user_role ADD VALUE 'devops_admin';
  END IF;
END $$;

-- Incident Clusters Table
CREATE TABLE IF NOT EXISTS public.incident_clusters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cluster_id TEXT NOT NULL UNIQUE,
  incident_ids TEXT[] NOT NULL,
  cluster_type TEXT NOT NULL CHECK (cluster_type IN ('coordinated_attack', 'cascading_failure', 'anomaly_spike', 'system_outage')),
  consensus_score DECIMAL(5,4) NOT NULL CHECK (consensus_score >= 0 AND consensus_score <= 1),
  confidence_level TEXT NOT NULL CHECK (confidence_level IN ('high', 'medium', 'low')),
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  incident_count INT NOT NULL,
  time_window JSONB NOT NULL,
  affected_systems TEXT[] NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'investigating', 'resolved')),
  root_cause_analysis JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Incidents Table
CREATE TABLE IF NOT EXISTS public.incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  type TEXT,
  severity TEXT NOT NULL CHECK (severity IN ('P0', 'P1', 'P2', 'P3', 'P4')),
  severity_justification TEXT NOT NULL,
  affected_systems TEXT[] NOT NULL,
  status TEXT NOT NULL DEFAULT 'detected' CHECK (status IN ('detected', 'acknowledged', 'investigating', 'resolving', 'resolved')),
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  user_count_affected INT DEFAULT 0,
  revenue_impact DECIMAL(12,2) DEFAULT 0,
  assigned_to UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Escalation Rules Table
CREATE TABLE IF NOT EXISTS public.escalation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  conditions JSONB NOT NULL,
  actions JSONB NOT NULL,
  priority INT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Escalation History Table
CREATE TABLE IF NOT EXISTS public.escalation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  severity TEXT NOT NULL,
  response_time_minutes INT NOT NULL,
  escalated_to TEXT,
  escalation_method TEXT,
  escalated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Remediation Playbooks Table
CREATE TABLE IF NOT EXISTS public.remediation_playbooks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  incident_type TEXT NOT NULL,
  description TEXT,
  steps JSONB NOT NULL,
  estimated_duration_minutes INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Playbook Executions Table
CREATE TABLE IF NOT EXISTS public.playbook_executions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  playbook_id UUID NOT NULL REFERENCES public.remediation_playbooks(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'paused', 'completed', 'abandoned')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  current_step_index INT DEFAULT 0,
  completed_steps JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Playbook Step Logs Table
CREATE TABLE IF NOT EXISTS public.playbook_step_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  execution_id UUID NOT NULL REFERENCES public.playbook_executions(id) ON DELETE CASCADE,
  step_description TEXT NOT NULL,
  action_type TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending', 'in_progress', 'completed', 'failed', 'skipped')),
  completed_at TIMESTAMPTZ,
  completed_by UUID REFERENCES auth.users(id),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Incident Timeline Table
CREATE TABLE IF NOT EXISTS public.incident_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  event_type TEXT NOT NULL,
  description TEXT NOT NULL,
  actor UUID REFERENCES auth.users(id),
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Post-Incident Reports Table
CREATE TABLE IF NOT EXISTS public.post_incident_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  timeline_of_events JSONB NOT NULL,
  root_cause_analysis TEXT,
  resolution_summary TEXT,
  impact_assessment JSONB,
  team_performance JSONB,
  what_went_well TEXT[],
  areas_for_improvement TEXT[],
  prevention_recommendations JSONB,
  action_items JSONB,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- SLA Monitoring Tables
CREATE TABLE IF NOT EXISTS public.downtime_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  duration_minutes INT,
  severity TEXT NOT NULL,
  root_cause TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.service_health_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_name TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('healthy', 'degraded', 'down')),
  response_time_ms INT,
  error_message TEXT,
  checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.monitored_screens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  screen_name TEXT NOT NULL UNIQUE,
  route_path TEXT NOT NULL,
  importance_level TEXT NOT NULL CHECK (importance_level IN ('critical', 'high', 'medium', 'low')),
  monitoring_enabled BOOLEAN DEFAULT true,
  expected_load_time_ms INT,
  critical_elements TEXT[],
  owner_team TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.sla_breach_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  breach_type TEXT NOT NULL,
  service_name TEXT NOT NULL,
  breach_duration_minutes INT NOT NULL,
  sla_target_percentage DECIMAL(5,2) NOT NULL,
  actual_percentage DECIMAL(5,2) NOT NULL,
  impact_description TEXT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_incident_clusters_detected_at ON public.incident_clusters(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_incident_clusters_status ON public.incident_clusters(status);
CREATE INDEX IF NOT EXISTS idx_incidents_severity ON public.incidents(severity);
CREATE INDEX IF NOT EXISTS idx_incidents_status ON public.incidents(status);
CREATE INDEX IF NOT EXISTS idx_incidents_detected_at ON public.incidents(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_escalation_history_incident_id ON public.escalation_history(incident_id);
CREATE INDEX IF NOT EXISTS idx_playbook_executions_incident_id ON public.playbook_executions(incident_id);
CREATE INDEX IF NOT EXISTS idx_incident_timeline_incident_id ON public.incident_timeline(incident_id);
CREATE INDEX IF NOT EXISTS idx_service_health_history_checked_at ON public.service_health_history(checked_at DESC);

-- Row Level Security Policies
ALTER TABLE public.incident_clusters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escalation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escalation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.remediation_playbooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playbook_executions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playbook_step_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_timeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_incident_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.downtime_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_health_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monitored_screens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sla_breach_events ENABLE ROW LEVEL SECURITY;

-- Admin-only access policies (using TEXT comparison instead of enum to avoid transaction issues)
CREATE POLICY "Admin full access to incident_clusters" ON public.incident_clusters
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role::TEXT IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admin full access to incidents" ON public.incidents
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role::TEXT IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admin full access to escalation_rules" ON public.escalation_rules
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role::TEXT IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admin full access to remediation_playbooks" ON public.remediation_playbooks
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role::TEXT IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Admin read access to all monitoring tables" ON public.service_health_history
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role::TEXT IN ('admin', 'super_admin')
    )
  );

-- Insert default escalation rules
INSERT INTO public.escalation_rules (name, conditions, actions, priority) VALUES
('P0 Immediate Escalation', 
 '{"severity": "P0", "response_time_threshold": 5}',
 '[{"type": "twilio_sms", "phone_number": "+1234567890"}, {"type": "resend_email", "email": "oncall@company.com"}]',
 1),
('P1 15-Minute Escalation',
 '{"severity": "P1", "response_time_threshold": 15}',
 '[{"type": "resend_email", "email": "manager@company.com"}]',
 2);

-- Insert sample remediation playbooks
INSERT INTO public.remediation_playbooks (name, incident_type, description, steps, estimated_duration_minutes) VALUES
('Database Outage Response',
 'database_outage',
 'Standard procedure for database connectivity issues',
 '[{"description": "Check database connection", "action_type": "diagnostic", "automated_action_possible": false}, {"description": "Restart database service", "action_type": "restart_service", "service_name": "postgres", "automated_action_possible": true}, {"description": "Verify connectivity restored", "action_type": "verification", "automated_action_possible": false}]',
 30),
('DDoS Attack Mitigation',
 'ddos_attack',
 'Response procedure for distributed denial of service attacks',
 '[{"description": "Enable rate limiting", "action_type": "config_change", "automated_action_possible": true}, {"description": "Block malicious IPs", "action_type": "firewall_update", "automated_action_possible": true}, {"description": "Scale up resources", "action_type": "scale_up_resources", "automated_action_possible": true}]',
 45);

-- Insert monitored screens (sample - all 216 screens should be added)
INSERT INTO public.monitored_screens (screen_name, route_path, importance_level, expected_load_time_ms, owner_team) VALUES
('Vote Dashboard', '/vote-dashboard', 'critical', 2000, 'core'),
('Vote Casting', '/vote-casting', 'critical', 1500, 'core'),
('Payment Processing', '/payment', 'critical', 3000, 'payments'),
('User Profile', '/user-profile', 'high', 1000, 'user-experience');
