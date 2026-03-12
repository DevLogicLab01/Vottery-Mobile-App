-- Phase B Batch 2: Creator Success Academy Migration
-- Implements progressive 5-tier onboarding, video tutorials, quizzes, achievements, and certifications

-- 1. Types
DROP TYPE IF EXISTS public.creator_tier_level CASCADE;
CREATE TYPE public.creator_tier_level AS ENUM ('beginner', 'novice', 'intermediate', 'advanced', 'expert');

DROP TYPE IF EXISTS public.quiz_status CASCADE;
CREATE TYPE public.quiz_status AS ENUM ('not_started', 'in_progress', 'passed', 'failed');

DROP TYPE IF EXISTS public.certification_status CASCADE;
CREATE TYPE public.certification_status AS ENUM ('not_earned', 'pending', 'certified');

-- 2. Core Tables
CREATE TABLE IF NOT EXISTS public.creator_academy_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier_level public.creator_tier_level NOT NULL UNIQUE,
    tier_name TEXT NOT NULL,
    tier_order INTEGER NOT NULL UNIQUE,
    xp_required INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    badge_icon_url TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.creator_academy_modules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier_level public.creator_tier_level NOT NULL,
    module_title TEXT NOT NULL,
    module_description TEXT,
    module_order INTEGER NOT NULL,
    estimated_duration_minutes INTEGER DEFAULT 10,
    is_required BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.creator_academy_video_tutorials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id UUID REFERENCES public.creator_academy_modules(id) ON DELETE CASCADE,
    video_title TEXT NOT NULL,
    video_description TEXT,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    duration_seconds INTEGER DEFAULT 0,
    video_order INTEGER DEFAULT 1,
    view_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.creator_academy_quizzes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    module_id UUID REFERENCES public.creator_academy_modules(id) ON DELETE CASCADE,
    quiz_title TEXT NOT NULL,
    quiz_description TEXT,
    passing_score_percentage INTEGER DEFAULT 80,
    total_questions INTEGER DEFAULT 5,
    time_limit_minutes INTEGER DEFAULT 15,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.creator_academy_quiz_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID REFERENCES public.creator_academy_quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type TEXT DEFAULT 'multiple_choice',
    options JSONB DEFAULT '[]'::JSONB,
    correct_answer TEXT NOT NULL,
    explanation TEXT,
    question_order INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.creator_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    current_tier public.creator_tier_level DEFAULT 'beginner'::public.creator_tier_level,
    total_xp INTEGER DEFAULT 0,
    modules_completed INTEGER DEFAULT 0,
    quizzes_passed INTEGER DEFAULT 0,
    videos_watched INTEGER DEFAULT 0,
    completion_percentage INTEGER DEFAULT 0,
    last_activity_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(creator_id)
);

CREATE TABLE IF NOT EXISTS public.creator_module_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    module_id UUID REFERENCES public.creator_academy_modules(id) ON DELETE CASCADE,
    is_completed BOOLEAN DEFAULT false,
    completion_date TIMESTAMPTZ,
    time_spent_minutes INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(creator_id, module_id)
);

CREATE TABLE IF NOT EXISTS public.creator_quiz_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    quiz_id UUID REFERENCES public.creator_academy_quizzes(id) ON DELETE CASCADE,
    attempt_number INTEGER DEFAULT 1,
    score_percentage INTEGER DEFAULT 0,
    status public.quiz_status DEFAULT 'not_started'::public.quiz_status,
    answers JSONB DEFAULT '[]'::JSONB,
    started_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.creator_video_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    video_id UUID REFERENCES public.creator_academy_video_tutorials(id) ON DELETE CASCADE,
    watch_time_seconds INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT false,
    last_watched_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(creator_id, video_id)
);

CREATE TABLE IF NOT EXISTS public.creator_certifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    tier_level public.creator_tier_level NOT NULL,
    certification_status public.certification_status DEFAULT 'not_earned'::public.certification_status,
    certificate_url TEXT,
    issued_at TIMESTAMPTZ,
    blockchain_hash TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(creator_id, tier_level)
);

