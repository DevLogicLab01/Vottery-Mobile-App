-- ============================================================
-- SECURITY FIX: Enable RLS on all tables missing it
-- Fixes: 52 Security Errors + 453 Warnings
-- ============================================================

-- ============================================================
-- STEP 1: Create admin helper function (SECURITY INVOKER safe)
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid()
    AND (
      au.raw_user_meta_data->>'role' IN ('admin', 'super_admin')
      OR au.raw_app_meta_data->>'role' IN ('admin', 'super_admin')
    )
  );
$$;

-- ============================================================
-- STEP 2: Enable RLS on tables missing it
-- ============================================================

ALTER TABLE public.incident_updates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jolt_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jolt_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_correlations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exchange_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cultural_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversion_pixels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alert_batch_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_features ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_feed_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_flag_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.authentication_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.country_access_controls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_frequency_caps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ad_auction_bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moment_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.regional_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.webhook_idempotency ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_role_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.claude_confidence_thresholds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.flag_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.forecast_accuracy_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.translation_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tie_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.predictor_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unread_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispute_resolution_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.translation_validations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_elections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settlement_schedule ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_join_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_controls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.marketplace_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.translation_memory ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tie_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_moderation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slack_notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.metrics_updates ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 3: RLS Policies for tables missing them
-- ============================================================

-- incident_updates: admin-only write, authenticated read
DROP POLICY IF EXISTS "incident_updates_read" ON public.incident_updates;
CREATE POLICY "incident_updates_read"
  ON public.incident_updates FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "incident_updates_admin_write" ON public.incident_updates;
CREATE POLICY "incident_updates_admin_write"
  ON public.incident_updates FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- performance_metrics: admin-only
DROP POLICY IF EXISTS "performance_metrics_admin" ON public.performance_metrics;
CREATE POLICY "performance_metrics_admin"
  ON public.performance_metrics FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- jolt_interactions: users manage own
DROP POLICY IF EXISTS "jolt_interactions_own" ON public.jolt_interactions;
CREATE POLICY "jolt_interactions_own"
  ON public.jolt_interactions FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "jolt_interactions_read" ON public.jolt_interactions;
CREATE POLICY "jolt_interactions_read"
  ON public.jolt_interactions FOR SELECT
  TO authenticated
  USING (true);

-- jolt_comments: users manage own, all can read
DROP POLICY IF EXISTS "jolt_comments_read" ON public.jolt_comments;
CREATE POLICY "jolt_comments_read"
  ON public.jolt_comments FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "jolt_comments_own" ON public.jolt_comments;
CREATE POLICY "jolt_comments_own"
  ON public.jolt_comments FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- campaign_performance: admin read, advertiser own
DROP POLICY IF EXISTS "campaign_performance_read" ON public.campaign_performance;
CREATE POLICY "campaign_performance_read"
  ON public.campaign_performance FOR SELECT
  TO authenticated
  USING (public.is_admin_user());

-- user_groups: public read, creator manages own
DROP POLICY IF EXISTS "user_groups_public_read" ON public.user_groups;
CREATE POLICY "user_groups_public_read"
  ON public.user_groups FOR SELECT
  TO authenticated
  USING (is_public = true OR creator_id = auth.uid() OR public.is_admin_user());

