-- Phase 4-5: Monetization & Enterprise Features Migration
-- Timestamp: 20260205004000
-- Description: Subscriptions, AdSense, creator payouts, admin controls, business intelligence

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.subscription_tier CASCADE;
CREATE TYPE public.subscription_tier AS ENUM (
  'free',
  'basic',
  'pro',
  'elite'
);

DROP TYPE IF EXISTS public.subscription_status CASCADE;
CREATE TYPE public.subscription_status AS ENUM (
  'active',
  'cancelled',
  'expired',
  'paused'
);

DROP TYPE IF EXISTS public.payout_status CASCADE;
CREATE TYPE public.payout_status AS ENUM (
  'pending',
  'processing',
  'completed',
  'failed',
  'cancelled'
);

DROP TYPE IF EXISTS public.ad_type CASCADE;
CREATE TYPE public.ad_type AS ENUM (
  'adsense',
  'participatory',
  'sponsored'
);

DROP TYPE IF EXISTS public.audit_action CASCADE;
CREATE TYPE public.audit_action AS ENUM (
  'create',
  'update',
  'delete',
  'login',
  'logout',
  'permission_change',
  'feature_toggle'
);

-- ============================================================
-- 2. SUBSCRIPTION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.subscription_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_name public.subscription_tier NOT NULL UNIQUE,
  vp_multiplier NUMERIC(3,2) NOT NULL DEFAULT 1.00,
  monthly_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  annual_price NUMERIC(10,2) NOT NULL DEFAULT 0.00,
  features JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  tier public.subscription_tier NOT NULL,
  status public.subscription_status NOT NULL DEFAULT 'active',
  stripe_subscription_id TEXT,
  stripe_customer_id TEXT,
  current_period_start TIMESTAMPTZ,
  current_period_end TIMESTAMPTZ,
  cancel_at_period_end BOOLEAN DEFAULT false,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX idx_user_subscriptions_user ON public.user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON public.user_subscriptions(status);
CREATE INDEX idx_user_subscriptions_tier ON public.user_subscriptions(tier);

-- ============================================================
-- 3. CREATOR MONETIZATION TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.creator_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  creator_tier TEXT DEFAULT 'bronze',
  total_earnings NUMERIC(12,2) DEFAULT 0.00,
  lifetime_earnings NUMERIC(12,2) DEFAULT 0.00,
  revenue_share_percentage INTEGER DEFAULT 70,
  stripe_account_id TEXT,
  is_verified BOOLEAN DEFAULT false,
  verification_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS public.creator_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.creator_profiles(id) ON DELETE CASCADE,
  amount NUMERIC(12,2) NOT NULL,
  status public.payout_status NOT NULL DEFAULT 'pending',
  stripe_payout_id TEXT,
  payout_method TEXT DEFAULT 'stripe',
  payout_date TIMESTAMPTZ,
  failure_reason TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_creator_payouts_creator ON public.creator_payouts(creator_id);
CREATE INDEX idx_creator_payouts_status ON public.creator_payouts(status);
CREATE INDEX idx_creator_payouts_created_at ON public.creator_payouts(created_at DESC);

CREATE TABLE IF NOT EXISTS public.revenue_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES public.creator_profiles(id) ON DELETE CASCADE,
  transaction_type TEXT NOT NULL,
  amount NUMERIC(12,2) NOT NULL,
  platform_fee NUMERIC(12,2) DEFAULT 0.00,
  creator_share NUMERIC(12,2) DEFAULT 0.00,
  source_type TEXT,
  source_id UUID,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_revenue_transactions_creator ON public.revenue_transactions(creator_id);
CREATE INDEX idx_revenue_transactions_created_at ON public.revenue_transactions(created_at DESC);

