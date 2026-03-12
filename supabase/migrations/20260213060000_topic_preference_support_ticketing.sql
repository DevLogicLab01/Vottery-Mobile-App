-- Topic Preference Collection & Support Ticketing System Migration
-- Batch 3: Swipeable onboarding cards with ML preference profiling and comprehensive support ticketing

-- ============================================================================
-- TOPIC PREFERENCE COLLECTION SYSTEM
-- ============================================================================

-- Support ticket categories enum
CREATE TYPE public.ticket_category AS ENUM (
  'technical',
  'billing',
  'election',
  'fraud',
  'account',
  'other'
);

-- Support ticket priority enum
CREATE TYPE public.ticket_priority AS ENUM (
  'low',
  'medium',
  'high',
  'urgent'
);

-- Support ticket status enum
CREATE TYPE public.ticket_status AS ENUM (
  'open',
  'in_progress',
  'waiting_for_user',
  'resolved',
  'closed'
);

-- Preference summary table for ML clustering
CREATE TABLE IF NOT EXISTS public.preference_summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  selected_categories JSONB DEFAULT '[]'::jsonb,
  persona_cluster TEXT,
  confidence_score DECIMAL(5,2) DEFAULT 0.0,
  total_swipes INTEGER DEFAULT 0,
  completion_percentage DECIMAL(5,2) DEFAULT 0.0,
  onboarding_completed BOOLEAN DEFAULT false,
  ab_test_variant TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- Engagement metrics for A/B testing
CREATE TABLE IF NOT EXISTS public.onboarding_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  variant TEXT NOT NULL,
  completion_time_seconds INTEGER,
  skip_count INTEGER DEFAULT 0,
  back_navigation_count INTEGER DEFAULT 0,
  total_interactions INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- SUPPORT TICKETING SYSTEM
-- ============================================================================

-- Support tickets table
CREATE TABLE IF NOT EXISTS public.support_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category public.ticket_category NOT NULL,
  priority public.ticket_priority NOT NULL,
  status public.ticket_status DEFAULT 'open',
  subject TEXT NOT NULL,
  description TEXT NOT NULL,
  assigned_agent_id UUID REFERENCES auth.users(id),
  sla_deadline TIMESTAMPTZ,
  first_response_at TIMESTAMPTZ,
  resolved_at TIMESTAMPTZ,
  closed_at TIMESTAMPTZ,
  satisfaction_rating INTEGER CHECK (satisfaction_rating BETWEEN 1 AND 5),
  agent_review TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ticket messages (conversation history)
CREATE TABLE IF NOT EXISTS public.ticket_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id),
  sender_type TEXT NOT NULL CHECK (sender_type IN ('user', 'agent', 'system')),
  message TEXT NOT NULL,
  is_internal_note BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Ticket attachments
CREATE TABLE IF NOT EXISTS public.ticket_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  message_id UUID REFERENCES public.ticket_messages(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  file_type TEXT NOT NULL,
  uploaded_by UUID NOT NULL REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- SLA configuration
CREATE TABLE IF NOT EXISTS public.ticket_sla_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category public.ticket_category NOT NULL,
  priority public.ticket_priority NOT NULL,
  response_time_hours INTEGER NOT NULL,
  resolution_time_hours INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(category, priority)
);

-- Ticket queue assignments
CREATE TABLE IF NOT EXISTS public.ticket_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  agent_id UUID REFERENCES auth.users(id),
  queue_position INTEGER,
  estimated_response_time TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(ticket_id)
);

-- FAQ articles for AI-powered suggestions
CREATE TABLE IF NOT EXISTS public.faq_articles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category public.ticket_category NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  keywords TEXT[],
  view_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Canned responses for common issues
CREATE TABLE IF NOT EXISTS public.canned_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category public.ticket_category NOT NULL,
  title TEXT NOT NULL,
  response_text TEXT NOT NULL,
  usage_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Ticket analytics
