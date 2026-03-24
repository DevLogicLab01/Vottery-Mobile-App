/// Web app base URL and admin paths. Same as Web (React) for parity.
class AppUrls {
  AppUrls._();

  static const String webAppBase = 'https://vottery.com';

  /// Country restrictions admin (Web path: /country-restrictions-admin)
  static const String countryRestrictionsAdmin =
      '$webAppBase/country-restrictions-admin';

  /// Platform integrations admin (Web path: /platform-integrations-admin)
  static const String platformIntegrationsAdmin =
      '$webAppBase/platform-integrations-admin';

  /// Country revenue share management (Web path: /country-revenue-share-management-center)
  static const String countryRevenueShareManagement =
      '$webAppBase/country-revenue-share-management-center';

  /// Regional revenue analytics (Web path: /regional-revenue-analytics-dashboard)
  static const String regionalRevenueAnalytics =
      '$webAppBase/regional-revenue-analytics-dashboard';

  /// International payment dispute resolution (Web: /international-payment-dispute-resolution-center)
  static const String internationalPaymentDisputeResolution =
      '$webAppBase/international-payment-dispute-resolution-center';

  /// Legacy alias — use [internationalPaymentDisputeResolution] for admin parity.
  static const String claudeDisputeResolution =
      internationalPaymentDisputeResolution;

  /// Multi-currency settlement (Web path: /multi-currency-settlement-dashboard)
  static const String multiCurrencySettlement =
      '$webAppBase/multi-currency-settlement-dashboard';

  /// Admin subscription analytics (Web: /admin-subscription-analytics-hub)
  static const String adminSubscriptionAnalyticsHub =
      '$webAppBase/admin-subscription-analytics-hub';

  /// Stripe subscription management (Web: /stripe-subscription-management-center)
  static const String stripeSubscriptionManagementCenter =
      '$webAppBase/stripe-subscription-management-center';

  /// Stripe payment integration hub (Web: /stripe-payment-integration-hub)
  static const String stripePaymentIntegrationHub =
      '$webAppBase/stripe-payment-integration-hub';

  /// SMS webhook delivery analytics hub (Web: /sms-webhook-delivery-analytics-hub)
  static const String smsWebhookDeliveryAnalyticsHub =
      '$webAppBase/sms-webhook-delivery-analytics-hub';

  /// SMS emergency alerts hub (Web: /sms-emergency-alerts-hub)
  static const String smsEmergencyAlertsHub =
      '$webAppBase/sms-emergency-alerts-hub';

  /// Telnyx SMS provider management center (Web: /telnyx-sms-provider-management-center)
  static const String telnyxSmsProviderManagementCenter =
      '$webAppBase/telnyx-sms-provider-management-center';

  /// Alert rules engine (Web: /custom-alert-rules-engine)
  static const String customAlertRulesEngine =
      '$webAppBase/custom-alert-rules-engine';

  /// Advanced alert rules engine (Web: /advanced-custom-alert-rules-engine)
  static const String advancedCustomAlertRulesEngine =
      '$webAppBase/advanced-custom-alert-rules-engine';

  /// Unified alert management center (Web: /unified-alert-management-center)
  static const String unifiedAlertManagementCenter =
      '$webAppBase/unified-alert-management-center';

  /// Automated payment processing hub (Web: /automated-payment-processing-hub)
  static const String automatedPaymentProcessingHub =
      '$webAppBase/automated-payment-processing-hub';

  /// Automated payout calculation engine (Web: /automated-payout-calculation-engine)
  static const String automatedPayoutCalculationEngine =
      '$webAppBase/automated-payout-calculation-engine';

  /// Country-based payout processing engine (Web: /country-based-payout-processing-engine)
  static const String countryBasedPayoutProcessingEngine =
      '$webAppBase/country-based-payout-processing-engine';

