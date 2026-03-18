// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../presentation/route_placeholder_screen/route_placeholder_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/social_media_home_feed/social_media_home_feed.dart';
import '../presentation/social_home_feed/social_home_feed.dart';
import '../presentation/vote_dashboard/vote_dashboard.dart';
import '../presentation/vote_dashboard/vote_dashboard_initial_page.dart';
import '../presentation/vote_casting/vote_casting.dart';
import '../presentation/vote_results/vote_results.dart';
import '../presentation/vote_history/vote_history.dart';
import '../presentation/vote_analytics/vote_analytics.dart';
import '../presentation/vote_discovery/vote_discovery.dart';
import '../presentation/create_vote/create_vote.dart';
import '../presentation/election_creation_studio/election_creation_studio.dart';
import '../presentation/user_profile/user_profile.dart';
import '../presentation/admin_dashboard/admin_dashboard.dart';
import '../presentation/facebook_style_profile_menu/facebook_style_profile_menu.dart';
import '../presentation/gamification_hub/gamification_hub.dart';
import '../presentation/unified_gamification_dashboard/unified_gamification_dashboard.dart';
import '../presentation/quest_management_dashboard/quest_management_dashboard.dart';
import '../presentation/ai_quest_generation/ai_quest_generation.dart';
import '../presentation/feed_quest_dashboard/feed_quest_dashboard.dart';
import '../presentation/adventure_paths/adventure_paths_view.dart';
import '../presentation/vp_economy_dashboard/vp_economy_dashboard.dart';
import '../presentation/vp_economy_health_monitor/vp_economy_health_monitor.dart';
import '../presentation/vp_economy_management_dashboard/vp_economy_management_dashboard.dart';
import '../presentation/complete_gamified_lottery_drawing_system/complete_gamified_lottery_drawing_system.dart';
import '../presentation/gamified_prize_configuration_studio/gamified_prize_configuration_studio.dart';
import '../presentation/winner_reveal_ceremony/winner_reveal_ceremony.dart';
import '../presentation/nft_achievement_system_hub/nft_achievement_system_hub.dart';
import '../presentation/rewards_shop_hub/rewards_shop_hub.dart';
import '../presentation/real_time_gamification_notification_center/real_time_gamification_notification_center.dart';
import '../presentation/real_time_gamification_notifications_center/real_time_gamification_notifications_center.dart';
import '../presentation/real_time_gamification_sync_optimization_center/real_time_gamification_sync_optimization_center.dart';
import '../presentation/gamification_e2e_testing_suite_dashboard/gamification_e2e_testing_suite_dashboard.dart';
import '../presentation/admin_gamification_toggle_panel/admin_gamification_toggle_panel.dart';
import '../presentation/digital_wallet_screen/digital_wallet_screen.dart';
import '../presentation/wallet_dashboard/wallet_dashboard.dart';
import '../presentation/wallet_prize_distribution_center/wallet_prize_distribution_center.dart';
import '../presentation/digital_wallet_prize_redemption_system/digital_wallet_prize_redemption_system.dart';
import '../presentation/unified_payment_orchestration_hub/unified_payment_orchestration_hub.dart';
import '../presentation/automated_payment_processing_hub/automated_payment_processing_hub.dart';
import '../presentation/multi_currency_settlement_dashboard/multi_currency_settlement_dashboard.dart';
import '../presentation/enhanced_multi_currency_settlement_dashboard/enhanced_multi_currency_settlement_dashboard.dart';
import '../presentation/stripe_connect_payout_management_hub/stripe_connect_payout_management_hub.dart';
import '../presentation/settlement_reconciliation_hub/settlement_reconciliation_hub.dart';
import '../presentation/payout_history_screen/payout_history_screen.dart';
import '../presentation/payout_schedule_settings_screen/payout_schedule_settings_screen.dart';
import '../presentation/bank_account_linking_screen/bank_account_linking_screen.dart';
import '../presentation/enhanced_bank_account_linking_hub/enhanced_bank_account_linking_hub.dart';
import '../presentation/tax_compliance_dashboard/tax_compliance_dashboard.dart';
import '../presentation/participation_fee_payment/participation_fee_payment_screen.dart';
import '../presentation/premium_subscription_center/premium_subscription_center.dart';
import '../presentation/wallet_authentication_screen/wallet_authentication_screen.dart';
import '../presentation/creator_analytics_dashboard/creator_analytics_dashboard.dart';
import '../presentation/creator_monetization_hub/creator_monetization_hub.dart';
import '../presentation/creator_monetization_studio/creator_monetization_studio.dart';
import '../presentation/creator_payout_dashboard/creator_payout_dashboard.dart';
import '../presentation/creator_earnings_command_center/creator_earnings_command_center.dart';
import '../presentation/creator_marketplace/creator_marketplace.dart';
import '../presentation/creator_marketplace_store/creator_marketplace_store.dart';
import '../presentation/creator_brand_partnership_hub/creator_brand_partnership_hub.dart';
import '../presentation/creator_success_academy/creator_success_academy.dart';
import '../presentation/creator_studio_dashboard/creator_studio_dashboard.dart';
import '../presentation/creator_tier_dashboard_screen/creator_tier_dashboard_screen.dart';
import '../presentation/creator_verification_kyc_screen/creator_verification_kyc_screen.dart';
import '../presentation/creator_support_hub_screen/creator_support_hub_screen.dart';
import '../presentation/creator_q_a_management_center/creator_q_a_management_center.dart';
import '../presentation/creator_feedback_loop/creator_feedback_loop.dart';
import '../presentation/creator_growth_analytics_dashboard/creator_growth_analytics_dashboard.dart';
import '../presentation/creator_churn_prediction_dashboard/creator_churn_prediction_dashboard.dart';
import '../presentation/creator_churn_auto_trigger_retention_hub/creator_churn_auto_trigger_retention_hub.dart';
import '../presentation/creator_revenue_transparency_hub/creator_revenue_transparency_hub.dart';
import '../presentation/creator_monetization_analytics_dashboard/creator_monetization_analytics_dashboard.dart';
import '../presentation/creator_optimization_studio/creator_optimization_studio.dart';
import '../presentation/creator_predictive_insights_hub/creator_predictive_insights_hub.dart';
import '../presentation/creator_settlement_reconciliation_center/creator_settlement_reconciliation_center.dart';
import '../presentation/enhanced_creator_analytics_dashboard_with_gamification_metrics/enhanced_creator_analytics_dashboard_with_gamification_metrics.dart';
import '../presentation/enhanced_creator_earnings_dashboard/enhanced_creator_earnings_dashboard.dart';
import '../presentation/enhanced_creator_revenue_analytics/enhanced_creator_revenue_analytics.dart';
import '../presentation/advanced_creator_payout_management_hub/advanced_creator_payout_management_hub.dart';
import '../presentation/real_time_creator_metrics_monitor/real_time_creator_metrics_monitor.dart';
import '../presentation/real_time_creator_earnings_widget/real_time_creator_earnings_widget.dart';
import '../presentation/campaign_management_dashboard/campaign_management_dashboard.dart';
import '../presentation/campaign_optimization_dashboard/campaign_optimization_dashboard.dart';
import '../presentation/campaign_template_gallery/campaign_template_gallery.dart';
import '../presentation/participatory_ads_studio/participatory_ads_studio.dart';
import '../presentation/participatory_ads_gamification_center/participatory_ads_gamification_center.dart';
import '../presentation/advertiser_analytics_dashboard/advertiser_analytics_dashboard.dart';
import '../presentation/advertiser_portal_screen/advertiser_portal_screen.dart';
import '../presentation/real_time_advertiser_roi_dashboard/real_time_advertiser_roi_dashboard.dart';
import '../presentation/brand_advertiser_registration_portal/brand_advertiser_registration_portal.dart';
import '../presentation/brand_partnership_hub/brand_partnership_hub.dart';
import '../presentation/brand_onboarding_wizard/brand_onboarding_wizard.dart';
import '../presentation/dynamic_cpe_pricing_engine_dashboard/dynamic_cpe_pricing_engine_dashboard.dart';
import '../presentation/google_ad_sense_live_integration_hub/google_ad_sense_live_integration_hub.dart';
import '../presentation/google_ad_sense_monetization_hub/google_ad_sense_monetization_hub.dart';
import '../presentation/real_time_brand_alert_sales_outreach_hub/real_time_brand_alert_sales_outreach_hub.dart';
import '../presentation/admin_feature_toggle_panel/admin_feature_toggle_panel.dart';
import '../presentation/enhanced_admin_feature_toggle_panel/enhanced_admin_feature_toggle_panel.dart';
import '../presentation/admin_revenue_sharing_management_panel/admin_revenue_sharing_management_panel.dart';
import '../presentation/admin_country_access_control_panel/admin_country_access_control_panel.dart';
import '../presentation/enhanced_admin_control_panel/enhanced_admin_control_panel.dart';
import '../presentation/enhanced_mobile_admin_dashboard/enhanced_mobile_admin_dashboard.dart';
import '../presentation/multi_role_admin_control_center/multi_role_admin_control_center.dart';
import '../presentation/comprehensive_settings_hub/comprehensive_settings_hub.dart';
import '../presentation/enhanced_settings_account_dashboard/enhanced_settings_account_dashboard.dart';
import '../presentation/enhanced_privacy_settings_hub/enhanced_privacy_settings_hub.dart';
import '../presentation/enhanced_profile_privacy_controls/enhanced_profile_privacy_controls.dart';
import '../presentation/enhanced_profile_privacy_controls_center/enhanced_profile_privacy_controls_center.dart';
import '../presentation/accessibility_settings_hub/accessibility_settings_hub.dart';
import '../presentation/global_language_settings_hub/global_language_settings_hub.dart';
import '../presentation/family_sharing_management_hub/family_sharing_management_hub.dart';
import '../presentation/user_security_center/user_security_center.dart';
import '../presentation/passkey_authentication_center/passkey_authentication_center.dart';
import '../presentation/biometric_authentication/biometric_authentication.dart';
import '../presentation/otp_email_verification_hub/otp_email_verification_hub.dart';
import '../presentation/quick_registration_screen/quick_registration_screen.dart';
import '../presentation/comprehensive_onboarding_flow/comprehensive_onboarding_flow.dart';
import '../presentation/interactive_onboarding_tutorial_system/interactive_onboarding_tutorial_system.dart';
import '../presentation/interactive_onboarding_tours_hub/interactive_onboarding_tours_hub.dart';
import '../presentation/topic_preference_collection_hub/topic_preference_collection_hub.dart';
import '../presentation/role_upgrade/role_upgrade_screen.dart';
import '../presentation/notification_center_hub/notification_center_hub.dart';
import '../presentation/ai_notification_center/ai_notification_center.dart';
import '../presentation/push_notification_management_center/push_notification_management_center.dart';
import '../presentation/push_notification_dashboard/push_notification_dashboard.dart';
import '../presentation/push_notification_intelligence_hub/push_notification_intelligence_hub.dart';
import '../presentation/log_notification_center/log_notification_center.dart';
import '../presentation/social_connections_manager/social_connections_manager.dart';
import '../presentation/friend_requests_hub/friend_requests_hub.dart';
import '../presentation/direct_messaging_screen/direct_messaging_screen.dart';
import '../presentation/direct_messaging_system/direct_messaging_system.dart';
import '../presentation/enhanced_direct_messaging_screen/enhanced_direct_messaging_screen.dart';
import '../presentation/groups_hub/groups_hub.dart';
import '../presentation/enhanced_groups_hub/enhanced_groups_hub.dart';
import '../presentation/moments_stories_hub/moments_stories_hub.dart';
import '../presentation/social_post_composer/social_post_composer.dart';
import '../presentation/enhanced_posts_feeds_composer/enhanced_posts_feeds_composer.dart';
import '../presentation/social_media_navigation_hub/social_media_navigation_hub.dart';
import '../presentation/jolts_video_feed/jolts_video_feed.dart';
import '../presentation/jolts_video_studio/jolts_video_studio.dart';
import '../presentation/jolts_analytics_dashboard/jolts_analytics_dashboard.dart';
import '../presentation/jolts_creator_gamification_hub/jolts_creator_gamification_hub.dart';
import '../presentation/enhanced_social_media_home_feed_with_claude_confidence_sidebar/enhanced_social_media_home_feed_with_claude_confidence_sidebar.dart';
import '../presentation/blockchain_vote_verification_hub/blockchain_vote_verification_hub.dart';
import '../presentation/enhanced_blockchain_vote_verification_hub/enhanced_blockchain_vote_verification_hub.dart';
import '../presentation/blockchain_vote_receipt_center/blockchain_vote_receipt_center.dart';
import '../presentation/blockchain_gamification_logging_hub/blockchain_gamification_logging_hub.dart';
import '../presentation/verify_audit_elections_hub/verify_audit_elections_hub.dart';
import '../presentation/election_integrity_monitoring_hub/election_integrity_monitoring_hub.dart';
import '../presentation/tie_handling_resolution_center/tie_handling_resolution_center.dart';
import '../presentation/abstentions_tracking_dashboard/abstentions_tracking_dashboard.dart';
import '../presentation/vote_change_management_center/vote_change_management_center.dart';
import '../presentation/anonymous_voting_configuration_hub/anonymous_voting_configuration_hub.dart';
import '../presentation/collaborative_voting_room/collaborative_voting_room.dart';
import '../presentation/location_voting/location_voting.dart';
import '../presentation/enhanced_vote_casting/enhanced_vote_casting.dart';
import '../presentation/enhanced_vote_casting_with_prediction_integration/enhanced_vote_casting_with_prediction_integration.dart';
import '../presentation/live_question_injection_control_center/live_question_injection_control_center.dart';
import '../presentation/enhanced_mcq_image_options_interface/enhanced_mcq_image_options_interface.dart';
import '../presentation/open_ended_answer_questions_builder/open_ended_answer_questions_builder.dart';
import '../presentation/audience_questions_hub/audience_questions_hub.dart';
import '../presentation/presentation_slides_viewer/presentation_slides_viewer.dart';
import '../presentation/social_proof_indicators_dashboard/social_proof_indicators_dashboard.dart';
import '../presentation/personalization_dashboard/personalization_dashboard.dart';
import '../presentation/unified_search_system_hub/unified_search_system_hub.dart';
import '../presentation/content_moderation_tools/content_moderation_tools.dart';
import '../presentation/ai_content_moderation_dashboard/ai_content_moderation_dashboard.dart';
import '../presentation/age_verification_control_center/age_verification_control_center.dart';
import '../presentation/country_restriction_controls/country_restriction_controls.dart';
import '../presentation/country_biometric_compliance_dashboard/country_biometric_compliance_dashboard.dart';
import '../presentation/enhanced_compliance_dashboard/enhanced_compliance_dashboard.dart';
import '../presentation/enhanced_compliance_reports_dashboard/enhanced_compliance_reports_dashboard.dart';
import '../presentation/compliance_reports_generator_dashboard/compliance_reports_generator_dashboard.dart';
import '../presentation/fraud_monitoring_dashboard/fraud_monitoring_dashboard.dart';
import '../presentation/advanced_fraud_detection_center/advanced_fraud_detection_center.dart';
import '../presentation/fraud_appeal_screen/fraud_appeal_screen.dart';
import '../presentation/perplexity_fraud_dashboard_screen/perplexity_fraud_dashboard_screen.dart';
import '../presentation/enhanced_fraud_investigation_workflows_hub/enhanced_fraud_investigation_workflows_hub.dart';
import '../presentation/enhanced_perplexity_ai_fraud_forecasting_hub/enhanced_perplexity_ai_fraud_forecasting_hub.dart';
import '../presentation/enhanced_perplexity_90_day_threat_forecasting_hub/enhanced_perplexity_90_day_threat_forecasting_hub.dart';
import '../presentation/coordinated_voting_detection_screen/coordinated_voting_detection_screen.dart';
import '../presentation/behavioral_biometric_fraud_prevention_center/behavioral_biometric_fraud_prevention_center.dart';
import '../presentation/revenue_fraud_detection_engine/revenue_fraud_detection_engine.dart';
import '../presentation/ai_anomaly_detection_fraud_prevention_hub/ai_anomaly_detection_fraud_prevention_hub.dart';
import '../presentation/advanced_threat_prediction_dashboard/advanced_threat_prediction_dashboard.dart';
import '../presentation/zone_specific_threat_heatmaps_dashboard/zone_specific_threat_heatmaps_dashboard.dart';
import '../presentation/real_time_threat_correlation_dashboard/real_time_threat_correlation_dashboard.dart';
import '../presentation/automated_threat_response_execution/automated_threat_response_execution.dart';
import '../presentation/multi_ai_threat_orchestration_hub/multi_ai_threat_orchestration_hub.dart';
import '../presentation/predictive_incident_prevention_engine/predictive_incident_prevention_engine.dart';
import '../presentation/automated_incident_prevention_hub/automated_incident_prevention_hub.dart';
import '../presentation/automated_incident_response_center/automated_incident_response_center.dart';
import '../presentation/unified_incident_orchestration_center/unified_incident_orchestration_center.dart';
import '../presentation/unified_incident_management_dashboard/unified_incident_management_dashboard.dart';
import '../presentation/team_incident_war_room/team_incident_war_room.dart';
import '../presentation/incident_testing_suite_dashboard/incident_testing_suite_dashboard.dart';
import '../presentation/enhanced_incident_correlation_engine/enhanced_incident_correlation_engine.dart';
import '../presentation/security_monitoring_dashboard/security_monitoring_dashboard.dart';
import '../presentation/ai_security_dashboard/ai_security_dashboard.dart';
import '../presentation/owasp_security_testing_dashboard/owasp_security_testing_dashboard.dart';
import '../presentation/production_security_hardening_sprint_dashboard/production_security_hardening_sprint_dashboard.dart';
import '../presentation/security_feature_adoption_analytics/security_feature_adoption_analytics.dart';
import '../presentation/comprehensive_audit_log_screen/comprehensive_audit_log_screen.dart';
import '../presentation/comprehensive_audit_log_viewer/comprehensive_audit_log_viewer.dart';
import '../presentation/user_activity_log_viewer/user_activity_log_viewer.dart';
import '../presentation/real_time_system_monitoring_dashboard/real_time_system_monitoring_dashboard.dart';
import '../presentation/datadog_apm_monitoring_dashboard/datadog_apm_monitoring_dashboard.dart';
import '../presentation/datadog_apm_distributed_tracing_hub/datadog_apm_distributed_tracing_hub.dart';
import '../presentation/datadog_apm_performance_monitoring_hub/datadog_apm_performance_monitoring_hub.dart';
import '../presentation/real_time_performance_monitoring_with_datadog_apm_dashboard/real_time_performance_monitoring_with_datadog_apm_dashboard.dart';
import '../presentation/sentry_error_tracking_dashboard/sentry_error_tracking_dashboard.dart';
import '../presentation/sentry_error_tracking_integration_hub/sentry_error_tracking_integration_hub.dart';
import '../presentation/sentry_slack_alert_pipeline_dashboard/sentry_slack_alert_pipeline_dashboard.dart';
import '../presentation/enhanced_sentry_automated_alerting_hub/enhanced_sentry_automated_alerting_hub.dart';
import '../presentation/slack_incident_notifications_dashboard/slack_incident_notifications_dashboard.dart';
import '../presentation/redis_cache_monitoring_dashboard/redis_cache_monitoring_dashboard.dart';
import '../presentation/advanced_redis_caching_management_hub/advanced_redis_caching_management_hub.dart';
import '../presentation/supabase_query_result_caching_management_hub/supabase_query_result_caching_management_hub.dart';
import '../presentation/ai_cache_management_dashboard/ai_cache_management_dashboard.dart';
import '../presentation/mobile_app_performance_optimization_hub/mobile_app_performance_optimization_hub.dart';
import '../presentation/mobile_performance_optimization_dashboard/mobile_performance_optimization_dashboard.dart';
import '../presentation/mobile_performance_optimization_hub/mobile_performance_optimization_hub.dart';
import '../presentation/advanced_performance_profiling_dashboard/advanced_performance_profiling_dashboard.dart';
import '../presentation/flutter_client_side_performance_profiling_dashboard/flutter_client_side_performance_profiling_dashboard.dart';
import '../presentation/performance_monitoring_dashboard/performance_monitoring_dashboard.dart';
import '../presentation/performance_test_dashboard/performance_test_dashboard.dart';
import '../presentation/app_performance_dashboard/app_performance_dashboard.dart';
import '../presentation/production_performance_monitoring_dashboard/production_performance_monitoring_dashboard.dart';
import '../presentation/production_sla_monitoring_dashboard/production_sla_monitoring_dashboard.dart';
import '../presentation/production_load_testing_suite_dashboard/production_load_testing_suite_dashboard.dart';
import '../presentation/production_load_test_auto_response_hub/production_load_test_auto_response_hub.dart';
import '../presentation/production_deployment_hub/production_deployment_hub.dart';
import '../presentation/git_hub_actions_ci_cd_pipeline_dashboard/git_hub_actions_ci_cd_pipeline_dashboard.dart';
import '../presentation/automated_testing_performance_dashboard/automated_testing_performance_dashboard.dart';
import '../presentation/automated_testing_suite_runner/automated_testing_suite_runner.dart';
import '../presentation/e2e_testing_coverage_dashboard/e2e_testing_coverage_dashboard.dart';
import '../presentation/mobile_launch_readiness_checklist/mobile_launch_readiness_checklist.dart';
import '../presentation/api_gateway_optimization_dashboard/api_gateway_optimization_dashboard.dart';
import '../presentation/api_performance_optimization_dashboard/api_performance_optimization_dashboard.dart';
import '../presentation/res_tful_api_management_hub/res_tful_api_management_hub.dart';
import '../presentation/webhook_integration_management_hub/webhook_integration_management_hub.dart';
import '../presentation/code_splitting_performance_optimization_hub/code_splitting_performance_optimization_hub.dart';
import '../presentation/hive_offline_storage_management_hub/hive_offline_storage_management_hub.dart';
import '../presentation/enhanced_hive_offline_first_architecture_hub/enhanced_hive_offline_first_architecture_hub.dart';
import '../presentation/enhanced_mobile_offline_sync_hub/enhanced_mobile_offline_sync_hub.dart';
import '../presentation/cross_domain_data_sync_hub/cross_domain_data_sync_hub.dart';
import '../presentation/pwa_offline_voting_hub/pwa_offline_voting_hub.dart';
import '../presentation/status_page_screen/status_page_screen.dart';
import '../presentation/automated_threshold_based_alerting_hub/automated_threshold_based_alerting_hub.dart';
import '../presentation/unified_alert_management_center/unified_alert_management_center.dart';
import '../presentation/real_time_alert_dashboard/real_time_alert_dashboard.dart';
import '../presentation/real_time_engagement_dashboard/real_time_engagement_dashboard.dart';
import '../presentation/real_time_dashboard_refresh_control_center/real_time_dashboard_refresh_control_center.dart';
import '../presentation/mobile_logging_dashboard/mobile_logging_dashboard.dart';
import '../presentation/log_rocket_session_replay_monitoring_center/log_rocket_session_replay_monitoring_center.dart';
import '../presentation/ai_failover_dashboard_screen/ai_failover_dashboard_screen.dart';
import '../presentation/ai_service_failover_control_center/ai_service_failover_control_center.dart';
import '../presentation/automatic_ai_failover_engine_control_center/automatic_ai_failover_engine_control_center.dart';
import '../presentation/ai_voice_interaction_hub/ai_voice_interaction_hub.dart';
import '../presentation/multi_language_ai_translation_hub/multi_language_ai_translation_hub.dart';
import '../presentation/claude_model_comparison_center/claude_model_comparison_center.dart';
import '../presentation/claude_contextual_insights_overlay_system/claude_contextual_insights_overlay_system.dart';
import '../presentation/claude_autonomous_actions_hub/claude_autonomous_actions_hub.dart';
import '../presentation/real_time_claude_coaching_api_hub/real_time_claude_coaching_api_hub.dart';
import '../presentation/gemini_cost_efficiency_analyzer/gemini_cost_efficiency_analyzer.dart';
import '../presentation/anthropic_content_intelligence_hub/anthropic_content_intelligence_hub.dart';
import '../presentation/ai_recommendations_center/ai_recommendations_center.dart';
import '../presentation/ai_powered_predictive_analytics_engine/ai_powered_predictive_analytics_engine.dart';
import '../presentation/ai_predictive_modeling_screen/ai_predictive_modeling_screen.dart';
import '../presentation/ai_voter_sentiment_dashboard/ai_voter_sentiment_dashboard.dart';
import '../presentation/ai_analytics_hub/ai_analytics_hub.dart';
import '../presentation/unified_ai_performance_dashboard/unified_ai_performance_dashboard.dart';
import '../presentation/context_aware_recommendations_overlay/context_aware_recommendations_overlay.dart';
import '../presentation/gemini_recommendation_sync_hub/gemini_recommendation_sync_hub.dart';
import '../presentation/unified_analytics_dashboard/unified_analytics_dashboard.dart';
import '../presentation/unified_business_intelligence_hub/unified_business_intelligence_hub.dart';
import '../presentation/executive_business_intelligence_suite/executive_business_intelligence_suite.dart';
import '../presentation/revenue_analytics/revenue_analytics.dart';
import '../presentation/revenue_split_analytics_dashboard/revenue_split_analytics_dashboard.dart';
import '../presentation/revenue_split_admin_control_center/revenue_split_admin_control_center.dart';
import '../presentation/unified_revenue_intelligence_dashboard/unified_revenue_intelligence_dashboard.dart';
import '../presentation/google_analytics_integration_dashboard/google_analytics_integration_dashboard.dart';
import '../presentation/advanced_google_analytics_tracking_hub/advanced_google_analytics_tracking_hub.dart';
import '../presentation/google_analytics_gamification_tracking_hub/google_analytics_gamification_tracking_hub.dart';
import '../presentation/google_analytics_monetization_tracking_hub/google_analytics_monetization_tracking_hub.dart';
import '../presentation/google_analytics_ai_feature_adoption_dashboard/google_analytics_ai_feature_adoption_dashboard.dart';
import '../presentation/ml_model_monitoring_dashboard/ml_model_monitoring_dashboard.dart';
import '../presentation/enhanced_analytics_with_cdn_integration_hub/enhanced_analytics_with_cdn_integration_hub.dart';
import '../presentation/advanced_behavioral_heatmaps_ml_analytics_hub/advanced_behavioral_heatmaps_ml_analytics_hub.dart';
import '../presentation/collaborative_analytics_workspace/collaborative_analytics_workspace.dart';
import '../presentation/feed_ranking_analytics_dashboard/feed_ranking_analytics_dashboard.dart';
import '../presentation/enhanced_feed_ranking_with_claude_integration_hub/enhanced_feed_ranking_with_claude_integration_hub.dart';
import '../presentation/feed_orchestration_engine_control_center/feed_orchestration_engine_control_center.dart';
import '../presentation/unified_cross_domain_recommendation_engine_hub/unified_cross_domain_recommendation_engine_hub.dart';
import '../presentation/cross_domain_intelligence_hub/cross_domain_intelligence_hub.dart';
import '../presentation/prediction_analytics_dashboard/prediction_analytics_dashboard.dart';
import '../presentation/dedicated_market_research_dashboard/dedicated_market_research_dashboard.dart';
import '../presentation/mobile_election_insights_analytics/mobile_election_insights_analytics.dart';
import '../presentation/engagement_metrics_dashboard/engagement_metrics_dashboard.dart';
import '../presentation/feature_performance_dashboard/feature_performance_dashboard.dart';
import '../presentation/feature_flag_management_dashboard/feature_flag_management_dashboard.dart';
import '../presentation/analytics_performance_control_center/analytics_performance_control_center.dart';
import '../presentation/advanced_a_b_testing_center/advanced_a_b_testing_center.dart';
import '../presentation/carousel_analytics_dashboard/carousel_analytics_dashboard.dart';
import '../presentation/carousel_analytics_intelligence_center/carousel_analytics_intelligence_center.dart';
import '../presentation/carousel_performance_analytics_dashboard/carousel_performance_analytics_dashboard.dart';
import '../presentation/carousel_performance_monitor_dashboard/carousel_performance_monitor_dashboard.dart';
import '../presentation/carousel_health_alerting_dashboard/carousel_health_alerting_dashboard.dart';
import '../presentation/carousel_health_scaling_dashboard/carousel_health_scaling_dashboard.dart';
import '../presentation/carousel_roi_analytics_dashboard/carousel_roi_analytics_dashboard.dart';
import '../presentation/carousel_security_audit_dashboard/carousel_security_audit_dashboard.dart';
import '../presentation/carousel_template_marketplace/carousel_template_marketplace.dart';
import '../presentation/carousel_creator_tiers_management_hub/carousel_creator_tiers_management_hub.dart';
import '../presentation/carousel_content_discovery_filter_center/carousel_content_discovery_filter_center.dart';
import '../presentation/carousel_personalization_engine_dashboard/carousel_personalization_engine_dashboard.dart';
import '../presentation/carousel_a_b_testing_framework_dashboard/carousel_a_b_testing_framework_dashboard.dart';
import '../presentation/carousel_real_time_bidding_system_hub/carousel_real_time_bidding_system_hub.dart';
import '../presentation/carousel_content_moderation_automation_center/carousel_content_moderation_automation_center.dart';
import '../presentation/carousel_mobile_optimization_suite_dashboard/carousel_mobile_optimization_suite_dashboard.dart';
import '../presentation/carousel_claude_observability_hub/carousel_claude_observability_hub.dart';
import '../presentation/unified_carousel_observability_hub/unified_carousel_observability_hub.dart';
import '../presentation/unified_carousel_operations_command_center/unified_carousel_operations_command_center.dart';
import '../presentation/advanced_carousel_filter_control_center/advanced_carousel_filter_control_center.dart';
import '../presentation/sms_provider_dashboard/sms_provider_dashboard.dart';
import '../presentation/sms_failover_configuration_center/sms_failover_configuration_center.dart';
import '../presentation/sms_rate_limiting_queue_control_center/sms_rate_limiting_queue_control_center.dart';
import '../presentation/sms_queue_management_dashboard/sms_queue_management_dashboard.dart';
import '../presentation/sms_delivery_analytics_dashboard/sms_delivery_analytics_dashboard.dart';
import '../presentation/sms_compliance_manager_dashboard/sms_compliance_manager_dashboard.dart';
import '../presentation/sms_webhook_management_dashboard/sms_webhook_management_dashboard.dart';
import '../presentation/sms_alert_template_management_center/sms_alert_template_management_center.dart';
import '../presentation/sms_emergency_alerts_hub/sms_emergency_alerts_hub.dart';
import '../presentation/twilio_sms_emergency_alert_management_center/twilio_sms_emergency_alert_management_center.dart';
import '../presentation/twilio_video_live_streaming_hub/twilio_video_live_streaming_hub.dart';
import '../presentation/telnyx_sms_provider_management_dashboard/telnyx_sms_provider_management_dashboard.dart';
import '../presentation/open_ai_sms_optimization_hub/open_ai_sms_optimization_hub.dart';