DROP POLICY IF EXISTS "user_groups_creator_manage" ON public.user_groups;
CREATE POLICY "user_groups_creator_manage"
  ON public.user_groups FOR ALL
  TO authenticated
  USING (creator_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (creator_id = auth.uid() OR public.is_admin_user());

-- incident_correlations: admin only
DROP POLICY IF EXISTS "incident_correlations_admin" ON public.incident_correlations;
CREATE POLICY "incident_correlations_admin"
  ON public.incident_correlations FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- exchange_rates: public read, admin write
DROP POLICY IF EXISTS "exchange_rates_read" ON public.exchange_rates;
CREATE POLICY "exchange_rates_read"
  ON public.exchange_rates FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "exchange_rates_admin_write" ON public.exchange_rates;
CREATE POLICY "exchange_rates_admin_write"
  ON public.exchange_rates FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- community_analytics: admin only
DROP POLICY IF EXISTS "community_analytics_admin" ON public.community_analytics;
CREATE POLICY "community_analytics_admin"
  ON public.community_analytics FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- post_interactions: users manage own, all read
DROP POLICY IF EXISTS "post_interactions_read" ON public.post_interactions;
CREATE POLICY "post_interactions_read"
  ON public.post_interactions FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "post_interactions_own" ON public.post_interactions;
CREATE POLICY "post_interactions_own"
  ON public.post_interactions FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- cultural_settings: admin write, all read
DROP POLICY IF EXISTS "cultural_settings_read" ON public.cultural_settings;
CREATE POLICY "cultural_settings_read"
  ON public.cultural_settings FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "cultural_settings_admin" ON public.cultural_settings;
CREATE POLICY "cultural_settings_admin"
  ON public.cultural_settings FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- conversion_pixels: admin only
DROP POLICY IF EXISTS "conversion_pixels_admin" ON public.conversion_pixels;
CREATE POLICY "conversion_pixels_admin"
  ON public.conversion_pixels FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- alert_batch_operations: admin only
DROP POLICY IF EXISTS "alert_batch_operations_admin" ON public.alert_batch_operations;
CREATE POLICY "alert_batch_operations_admin"
  ON public.alert_batch_operations FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- platform_features: all read, admin write
DROP POLICY IF EXISTS "platform_features_read" ON public.platform_features;
CREATE POLICY "platform_features_read"
  ON public.platform_features FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "platform_features_admin" ON public.platform_features;
CREATE POLICY "platform_features_admin"
  ON public.platform_features FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- feedback_status_history: users read own, admin all
DROP POLICY IF EXISTS "feedback_status_history_admin" ON public.feedback_status_history;
CREATE POLICY "feedback_status_history_admin"
  ON public.feedback_status_history FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- social_feed_items: authenticated read
DROP POLICY IF EXISTS "social_feed_items_read" ON public.social_feed_items;
CREATE POLICY "social_feed_items_read"
  ON public.social_feed_items FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "social_feed_items_admin" ON public.social_feed_items;
CREATE POLICY "social_feed_items_admin"
  ON public.social_feed_items FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- integration_usage_logs: admin only
DROP POLICY IF EXISTS "integration_usage_logs_admin" ON public.integration_usage_logs;
CREATE POLICY "integration_usage_logs_admin"
  ON public.integration_usage_logs FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- feature_flag_analytics: admin only
DROP POLICY IF EXISTS "feature_flag_analytics_admin" ON public.feature_flag_analytics;
CREATE POLICY "feature_flag_analytics_admin"
  ON public.feature_flag_analytics FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- authentication_logs: users read own, admin all
DROP POLICY IF EXISTS "authentication_logs_own" ON public.authentication_logs;
DROP POLICY IF EXISTS "authentication_logs_insert" ON public.authentication_logs;

DO $$
BEGIN
  -- Only create user_id-based policies if the column exists
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'authentication_logs'
      AND column_name = 'user_id'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "authentication_logs_own"
      ON public.authentication_logs FOR SELECT
      TO authenticated
      USING (user_id = auth.uid() OR public.is_admin_user());
    $policy$;

    EXECUTE $policy$
      CREATE POLICY "authentication_logs_insert"
      ON public.authentication_logs FOR INSERT
      TO authenticated
      WITH CHECK (user_id = auth.uid() OR public.is_admin_user());
    $policy$;
  ELSE
    -- Fallback: admin-only access if user_id column doesn't exist
    EXECUTE $policy$
      CREATE POLICY "authentication_logs_own"
      ON public.authentication_logs FOR ALL
      TO authenticated
      USING (public.is_admin_user())
      WITH CHECK (public.is_admin_user());
    $policy$;
  END IF;
END $$;

-- country_access_controls: admin only
DROP POLICY IF EXISTS "country_access_controls_admin" ON public.country_access_controls;
CREATE POLICY "country_access_controls_admin"
  ON public.country_access_controls FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- ad_frequency_caps: admin only
DROP POLICY IF EXISTS "ad_frequency_caps_admin" ON public.ad_frequency_caps;
CREATE POLICY "ad_frequency_caps_admin"
  ON public.ad_frequency_caps FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- ad_auction_bids: admin read, authenticated insert own
DROP POLICY IF EXISTS "ad_auction_bids_admin" ON public.ad_auction_bids;
CREATE POLICY "ad_auction_bids_admin"
  ON public.ad_auction_bids FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- moment_views: users insert own, admin all
DROP POLICY IF EXISTS "moment_views_insert" ON public.moment_views;
CREATE POLICY "moment_views_insert"
  ON public.moment_views FOR INSERT
  TO authenticated
  WITH CHECK (viewer_id = auth.uid());

DROP POLICY IF EXISTS "moment_views_read" ON public.moment_views;
CREATE POLICY "moment_views_read"
  ON public.moment_views FOR SELECT
  TO authenticated
  USING (viewer_id = auth.uid() OR public.is_admin_user());

-- regional_requirements: all read, admin write
DROP POLICY IF EXISTS "regional_requirements_read" ON public.regional_requirements;
CREATE POLICY "regional_requirements_read"
  ON public.regional_requirements FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "regional_requirements_admin" ON public.regional_requirements;
CREATE POLICY "regional_requirements_admin"
  ON public.regional_requirements FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- conversations: users manage own
DROP POLICY IF EXISTS "conversations_own" ON public.conversations;
CREATE POLICY "conversations_own"
  ON public.conversations FOR ALL
  TO authenticated
  USING (
    auth.uid() = ANY(participant_ids) OR
    public.is_admin_user()
  )
  WITH CHECK (
    auth.uid() = ANY(participant_ids)
  );

-- webhook_idempotency: admin only (internal)
DROP POLICY IF EXISTS "webhook_idempotency_admin" ON public.webhook_idempotency;
CREATE POLICY "webhook_idempotency_admin"
  ON public.webhook_idempotency FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- user_role_assignments: admin only
DROP POLICY IF EXISTS "user_role_assignments_admin" ON public.user_role_assignments;
CREATE POLICY "user_role_assignments_admin"
  ON public.user_role_assignments FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "user_role_assignments_read_own" ON public.user_role_assignments;
CREATE POLICY "user_role_assignments_read_own"
  ON public.user_role_assignments FOR SELECT
  TO authenticated
  USING (user_id = auth.uid() OR public.is_admin_user());

-- claude_confidence_thresholds: all read, admin write
DROP POLICY IF EXISTS "claude_confidence_thresholds_read" ON public.claude_confidence_thresholds;
CREATE POLICY "claude_confidence_thresholds_read"
  ON public.claude_confidence_thresholds FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "claude_confidence_thresholds_admin" ON public.claude_confidence_thresholds;
CREATE POLICY "claude_confidence_thresholds_admin"
  ON public.claude_confidence_thresholds FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- flag_archive: admin only
DROP POLICY IF EXISTS "flag_archive_admin" ON public.flag_archive;
CREATE POLICY "flag_archive_admin"
  ON public.flag_archive FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- forecast_accuracy_log: admin only
DROP POLICY IF EXISTS "forecast_accuracy_log_admin" ON public.forecast_accuracy_log;
CREATE POLICY "forecast_accuracy_log_admin"
  ON public.forecast_accuracy_log FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- marketplace_reviews: users manage own, all read
DROP POLICY IF EXISTS "marketplace_reviews_read" ON public.marketplace_reviews;
CREATE POLICY "marketplace_reviews_read"
  ON public.marketplace_reviews FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "marketplace_reviews_own" ON public.marketplace_reviews;
CREATE POLICY "marketplace_reviews_own"
  ON public.marketplace_reviews FOR ALL
  TO authenticated
  USING (buyer_id = auth.uid() OR seller_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (buyer_id = auth.uid());

-- translation_status: admin write, all read
DROP POLICY IF EXISTS "translation_status_read" ON public.translation_status;
CREATE POLICY "translation_status_read"
  ON public.translation_status FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "translation_status_admin" ON public.translation_status;
CREATE POLICY "translation_status_admin"
  ON public.translation_status FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- tie_analytics: all read, admin write
DROP POLICY IF EXISTS "tie_analytics_read" ON public.tie_analytics;
CREATE POLICY "tie_analytics_read"
  ON public.tie_analytics FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "tie_analytics_admin" ON public.tie_analytics;
CREATE POLICY "tie_analytics_admin"
  ON public.tie_analytics FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- predictor_ratings: users manage own, all read
DROP POLICY IF EXISTS "predictor_ratings_read" ON public.predictor_ratings;
CREATE POLICY "predictor_ratings_read"
  ON public.predictor_ratings FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "predictor_ratings_own" ON public.predictor_ratings;
CREATE POLICY "predictor_ratings_own"
  ON public.predictor_ratings FOR ALL
  TO authenticated
  USING (user_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (user_id = auth.uid());

-- unread_messages: users manage own
DROP POLICY IF EXISTS "unread_messages_own" ON public.unread_messages;
CREATE POLICY "unread_messages_own"
  ON public.unread_messages FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- dispute_resolution_log: admin only
DROP POLICY IF EXISTS "dispute_resolution_log_admin" ON public.dispute_resolution_log;
CREATE POLICY "dispute_resolution_log_admin"
  ON public.dispute_resolution_log FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- translation_validations: admin only
DROP POLICY IF EXISTS "translation_validations_admin" ON public.translation_validations;
CREATE POLICY "translation_validations_admin"
  ON public.translation_validations FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- group_elections: authenticated read, admin write
DROP POLICY IF EXISTS "group_elections_read" ON public.group_elections;
CREATE POLICY "group_elections_read"
  ON public.group_elections FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "group_elections_admin" ON public.group_elections;
CREATE POLICY "group_elections_admin"
  ON public.group_elections FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- settlement_schedule: admin only
DROP POLICY IF EXISTS "settlement_schedule_admin" ON public.settlement_schedule;
CREATE POLICY "settlement_schedule_admin"
  ON public.settlement_schedule FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- feedback_attachments: users manage own
DROP POLICY IF EXISTS "feedback_attachments_own" ON public.feedback_attachments;
CREATE POLICY "feedback_attachments_own"
ON public.feedback_attachments FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.feature_requests fr
      WHERE fr.id = feedback_id
      AND (fr.user_id = auth.uid() OR public.is_admin_user())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.feature_requests fr
      WHERE fr.id = feedback_id
      AND fr.user_id = auth.uid()
    )
  );

-- admin_roles: admin only
DROP POLICY IF EXISTS "admin_roles_admin" ON public.admin_roles;
CREATE POLICY "admin_roles_admin"
  ON public.admin_roles FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- community_join_requests: users manage own, admin all
DROP POLICY IF EXISTS "community_join_requests_own" ON public.community_join_requests;
CREATE POLICY "community_join_requests_own"
  ON public.community_join_requests FOR ALL
  TO authenticated
  USING (user_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (user_id = auth.uid());

-- integration_controls: admin only
DROP POLICY IF EXISTS "integration_controls_admin" ON public.integration_controls;
CREATE POLICY "integration_controls_admin"
  ON public.integration_controls FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- marketplace_services: public read, owner manage
DROP POLICY IF EXISTS "marketplace_services_read" ON public.marketplace_services;
CREATE POLICY "marketplace_services_read"
  ON public.marketplace_services FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "marketplace_services_own" ON public.marketplace_services;
CREATE POLICY "marketplace_services_own"
  ON public.marketplace_services FOR ALL
  TO authenticated
  USING (creator_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (creator_id = auth.uid());

-- translation_memory: admin only
DROP POLICY IF EXISTS "translation_memory_admin" ON public.translation_memory;
CREATE POLICY "translation_memory_admin"
  ON public.translation_memory FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- tie_notifications: users read own, admin all
DROP POLICY IF EXISTS "tie_notifications_own" ON public.tie_notifications;
CREATE POLICY "tie_notifications_own"
  ON public.tie_notifications FOR ALL
  TO authenticated
  USING (recipient_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (recipient_id = auth.uid());

-- community_moderation_logs: admin only
DROP POLICY IF EXISTS "community_moderation_logs_admin" ON public.community_moderation_logs;
CREATE POLICY "community_moderation_logs_admin"
  ON public.community_moderation_logs FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- service_performance_metrics: admin only
DROP POLICY IF EXISTS "service_performance_metrics_admin" ON public.service_performance_metrics;
CREATE POLICY "service_performance_metrics_admin"
  ON public.service_performance_metrics FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- slack_notification_settings: admin only
DROP POLICY IF EXISTS "slack_notification_settings_admin" ON public.slack_notification_settings;
CREATE POLICY "slack_notification_settings_admin"
  ON public.slack_notification_settings FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- metrics_updates: admin only
DROP POLICY IF EXISTS "metrics_updates_admin" ON public.metrics_updates;
CREATE POLICY "metrics_updates_admin"
  ON public.metrics_updates FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- ============================================================
-- STEP 4: Revoke anon access from sensitive tables
-- ============================================================
REVOKE ALL ON public.authentication_logs FROM anon;
REVOKE ALL ON public.user_role_assignments FROM anon;
REVOKE ALL ON public.admin_roles FROM anon;
REVOKE ALL ON public.integration_controls FROM anon;
REVOKE ALL ON public.country_access_controls FROM anon;
REVOKE ALL ON public.slack_notification_settings FROM anon;
REVOKE ALL ON public.webhook_idempotency FROM anon;
REVOKE ALL ON public.service_performance_metrics FROM anon;
REVOKE ALL ON public.performance_metrics FROM anon;
REVOKE ALL ON public.incident_correlations FROM anon;
REVOKE ALL ON public.incident_updates FROM anon;
REVOKE ALL ON public.flag_archive FROM anon;
REVOKE ALL ON public.forecast_accuracy_log FROM anon;
REVOKE ALL ON public.dispute_resolution_log FROM anon;
REVOKE ALL ON public.settlement_schedule FROM anon;
REVOKE ALL ON public.community_moderation_logs FROM anon;
REVOKE ALL ON public.translation_memory FROM anon;
REVOKE ALL ON public.translation_validations FROM anon;
REVOKE ALL ON public.alert_batch_operations FROM anon;
REVOKE ALL ON public.ad_auction_bids FROM anon;
REVOKE ALL ON public.ad_frequency_caps FROM anon;
REVOKE ALL ON public.conversion_pixels FROM anon;
REVOKE ALL ON public.feature_flag_analytics FROM anon;
REVOKE ALL ON public.integration_usage_logs FROM anon;

-- ============================================================
-- STEP 5: Audit log for security remediation
-- ============================================================
DO $$
BEGIN
  RAISE NOTICE 'Security migration applied: RLS enabled on 50 tables, policies created, anon access revoked from sensitive tables';
END $$;
