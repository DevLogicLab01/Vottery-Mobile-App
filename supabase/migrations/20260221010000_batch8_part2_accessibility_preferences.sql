-- Batch 8 Part 2: Accessibility Preferences Table
-- User font scaling preferences with real-time sync across devices

-- =====================================================
-- USER ACCESSIBILITY PREFERENCES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.user_accessibility_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  font_scale_factor DECIMAL(3, 2) NOT NULL DEFAULT 1.00 CHECK (font_scale_factor >= 0.80 AND font_scale_factor <= 1.20),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_accessibility_preferences_user_id ON public.user_accessibility_preferences(user_id);

-- =====================================================
-- RLS POLICIES
-- =====================================================
ALTER TABLE public.user_accessibility_preferences ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_accessibility_preferences' AND policyname = 'users_manage_own_accessibility_preferences') THEN
    CREATE POLICY users_manage_own_accessibility_preferences ON public.user_accessibility_preferences
      FOR ALL
      TO authenticated
      USING (user_id = auth.uid())
      WITH CHECK (user_id = auth.uid());
  END IF;
END $$;
