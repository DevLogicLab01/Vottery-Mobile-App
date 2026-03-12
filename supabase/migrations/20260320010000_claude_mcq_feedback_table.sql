-- Migration: Add claude_mcq_feedback table for Creator Feedback Loop
-- Timestamp: 20260320010000

CREATE TABLE IF NOT EXISTS public.claude_mcq_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  optimization_id TEXT,
  original_question TEXT,
  improved_question TEXT,
  feedback_type TEXT NOT NULL CHECK (feedback_type IN ('helpful', 'not_helpful', 'try_alternative')),
  optimization_type TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add feedback columns to mcq_optimization_history if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'mcq_optimization_history'
      AND column_name = 'feedback_rating'
  ) THEN
    ALTER TABLE public.mcq_optimization_history
      ADD COLUMN feedback_rating TEXT CHECK (feedback_rating IN ('helpful', 'not_helpful', 'try_alternative')),
      ADD COLUMN feedback_at TIMESTAMPTZ;
  END IF;
END;
$$;

-- RLS for claude_mcq_feedback
ALTER TABLE public.claude_mcq_feedback ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'claude_mcq_feedback'
      AND policyname = 'Users can insert their own feedback'
  ) THEN
    CREATE POLICY "Users can insert their own feedback"
      ON public.claude_mcq_feedback
      FOR INSERT
      WITH CHECK (auth.uid() = user_id OR user_id IS NULL);
  END IF;
END;
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'claude_mcq_feedback'
      AND policyname = 'Users can view their own feedback'
  ) THEN
    CREATE POLICY "Users can view their own feedback"
      ON public.claude_mcq_feedback
      FOR SELECT
      USING (auth.uid() = user_id OR user_id IS NULL);
  END IF;
END;
$$;