CREATE TABLE IF NOT EXISTS public.ticket_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date DATE NOT NULL,
  category public.ticket_category NOT NULL,
  total_tickets INTEGER DEFAULT 0,
  resolved_tickets INTEGER DEFAULT 0,
  avg_resolution_time_hours DECIMAL(10,2),
  avg_first_response_time_hours DECIMAL(10,2),
  avg_satisfaction_rating DECIMAL(3,2),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(date, category)
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_preference_summaries_user ON public.preference_summaries(user_id);
CREATE INDEX IF NOT EXISTS idx_onboarding_analytics_user ON public.onboarding_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_category ON public.support_tickets(category);
CREATE INDEX IF NOT EXISTS idx_support_tickets_priority ON public.support_tickets(priority);
CREATE INDEX IF NOT EXISTS idx_support_tickets_assigned ON public.support_tickets(assigned_agent_id);
CREATE INDEX IF NOT EXISTS idx_ticket_messages_ticket ON public.ticket_messages(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_ticket ON public.ticket_attachments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_queue_agent ON public.ticket_queue(agent_id);
CREATE INDEX IF NOT EXISTS idx_faq_articles_category ON public.faq_articles(category);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE public.preference_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.onboarding_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_sla_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faq_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.canned_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_analytics ENABLE ROW LEVEL SECURITY;

-- Preference summaries policies
CREATE POLICY preference_summaries_select ON public.preference_summaries
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY preference_summaries_insert ON public.preference_summaries
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY preference_summaries_update ON public.preference_summaries
  FOR UPDATE USING (auth.uid() = user_id);

-- Onboarding analytics policies
CREATE POLICY onboarding_analytics_insert ON public.onboarding_analytics
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Support tickets policies
CREATE POLICY support_tickets_select ON public.support_tickets
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = assigned_agent_id);

CREATE POLICY support_tickets_insert ON public.support_tickets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY support_tickets_update ON public.support_tickets
  FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = assigned_agent_id);

-- Ticket messages policies
CREATE POLICY ticket_messages_select ON public.ticket_messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets
      WHERE id = ticket_messages.ticket_id
      AND (user_id = auth.uid() OR assigned_agent_id = auth.uid())
    )
  );

CREATE POLICY ticket_messages_insert ON public.ticket_messages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.support_tickets
      WHERE id = ticket_messages.ticket_id
      AND (user_id = auth.uid() OR assigned_agent_id = auth.uid())
    )
  );

-- Ticket attachments policies
CREATE POLICY ticket_attachments_select ON public.ticket_attachments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets
      WHERE id = ticket_attachments.ticket_id
      AND (user_id = auth.uid() OR assigned_agent_id = auth.uid())
    )
  );

CREATE POLICY ticket_attachments_insert ON public.ticket_attachments
  FOR INSERT WITH CHECK (auth.uid() = uploaded_by);

-- SLA config policies (read-only for users)
CREATE POLICY ticket_sla_config_select ON public.ticket_sla_config
  FOR SELECT USING (true);

-- Ticket queue policies
CREATE POLICY ticket_queue_select ON public.ticket_queue
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.support_tickets
      WHERE id = ticket_queue.ticket_id
      AND (user_id = auth.uid() OR assigned_agent_id = auth.uid())
    )
  );

-- FAQ articles policies (public read)
CREATE POLICY faq_articles_select ON public.faq_articles
  FOR SELECT USING (is_active = true);

-- Canned responses policies (public read)
CREATE POLICY canned_responses_select ON public.canned_responses
  FOR SELECT USING (is_active = true);

-- Ticket analytics policies (public read)
CREATE POLICY ticket_analytics_select ON public.ticket_analytics
  FOR SELECT USING (true);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Auto-generate ticket number
CREATE OR REPLACE FUNCTION generate_ticket_number()
RETURNS TEXT AS $$
BEGIN
  RETURN 'TKT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- Auto-assign ticket number on insert
CREATE OR REPLACE FUNCTION auto_assign_ticket_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.ticket_number IS NULL THEN
    NEW.ticket_number := generate_ticket_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_assign_ticket_number
  BEFORE INSERT ON public.support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_ticket_number();

-- Calculate SLA deadline on ticket creation
CREATE OR REPLACE FUNCTION calculate_sla_deadline()
RETURNS TRIGGER AS $$
DECLARE
  response_hours INTEGER;
BEGIN
  SELECT response_time_hours INTO response_hours
  FROM public.ticket_sla_config
  WHERE category = NEW.category AND priority = NEW.priority;
  
  IF response_hours IS NOT NULL THEN
    NEW.sla_deadline := NOW() + (response_hours || ' hours')::INTERVAL;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_sla_deadline
  BEFORE INSERT ON public.support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION calculate_sla_deadline();

