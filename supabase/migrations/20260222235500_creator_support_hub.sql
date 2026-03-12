-- Creator Support Hub Migration
-- Extends existing support_tickets system with guides, FAQ bot, and analytics

-- ============================================================================
-- TYPES
-- ============================================================================

DROP TYPE IF EXISTS public.guide_difficulty CASCADE;
CREATE TYPE public.guide_difficulty AS ENUM ('beginner', 'intermediate', 'advanced');

DROP TYPE IF EXISTS public.guide_category CASCADE;
CREATE TYPE public.guide_category AS ENUM (
  'getting_started',
  'content_creation',
  'audience_growth',
  'monetization',
  'analytics',
  'best_practices'
);

DROP TYPE IF EXISTS public.journey_step_name CASCADE;
CREATE TYPE public.journey_step_name AS ENUM (
  'account_created',
  'profile_completed',
  'first_post',
  'first_election',
  'first_earning',
  'activated_creator'
);

-- ============================================================================
-- TABLES
-- ============================================================================

-- Guides table
CREATE TABLE IF NOT EXISTS public.guides (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(200) NOT NULL,
  category public.guide_category NOT NULL,
  difficulty public.guide_difficulty NOT NULL,
  estimated_minutes INTEGER NOT NULL DEFAULT 15,
  description TEXT,
  reward_vp INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Guide steps table
CREATE TABLE IF NOT EXISTS public.guides_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  guide_id UUID NOT NULL REFERENCES public.guides(id) ON DELETE CASCADE,
  step_order INTEGER NOT NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  step_image_url VARCHAR(500),
  step_video_url VARCHAR(500),
  actions JSONB DEFAULT '[]'::jsonb,
  quiz JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Guide progress tracking
CREATE TABLE IF NOT EXISTS public.guide_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  guide_id UUID NOT NULL REFERENCES public.guides(id) ON DELETE CASCADE,
  current_step INTEGER DEFAULT 0,
  completed_steps INTEGER[] DEFAULT ARRAY[]::INTEGER[],
  completed BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, guide_id)
);

-- FAQ feedback table
CREATE TABLE IF NOT EXISTS public.faq_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  response TEXT NOT NULL,
  helpful BOOLEAN NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Creator journey steps tracking
CREATE TABLE IF NOT EXISTS public.creator_journey_steps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  step_name public.journey_step_name NOT NULL,
  completed_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, step_name)
);

-- Ticket ratings table (extends existing support_tickets)
CREATE TABLE IF NOT EXISTS public.ticket_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  feedback TEXT,
  rated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(ticket_id, user_id)
);

