-- Campaign Optimization System Migration
-- Supports ML-powered budget reallocation, audience expansion, creative rotation automation

-- Campaign optimization recommendations table
CREATE TABLE IF NOT EXISTS public.campaign_optimization_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL,
  advertiser_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recommendation_type TEXT NOT NULL CHECK (recommendation_type IN ('budget_reallocation', 'audience_expansion', 'creative_rotation', 'bid_adjustment', 'schedule_optimization')),
  current_performance JSONB NOT NULL DEFAULT '{}',
  suggested_changes JSONB NOT NULL DEFAULT '{}',
  projected_improvement JSONB NOT NULL DEFAULT '{}',
  confidence_score DECIMAL(5,2) DEFAULT 0.00,
  ml_model_version TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'applied', 'rejected', 'expired')),
  applied_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '7 days'),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_campaign_optimization_recommendations_campaign ON public.campaign_optimization_recommendations(campaign_id);
CREATE INDEX idx_campaign_optimization_recommendations_advertiser ON public.campaign_optimization_recommendations(advertiser_id);
CREATE INDEX idx_campaign_optimization_recommendations_type ON public.campaign_optimization_recommendations(recommendation_type);
CREATE INDEX idx_campaign_optimization_recommendations_status ON public.campaign_optimization_recommendations(status);

-- Audience expansion suggestions table
CREATE TABLE IF NOT EXISTS public.audience_expansion_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL,
  advertiser_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source_segment JSONB NOT NULL DEFAULT '{}',
  suggested_segment JSONB NOT NULL DEFAULT '{}',
  similarity_score DECIMAL(5,2) DEFAULT 0.00,
  estimated_reach INTEGER DEFAULT 0,
  estimated_cpm DECIMAL(10,2) DEFAULT 0.00,
  demographic_breakdown JSONB DEFAULT '{}',
  lookalike_type TEXT CHECK (lookalike_type IN ('demographic', 'behavioral', 'interest', 'geographic', 'hybrid')),
  status TEXT DEFAULT 'suggested' CHECK (status IN ('suggested', 'testing', 'active', 'rejected')),
  performance_data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_audience_expansion_suggestions_campaign ON public.audience_expansion_suggestions(campaign_id);
CREATE INDEX idx_audience_expansion_suggestions_advertiser ON public.audience_expansion_suggestions(advertiser_id);
CREATE INDEX idx_audience_expansion_suggestions_status ON public.audience_expansion_suggestions(status);

