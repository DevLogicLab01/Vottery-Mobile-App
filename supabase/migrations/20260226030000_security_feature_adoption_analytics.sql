-- Security Feature Adoption Analytics Tables

-- Track security feature events (education hub, blockchain, etc.)
CREATE TABLE IF NOT EXISTS public.security_feature_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  feature TEXT NOT NULL,
  event_type TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_security_feature_events_feature ON public.security_feature_events(feature);
CREATE INDEX IF NOT EXISTS idx_security_feature_events_user ON public.security_feature_events(user_id);
CREATE INDEX IF NOT EXISTS idx_security_feature_events_created ON public.security_feature_events(created_at DESC);

-- Track threat response acknowledgments
CREATE TABLE IF NOT EXISTS public.threat_response_acknowledgments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  threat_id UUID,
  acknowledged BOOLEAN DEFAULT FALSE,
  response_time_ms INTEGER,
  threat_level TEXT DEFAULT 'medium',
  action_taken TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_threat_ack_admin ON public.threat_response_acknowledgments(admin_id);
CREATE INDEX IF NOT EXISTS idx_threat_ack_created ON public.threat_response_acknowledgments(created_at DESC);

-- Claude model versions for A/B testing
CREATE TABLE IF NOT EXISTS public.claude_model_versions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  version TEXT NOT NULL UNIQUE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'legacy', 'retired', 'testing')),
  accuracy NUMERIC(5,2) DEFAULT 0,
  helpful_rate NUMERIC(5,2) DEFAULT 0,
  training_samples INTEGER DEFAULT 0,
  ab_group TEXT CHECK (ab_group IN ('control', 'treatment', NULL)),
  requests_served INTEGER DEFAULT 0,
  deployed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.security_feature_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.threat_response_acknowledgments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.claude_model_versions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'security_feature_events' AND policyname = 'Users can insert own events'
  ) THEN
    CREATE POLICY "Users can insert own events" ON public.security_feature_events
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'security_feature_events' AND policyname = 'Users can read own events'
  ) THEN
    CREATE POLICY "Users can read own events" ON public.security_feature_events
      FOR SELECT USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'threat_response_acknowledgments' AND policyname = 'Admins can manage threat acks'
  ) THEN
    CREATE POLICY "Admins can manage threat acks" ON public.threat_response_acknowledgments
      FOR ALL USING (auth.uid() = admin_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'claude_model_versions' AND policyname = 'Anyone can read model versions'
  ) THEN
    CREATE POLICY "Anyone can read model versions" ON public.claude_model_versions
      FOR SELECT USING (true);
  END IF;
END;
$$;

-- Seed initial model versions
INSERT INTO public.claude_model_versions (version, status, accuracy, helpful_rate, training_samples, ab_group, requests_served)
VALUES
  ('claude-3.5-sonnet-v3-finetuned', 'active', 87.4, 82.1, 1240, 'treatment', 4821),
  ('claude-3.5-sonnet-v2-finetuned', 'legacy', 84.1, 78.6, 890, 'control', 3201),
  ('claude-3.5-sonnet-base', 'retired', 79.3, 71.2, 0, NULL, 12400)
ON CONFLICT (version) DO NOTHING;