  /// Comprehensive gamification admin (Web: /comprehensive-gamification-admin-control-center)
  static const String comprehensiveGamificationAdminControlCenter =
      '$webAppBase/comprehensive-gamification-admin-control-center';
  static const String userProfileHub = '$webAppBase/user-profile-hub';
  static const String unifiedGamificationDashboard =
      '$webAppBase/unified-gamification-dashboard';
  static const String dynamicQuestManagementDashboard =
      '$webAppBase/dynamic-quest-management-dashboard';
  static const String vpEconomyHealthMonitorDashboard =
      '$webAppBase/vp-economy-health-monitor-dashboard';
  static const String creatorSuccessAcademy = '$webAppBase/creator-success-academy';
  static const String electionCreationStudio = '$webAppBase/election-creation-studio';
  static const String creatorMonetizationStudio =
      '$webAppBase/creator-monetization-studio';
  static const String creatorRevenueForecastingDashboard =
      '$webAppBase/creator-revenue-forecasting-dashboard';
  static const String realTimeAnalyticsDashboard =
      '$webAppBase/real-time-analytics-dashboard';
  static const String creatorMarketplaceScreen =
      '$webAppBase/creator-marketplace-screen';
  static const String notificationCenterHub = '$webAppBase/notification-center-hub';
  static const String predictionPoolNotificationsHub =
      '$webAppBase/prediction-pool-notifications-hub';

  /// Platform gamification core engine (Web: /platform-gamification-core-engine)
  static const String platformGamificationCoreEngine =
      '$webAppBase/platform-gamification-core-engine';

  /// Gamification campaign management (Web: /gamification-campaign-management-center)
  static const String gamificationCampaignManagementCenter =
      '$webAppBase/gamification-campaign-management-center';

  /// Gamification rewards management (Web: /gamification-rewards-management-center)
  static const String gamificationRewardsManagementCenter =
      '$webAppBase/gamification-rewards-management-center';

  /// Admin quest configuration center (Web: /admin-quest-configuration-control-center)
  static const String adminQuestConfigurationControlCenter =
      '$webAppBase/admin-quest-configuration-control-center';

  /// Security compliance automation (Web: /security-compliance-automation-center)
  static const String securityComplianceAutomationCenter =
      '$webAppBase/security-compliance-automation-center';

  /// Localization & tax reporting (Web: /localization-tax-reporting-intelligence-center)
  static const String localizationTaxReportingIntelligenceCenter =
      '$webAppBase/localization-tax-reporting-intelligence-center';

  /// Gamification multi-language intelligence center (Web: /gamification-multi-language-intelligence-center)
  static const String gamificationMultiLanguageIntelligenceCenter =
      '$webAppBase/gamification-multi-language-intelligence-center';

  /// Compliance dashboard (Web: /compliance-dashboard)
  static const String complianceDashboard = '$webAppBase/compliance-dashboard';

  /// Compliance audit dashboard (Web: /compliance-audit-dashboard)
  static const String complianceAuditDashboard =
      '$webAppBase/compliance-audit-dashboard';

  /// Regulatory compliance automation (Web: /regulatory-compliance-automation-hub)
  static const String regulatoryComplianceAutomationHub =
      '$webAppBase/regulatory-compliance-automation-hub';

  /// Public bulletin & audit trail (Web: /public-bulletin-board-audit-trail-center)
  static const String publicBulletinBoardAuditTrailCenter =
      '$webAppBase/public-bulletin-board-audit-trail-center';

  /// Cryptographic security center (Web: /cryptographic-security-management-center)
  static const String cryptographicSecurityManagementCenter =
      '$webAppBase/cryptographic-security-management-center';

  /// Vote anonymity mixnet hub (Web: /vote-anonymity-mixnet-control-hub)
  static const String voteAnonymityMixnetControlHub =
      '$webAppBase/vote-anonymity-mixnet-control-hub';

  /// Vote verification portal (Web: /vote-verification-portal)
  static const String voteVerificationPortal =
      '$webAppBase/vote-verification-portal';