-- Creative performance tracking table
CREATE TABLE IF NOT EXISTS public.creative_performance_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL,
  advertiser_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  creative_id TEXT NOT NULL,
  creative_variant TEXT NOT NULL,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  conversions INTEGER DEFAULT 0,
  spend DECIMAL(10,2) DEFAULT 0.00,
  ctr DECIMAL(5,2) DEFAULT 0.00,
  cvr DECIMAL(5,2) DEFAULT 0.00,
  cpc DECIMAL(10,2) DEFAULT 0.00,
  cpa DECIMAL(10,2) DEFAULT 0.00,
  roas DECIMAL(10,2) DEFAULT 0.00,
  engagement_score DECIMAL(5,2) DEFAULT 0.00,
  ab_test_group TEXT,
  statistical_significance DECIMAL(5,2) DEFAULT 0.00,
  is_winner BOOLEAN DEFAULT false,
  rotation_weight DECIMAL(5,2) DEFAULT 1.00,
  performance_trend TEXT CHECK (performance_trend IN ('improving', 'stable', 'declining')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_creative_performance_tracking_campaign ON public.creative_performance_tracking(campaign_id);
CREATE INDEX idx_creative_performance_tracking_advertiser ON public.creative_performance_tracking(advertiser_id);
CREATE INDEX idx_creative_performance_tracking_creative ON public.creative_performance_tracking(creative_id);
CREATE INDEX idx_creative_performance_tracking_winner ON public.creative_performance_tracking(is_winner);

-- Campaign automation rules table
CREATE TABLE IF NOT EXISTS public.campaign_automation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL,
  advertiser_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rule_name TEXT NOT NULL,
  rule_type TEXT NOT NULL CHECK (rule_type IN ('budget_adjustment', 'pause_campaign', 'increase_bid', 'decrease_bid', 'rotate_creative', 'expand_audience', 'send_alert')),
  trigger_conditions JSONB NOT NULL DEFAULT '{}',
  actions JSONB NOT NULL DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 1,
  execution_count INTEGER DEFAULT 0,
  last_executed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_campaign_automation_rules_campaign ON public.campaign_automation_rules(campaign_id);
CREATE INDEX idx_campaign_automation_rules_advertiser ON public.campaign_automation_rules(advertiser_id);
CREATE INDEX idx_campaign_automation_rules_active ON public.campaign_automation_rules(is_active);

-- Budget optimization history table
CREATE TABLE IF NOT EXISTS public.budget_optimization_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL,
  advertiser_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  optimization_date DATE NOT NULL DEFAULT CURRENT_DATE,
  previous_budget DECIMAL(10,2) NOT NULL,
  optimized_budget DECIMAL(10,2) NOT NULL,
  budget_change_percent DECIMAL(5,2) DEFAULT 0.00,
  previous_performance JSONB DEFAULT '{}',
  projected_performance JSONB DEFAULT '{}',
  actual_performance JSONB DEFAULT '{}',
  roi_improvement DECIMAL(5,2) DEFAULT 0.00,
  optimization_reason TEXT,
  applied_by TEXT CHECK (applied_by IN ('ml_algorithm', 'manual', 'automation_rule')),
  created_at TIMESTAMPTZ DEFAULT now(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_budget_optimization_history_campaign ON public.budget_optimization_history(campaign_id);
CREATE INDEX idx_budget_optimization_history_advertiser ON public.budget_optimization_history(advertiser_id);
CREATE INDEX idx_budget_optimization_history_date ON public.budget_optimization_history(optimization_date);

-- ROI enhancement tracking table
CREATE TABLE IF NOT EXISTS public.roi_enhancement_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL,
  advertiser_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  enhancement_type TEXT NOT NULL CHECK (enhancement_type IN ('conversion_optimization', 'bid_adjustment', 'targeting_refinement', 'creative_optimization', 'schedule_optimization')),
  baseline_roi DECIMAL(10,2) DEFAULT 0.00,
  current_roi DECIMAL(10,2) DEFAULT 0.00,
  roi_improvement_percent DECIMAL(5,2) DEFAULT 0.00,
  cost_savings DECIMAL(10,2) DEFAULT 0.00,
  revenue_increase DECIMAL(10,2) DEFAULT 0.00,
  implementation_date TIMESTAMPTZ DEFAULT now(),
  measurement_period_days INTEGER DEFAULT 7,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'reverted')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_roi_enhancement_tracking_campaign ON public.roi_enhancement_tracking(campaign_id);
CREATE INDEX idx_roi_enhancement_tracking_advertiser ON public.roi_enhancement_tracking(advertiser_id);
CREATE INDEX idx_roi_enhancement_tracking_type ON public.roi_enhancement_tracking(enhancement_type);

-- RLS Policies
ALTER TABLE public.campaign_optimization_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audience_expansion_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creative_performance_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_automation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget_optimization_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roi_enhancement_tracking ENABLE ROW LEVEL SECURITY;

-- Campaign optimization recommendations policies
CREATE POLICY "Users can view their own optimization recommendations"
  ON public.campaign_optimization_recommendations FOR SELECT
  USING (auth.uid() = advertiser_id);

CREATE POLICY "Users can insert their own optimization recommendations"
  ON public.campaign_optimization_recommendations FOR INSERT
  WITH CHECK (auth.uid() = advertiser_id);

CREATE POLICY "Users can update their own optimization recommendations"
  ON public.campaign_optimization_recommendations FOR UPDATE
  USING (auth.uid() = advertiser_id);

-- Audience expansion suggestions policies
CREATE POLICY "Users can view their own audience expansion suggestions"
  ON public.audience_expansion_suggestions FOR SELECT
  USING (auth.uid() = advertiser_id);

CREATE POLICY "Users can insert their own audience expansion suggestions"
  ON public.audience_expansion_suggestions FOR INSERT
  WITH CHECK (auth.uid() = advertiser_id);

CREATE POLICY "Users can update their own audience expansion suggestions"
  ON public.audience_expansion_suggestions FOR UPDATE
  USING (auth.uid() = advertiser_id);

-- Creative performance tracking policies
CREATE POLICY "Users can view their own creative performance"
  ON public.creative_performance_tracking FOR SELECT
  USING (auth.uid() = advertiser_id);

CREATE POLICY "Users can insert their own creative performance"
  ON public.creative_performance_tracking FOR INSERT
  WITH CHECK (auth.uid() = advertiser_id);

CREATE POLICY "Users can update their own creative performance"
  ON public.creative_performance_tracking FOR UPDATE
  USING (auth.uid() = advertiser_id);

-- Campaign automation rules policies
CREATE POLICY "Users can view their own automation rules"
  ON public.campaign_automation_rules FOR SELECT
  USING (auth.uid() = advertiser_id);

CREATE POLICY "Users can insert their own automation rules"
  ON public.campaign_automation_rules FOR INSERT
  WITH CHECK (auth.uid() = advertiser_id);

CREATE POLICY "Users can update their own automation rules"
  ON public.campaign_automation_rules FOR UPDATE
  USING (auth.uid() = advertiser_id);

CREATE POLICY "Users can delete their own automation rules"
  ON public.campaign_automation_rules FOR DELETE
  USING (auth.uid() = advertiser_id);

-- Budget optimization history policies
CREATE POLICY "Users can view their own budget optimization history"
  ON public.budget_optimization_history FOR SELECT
  USING (auth.uid() = advertiser_id);

CREATE POLICY "Users can insert their own budget optimization history"
  ON public.budget_optimization_history FOR INSERT
  WITH CHECK (auth.uid() = advertiser_id);

-- ROI enhancement tracking policies
CREATE POLICY "Users can view their own ROI enhancement tracking"
  ON public.roi_enhancement_tracking FOR SELECT
  USING (auth.uid() = advertiser_id);

CREATE POLICY "Users can insert their own ROI enhancement tracking"
  ON public.roi_enhancement_tracking FOR INSERT
  WITH CHECK (auth.uid() = advertiser_id);

CREATE POLICY "Users can update their own ROI enhancement tracking"
  ON public.roi_enhancement_tracking FOR UPDATE
  USING (auth.uid() = advertiser_id);

-- Helper function to calculate optimization score
CREATE OR REPLACE FUNCTION public.calculate_optimization_score(
  p_campaign_id UUID
) RETURNS DECIMAL AS $$
DECLARE
  v_score DECIMAL := 0.00;
  v_pending_recommendations INTEGER;
  v_active_rules INTEGER;
  v_roi_improvement DECIMAL;
BEGIN
  SELECT COUNT(*) INTO v_pending_recommendations
  FROM public.campaign_optimization_recommendations
  WHERE campaign_id = p_campaign_id AND status = 'pending';
  
  SELECT COUNT(*) INTO v_active_rules
  FROM public.campaign_automation_rules
  WHERE campaign_id = p_campaign_id AND is_active = true;
  
  SELECT COALESCE(AVG(roi_improvement_percent), 0) INTO v_roi_improvement
  FROM public.roi_enhancement_tracking
  WHERE campaign_id = p_campaign_id AND status = 'active';
  
  v_score := (v_pending_recommendations * 10) + (v_active_rules * 5) + v_roi_improvement;
  
  RETURN LEAST(v_score, 100.00);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Helper function to get campaign optimization summary
CREATE OR REPLACE FUNCTION public.get_campaign_optimization_summary(
  p_advertiser_id UUID
) RETURNS TABLE (
  campaign_id UUID,
  pending_recommendations INTEGER,
  active_automations INTEGER,
  avg_roi_improvement DECIMAL,
  total_cost_savings DECIMAL,
  optimization_score DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    cor.campaign_id,
    COUNT(DISTINCT cor.id)::INTEGER as pending_recommendations,
    COUNT(DISTINCT car.id)::INTEGER as active_automations,
    COALESCE(AVG(ret.roi_improvement_percent), 0.00)::DECIMAL as avg_roi_improvement,
    COALESCE(SUM(ret.cost_savings), 0.00)::DECIMAL as total_cost_savings,
    public.calculate_optimization_score(cor.campaign_id) as optimization_score
  FROM public.campaign_optimization_recommendations cor
  LEFT JOIN public.campaign_automation_rules car ON cor.campaign_id = car.campaign_id AND car.is_active = true
  LEFT JOIN public.roi_enhancement_tracking ret ON cor.campaign_id = ret.campaign_id AND ret.status = 'active'
  WHERE cor.advertiser_id = p_advertiser_id
  GROUP BY cor.campaign_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_campaign_optimization_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_audience_expansion_suggestions_updated_at
  BEFORE UPDATE ON public.audience_expansion_suggestions
  FOR EACH ROW EXECUTE FUNCTION public.update_campaign_optimization_updated_at();

CREATE TRIGGER update_creative_performance_tracking_updated_at
  BEFORE UPDATE ON public.creative_performance_tracking
  FOR EACH ROW EXECUTE FUNCTION public.update_campaign_optimization_updated_at();

CREATE TRIGGER update_campaign_automation_rules_updated_at
  BEFORE UPDATE ON public.campaign_automation_rules
  FOR EACH ROW EXECUTE FUNCTION public.update_campaign_optimization_updated_at();

CREATE TRIGGER update_roi_enhancement_tracking_updated_at
  BEFORE UPDATE ON public.roi_enhancement_tracking
  FOR EACH ROW EXECUTE FUNCTION public.update_campaign_optimization_updated_at();