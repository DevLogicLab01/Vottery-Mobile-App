-- Creator Churn Prediction Tables
-- Migration: 20260226020000_creator_churn_prediction_tables.sql

-- Creator engagement metrics table
CREATE TABLE IF NOT EXISTS public.creator_engagement_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  posting_count INTEGER DEFAULT 0,
  login_count INTEGER DEFAULT 0,
  vp_earned DECIMAL(10, 2) DEFAULT 0,
  engagement_rate DECIMAL(5, 2) DEFAULT 0,
  content_views INTEGER DEFAULT 0,
  CONSTRAINT unique_creator_metric_date UNIQUE (creator_user_id, metric_date)
);

CREATE INDEX IF NOT EXISTS idx_engagement_metrics_creator_date
  ON public.creator_engagement_metrics (creator_user_id, metric_date DESC);

-- Creator churn predictions table
CREATE TABLE IF NOT EXISTS public.creator_churn_predictions (
  prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  churn_probability DECIMAL(3, 2) CHECK (churn_probability >= 0 AND churn_probability <= 1),
  churn_timeframe_days INTEGER,
  risk_level VARCHAR(20) CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  primary_drivers JSONB DEFAULT '[]'::jsonb,
  recommended_interventions JSONB DEFAULT '[]'::jsonb,
  claude_analysis JSONB,
  predicted_at TIMESTAMPTZ DEFAULT NOW(),
  intervention_sent BOOLEAN DEFAULT false,
  last_intervention_at TIMESTAMPTZ,
  CONSTRAINT unique_creator_churn_prediction UNIQUE (creator_user_id)
);

CREATE INDEX IF NOT EXISTS idx_churn_predictions_probability
  ON public.creator_churn_predictions (churn_probability DESC, risk_level)
  WHERE intervention_sent = false;

CREATE INDEX IF NOT EXISTS idx_churn_predictions_creator
  ON public.creator_churn_predictions (creator_user_id, predicted_at DESC);

-- Creator churn interventions table
CREATE TABLE IF NOT EXISTS public.creator_churn_interventions (
  intervention_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID REFERENCES public.creator_churn_predictions(prediction_id) ON DELETE CASCADE,
  creator_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  intervention_type VARCHAR(20) CHECK (intervention_type IN ('sms', 'email', 'push_notification', 'urgent_retention', 'proactive_engagement')),
  message_content TEXT,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  response_status VARCHAR(20) DEFAULT 'sent' CHECK (response_status IN ('sent', 'opened', 'engaged', 'resumed_posting', 'churned')),
  response_timestamp TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_interventions_prediction
  ON public.creator_churn_interventions (prediction_id, sent_at DESC);

CREATE INDEX IF NOT EXISTS idx_interventions_creator
  ON public.creator_churn_interventions (creator_user_id, sent_at DESC);

-- Add priority_level to offline_sync_queue if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'offline_sync_queue'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'offline_sync_queue'
        AND column_name = 'priority_level'
    ) THEN
      ALTER TABLE public.offline_sync_queue
        ADD COLUMN priority_level VARCHAR(20)
          DEFAULT 'normal'
          CHECK (priority_level IN ('critical', 'high', 'normal'));
    END IF;
  END IF;
END;
$$;

-- RLS Policies for creator_engagement_metrics
ALTER TABLE public.creator_engagement_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own metrics" ON public.creator_engagement_metrics;
CREATE POLICY "Creators can view own metrics"
  ON public.creator_engagement_metrics
  FOR SELECT
  USING (auth.uid() = creator_user_id);

DROP POLICY IF EXISTS "Admins can manage engagement metrics" ON public.creator_engagement_metrics;
CREATE POLICY "Admins can manage engagement metrics"
  ON public.creator_engagement_metrics
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- RLS Policies for creator_churn_predictions
ALTER TABLE public.creator_churn_predictions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage churn predictions" ON public.creator_churn_predictions;
CREATE POLICY "Admins can manage churn predictions"
  ON public.creator_churn_predictions
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'retention_specialist')
    )
  );

-- RLS Policies for creator_churn_interventions
ALTER TABLE public.creator_churn_interventions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can manage interventions" ON public.creator_churn_interventions;
CREATE POLICY "Admins can manage interventions"
  ON public.creator_churn_interventions
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin', 'retention_specialist')
    )
  );
