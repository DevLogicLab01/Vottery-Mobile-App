-- Mobile Operations Command Console & Unified Incident Orchestration Center Schema

-- Incident Correlation Clusters Table
CREATE TABLE IF NOT EXISTS public.incident_correlation_clusters (
  cluster_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  incident_ids TEXT[] NOT NULL,
  correlation_score DECIMAL(3,2) NOT NULL CHECK (correlation_score >= 0 AND correlation_score <= 1),
  correlation_factors JSONB DEFAULT '[]'::jsonb,
  cluster_size INTEGER NOT NULL,
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'acknowledged', 'resolved')),
  war_room_created BOOLEAN DEFAULT FALSE,
  war_room_channel TEXT,
  acknowledged_by UUID REFERENCES auth.users(id),
  acknowledged_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_incident_correlation_clusters_status 
  ON public.incident_correlation_clusters(status);
CREATE INDEX IF NOT EXISTS idx_incident_correlation_clusters_detected_at 
  ON public.incident_correlation_clusters(detected_at DESC);
CREATE INDEX IF NOT EXISTS idx_incident_correlation_clusters_correlation_score 
  ON public.incident_correlation_clusters(correlation_score DESC);

-- Voice Command Logs Table
CREATE TABLE IF NOT EXISTS public.voice_command_logs (
  log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  command_text TEXT NOT NULL,
  command_type TEXT,
  execution_status TEXT CHECK (execution_status IN ('success', 'failed', 'not_recognized')),
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  error_message TEXT,
  affected_incidents TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_voice_command_logs_user_id 
  ON public.voice_command_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_command_logs_executed_at 
  ON public.voice_command_logs(executed_at DESC);

-- Biometric Authentication Logs Table
CREATE TABLE IF NOT EXISTS public.biometric_auth_logs (
  log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  action_type TEXT NOT NULL,
  auth_method TEXT CHECK (auth_method IN ('fingerprint', 'face_id', 'iris')),
  auth_result TEXT CHECK (auth_result IN ('success', 'failed', 'cancelled')),
  incident_id TEXT,
  authenticated_at TIMESTAMPTZ DEFAULT NOW(),
  device_info JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_biometric_auth_logs_user_id 
  ON public.biometric_auth_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_biometric_auth_logs_authenticated_at 
  ON public.biometric_auth_logs(authenticated_at DESC);

-- War Room Participants Table
CREATE TABLE IF NOT EXISTS public.war_room_participants (
  participant_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cluster_id UUID REFERENCES public.incident_correlation_clusters(cluster_id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  role TEXT CHECK (role IN ('responder', 'observer', 'coordinator')),
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  left_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_war_room_participants_cluster_id 
  ON public.war_room_participants(cluster_id);
CREATE INDEX IF NOT EXISTS idx_war_room_participants_user_id 
  ON public.war_room_participants(user_id);

-- Function to execute raw SQL for unified incident queries
CREATE OR REPLACE FUNCTION public.execute_raw_sql(query TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
BEGIN
  EXECUTE query INTO result;
  RETURN result;
EXCEPTION WHEN OTHERS THEN
    RETURN jsonb_build_object('error', SQLERRM);
END;
$$;

-- RLS Policies
ALTER TABLE public.incident_correlation_clusters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_command_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.biometric_auth_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.war_room_participants ENABLE ROW LEVEL SECURITY;

-- Incident Correlation Clusters Policies
CREATE POLICY "Admin users can view all clusters"
  ON public.incident_correlation_clusters FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can insert clusters"
  ON public.incident_correlation_clusters FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

CREATE POLICY "Admin users can update clusters"
  ON public.incident_correlation_clusters FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Voice Command Logs Policies
CREATE POLICY "Users can view own voice commands"
  ON public.voice_command_logs FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own voice commands"
  ON public.voice_command_logs FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all voice commands"
  ON public.voice_command_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Biometric Auth Logs Policies
CREATE POLICY "Users can view own biometric logs"
  ON public.biometric_auth_logs FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own biometric logs"
  ON public.biometric_auth_logs FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all biometric logs"
  ON public.biometric_auth_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- War Room Participants Policies
CREATE POLICY "Participants can view war room members"
  ON public.war_room_participants FOR SELECT
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

CREATE POLICY "Admins can manage war room participants"
  ON public.war_room_participants FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_incident_correlation_clusters_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_incident_correlation_clusters_updated_at
  BEFORE UPDATE ON public.incident_correlation_clusters
  FOR EACH ROW
  EXECUTE FUNCTION public.update_incident_correlation_clusters_updated_at();

-- Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.incident_correlation_clusters TO authenticated;
GRANT ALL ON public.voice_command_logs TO authenticated;
GRANT ALL ON public.biometric_auth_logs TO authenticated;
GRANT ALL ON public.war_room_participants TO authenticated;
GRANT EXECUTE ON FUNCTION public.execute_raw_sql TO authenticated;
