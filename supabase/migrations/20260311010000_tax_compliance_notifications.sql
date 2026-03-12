-- Tax Compliance Notifications System
-- Automated Resend email alerts, push notifications, SMS alerts via Twilio

-- =====================================================
-- 1. TAX NOTIFICATION TYPES
-- =====================================================

DROP TYPE IF EXISTS public.tax_notification_type CASCADE;
CREATE TYPE public.tax_notification_type AS ENUM (
  'expiration_90_days',
  'expiration_60_days',
  'expiration_30_days',
  'expiration_7_days',
  'document_expired',
  'compliance_violation',
  'jurisdiction_status_change',
  'weekly_compliance_digest',
  'monthly_compliance_report',
  'filing_deadline_reminder'
);

DROP TYPE IF EXISTS public.tax_notification_channel CASCADE;
CREATE TYPE public.tax_notification_channel AS ENUM (
  'email',
  'push',
  'sms'
);

DROP TYPE IF EXISTS public.tax_notification_status CASCADE;
CREATE TYPE public.tax_notification_status AS ENUM (
  'pending',
  'sent',
  'delivered',
  'opened',
  'clicked',
  'failed',
  'bounced'
);

-- =====================================================
-- 2. TAX NOTIFICATION TABLES
-- =====================================================

-- Tax notification preferences
CREATE TABLE IF NOT EXISTS public.tax_notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  notification_type public.tax_notification_type NOT NULL,
  email_enabled BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT true,
  sms_enabled BOOLEAN DEFAULT false,
  preferred_time TIME DEFAULT '09:00:00',
  timezone TEXT DEFAULT 'UTC',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(creator_id, notification_type)
);

CREATE INDEX IF NOT EXISTS idx_tax_notification_preferences_creator_id ON public.tax_notification_preferences(creator_id);

-- Tax notification history
CREATE TABLE IF NOT EXISTS public.tax_notification_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  document_id UUID REFERENCES public.tax_compliance_documents(id) ON DELETE SET NULL,
  notification_type public.tax_notification_type NOT NULL,
  channel public.tax_notification_channel NOT NULL,
  status public.tax_notification_status DEFAULT 'pending'::public.tax_notification_status,
  subject TEXT,
  message_body TEXT,
  recipient_email TEXT,
  recipient_phone TEXT,
  external_id TEXT, -- Resend email ID or Twilio message SID
  sent_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  opened_at TIMESTAMPTZ,
  clicked_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  failure_reason TEXT,
  metadata JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tax_notification_history_creator_id ON public.tax_notification_history(creator_id);
CREATE INDEX IF NOT EXISTS idx_tax_notification_history_document_id ON public.tax_notification_history(document_id);
CREATE INDEX IF NOT EXISTS idx_tax_notification_history_status ON public.tax_notification_history(status);
CREATE INDEX IF NOT EXISTS idx_tax_notification_history_sent_at ON public.tax_notification_history(sent_at);

-- Tax notification queue (for batch processing)
CREATE TABLE IF NOT EXISTS public.tax_notification_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  document_id UUID REFERENCES public.tax_compliance_documents(id) ON DELETE CASCADE,
  notification_type public.tax_notification_type NOT NULL,
  channel public.tax_notification_channel NOT NULL,
  scheduled_for TIMESTAMPTZ NOT NULL,
  priority INTEGER DEFAULT 0,
  payload JSONB DEFAULT '{}'::JSONB,
  processed BOOLEAN DEFAULT false,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_tax_notification_queue_scheduled_for ON public.tax_notification_queue(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_tax_notification_queue_processed ON public.tax_notification_queue(processed);
CREATE INDEX IF NOT EXISTS idx_tax_notification_queue_creator_id ON public.tax_notification_queue(creator_id);

-- Tax notification templates
CREATE TABLE IF NOT EXISTS public.tax_notification_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_type public.tax_notification_type NOT NULL,
  document_type public.tax_document_type,
  channel public.tax_notification_channel NOT NULL,
  subject_template TEXT,
  body_template TEXT,
  variables JSONB DEFAULT '[]'::JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(notification_type, document_type, channel)
);