-- Guide bookmarks table
CREATE TABLE IF NOT EXISTS public.guide_bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  guide_id UUID NOT NULL REFERENCES public.guides(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, guide_id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_guides_category ON public.guides(category);
CREATE INDEX IF NOT EXISTS idx_guides_difficulty ON public.guides(difficulty);
CREATE INDEX IF NOT EXISTS idx_guides_steps_guide_id ON public.guides_steps(guide_id);
CREATE INDEX IF NOT EXISTS idx_guides_steps_order ON public.guides_steps(guide_id, step_order);
CREATE INDEX IF NOT EXISTS idx_guide_progress_user_id ON public.guide_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_guide_progress_guide_id ON public.guide_progress(guide_id);
CREATE INDEX IF NOT EXISTS idx_faq_feedback_user_id ON public.faq_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_creator_journey_user_id ON public.creator_journey_steps(user_id);
CREATE INDEX IF NOT EXISTS idx_ticket_ratings_ticket_id ON public.ticket_ratings(ticket_id);
CREATE INDEX IF NOT EXISTS idx_guide_bookmarks_user_id ON public.guide_bookmarks(user_id);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to update guide progress
CREATE OR REPLACE FUNCTION public.update_guide_progress_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- Function to get creator onboarding completion rate
CREATE OR REPLACE FUNCTION public.get_onboarding_completion_rate()
RETURNS DECIMAL
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT 
    CASE 
      WHEN COUNT(DISTINCT user_id) = 0 THEN 0
      ELSE ROUND(
        (COUNT(DISTINCT CASE WHEN step_name = 'activated_creator' THEN user_id END)::DECIMAL / 
         COUNT(DISTINCT user_id)::DECIMAL) * 100, 2
      )
    END
  FROM public.creator_journey_steps;
$$;

-- Function to get guide completion count for category
CREATE OR REPLACE FUNCTION public.get_guide_completion_count(
  p_user_id UUID,
  p_category public.guide_category
)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COUNT(*)::INTEGER
  FROM public.guide_progress gp
  JOIN public.guides g ON gp.guide_id = g.id
  WHERE gp.user_id = p_user_id
    AND g.category = p_category
    AND gp.completed = true;
$$;

-- ============================================================================
-- ENABLE RLS
-- ============================================================================

ALTER TABLE public.guides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guides_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guide_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faq_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_journey_steps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guide_bookmarks ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Guides: Public read, admin write
DROP POLICY IF EXISTS "public_can_read_guides" ON public.guides;
CREATE POLICY "public_can_read_guides"
ON public.guides
FOR SELECT
TO public
USING (true);

-- Guide steps: Public read
DROP POLICY IF EXISTS "public_can_read_guides_steps" ON public.guides_steps;
CREATE POLICY "public_can_read_guides_steps"
ON public.guides_steps
FOR SELECT
TO public
USING (true);

-- Guide progress: Users manage own
DROP POLICY IF EXISTS "users_manage_own_guide_progress" ON public.guide_progress;
CREATE POLICY "users_manage_own_guide_progress"
ON public.guide_progress
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- FAQ feedback: Users manage own
DROP POLICY IF EXISTS "users_manage_own_faq_feedback" ON public.faq_feedback;
CREATE POLICY "users_manage_own_faq_feedback"
ON public.faq_feedback
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Creator journey: Users manage own
DROP POLICY IF EXISTS "users_manage_own_creator_journey" ON public.creator_journey_steps;
CREATE POLICY "users_manage_own_creator_journey"
ON public.creator_journey_steps
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Ticket ratings: Users manage own
DROP POLICY IF EXISTS "users_manage_own_ticket_ratings" ON public.ticket_ratings;
CREATE POLICY "users_manage_own_ticket_ratings"
ON public.ticket_ratings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Guide bookmarks: Users manage own
DROP POLICY IF EXISTS "users_manage_own_guide_bookmarks" ON public.guide_bookmarks;
CREATE POLICY "users_manage_own_guide_bookmarks"
ON public.guide_bookmarks
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ============================================================================
-- TRIGGERS
-- ============================================================================

DROP TRIGGER IF EXISTS update_guide_progress_timestamp_trigger ON public.guide_progress;
CREATE TRIGGER update_guide_progress_timestamp_trigger
BEFORE UPDATE ON public.guide_progress
FOR EACH ROW
EXECUTE FUNCTION public.update_guide_progress_timestamp();

-- ============================================================================
-- MOCK DATA
-- ============================================================================

DO $$
DECLARE
  existing_user_id UUID;
  guide1_id UUID := gen_random_uuid();
  guide2_id UUID := gen_random_uuid();
  guide3_id UUID := gen_random_uuid();
BEGIN
  -- Get existing user
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'auth' AND table_name = 'users'
  ) THEN
    SELECT id INTO existing_user_id FROM auth.users LIMIT 1;
    
    IF existing_user_id IS NOT NULL THEN
      -- Insert sample guides
      INSERT INTO public.guides (id, title, category, difficulty, estimated_minutes, description, reward_vp)
      VALUES 
        (guide1_id, 'Getting Started with Vottery', 'getting_started', 'beginner', 10, 'Learn the basics of creating elections and earning VP', 50),
        (guide2_id, 'Creating Engaging Content', 'content_creation', 'intermediate', 20, 'Master the art of creating content that drives engagement', 100),
        (guide3_id, 'Monetization Strategies', 'monetization', 'advanced', 30, 'Advanced strategies for maximizing your creator earnings', 200)
      ON CONFLICT (id) DO NOTHING;
      
      -- Insert guide steps
      INSERT INTO public.guides_steps (guide_id, step_order, title, content)
      VALUES 
        (guide1_id, 1, 'Create Your First Election', 'Navigate to the Create Election screen and fill in the basic details. Choose a compelling title and description that will attract voters.'),
        (guide1_id, 2, 'Add Voting Options', 'Add at least 2 voting options. Make them clear and distinct so voters can easily understand their choices.'),
        (guide1_id, 3, 'Publish and Share', 'Review your election settings and publish. Share the election link with your audience to start collecting votes.'),
        (guide2_id, 1, 'Understanding Your Audience', 'Analyze your audience demographics and preferences using the Analytics dashboard. Identify what content resonates most.'),
        (guide2_id, 2, 'Content Planning', 'Create a content calendar with diverse election topics. Mix trending topics with evergreen content for consistent engagement.'),
        (guide3_id, 1, 'VP Earning Strategies', 'Learn about different ways to earn VP: creating elections, receiving votes, engagement bonuses, and completing quests.'),
        (guide3_id, 2, 'Redemption Options', 'Explore various redemption options in the Digital Wallet. Understand minimum thresholds and processing times.')
      ON CONFLICT (id) DO NOTHING;
      
      -- Insert sample guide progress
      INSERT INTO public.guide_progress (user_id, guide_id, current_step, completed_steps, completed)
      VALUES 
        (existing_user_id, guide1_id, 3, ARRAY[1, 2, 3], true),
        (existing_user_id, guide2_id, 1, ARRAY[1], false)
      ON CONFLICT (user_id, guide_id) DO NOTHING;
      
      -- Insert creator journey steps
      INSERT INTO public.creator_journey_steps (user_id, step_name)
      VALUES 
        (existing_user_id, 'account_created'),
        (existing_user_id, 'profile_completed'),
        (existing_user_id, 'first_post')
      ON CONFLICT (user_id, step_name) DO NOTHING;
      
      RAISE NOTICE 'Creator Support Hub mock data created successfully';
    ELSE
      RAISE NOTICE 'No users found. Run auth migration first.';
    END IF;
  ELSE
    RAISE NOTICE 'Auth users table does not exist. Run auth migration first.';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;
