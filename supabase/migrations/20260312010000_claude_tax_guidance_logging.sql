-- Claude Tax Guidance Logging Tables
-- Track AI-powered tax recommendations and chatbot interactions

-- =====================================================
-- 1. CLAUDE TAX GUIDANCE LOGS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.claude_tax_guidance_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  guidance_type TEXT NOT NULL, -- tax_strategy, settlement_optimization, jurisdiction_guidance, quarterly_planning, document_analysis, compliance_risk, structure_comparison
  recommendations JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_claude_tax_guidance_logs_creator_id ON public.claude_tax_guidance_logs(creator_id);
CREATE INDEX IF NOT EXISTS idx_claude_tax_guidance_logs_guidance_type ON public.claude_tax_guidance_logs(guidance_type);
CREATE INDEX IF NOT EXISTS idx_claude_tax_guidance_logs_created_at ON public.claude_tax_guidance_logs(created_at);

-- =====================================================
-- 2. CLAUDE TAX CHATBOT LOGS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.claude_tax_chatbot_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  response TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_claude_tax_chatbot_logs_creator_id ON public.claude_tax_chatbot_logs(creator_id);
CREATE INDEX IF NOT EXISTS idx_claude_tax_chatbot_logs_created_at ON public.claude_tax_chatbot_logs(created_at);

-- =====================================================
-- 3. RLS POLICIES
-- =====================================================

-- Claude tax guidance logs
ALTER TABLE public.claude_tax_guidance_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own tax guidance logs" ON public.claude_tax_guidance_logs;
CREATE POLICY "Creators can view own tax guidance logs" ON public.claude_tax_guidance_logs
  FOR SELECT USING (auth.uid() = creator_id);

-- Claude tax chatbot logs
ALTER TABLE public.claude_tax_chatbot_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own chatbot logs" ON public.claude_tax_chatbot_logs;
CREATE POLICY "Creators can view own chatbot logs" ON public.claude_tax_chatbot_logs
  FOR SELECT USING (auth.uid() = creator_id);