-- ============================================================
-- 4. ADVERTISING TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.ad_campaigns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_name TEXT NOT NULL,
  ad_type public.ad_type NOT NULL,
  advertiser_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  budget NUMERIC(12,2) DEFAULT 0.00,
  spent NUMERIC(12,2) DEFAULT 0.00,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  engagements INTEGER DEFAULT 0,
  cpe_rate NUMERIC(10,4) DEFAULT 0.00,
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  targeting_config JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ad_campaigns_advertiser ON public.ad_campaigns(advertiser_id);
CREATE INDEX idx_ad_campaigns_type ON public.ad_campaigns(ad_type);
CREATE INDEX idx_ad_campaigns_active ON public.ad_campaigns(is_active);

CREATE TABLE IF NOT EXISTS public.ad_impressions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.ad_campaigns(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  impression_type TEXT NOT NULL,
  clicked BOOLEAN DEFAULT false,
  engaged BOOLEAN DEFAULT false,
  engagement_duration INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ad_impressions_campaign ON public.ad_impressions(campaign_id);
CREATE INDEX idx_ad_impressions_user ON public.ad_impressions(user_id);
CREATE INDEX idx_ad_impressions_created_at ON public.ad_impressions(created_at DESC);

-- ============================================================
-- 5. ADMIN & ENTERPRISE TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.feature_toggles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_key TEXT NOT NULL UNIQUE,
  feature_name TEXT NOT NULL,
  description TEXT,
  is_enabled BOOLEAN DEFAULT false,
  rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  target_users UUID[],
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.admin_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action public.audit_action NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  old_values JSONB,
  new_values JSONB,
  ip_address TEXT,
  user_agent TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_admin_audit_logs_admin ON public.admin_audit_logs(admin_id);
CREATE INDEX idx_admin_audit_logs_action ON public.admin_audit_logs(action);
CREATE INDEX idx_admin_audit_logs_resource ON public.admin_audit_logs(resource_type, resource_id);
CREATE INDEX idx_admin_audit_logs_created_at ON public.admin_audit_logs(created_at DESC);

CREATE TABLE IF NOT EXISTS public.compliance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  compliance_type TEXT NOT NULL,
  status TEXT NOT NULL,
  details JSONB NOT NULL,
  severity TEXT,
  resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_compliance_logs_type ON public.compliance_logs(compliance_type);
CREATE INDEX idx_compliance_logs_status ON public.compliance_logs(status);
CREATE INDEX idx_compliance_logs_resolved ON public.compliance_logs(resolved);
CREATE INDEX idx_compliance_logs_created_at ON public.compliance_logs(created_at DESC);

CREATE TABLE IF NOT EXISTS public.business_intelligence_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type TEXT NOT NULL,
  report_period TEXT NOT NULL,
  report_data JSONB NOT NULL,
  generated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bi_reports_type ON public.business_intelligence_reports(report_type);
CREATE INDEX idx_bi_reports_period ON public.business_intelligence_reports(report_period);
CREATE INDEX idx_bi_reports_created_at ON public.business_intelligence_reports(created_at DESC);

-- ============================================================
-- 6. ROW LEVEL SECURITY POLICIES
-- ============================================================

-- Subscription Tiers (Public read, admin write)
ALTER TABLE public.subscription_tiers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view subscription tiers"
  ON public.subscription_tiers FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admin can manage subscription tiers"
  ON public.subscription_tiers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- User Subscriptions (Users see their own)
ALTER TABLE public.user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own subscription"
  ON public.user_subscriptions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "System can manage subscriptions"
  ON public.user_subscriptions FOR ALL
  USING (true);

-- Creator Profiles (Creators see their own, public can view verified)
ALTER TABLE public.creator_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their own profile"
  ON public.creator_profiles FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Anyone can view verified creators"
  ON public.creator_profiles FOR SELECT
  USING (is_verified = true);

CREATE POLICY "Creators can update their own profile"
  ON public.creator_profiles FOR UPDATE
  USING (user_id = auth.uid());

-- Creator Payouts (Creators see their own)
ALTER TABLE public.creator_payouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their own payouts"
  ON public.creator_payouts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.creator_profiles
      WHERE id = creator_payouts.creator_id AND user_id = auth.uid()
    )
  );