CREATE INDEX IF NOT EXISTS idx_tax_notification_templates_notification_type ON public.tax_notification_templates(notification_type);
CREATE INDEX IF NOT EXISTS idx_tax_notification_templates_is_active ON public.tax_notification_templates(is_active);

-- =====================================================
-- 3. RLS POLICIES
-- =====================================================

-- Tax notification preferences
ALTER TABLE public.tax_notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own notification preferences" ON public.tax_notification_preferences;
CREATE POLICY "Creators can view own notification preferences" ON public.tax_notification_preferences
  FOR SELECT USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can insert own notification preferences" ON public.tax_notification_preferences;
CREATE POLICY "Creators can insert own notification preferences" ON public.tax_notification_preferences
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators can update own notification preferences" ON public.tax_notification_preferences;
CREATE POLICY "Creators can update own notification preferences" ON public.tax_notification_preferences
  FOR UPDATE USING (auth.uid() = creator_id);

-- Tax notification history
ALTER TABLE public.tax_notification_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Creators can view own notification history" ON public.tax_notification_history;
CREATE POLICY "Creators can view own notification history" ON public.tax_notification_history
  FOR SELECT USING (auth.uid() = creator_id);

-- Tax notification queue (service role only)
ALTER TABLE public.tax_notification_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Service role can manage notification queue" ON public.tax_notification_queue;
CREATE POLICY "Service role can manage notification queue" ON public.tax_notification_queue
  FOR ALL USING (auth.role() = 'service_role');

-- Tax notification templates (read-only for authenticated users)
ALTER TABLE public.tax_notification_templates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can view templates" ON public.tax_notification_templates;
CREATE POLICY "Authenticated users can view templates" ON public.tax_notification_templates
  FOR SELECT USING (auth.role() = 'authenticated');

-- =====================================================
-- 4. HELPER FUNCTIONS
-- =====================================================

-- Schedule tax expiration notifications
CREATE OR REPLACE FUNCTION public.schedule_tax_expiration_notifications()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_scheduled_count INTEGER := 0;
  v_doc RECORD;
  v_days_until_expiration INTEGER;
  v_notification_type public.tax_notification_type;
BEGIN
  -- Loop through documents expiring in next 90 days
  FOR v_doc IN
    SELECT *
    FROM public.tax_compliance_documents
    WHERE expires_at IS NOT NULL
    AND expires_at > CURRENT_TIMESTAMP
    AND expires_at <= CURRENT_TIMESTAMP + INTERVAL '90 days'
    AND status != 'expired'
  LOOP
    v_days_until_expiration := EXTRACT(DAY FROM (v_doc.expires_at - CURRENT_TIMESTAMP));

    -- Determine notification type based on days until expiration
    IF v_days_until_expiration <= 7 THEN
      v_notification_type := 'expiration_7_days';
    ELSIF v_days_until_expiration <= 30 THEN
      v_notification_type := 'expiration_30_days';
    ELSIF v_days_until_expiration <= 60 THEN
      v_notification_type := 'expiration_60_days';
    ELSE
      v_notification_type := 'expiration_90_days';
    END IF;

    -- Check if notification already sent for this document and type
    IF NOT EXISTS (
      SELECT 1 FROM public.tax_notification_history
      WHERE document_id = v_doc.id
      AND notification_type = v_notification_type
      AND status IN ('sent', 'delivered', 'opened')
    ) THEN
      -- Schedule email notification
      INSERT INTO public.tax_notification_queue (
        creator_id,
        document_id,
        notification_type,
        channel,
        scheduled_for,
        priority,
        payload
      ) VALUES (
        v_doc.creator_id,
        v_doc.id,
        v_notification_type,
        'email',
        CURRENT_TIMESTAMP + INTERVAL '5 minutes',
        CASE v_notification_type
          WHEN 'expiration_7_days' THEN 100
          WHEN 'expiration_30_days' THEN 75
          WHEN 'expiration_60_days' THEN 50
          ELSE 25
        END,
        jsonb_build_object(
          'document_type', v_doc.document_type,
          'tax_year', v_doc.tax_year,
          'expires_at', v_doc.expires_at,
          'days_until_expiration', v_days_until_expiration
        )
      );

      -- Schedule SMS for critical expirations (7 days or less)
      IF v_days_until_expiration <= 7 THEN
        INSERT INTO public.tax_notification_queue (
          creator_id,
          document_id,
          notification_type,
          channel,
          scheduled_for,
          priority,
          payload
        ) VALUES (
          v_doc.creator_id,
          v_doc.id,
          v_notification_type,
          'sms',
          CURRENT_TIMESTAMP + INTERVAL '5 minutes',
          100,
          jsonb_build_object(
            'document_type', v_doc.document_type,
            'tax_year', v_doc.tax_year,
            'expires_at', v_doc.expires_at,
            'days_until_expiration', v_days_until_expiration
          )
        );
      END IF;

      v_scheduled_count := v_scheduled_count + 1;
    END IF;
  END LOOP;

  RETURN v_scheduled_count;
