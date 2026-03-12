-- =====================================================
-- REAL-TIME ALERT DASHBOARD + DATADOG APM + COMPREHENSIVE AUDIT LOGGING MIGRATION
-- Timestamp: 20260222091500

-- =====================================================
-- FEATURE 1: UNIFIED ALERTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.unified_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type TEXT NOT NULL CHECK (alert_type IN (
    'threat_correlation',
    'sla_breach',
    'rule_violation',
    'security_incident',
    'system_health',
    'performance',
    'compliance'
  )),
  severity TEXT NOT NULL CHECK (severity IN ('critical', 'high', 'medium', 'low')),
  title TEXT NOT NULL,
  description TEXT,
  source TEXT NOT NULL,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  affected_resources JSONB DEFAULT '[]'::JSONB,
  acknowledgment_status TEXT NOT NULL DEFAULT 'unacknowledged' CHECK (acknowledgment_status IN (
    'unacknowledged',
    'acknowledged',
    'resolved',
    'dismissed'
  )),
  assigned_to UUID REFERENCES auth.users(id),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES auth.users(id),
  resolution_notes TEXT,
  resolution_action TEXT,
  dismissed_at TIMESTAMPTZ,
  dismissed_by UUID REFERENCES auth.users(id),
  dismissal_reason TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_unified_alerts_type ON public.unified_alerts(alert_type);
CREATE INDEX IF NOT EXISTS idx_unified_alerts_severity ON public.unified_alerts(severity);
CREATE INDEX IF NOT EXISTS idx_unified_alerts_status ON public.unified_alerts(acknowledgment_status);
CREATE INDEX IF NOT EXISTS idx_unified_alerts_detected_at ON public.unified_alerts(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_unified_alerts_assigned_to ON public.unified_alerts(assigned_to);

-- =====================================================
-- ALERT TIMELINE TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.alert_timeline (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_id UUID NOT NULL REFERENCES public.unified_alerts(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN (
    'detected',
    'acknowledged',
    'assigned',
    'escalated',
    'resolved',
    'dismissed',
    'commented'
  )),
  actor_id UUID REFERENCES auth.users(id),
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alert_timeline_alert_id ON public.alert_timeline(alert_id);
CREATE INDEX IF NOT EXISTS idx_alert_timeline_created_at ON public.alert_timeline(created_at DESC);

-- =====================================================
-- ALERT COMMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.alert_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_id UUID NOT NULL REFERENCES public.unified_alerts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  comment TEXT NOT NULL,
  parent_comment_id UUID REFERENCES public.alert_comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alert_comments_alert_id ON public.alert_comments(alert_id);
CREATE INDEX IF NOT EXISTS idx_alert_comments_parent ON public.alert_comments(parent_comment_id);

-- =====================================================
-- ALERT BATCH OPERATIONS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.alert_batch_operations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_type TEXT NOT NULL CHECK (operation_type IN (
    'acknowledge',
    'assign',
    'dismiss',
    'resolve',
    'export'
  )),
  alert_ids UUID[] NOT NULL,
  performed_by UUID NOT NULL REFERENCES auth.users(id),
  success_count INTEGER NOT NULL DEFAULT 0,
  failure_count INTEGER NOT NULL DEFAULT 0,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alert_batch_ops_performed_by ON public.alert_batch_operations(performed_by);
CREATE INDEX IF NOT EXISTS idx_alert_batch_ops_created_at ON public.alert_batch_operations(created_at DESC);

-- =====================================================
-- FEATURE 2: DATADOG TRACES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.datadog_traces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  span_id TEXT NOT NULL,
  parent_span_id TEXT,
  operation_name TEXT NOT NULL,
  resource_name TEXT,
  service_name TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  duration_ms INTEGER,
  tags JSONB DEFAULT '{}'::JSONB,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_datadog_traces_span_id ON public.datadog_traces(span_id);
CREATE INDEX IF NOT EXISTS idx_datadog_traces_operation ON public.datadog_traces(operation_name);
CREATE INDEX IF NOT EXISTS idx_datadog_traces_service ON public.datadog_traces(service_name);
CREATE INDEX IF NOT EXISTS idx_datadog_traces_start_time ON public.datadog_traces(start_time DESC);

-- =====================================================
-- FEATURE 3: IMMUTABLE AUDIT LOG TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.immutable_audit_log (
  audit_log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  event_type TEXT NOT NULL CHECK (event_type IN (
    'security_policy_change',
    'incident_resolution',
    'playbook_execution',
    'escalation_decision',
    'configuration_change',
    'user_action'
  )),
  actor_id UUID REFERENCES auth.users(id),
  actor_username TEXT NOT NULL,
  actor_ip_address TEXT,
  action_type TEXT NOT NULL CHECK (action_type IN (
    'create',
    'read',
    'update',
    'delete',
    'execute',
    'escalate',
    'resolve'
  )),
  entity_type TEXT NOT NULL CHECK (entity_type IN (
    'prevention_policy',
    'incident',
    'playbook',
    'escalation_rule',
    'alert',
    'user',
    'configuration'
  )),
  entity_id TEXT,
  old_value JSONB,
  new_value JSONB,
  reason TEXT,
  cryptographic_hash VARCHAR(64) NOT NULL,
  previous_hash VARCHAR(64) NOT NULL,
  metadata JSONB DEFAULT '{}'::JSONB,
  tamper_detected BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON public.immutable_audit_log(event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_event_type ON public.immutable_audit_log(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON public.immutable_audit_log(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_entity ON public.immutable_audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_tamper ON public.immutable_audit_log(tamper_detected);

-- =====================================================
-- AUDIT VERIFICATION LOG TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.audit_verification_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  verification_timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  entries_verified INTEGER NOT NULL,
  tampering_detected BOOLEAN NOT NULL DEFAULT FALSE,
  tampered_entry_ids UUID[] DEFAULT ARRAY[]::UUID[],
  verification_duration_ms INTEGER,
  performed_by UUID REFERENCES auth.users(id)
);

CREATE INDEX IF NOT EXISTS idx_audit_verification_timestamp ON public.audit_verification_log(verification_timestamp DESC);

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- Unified Alerts RLS
ALTER TABLE public.unified_alerts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view all alerts" ON public.unified_alerts;
CREATE POLICY "Users can view all alerts"
  ON public.unified_alerts FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admins can manage alerts" ON public.unified_alerts;
CREATE POLICY "Admins can manage alerts"
  ON public.unified_alerts FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin')
    )
  );

-- Alert Timeline RLS
ALTER TABLE public.alert_timeline ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view alert timeline" ON public.alert_timeline;
CREATE POLICY "Users can view alert timeline"
  ON public.alert_timeline FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can add timeline entries" ON public.alert_timeline;
CREATE POLICY "Users can add timeline entries"
  ON public.alert_timeline FOR INSERT
  TO authenticated
  WITH CHECK (actor_id = auth.uid());

-- Alert Comments RLS
ALTER TABLE public.alert_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view comments" ON public.alert_comments;
CREATE POLICY "Users can view comments"
  ON public.alert_comments FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can add comments" ON public.alert_comments;
CREATE POLICY "Users can add comments"
  ON public.alert_comments FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own comments" ON public.alert_comments;
CREATE POLICY "Users can update own comments"
  ON public.alert_comments FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid());

-- Datadog Traces RLS
ALTER TABLE public.datadog_traces ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view traces" ON public.datadog_traces;
CREATE POLICY "Admins can view traces"
  ON public.datadog_traces FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'devops_admin')
    )
  );

