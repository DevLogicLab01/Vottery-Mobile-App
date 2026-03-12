-- Migration: New features support tables
-- Timestamp: 20260228020000

-- Circuit breaker state table
CREATE TABLE IF NOT EXISTS public.circuit_breaker_state (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  service_name TEXT NOT NULL UNIQUE,
  state TEXT NOT NULL DEFAULT 'closed' CHECK (state IN ('open', 'closed', 'half_open')),
  failure_count INTEGER DEFAULT 0,
  rate_limiting_enabled BOOLEAN DEFAULT FALSE,
  rate_limit_rps INTEGER DEFAULT 1000,
  rollback_ready BOOLEAN DEFAULT FALSE,
  triggered_by TEXT,
  triggered_at TIMESTAMPTZ,
  test_id TEXT,
  regression_details JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Incident response log table
CREATE TABLE IF NOT EXISTS public.incident_response_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  action_type TEXT NOT NULL,
  trigger_reason TEXT,
  trigger_value DOUBLE PRECISION,
  threshold_value DOUBLE PRECISION,
  user_tier BIGINT,
  test_id TEXT,
  status TEXT DEFAULT 'pending',
  details JSONB DEFAULT '{}',
  triggered BOOLEAN DEFAULT FALSE,
  actions_taken TEXT[],
  errors TEXT[],
  message TEXT,
  executed_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Creator tax documents table
CREATE TABLE IF NOT EXISTS public.creator_tax_documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id TEXT UNIQUE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL CHECK (document_type IN ('W9', 'W8BEN', 'W8BEN_E')),
  file_url TEXT NOT NULL,
  upload_date TIMESTAMPTZ DEFAULT NOW(),
  verification_status TEXT DEFAULT 'pending' CHECK (verification_status IN ('pending', 'verified', 'rejected')),
  verified_at TIMESTAMPTZ,
  rejected_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Stripe webhook events table
CREATE TABLE IF NOT EXISTS public.stripe_webhook_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_id TEXT UNIQUE,
  event_type TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'processed', 'failed')),
  payout_id TEXT,
  amount INTEGER,
  currency TEXT DEFAULT 'usd',
  failure_reason TEXT,
  raw_payload JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- Payout reconciliation issues table
CREATE TABLE IF NOT EXISTS public.payout_reconciliation_issues (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  payout_id TEXT NOT NULL,
  issue_type TEXT NOT NULL,
  stripe_amount INTEGER,
  db_amount INTEGER,
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'escalated')),
  resolution_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- User notification preferences table (smart push timing)
CREATE TABLE IF NOT EXISTS public.user_notification_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  optimal_hours JSONB DEFAULT '[18, 19, 20]',
  timezone TEXT DEFAULT 'UTC',
  engagement_by_hour JSONB DEFAULT '{}',
  last_analyzed_at TIMESTAMPTZ DEFAULT NOW(),
  total_sessions_analyzed INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Moment polls table
CREATE TABLE IF NOT EXISTS public.moment_polls (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  moment_id UUID,
  question TEXT NOT NULL,
  options JSONB NOT NULL DEFAULT '[]',
  duration_seconds INTEGER DEFAULT 30,
  votes JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ
);

-- Moment viral scores table
CREATE TABLE IF NOT EXISTS public.moment_viral_scores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  moment_id UUID NOT NULL,
  creator_id UUID REFERENCES auth.users(id),
  viral_score DOUBLE PRECISION DEFAULT 0,
  viral_probability DOUBLE PRECISION DEFAULT 0,
  factors JSONB DEFAULT '{}',
  calculated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Blockchain vote receipts table
CREATE TABLE IF NOT EXISTS public.blockchain_vote_receipts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  receipt_id TEXT UNIQUE NOT NULL,
  vote_id UUID,
  voter_id UUID REFERENCES auth.users(id),
  election_id UUID,
  vote_hash TEXT NOT NULL,
  signature TEXT NOT NULL,
  block_number BIGINT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Carousel recommendation accuracy table
CREATE TABLE IF NOT EXISTS public.carousel_recommendation_accuracy (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  accuracy_score DOUBLE PRECISION NOT NULL,
  recommended_count INTEGER DEFAULT 0,
  engaged_count INTEGER DEFAULT 0,
  measured_at TIMESTAMPTZ DEFAULT NOW()
);

-- SLA violations table
CREATE TABLE IF NOT EXISTS public.sla_violations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  violation_type TEXT NOT NULL,
  screen_or_endpoint TEXT,
  current_value DOUBLE PRECISION,
  threshold_value DOUBLE PRECISION,
  severity TEXT DEFAULT 'warning' CHECK (severity IN ('warning', 'critical')),
  detected_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- Incident tickets table
CREATE TABLE IF NOT EXISTS public.incident_tickets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  severity TEXT DEFAULT 'medium',
  violations JSONB DEFAULT '[]',
  status TEXT DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- Incident correlations table
CREATE TABLE IF NOT EXISTS public.incident_correlations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  correlation_type TEXT NOT NULL,
  description TEXT,
  violations JSONB DEFAULT '[]',
  detected_at TIMESTAMPTZ DEFAULT NOW()
);

