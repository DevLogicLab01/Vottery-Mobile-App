-- Phase 3-5: Advanced AI, Monetization & Enterprise Features Migration
-- Timestamp: 20260205003000
-- Description: Fraud detection, AI recommendations, subscriptions, creator monetization, admin management, business intelligence

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.fraud_severity CASCADE;
CREATE TYPE public.fraud_severity AS ENUM (
  'minimal',
  'low',
  'medium',
  'high',
  'critical'
);

DROP TYPE IF EXISTS public.subscription_tier CASCADE;
CREATE TYPE public.subscription_tier AS ENUM (
  'basic',
  'pro',
  'elite'
);

DROP TYPE IF EXISTS public.payout_status CASCADE;
CREATE TYPE public.payout_status AS ENUM (
  'pending',
  'processing',
  'completed',
  'failed',
  'cancelled'
);

DROP TYPE IF EXISTS public.alert_severity CASCADE;
CREATE TYPE public.alert_severity AS ENUM (
  'info',
  'warning',
  'error',
  'critical'
);

-- ============================================================
-- 2. FRAUD DETECTION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.fraud_detections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vote_id UUID REFERENCES public.votes(id) ON DELETE CASCADE,
  fraud_score NUMERIC(5,2) NOT NULL CHECK (fraud_score >= 0 AND fraud_score <= 100),
  severity public.fraud_severity NOT NULL,
  confidence NUMERIC(3,2) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  ai_consensus JSONB DEFAULT '{}'::jsonb,
  recommended_action TEXT,
  reasoning TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.fraud_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vote_id UUID REFERENCES public.votes(id) ON DELETE CASCADE,
  fraud_score NUMERIC(5,2) NOT NULL,
  severity public.fraud_severity NOT NULL,
  alert_type TEXT NOT NULL,
  description TEXT NOT NULL,
  recommended_action TEXT,
  is_resolved BOOLEAN DEFAULT false,
  resolution TEXT,
  resolution_notes TEXT,
  resolved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 3. AI RECOMMENDATIONS TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.recommendation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  context TEXT NOT NULL,
  recommendation_count INTEGER DEFAULT 0,
  recommendations JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.trending_topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_name TEXT NOT NULL,
  category TEXT,
  trend_score NUMERIC(5,2) DEFAULT 0,
  sentiment_analysis JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 4. ADVERTISING TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.participatory_ads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  advertiser_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  election_id UUID REFERENCES public.elections(id) ON DELETE SET NULL,
  context TEXT NOT NULL,
  cpe_bid NUMERIC(10,2) NOT NULL,
  budget NUMERIC(10,2) NOT NULL,
  spent NUMERIC(10,2) DEFAULT 0,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  engagements INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.ad_impressions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id TEXT NOT NULL,
  ad_type TEXT NOT NULL,
  slot_id TEXT NOT NULL,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.ad_clicks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id TEXT NOT NULL,
  ad_type TEXT NOT NULL,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.ad_engagements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ad_id TEXT NOT NULL,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  engagement_type TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 5. SUBSCRIPTION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  tier public.subscription_tier NOT NULL,
  billing_period TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  status TEXT NOT NULL,
  start_date TIMESTAMPTZ NOT NULL,
  next_billing_date TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  payment_intent_id TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 6. CREATOR MONETIZATION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.creator_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  tier TEXT NOT NULL,
  tier_level INTEGER NOT NULL,
  revenue_share_percentage NUMERIC(5,2) DEFAULT 70.00,
  benefits JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_id)
);

CREATE TABLE IF NOT EXISTS public.revenue_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content_id UUID,
  content_type TEXT,
  total_revenue NUMERIC(10,2) NOT NULL,
  creator_share NUMERIC(10,2) NOT NULL,
  platform_share NUMERIC(10,2) NOT NULL,
  revenue_source TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.payout_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL,
  payout_method TEXT NOT NULL,
  payout_details JSONB DEFAULT '{}'::jsonb,
  status public.payout_status DEFAULT 'pending',
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.brand_partnerships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_name TEXT NOT NULL,
  description TEXT,
  budget NUMERIC(10,2) NOT NULL,
  requirements JSONB DEFAULT '{}'::jsonb,
  status TEXT DEFAULT 'open',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 7. ADMIN MANAGEMENT TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.feature_toggles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_name TEXT NOT NULL UNIQUE,
  is_enabled BOOLEAN DEFAULT false,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  action_type TEXT NOT NULL,
  target_id UUID,
  target_type TEXT,
  details JSONB DEFAULT '{}'::jsonb,
  ip_address TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.admin_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  target_id TEXT NOT NULL,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.system_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type TEXT NOT NULL,
  severity public.alert_severity NOT NULL,
  message TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  is_resolved BOOLEAN DEFAULT false,
  resolution TEXT,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 8. BUSINESS INTELLIGENCE TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.kpi_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kpi_name TEXT NOT NULL,
  kpi_value NUMERIC(15,2) NOT NULL,
  target_value NUMERIC(15,2),
  period TEXT NOT NULL,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.executive_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type TEXT NOT NULL,
  report_data JSONB NOT NULL,
  generated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 9. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fraud_detections_vote ON public.fraud_detections(vote_id);
CREATE INDEX IF NOT EXISTS idx_fraud_detections_severity ON public.fraud_detections(severity);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_unresolved ON public.fraud_alerts(is_resolved) WHERE is_resolved = false;

CREATE INDEX IF NOT EXISTS idx_recommendation_logs_user ON public.recommendation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_trending_topics_score ON public.trending_topics(trend_score DESC);

