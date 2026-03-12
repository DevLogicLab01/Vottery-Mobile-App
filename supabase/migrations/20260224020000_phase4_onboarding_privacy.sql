-- Phase 4: Onboarding Tours & Privacy Controls
-- Migration: 20260224020000_phase4_onboarding_privacy.sql

-- ============================================================================
-- CLEANUP: Drop existing tables if they exist
-- ============================================================================

DROP TRIGGER IF EXISTS update_privacy_score ON public.user_privacy_settings;
DROP TRIGGER IF EXISTS log_privacy_audit ON public.user_privacy_settings;
DROP TRIGGER IF EXISTS update_onboarding_progress_updated_at ON public.user_onboarding_progress;
DROP TRIGGER IF EXISTS update_privacy_settings_updated_at ON public.user_privacy_settings;

DROP FUNCTION IF EXISTS calculate_privacy_score();
DROP FUNCTION IF EXISTS log_privacy_changes();
-- DO NOT DROP update_updated_at_column() - it's used by many other triggers across the database

DROP TABLE IF EXISTS public.user_privacy_audit CASCADE;
DROP TABLE IF EXISTS public.user_privacy_settings CASCADE;
DROP TABLE IF EXISTS public.tour_analytics CASCADE;
DROP TABLE IF EXISTS public.user_onboarding_progress CASCADE;

-- ============================================================================
-- USER ONBOARDING PROGRESS TABLE
-- ============================================================================