  /// Vote in elections hub (Web: /vote-in-elections-hub)
  static const String voteInElectionsHub = '$webAppBase/vote-in-elections-hub';

  /// Elections dashboard (Web: /elections-dashboard)
  static const String electionsDashboard = '$webAppBase/elections-dashboard';

  /// Secure voting interface (Web: /secure-voting-interface)
  static const String secureVotingInterface =
      '$webAppBase/secure-voting-interface';

  /// Voting categories (Web: /voting-categories)
  static const String votingCategories = '$webAppBase/voting-categories';

  /// Blockchain audit portal (Web: /blockchain-audit-portal)
  static const String blockchainAuditPortal =
      '$webAppBase/blockchain-audit-portal';

  /// Enterprise SSO hub (Web: /enterprise-sso-integration-hub)
  static const String enterpriseSsoIntegrationHub =
      '$webAppBase/enterprise-sso-integration-hub';

  /// Enterprise operations hub (Web: /enterprise-operations-center)
  static const String enterpriseOperationsCenter =
      '$webAppBase/enterprise-operations-center';

  /// Enterprise analytics hub (Web: /enterprise-analytics-hub)
  static const String enterpriseAnalyticsHub =
      '$webAppBase/enterprise-analytics-hub';

  /// Enterprise API access center (Web: /enterprise-api-access-center)
  static const String enterpriseApiAccessCenter =
      '$webAppBase/enterprise-api-access-center';

  /// Enterprise compliance reports center (Web: /enterprise-compliance-reports-center)
  static const String enterpriseComplianceReportsCenter =
      '$webAppBase/enterprise-compliance-reports-center';

  /// Claude AI dispute moderation (Web: /claude-ai-dispute-moderation-center)
  static const String claudeAiDisputeModerationCenter =
      '$webAppBase/claude-ai-dispute-moderation-center';

