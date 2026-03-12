-- Phase B Batch 4: AI Predictive Modeling + Enhanced Offline Sync + Fraud Detection Enhancements
-- Migration: 20260303010000_phase_b_batch4_predictive_modeling_offline_sync.sql

-- ============================================================================
-- ELECTION FORECASTING TABLES
-- ============================================================================

-- Election forecasts with GPT-5 predictions
CREATE TABLE IF NOT EXISTS public.election_forecasts (
  forecast_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  predicted_winner UUID REFERENCES public.election_options(id),
  confidence_percentage DECIMAL(5,2) NOT NULL CHECK (confidence_percentage >= 0 AND confidence_percentage <= 100),
  predicted_vote_distribution JSONB NOT NULL DEFAULT '{}',
  swing_voters JSONB NOT NULL DEFAULT '[]',
  demographic_shifts JSONB NOT NULL DEFAULT '{}',
  trend_analysis JSONB NOT NULL DEFAULT '{}',
  forecast_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  model_version TEXT NOT NULL DEFAULT 'gpt-5-turbo',
  forecast_horizon_days INTEGER NOT NULL DEFAULT 30,
  accuracy_score DECIMAL(5,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_election_forecasts_election ON public.election_forecasts(election_id);
CREATE INDEX idx_election_forecasts_date ON public.election_forecasts(forecast_date DESC);

-- Swing voter identification
CREATE TABLE IF NOT EXISTS public.swing_voters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  persuadability_score DECIMAL(5,2) NOT NULL CHECK (persuadability_score >= 0 AND persuadability_score <= 100),
  voting_history_inconsistency DECIMAL(5,2) NOT NULL DEFAULT 0,
  targeting_recommendations JSONB NOT NULL DEFAULT '[]',
  identified_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(election_id, user_id)
);

CREATE INDEX idx_swing_voters_election ON public.swing_voters(election_id);
CREATE INDEX idx_swing_voters_score ON public.swing_voters(persuadability_score DESC);

-- Demographic shift tracking
CREATE TABLE IF NOT EXISTS public.demographic_shifts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  demographic_category TEXT NOT NULL,
  baseline_percentage DECIMAL(5,2) NOT NULL,
  current_percentage DECIMAL(5,2) NOT NULL,
  shift_percentage DECIMAL(5,2) NOT NULL,
  shift_direction TEXT NOT NULL CHECK (shift_direction IN ('increase', 'decrease', 'stable')),
  analyzed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_demographic_shifts_election ON public.demographic_shifts(election_id);

-- Forecast accuracy tracking
CREATE TABLE IF NOT EXISTS public.forecast_accuracy_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  forecast_id UUID NOT NULL REFERENCES public.election_forecasts(forecast_id) ON DELETE CASCADE,
  actual_winner UUID REFERENCES public.election_options(id),
  predicted_winner UUID REFERENCES public.election_options(id),
  mean_absolute_error DECIMAL(5,2),
  confidence_calibration DECIMAL(5,2),
  evaluated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- FRAUD INCIDENTS TABLE (Enhancement to existing fraud detection)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.fraud_incidents (
  incident_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  election_id UUID NOT NULL REFERENCES public.elections(id) ON DELETE CASCADE,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ai_consensus_score DECIMAL(5,2) NOT NULL CHECK (ai_consensus_score >= 0 AND ai_consensus_score <= 100),
  risk_level TEXT NOT NULL CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  threat_patterns JSONB NOT NULL DEFAULT '[]',
  resolution_status TEXT NOT NULL DEFAULT 'pending' CHECK (resolution_status IN ('pending', 'investigating', 'resolved', 'false_positive')),
  assigned_investigator UUID REFERENCES auth.users(id),
  evidence_data JSONB NOT NULL DEFAULT '{}',
  countermeasures_applied JSONB NOT NULL DEFAULT '[]',
  resolved_at TIMESTAMPTZ,
  resolution_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_fraud_incidents_election ON public.fraud_incidents(election_id);
CREATE INDEX idx_fraud_incidents_risk ON public.fraud_incidents(risk_level);
CREATE INDEX idx_fraud_incidents_status ON public.fraud_incidents(resolution_status);
CREATE INDEX idx_fraud_incidents_detected ON public.fraud_incidents(detected_at DESC);

-- ============================================================================
-- OFFLINE SYNC OPTIMIZATION TABLES
-- ============================================================================

-- Sync conflict log
CREATE TABLE IF NOT EXISTS public.sync_conflicts (
  conflict_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  table_name TEXT NOT NULL,
  record_id UUID NOT NULL,
  local_version JSONB NOT NULL,
  server_version JSONB NOT NULL,
  ancestor_version JSONB,
  resolution_strategy TEXT NOT NULL CHECK (resolution_strategy IN ('local_wins', 'server_wins', 'manual', 'merged')),
  resolved_version JSONB,
  detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES auth.users(id)
);

CREATE INDEX idx_sync_conflicts_user ON public.sync_conflicts(user_id);
CREATE INDEX idx_sync_conflicts_detected ON public.sync_conflicts(detected_at DESC);

-- Sync queue with priority
CREATE TABLE IF NOT EXISTS public.sync_queue (
  queue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  operation_type TEXT NOT NULL CHECK (operation_type IN ('insert', 'update', 'delete')),
  table_name TEXT NOT NULL,
  record_data JSONB NOT NULL,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('critical', 'high', 'medium', 'low')),
  retry_count INTEGER NOT NULL DEFAULT 0,
  max_retries INTEGER NOT NULL DEFAULT 3,
  queued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_attempt_at TIMESTAMPTZ,
  synced_at TIMESTAMPTZ,
  error_message TEXT
);

CREATE INDEX idx_sync_queue_user ON public.sync_queue(user_id);
CREATE INDEX idx_sync_queue_priority ON public.sync_queue(priority, queued_at);
CREATE INDEX idx_sync_queue_status ON public.sync_queue(synced_at NULLS FIRST);

-- Sync performance metrics
CREATE TABLE IF NOT EXISTS public.sync_performance_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  sync_duration_ms INTEGER NOT NULL,
  data_volume_bytes INTEGER NOT NULL,
  records_synced INTEGER NOT NULL,
  conflicts_detected INTEGER NOT NULL DEFAULT 0,
  network_quality TEXT NOT NULL CHECK (network_quality IN ('wifi', '4g', '3g', '2g', 'offline')),
  sync_strategy TEXT NOT NULL CHECK (sync_strategy IN ('realtime', 'interval_30s', 'interval_5min', 'manual')),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sync_performance_user ON public.sync_performance_metrics(user_id);
CREATE INDEX idx_sync_performance_recorded ON public.sync_performance_metrics(recorded_at DESC);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Election forecasts policies
ALTER TABLE public.election_forecasts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view forecasts for elections they can access"
  ON public.election_forecasts FOR SELECT
  USING (true);

CREATE POLICY "Election creators can manage forecasts"
  ON public.election_forecasts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = election_forecasts.election_id
      AND elections.created_by = auth.uid()
    )
  );

