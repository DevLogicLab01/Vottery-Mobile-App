-- Brand Partnership Hub Migration
-- Timestamp: 20260206010000
-- Description: Brand partnerships, campaign applications, verification, and history tracking

-- ============================================================
-- 1. TYPES
-- ============================================================

DROP TYPE IF EXISTS public.campaign_status CASCADE;
CREATE TYPE public.campaign_status AS ENUM (
  'draft',
  'open',
  'in_progress',
  'completed',
  'cancelled'
);

DROP TYPE IF EXISTS public.application_status CASCADE;
CREATE TYPE public.application_status AS ENUM (
  'pending',
  'under_review',
  'accepted',
  'rejected',
  'withdrawn'
);

DROP TYPE IF EXISTS public.brand_verification_status CASCADE;
CREATE TYPE public.brand_verification_status AS ENUM (
  'unverified',
  'pending',
  'verified',
  'rejected'
);

DROP TYPE IF EXISTS public.partnership_tier CASCADE;
CREATE TYPE public.partnership_tier AS ENUM (
  'bronze',
  'silver',
  'gold',
  'platinum'
);

-- ============================================================
-- 2. BRAND PARTNERSHIPS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.brand_partnerships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  campaign_name TEXT NOT NULL,
  campaign_description TEXT,
  campaign_objectives JSONB DEFAULT '[]'::jsonb,
  participation_requirements JSONB DEFAULT '[]'::jsonb,
  revenue_potential NUMERIC(12,2) DEFAULT 0.00,
  budget NUMERIC(12,2) DEFAULT 0.00,
  spent NUMERIC(12,2) DEFAULT 0.00,
  status public.campaign_status DEFAULT 'draft',
  application_deadline TIMESTAMPTZ,
  campaign_start_date TIMESTAMPTZ,
  campaign_end_date TIMESTAMPTZ,
  target_creators INTEGER DEFAULT 0,
  accepted_creators INTEGER DEFAULT 0,
  content_approval_required BOOLEAN DEFAULT true,
  performance_metrics JSONB DEFAULT '{}'::jsonb,
  targeting_criteria JSONB DEFAULT '{}'::jsonb,
  brand_logo_url TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_brand_partnerships_brand ON public.brand_partnerships(brand_id);
CREATE INDEX idx_brand_partnerships_status ON public.brand_partnerships(status);
CREATE INDEX idx_brand_partnerships_deadline ON public.brand_partnerships(application_deadline);

-- ============================================================
-- 3. CAMPAIGN APPLICATIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.campaign_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.brand_partnerships(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  application_status public.application_status DEFAULT 'pending',
  portfolio_submission JSONB DEFAULT '[]'::jsonb,
  audience_demographics JSONB DEFAULT '{}'::jsonb,
  collaboration_proposal TEXT,
  expected_reach INTEGER DEFAULT 0,
  expected_engagement_rate NUMERIC(5,2) DEFAULT 0.00,
  proposed_content_plan JSONB DEFAULT '[]'::jsonb,
  reviewed_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(campaign_id, creator_id)
);

CREATE INDEX idx_campaign_applications_campaign ON public.campaign_applications(campaign_id);
CREATE INDEX idx_campaign_applications_creator ON public.campaign_applications(creator_id);
CREATE INDEX idx_campaign_applications_status ON public.campaign_applications(application_status);

-- ============================================================
-- 4. BRAND VERIFICATION TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.brand_verification (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  verification_status public.brand_verification_status DEFAULT 'unverified',
  company_name TEXT NOT NULL,
  business_registration_number TEXT,
  tax_id TEXT,
  website_url TEXT,
  verification_documents JSONB DEFAULT '[]'::jsonb,
  trust_score NUMERIC(3,2) DEFAULT 0.00,
  partnership_history_count INTEGER DEFAULT 0,
  creator_reviews JSONB DEFAULT '[]'::jsonb,
  average_rating NUMERIC(3,2) DEFAULT 0.00,
  verified_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  verified_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(brand_id)
);

CREATE INDEX idx_brand_verification_brand ON public.brand_verification(brand_id);
CREATE INDEX idx_brand_verification_status ON public.brand_verification(verification_status);

-- ============================================================
-- 5. PARTNERSHIP HISTORY TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.partnership_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.brand_partnerships(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  brand_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  partnership_tier public.partnership_tier DEFAULT 'bronze',
  total_earnings NUMERIC(12,2) DEFAULT 0.00,
  content_delivered INTEGER DEFAULT 0,
  content_approved INTEGER DEFAULT 0,
  total_reach INTEGER DEFAULT 0,
  total_engagement INTEGER DEFAULT 0,
  engagement_rate NUMERIC(5,2) DEFAULT 0.00,
  performance_rating NUMERIC(3,2) DEFAULT 0.00,
  creator_review TEXT,
  creator_rating NUMERIC(3,2) DEFAULT 0.00,
  brand_review TEXT,
  brand_rating NUMERIC(3,2) DEFAULT 0.00,
  payment_status TEXT DEFAULT 'pending',
  payment_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_partnership_history_campaign ON public.partnership_history(campaign_id);
CREATE INDEX idx_partnership_history_creator ON public.partnership_history(creator_id);
CREATE INDEX idx_partnership_history_brand ON public.partnership_history(brand_id);
CREATE INDEX idx_partnership_history_completed ON public.partnership_history(completed_at DESC);

-- ============================================================
-- 6. RLS POLICIES
-- ============================================================

-- Brand Partnerships Policies
ALTER TABLE public.brand_partnerships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Brands can manage their own campaigns"
  ON public.brand_partnerships
  FOR ALL
  USING (auth.uid() = brand_id);

CREATE POLICY "Creators can view open campaigns"
  ON public.brand_partnerships
  FOR SELECT
  USING (status = 'open');

-- Campaign Applications Policies
ALTER TABLE public.campaign_applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can manage their own applications"
  ON public.campaign_applications
  FOR ALL
  USING (auth.uid() = creator_id);

CREATE POLICY "Brands can view applications to their campaigns"
  ON public.campaign_applications
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.brand_partnerships
      WHERE brand_partnerships.id = campaign_applications.campaign_id
      AND brand_partnerships.brand_id = auth.uid()
    )
  );