DROP POLICY IF EXISTS "System can insert traces" ON public.datadog_traces;
CREATE POLICY "System can insert traces"
  ON public.datadog_traces FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Immutable Audit Log RLS (Append-Only)
ALTER TABLE public.immutable_audit_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view audit logs" ON public.immutable_audit_log;
CREATE POLICY "Admins can view audit logs"
  ON public.immutable_audit_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin', 'auditor')
    )
  );

DROP POLICY IF EXISTS "System can append audit logs" ON public.immutable_audit_log;
CREATE POLICY "System can append audit logs"
  ON public.immutable_audit_log FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Prevent UPDATE and DELETE on audit logs (immutability)
DROP POLICY IF EXISTS "Prevent audit log updates" ON public.immutable_audit_log;
CREATE POLICY "Prevent audit log updates"
  ON public.immutable_audit_log FOR UPDATE
  TO authenticated
  USING (false);

DROP POLICY IF EXISTS "Prevent audit log deletes" ON public.immutable_audit_log;
CREATE POLICY "Prevent audit log deletes"
  ON public.immutable_audit_log FOR DELETE
  TO authenticated
  USING (false);

-- Audit Verification Log RLS
ALTER TABLE public.audit_verification_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view verification logs" ON public.audit_verification_log;
CREATE POLICY "Admins can view verification logs"
  ON public.audit_verification_log FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'security_admin', 'auditor')
    )
  );

DROP POLICY IF EXISTS "System can insert verification logs" ON public.audit_verification_log;
CREATE POLICY "System can insert verification logs"
  ON public.audit_verification_log FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Update updated_at timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_unified_alerts_updated_at ON public.unified_alerts;
CREATE TRIGGER update_unified_alerts_updated_at
  BEFORE UPDATE ON public.unified_alerts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_alert_comments_updated_at ON public.alert_comments;
CREATE TRIGGER update_alert_comments_updated_at
  BEFORE UPDATE ON public.alert_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
