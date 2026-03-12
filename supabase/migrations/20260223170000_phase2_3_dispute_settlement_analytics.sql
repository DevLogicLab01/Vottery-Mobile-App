-- Phase 2 & 3: Marketplace Dispute Resolution + Creator Settlement + Unified Analytics
-- Comprehensive ecosystem completion with AI arbitration, multi-currency settlements, and cross-platform analytics

-- =====================================================
-- 1. TYPES (with idempotency)
-- =====================================================

DROP TYPE IF EXISTS public.dispute_status CASCADE;
CREATE TYPE public.dispute_status AS ENUM ('open', 'under_review', 'resolved', 'closed');

DROP TYPE IF EXISTS public.resolution_type CASCADE;
CREATE TYPE public.resolution_type AS ENUM ('full_refund', 'partial_refund', 'release_to_seller', 'mediation_required');

DROP TYPE IF EXISTS public.settlement_status CASCADE;
CREATE TYPE public.settlement_status AS ENUM ('pending', 'processing', 'completed', 'failed');

DROP TYPE IF EXISTS public.discrepancy_status CASCADE;
CREATE TYPE public.discrepancy_status AS ENUM ('investigating', 'resolved', 'disputed');

-- =====================================================
-- 2. MARKETPLACE DISPUTE RESOLUTION TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.marketplace_disputes (
  dispute_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.marketplace_orders(order_id) ON DELETE CASCADE,
  raised_by VARCHAR(20) NOT NULL CHECK (raised_by IN ('buyer', 'seller')),
  dispute_reason VARCHAR(100) NOT NULL,
  dispute_description TEXT NOT NULL,
  buyer_claim_evidence JSONB DEFAULT '[]'::JSONB,
  seller_response_text TEXT,
  seller_evidence JSONB DEFAULT '[]'::JSONB,
  status public.dispute_status DEFAULT 'open'::public.dispute_status,
  ai_analysis JSONB,
  resolution_type public.resolution_type,
  refund_percentage INTEGER CHECK (refund_percentage >= 0 AND refund_percentage <= 100),
  resolution_notes TEXT,
  resolved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  raised_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  responded_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  UNIQUE(order_id)
);

