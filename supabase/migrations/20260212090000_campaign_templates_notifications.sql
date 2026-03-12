-- Campaign Templates and Unified Notifications Migration
-- Timestamp: 20260212090000
-- Description: Campaign template gallery and unified notification center hub

-- ============================================================
-- 1. CAMPAIGN TEMPLATES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.campaign_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  category public.sponsored_election_type NOT NULL,
  industry_tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  thumbnail_url TEXT,
  sample_questions TEXT[] DEFAULT ARRAY[]::TEXT[],
  targeting_parameters JSONB DEFAULT '{}'::jsonb,
  default_configuration JSONB DEFAULT '{}'::jsonb,
  success_rate NUMERIC(5,2) DEFAULT 0.00,
  avg_roi NUMERIC(8,2) DEFAULT 0.00,
  avg_engagement NUMERIC(5,2) DEFAULT 0.00,
  usage_count INTEGER DEFAULT 0,
  community_rating NUMERIC(3,2) DEFAULT 0.00,
  is_featured BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_campaign_templates_category ON public.campaign_templates(category);
CREATE INDEX IF NOT EXISTS idx_campaign_templates_featured ON public.campaign_templates(is_featured);
CREATE INDEX IF NOT EXISTS idx_campaign_templates_active ON public.campaign_templates(is_active);
CREATE INDEX IF NOT EXISTS idx_campaign_templates_usage ON public.campaign_templates(usage_count DESC);

-- ============================================================
-- 2. TEMPLATE FAVORITES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.template_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  template_id UUID NOT NULL REFERENCES public.campaign_templates(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, template_id)
);

CREATE INDEX IF NOT EXISTS idx_template_favorites_user ON public.template_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_template_favorites_template ON public.template_favorites(template_id);

-- ============================================================
-- 3. UNIFIED NOTIFICATIONS TABLE
-- ============================================================

