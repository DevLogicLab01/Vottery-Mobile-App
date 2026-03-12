-- Creator Growth Predictions Table
CREATE TABLE IF NOT EXISTS public.creator_growth_predictions (
  prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  predicted_tier VARCHAR(20),
  predicted_tier_date DATE,
  predicted_earnings_30d DECIMAL(10, 2) DEFAULT 0,
  predicted_earnings_90d DECIMAL(10, 2) DEFAULT 0,
  confidence_score DECIMAL(3, 2) DEFAULT 0.5,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_creator_growth_prediction UNIQUE (creator_user_id)
);

CREATE INDEX IF NOT EXISTS idx_growth_predictions
  ON public.creator_growth_predictions (creator_user_id, generated_at);

-- Creator Churn Predictions Table
CREATE TABLE IF NOT EXISTS public.creator_churn_predictions (
  prediction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  churn_probability DECIMAL(3, 2) DEFAULT 0 CHECK (churn_probability >= 0 AND churn_probability <= 1),
  churn_timeframe_days INTEGER DEFAULT 30,
  risk_level VARCHAR(20) DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
  primary_drivers JSONB DEFAULT '[]'::jsonb,
  recommended_interventions JSONB DEFAULT '[]'::jsonb,
  claude_analysis JSONB DEFAULT '{}'::jsonb,
  predicted_at TIMESTAMPTZ DEFAULT NOW(),
  intervention_sent BOOLEAN DEFAULT false,
  last_intervention_at TIMESTAMPTZ,
  CONSTRAINT unique_creator_churn_prediction UNIQUE (creator_user_id)
);

CREATE INDEX IF NOT EXISTS idx_churn_predictions
  ON public.creator_churn_predictions (churn_probability DESC, risk_level)
  WHERE intervention_sent = false;

-- Creator Churn Interventions Table
CREATE TABLE IF NOT EXISTS public.creator_churn_interventions (
  intervention_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID REFERENCES public.creator_churn_predictions(prediction_id) ON DELETE CASCADE,
  creator_user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  intervention_type VARCHAR(20) DEFAULT 'email' CHECK (intervention_type IN ('sms', 'email', 'push_notification')),
  message_content TEXT,
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  response_status VARCHAR(20) DEFAULT 'sent' CHECK (response_status IN ('sent', 'opened', 'engaged', 'resumed_posting', 'churned')),
  response_timestamp TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_interventions
  ON public.creator_churn_interventions (prediction_id, sent_at);

-- Creator Engagement Metrics Table
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

CREATE INDEX IF NOT EXISTS idx_engagement_metrics
  ON public.creator_engagement_metrics (creator_user_id, metric_date DESC);

-- Add priority_level to offline_sync_queue if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'offline_sync_queue'
    AND column_name = 'priority_level'
  ) THEN
    ALTER TABLE public.offline_sync_queue
    ADD COLUMN priority_level VARCHAR(20) DEFAULT 'normal'
    CHECK (priority_level IN ('critical', 'high', 'normal'));
  END IF;
END $$;

-- RLS Policies
ALTER TABLE public.creator_growth_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_churn_predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_churn_interventions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_engagement_metrics ENABLE ROW LEVEL SECURITY;

-- Growth predictions: creators see own, admins see all
DROP POLICY IF EXISTS creator_growth_predictions_select ON public.creator_growth_predictions;
CREATE POLICY creator_growth_predictions_select ON public.creator_growth_predictions
  FOR SELECT USING (
    auth.uid() = creator_user_id
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS creator_growth_predictions_insert ON public.creator_growth_predictions;
CREATE POLICY creator_growth_predictions_insert ON public.creator_growth_predictions
  FOR INSERT WITH CHECK (auth.uid() = creator_user_id);

DROP POLICY IF EXISTS creator_growth_predictions_update ON public.creator_growth_predictions;
CREATE POLICY creator_growth_predictions_update ON public.creator_growth_predictions
  FOR UPDATE USING (auth.uid() = creator_user_id);

-- Churn predictions: admins only
DROP POLICY IF EXISTS churn_predictions_admin ON public.creator_churn_predictions;
CREATE POLICY churn_predictions_admin ON public.creator_churn_predictions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Engagement metrics: creators see own, admins see all
DROP POLICY IF EXISTS engagement_metrics_select ON public.creator_engagement_metrics;
CREATE POLICY engagement_metrics_select ON public.creator_engagement_metrics
  FOR SELECT USING (
    auth.uid() = creator_user_id
    OR EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

DROP POLICY IF EXISTS engagement_metrics_insert ON public.creator_engagement_metrics;
CREATE POLICY engagement_metrics_insert ON public.creator_engagement_metrics
  FOR INSERT WITH CHECK (auth.uid() = creator_user_id);
