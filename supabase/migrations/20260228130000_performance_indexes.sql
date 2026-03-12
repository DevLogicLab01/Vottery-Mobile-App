-- ============================================================
-- PERFORMANCE FIX: Add missing indexes
-- Fixes: 2112 Performance Warnings + 2105 Suggestions
-- Addresses: 36 Slow Queries, 2.2 Avg Rows Per Call (N+1)
-- ============================================================

-- ============================================================
-- SECTION 1: Core user/auth table indexes
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_user_profiles_id ON public.user_profiles(id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at ON public.user_profiles(created_at DESC);

-- ============================================================
-- SECTION 2: Elections - most queried table
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_elections_creator_id ON public.elections(creator_id);
CREATE INDEX IF NOT EXISTS idx_elections_status ON public.elections(status);
CREATE INDEX IF NOT EXISTS idx_elections_created_at ON public.elections(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_elections_status_created ON public.elections(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_elections_creator_status ON public.elections(creator_id, status);
CREATE INDEX IF NOT EXISTS idx_elections_end_time ON public.elections(end_time);
CREATE INDEX IF NOT EXISTS idx_elections_start_time ON public.elections(start_time);
-- Partial index for active elections (most common query)
CREATE INDEX IF NOT EXISTS idx_elections_active
  ON public.elections(created_at DESC)
  WHERE status = 'active';

-- ============================================================
-- SECTION 3: Votes - high-frequency table
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_votes_user_id ON public.votes(user_id);
CREATE INDEX IF NOT EXISTS idx_votes_election_id ON public.votes(election_id);
CREATE INDEX IF NOT EXISTS idx_votes_created_at ON public.votes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_votes_user_election ON public.votes(user_id, election_id);
CREATE INDEX IF NOT EXISTS idx_votes_election_created ON public.votes(election_id, created_at DESC);

-- ============================================================
-- SECTION 4: VP Transactions - financial queries
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_vp_transactions_user_id ON public.vp_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_vp_transactions_created_at ON public.vp_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vp_transactions_user_created ON public.vp_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_vp_transactions_type ON public.vp_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_vp_transactions_user_type ON public.vp_transactions(user_id, transaction_type);

-- ============================================================
-- SECTION 5: Notifications - user-specific queries
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON public.notifications(user_id, created_at DESC);
-- Partial index for unread notifications
CREATE INDEX IF NOT EXISTS idx_notifications_unread
  ON public.notifications(user_id, created_at DESC)
  WHERE is_read = false;

-- ============================================================
-- SECTION 6: Social posts / feed
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_social_posts_user_id ON public.social_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_social_posts_created_at ON public.social_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_social_posts_user_created ON public.social_posts(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_social_posts_election_id ON public.social_posts(election_id);

-- ============================================================
-- SECTION 7: Gamification tables
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_created_at ON public.user_achievements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_levels_user_id ON public.user_levels(user_id);
CREATE INDEX IF NOT EXISTS idx_user_streaks_user_id ON public.user_streaks(user_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_entries_user_id ON public.leaderboard_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_entries_score ON public.leaderboard_entries(score DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_entries_period ON public.leaderboard_entries(period_type, score DESC);

-- ============================================================
-- SECTION 8: Quests
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_user_quests_user_id ON public.user_quests(user_id);
CREATE INDEX IF NOT EXISTS idx_user_quests_status ON public.user_quests(status);
CREATE INDEX IF NOT EXISTS idx_user_quests_user_status ON public.user_quests(user_id, status);
CREATE INDEX IF NOT EXISTS idx_quest_completions_user_id ON public.quest_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_quest_completions_quest_id ON public.quest_completions(quest_id);

-- ============================================================
-- SECTION 9: Messaging
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON public.messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_participant_ids ON public.conversations USING GIN(participant_ids);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON public.conversations(updated_at DESC);

-- ============================================================
-- SECTION 10: Security events
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_security_events_user_id ON public.security_events(user_id);
CREATE INDEX IF NOT EXISTS idx_security_events_created_at ON public.security_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_security_events_type ON public.security_events(event_type);
CREATE INDEX IF NOT EXISTS idx_security_events_severity ON public.security_events(severity);
CREATE INDEX IF NOT EXISTS idx_security_events_ip ON public.security_events(ip_address);

-- ============================================================
-- SECTION 11: Fraud detection
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_user_id ON public.fraud_alerts(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_created_at ON public.fraud_alerts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_status ON public.fraud_alerts(status);
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_severity ON public.fraud_alerts(severity);
-- Partial index for open fraud alerts
CREATE INDEX IF NOT EXISTS idx_fraud_alerts_open
  ON public.fraud_alerts(created_at DESC)
  WHERE status = 'open';

-- ============================================================
-- SECTION 12: Payouts
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_payouts_user_id ON public.payouts(user_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON public.payouts(status);
CREATE INDEX IF NOT EXISTS idx_payouts_created_at ON public.payouts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payouts_user_status ON public.payouts(user_id, status);
-- Partial index for pending payouts
CREATE INDEX IF NOT EXISTS idx_payouts_pending
  ON public.payouts(created_at DESC)
  WHERE status = 'pending';

-- ============================================================
-- SECTION 13: Carousel / content
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_carousel_items_creator_id ON public.carousel_items(creator_id);
CREATE INDEX IF NOT EXISTS idx_carousel_items_status ON public.carousel_items(status);
CREATE INDEX IF NOT EXISTS idx_carousel_items_created_at ON public.carousel_items(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_carousel_items_creator_status ON public.carousel_items(creator_id, status);

-- ============================================================
-- SECTION 14: Prediction pools
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_prediction_pools_election_id ON public.prediction_pools(election_id);
CREATE INDEX IF NOT EXISTS idx_prediction_pools_status ON public.prediction_pools(status);
CREATE INDEX IF NOT EXISTS idx_prediction_pools_created_at ON public.prediction_pools(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_prediction_entries_user_id ON public.prediction_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_prediction_entries_pool_id ON public.prediction_entries(pool_id);
CREATE INDEX IF NOT EXISTS idx_prediction_entries_user_pool ON public.prediction_entries(user_id, pool_id);

-- ============================================================
-- SECTION 15: AI service monitoring
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_ai_service_monitoring_service ON public.ai_service_monitoring(service_name);
CREATE INDEX IF NOT EXISTS idx_ai_service_monitoring_monitored_at ON public.ai_service_monitoring(monitored_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_service_costs_service ON public.ai_service_costs(service_name);
CREATE INDEX IF NOT EXISTS idx_ai_service_costs_recorded_at ON public.ai_service_costs(recorded_at DESC);

-- ============================================================
-- SECTION 16: SMS / notifications
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_sms_provider_health_provider ON public.sms_provider_health(provider);
CREATE INDEX IF NOT EXISTS idx_sms_provider_health_checked_at ON public.sms_provider_health(checked_at DESC);

-- ============================================================
-- SECTION 17: Audit logs
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON public.audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_table_name ON public.audit_logs(table_name);

-- ============================================================
-- SECTION 18: Creator tables
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_creator_accounts_user_id ON public.creator_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_creator_accounts_tier ON public.creator_accounts(tier);
CREATE INDEX IF NOT EXISTS idx_creator_earnings_creator_id ON public.creator_earnings(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_earnings_created_at ON public.creator_earnings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_creator_earnings_creator_created ON public.creator_earnings(creator_id, created_at DESC);

-- ============================================================
-- SECTION 19: Moments / Jolts
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_moments_creator_id ON public.moments(creator_id);
CREATE INDEX IF NOT EXISTS idx_moments_created_at ON public.moments(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_moments_status ON public.moments(status);
CREATE INDEX IF NOT EXISTS idx_jolts_creator_id ON public.jolts(creator_id);
CREATE INDEX IF NOT EXISTS idx_jolts_created_at ON public.jolts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_jolt_interactions_jolt_id ON public.jolt_interactions(jolt_id);
CREATE INDEX IF NOT EXISTS idx_jolt_interactions_user_id ON public.jolt_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_jolt_comments_jolt_id ON public.jolt_comments(jolt_id);
CREATE INDEX IF NOT EXISTS idx_jolt_comments_user_id ON public.jolt_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_moment_viral_scores_moment_id ON public.moment_viral_scores(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_viral_scores_creator_id ON public.moment_viral_scores(creator_id);

-- ============================================================
-- SECTION 20: Social connections
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower_following ON public.follows(follower_id, following_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_sender_id ON public.friend_requests(sender_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_receiver_id ON public.friend_requests(receiver_id);
CREATE INDEX IF NOT EXISTS idx_friend_requests_status ON public.friend_requests(status);

-- ============================================================
-- SECTION 21: Groups
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_user_groups_creator_id ON public.user_groups(creator_id);
CREATE INDEX IF NOT EXISTS idx_user_groups_created_at ON public.user_groups(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group_user ON public.group_members(group_id, user_id);

-- ============================================================
-- SECTION 22: Marketplace
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_marketplace_services_creator_id ON public.marketplace_services(creator_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_services_status ON public.marketplace_services(status);
CREATE INDEX IF NOT EXISTS idx_marketplace_reviews_service_id ON public.marketplace_reviews(service_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_reviews_reviewer_id ON public.marketplace_reviews(reviewer_id);

-- ============================================================
-- SECTION 23: Campaigns / Ads
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_campaigns_advertiser_id ON public.campaigns(advertiser_id);
CREATE INDEX IF NOT EXISTS idx_campaigns_status ON public.campaigns(status);
CREATE INDEX IF NOT EXISTS idx_campaigns_created_at ON public.campaigns(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_campaign_performance_campaign_id ON public.campaign_performance(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_performance_recorded_at ON public.campaign_performance(recorded_at DESC);

-- ============================================================
-- SECTION 24: Wallets
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON public.wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON public.wallet_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON public.wallet_transactions(transaction_type);

-- ============================================================
-- SECTION 25: Support tickets
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON public.support_tickets(created_at DESC);
-- Partial index for open tickets
CREATE INDEX IF NOT EXISTS idx_support_tickets_open
  ON public.support_tickets(created_at DESC)
  WHERE status IN ('open', 'pending');

-- ============================================================
-- SECTION 26: AB Testing
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_ab_testing_user_assignments_user_id ON public.ab_testing_user_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_ab_testing_user_assignments_experiment_id ON public.ab_testing_user_assignments(experiment_id);
CREATE INDEX IF NOT EXISTS idx_ab_testing_user_assignments_user_exp ON public.ab_testing_user_assignments(user_id, experiment_id);

-- ============================================================
-- SECTION 27: Gamification eligibility
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_gamification_user_eligibility_user_id ON public.gamification_user_eligibility(user_id);
CREATE INDEX IF NOT EXISTS idx_gamification_user_eligibility_campaign_id ON public.gamification_user_eligibility(campaign_id);
CREATE INDEX IF NOT EXISTS idx_gamification_user_eligibility_user_campaign ON public.gamification_user_eligibility(user_id, campaign_id);

-- ============================================================
-- SECTION 28: Creator unlocked achievements
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_creator_unlocked_achievements_creator_id ON public.creator_unlocked_achievements(creator_id);
CREATE INDEX IF NOT EXISTS idx_creator_unlocked_achievements_achievement_id ON public.creator_unlocked_achievements(achievement_id);

-- ============================================================
-- SECTION 29: Bulk operations
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_bulk_operation_logs_bulk_operation_id ON public.bulk_operation_logs(bulk_operation_id);
CREATE INDEX IF NOT EXISTS idx_bulk_operation_logs_created_at ON public.bulk_operation_logs(created_at DESC);

-- ============================================================
-- SECTION 30: Post interactions
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_post_interactions_post_id ON public.post_interactions(post_id);
CREATE INDEX IF NOT EXISTS idx_post_interactions_user_id ON public.post_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_post_interactions_user_post ON public.post_interactions(user_id, post_id);

-- ============================================================
-- SECTION 31: Authentication logs
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_authentication_logs_user_id ON public.authentication_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_authentication_logs_created_at ON public.authentication_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_authentication_logs_ip ON public.authentication_logs(ip_address);

-- ============================================================
-- SECTION 32: Unread messages
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_unread_messages_user_id ON public.unread_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_unread_messages_conversation_id ON public.unread_messages(conversation_id);

-- ============================================================
-- SECTION 33: Moment views
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_moment_views_moment_id ON public.moment_views(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_views_viewer_id ON public.moment_views(viewer_id);
CREATE INDEX IF NOT EXISTS idx_moment_views_viewed_at ON public.moment_views(viewed_at DESC);

-- ============================================================
-- SECTION 34: Predictor ratings
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_predictor_ratings_user_id ON public.predictor_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_predictor_ratings_election_id ON public.predictor_ratings(election_id);

-- ============================================================
-- SECTION 35: Community join requests
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_community_join_requests_user_id ON public.community_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_community_join_requests_status ON public.community_join_requests(status);

-- ============================================================
-- SECTION 36: Dispute resolution
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_dispute_resolution_log_created_at ON public.dispute_resolution_log(created_at DESC);

-- ============================================================
-- SECTION 37: Settlement schedule
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_settlement_schedule_status ON public.settlement_schedule(status);
CREATE INDEX IF NOT EXISTS idx_settlement_schedule_scheduled_at ON public.settlement_schedule(scheduled_at);

-- ============================================================
-- SECTION 38: Tie analytics
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_tie_analytics_election_id ON public.tie_analytics(election_id);

-- ============================================================
-- SECTION 39: Group elections
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_group_elections_group_id ON public.group_elections(group_id);
CREATE INDEX IF NOT EXISTS idx_group_elections_election_id ON public.group_elections(election_id);

-- ============================================================
-- SECTION 40: Feedback attachments
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_feedback_attachments_feedback_id ON public.feedback_attachments(feedback_id);

DO $$
BEGIN
  RAISE NOTICE 'Performance migration applied: 120+ indexes created across all major tables';
END $$;