DO $$ BEGIN
  CREATE TYPE public.notification_type AS ENUM (
    'votes',
    'messages',
    'achievements',
    'elections',
    'campaigns'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.notification_priority AS ENUM (
    'low',
    'normal',
    'high',
    'urgent'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.unified_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  notification_type public.notification_type NOT NULL,
  priority public.notification_priority DEFAULT 'normal',
  title TEXT NOT NULL,
  body TEXT,
  reference_id UUID,
  reference_type TEXT,
  action_url TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_unified_notifications_user ON public.unified_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_unified_notifications_type ON public.unified_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_unified_notifications_unread ON public.unified_notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_unified_notifications_created ON public.unified_notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_unified_notifications_priority ON public.unified_notifications(priority);

-- ============================================================
-- 4. RLS POLICIES
-- ============================================================

ALTER TABLE public.campaign_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.template_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unified_notifications ENABLE ROW LEVEL SECURITY;

-- Campaign Templates Policies
DROP POLICY IF EXISTS "Public can view active templates" ON public.campaign_templates;
CREATE POLICY "Public can view active templates"
  ON public.campaign_templates
  FOR SELECT
  USING (is_active = true);

DROP POLICY IF EXISTS "Creators can manage their templates" ON public.campaign_templates;
CREATE POLICY "Creators can manage their templates"
  ON public.campaign_templates
  FOR ALL
  USING (auth.uid() = created_by);

-- Template Favorites Policies
DROP POLICY IF EXISTS "Users can manage their favorites" ON public.template_favorites;
CREATE POLICY "Users can manage their favorites"
  ON public.template_favorites
  FOR ALL
  USING (auth.uid() = user_id);

-- Unified Notifications Policies
DROP POLICY IF EXISTS "Users can view their notifications" ON public.unified_notifications;
CREATE POLICY "Users can view their notifications"
  ON public.unified_notifications
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their notifications" ON public.unified_notifications;
CREATE POLICY "Users can update their notifications"
  ON public.unified_notifications
  FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their notifications" ON public.unified_notifications;
CREATE POLICY "Users can delete their notifications"
  ON public.unified_notifications
  FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================
-- 5. MOCK DATA - CAMPAIGN TEMPLATES
-- ============================================================

INSERT INTO public.campaign_templates (name, description, category, industry_tags, sample_questions, targeting_parameters, default_configuration, success_rate, avg_roi, avg_engagement, usage_count, community_rating, is_featured)
VALUES
  (
    'Tech Product Launch Survey',
    'Gather market feedback on new tech product features and pricing',
    'market_research',
    ARRAY['tech', 'retail'],
    ARRAY['Which feature interests you most?', 'What price point is acceptable?', 'Would you recommend this to others?'],
    '{"age_min": 18, "age_max": 45, "zones": ["zone_1_us_canada", "zone_2_western_europe"], "estimated_reach": 50000}',
    '{"budget": 5000, "duration_days": 14, "double_xp": true}',
    78.5,
    145.2,
    62.3,
    342,
    4.6,
    true
  ),
  (
    'Healthcare Awareness Campaign',
    'Educate and gather opinions on healthcare initiatives',
    'csr_vote',
    ARRAY['healthcare', 'nonprofit'],
    ARRAY['How important is mental health support?', 'Would you participate in wellness programs?'],
    '{"age_min": 25, "age_max": 65, "zones": ["zone_1_us_canada", "zone_2_western_europe", "zone_7_australasia_advanced_asia"], "estimated_reach": 75000}',
    '{"budget": 8000, "duration_days": 21, "double_xp": true}',
    82.1,
    168.5,
    71.2,
    567,
    4.8,
    true
  ),
  (
    'Movie Hype Prediction',
    'Predict box office success and audience interest',
    'hype_prediction',
    ARRAY['entertainment', 'retail'],
    ARRAY['Will this movie be a blockbuster?', 'Which actor will win best performance?'],
    '{"age_min": 16, "age_max": 50, "zones": ["zone_1_us_canada", "zone_2_western_europe", "zone_8_china_hong_kong_macau"], "estimated_reach": 100000}',
    '{"budget": 12000, "duration_days": 30, "double_xp": true}',
    85.3,
    192.7,
    78.9,
    891,
    4.9,
    true
  ),
  (
    'Financial Services Feedback',
    'Collect user feedback on banking app features',
    'product_feedback',
    ARRAY['finance', 'tech'],
    ARRAY['How satisfied are you with mobile banking?', 'What features would you like added?'],
    '{"age_min": 22, "age_max": 60, "zones": ["zone_1_us_canada", "zone_2_western_europe", "zone_3_eastern_europe_russia"], "estimated_reach": 60000}',
    '{"budget": 7000, "duration_days": 18, "double_xp": true}',
    76.8,
    138.4,
    65.7,
    423,
    4.5,
    false
  ),
  (
    'Retail Brand Awareness',
    'Increase brand visibility and measure recognition',
    'brand_awareness',
    ARRAY['retail', 'entertainment'],
    ARRAY['Have you heard of our brand?', 'What do you associate with our products?'],
    '{"age_min": 18, "age_max": 55, "zones": ["zone_1_us_canada", "zone_4_africa", "zone_5_latin_america_caribbean"], "estimated_reach": 80000}',
    '{"budget": 9000, "duration_days": 25, "double_xp": true}',
    79.2,
    156.3,
    68.5,
    634,
    4.7,
    true
  ),
  (
    'Education Platform Survey',
    'Gather feedback on online learning experiences',
    'market_research',
    ARRAY['education', 'tech'],
    ARRAY['How effective is online learning?', 'What improvements would you suggest?'],
    '{"age_min": 16, "age_max": 40, "zones": ["zone_1_us_canada", "zone_6_middle_east_asia", "zone_7_australasia_advanced_asia"], "estimated_reach": 55000}',
    '{"budget": 6000, "duration_days": 20, "double_xp": true}',
    74.5,
    132.8,
    63.1,
    389,
    4.4,
    false
  );

-- ============================================================
-- 6. MOCK DATA - UNIFIED NOTIFICATIONS
-- ============================================================

-- Note: Mock notifications will be created dynamically based on user activity
-- This is a placeholder for the notification system structure

-- ============================================================
-- 7. FUNCTIONS
-- ============================================================

-- Function to create notification
CREATE OR REPLACE FUNCTION public.create_unified_notification(
  p_user_id UUID,
  p_type public.notification_type,
  p_title TEXT,
  p_body TEXT,
  p_priority public.notification_priority DEFAULT 'normal',
  p_reference_id UUID DEFAULT NULL,
  p_reference_type TEXT DEFAULT NULL,
  p_action_url TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO public.unified_notifications (
    user_id,
    notification_type,
    priority,
    title,
    body,
    reference_id,
    reference_type,
    action_url,
    metadata
  )
  VALUES (
    p_user_id,
    p_type,
    p_priority,
    p_title,
    p_body,
    p_reference_id,
    p_reference_type,
    p_action_url,
    p_metadata
  )
  RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$;

-- ============================================================
-- 8. TRIGGERS
-- ============================================================

-- Update updated_at timestamp for campaign_templates
CREATE OR REPLACE FUNCTION public.update_campaign_template_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_campaign_template_timestamp ON public.campaign_templates;
CREATE TRIGGER trigger_update_campaign_template_timestamp
  BEFORE UPDATE ON public.campaign_templates
  FOR EACH ROW
  EXECUTE FUNCTION public.update_campaign_template_timestamp();

-- Update read_at timestamp when notification is marked as read
CREATE OR REPLACE FUNCTION public.update_notification_read_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.is_read = true AND OLD.is_read = false THEN
    NEW.read_at = CURRENT_TIMESTAMP;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_notification_read_timestamp ON public.unified_notifications;
CREATE TRIGGER trigger_update_notification_read_timestamp
  BEFORE UPDATE ON public.unified_notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.update_notification_read_timestamp();