END;
$$;

-- Get pending notifications for processing
CREATE OR REPLACE FUNCTION public.get_pending_tax_notifications(
  p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
  id UUID,
  creator_id UUID,
  document_id UUID,
  notification_type public.tax_notification_type,
  channel public.tax_notification_channel,
  payload JSONB,
  creator_email TEXT,
  creator_phone TEXT,
  creator_full_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    q.id,
    q.creator_id,
    q.document_id,
    q.notification_type,
    q.channel,
    q.payload,
    up.email AS creator_email,
    up.phone_number AS creator_phone,
    up.full_name AS creator_full_name
  FROM public.tax_notification_queue q
  JOIN public.user_profiles up ON up.id = q.creator_id
  WHERE q.processed = false
  AND q.scheduled_for <= CURRENT_TIMESTAMP
  ORDER BY q.priority DESC, q.scheduled_for ASC
  LIMIT p_limit;
END;
$$;

-- Mark notification as processed
CREATE OR REPLACE FUNCTION public.mark_tax_notification_processed(
  p_queue_id UUID,
  p_external_id TEXT DEFAULT NULL,
  p_status public.tax_notification_status DEFAULT 'sent'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.tax_notification_queue
  SET processed = true,
      processed_at = CURRENT_TIMESTAMP
  WHERE id = p_queue_id;

  -- Insert into history
  INSERT INTO public.tax_notification_history (
    creator_id,
    document_id,
    notification_type,
    channel,
    status,
    external_id,
    sent_at
  )
  SELECT 
    creator_id,
    document_id,
    notification_type,
    channel,
    p_status,
    p_external_id,
    CURRENT_TIMESTAMP
  FROM public.tax_notification_queue
  WHERE id = p_queue_id;
END;
$$;

-- =====================================================
-- 5. DEFAULT NOTIFICATION TEMPLATES
-- =====================================================

-- Insert default email templates
INSERT INTO public.tax_notification_templates (
  notification_type,
  document_type,
  channel,
  subject_template,
  body_template,
  variables
) VALUES
(
  'expiration_90_days',
  'form_1099_nec',
  'email',
  'Tax Document Expiring in 90 Days - {{document_type}}',
  '<h2>Tax Document Expiration Notice</h2><p>Your {{document_type}} for tax year {{tax_year}} will expire in {{days_until_expiration}} days on {{expires_at}}.</p><p>Please renew this document to maintain compliance.</p>',
  '["document_type", "tax_year", "days_until_expiration", "expires_at"]'
),
(
  'expiration_7_days',
  'form_1099_nec',
  'email',
  'URGENT: Tax Document Expiring in 7 Days - {{document_type}}',
  '<h2 style="color: red;">URGENT: Tax Document Expiration</h2><p>Your {{document_type}} for tax year {{tax_year}} will expire in {{days_until_expiration}} days on {{expires_at}}.</p><p><strong>Immediate action required to maintain compliance.</strong></p>',
  '["document_type", "tax_year", "days_until_expiration", "expires_at"]'
),
(
  'expiration_7_days',
  'form_1099_nec',
  'sms',
  NULL,
  'URGENT: Your {{document_type}} expires in {{days_until_expiration}} days. Renew now to maintain compliance.',
  '["document_type", "days_until_expiration"]'
)
ON CONFLICT (notification_type, document_type, channel) DO NOTHING;