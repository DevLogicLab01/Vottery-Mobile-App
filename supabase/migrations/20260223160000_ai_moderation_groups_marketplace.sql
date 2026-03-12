-- AI Content Moderation + Complete Groups Hub + Creator Marketplace
-- Comprehensive platform features with Claude integration, group management, and marketplace escrow

-- =====================================================
-- 1. TYPES (with idempotency)
-- =====================================================

DROP TYPE IF EXISTS public.moderation_action CASCADE;
CREATE TYPE public.moderation_action AS ENUM ('pending_review', 'approved', 'removed', 'flagged', 'escalated');

DROP TYPE IF EXISTS public.violation_category CASCADE;
CREATE TYPE public.violation_category AS ENUM ('hate_speech', 'harassment', 'violence', 'sexual_content', 'spam', 'misinformation', 'copyright_infringement', 'minor_safety');

DROP TYPE IF EXISTS public.violation_severity CASCADE;
CREATE TYPE public.violation_severity AS ENUM ('low', 'medium', 'high', 'critical');

DROP TYPE IF EXISTS public.appeal_status CASCADE;
CREATE TYPE public.appeal_status AS ENUM ('pending', 'approved', 'denied', 'escalated');

DROP TYPE IF EXISTS public.group_role CASCADE;
CREATE TYPE public.group_role AS ENUM ('admin', 'moderator', 'member');

DROP TYPE IF EXISTS public.rsvp_status CASCADE;
CREATE TYPE public.rsvp_status AS ENUM ('going', 'maybe', 'not_going');

DROP TYPE IF EXISTS public.order_status CASCADE;
CREATE TYPE public.order_status AS ENUM ('pending', 'in_progress', 'revision', 'completed', 'cancelled', 'disputed');

DROP TYPE IF EXISTS public.escrow_status CASCADE;
CREATE TYPE public.escrow_status AS ENUM ('held', 'released', 'refunded');

-- =====================================================
-- 2. AI CONTENT MODERATION TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.moderation_config (
  config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_type VARCHAR(50) NOT NULL,
  violation_category public.violation_category NOT NULL,
  confidence_threshold DECIMAL(3,2) NOT NULL DEFAULT 0.70,
  auto_remove_enabled BOOLEAN DEFAULT false,
  notification_template VARCHAR(500),
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(content_type, violation_category)
);