-- Telnyx critical alerts log table
CREATE TABLE IF NOT EXISTS public.telnyx_critical_alerts_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  alert_id TEXT UNIQUE DEFAULT gen_random_uuid()::TEXT,
  alert_type TEXT NOT NULL,
  recipient_phone TEXT,
  message_body TEXT NOT NULL,
  severity TEXT DEFAULT 'high',
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  acknowledged_at TIMESTAMPTZ
);

-- GA4 custom events table
CREATE TABLE IF NOT EXISTS public.ga4_custom_events (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  event_name TEXT NOT NULL,
  event_params JSONB DEFAULT '{}',
  user_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Election drafts table (for group collaborative creation)
CREATE TABLE IF NOT EXISTS public.election_drafts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID,
  title TEXT NOT NULL,
  description TEXT,
  created_by TEXT,
  creator_id UUID REFERENCES auth.users(id),
  status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending_approval', 'approved', 'rejected')),
  draft_data JSONB DEFAULT '{}',
  approved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Group member leaderboard table
CREATE TABLE IF NOT EXISTS public.group_member_leaderboard (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID NOT NULL,
  user_id UUID REFERENCES auth.users(id),
  member_name TEXT,
  score INTEGER DEFAULT 0,
  elections_created INTEGER DEFAULT 0,
  votes_attracted INTEGER DEFAULT 0,
  engagement_rate DOUBLE PRECISION DEFAULT 0,
  badges TEXT[] DEFAULT '{}',
  rank INTEGER,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- On-call schedule table
CREATE TABLE IF NOT EXISTS public.on_call_schedule (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_id UUID REFERENCES auth.users(id),
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Election integrity monitoring table
CREATE TABLE IF NOT EXISTS public.election_integrity_monitoring (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  election_id UUID,
  event_type TEXT NOT NULL,
  reason TEXT,
  blockchain_tps INTEGER,
  threshold INTEGER,
  risk_score DOUBLE PRECISION,
  triggered_by TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE public.circuit_breaker_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_response_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.creator_tax_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stripe_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_reconciliation_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moment_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moment_viral_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.blockchain_vote_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carousel_recommendation_accuracy ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sla_violations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.telnyx_critical_alerts_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ga4_custom_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_member_leaderboard ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.on_call_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.election_integrity_monitoring ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read/write their own data
DROP POLICY IF EXISTS "Users can manage own tax documents" ON public.creator_tax_documents;
CREATE POLICY "Users can manage own tax documents"
  ON public.creator_tax_documents
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own notification preferences" ON public.user_notification_preferences;
CREATE POLICY "Users can manage own notification preferences"
  ON public.user_notification_preferences
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can read own vote receipts" ON public.blockchain_vote_receipts;
CREATE POLICY "Users can read own vote receipts"
  ON public.blockchain_vote_receipts
  FOR SELECT USING (auth.uid() = voter_id);

DROP POLICY IF EXISTS "Authenticated users can insert vote receipts" ON public.blockchain_vote_receipts;
CREATE POLICY "Authenticated users can insert vote receipts"
  ON public.blockchain_vote_receipts
  FOR INSERT WITH CHECK (auth.uid() = voter_id);

DROP POLICY IF EXISTS "Authenticated users can read circuit breakers" ON public.circuit_breaker_state;
CREATE POLICY "Authenticated users can read circuit breakers"
  ON public.circuit_breaker_state
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read incident logs" ON public.incident_response_log;
CREATE POLICY "Authenticated users can read incident logs"
  ON public.incident_response_log
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert incident logs" ON public.incident_response_log;
CREATE POLICY "Authenticated users can insert incident logs"
  ON public.incident_response_log
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read webhook events" ON public.stripe_webhook_events;
CREATE POLICY "Authenticated users can read webhook events"
  ON public.stripe_webhook_events
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read reconciliation issues" ON public.payout_reconciliation_issues;
CREATE POLICY "Authenticated users can read reconciliation issues"
  ON public.payout_reconciliation_issues
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read election drafts" ON public.election_drafts;
CREATE POLICY "Authenticated users can read election drafts"
  ON public.election_drafts
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert election drafts" ON public.election_drafts;
CREATE POLICY "Authenticated users can insert election drafts"
  ON public.election_drafts
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read leaderboard" ON public.group_member_leaderboard;
CREATE POLICY "Authenticated users can read leaderboard"
  ON public.group_member_leaderboard
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read ga4 events" ON public.ga4_custom_events;
CREATE POLICY "Authenticated users can read ga4 events"
  ON public.ga4_custom_events
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert ga4 events" ON public.ga4_custom_events;
CREATE POLICY "Authenticated users can insert ga4 events"
  ON public.ga4_custom_events
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read sla violations" ON public.sla_violations;
CREATE POLICY "Authenticated users can read sla violations"
  ON public.sla_violations
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read telnyx alerts" ON public.telnyx_critical_alerts_log;
CREATE POLICY "Authenticated users can read telnyx alerts"
  ON public.telnyx_critical_alerts_log
  FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can read election integrity" ON public.election_integrity_monitoring;
CREATE POLICY "Authenticated users can read election integrity"
  ON public.election_integrity_monitoring
  FOR SELECT USING (auth.role() = 'authenticated');