/// Returns the screen widget for routes that are not handled by the main
/// onGenerateRoute switch (e.g. role-guarded routes). Used in default case.
Widget? screenForRoute(String? name) {
  if (name == null || name.isEmpty) return null;
  switch (name) {
    case AppRoutes.splash:
    case AppRoutes.initial:
      return const SplashScreen();
    case AppRoutes.socialMediaHomeFeed:
      return const SocialMediaHomeFeed();
    case AppRoutes.socialHomeFeed:
      return const SocialHomeFeed();
    case AppRoutes.voteDashboard:
      return const VoteDashboard();
    case AppRoutes.voteDashboardInitialPage:
      return const VoteDashboardInitialPage();
    case AppRoutes.voteCasting:
      return const VoteCasting();
    case AppRoutes.voteResults:
      return const VoteResults();
    case AppRoutes.voteHistory:
      return const VoteHistory();
    case AppRoutes.voteAnalytics:
      return const VoteAnalytics();
    case AppRoutes.voteDiscovery:
      return const VoteDiscovery();
    case AppRoutes.createVote:
      return const CreateVote();
    case AppRoutes.electionCreationStudio:
      return const ElectionCreationStudio();
    case AppRoutes.userProfile:
      return const UserProfile();
    case AppRoutes.adminDashboard:
      return const AdminDashboard();
    case AppRoutes.facebookStyleProfileMenu:
      return const FacebookStyleProfileMenu();
    case AppRoutes.gamificationHub:
      return const GamificationHub();
    case AppRoutes.unifiedGamificationDashboard:
      return const UnifiedGamificationDashboard();
    case AppRoutes.questManagementDashboard:
      return const QuestManagementDashboard();
    case AppRoutes.aiQuestGeneration:
      return const AiQuestGeneration();
    case AppRoutes.feedQuestDashboard:
      return const FeedQuestDashboard();
    case AppRoutes.adventurePaths:
      return const AdventurePathsView();
    case AppRoutes.vpEconomyDashboard:
      return const VpEconomyDashboard();
    case AppRoutes.vpEconomyHealthMonitor:
      return const VpEconomyHealthMonitor();
    case AppRoutes.vpEconomyManagementDashboard:
      return const VpEconomyManagementDashboard();
    case AppRoutes.completeGamifiedLotteryDrawingSystem:
      return const CompleteGamifiedLotteryDrawingSystem();
    case AppRoutes.gamifiedPrizeConfigurationStudio:
      return const GamifiedPrizeConfigurationStudio();
    case AppRoutes.winnerRevealCeremony:
      return const WinnerRevealCeremony();
    case AppRoutes.nftAchievementSystemHub:
      return const NftAchievementSystemHub();
    case AppRoutes.rewardsShopHub:
      return const RewardsShopHub();
    case AppRoutes.realTimeGamificationNotificationCenter:
      return const RealTimeGamificationNotificationCenter();
    case AppRoutes.realTimeGamificationNotificationsCenter:
      return const RealTimeGamificationNotificationsCenter();
    case AppRoutes.realTimeGamificationSyncOptimizationCenter:
      return const RealTimeGamificationSyncOptimizationCenter();
    case AppRoutes.gamificationE2eTestingSuiteDashboard:
      return const GamificationE2eTestingSuiteDashboard();
    case AppRoutes.adminGamificationTogglePanel:
      return const AdminGamificationTogglePanel();
    case AppRoutes.digitalWalletScreen:
      return const DigitalWalletScreen();
    case AppRoutes.walletDashboard:
      return const WalletDashboard();
    case AppRoutes.walletPrizeDistributionCenter:
      return const WalletPrizeDistributionCenter();
    case AppRoutes.digitalWalletPrizeRedemptionSystem:
      return const DigitalWalletPrizeRedemptionSystem();
    case AppRoutes.unifiedPaymentOrchestrationHub:
      return const UnifiedPaymentOrchestrationHub();
    case AppRoutes.automatedPaymentProcessingHub:
      return const AutomatedPaymentProcessingHub();
    case AppRoutes.multiCurrencySettlementDashboard:
      return const MultiCurrencySettlementDashboard();
    case AppRoutes.enhancedMultiCurrencySettlementDashboard:
      return const EnhancedMultiCurrencySettlementDashboard();
    case AppRoutes.stripeConnectPayoutManagementHub:
      return const StripeConnectPayoutManagementHub();
    case AppRoutes.settlementReconciliationHub:
      return const SettlementReconciliationHub();
    case AppRoutes.payoutHistoryScreen:
      return const PayoutHistoryScreen();
    case AppRoutes.payoutScheduleSettingsScreen:
      return const PayoutScheduleSettingsScreen();
    case AppRoutes.bankAccountLinkingScreen:
      return const BankAccountLinkingScreen();
    case AppRoutes.enhancedBankAccountLinkingHub:
      return const EnhancedBankAccountLinkingHub();
    case AppRoutes.taxComplianceDashboard:
      return const TaxComplianceDashboard();
    case AppRoutes.participationFeePayment:
      return const ParticipationFeePaymentScreen();
    case AppRoutes.premiumSubscriptionCenter:
      return const PremiumSubscriptionCenter();
    case AppRoutes.walletAuthenticationScreen:
      return const WalletAuthenticationScreen();
    case AppRoutes.creatorAnalyticsDashboard:
      return const CreatorAnalyticsDashboard();
    case AppRoutes.creatorMonetizationHub:
      return const CreatorMonetizationHub();
    case AppRoutes.creatorMonetizationStudio:
      return const CreatorMonetizationStudio();
    case AppRoutes.creatorPayoutDashboard:
      return const CreatorPayoutDashboard();
    case AppRoutes.creatorEarningsCommandCenter:
      return const CreatorEarningsCommandCenter();
    case AppRoutes.creatorMarketplace:
      return const CreatorMarketplace();
    case AppRoutes.creatorMarketplaceStore:
      return const CreatorMarketplaceStore();
    case AppRoutes.creatorBrandPartnershipHub:
      return const CreatorBrandPartnershipHub();
    case AppRoutes.creatorSuccessAcademy:
      return const CreatorSuccessAcademy();
    case AppRoutes.creatorStudioDashboard:
      return const CreatorStudioDashboard();
    case AppRoutes.creatorTierDashboardScreen:
      return const CreatorTierDashboardScreen();
    case AppRoutes.creatorVerificationKycScreen:
      return const CreatorVerificationKycScreen();
    case AppRoutes.creatorSupportHub:
      return const CreatorSupportHubScreen();
    case AppRoutes.creatorQaManagementCenter:
      return const CreatorQaManagementCenter();
    case AppRoutes.creatorFeedbackLoop:
      return const CreatorFeedbackLoop();
    case AppRoutes.creatorGrowthAnalyticsDashboard:
      return const CreatorGrowthAnalyticsDashboard();
    case AppRoutes.creatorChurnPredictionDashboard:
      return const CreatorChurnPredictionDashboard();
    case AppRoutes.creatorChurnAutoTriggerRetentionHub:
      return const CreatorChurnAutoTriggerRetentionHub();
    case AppRoutes.creatorRevenueTransparencyHub:
      return const CreatorRevenueTransparencyHub();
    case AppRoutes.creatorMonetizationAnalyticsDashboard:
      return const CreatorMonetizationAnalyticsDashboard();
    case AppRoutes.creatorOptimizationStudio:
      return const CreatorOptimizationStudio();
    case AppRoutes.creatorPredictiveInsightsHub:
      return const CreatorPredictiveInsightsHub();
    case AppRoutes.creatorSettlementReconciliationCenter:
      return const CreatorSettlementReconciliationCenter();
    case AppRoutes.enhancedCreatorAnalyticsDashboard:
      return const EnhancedCreatorAnalyticsDashboardWithGamificationMetrics();
    case AppRoutes.enhancedCreatorEarningsDashboard:
      return const EnhancedCreatorEarningsDashboard();
    case AppRoutes.enhancedCreatorRevenueAnalytics:
      return const EnhancedCreatorRevenueAnalytics();
    case AppRoutes.advancedCreatorPayoutManagementHub:
      return const AdvancedCreatorPayoutManagementHub();
    case AppRoutes.realTimeCreatorMetricsMonitor:
      return const RealTimeCreatorMetricsMonitor();
    case AppRoutes.realTimeCreatorEarningsWidget:
      return const RealTimeCreatorEarningsWidget();
    case AppRoutes.campaignManagementDashboard:
      return const CampaignManagementDashboard();
    case AppRoutes.campaignOptimizationDashboard:
      return const CampaignOptimizationDashboard();
    case AppRoutes.campaignTemplateGallery:
      return const CampaignTemplateGallery();
    case AppRoutes.participatoryAdsStudio:
      return const ParticipatoryAdsStudio();
    case AppRoutes.participatoryAdsGamificationCenter:
      return const ParticipatoryAdsGamificationCenter();
    case AppRoutes.advertiserAnalyticsDashboard:
      return const AdvertiserAnalyticsDashboard();
    case AppRoutes.advertiserPortalScreen:
      return const AdvertiserPortalScreen();
    case AppRoutes.realTimeAdvertiserRoiDashboard:
      return const RealTimeAdvertiserRoiDashboard();
    case AppRoutes.brandAdvertiserRegistrationPortal:
      return const BrandAdvertiserRegistrationPortal();
    case AppRoutes.brandPartnershipHub:
      return const BrandPartnershipHub();
    case AppRoutes.brandOnboardingWizard:
      return const BrandOnboardingWizard();
    case AppRoutes.dynamicCpePricingEngineDashboard:
      return const DynamicCpePricingEngineDashboard();
    case AppRoutes.googleAdSenseLiveIntegrationHub:
      return const GoogleAdSenseLiveIntegrationHub();
    case AppRoutes.googleAdSenseMonetizationHub:
      return const GoogleAdSenseMonetizationHub();
    case AppRoutes.realTimeBrandAlertSalesOutreachHub:
      return const RealTimeBrandAlertSalesOutreachHub();
    case AppRoutes.adminFeatureTogglePanel:
      return const AdminFeatureTogglePanel();
    case AppRoutes.enhancedAdminFeatureTogglePanel:
      return const EnhancedAdminFeatureTogglePanel();
    case AppRoutes.adminRevenueSharingManagementPanel:
      return const AdminRevenueSharingManagementPanel();
    case AppRoutes.adminCountryAccessControlPanel:
      return const AdminCountryAccessControlPanel();
    case AppRoutes.enhancedAdminControlPanel:
      return const EnhancedAdminControlPanel();
    case AppRoutes.enhancedMobileAdminDashboard:
      return const EnhancedMobileAdminDashboard();
    case AppRoutes.multiRoleAdminControlCenter:
      return const MultiRoleAdminControlCenter();
    case AppRoutes.comprehensiveSettingsHub:
      return const ComprehensiveSettingsHub();
    case AppRoutes.enhancedSettingsAccountDashboard:
      return const EnhancedSettingsAccountDashboard();
    case AppRoutes.enhancedPrivacySettingsHub:
      return const EnhancedPrivacySettingsHub();
    case AppRoutes.enhancedProfilePrivacyControls:
      return const EnhancedProfilePrivacyControls();
    case AppRoutes.enhancedProfilePrivacyControlsCenter:
      return const EnhancedProfilePrivacyControlsCenter();
    case AppRoutes.accessibilitySettingsHub:
      return const AccessibilitySettingsHub();
    case AppRoutes.globalLanguageSettingsHub:
      return const GlobalLanguageSettingsHub();
    case AppRoutes.familySharingManagementHub:
      return const FamilySharingManagementHub();
    case AppRoutes.userSecurityCenter:
      return const UserSecurityCenter();
    case AppRoutes.passkeyAuthenticationCenter:
      return const PasskeyAuthenticationCenter();
    case AppRoutes.biometricAuthentication:
      return const BiometricAuthentication();
    case AppRoutes.otpEmailVerificationHub:
      return const OtpEmailVerificationHub();
    case AppRoutes.quickRegistrationScreen:
      return const QuickRegistrationScreen();
    case AppRoutes.comprehensiveOnboardingFlow:
      return const ComprehensiveOnboardingFlow();
    case AppRoutes.interactiveOnboardingTutorialSystem:
      return const InteractiveOnboardingTutorialSystem();
    case AppRoutes.interactiveOnboardingToursHub:
      return const InteractiveOnboardingToursHub();
    case AppRoutes.topicPreferenceCollectionHub:
      return const TopicPreferenceCollectionHub();
    case AppRoutes.roleUpgrade:
      return const RoleUpgradeScreen();
    case AppRoutes.notificationCenterHub:
      return const NotificationCenterHub();
    case AppRoutes.aiNotificationCenter:
      return const AiNotificationCenter();
    case AppRoutes.pushNotificationManagementCenter:
      return const PushNotificationManagementCenter();
    case AppRoutes.pushNotificationDashboard:
      return const PushNotificationDashboard();
    case AppRoutes.pushNotificationIntelligenceHub:
      return const PushNotificationIntelligenceHub();
    case AppRoutes.logNotificationCenter:
      return const LogNotificationCenter();
    case AppRoutes.socialConnectionsManager:
      return const SocialConnectionsManager();
    case AppRoutes.friendRequestsHub:
      return const FriendRequestsHub();
    case AppRoutes.directMessagingScreen:
      return const DirectMessagingScreen();
    case AppRoutes.directMessagingSystem:
      return const DirectMessagingSystem();
    case AppRoutes.enhancedDirectMessagingScreen:
      return const EnhancedDirectMessagingScreen();
    case AppRoutes.groupsHub:
      return const GroupsHub();
    case AppRoutes.enhancedGroupsHub:
      return const EnhancedGroupsHub();
    case AppRoutes.momentsStoriesHub:
      return const MomentsStoriesHub();
    case AppRoutes.socialPostComposer:
      return const SocialPostComposer();
    case AppRoutes.enhancedPostsFeedsComposer:
      return const EnhancedPostsFeedsComposer();
    case AppRoutes.socialMediaNavigationHub:
      return const SocialMediaNavigationHub();
    case AppRoutes.joltsVideoFeed:
      return const JoltsVideoFeed();
    case AppRoutes.joltsVideoStudio:
      return const JoltsVideoStudio();
    case AppRoutes.joltsAnalyticsDashboard:
      return const JoltsAnalyticsDashboard();
    case AppRoutes.joltsCreatorGamificationHub:
      return const JoltsCreatorGamificationHub();
    case AppRoutes.enhancedSocialMediaHomeFeed:
      return const EnhancedSocialMediaHomeFeedWithClaudeConfidenceSidebar();
    case AppRoutes.blockchainVoteVerificationHub:
      return const BlockchainVoteVerificationHub();
    case AppRoutes.enhancedBlockchainVoteVerificationHub:
      return const EnhancedBlockchainVoteVerificationHub();
    case AppRoutes.blockchainVoteReceiptCenter:
      return const BlockchainVoteReceiptCenter();
    case AppRoutes.blockchainGamificationLoggingHub:
      return const BlockchainGamificationLoggingHub();
    case AppRoutes.verifyAuditElectionsHub:
      return const VerifyAuditElectionsHub();
    case AppRoutes.electionIntegrityMonitoringHub:
      return const ElectionIntegrityMonitoringHub();
    case AppRoutes.tieHandlingResolutionCenter:
      return const TieHandlingResolutionCenter();
    case AppRoutes.abstentionsTrackingDashboard:
      return const AbstentionsTrackingDashboard();
    case AppRoutes.voteChangeManagementCenter:
      return const VoteChangeManagementCenter();
    case AppRoutes.anonymousVotingConfigurationHub:
      return const AnonymousVotingConfigurationHub();
    case AppRoutes.collaborativeVotingRoom:
      return const CollaborativeVotingRoom();
    case AppRoutes.locationVoting:
      return const LocationVoting();
    case AppRoutes.enhancedVoteCasting:
      return const EnhancedVoteCasting();
    case AppRoutes.enhancedVoteCastingWithPredictionIntegration:
      return const EnhancedVoteCastingWithPredictionIntegration();
    case AppRoutes.liveQuestionInjectionControlCenter:
      return const LiveQuestionInjectionControlCenter();
    case AppRoutes.enhancedMcqImageOptionsInterface:
      return const EnhancedMcqImageOptionsInterface();
    case AppRoutes.openEndedAnswerQuestionsBuilder:
      return const OpenEndedAnswerQuestionsBuilder();
    case AppRoutes.audienceQuestionsHub:
      return const AudienceQuestionsHub();
    case AppRoutes.presentationSlidesViewer:
      return const PresentationSlidesViewer();
    case AppRoutes.socialProofIndicatorsDashboard:
      return const SocialProofIndicatorsDashboard();
    case AppRoutes.personalizationDashboard:
      return const PersonalizationDashboard();
    case AppRoutes.unifiedSearchSystemHub:
      return const UnifiedSearchSystemHub();
    case AppRoutes.contentModerationTools:
      return const ContentModerationTools();
    case AppRoutes.aiContentModerationDashboard:
      return const AiContentModerationDashboard();
    case AppRoutes.ageVerificationControlCenter:
      return const AgeVerificationControlCenter();
    case AppRoutes.countryRestrictionControls:
      return const CountryRestrictionControls();
    case AppRoutes.countryBiometricComplianceDashboard:
      return const CountryBiometricComplianceDashboard();
    case AppRoutes.enhancedComplianceDashboard:
      return const EnhancedComplianceDashboard();
    case AppRoutes.enhancedComplianceReportsDashboard:
      return const EnhancedComplianceReportsDashboard();
    case AppRoutes.complianceReportsGeneratorDashboard:
      return const ComplianceReportsGeneratorDashboard();
    case AppRoutes.fraudMonitoringDashboard:
      return const FraudMonitoringDashboard();
    case AppRoutes.advancedFraudDetectionCenter:
      return const AdvancedFraudDetectionCenter();
    case AppRoutes.fraudAppealScreen:
      return const FraudAppealScreen();
    case AppRoutes.perplexityFraudDashboardScreen:
      return const PerplexityFraudDashboardScreen();
    case AppRoutes.enhancedFraudInvestigationWorkflowsHub:
      return const EnhancedFraudInvestigationWorkflowsHub();
    case AppRoutes.enhancedPerplexityAiFraudForecastingHub:
      return const EnhancedPerplexityAiFraudForecastingHub();
    case AppRoutes.enhancedPerplexity90DayThreatForecastingHub:
      return const EnhancedPerplexity90DayThreatForecastingHub();
    case AppRoutes.coordinatedVotingDetectionScreen:
      return const CoordinatedVotingDetectionScreen();
    case AppRoutes.behavioralBiometricFraudPreventionCenter:
      return const BehavioralBiometricFraudPreventionCenter();
    case AppRoutes.revenueFraudDetectionEngine:
      return const RevenueFraudDetectionEngine();
    case AppRoutes.aiAnomalyDetectionFraudPreventionHub:
      return const AiAnomalyDetectionFraudPreventionHub();
    case AppRoutes.advancedThreatPredictionDashboard:
      return const AdvancedThreatPredictionDashboard();
    case AppRoutes.zoneSpecificThreatHeatmapsDashboard:
      return const ZoneSpecificThreatHeatmapsDashboard();
    case AppRoutes.realTimeThreatCorrelationDashboard:
      return const RealTimeThreatCorrelationDashboard();
    case AppRoutes.automatedThreatResponseExecution:
      return const AutomatedThreatResponseExecution();
    case AppRoutes.multiAiThreatOrchestrationHub:
      return const MultiAiThreatOrchestrationHub();
    case AppRoutes.predictiveIncidentPreventionEngine:
      return const PredictiveIncidentPreventionEngine();
    case AppRoutes.automatedIncidentPreventionHub:
      return const AutomatedIncidentPreventionHub();
    case AppRoutes.automatedIncidentResponseCenter:
      return const AutomatedIncidentResponseCenter();
    case AppRoutes.unifiedIncidentOrchestrationCenter:
      return const UnifiedIncidentOrchestrationCenter();
    case AppRoutes.unifiedIncidentManagementDashboard:
      return const UnifiedIncidentManagementDashboard();
    case AppRoutes.teamIncidentWarRoom:
      return const TeamIncidentWarRoom();
    case AppRoutes.incidentTestingSuiteDashboard:
      return const IncidentTestingSuiteDashboard();
    case AppRoutes.enhancedIncidentCorrelationEngine:
      return const EnhancedIncidentCorrelationEngine();
    case AppRoutes.securityMonitoringDashboard:
      return const SecurityMonitoringDashboard();
    case AppRoutes.aiSecurityDashboard:
      return const AiSecurityDashboard();
    case AppRoutes.owaspSecurityTestingDashboard:
      return const OwaspSecurityTestingDashboard();
    case AppRoutes.productionSecurityHardeningSprintDashboard:
      return const ProductionSecurityHardeningSprintDashboard();
    case AppRoutes.securityFeatureAdoptionAnalytics:
      return const SecurityFeatureAdoptionAnalytics();
    case AppRoutes.comprehensiveAuditLogScreen:
      return const ComprehensiveAuditLogScreen();
    case AppRoutes.comprehensiveAuditLogViewer:
      return const ComprehensiveAuditLogViewer();
    case AppRoutes.userActivityLogViewer:
      return const UserActivityLogViewer();
    case AppRoutes.realTimeSystemMonitoringDashboard:
      return const RealTimeSystemMonitoringDashboard();
    case AppRoutes.datadogApmMonitoringDashboard:
      return const DatadogApmMonitoringDashboard();
    case AppRoutes.datadogApmDistributedTracingHub:
      return const DatadogApmDistributedTracingHub();
    case AppRoutes.datadogApmPerformanceMonitoringHub:
      return const DatadogApmPerformanceMonitoringHub();
    case AppRoutes.realTimePerformanceMonitoringWithDatadogApmDashboard:
      return const RealTimePerformanceMonitoringWithDatadogApmDashboard();
    case AppRoutes.sentryErrorTrackingDashboard:
      return const SentryErrorTrackingDashboard();
    case AppRoutes.sentryErrorTrackingIntegrationHub:
      return const SentryErrorTrackingIntegrationHub();
    case AppRoutes.sentrySlackAlertPipelineDashboard:
      return const SentrySlackAlertPipelineDashboard();
    case AppRoutes.enhancedSentryAutomatedAlertingHub:
      return const EnhancedSentryAutomatedAlertingHub();
    case AppRoutes.slackIncidentNotificationsDashboard:
      return const SlackIncidentNotificationsDashboard();
    case AppRoutes.redisCacheMonitoringDashboard:
      return const RedisCacheMonitoringDashboard();
    case AppRoutes.advancedRedisCachingManagementHub:
      return const AdvancedRedisCachingManagementHub();
    case AppRoutes.supabaseQueryResultCachingManagementHub:
      return const SupabaseQueryResultCachingManagementHub();
    case AppRoutes.aiCacheManagementDashboard:
      return const AiCacheManagementDashboard();
    case AppRoutes.mobileAppPerformanceOptimizationHub:
      return const MobileAppPerformanceOptimizationHub();
    case AppRoutes.mobilePerformanceOptimizationDashboard:
      return const MobilePerformanceOptimizationDashboard();
    case AppRoutes.mobilePerformanceOptimizationHub:
      return const MobilePerformanceOptimizationHub();
    case AppRoutes.advancedPerformanceProfilingDashboard:
      return const AdvancedPerformanceProfilingDashboard();
    case AppRoutes.flutterClientSidePerformanceProfilingDashboard:
      return const FlutterClientSidePerformanceProfilingDashboard();
    case AppRoutes.performanceMonitoringDashboard:
      return const PerformanceMonitoringDashboard();
    case AppRoutes.performanceTestDashboard:
      return const PerformanceTestDashboard();
    case AppRoutes.appPerformanceDashboard:
      return const AppPerformanceDashboard();
    case AppRoutes.productionPerformanceMonitoringDashboard:
      return const ProductionPerformanceMonitoringDashboard();
    case AppRoutes.productionSlaMonitoringDashboard:
      return const ProductionSlaMonitoringDashboard();
    case AppRoutes.productionLoadTestingSuiteDashboard:
      return const ProductionLoadTestingSuiteDashboard();
    case AppRoutes.productionLoadTestAutoResponseHub:
      return const ProductionLoadTestAutoResponseHub();
    case AppRoutes.productionDeploymentHub:
      return const ProductionDeploymentHub();
    case AppRoutes.gitHubActionsCiCdPipelineDashboard:
      return const GitHubActionsCiCdPipelineDashboard();
    case AppRoutes.automatedTestingPerformanceDashboard:
      return const AutomatedTestingPerformanceDashboard();
    case AppRoutes.automatedTestingSuiteRunner:
      return const AutomatedTestingSuiteRunner();
    case AppRoutes.e2eTestingCoverageDashboard:
      return const E2eTestingCoverageDashboard();
    case AppRoutes.mobileLaunchReadinessChecklist:
      return const MobileLaunchReadinessChecklist();
    case AppRoutes.apiGatewayOptimizationDashboard:
      return const ApiGatewayOptimizationDashboard();
    case AppRoutes.apiPerformanceOptimizationDashboard:
      return const ApiPerformanceOptimizationDashboard();
    case AppRoutes.resTfulApiManagementHub:
      return const ResTfulApiManagementHub();
    case AppRoutes.webhookIntegrationManagementHub:
      return const WebhookIntegrationManagementHub();
    case AppRoutes.codeSplittingPerformanceOptimizationHub:
      return const CodeSplittingPerformanceOptimizationHub();
    case AppRoutes.hiveOfflineStorageManagementHub:
      return const HiveOfflineStorageManagementHub();
    case AppRoutes.enhancedHiveOfflineFirstArchitectureHub:
      return const EnhancedHiveOfflineFirstArchitectureHub();
    case AppRoutes.enhancedMobileOfflineSyncHub:
      return const EnhancedMobileOfflineSyncHub();
    case AppRoutes.crossDomainDataSyncHub:
      return const CrossDomainDataSyncHub();
    case AppRoutes.pwaOfflineVotingHub:
      return const PwaOfflineVotingHub();
    case AppRoutes.statusPageScreen:
      return const StatusPageScreen();
    case AppRoutes.automatedThresholdBasedAlertingHub:
      return const AutomatedThresholdBasedAlertingHub();
    case AppRoutes.unifiedAlertManagementCenter:
      return const UnifiedAlertManagementCenter();
    case AppRoutes.realTimeAlertDashboard:
      return const RealTimeAlertDashboard();
    case AppRoutes.realTimeEngagementDashboard:
      return const RealTimeEngagementDashboard();
    case AppRoutes.realTimeDashboardRefreshControlCenter:
      return const RealTimeDashboardRefreshControlCenter();
    case AppRoutes.mobileLoggingDashboard:
      return const MobileLoggingDashboard();
    case AppRoutes.logRocketSessionReplayMonitoringCenter:
      return const LogRocketSessionReplayMonitoringCenter();
    case AppRoutes.aiFailoverDashboardScreen:
      return const AiFailoverDashboardScreen();
    case AppRoutes.aiServiceFailoverControlCenter:
      return const AiServiceFailoverControlCenter();
    case AppRoutes.automaticAiFailoverEngineControlCenter:
      return const AutomaticAiFailoverEngineControlCenter();
    case AppRoutes.aiVoiceInteractionHub:
      return const AiVoiceInteractionHub();
    case AppRoutes.multiLanguageAiTranslationHub:
      return const MultiLanguageAiTranslationHub();
    case AppRoutes.claudeModelComparisonCenter:
      return const ClaudeModelComparisonCenter();
    case AppRoutes.claudeContextualInsightsOverlaySystem:
      return const ClaudeContextualInsightsOverlaySystem();
    case AppRoutes.claudeAutonomousActionsHub:
      return const ClaudeAutonomousActionsHub();
    case AppRoutes.realTimeClaudeCoachingApiHub:
      return const RealTimeClaudeCoachingApiHub();
    case AppRoutes.geminiCostEfficiencyAnalyzer:
      return const GeminiCostEfficiencyAnalyzer();
    case AppRoutes.anthropicContentIntelligenceHub:
      return const AnthropicContentIntelligenceHub();
    case AppRoutes.aiRecommendationsCenter:
      return const AiRecommendationsCenter();
    case AppRoutes.aiPoweredPredictiveAnalyticsEngine:
      return const AiPoweredPredictiveAnalyticsEngine();
    case AppRoutes.aiPredictiveModelingScreen:
      return const AiPredictiveModelingScreen();
    case AppRoutes.aiVoterSentimentDashboard:
      return const AiVoterSentimentDashboard();
    case AppRoutes.aiAnalyticsHub:
      return const AiAnalyticsHub();
    case AppRoutes.unifiedAiPerformanceDashboard:
      return const UnifiedAiPerformanceDashboard();
    case AppRoutes.contextAwareRecommendationsOverlay:
      return const ContextAwareRecommendationsOverlay();
    case AppRoutes.geminiRecommendationSyncHub:
      return const GeminiRecommendationSyncHub();
    case AppRoutes.unifiedAnalyticsDashboard:
      return const UnifiedAnalyticsDashboard();
    case AppRoutes.unifiedBusinessIntelligenceHub:
      return const UnifiedBusinessIntelligenceHub();
    case AppRoutes.executiveBusinessIntelligenceSuite:
      return const ExecutiveBusinessIntelligenceSuite();
    case AppRoutes.revenueAnalytics:
      return const RevenueAnalytics();
    case AppRoutes.revenueSplitAnalyticsDashboard:
      return const RevenueSplitAnalyticsDashboard();
    case AppRoutes.revenueSplitAdminControlCenter:
      return const RevenueSplitAdminControlCenter();
    case AppRoutes.unifiedRevenueIntelligenceDashboard:
      return const UnifiedRevenueIntelligenceDashboard();
    case AppRoutes.googleAnalyticsIntegrationDashboard:
      return const GoogleAnalyticsIntegrationDashboard();
    case AppRoutes.advancedGoogleAnalyticsTrackingHub:
      return const AdvancedGoogleAnalyticsTrackingHub();
    case AppRoutes.googleAnalyticsGamificationTrackingHub:
      return const GoogleAnalyticsGamificationTrackingHub();
    case AppRoutes.googleAnalyticsMonetizationTrackingHub:
      return const GoogleAnalyticsMonetizationTrackingHub();
    case AppRoutes.googleAnalyticsAiFeatureAdoptionDashboard:
      return const GoogleAnalyticsAiFeatureAdoptionDashboard();
    case AppRoutes.mlModelMonitoringDashboard:
      return const MlModelMonitoringDashboard();
    case AppRoutes.enhancedAnalyticsWithCdnIntegrationHub:
      return const EnhancedAnalyticsWithCdnIntegrationHub();
    case AppRoutes.advancedBehavioralHeatmapsMlAnalyticsHub:
      return const AdvancedBehavioralHeatmapsMlAnalyticsHub();
    case AppRoutes.collaborativeAnalyticsWorkspace:
      return const CollaborativeAnalyticsWorkspace();
    case AppRoutes.feedRankingAnalyticsDashboard:
      return const FeedRankingAnalyticsDashboard();
    case AppRoutes.enhancedFeedRankingWithClaudeIntegrationHub:
      return const EnhancedFeedRankingWithClaudeIntegrationHub();
    case AppRoutes.feedOrchestrationEngineControlCenter:
      return const FeedOrchestrationEngineControlCenter();
    case AppRoutes.unifiedCrossDomainRecommendationEngineHub:
      return const UnifiedCrossDomainRecommendationEngineHub();
    case AppRoutes.crossDomainIntelligenceHub:
      return const CrossDomainIntelligenceHub();
    case AppRoutes.predictionAnalyticsDashboard:
      return const PredictionAnalyticsDashboard();
    case AppRoutes.dedicatedMarketResearchDashboard:
      return const DedicatedMarketResearchDashboard();
    case AppRoutes.mobileElectionInsightsAnalytics:
      return const MobileElectionInsightsAnalytics();
    case AppRoutes.engagementMetricsDashboard:
      return const EngagementMetricsDashboard();
    case AppRoutes.featurePerformanceDashboard:
      return const FeaturePerformanceDashboard();
    case AppRoutes.featureFlagManagementDashboard:
      return const FeatureFlagManagementDashboard();
    case AppRoutes.analyticsPerformanceControlCenter:
      return const AnalyticsPerformanceControlCenter();
    case AppRoutes.advancedABTestingCenter:
      return const AdvancedABTestingCenter();
    case AppRoutes.carouselAnalyticsDashboard:
      return const CarouselAnalyticsDashboard();
    case AppRoutes.carouselAnalyticsIntelligenceCenter:
      return const CarouselAnalyticsIntelligenceCenter();
    case AppRoutes.carouselPerformanceAnalyticsDashboard:
      return const CarouselPerformanceAnalyticsDashboard();
    case AppRoutes.carouselPerformanceMonitorDashboard:
      return const CarouselPerformanceMonitorDashboard();
    case AppRoutes.carouselHealthAlertingDashboard:
      return const CarouselHealthAlertingDashboard();
    case AppRoutes.carouselHealthScalingDashboard:
      return const CarouselHealthScalingDashboard();
    case AppRoutes.carouselRoiAnalyticsDashboard:
      return const CarouselRoiAnalyticsDashboard();
    case AppRoutes.carouselSecurityAuditDashboard:
      return const CarouselSecurityAuditDashboard();
    case AppRoutes.carouselTemplateMarketplace:
      return const CarouselTemplateMarketplace();
    case AppRoutes.carouselCreatorTiersManagementHub:
      return const CarouselCreatorTiersManagementHub();
    case AppRoutes.carouselContentDiscoveryFilterCenter:
      return const CarouselContentDiscoveryFilterCenter();
    case AppRoutes.carouselPersonalizationEngineDashboard:
      return const CarouselPersonalizationEngineDashboard();
    case AppRoutes.carouselABTestingFrameworkDashboard:
      return const CarouselABTestingFrameworkDashboard();
    case AppRoutes.carouselRealTimeBiddingSystemHub:
      return const CarouselRealTimeBiddingSystemHub();
    case AppRoutes.carouselContentModerationAutomationCenter:
      return const CarouselContentModerationAutomationCenter();
    case AppRoutes.carouselMobileOptimizationSuiteDashboard:
      return const CarouselMobileOptimizationSuiteDashboard();
    case AppRoutes.carouselClaudeObservabilityHub:
      return const CarouselClaudeObservabilityHub();
    case AppRoutes.unifiedCarouselObservabilityHub:
      return const UnifiedCarouselObservabilityHub();
    case AppRoutes.unifiedCarouselOperationsCommandCenter:
      return const UnifiedCarouselOperationsCommandCenter();
    case AppRoutes.advancedCarouselFilterControlCenter:
      return const AdvancedCarouselFilterControlCenter();
    case AppRoutes.smsProviderDashboard:
      return const SmsProviderDashboard();
    case AppRoutes.smsFailoverConfigurationCenter:
      return const SmsFailoverConfigurationCenter();
    case AppRoutes.smsRateLimitingQueueControlCenter:
      return const SmsRateLimitingQueueControlCenter();
    case AppRoutes.smsQueueManagementDashboard:
      return const SmsQueueManagementDashboard();
    case AppRoutes.smsDeliveryAnalyticsDashboard:
      return const SmsDeliveryAnalyticsDashboard();
    case AppRoutes.smsComplianceManagerDashboard:
      return const SmsComplianceManagerDashboard();
    case AppRoutes.smsWebhookManagementDashboard:
      return const SmsWebhookManagementDashboard();
    case AppRoutes.smsAlertTemplateManagementCenter:
      return const SmsAlertTemplateManagementCenter();
    case AppRoutes.smsEmergencyAlertsHub:
      return const SmsEmergencyAlertsHub();
    case AppRoutes.twilioSmsEmergencyAlertManagementCenter:
      return const TwilioSmsEmergencyAlertManagementCenter();
    case AppRoutes.twilioVideoLiveStreamingHub:
      return const TwilioVideoLiveStreamingHub();
    case AppRoutes.telnyxSmsProviderManagementDashboard:
      return const TelnyxSmsProviderManagementDashboard();
    case AppRoutes.openAiSmsOptimizationHub:
      return const OpenAiSmsOptimizationHub();
    case AppRoutes.blockchainAuditPortal:
    case AppRoutes.liveStreamingCenter:
      return RoutePlaceholderScreen(
        routeName: name,
        title: name.startsWith('/') ? name.substring(1).replaceAll('-', ' ') : name,
      );
    default:
      return RoutePlaceholderScreen(
        routeName: name,
        title: name.startsWith('/') ? name.substring(1).replaceAll('-', ' ') : name,
      );
  }
}