-- Update ticket updated_at timestamp
CREATE OR REPLACE FUNCTION update_ticket_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ticket_timestamp
  BEFORE UPDATE ON public.support_tickets
  FOR EACH ROW
  EXECUTE FUNCTION update_ticket_timestamp();

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Insert default SLA configurations
INSERT INTO public.ticket_sla_config (category, priority, response_time_hours, resolution_time_hours)
VALUES
  ('technical', 'urgent', 1, 4),
  ('technical', 'high', 2, 8),
  ('technical', 'medium', 4, 24),
  ('technical', 'low', 8, 48),
  ('billing', 'urgent', 1, 4),
  ('billing', 'high', 2, 8),
  ('billing', 'medium', 4, 24),
  ('billing', 'low', 8, 48),
  ('election', 'urgent', 1, 2),
  ('election', 'high', 2, 6),
  ('election', 'medium', 4, 12),
  ('election', 'low', 8, 24),
  ('fraud', 'urgent', 1, 2),
  ('fraud', 'high', 1, 4),
  ('fraud', 'medium', 2, 8),
  ('fraud', 'low', 4, 16),
  ('account', 'urgent', 1, 4),
  ('account', 'high', 2, 8),
  ('account', 'medium', 4, 24),
  ('account', 'low', 8, 48),
  ('other', 'urgent', 2, 8),
  ('other', 'high', 4, 12),
  ('other', 'medium', 8, 24),
  ('other', 'low', 12, 48)
ON CONFLICT (category, priority) DO NOTHING;

-- Insert sample FAQ articles
INSERT INTO public.faq_articles (category, title, content, keywords)
VALUES
  ('technical', 'How do I reset my password?', 'To reset your password, go to Settings > Security > Change Password. You will need to verify your identity via email or SMS.', ARRAY['password', 'reset', 'security', 'login']),
  ('billing', 'How do I update my payment method?', 'Navigate to Settings > Billing > Payment Methods. Click "Add Payment Method" and enter your card details. You can set it as default or remove old methods.', ARRAY['payment', 'billing', 'card', 'subscription']),
  ('election', 'How do I create an election?', 'Go to the Elections tab and click "Create Election". Fill in the election details, add candidates, set voting rules, and publish when ready.', ARRAY['election', 'create', 'voting', 'candidates']),
  ('fraud', 'How do I report suspicious activity?', 'If you notice suspicious activity, go to Help & Support > Report Problem > Fraud. Provide details and screenshots if possible. Our security team will investigate immediately.', ARRAY['fraud', 'report', 'security', 'suspicious']),
  ('account', 'How do I delete my account?', 'To delete your account, go to Settings > Account > Delete Account. This action is permanent and cannot be undone. All your data will be removed within 30 days.', ARRAY['account', 'delete', 'remove', 'data'])
ON CONFLICT DO NOTHING;

-- Insert sample canned responses
INSERT INTO public.canned_responses (category, title, response_text)
VALUES
  ('technical', 'Password Reset Instructions', 'Thank you for contacting support. To reset your password, please follow these steps: 1) Go to Settings > Security, 2) Click "Change Password", 3) Verify your identity via email/SMS, 4) Enter your new password. If you continue to experience issues, please let us know.'),
  ('billing', 'Payment Method Update', 'Thank you for reaching out. To update your payment method: 1) Navigate to Settings > Billing, 2) Click "Payment Methods", 3) Add your new card details, 4) Set it as default if needed. Your subscription will continue without interruption.'),
  ('election', 'Election Creation Guide', 'Thank you for your interest in creating an election. Here''s a quick guide: 1) Go to Elections > Create Election, 2) Fill in election details (title, description, dates), 3) Add candidates with photos and descriptions, 4) Configure voting rules, 5) Preview and publish. Let me know if you need help with any specific step.'),
  ('fraud', 'Fraud Report Acknowledgment', 'Thank you for reporting this issue. We take fraud and security very seriously. Our security team has been notified and will investigate this matter immediately. We will update you within 2 hours with our findings. Your account has been flagged for additional protection.'),
  ('account', 'Account Deletion Confirmation', 'We''re sorry to see you go. To proceed with account deletion: 1) Go to Settings > Account > Delete Account, 2) Confirm your decision, 3) Your data will be removed within 30 days. Please note this action is permanent and cannot be undone. Is there anything we can do to improve your experience?')
ON CONFLICT DO NOTHING;