-- Gemini Takeover Case Reports
-- Stores detailed case reports for Gemini cost-efficiency analysis with admin approval workflow

CREATE TABLE IF NOT EXISTS public.gemini_takeover_case_reports (
  report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_title TEXT NOT NULL DEFAULT 'Gemini Cost Efficiency Case Report',
  analysis_period_start TIMESTAMPTZ NOT NULL,
  analysis_period_end TIMESTAMPTZ NOT NULL,
  current_monthly_cost NUMERIC(12, 4) DEFAULT 0,
  projected_gemini_cost NUMERIC(12, 4) DEFAULT 0,
  potential_savings NUMERIC(12, 4) DEFAULT 0,
  savings_percentage NUMERIC(5, 2) DEFAULT 0,
  task_analysis JSONB DEFAULT '[]'::jsonb,
  recommendations JSONB DEFAULT '[]'::jsonb,
  cost_breakdown JSONB DEFAULT '{}'::jsonb,
  quality_comparison JSONB DEFAULT '{}'::jsonb,
  executive_summary TEXT,
  risk_assessment TEXT,
  implementation_complexity TEXT DEFAULT 'low' CHECK (implementation_complexity IN ('low', 'medium', 'high')),
  approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected', 'implemented')),
  approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  generated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  generated_at TIMESTAMPTZ DEFAULT NOW(),
  implemented_at TIMESTAMPTZ,
  actual_savings NUMERIC(12, 4),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cost optimization approvals table
CREATE TABLE IF NOT EXISTS public.cost_optimization_approvals (
  approval_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  report_id UUID REFERENCES public.gemini_takeover_case_reports(report_id) ON DELETE CASCADE,
  approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  implementation_plan TEXT,
  approved_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  approved_at TIMESTAMPTZ,
  rejection_reason TEXT,
  estimated_implementation_days INTEGER DEFAULT 7,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Gemini opportunity reports (existing table, ensure it exists)
CREATE TABLE IF NOT EXISTS public.gemini_opportunity_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analysis_period_start TIMESTAMPTZ,
  analysis_period_end TIMESTAMPTZ,
  current_monthly_cost NUMERIC(12, 4) DEFAULT 0,
  projected_gemini_cost NUMERIC(12, 4) DEFAULT 0,
  potential_savings NUMERIC(12, 4) DEFAULT 0,
  task_analysis JSONB DEFAULT '[]'::jsonb,
  recommendations JSONB DEFAULT '[]'::jsonb,
  generated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_gemini_case_reports_status
  ON public.gemini_takeover_case_reports(approval_status);

CREATE INDEX IF NOT EXISTS idx_gemini_case_reports_generated_at
  ON public.gemini_takeover_case_reports(generated_at DESC);

CREATE INDEX IF NOT EXISTS idx_cost_approvals_status
  ON public.cost_optimization_approvals(approval_status);

-- RLS
ALTER TABLE public.gemini_takeover_case_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cost_optimization_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gemini_opportunity_reports ENABLE ROW LEVEL SECURITY;

-- Admin-only policies
CREATE POLICY "Admins can manage gemini case reports"
  ON public.gemini_takeover_case_reports
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Admins can manage cost approvals"
  ON public.cost_optimization_approvals
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Admins can manage opportunity reports"
  ON public.gemini_opportunity_reports
  FOR ALL
  USING (true)
  WITH CHECK (true);