  // —— Web admin parity (open in browser; same paths as React `Routes.jsx`) ——
  static const String unifiedAiDecisionOrchestrationCommandCenter =
      '$webAppBase/unified-ai-decision-orchestration-command-center';
  static const String unifiedAiOrchestrationCommandCenter =
      '$webAppBase/unified-ai-orchestration-command-center';
  static const String automaticAiFailoverEngineControlCenter =
      '$webAppBase/automatic-ai-failover-engine-control-center';
  static const String aiPerformanceOrchestrationDashboard =
      '$webAppBase/ai-performance-orchestration-dashboard';
  static const String claudeAiFeedIntelligenceCenter =
      '$webAppBase/claude-ai-feed-intelligence-center';
  static const String contextAwareClaudeRecommendationsOverlay =
      '$webAppBase/context-aware-claude-recommendations-overlay';
  static const String claudeAiContentCurationIntelligenceCenter =
      '$webAppBase/claude-ai-content-curation-intelligence-center';
  static const String claudeModelComparisonCenter =
      '$webAppBase/claude-model-comparison-center';
  static const String claudeContentOptimizationEngine =
      '$webAppBase/claude-content-optimization-engine';
  static const String claudeDecisionReasoningHub =
      '$webAppBase/claude-decision-reasoning-hub';
  static const String unifiedIncidentResponseOrchestrationCenter =
      '$webAppBase/unified-incident-response-orchestration-center';
  static const String queryPerformanceMonitoringDashboard =
      '$webAppBase/query-performance-monitoring-dashboard';
  static const String comprehensiveHealthMonitoringDashboard =
      '$webAppBase/comprehensive-health-monitoring-dashboard';
  static const String productionMonitoringDashboard =
      '$webAppBase/production-monitoring-dashboard';
  static const String mlModelTrainingInterface =
      '$webAppBase/ml-model-training-interface';
  static const String loadTestingPerformanceAnalyticsCenter =
      '$webAppBase/load-testing-performance-analytics-center';
  static const String performanceOptimizationEngineDashboard =
      '$webAppBase/performance-optimization-engine-dashboard';
  static const String advancedSupabaseRealtimeCoordinationHub =
      '$webAppBase/advanced-supabase-real-time-coordination-hub';
  static const String enhancedRealtimeWebSocketCoordinationHub =
      '$webAppBase/enhanced-real-time-web-socket-coordination-hub';
  static const String realtimeWebSocketMonitoringCommandCenter =
      '$webAppBase/real-time-web-socket-monitoring-command-center';
  static const String automatedDataCacheManagementHub =
      '$webAppBase/automated-data-cache-management-hub';
  static const String continuousMlFeedbackOutcomeLearningCenter =
      '$webAppBase/continuous-ml-feedback-outcome-learning-center';
  static const String autoImprovingFraudDetectionIntelligenceCenter =
      '$webAppBase/auto-improving-fraud-detection-intelligence-center';
  static const String fraudDetectionAlertManagementCenter =
      '$webAppBase/fraud-detection-alert-management-center';
  static const String advancedPerplexityFraudIntelligenceCenter =
      '$webAppBase/advanced-perplexity-fraud-intelligence-center';
  static const String advancedPerplexityFraudForecastingCenter =
      '$webAppBase/advanced-perplexity-fraud-forecasting-center';
  static const String advancedMlThreatDetectionCenter =
      '$webAppBase/advanced-ml-threat-detection-center';
  static const String zoneSpecificThreatHeatmapsDashboard =
      '$webAppBase/zone-specific-threat-heatmaps-dashboard';
  static const String predictiveAnomalyAlertingDeviationMonitoringHub =
      '$webAppBase/predictive-anomaly-alerting-deviation-monitoring-hub';
  static const String perplexityMarketResearchIntelligenceCenter =
      '$webAppBase/perplexity-market-research-intelligence-center';
  static const String perplexityStrategicPlanningCenter =
      '$webAppBase/perplexity-strategic-planning-center';
  static const String perplexityCarouselIntelligenceDashboard =
      '$webAppBase/perplexity-carousel-intelligence-dashboard';
  static const String predictionAnalyticsDashboard =
      '$webAppBase/prediction-analytics-dashboard';

  /// Unified admin activity log (Web: `/unified-admin-activity-log`)
  static const String unifiedAdminActivityLog =
      '$webAppBase/unified-admin-activity-log';

  /// Admin platform logs — Web: `/admin-platform-logs-center` (`AdminPlatformLogsCenter`)
  static const String adminPlatformLogsCenter =
      '$webAppBase/admin-platform-logs-center';
  static const String analyticsExportReportingHub =
      '$webAppBase/analytics-export-reporting-hub';
  static const String webhookIntegrationHub = '$webAppBase/webhook-integration-hub';
  static const String advancedWebhookOrchestrationHub =
      '$webAppBase/advanced-webhook-orchestration-hub';
  static const String executiveReportingComplianceAutomationHub =
      '$webAppBase/executive-reporting-compliance-automation-hub';
  static const String automatedExecutiveReportingClaudeIntelligenceHub =
      '$webAppBase/automated-executive-reporting-claude-intelligence-hub';
  static const String crossDomainDataSyncHub = '$webAppBase/cross-domain-data-sync-hub';

  /// Centralized support ticketing (Web: `/centralized-support-ticketing-system`)
  static const String centralizedSupportTicketingSystem =
      '$webAppBase/centralized-support-ticketing-system';

  /// Incident response analytics (Web: `/enhanced-incident-response-analytics`; legacy `/incident-response-analytics` redirects)
  static const String enhancedIncidentResponseAnalytics =
      '$webAppBase/enhanced-incident-response-analytics';

  /// Creator earnings / Stripe Connect (Web: `/enhanced-creator-payout-dashboard-with-stripe-connect-integration`)
  static const String enhancedCreatorPayoutDashboard =
      '$webAppBase/enhanced-creator-payout-dashboard-with-stripe-connect-integration';
}