-- Revenue Transactions (Creators see their own)
ALTER TABLE public.revenue_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their own revenue"
  ON public.revenue_transactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.creator_profiles
      WHERE id = revenue_transactions.creator_id AND user_id = auth.uid()
    )
  );

-- Ad Campaigns (Advertisers see their own, admin sees all)
ALTER TABLE public.ad_campaigns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Advertisers can view their own campaigns"
  ON public.ad_campaigns FOR SELECT
  USING (advertiser_id = auth.uid());

CREATE POLICY "Admin can view all campaigns"
  ON public.ad_campaigns FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Feature Toggles (Admin only)
ALTER TABLE public.feature_toggles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can manage feature toggles"
  ON public.feature_toggles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin Audit Logs (Admin only)
ALTER TABLE public.admin_audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view audit logs"
  ON public.admin_audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "System can create audit logs"
  ON public.admin_audit_logs FOR INSERT
  WITH CHECK (true);

-- Compliance Logs (Admin only)
ALTER TABLE public.compliance_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view compliance logs"
  ON public.compliance_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Business Intelligence Reports (Admin only)
ALTER TABLE public.business_intelligence_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admin can view BI reports"
  ON public.business_intelligence_reports FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================================
-- 7. FUNCTIONS
-- ============================================================

-- Function to apply VP multiplier
CREATE OR REPLACE FUNCTION public.apply_vp_multiplier(
  p_user_id UUID,
  p_base_vp INTEGER
) RETURNS INTEGER AS $$
DECLARE
  v_multiplier NUMERIC(3,2) := 1.00;
  v_tier public.subscription_tier;
BEGIN
  -- Get user's subscription tier
  SELECT tier INTO v_tier
  FROM public.user_subscriptions
  WHERE user_id = p_user_id AND status = 'active';

  -- Get multiplier for tier
  IF v_tier IS NOT NULL THEN
    SELECT vp_multiplier INTO v_multiplier
    FROM public.subscription_tiers
    WHERE tier_name = v_tier;
  END IF;

  RETURN (p_base_vp * v_multiplier)::INTEGER;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate creator payout
CREATE OR REPLACE FUNCTION public.calculate_creator_payout(
  p_creator_id UUID,
  p_period_start TIMESTAMPTZ,
  p_period_end TIMESTAMPTZ
) RETURNS NUMERIC AS $$
DECLARE
  v_total_earnings NUMERIC(12,2);
BEGIN
  SELECT COALESCE(SUM(creator_share), 0.00) INTO v_total_earnings
  FROM public.revenue_transactions
  WHERE creator_id = p_creator_id
    AND created_at >= p_period_start
    AND created_at < p_period_end;

  RETURN v_total_earnings;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 8. SEED DATA
-- ============================================================

-- Insert default subscription tiers
INSERT INTO public.subscription_tiers (tier_name, vp_multiplier, monthly_price, annual_price, features, display_order)
VALUES
  ('free', 1.00, 0.00, 0.00, '["Standard VP Earning", "Basic Features"]'::jsonb, 0),
  ('basic', 2.00, 4.99, 49.99, '["2x VP Multiplier", "Priority Support", "Exclusive Badges", "Early Access"]'::jsonb, 1),
  ('pro', 3.00, 9.99, 99.99, '["3x VP Multiplier", "Ad-Free Experience", "Custom Themes", "Priority Support", "Exclusive Content", "Advanced Analytics"]'::jsonb, 2),
  ('elite', 5.00, 19.99, 199.99, '["5x VP Multiplier", "All Pro Features", "Exclusive Elite Badge", "24/7 Priority Support", "Early Beta Access", "Creator Tools", "Family Sharing (5 accounts)"]'::jsonb, 3)
ON CONFLICT (tier_name) DO NOTHING;