-- Brand Verification Policies
ALTER TABLE public.brand_verification ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Brands can view their own verification"
  ON public.brand_verification
  FOR SELECT
  USING (auth.uid() = brand_id);

CREATE POLICY "Creators can view verified brands"
  ON public.brand_verification
  FOR SELECT
  USING (verification_status = 'verified');

-- Partnership History Policies
ALTER TABLE public.partnership_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can view their own partnership history"
  ON public.partnership_history
  FOR SELECT
  USING (auth.uid() = creator_id);

CREATE POLICY "Brands can view their partnership history"
  ON public.partnership_history
  FOR SELECT
  USING (auth.uid() = brand_id);

-- ============================================================
-- 7. MOCK DATA
-- ============================================================

-- Insert mock brand partnerships
DO $$
DECLARE
  brand_user_id UUID;
  creator_user_id UUID;
  selected_campaign_id UUID;
BEGIN
  -- Get first user as brand
  SELECT id INTO brand_user_id FROM public.user_profiles LIMIT 1;
  
  -- Get second user as creator (if exists)
  SELECT id INTO creator_user_id FROM public.user_profiles OFFSET 1 LIMIT 1;
  
  IF brand_user_id IS NOT NULL THEN
    -- Insert brand verification
    INSERT INTO public.brand_verification (
      brand_id,
      verification_status,
      company_name,
      business_registration_number,
      website_url,
      trust_score,
      partnership_history_count,
      average_rating
    ) VALUES (
      brand_user_id,
      'verified',
      'TechCorp Industries',
      'BR-2024-12345',
      'https://techcorp.example.com',
      4.8,
      15,
      4.7
    ) ON CONFLICT (brand_id) DO NOTHING;

    -- Insert brand partnerships
    INSERT INTO public.brand_partnerships (
      id,
      brand_id,
      campaign_name,
      campaign_description,
      campaign_objectives,
      revenue_potential,
      budget,
      spent,
      status,
      application_deadline,
      campaign_start_date,
      campaign_end_date,
      target_creators,
      accepted_creators,
      performance_metrics
    ) VALUES 
    (
      gen_random_uuid(),
      brand_user_id,
      'Summer Product Launch 2026',
      'Promote our new eco-friendly product line through engaging Jolts content',
      '["Brand awareness", "Product education", "Drive sales"]'::jsonb,
      50000.00,
      30000.00,
      12500.00,
      'open',
      CURRENT_TIMESTAMP + INTERVAL '14 days',
      CURRENT_TIMESTAMP + INTERVAL '21 days',
      CURRENT_TIMESTAMP + INTERVAL '60 days',
      20,
      5,
      '{"total_views": 125000, "engagement_rate": 8.5, "conversion_rate": 3.2}'::jsonb
    ),
    (
      gen_random_uuid(),
      brand_user_id,
      'Tech Innovation Showcase',
      'Create educational content about our AI-powered solutions',
      '["Thought leadership", "Technical education", "Lead generation"]'::jsonb,
      75000.00,
      50000.00,
      8000.00,
      'in_progress',
      CURRENT_TIMESTAMP - INTERVAL '7 days',
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP + INTERVAL '45 days',
      15,
      8,
      '{"total_views": 89000, "engagement_rate": 12.3, "conversion_rate": 5.1}'::jsonb
    );

    -- Get the first campaign ID for mock application
    SELECT id INTO selected_campaign_id 
    FROM public.brand_partnerships 
    WHERE brand_id = brand_user_id 
    ORDER BY created_at DESC 
    LIMIT 1;

    -- Insert campaign application if creator exists
    IF creator_user_id IS NOT NULL AND selected_campaign_id IS NOT NULL THEN
      INSERT INTO public.campaign_applications (
        campaign_id,
        creator_id,
        application_status,
        portfolio_submission,
        audience_demographics,
        collaboration_proposal,
        expected_reach,
        expected_engagement_rate,
        proposed_content_plan
      ) VALUES (
        selected_campaign_id,
        creator_user_id,
        'accepted',
        '[{"title": "Previous Tech Review", "url": "https://example.com/jolt1", "views": 50000}]'::jsonb,
        '{"age_range": "18-34", "primary_location": "US", "interests": ["Technology", "Innovation"]}'::jsonb,
        'I will create 5 engaging Jolts showcasing your AI solutions with real-world use cases',
        75000,
        9.5,
        '[{"week": 1, "content": "Product unboxing"}, {"week": 2, "content": "Feature deep-dive"}]'::jsonb
      ) ON CONFLICT (campaign_id, creator_id) DO NOTHING;

      -- Insert partnership history
      INSERT INTO public.partnership_history (
        campaign_id,
        creator_id,
        brand_id,
        partnership_tier,
        total_earnings,
        content_delivered,
        content_approved,
        total_reach,
        total_engagement,
        engagement_rate,
        performance_rating,
        creator_rating,
        brand_rating,
        payment_status,
        completed_at
      ) VALUES (
        selected_campaign_id,
        creator_user_id,
        brand_user_id,
        'gold',
        5000.00,
        5,
        5,
        75000,
        7125,
        9.5,
        4.8,
        4.9,
        4.7,
        'completed',
        CURRENT_TIMESTAMP - INTERVAL '30 days'
      );
    END IF;
  END IF;
END $$;