CREATE TABLE IF NOT EXISTS public.creator_academy_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    achievement_key TEXT NOT NULL UNIQUE,
    achievement_name TEXT NOT NULL,
    achievement_description TEXT,
    badge_icon_url TEXT,
    xp_reward INTEGER DEFAULT 50,
    tier_requirement public.creator_tier_level,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.creator_unlocked_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.creator_academy_achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(creator_id, achievement_id)
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_creator_academy_modules_tier ON public.creator_academy_modules(tier_level);
CREATE INDEX IF NOT EXISTS idx_creator_academy_video_tutorials_module ON public.creator_academy_video_tutorials(module_id);
CREATE INDEX IF NOT EXISTS idx_creator_academy_quizzes_module ON public.creator_academy_quizzes(module_id);
CREATE INDEX IF NOT EXISTS idx_creator_progress_creator ON public.creator_progress(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_module_progress_creator ON public.creator_module_progress(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_quiz_attempts_creator ON public.creator_quiz_attempts(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_video_progress_creator ON public.creator_video_progress(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_certifications_creator ON public.creator_certifications(creator_id);

-- 4. Functions
CREATE OR REPLACE FUNCTION public.update_creator_progress()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.creator_progress
    SET 
        modules_completed = (SELECT COUNT(*) FROM public.creator_module_progress WHERE creator_id = NEW.creator_id AND is_completed = true),
        quizzes_passed = (SELECT COUNT(*) FROM public.creator_quiz_attempts WHERE creator_id = NEW.creator_id AND status = 'passed'::public.quiz_status),
        videos_watched = (SELECT COUNT(*) FROM public.creator_video_progress WHERE creator_id = NEW.creator_id AND is_completed = true),
        last_activity_at = CURRENT_TIMESTAMP
    WHERE creator_id = NEW.creator_id;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.award_creator_xp(p_creator_id UUID, p_xp_amount INTEGER)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_total_xp INTEGER;
    new_tier public.creator_tier_level;
BEGIN
    UPDATE public.creator_progress
    SET total_xp = total_xp + p_xp_amount
    WHERE creator_id = p_creator_id
    RETURNING total_xp INTO new_total_xp;

    SELECT tier_level INTO new_tier
    FROM public.creator_academy_tiers
    WHERE xp_required <= new_total_xp
    ORDER BY xp_required DESC
    LIMIT 1;

    IF new_tier IS NOT NULL THEN
        UPDATE public.creator_progress
        SET current_tier = new_tier
        WHERE creator_id = p_creator_id;
    END IF;
END;
$$;

-- 5. Enable RLS
ALTER TABLE public.creator_academy_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_academy_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_academy_video_tutorials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_academy_quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_academy_quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_module_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_video_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_academy_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_unlocked_achievements ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
DROP POLICY IF EXISTS "public_read_academy_tiers" ON public.creator_academy_tiers;
CREATE POLICY "public_read_academy_tiers" ON public.creator_academy_tiers FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "public_read_academy_modules" ON public.creator_academy_modules;
CREATE POLICY "public_read_academy_modules" ON public.creator_academy_modules FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "public_read_video_tutorials" ON public.creator_academy_video_tutorials;
CREATE POLICY "public_read_video_tutorials" ON public.creator_academy_video_tutorials FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "public_read_quizzes" ON public.creator_academy_quizzes;
CREATE POLICY "public_read_quizzes" ON public.creator_academy_quizzes FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "public_read_quiz_questions" ON public.creator_academy_quiz_questions;
CREATE POLICY "public_read_quiz_questions" ON public.creator_academy_quiz_questions FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "users_manage_own_creator_progress" ON public.creator_progress;
CREATE POLICY "users_manage_own_creator_progress" ON public.creator_progress FOR ALL TO authenticated USING (creator_id = auth.uid()) WITH CHECK (creator_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_module_progress" ON public.creator_module_progress;
CREATE POLICY "users_manage_own_module_progress" ON public.creator_module_progress FOR ALL TO authenticated USING (creator_id = auth.uid()) WITH CHECK (creator_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_quiz_attempts" ON public.creator_quiz_attempts;
CREATE POLICY "users_manage_own_quiz_attempts" ON public.creator_quiz_attempts FOR ALL TO authenticated USING (creator_id = auth.uid()) WITH CHECK (creator_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_video_progress" ON public.creator_video_progress;
CREATE POLICY "users_manage_own_video_progress" ON public.creator_video_progress FOR ALL TO authenticated USING (creator_id = auth.uid()) WITH CHECK (creator_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_certifications" ON public.creator_certifications;
CREATE POLICY "users_manage_own_certifications" ON public.creator_certifications FOR ALL TO authenticated USING (creator_id = auth.uid()) WITH CHECK (creator_id = auth.uid());

DROP POLICY IF EXISTS "public_read_academy_achievements" ON public.creator_academy_achievements;
CREATE POLICY "public_read_academy_achievements" ON public.creator_academy_achievements FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "users_manage_own_unlocked_achievements" ON public.creator_unlocked_achievements;
CREATE POLICY "users_manage_own_unlocked_achievements" ON public.creator_unlocked_achievements FOR ALL TO authenticated USING (creator_id = auth.uid()) WITH CHECK (creator_id = auth.uid());

-- 7. Triggers
DROP TRIGGER IF EXISTS on_module_progress_update ON public.creator_module_progress;
CREATE TRIGGER on_module_progress_update
    AFTER INSERT OR UPDATE ON public.creator_module_progress
    FOR EACH ROW
    EXECUTE FUNCTION public.update_creator_progress();

DROP TRIGGER IF EXISTS on_quiz_attempt_update ON public.creator_quiz_attempts;
CREATE TRIGGER on_quiz_attempt_update
    AFTER INSERT OR UPDATE ON public.creator_quiz_attempts
    FOR EACH ROW
    EXECUTE FUNCTION public.update_creator_progress();

DROP TRIGGER IF EXISTS on_video_progress_update ON public.creator_video_progress;
CREATE TRIGGER on_video_progress_update
    AFTER INSERT OR UPDATE ON public.creator_video_progress
    FOR EACH ROW
    EXECUTE FUNCTION public.update_creator_progress();

-- 8. Mock Data
DO $$
DECLARE
    existing_user_id UUID;
    beginner_module_id UUID;
    novice_module_id UUID;
    video1_id UUID;
    video2_id UUID;
    quiz1_id UUID;
BEGIN
    -- Insert tier levels
    INSERT INTO public.creator_academy_tiers (tier_level, tier_name, tier_order, xp_required, description, badge_icon_url) VALUES
        ('beginner'::public.creator_tier_level, 'Beginner', 1, 0, 'Start your creator journey with fundamental concepts', 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=200'),
        ('novice'::public.creator_tier_level, 'Novice', 2, 500, 'Build on basics with practical election creation skills', 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=200'),
        ('intermediate'::public.creator_tier_level, 'Intermediate', 3, 1500, 'Master gamification and audience engagement strategies', 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=200'),
        ('advanced'::public.creator_tier_level, 'Advanced', 4, 3500, 'Optimize monetization and advanced analytics', 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=200'),
        ('expert'::public.creator_tier_level, 'Expert', 5, 7500, 'Elite creator mastery with blockchain and compliance', 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=200')
    ON CONFLICT (tier_level) DO NOTHING;

    -- Insert modules
    INSERT INTO public.creator_academy_modules (tier_level, module_title, module_description, module_order, estimated_duration_minutes) VALUES
        ('beginner'::public.creator_tier_level, 'Election Creation Basics', 'Learn how to create your first election with compelling content', 1, 15),
        ('beginner'::public.creator_tier_level, 'Understanding Voting Mechanics', 'Explore different voting types and when to use them', 2, 20),
        ('novice'::public.creator_tier_level, 'Gamification Strategies', 'Implement rewards and incentives to boost participation', 1, 25),
        ('novice'::public.creator_tier_level, 'Audience Growth Tactics', 'Build and engage your voter community effectively', 2, 30),
        ('intermediate'::public.creator_tier_level, 'Monetization Optimization', 'Maximize earnings through strategic pricing and partnerships', 1, 35)
    ON CONFLICT DO NOTHING
    RETURNING id INTO beginner_module_id;

    SELECT id INTO beginner_module_id FROM public.creator_academy_modules WHERE tier_level = 'beginner'::public.creator_tier_level LIMIT 1;
    SELECT id INTO novice_module_id FROM public.creator_academy_modules WHERE tier_level = 'novice'::public.creator_tier_level LIMIT 1;

    -- Insert video tutorials
    IF beginner_module_id IS NOT NULL THEN
        INSERT INTO public.creator_academy_video_tutorials (module_id, video_title, video_description, video_url, thumbnail_url, duration_seconds, video_order) VALUES
            (beginner_module_id, 'Creating Your First Election', 'Step-by-step guide to launching your first election', 'https://storage.supabase.co/tutorials/election-basics.mp4', 'https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg?w=400', 480, 1),
            (beginner_module_id, 'Crafting Compelling Questions', 'Best practices for writing questions that drive engagement', 'https://storage.supabase.co/tutorials/question-writing.mp4', 'https://images.pexels.com/photos/3183197/pexels-photo-3183197.jpeg?w=400', 360, 2)
        ON CONFLICT DO NOTHING
        RETURNING id INTO video1_id;
    END IF;

    IF novice_module_id IS NOT NULL THEN
        INSERT INTO public.creator_academy_video_tutorials (module_id, video_title, video_description, video_url, thumbnail_url, duration_seconds, video_order) VALUES
            (novice_module_id, 'Gamification Deep Dive', 'Advanced techniques for reward systems and voter incentives', 'https://storage.supabase.co/tutorials/gamification.mp4', 'https://images.pixabay.com/photo/2018/03/10/12/00/teamwork-3213924_1280.jpg?w=400', 600, 1)
        ON CONFLICT DO NOTHING
        RETURNING id INTO video2_id;
    END IF;

    -- Insert quizzes
    IF beginner_module_id IS NOT NULL THEN
        INSERT INTO public.creator_academy_quizzes (module_id, quiz_title, quiz_description, passing_score_percentage, total_questions, time_limit_minutes) VALUES
            (beginner_module_id, 'Election Basics Quiz', 'Test your knowledge of fundamental election creation concepts', 80, 5, 10)
        ON CONFLICT DO NOTHING
        RETURNING id INTO quiz1_id;
    END IF;

    -- Insert quiz questions
    IF quiz1_id IS NOT NULL THEN
        INSERT INTO public.creator_academy_quiz_questions (quiz_id, question_text, question_type, options, correct_answer, explanation, question_order) VALUES
            (quiz1_id, 'What is the minimum number of options required for an election?', 'multiple_choice', 
             '[{"id": "a", "text": "1"}, {"id": "b", "text": "2"}, {"id": "c", "text": "3"}, {"id": "d", "text": "4"}]'::JSONB, 
             'b', 'Elections require at least 2 options for voters to choose between', 1),
            (quiz1_id, 'Which voting type allows voters to select multiple options?', 'multiple_choice',
             '[{"id": "a", "text": "Plurality"}, {"id": "b", "text": "Approval"}, {"id": "c", "text": "Ranked Choice"}, {"id": "d", "text": "Single Choice"}]'::JSONB,
             'b', 'Approval voting allows voters to approve multiple options', 2)
        ON CONFLICT DO NOTHING;
    END IF;

    -- Insert achievements
    INSERT INTO public.creator_academy_achievements (achievement_key, achievement_name, achievement_description, badge_icon_url, xp_reward, tier_requirement) VALUES
        ('first_election', 'First Election', 'Created your first election', 'https://images.unsplash.com/photo-1569144157591-c60f3f82f137?w=100', 100, 'beginner'::public.creator_tier_level),
        ('100_votes', '100 Votes Milestone', 'Received 100 total votes across all elections', 'https://images.unsplash.com/photo-1532619675605-1ede6c2ed2b0?w=100', 250, 'novice'::public.creator_tier_level),
        ('first_prize_winner', 'First Prize Winner', 'Had a voter win a prize in your election', 'https://images.unsplash.com/photo-1567427017947-545c5f8d16ad?w=100', 300, 'novice'::public.creator_tier_level),
        ('1000_followers', '1K Followers', 'Reached 1000 followers', 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=100', 500, 'intermediate'::public.creator_tier_level),
        ('100_earned', '$100 Earned', 'Earned $100 in total revenue', 'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=100', 750, 'advanced'::public.creator_tier_level)
    ON CONFLICT (achievement_key) DO NOTHING;

    -- Create progress for existing user
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;
    IF existing_user_id IS NOT NULL THEN
        INSERT INTO public.creator_progress (creator_id, current_tier, total_xp, modules_completed, quizzes_passed, videos_watched, completion_percentage)
        VALUES (existing_user_id, 'beginner'::public.creator_tier_level, 150, 1, 0, 2, 15)
        ON CONFLICT (creator_id) DO NOTHING;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;