-- Swing voters policies
ALTER TABLE public.swing_voters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own swing voter status"
  ON public.swing_voters FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Election creators can view swing voters"
  ON public.swing_voters FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = swing_voters.election_id
      AND elections.created_by = auth.uid()
    )
  );

-- Demographic shifts policies
ALTER TABLE public.demographic_shifts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view demographic shifts"
  ON public.demographic_shifts FOR SELECT
  USING (true);

-- Fraud incidents policies
ALTER TABLE public.fraud_incidents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can view all fraud incidents"
  ON public.fraud_incidents FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_role_assignments ura
      JOIN public.admin_roles ar ON ar.id = ura.role_id
      WHERE ura.user_id = auth.uid()
      AND ar.role_name IN ('super_admin', 'admin', 'moderator')
      AND ura.is_active = true
    )
  );

CREATE POLICY "Election creators can view incidents for their elections"
  ON public.fraud_incidents FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.elections
      WHERE elections.id = fraud_incidents.election_id
      AND elections.created_by = auth.uid()
    )
  );

-- Sync conflicts policies
ALTER TABLE public.sync_conflicts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own sync conflicts"
  ON public.sync_conflicts FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their own sync conflicts"
  ON public.sync_conflicts FOR UPDATE
  USING (user_id = auth.uid());

