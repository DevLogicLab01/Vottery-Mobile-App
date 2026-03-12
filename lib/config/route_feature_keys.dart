/// Map route path (no leading slash, camelCase or path segment) to platform_feature_toggles.feature_key.
/// Same keys as Web routeFeatureKeys.js for parity. Use for gating screens by admin On/Off panel.
class RouteFeatureKeys {
  RouteFeatureKeys._();

  static const Map<String, String> routeToFeatureKey = {
    'electionCreationStudio': 'election_creation',
    'voteVerificationPortal': 'vote_verification_portal',
    'blockchainAuditPortal': 'blockchain_verification',
    'voteCasting': 'secure_voting_interface',
    'voteDashboard': 'vote_in_elections_hub',
    'voteDiscovery': 'voting_categories',
    'digitalWalletScreen': 'digital_wallet_hub',
    'adminGamificationTogglePanel': 'gamified_elections',
    'questManagementDashboard': 'dynamic_quest_management_dashboard',
    'unifiedGamificationDashboard': 'unified_gamification_dashboard',
    'userProfile': 'user_profile_hub',
    'directMessaging': 'direct_messaging',
    'notificationCenter': 'notification_center_hub',
    'friendsManagement': 'friends_management_hub',
    'settingsAccount': 'settings_account_dashboard',
    'personalAnalytics': 'personal_analytics_dashboard',
    'userAnalytics': 'user_analytics_dashboard',
    'userSecurityCenter': 'user_security_center',
    'participatoryAdsStudio': 'participatory_advertising',
    'campaignManagement': 'campaign_management_dashboard',
    'advertiserAnalyticsRoi': 'advertiser_analytics_roi',
    'brandAdvertiserRegistration': 'brand_advertiser_registration',
    'creatorMonetizationStudio': 'creator_monetization_studio',
    'creatorSuccessAcademy': 'creator_success_academy',
    'enhancedMcqCreationStudio': 'enhanced_mcq_creation_studio',
    'enhancedMcqPreVoting': 'mcq_pre_voting_interface',
    'liveQuestionInjection': 'live_question_injection_management_center',
    'interactiveOnboardingWizard': 'interactive_onboarding_wizard',
    'aiGuidedTutorial': 'ai_guided_interactive_tutorial_system',
    'userFeedbackPortal': 'user_feedback_portal_feature_request_system',
    'contentModerationControl': 'ai_content_moderation',
    'topicPreferenceCollection': 'interactive_topic_preference_collection_hub',
    'accessibilityPreferences': 'accessibility_analytics_preferences_center',
    'globalLocalization': 'global_localization_control_center',
    'multiAuthenticationGateway': 'multi_authentication_gateway',
    'communityElectionsHub': 'community_elections_hub',
    'topicBasedCommunityElections': 'topic_based_community_elections_hub',
    'enhancedGroupsDiscovery': 'enhanced_groups_discovery_management_hub',
    'comprehensiveSocialEngagement': 'comprehensive_social_engagement_suite',
    'communityEngagementDashboard': 'community_engagement_dashboard',
    'smartPushNotifications': 'smart_push_notifications_optimization_center',
    'premiumSubscriptionCenter': 'enhanced_premium_subscription_center',
    'electionInsightsPredictive': 'election_insights_predictive_analytics',
    'electionsDashboard': 'elections_dashboard',
    'creatorReputationElection': 'creator_reputation_election_management_system',
    'stripeConnectAccountLinking': 'stripe_connect_account_linking_interface',
    'enhancedCreatorPayout': 'enhanced_creator_payout_dashboard_stripe_connect',
    'creatorBrandPartnership': 'creator_brand_partnership_portal',
    'creatorGrowthAnalytics': 'creator_growth_analytics_dashboard',
    'creatorChurnPrediction': 'creator_churn_prediction_intelligence_center',
    'creatorMarketplace': 'creator_marketplace_screen',
    'creatorCountryVerification': 'creator_country_verification_interface',
    'claudeCreatorSuccessAgent': 'claude_creator_success_agent',
    'predictiveCreatorInsights': 'predictive_creator_insights_dashboard',
    'enhancedHomeFeed': 'enhanced_home_feed_dashboard',
    'mcqAnalyticsIntelligence': 'mcq_analytics_intelligence_dashboard',
    'mcqAbTestingAnalytics': 'mcq_ab_testing_analytics_dashboard',
    'fraudDetectionAlert': 'fraud_detection_alert_management_center',
    'advancedPerplexityFraud': 'advanced_perplexity_fraud_intelligence_center',
    'unifiedIncidentResponse': 'unified_incident_response_orchestration_center',
    'automatedIncidentResponse': 'automated_incident_response_portal',
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
    'adminAutomationControlPanel': 'admin_automation_control_panel',
    'securityComplianceAudit': 'security_compliance_audit_screen',
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