CREATE TABLE IF NOT EXISTS public.moderation_log (
  log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL,
  content_text TEXT,
  media_urls JSONB DEFAULT '[]'::JSONB,
  violation_categories JSONB DEFAULT '[]'::JSONB,
  is_safe BOOLEAN DEFAULT true,
  confidence_score DECIMAL(3,2),
  action_taken public.moderation_action DEFAULT 'pending_review'::public.moderation_action,
  removed_automatically BOOLEAN DEFAULT false,
  moderated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  moderated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  claude_reasoning TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.moderation_reviews (
  review_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL,
  content_type VARCHAR(50) NOT NULL,
  status public.moderation_action DEFAULT 'pending_review'::public.moderation_action,
  assigned_to UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  assigned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMPTZ,
  reviewer_decision VARCHAR(50),
  reviewer_notes TEXT
);

CREATE TABLE IF NOT EXISTS public.content_appeals (
  appeal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id UUID NOT NULL,
  appellant_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  appeal_reason TEXT NOT NULL,
  evidence_urls JSONB DEFAULT '[]'::JSONB,
  status public.appeal_status DEFAULT 'pending'::public.appeal_status,
  submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  reviewed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  resolution_notes TEXT
);

CREATE TABLE IF NOT EXISTS public.user_moderation_history (
  history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  violation_type public.violation_category NOT NULL,
  action_taken VARCHAR(50) NOT NULL,
  duration_days INTEGER,
  expires_at TIMESTAMPTZ,
  actioned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  actioned_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL
);

-- =====================================================
-- 3. GROUPS HUB ENHANCEMENT TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.group_role_permissions (
  permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.user_groups(id) ON DELETE CASCADE,
  role public.group_role NOT NULL,
  permission_name VARCHAR(100) NOT NULL,
  is_enabled BOOLEAN DEFAULT true,
  UNIQUE(group_id, role, permission_name)
);

CREATE TABLE IF NOT EXISTS public.group_events (
  event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.user_groups(id) ON DELETE CASCADE,
  creator_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  event_datetime TIMESTAMPTZ NOT NULL,
  location VARCHAR(200),
  max_attendees INTEGER,
  rsvp_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.event_rsvps (
  rsvp_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.group_events(event_id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  rsvp_status public.rsvp_status DEFAULT 'going'::public.rsvp_status,
  responded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(event_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.group_bans (
  ban_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.user_groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  banned_by UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  ban_reason TEXT NOT NULL,
  ban_duration VARCHAR(20) NOT NULL,
  expires_at TIMESTAMPTZ,
  banned_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(group_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.group_analytics_snapshots (
  snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.user_groups(id) ON DELETE CASCADE,
  snapshot_date DATE NOT NULL,
  member_count INTEGER DEFAULT 0,
  active_member_count INTEGER DEFAULT 0,
  post_count INTEGER DEFAULT 0,
  comment_count INTEGER DEFAULT 0,
  engagement_rate DECIMAL(5,2) DEFAULT 0.00,
  UNIQUE(group_id, snapshot_date)
);

CREATE TABLE IF NOT EXISTS public.group_posts (
  post_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES public.user_groups(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  media_urls JSONB DEFAULT '[]'::JSONB,
  approval_status VARCHAR(20) DEFAULT 'approved',
  approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- 4. CREATOR MARKETPLACE ENHANCEMENT TABLES
-- =====================================================

CREATE TABLE IF NOT EXISTS public.marketplace_orders (
  order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id UUID NOT NULL REFERENCES public.marketplace_services(id) ON DELETE CASCADE,
  buyer_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  seller_user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  tier_selected VARCHAR(50) NOT NULL,
  requirements_data JSONB DEFAULT '{}'::JSONB,
  delivery_date DATE,
  order_status public.order_status DEFAULT 'pending'::public.order_status,
  total_amount DECIMAL(10,2) NOT NULL,
  service_fee DECIMAL(10,2) NOT NULL,
  ordered_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  started_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.order_deliverables (
  deliverable_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.marketplace_orders(order_id) ON DELETE CASCADE,
  file_url VARCHAR(500) NOT NULL,
  file_name VARCHAR(200) NOT NULL,
  file_size INTEGER,
  delivery_notes TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.escrow_holds (
  hold_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.marketplace_orders(order_id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL,
  status public.escrow_status DEFAULT 'held'::public.escrow_status,
  held_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  released_at TIMESTAMPTZ
);

-- =====================================================
-- 5. INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_moderation_log_content_id ON public.moderation_log(content_id);
CREATE INDEX IF NOT EXISTS idx_moderation_log_action ON public.moderation_log(action_taken);
CREATE INDEX IF NOT EXISTS idx_moderation_reviews_status ON public.moderation_reviews(status);
CREATE INDEX IF NOT EXISTS idx_content_appeals_status ON public.content_appeals(status);
CREATE INDEX IF NOT EXISTS idx_user_moderation_history_user_id ON public.user_moderation_history(user_id);

CREATE INDEX IF NOT EXISTS idx_group_events_group_id ON public.group_events(group_id);
CREATE INDEX IF NOT EXISTS idx_event_rsvps_event_id ON public.event_rsvps(event_id);
CREATE INDEX IF NOT EXISTS idx_group_bans_group_id ON public.group_bans(group_id);
CREATE INDEX IF NOT EXISTS idx_group_posts_group_id ON public.group_posts(group_id);
CREATE INDEX IF NOT EXISTS idx_group_posts_approval_status ON public.group_posts(approval_status);

CREATE INDEX IF NOT EXISTS idx_marketplace_orders_buyer ON public.marketplace_orders(buyer_user_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_orders_seller ON public.marketplace_orders(seller_user_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_orders_status ON public.marketplace_orders(order_status);
CREATE INDEX IF NOT EXISTS idx_escrow_holds_order_id ON public.escrow_holds(order_id);

-- =====================================================
-- 6. ENABLE RLS
-- =====================================================

ALTER TABLE public.moderation_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_appeals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_moderation_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_rsvps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_bans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_analytics_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_deliverables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.escrow_holds ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 7. RLS POLICIES
-- =====================================================

-- Moderation Config (admin only)
DROP POLICY IF EXISTS "admin_manage_moderation_config" ON public.moderation_config;
CREATE POLICY "admin_manage_moderation_config" ON public.moderation_config
FOR ALL TO authenticated
USING (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND (raw_user_meta_data->>'role' = 'admin' OR raw_app_meta_data->>'role' = 'admin')))
WITH CHECK (EXISTS (SELECT 1 FROM auth.users WHERE id = auth.uid() AND (raw_user_meta_data->>'role' = 'admin' OR raw_app_meta_data->>'role' = 'admin')));

-- Moderation Log (moderators and admins)
DROP POLICY IF EXISTS "moderators_view_moderation_log" ON public.moderation_log;
CREATE POLICY "moderators_view_moderation_log" ON public.moderation_log
FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "moderators_manage_moderation_log" ON public.moderation_log;
CREATE POLICY "moderators_manage_moderation_log" ON public.moderation_log
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- Content Appeals (users manage own)
DROP POLICY IF EXISTS "users_manage_own_appeals" ON public.content_appeals;
CREATE POLICY "users_manage_own_appeals" ON public.content_appeals
FOR ALL TO authenticated
USING (appellant_user_id = auth.uid())
WITH CHECK (appellant_user_id = auth.uid());

-- Group Events (group members can view, creators can manage)
DROP POLICY IF EXISTS "members_view_group_events" ON public.group_events;
CREATE POLICY "members_view_group_events" ON public.group_events
FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.group_members WHERE group_id = group_events.group_id AND user_id = auth.uid()));

DROP POLICY IF EXISTS "creators_manage_group_events" ON public.group_events;
CREATE POLICY "creators_manage_group_events" ON public.group_events
FOR ALL TO authenticated
USING (creator_user_id = auth.uid())
WITH CHECK (creator_user_id = auth.uid());

-- Event RSVPs (users manage own)
DROP POLICY IF EXISTS "users_manage_own_rsvps" ON public.event_rsvps;
CREATE POLICY "users_manage_own_rsvps" ON public.event_rsvps
FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Group Posts (members can view, authors manage own)
DROP POLICY IF EXISTS "members_view_group_posts" ON public.group_posts;
CREATE POLICY "members_view_group_posts" ON public.group_posts
FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.group_members WHERE group_id = group_posts.group_id AND user_id = auth.uid()));

DROP POLICY IF EXISTS "authors_manage_own_posts" ON public.group_posts;
CREATE POLICY "authors_manage_own_posts" ON public.group_posts
FOR ALL TO authenticated
USING (author_id = auth.uid())
WITH CHECK (author_id = auth.uid());

-- Marketplace Orders (buyers and sellers can view own)
DROP POLICY IF EXISTS "users_view_own_orders" ON public.marketplace_orders;
CREATE POLICY "users_view_own_orders" ON public.marketplace_orders
FOR SELECT TO authenticated
USING (buyer_user_id = auth.uid() OR seller_user_id = auth.uid());

DROP POLICY IF EXISTS "buyers_create_orders" ON public.marketplace_orders;
CREATE POLICY "buyers_create_orders" ON public.marketplace_orders
FOR INSERT TO authenticated
WITH CHECK (buyer_user_id = auth.uid());

DROP POLICY IF EXISTS "participants_update_orders" ON public.marketplace_orders;
CREATE POLICY "participants_update_orders" ON public.marketplace_orders
FOR UPDATE TO authenticated
USING (buyer_user_id = auth.uid() OR seller_user_id = auth.uid())
WITH CHECK (buyer_user_id = auth.uid() OR seller_user_id = auth.uid());

-- Order Deliverables (order participants can view)
DROP POLICY IF EXISTS "order_participants_view_deliverables" ON public.order_deliverables;
CREATE POLICY "order_participants_view_deliverables" ON public.order_deliverables
FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.marketplace_orders WHERE order_id = order_deliverables.order_id AND (buyer_user_id = auth.uid() OR seller_user_id = auth.uid())));

DROP POLICY IF EXISTS "sellers_upload_deliverables" ON public.order_deliverables;
CREATE POLICY "sellers_upload_deliverables" ON public.order_deliverables
FOR INSERT TO authenticated
WITH CHECK (EXISTS (SELECT 1 FROM public.marketplace_orders WHERE order_id = order_deliverables.order_id AND seller_user_id = auth.uid()));

-- Escrow Holds (order participants can view)
DROP POLICY IF EXISTS "order_participants_view_escrow" ON public.escrow_holds;
CREATE POLICY "order_participants_view_escrow" ON public.escrow_holds
FOR SELECT TO authenticated
USING (EXISTS (SELECT 1 FROM public.marketplace_orders WHERE order_id = escrow_holds.order_id AND (buyer_user_id = auth.uid() OR seller_user_id = auth.uid())));

-- =====================================================
-- 8. MOCK DATA
-- =====================================================

DO $$
DECLARE
  existing_user_id UUID;
  existing_group_id UUID;
  existing_service_id UUID;
  test_event_id UUID := gen_random_uuid();
  test_order_id UUID := gen_random_uuid();
BEGIN
  -- Get existing user
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_profiles') THEN
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
    
    IF existing_user_id IS NOT NULL THEN
      -- Moderation Config
      INSERT INTO public.moderation_config (content_type, violation_category, confidence_threshold, auto_remove_enabled)
      VALUES 
        ('post', 'hate_speech'::public.violation_category, 0.60, true),
        ('comment', 'harassment'::public.violation_category, 0.70, true),
        ('jolt', 'violence'::public.violation_category, 0.65, true)
      ON CONFLICT (content_type, violation_category) DO NOTHING;
      
      -- Get existing group
      IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'user_groups') THEN
        SELECT id INTO existing_group_id FROM public.user_groups LIMIT 1;
        
        IF existing_group_id IS NOT NULL THEN
          -- Group Events
          INSERT INTO public.group_events (event_id, group_id, creator_user_id, title, description, event_datetime, location)
          VALUES 
            (test_event_id, existing_group_id, existing_user_id, 'Community Town Hall', 'Discuss upcoming local elections', NOW() + INTERVAL '7 days', 'Virtual')
          ON CONFLICT (event_id) DO NOTHING;
          
          -- Event RSVPs
          INSERT INTO public.event_rsvps (event_id, user_id, rsvp_status)
          VALUES (test_event_id, existing_user_id, 'going'::public.rsvp_status)
          ON CONFLICT (event_id, user_id) DO NOTHING;
        END IF;
      END IF;
      
      -- Get existing marketplace service
      IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'marketplace_services') THEN
        SELECT id INTO existing_service_id FROM public.marketplace_services LIMIT 1;
        
        IF existing_service_id IS NOT NULL THEN
          -- Marketplace Orders
          INSERT INTO public.marketplace_orders (order_id, service_id, buyer_user_id, seller_user_id, tier_selected, total_amount, service_fee)
          VALUES (test_order_id, existing_service_id, existing_user_id, existing_user_id, 'Standard', 500.00, 75.00)
          ON CONFLICT (order_id) DO NOTHING;
          
          -- Escrow Holds
          INSERT INTO public.escrow_holds (order_id, amount, status)
          VALUES (test_order_id, 500.00, 'held'::public.escrow_status)
          ON CONFLICT DO NOTHING;
        END IF;
      END IF;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;