CREATE INDEX IF NOT EXISTS idx_participatory_ads_status ON public.participatory_ads(status);
CREATE INDEX IF NOT EXISTS idx_ad_impressions_timestamp ON public.ad_impressions(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status);

CREATE INDEX IF NOT EXISTS idx_revenue_transactions_creator ON public.revenue_transactions(creator_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_creator ON public.payout_requests(creator_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_status ON public.payout_requests(status);

CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action_type);
CREATE INDEX IF NOT EXISTS idx_system_alerts_unresolved ON public.system_alerts(is_resolved) WHERE is_resolved = false;

CREATE INDEX IF NOT EXISTS idx_kpi_tracking_name ON public.kpi_tracking(kpi_name);
CREATE INDEX IF NOT EXISTS idx_executive_reports_type ON public.executive_reports(report_type);

-- ============================================================
-- 10. RLS POLICIES
-- ============================================================

-- Fraud Detection Policies
ALTER TABLE public.fraud_detections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin can view fraud detections" ON public.fraud_detections FOR SELECT USING (true);
CREATE POLICY "System can insert fraud detections" ON public.fraud_detections FOR INSERT WITH CHECK (true);

ALTER TABLE public.fraud_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin can view fraud alerts" ON public.fraud_alerts FOR SELECT USING (true);
CREATE POLICY "Admin can update fraud alerts" ON public.fraud_alerts FOR UPDATE USING (true);

-- Recommendations Policies
ALTER TABLE public.recommendation_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own recommendations" ON public.recommendation_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can insert recommendations" ON public.recommendation_logs FOR INSERT WITH CHECK (true);

-- Advertising Policies
ALTER TABLE public.participatory_ads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view active ads" ON public.participatory_ads FOR SELECT USING (status = 'active');
CREATE POLICY "Advertisers can manage own ads" ON public.participatory_ads FOR ALL USING (auth.uid() = advertiser_id);

-- Subscription Policies
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own subscriptions" ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can manage subscriptions" ON public.subscriptions FOR ALL USING (true);

-- Creator Monetization Policies
ALTER TABLE public.revenue_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Creators can view own revenue" ON public.revenue_transactions FOR SELECT USING (auth.uid() = creator_id);

ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Creators can view own payouts" ON public.payout_requests FOR SELECT USING (auth.uid() = creator_id);
CREATE POLICY "Creators can request payouts" ON public.payout_requests FOR INSERT WITH CHECK (auth.uid() = creator_id);

-- Admin Management Policies
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin can view audit logs" ON public.audit_logs FOR SELECT USING (true);
CREATE POLICY "System can insert audit logs" ON public.audit_logs FOR INSERT WITH CHECK (true);

ALTER TABLE public.system_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin can view system alerts" ON public.system_alerts FOR SELECT USING (true);
CREATE POLICY "Admin can manage system alerts" ON public.system_alerts FOR ALL USING (true);

-- Business Intelligence Policies
ALTER TABLE public.kpi_tracking ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin can view KPIs" ON public.kpi_tracking FOR SELECT USING (true);

ALTER TABLE public.executive_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin can view executive reports" ON public.executive_reports FOR SELECT USING (true);

-- ============================================================
-- 11. FUNCTIONS
-- ============================================================

-- Increment ad metrics
CREATE OR REPLACE FUNCTION public.increment_ad_impressions(ad_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.participatory_ads
  SET impressions = impressions + 1
  WHERE id::text = ad_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.increment_ad_clicks(ad_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.participatory_ads
  SET clicks = clicks + 1
  WHERE id::text = ad_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.increment_ad_engagements(ad_id TEXT)
RETURNS void AS $$
BEGIN
  UPDATE public.participatory_ads
  SET engagements = engagements + 1
  WHERE id::text = ad_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get fraud statistics
CREATE OR REPLACE FUNCTION public.get_fraud_statistics()
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_detections', COUNT(*),
    'critical_alerts', COUNT(*) FILTER (WHERE severity = 'critical'),
    'high_alerts', COUNT(*) FILTER (WHERE severity = 'high'),
    'medium_alerts', COUNT(*) FILTER (WHERE severity = 'medium'),
    'low_alerts', COUNT(*) FILTER (WHERE severity = 'low'),
    'resolved_alerts', COUNT(*) FILTER (WHERE is_resolved = true),
    'average_fraud_score', AVG(fraud_score)
  ) INTO result
  FROM public.fraud_alerts;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get system statistics
CREATE OR REPLACE FUNCTION public.get_system_statistics()
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_users', (SELECT COUNT(*) FROM public.user_profiles),
    'active_users', (SELECT COUNT(*) FROM public.user_profiles WHERE status = 'active'),
    'total_elections', (SELECT COUNT(*) FROM public.elections),
    'active_elections', (SELECT COUNT(*) FROM public.elections WHERE status = 'active'),
    'total_votes', (SELECT COUNT(*) FROM public.votes),
    'total_revenue', (SELECT COALESCE(SUM(total_revenue), 0) FROM public.revenue_transactions)
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get executive dashboard
CREATE OR REPLACE FUNCTION public.get_executive_dashboard()
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_revenue', COALESCE(SUM(total_revenue), 0),
    'monthly_revenue', COALESCE(SUM(total_revenue) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days'), 0),
    'revenue_growth', 0.0,
    'active_users', (SELECT COUNT(*) FROM public.user_profiles WHERE status = 'active'),
    'user_growth', 0.0,
    'engagement_rate', 0.0,
    'churn_rate', 0.0
  ) INTO result
  FROM public.revenue_transactions;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