CREATE TABLE public.user_onboarding_progress (
    progress_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_tour_completed BOOLEAN DEFAULT false,
    voting_tour_completed BOOLEAN DEFAULT false,
    creator_tour_completed BOOLEAN DEFAULT false,
    ai_tour_completed BOOLEAN DEFAULT false,
    carousel_tour_completed BOOLEAN DEFAULT false,
    marketplace_tour_completed BOOLEAN DEFAULT false,
    messaging_tour_completed BOOLEAN DEFAULT false,
    tours_disabled BOOLEAN DEFAULT false,
    last_tour_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ============================================================================
-- TOUR ANALYTICS TABLE
-- ============================================================================

CREATE TABLE public.tour_analytics (
    analytics_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tour_name VARCHAR(100) NOT NULL,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    completion_rate INTEGER CHECK (completion_rate >= 0 AND completion_rate <= 100),
    steps_completed INTEGER DEFAULT 0,
    steps_skipped INTEGER DEFAULT 0,
    time_spent_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- USER PRIVACY SETTINGS TABLE
-- ============================================================================

CREATE TABLE public.user_privacy_settings (
    settings_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Activity Privacy
    online_status_visibility VARCHAR(50) DEFAULT 'everyone' CHECK (online_status_visibility IN ('everyone', 'friends_only', 'nobody')),
    last_seen_visibility VARCHAR(50) DEFAULT 'everyone' CHECK (last_seen_visibility IN ('everyone', 'friends_only', 'nobody')),
    voting_history_visibility VARCHAR(50) DEFAULT 'everyone' CHECK (voting_history_visibility IN ('everyone', 'friends_only', 'nobody')),
    earnings_visibility VARCHAR(50) DEFAULT 'show_all' CHECK (earnings_visibility IN ('show_all', 'show_tier', 'hide_all')),
    
    -- Profile Visibility
    profile_visibility_level VARCHAR(50) DEFAULT 'public' CHECK (profile_visibility_level IN ('public', 'friends_only', 'private')),
    searchable BOOLEAN DEFAULT true,
    show_completion_badge BOOLEAN DEFAULT true,
    show_activity_feed BOOLEAN DEFAULT true,
    
    -- Content Privacy
    default_post_privacy VARCHAR(50) DEFAULT 'public' CHECK (default_post_privacy IN ('public', 'friends_only', 'private')),
    show_created_elections BOOLEAN DEFAULT true,
    allow_comments BOOLEAN DEFAULT true,
    allow_sharing BOOLEAN DEFAULT true,
    
    -- Communication Privacy
    message_privacy VARCHAR(50) DEFAULT 'everyone' CHECK (message_privacy IN ('everyone', 'friends_only', 'nobody')),
    friend_request_privacy VARCHAR(50) DEFAULT 'everyone' CHECK (friend_request_privacy IN ('everyone', 'friends_only', 'nobody')),
    email_visibility BOOLEAN DEFAULT false,
    phone_visibility BOOLEAN DEFAULT false,
    push_notifications_enabled BOOLEAN DEFAULT true,
    email_notifications_enabled BOOLEAN DEFAULT true,
    
    -- Data Sharing
    analytics_consent BOOLEAN DEFAULT true,
    marketing_consent BOOLEAN DEFAULT false,
    partner_data_sharing BOOLEAN DEFAULT false,
    
    -- Privacy Metrics
    privacy_preset VARCHAR(50),
    privacy_score INTEGER DEFAULT 50 CHECK (privacy_score >= 0 AND privacy_score <= 100),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ============================================================================
-- USER PRIVACY AUDIT TABLE
-- ============================================================================

CREATE TABLE public.user_privacy_audit (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    setting_name VARCHAR(100) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    ip_address VARCHAR(45)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Drop indexes if they exist (prevents "already exists" errors)
DROP INDEX IF EXISTS public.idx_onboarding_user;
DROP INDEX IF EXISTS public.idx_tour_analytics_user;
DROP INDEX IF EXISTS public.idx_tour_analytics_tour;
DROP INDEX IF EXISTS public.idx_privacy_user;
DROP INDEX IF EXISTS public.idx_privacy_visibility;
DROP INDEX IF EXISTS public.idx_privacy_audit_user;
DROP INDEX IF EXISTS public.idx_privacy_audit_time;

-- Create indexes
CREATE INDEX idx_onboarding_user ON public.user_onboarding_progress(user_id);
CREATE INDEX idx_tour_analytics_user ON public.tour_analytics(user_id);
CREATE INDEX idx_tour_analytics_tour ON public.tour_analytics(tour_name);
CREATE INDEX idx_privacy_user ON public.user_privacy_settings(user_id);
CREATE INDEX idx_privacy_visibility ON public.user_privacy_settings(profile_visibility_level, searchable);
CREATE INDEX idx_privacy_audit_user ON public.user_privacy_audit(user_id);
CREATE INDEX idx_privacy_audit_time ON public.user_privacy_audit(changed_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE public.user_onboarding_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tour_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_privacy_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_privacy_audit ENABLE ROW LEVEL SECURITY;

-- User Onboarding Progress Policies
CREATE POLICY users_manage_own_onboarding ON public.user_onboarding_progress
    FOR ALL USING (user_id = auth.uid());

-- Tour Analytics Policies
CREATE POLICY users_manage_own_tour_analytics ON public.tour_analytics
    FOR ALL USING (user_id = auth.uid());

-- Privacy Settings Policies
CREATE POLICY users_manage_own_privacy ON public.user_privacy_settings
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY others_read_privacy ON public.user_privacy_settings
    FOR SELECT USING (true);

-- Privacy Audit Policies
CREATE POLICY users_view_own_audit ON public.user_privacy_audit
    FOR SELECT USING (user_id = auth.uid());

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to calculate privacy score
CREATE OR REPLACE FUNCTION calculate_privacy_score()
RETURNS TRIGGER AS $$
DECLARE
    score INTEGER := 0;
BEGIN
    -- Activity Privacy (25 points max)
    IF NEW.online_status_visibility = 'nobody' THEN score := score + 7; END IF;
    IF NEW.online_status_visibility = 'friends_only' THEN score := score + 4; END IF;
    IF NEW.last_seen_visibility = 'nobody' THEN score := score + 6; END IF;
    IF NEW.last_seen_visibility = 'friends_only' THEN score := score + 3; END IF;
    IF NEW.voting_history_visibility = 'nobody' THEN score := score + 6; END IF;
    IF NEW.voting_history_visibility = 'friends_only' THEN score := score + 3; END IF;
    IF NEW.earnings_visibility = 'hide_all' THEN score := score + 6; END IF;
    IF NEW.earnings_visibility = 'show_tier' THEN score := score + 3; END IF;
    
    -- Profile Visibility (25 points max)
    IF NEW.profile_visibility_level = 'private' THEN score := score + 10; END IF;
    IF NEW.profile_visibility_level = 'friends_only' THEN score := score + 5; END IF;
    IF NOT NEW.searchable THEN score := score + 8; END IF;
    IF NOT NEW.show_completion_badge THEN score := score + 3; END IF;
    IF NOT NEW.show_activity_feed THEN score := score + 4; END IF;
    
    -- Content Privacy (20 points max)
    IF NEW.default_post_privacy = 'private' THEN score := score + 8; END IF;
    IF NEW.default_post_privacy = 'friends_only' THEN score := score + 4; END IF;
    IF NOT NEW.show_created_elections THEN score := score + 4; END IF;
    IF NOT NEW.allow_comments THEN score := score + 4; END IF;
    IF NOT NEW.allow_sharing THEN score := score + 4; END IF;
    
    -- Communication Privacy (20 points max)
    IF NEW.message_privacy = 'nobody' THEN score := score + 6; END IF;
    IF NEW.message_privacy = 'friends_only' THEN score := score + 3; END IF;
    IF NEW.friend_request_privacy = 'nobody' THEN score := score + 5; END IF;
    IF NEW.friend_request_privacy = 'friends_only' THEN score := score + 2; END IF;
    IF NOT NEW.email_visibility THEN score := score + 3; END IF;
    IF NOT NEW.phone_visibility THEN score := score + 3; END IF;
    IF NOT NEW.push_notifications_enabled THEN score := score + 1; END IF;
    
    -- Data Sharing (10 points max)
    IF NOT NEW.analytics_consent THEN score := score + 4; END IF;
    IF NOT NEW.marketing_consent THEN score := score + 3; END IF;
    IF NOT NEW.partner_data_sharing THEN score := score + 3; END IF;
    
    NEW.privacy_score := LEAST(score, 100);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to log privacy changes
CREATE OR REPLACE FUNCTION log_privacy_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        -- Log each changed field
        IF OLD.online_status_visibility != NEW.online_status_visibility THEN
            INSERT INTO public.user_privacy_audit (user_id, setting_name, old_value, new_value)
            VALUES (NEW.user_id, 'online_status_visibility', OLD.online_status_visibility, NEW.online_status_visibility);
        END IF;
        
        IF OLD.profile_visibility_level != NEW.profile_visibility_level THEN
            INSERT INTO public.user_privacy_audit (user_id, setting_name, old_value, new_value)
            VALUES (NEW.user_id, 'profile_visibility_level', OLD.profile_visibility_level, NEW.profile_visibility_level);
        END IF;
        
        IF OLD.searchable != NEW.searchable THEN
            INSERT INTO public.user_privacy_audit (user_id, setting_name, old_value, new_value)
            VALUES (NEW.user_id, 'searchable', OLD.searchable::TEXT, NEW.searchable::TEXT);
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update timestamps (CREATE OR REPLACE to avoid conflicts with existing function)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Privacy score calculation trigger
CREATE TRIGGER update_privacy_score
    BEFORE INSERT OR UPDATE ON public.user_privacy_settings
    FOR EACH ROW
    EXECUTE FUNCTION calculate_privacy_score();

-- Privacy audit logging trigger
CREATE TRIGGER log_privacy_audit
    AFTER UPDATE ON public.user_privacy_settings
    FOR EACH ROW
    EXECUTE FUNCTION log_privacy_changes();

-- Updated_at triggers
CREATE TRIGGER update_onboarding_progress_updated_at
    BEFORE UPDATE ON public.user_onboarding_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_privacy_settings_updated_at
    BEFORE UPDATE ON public.user_privacy_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- INITIAL DATA
-- ============================================================================

-- Create default privacy settings for existing users
INSERT INTO public.user_privacy_settings (user_id)
SELECT id FROM auth.users
WHERE id NOT IN (SELECT user_id FROM public.user_privacy_settings)
ON CONFLICT (user_id) DO NOTHING;

-- Create default onboarding progress for existing users
INSERT INTO public.user_onboarding_progress (user_id)
SELECT id FROM auth.users
WHERE id NOT IN (SELECT user_id FROM public.user_onboarding_progress)
ON CONFLICT (user_id) DO NOTHING;
