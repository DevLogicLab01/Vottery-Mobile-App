-- ============================================================
-- Phase B Batch 5 Final: GA4 Advanced Events + Performance + Partnerships
-- Timestamp: 20260305010000
-- ============================================================

-- ============================================================
-- 1. PROPOSAL SUBMISSIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.proposal_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES public.brand_partnerships(id) ON DELETE CASCADE,
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  creator_pitch TEXT,
  proposed_election_concept TEXT,
  audience_reach_estimate INTEGER DEFAULT 0,
  asking_price NUMERIC(12,2) DEFAULT 0.00,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'rejected', 'withdrawn')),
  submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_proposal_submissions_campaign ON public.proposal_submissions(campaign_id);
CREATE INDEX idx_proposal_submissions_creator ON public.proposal_submissions(creator_id);
CREATE INDEX idx_proposal_submissions_status ON public.proposal_submissions(status);

-- ============================================================
-- 2. PARTNERSHIP PERFORMANCE METRICS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.partnership_performance_metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partnership_id UUID NOT NULL REFERENCES public.brand_partnerships(id) ON DELETE CASCADE,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  conversions INTEGER DEFAULT 0,
  roi NUMERIC(10,2) DEFAULT 0.00,
  recorded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_partnership_performance_partnership ON public.partnership_performance_metrics(partnership_id);
CREATE INDEX idx_partnership_performance_recorded ON public.partnership_performance_metrics(recorded_at DESC);

-- ============================================================
-- 3. ALTER BRAND_PARTNERSHIPS TABLE
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'brand_partnerships' 
    AND column_name = 'creator_id'
  ) THEN
    ALTER TABLE public.brand_partnerships ADD COLUMN creator_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- ============================================================
-- 4. RLS POLICIES
-- ============================================================

-- Proposal Submissions Policies
ALTER TABLE public.proposal_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators can manage their own proposals"
ON public.proposal_submissions
  FOR ALL
  USING (auth.uid() = creator_id);

CREATE POLICY "Brands can view proposals for their campaigns"
ON public.proposal_submissions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.brand_partnerships
      WHERE brand_partnerships.id = proposal_submissions.campaign_id
      AND brand_partnerships.brand_id = auth.uid()
    )
  );

-- Partnership Performance Metrics Policies
ALTER TABLE public.partnership_performance_metrics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creators and brands can view partnership metrics"
ON public.partnership_performance_metrics
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.brand_partnerships
      WHERE brand_partnerships.id = partnership_performance_metrics.partnership_id
      AND (brand_partnerships.brand_id = auth.uid() OR brand_partnerships.creator_id = auth.uid())
    )
  );

-- ============================================================
-- 5. FUNCTIONS
-- ============================================================

-- Function to calculate partnership compatibility score
CREATE OR REPLACE FUNCTION public.calculate_partnership_compatibility(
  p_creator_id UUID,
  p_campaign_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_compatibility_score INTEGER := 0;
  v_creator_followers INTEGER;
  v_creator_engagement NUMERIC;
BEGIN
  -- Get creator metrics
  SELECT follower_count INTO v_creator_followers
  FROM public.user_profiles
  WHERE id = p_creator_id;

  -- Calculate compatibility score (0-100)
  -- Basic scoring based on follower count
  IF v_creator_followers >= 10000 THEN
    v_compatibility_score := 80;
  ELSIF v_creator_followers >= 5000 THEN
    v_compatibility_score := 60;
  ELSIF v_creator_followers >= 1000 THEN
    v_compatibility_score := 40;
  ELSE
    v_compatibility_score := 20;
  END IF;

  RETURN v_compatibility_score;
END;
$$;

-- ============================================================
-- 6. MOCK DATA (Optional)
-- ============================================================

DO $$
DECLARE
  v_creator_id UUID;
  v_campaign_id UUID;
BEGIN
  -- Get a creator user
  SELECT id INTO v_creator_id
  FROM public.user_profiles
  WHERE creator_verification_status = 'approved'
  LIMIT 1;

  -- Get a campaign
  SELECT id INTO v_campaign_id
  FROM public.brand_partnerships
  WHERE status = 'open'
  LIMIT 1;

  IF v_creator_id IS NOT NULL AND v_campaign_id IS NOT NULL THEN
    -- Insert mock proposal
    INSERT INTO public.proposal_submissions (
      campaign_id,
      creator_id,
      creator_pitch,
      proposed_election_concept,
      audience_reach_estimate,
      asking_price,
      status
    ) VALUES (
      v_campaign_id,
      v_creator_id,
      'I have a highly engaged audience in the target demographic',
      'Create an interactive election showcasing brand values',
      50000,
      5000.00,
      'pending'
    ) ON CONFLICT DO NOTHING;
  END IF;
END $$;