-- Sync queue policies
ALTER TABLE public.sync_queue ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own sync queue"
  ON public.sync_queue FOR ALL
  USING (user_id = auth.uid());

-- Sync performance metrics policies
ALTER TABLE public.sync_performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own sync metrics"
  ON public.sync_performance_metrics FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own sync metrics"
  ON public.sync_performance_metrics FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to calculate forecast accuracy
CREATE OR REPLACE FUNCTION public.calculate_forecast_accuracy(
  p_forecast_id UUID,
  p_actual_winner UUID
)
RETURNS DECIMAL AS $$
DECLARE
  v_predicted_winner UUID;
  v_accuracy DECIMAL;
BEGIN
  SELECT predicted_winner INTO v_predicted_winner
  FROM public.election_forecasts
  WHERE forecast_id = p_forecast_id;

  IF v_predicted_winner = p_actual_winner THEN
    v_accuracy := 100.0;
  ELSE
    v_accuracy := 0.0;
  END IF;

  INSERT INTO public.forecast_accuracy_log (
    forecast_id,
    actual_winner,
    predicted_winner,
    mean_absolute_error,
    evaluated_at
  ) VALUES (
    p_forecast_id,
    p_actual_winner,
    v_predicted_winner,
    100.0 - v_accuracy,
    NOW()
  );

  RETURN v_accuracy;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to auto-escalate critical fraud incidents
CREATE OR REPLACE FUNCTION public.auto_escalate_fraud_incidents()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.risk_level = 'critical' AND NEW.resolution_status = 'pending' THEN
    -- Auto-assign to first available admin
    SELECT user_id INTO NEW.assigned_investigator
    FROM public.user_roles
    WHERE role = 'admin'
    LIMIT 1;

    NEW.resolution_status := 'investigating';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_escalate_fraud
  BEFORE INSERT ON public.fraud_incidents
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_escalate_fraud_incidents();

-- Function to clean old sync queue entries
CREATE OR REPLACE FUNCTION public.cleanup_old_sync_queue()
RETURNS void AS $$
BEGIN
  DELETE FROM public.sync_queue
  WHERE synced_at IS NOT NULL
  AND synced_at < NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- MOCK DATA (Development Only)
-- ============================================================================

DO $$
DECLARE
  v_election_id UUID;
  v_option1_id UUID;
  v_option2_id UUID;
  v_user_id UUID;
BEGIN
  -- Get sample election and options
  SELECT id INTO v_election_id FROM public.elections LIMIT 1;
  
  IF v_election_id IS NOT NULL THEN
    SELECT id INTO v_option1_id FROM public.election_options WHERE election_id = v_election_id LIMIT 1;
    SELECT id INTO v_option2_id FROM public.election_options WHERE election_id = v_election_id OFFSET 1 LIMIT 1;
    
    -- Insert sample forecast
    INSERT INTO public.election_forecasts (
      election_id,
      predicted_winner,
      confidence_percentage,
      predicted_vote_distribution,
      swing_voters,
      demographic_shifts,
      trend_analysis,
      forecast_horizon_days
    ) VALUES (
      v_election_id,
      v_option1_id,
      67.5,
      jsonb_build_object(
        v_option1_id::text, 55.2,
        v_option2_id::text, 44.8
      ),
      jsonb_build_array(
        jsonb_build_object('segment', '18-25 urban male', 'count', 1250, 'persuadability', 78.5)
      ),
      jsonb_build_object(
        '18-25_male', jsonb_build_object('baseline', 22.5, 'current', 28.3, 'shift', '+5.8%'),
        'urban_female', jsonb_build_object('baseline', 31.2, 'current', 35.7, 'shift', '+4.5%')
      ),
      jsonb_build_object(
        'momentum', 'positive',
        'velocity', '+2.3% per day',
        'confidence_interval', '±5.2%'
      ),
      30
    ) ON CONFLICT DO NOTHING;
  END IF;
END $$;