CREATE TABLE IF NOT EXISTS public.dispute_messages (
  message_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_id UUID NOT NULL REFERENCES public.marketplace_disputes(dispute_id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  message_text TEXT NOT NULL,
  attachments JSONB DEFAULT '[]'::JSONB,
  sent_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.dispute_resolution_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  dispute_id UUID NOT NULL REFERENCES public.marketplace_disputes(dispute_id) ON DELETE CASCADE,
  action_type VARCHAR(50) NOT NULL,
  action_details JSONB,
  performed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  performed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 3. CREATOR SETTLEMENT & RECONCILIATION TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.settlement_records (
  settlement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  settlement_period_start DATE NOT NULL,
  settlement_period_end DATE NOT NULL,
  marketplace_earnings DECIMAL(10,2) DEFAULT 0.00,
  election_earnings DECIMAL(10,2) DEFAULT 0.00,
  ad_earnings DECIMAL(10,2) DEFAULT 0.00,
  total_earnings DECIMAL(10,2) NOT NULL,
  platform_fees DECIMAL(10,2) NOT NULL,
  payment_processing_fees DECIMAL(10,2) DEFAULT 0.00,
  net_amount DECIMAL(10,2) NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',
  exchange_rate DECIMAL(10,6),
  tax_withheld DECIMAL(10,2),
  status public.settlement_status DEFAULT 'pending'::public.settlement_status,
  stripe_transfer_id VARCHAR(100),
  settled_at TIMESTAMPTZ,
  arrived_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.reconciliation_discrepancies (
  discrepancy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  settlement_id UUID NOT NULL REFERENCES public.settlement_records(settlement_id) ON DELETE CASCADE,
  expected_amount DECIMAL(10,2) NOT NULL,
  actual_amount DECIMAL(10,2) NOT NULL,
  difference DECIMAL(10,2) NOT NULL,
  status public.discrepancy_status DEFAULT 'investigating'::public.discrepancy_status,
  resolution_notes TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.exchange_rates (
  rate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_currency VARCHAR(3) NOT NULL,
  to_currency VARCHAR(3) NOT NULL,
  rate DECIMAL(10,6) NOT NULL,
  effective_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(from_currency, to_currency, effective_date)
);

CREATE TABLE IF NOT EXISTS public.tax_documents (
  document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  document_type VARCHAR(20) NOT NULL CHECK (document_type IN ('W-9', '1099', 'W-8BEN', '1042-S')),
  tax_year INTEGER NOT NULL,
  document_url VARCHAR(500),
  total_earnings DECIMAL(10,2),
  breakdown JSONB,
  generated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  sent_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.settlement_schedule (
  schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  frequency VARCHAR(20) DEFAULT 'weekly' CHECK (frequency IN ('daily', 'weekly', 'bi-weekly', 'monthly')),
  minimum_payout_threshold DECIMAL(10,2) DEFAULT 10.00,
  next_settlement_date DATE,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_user_id)
);

-- =====================================================
-- 4. UNIFIED ANALYTICS DASHBOARD TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.analytics_snapshots (
  snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_date DATE NOT NULL,
  marketplace_orders_count INTEGER DEFAULT 0,
  marketplace_revenue DECIMAL(10,2) DEFAULT 0.00,
  groups_total_members INTEGER DEFAULT 0,
  groups_new_members INTEGER DEFAULT 0,
  groups_posts_count INTEGER DEFAULT 0,
  moderation_violations INTEGER DEFAULT 0,
  moderation_auto_removed INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(snapshot_date)
);

CREATE TABLE IF NOT EXISTS public.creator_performance_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  marketplace_orders INTEGER DEFAULT 0,
  marketplace_revenue DECIMAL(10,2) DEFAULT 0.00,
  avg_rating DECIMAL(3,2),
  response_time_hours DECIMAL(6,2),
  completion_rate DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_user_id, metric_date)
);

CREATE TABLE IF NOT EXISTS public.group_engagement_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.user_groups(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  member_count INTEGER DEFAULT 0,
  new_members INTEGER DEFAULT 0,
  post_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  engagement_rate DECIMAL(5,2),
  event_count INTEGER DEFAULT 0,
  event_attendance_rate DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(group_id, metric_date)
);

CREATE TABLE IF NOT EXISTS public.service_performance_metrics (
  metric_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES public.marketplace_services(id) ON DELETE CASCADE,
  metric_date DATE NOT NULL,
  views_count INTEGER DEFAULT 0,
  orders_count INTEGER DEFAULT 0,
  revenue DECIMAL(10,2) DEFAULT 0.00,
  avg_rating DECIMAL(3,2),
  conversion_rate DECIMAL(5,2),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(service_id, metric_date)
);

-- =====================================================
-- 5. INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_marketplace_disputes_order ON public.marketplace_disputes(order_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_disputes_status ON public.marketplace_disputes(status);
CREATE INDEX IF NOT EXISTS idx_dispute_messages_dispute ON public.dispute_messages(dispute_id);
CREATE INDEX IF NOT EXISTS idx_settlement_records_creator ON public.settlement_records(creator_user_id);
CREATE INDEX IF NOT EXISTS idx_settlement_records_status ON public.settlement_records(status);
CREATE INDEX IF NOT EXISTS idx_settlement_records_period ON public.settlement_records(settlement_period_start, settlement_period_end);
CREATE INDEX IF NOT EXISTS idx_analytics_snapshots_date ON public.analytics_snapshots(snapshot_date);
CREATE INDEX IF NOT EXISTS idx_creator_performance_date ON public.creator_performance_metrics(creator_user_id, metric_date);
CREATE INDEX IF NOT EXISTS idx_group_engagement_date ON public.group_engagement_metrics(group_id, metric_date);
CREATE INDEX IF NOT EXISTS idx_service_performance_date ON public.service_performance_metrics(service_id, metric_date);

-- =====================================================
-- 6. RLS POLICIES
-- =====================================================

-- Marketplace Disputes
ALTER TABLE public.marketplace_disputes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own disputes" ON public.marketplace_disputes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.marketplace_orders mo
      WHERE mo.order_id = marketplace_disputes.order_id
      AND (mo.buyer_user_id = auth.uid() OR mo.seller_user_id = auth.uid())
    )
  );

CREATE POLICY "Buyers and sellers can create disputes" ON public.marketplace_disputes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.marketplace_orders mo
      WHERE mo.order_id = marketplace_disputes.order_id
      AND (mo.buyer_user_id = auth.uid() OR mo.seller_user_id = auth.uid())
    )
  );

