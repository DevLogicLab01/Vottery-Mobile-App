-- MCQ Optimization History Table
CREATE TABLE IF NOT EXISTS public.mcq_optimization_history (
  optimization_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mcq_id UUID REFERENCES public.election_mcqs(id) ON DELETE CASCADE,
  original_question_text TEXT,
  original_options JSONB,
  improved_question_text TEXT,
  improved_options JSONB,
  optimization_type VARCHAR(50) CHECK (
    optimization_type IN (
      'wording_clarity',
      'better_options',
      'difficulty_adjustment',
      'alternative_question'
    )
  ),
  applied_at TIMESTAMPTZ DEFAULT NOW(),
  applied_by UUID REFERENCES public.user_profiles(id),
  accuracy_before DECIMAL(5, 2),
  accuracy_after DECIMAL(5, 2)
);

CREATE INDEX IF NOT EXISTS idx_optimization_history_mcq_applied
  ON public.mcq_optimization_history(mcq_id, applied_at);

-- MCQ Performance Tracking Table
CREATE TABLE IF NOT EXISTS public.mcq_performance_tracking (
  tracking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  mcq_id UUID REFERENCES public.election_mcqs(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  total_responses INTEGER DEFAULT 0,
  correct_responses INTEGER DEFAULT 0,
  accuracy_rate DECIMAL(5, 2),
  avg_response_time_seconds INTEGER,
  CONSTRAINT unique_mcq_date UNIQUE (mcq_id, date)
);

CREATE INDEX IF NOT EXISTS idx_performance_tracking_mcq_date
  ON public.mcq_performance_tracking(mcq_id, date DESC);

-- RLS Policies for mcq_optimization_history
ALTER TABLE public.mcq_optimization_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can view optimization history" ON public.mcq_optimization_history;
CREATE POLICY "Authenticated users can view optimization history"
  ON public.mcq_optimization_history
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can insert their own optimization history" ON public.mcq_optimization_history;
CREATE POLICY "Users can insert their own optimization history"
  ON public.mcq_optimization_history
  FOR INSERT
  WITH CHECK (auth.uid() = applied_by);

-- RLS Policies for mcq_performance_tracking
ALTER TABLE public.mcq_performance_tracking ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can view performance tracking" ON public.mcq_performance_tracking;
CREATE POLICY "Authenticated users can view performance tracking"
  ON public.mcq_performance_tracking
  FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Service role can manage performance tracking" ON public.mcq_performance_tracking;
CREATE POLICY "Service role can manage performance tracking"
  ON public.mcq_performance_tracking
  FOR ALL
  USING (auth.role() = 'service_role');
