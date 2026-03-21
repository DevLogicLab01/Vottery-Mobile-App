/// Map route path (no leading slash, camelCase or path segment) to platform_feature_toggles.feature_key.
/// Same keys as Web routeFeatureKeys.js for parity. Use for gating screens by admin On/Off panel.
class RouteFeatureKeys {
  RouteFeatureKeys._();

  static const Map<String, String> routeToFeatureKey = {
    'electionCreationStudio': 'election_creation',
    'voteVerificationPortal': 'vote_verification_portal',
    'vote-verification-portal': 'vote_verification_portal',
    'vpCharityHub': 'vp_redemption_marketplace_charity_hub',
    'vp-redemption-marketplace-charity-hub':
        'vp_redemption_marketplace_charity_hub',
    'vpCryptoConversion': 'vp_redemption_marketplace_charity_hub',
    'blockchainVoteReceiptCenter': 'vote_verification_portal',
    'blockchainVoteVerificationHub': 'blockchain_verification',
    'verifyAuditElectionsHub': 'blockchain_verification',
    'blockchainAuditPortal': 'blockchain_verification',
    'blockchain-audit-portal': 'blockchain_verification',
    'voteCasting': 'secure_voting_interface',
    'secure-voting-interface': 'secure_voting_interface',
    'enhancedVoteCasting': 'secure_voting_interface',
    'collaborativeVotingRoom': 'collaborative_voting_room',
    'collaborative-voting-room': 'collaborative_voting_room',
    'locationVoting': 'location_based_voting',
    'location-based-voting': 'location_based_voting',
    'enhancedVoteCastingWithPredictionIntegration': 'prediction_pools',
    'election-prediction-pools-interface': 'prediction_pools',
    'voteDashboard': 'vote_in_elections_hub',
    'vote-in-elections-hub': 'vote_in_elections_hub',
    'voteDiscovery': 'voting_categories',
    'digitalWalletScreen': 'digital_wallet_hub',
    'digital-wallet-hub': 'digital_wallet_hub',
    'walletPrizeDistributionCenter': 'prize_distribution_tracking_center',
    'prize-distribution-tracking-center': 'prize_distribution_tracking_center',
    'multiCurrencySettlementDashboard': 'multi_currency_settlement_dashboard',
    'multi-currency-settlement-dashboard': 'multi_currency_settlement_dashboard',
    'adminGamificationTogglePanel': 'gamified_elections',
    'vpEconomyDashboard': 'vp_universal_currency_center',
    'vottery-points-vp-universal-currency-center':
        'vp_universal_currency_center',
    'questManagementDashboard': 'dynamic_quest_management_dashboard',
    'dynamic-quest-management-dashboard': 'dynamic_quest_management_dashboard',
    'seasonalChallengesHub': 'seasonal_challenges',
    'seasonal-challenges': 'seasonal_challenges',
    'unifiedGamificationDashboard': 'unified_gamification_dashboard',
    'unified-gamification-dashboard': 'unified_gamification_dashboard',
    'userProfile': 'user_profile_hub',
    'socialActivityTimeline': 'social_activity_timeline',
    'social-activity-timeline': 'social_activity_timeline',
    'directMessaging': 'direct_messaging',
    'directMessagingScreen': 'direct_messaging',
    'direct-messaging-center': 'direct_messaging',
    'notificationCenter': 'notification_center_hub',
    'notificationCenterHub': 'notification_center_hub',
    'notification-center-hub': 'notification_center_hub',
    'pushNotificationManagementCenter': 'smart_push_notifications_optimization_center',
    'smart-push-notifications-optimization-center':
        'smart_push_notifications_optimization_center',
    'friendsManagement': 'friends_management_hub',
    'friendsManagementHub': 'friends_management_hub',
    'friends-management-hub': 'friends_management_hub',
    'settingsAccount': 'settings_account_dashboard',
    'settings-account-dashboard': 'settings_account_dashboard',
    'personalAnalytics': 'personal_analytics_dashboard',
    'personal-analytics-dashboard': 'personal_analytics_dashboard',
    'realTimeAnalyticsDashboard': 'real_time_analytics_dashboard',
    'real-time-analytics-dashboard': 'real_time_analytics_dashboard',
    'livePlatformMonitoringDashboard': 'live_platform_monitoring_dashboard',
    'live-platform-monitoring-dashboard': 'live_platform_monitoring_dashboard',
    'userAnalytics': 'user_analytics_dashboard',
    'userAnalyticsDashboard': 'user_analytics_dashboard',
    'user-analytics-dashboard': 'user_analytics_dashboard',
    'userSecurityCenter': 'user_security_center',
    'user-security-center': 'user_security_center',
    'participatoryAdsStudio': 'participatory_advertising',
    'participatory-ads-studio': 'participatory_advertising',
    'vottery-ads-studio': 'participatory_advertising',
    'campaignManagementDashboard': 'campaign_management_dashboard',
    'campaign-management-dashboard': 'campaign_management_dashboard',
    'campaignOptimizationDashboard': 'campaign_optimization_dashboard',
    'automated-campaign-optimization-dashboard':
        'campaign_optimization_dashboard',
    'campaignTemplateGallery': 'campaign_template_gallery',
    'campaign-template-gallery': 'campaign_template_gallery',
    'advertiserAnalyticsDashboard': 'advertiser_analytics_roi',
    'advertiser-analytics-roi-dashboard': 'advertiser_analytics_roi',
    'realTimeAdvertiserRoiDashboard':
        'enhanced_real_time_advertiser_roi_dashboard',
    'enhanced-real-time-advertiser-roi-dashboard':
        'enhanced_real_time_advertiser_roi_dashboard',
    'dynamicCpePricingEngineDashboard':
        'sponsored_elections_schema_cpe_management_hub',
    'enhancedMobileAdminDashboard': 'mobile_admin_dashboard',
    'mobile-admin-dashboard': 'mobile_admin_dashboard',
    'multiRoleAdminControlCenter': 'advanced_admin_role_management_system',
    'advanced-admin-role-management-system':
        'advanced_admin_role_management_system',
    'adminAutomationControlPanel': 'admin_automation_control_panel',
    'contentModerationControlCenter': 'ai_content_moderation',
    'aiContentModerationDashboard': 'ai_content_safety_screening_center',
    'ai-content-safety-screening-center': 'ai_content_safety_screening_center',
    'contentDistributionControlCenter': 'content_distribution_control_center',
    'content-distribution-control-center': 'content_distribution_control_center',
    'anthropicContentIntelligenceHub': 'anthropic_content_intelligence_center',
    'anthropic-content-intelligence-center':
        'anthropic_content_intelligence_center',
    'anthropicAdvancedContentAnalysisCenter':
        'anthropic_advanced_content_analysis_center',
    'anthropic-advanced-content-analysis-center':
        'anthropic_advanced_content_analysis_center',
    'campaignManagement': 'campaign_management_dashboard',
    'advertiserAnalyticsRoi': 'advertiser_analytics_roi',
    'brandAdvertiserRegistration': 'brand_advertiser_registration',
    'brand-advertiser-registration-portal': 'brand_advertiser_registration',
    'creatorMonetizationStudio': 'creator_monetization_studio',
    'creator-monetization-studio': 'creator_monetization_studio',
    'creatorSuccessAcademy': 'creator_success_academy',
    'creator-success-academy': 'creator_success_academy',
    'enhancedMcqCreationStudio': 'enhanced_mcq_creation_studio',
    'enhancedMcqPreVoting': 'mcq_pre_voting_interface',
    'enhancedMcqImageOptionsInterface': 'enhanced_mcq_image_interface',
    'liveQuestionInjection': 'live_question_injection_management_center',
    'interactiveOnboardingWizard': 'interactive_onboarding_wizard',
    'aiGuidedTutorial': 'ai_guided_interactive_tutorial_system',
    'userFeedbackPortal': 'user_feedback_portal_feature_request_system',
    'contentModerationControl': 'ai_content_moderation',
    'topicPreferenceCollection': 'interactive_topic_preference_collection_hub',
    'topicPreferenceCollectionHub': 'interactive_topic_preference_collection_hub',
    'interactive-topic-preference-collection-hub':
        'interactive_topic_preference_collection_hub',
    'accessibilityPreferences': 'accessibility_analytics_preferences_center',
    'accessibility-analytics-preferences-center':
        'accessibility_analytics_preferences_center',
    'globalLocalization': 'global_localization_control_center',
    'global-localization-control-center': 'global_localization_control_center',
    'multiAuthenticationGateway': 'multi_authentication_gateway',
    'multi-authentication-gateway': 'multi_authentication_gateway',
    'communityElectionsHub': 'community_elections_hub',
    'community-elections-hub': 'community_elections_hub',
    'topicBasedCommunityElections': 'topic_based_community_elections_hub',
    'topic-based-community-elections-hub': 'topic_based_community_elections_hub',
    'enhancedGroupsDiscovery': 'enhanced_groups_discovery_management_hub',
    'enhancedGroupsHub': 'enhanced_groups_discovery_management_hub',
    'enhanced-groups-discovery-management-hub':
        'enhanced_groups_discovery_management_hub',
    'comprehensiveSocialEngagement': 'comprehensive_social_engagement_suite',
    'communityEngagementDashboard': 'community_engagement_dashboard',
    'community-engagement-dashboard': 'community_engagement_dashboard',
    'creator-community-hub': 'creator_community_hub',
    'creatorCommunityHub': 'creator_community_hub',
    'joltsVideoStudio': 'jolts_video_studio',
    'voterEducationHub': 'voter_education_hub',
    'voter-education-hub': 'voter_education_hub',
    'smartPushNotifications': 'smart_push_notifications_optimization_center',
    'premiumSubscriptionCenter': 'enhanced_premium_subscription_center',
    'enhanced-premium-subscription-center':
        'enhanced_premium_subscription_center',
    'electionInsightsPredictive': 'election_insights_predictive_analytics',
    'mobileElectionInsightsAnalytics': 'election_insights_predictive_analytics',
    'election-insights-predictive-analytics':
        'election_insights_predictive_analytics',
    'electionsDashboard': 'elections_dashboard',
    'elections-dashboard': 'elections_dashboard',
    'creatorReputationElection': 'creator_reputation_election_management_system',
    'creator-reputation-election-management-system':
        'creator_reputation_election_management_system',
    'stripeConnectAccountLinking': 'stripe_connect_account_linking_interface',
    'stripe-connect-account-linking-interface':
        'stripe_connect_account_linking_interface',
    'enhancedCreatorPayout': 'enhanced_creator_payout_dashboard_stripe_connect',
    'enhanced-creator-payout-dashboard-with-stripe-connect-integration':
        'enhanced_creator_payout_dashboard_stripe_connect',
    'creatorBrandPartnership': 'creator_brand_partnership_portal',
    'creator-brand-partnership-portal': 'creator_brand_partnership_portal',
    'creatorGrowthAnalytics': 'creator_growth_analytics_dashboard',
    'creator-growth-analytics-dashboard': 'creator_growth_analytics_dashboard',
    'creatorRevenueForecastingDashboard': 'creator_revenue_forecasting_dashboard',
    'creator-revenue-forecasting-dashboard': 'creator_revenue_forecasting_dashboard',
    'creatorChurnPrediction': 'creator_churn_prediction_intelligence_center',
    'creator-churn-prediction-intelligence-center':
        'creator_churn_prediction_intelligence_center',
    'creatorMarketplace': 'creator_marketplace_screen',
    'creator-marketplace-screen': 'creator_marketplace_screen',
    'creatorCountryVerification': 'creator_country_verification_interface',
    'creator-country-verification-interface':
        'creator_country_verification_interface',
    'claudeCreatorSuccessAgent': 'claude_creator_success_agent',
    'claude-creator-success-agent': 'claude_creator_success_agent',
    'predictiveCreatorInsights': 'predictive_creator_insights_dashboard',
    'predictive-creator-insights-dashboard':
        'predictive_creator_insights_dashboard',
    'enhancedHomeFeed': 'enhanced_home_feed_dashboard',
    'enhanced-home-feed-dashboard': 'enhanced_home_feed_dashboard',
    'mcqAnalyticsIntelligence': 'mcq_analytics_intelligence_dashboard',
    'mcqAnalyticsIntelligenceDashboard': 'mcq_analytics_intelligence_dashboard',
    'mcq-analytics-intelligence-dashboard': 'mcq_analytics_intelligence_dashboard',
    'mcqAbTestingAnalytics': 'mcq_ab_testing_analytics_dashboard',
    'mcqAbTestingAnalyticsDashboard': 'mcq_ab_testing_analytics_dashboard',
    'mcq-a-b-testing-analytics-dashboard': 'mcq_ab_testing_analytics_dashboard',
    'fraudDetectionAlert': 'fraud_detection_alert_management_center',
    'fraud-detection-alert-management-center':
        'fraud_detection_alert_management_center',
    'predictive-anomaly-alerting-deviation-monitoring-hub':
        'fraud_detection_alert_management_center',
    'advancedPerplexityFraud': 'advanced_perplexity_fraud_intelligence_center',
    'advanced-perplexity-fraud-intelligence-center':
        'advanced_perplexity_fraud_intelligence_center',
    'advanced-perplexity-fraud-forecasting-center':
        'advanced_perplexity_fraud_forecasting_center',
    'advanced-ml-threat-detection-center': 'fraud_detection_alert_management_center',
    'continuous-ml-feedback-outcome-learning-center':
        'advanced_perplexity_fraud_intelligence_center',
    'perplexity-market-research-intelligence-center':
        'advanced_perplexity_fraud_intelligence_center',
    'perplexity-strategic-planning-center':
        'advanced_perplexity_fraud_forecasting_center',
    'perplexity-carousel-intelligence-dashboard':
        'advanced_perplexity_fraud_intelligence_center',
    'dedicatedMarketResearchDashboard':
        'advanced_perplexity_fraud_intelligence_center',
    'dedicated-market-research-dashboard':
        'advanced_perplexity_fraud_intelligence_center',
    'predictionAnalyticsDashboard':
        'advanced_perplexity_fraud_forecasting_center',
    'prediction-analytics-dashboard':
        'advanced_perplexity_fraud_forecasting_center',
    'anthropic-claude-revenue-risk-intelligence-center':
        'creator_revenue_forecasting_dashboard',
    'claude-analytics-dashboard-for-campaign-intelligence':
        'claude_ai_feed_intelligence_center',
    'claude-predictive-analytics-dashboard':
        'claude_ai_feed_intelligence_center',
    'claude-ai-content-curation-intelligence-center':
        'anthropic_content_intelligence_center',
    'claude-model-comparison-center': 'claude_ai_feed_intelligence_center',
    'claude-content-optimization-engine': 'content_quality_scoring_claude',
    'automatic-ai-failover-engine-control-center':
        'live_platform_monitoring_dashboard',
    'ai-performance-orchestration-dashboard':
        'real_time_performance_testing_suite',
    'ai-powered-performance-advisor-hub':
        'real_time_performance_testing_suite',
    'open-ai-carousel-content-intelligence-center':
        'content_distribution_control_center',
    'autonomous-claude-agent-orchestration-hub':
        'unified_incident_response_orchestration_center',
    'enhanced-real-time-behavioral-heatmaps-center':
        'fraud_detection_alert_management_center',
    'real-time-brand-alert-budget-monitoring-center':
        'real_time_brand_alert_budget_monitoring_center',
    'gemini-cost-efficiency-analyzer-case-report-generator':
        'live_platform_monitoring_dashboard',
    'geminiCostEfficiencyAnalyzer':
        'live_platform_monitoring_dashboard',
    'aiPoweredPredictiveAnalyticsEngine':
        'election_insights_predictive_analytics',
    'ai-powered-predictive-analytics-engine':
        'election_insights_predictive_analytics',
    'unifiedAiPerformanceDashboard':
        'real_time_performance_testing_suite',
    'unified-ai-performance-dashboard':
        'real_time_performance_testing_suite',
    'unifiedIncidentResponse': 'unified_incident_response_orchestration_center',
    'unified-incident-response-orchestration-center':
        'unified_incident_response_orchestration_center',
    'unified-incident-response-command-center':
        'unified_incident_response_orchestration_center',
    'automatedIncidentResponse': 'automated_incident_response_portal',
    'automated-incident-response-portal': 'automated_incident_response_portal',
    'advanced-monitoring-hub-with-automated-incident-response':
        'unified_incident_response_orchestration_center',
    'enhanced-incident-response-analytics':
        'unified_incident_response_orchestration_center',
    'custom-alert-rules-engine': 'unified_alert_management_center',
    'advanced-custom-alert-rules-engine': 'unified_alert_management_center',
    'unified-alert-management-center': 'unified_alert_management_center',
    'stakeholder-incident-communication-hub': 'unified_alert_management_center',
    'sms-emergency-alerts-hub': 'unified_alert_management_center',
    'sms-webhook-delivery-analytics-hub': 'unified_alert_management_center',
    'telnyx-sms-provider-management-center': 'unified_alert_management_center',
    'api-documentation-portal': 'api_rate_limiting_dashboard',
    'countryRestrictionsAdmin': 'country_restrictions',
    'platformIntegrationsAdmin': 'platform_integrations',

    // Advanced / infra features with existing toggles
    'unifiedPaymentOrchestrationHub': 'unified_payment_orchestration_hub',
    'statusPageScreen': 'public_status_page',
    'predictiveIncidentPreventionEngine': 'predictive_incident_prevention_24h',
    'performanceTestingDashboard': 'real_time_performance_testing_suite',
    'analyticsExportReportingHub': 'analytics_export_reporting_hub',
    'apiRateLimitingDashboard': 'api_rate_limiting_dashboard',
    'costAnalyticsRoiDashboard': 'cost_analytics_roi_dashboard',
    'claudeDecisionReasoningHub': 'claude_decision_reasoning_hub',
    'securityComplianceAudit': 'security_compliance_audit_screen',
    'security-compliance-audit-screen': 'security_compliance_audit_screen',
    'security-compliance-automation-center': 'security_compliance_audit_screen',
    'automated-payout-calculation-engine': 'prize_distribution_tracking_center',
    'country-based-payout-processing-engine':
        'prize_distribution_tracking_center',
    'admin-quest-configuration-control-center':
        'dynamic_quest_management_dashboard',
    'stripe-subscription-management-center':
        'stripe_subscription_management_center',
    'admin-subscription-analytics-hub': 'admin_subscription_analytics_hub',
    'public-status-page': 'public_status_page',
    'mobile-operations-command-console': 'mobile_operations_command_console',
    'predictive-incident-prevention-24h': 'predictive_incident_prevention_24h',
    'real-time-performance-testing-suite': 'real_time_performance_testing_suite',
    'performance-regression-detection': 'performance_regression_detection',
    'analytics-export-reporting-hub': 'analytics_export_reporting_hub',
    'res-tful-api-management-center': 'api_rate_limiting_dashboard',
    'webhook-integration-hub': 'analytics_export_reporting_hub',
    'advanced-webhook-orchestration-hub': 'analytics_export_reporting_hub',
    'executive-reporting-compliance-automation-hub':
        'analytics_export_reporting_hub',
    'automated-executive-reporting-claude-intelligence-hub':
        'analytics_export_reporting_hub',
    'api-rate-limiting-dashboard': 'api_rate_limiting_dashboard',
    'unified-payment-orchestration-hub': 'unified_payment_orchestration_hub',
    'unifiedSearchSystemHub': 'advanced_search_discovery_intelligence_hub',
    'advancedUnifiedSearchScreen': 'advanced_search_discovery_intelligence_hub',
    'advanced-search-discovery-intelligence-hub':
        'advanced_search_discovery_intelligence_hub',
    'claudeContextualInsightsOverlaySystem':
        'context_aware_claude_recommendations_overlay',
    'contentQualityScoringClaude': 'content_quality_scoring_claude',
    'content-quality-scoring-claude': 'content_quality_scoring_claude',
    'unified-ai-decision-orchestration-command-center':
        'unified_incident_response_orchestration_center',
    'unified-ai-orchestration-command-center':
        'unified_incident_response_orchestration_center',
    'query-performance-monitoring-dashboard': 'live_platform_monitoring_dashboard',
    'comprehensive-health-monitoring-dashboard': 'live_platform_monitoring_dashboard',
    'production-monitoring-dashboard': 'live_platform_monitoring_dashboard',
    'ml-model-training-interface': 'claude_ai_feed_intelligence_center',
    'load-testing-performance-analytics-center': 'real_time_performance_testing_suite',
    'performance-optimization-engine-dashboard': 'performance_regression_detection',
    'advanced-supabase-real-time-coordination-hub': 'live_platform_monitoring_dashboard',
    'enhanced-real-time-web-socket-coordination-hub': 'live_platform_monitoring_dashboard',
    'real-time-web-socket-monitoring-command-center': 'live_platform_monitoring_dashboard',
    'automated-data-cache-management-hub': 'live_platform_monitoring_dashboard',
    'auto-improving-fraud-detection-intelligence-center':
        'advanced_perplexity_fraud_intelligence_center',
  };

  /// Get feature_key for a route name/path. Returns null if not gated.
  static String? getFeatureKeyForRoute(String routeNameOrPath) {
    if (routeNameOrPath.isEmpty) return null;
    final normalized = routeNameOrPath
        .replaceFirst(RegExp(r'^/'), '')
        .split('?')
        .first;
    if (routeToFeatureKey.containsKey(normalized)) {
      return routeToFeatureKey[normalized];
    }
    return null;
  }
}