CREATE POLICY "Admins can view all disputes" ON public.marketplace_disputes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Dispute Messages
ALTER TABLE public.dispute_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view dispute messages" ON public.dispute_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.marketplace_disputes md
      JOIN public.marketplace_orders mo ON mo.order_id = md.order_id
      WHERE md.dispute_id = dispute_messages.dispute_id
      AND (mo.buyer_user_id = auth.uid() OR mo.seller_user_id = auth.uid())
    )
  );

CREATE POLICY "Users can send dispute messages" ON public.dispute_messages
  FOR INSERT WITH CHECK (sender_id = auth.uid());

-- Settlement Records
ALTER TABLE public.settlement_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their settlements" ON public.settlement_records
  FOR SELECT USING (creator_user_id = auth.uid());

CREATE POLICY "Admins can view all settlements" ON public.settlement_records
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
    )
  );

-- Analytics Snapshots (public read)
ALTER TABLE public.analytics_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view analytics snapshots" ON public.analytics_snapshots
  FOR SELECT USING (true);

-- Creator Performance Metrics
ALTER TABLE public.creator_performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their metrics" ON public.creator_performance_metrics
  FOR SELECT USING (creator_user_id = auth.uid());

-- Group Engagement Metrics
ALTER TABLE public.group_engagement_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Group members can view metrics" ON public.group_engagement_metrics
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.group_members
      WHERE group_id = group_engagement_metrics.group_id
      AND user_id = auth.uid()
    )
  );

-- =====================================================
-- 7. MATERIALIZED VIEWS FOR PERFORMANCE
-- =====================================================

CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_top_performing_services AS
SELECT 
  ms.id AS service_id,
  ms.title,
  ms.creator_id,
  COUNT(mo.order_id) AS total_orders,
  SUM(mo.total_amount) AS total_revenue,
  AVG(mo.total_amount) AS avg_order_value,
  COUNT(CASE WHEN mo.order_status = 'completed' THEN 1 END)::DECIMAL / NULLIF(COUNT(mo.order_id), 0) AS completion_rate
FROM public.marketplace_services ms
LEFT JOIN public.marketplace_orders mo ON mo.service_id = ms.id
GROUP BY ms.id, ms.title, ms.creator_id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_top_services_id ON public.mv_top_performing_services(service_id);

CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_group_health_scores AS
SELECT 
  ug.id AS group_id,
  ug.name,
  COUNT(DISTINCT gm.user_id) AS member_count,
  COUNT(DISTINCT gp.post_id) AS post_count,
  AVG(gem.engagement_rate) AS avg_engagement_rate,
  CASE 
    WHEN AVG(gem.engagement_rate) > 50 THEN 'healthy'
    WHEN AVG(gem.engagement_rate) > 25 THEN 'needs_attention'
    ELSE 'declining'
  END AS health_status
FROM public.user_groups ug
LEFT JOIN public.group_members gm ON gm.group_id = ug.id
LEFT JOIN public.group_posts gp ON gp.group_id = ug.id AND gp.created_at > CURRENT_DATE - INTERVAL '30 days'
LEFT JOIN public.group_engagement_metrics gem ON gem.group_id = ug.id AND gem.metric_date > CURRENT_DATE - INTERVAL '30 days'
GROUP BY ug.id, ug.name;

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_group_health_id ON public.mv_group_health_scores(group_id);

-- =====================================================
-- 8. FUNCTIONS
-- =====================================================

-- Function to calculate settlement amounts
CREATE OR REPLACE FUNCTION public.calculate_settlement_amount(
  p_creator_id UUID,
  p_start_date DATE,
  p_end_date DATE
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_marketplace_earnings DECIMAL(10,2);
  v_election_earnings DECIMAL(10,2);
  v_ad_earnings DECIMAL(10,2);
  v_total_earnings DECIMAL(10,2);
  v_platform_fees DECIMAL(10,2);
  v_net_amount DECIMAL(10,2);
BEGIN
  -- Calculate marketplace earnings
  SELECT COALESCE(SUM(mo.total_amount * 0.9), 0) INTO v_marketplace_earnings
  FROM public.marketplace_orders mo
  WHERE mo.seller_user_id = p_creator_id
  AND mo.order_status = 'completed'
  AND mo.delivered_at BETWEEN p_start_date AND p_end_date;

  -- Calculate election earnings (placeholder - would integrate with election_payouts)
  v_election_earnings := 0;

  -- Calculate ad earnings (placeholder - would integrate with ad_revenue)
  v_ad_earnings := 0;

  v_total_earnings := v_marketplace_earnings + v_election_earnings + v_ad_earnings;
  v_platform_fees := v_total_earnings * 0.1;
  v_net_amount := v_total_earnings - v_platform_fees;

  RETURN jsonb_build_object(
    'marketplace_earnings', v_marketplace_earnings,
    'election_earnings', v_election_earnings,
    'ad_earnings', v_ad_earnings,
    'total_earnings', v_total_earnings,
    'platform_fees', v_platform_fees,
    'net_amount', v_net_amount
  );
END;
$$;

-- Function to refresh analytics snapshots
CREATE OR REPLACE FUNCTION public.refresh_analytics_snapshot(p_date DATE)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.analytics_snapshots (
    snapshot_date,
    marketplace_orders_count,
    marketplace_revenue,
    groups_total_members,
    groups_new_members,
    groups_posts_count,
    moderation_violations,
    moderation_auto_removed
  )
  SELECT
    p_date,
    (SELECT COUNT(*) FROM public.marketplace_orders WHERE DATE(ordered_at) = p_date),
    (SELECT COALESCE(SUM(total_amount), 0) FROM public.marketplace_orders WHERE DATE(ordered_at) = p_date),
    (SELECT COUNT(*) FROM public.group_members),
    (SELECT COUNT(*) FROM public.group_members WHERE DATE(joined_at) = p_date),
    (SELECT COUNT(*) FROM public.group_posts WHERE DATE(created_at) = p_date),
    (SELECT COUNT(*) FROM public.moderation_log WHERE DATE(created_at) = p_date AND is_safe = false),
    (SELECT COUNT(*) FROM public.moderation_log WHERE DATE(created_at) = p_date AND removed_automatically = true)
  ON CONFLICT (snapshot_date) DO UPDATE SET
    marketplace_orders_count = EXCLUDED.marketplace_orders_count,
    marketplace_revenue = EXCLUDED.marketplace_revenue,
    groups_total_members = EXCLUDED.groups_total_members,
    groups_new_members = EXCLUDED.groups_new_members,
    groups_posts_count = EXCLUDED.groups_posts_count,
    moderation_violations = EXCLUDED.moderation_violations,
    moderation_auto_removed = EXCLUDED.moderation_auto_removed,
    updated_at = CURRENT_TIMESTAMP;
END;
$$;