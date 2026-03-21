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

  /// Automated payout calculation engine (Web: /automated-payout-calculation-engine)
  static const String automatedPayoutCalculationEngine =
      '$webAppBase/automated-payout-calculation-engine';

  /// Country-based payout processing engine (Web: /country-based-payout-processing-engine)
  static const String countryBasedPayoutProcessingEngine =
      '$webAppBase/country-based-payout-processing-engine';

  /// Comprehensive gamification admin (Web: /comprehensive-gamification-admin-control-center)
  static const String comprehensiveGamificationAdminControlCenter =
      '$webAppBase/comprehensive-gamification-admin-control-center';

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

  /// Vote verification portal (Web: /vote-verification-portal)
  static const String voteVerificationPortal =
      '$webAppBase/vote-verification-portal';

  /// Claude AI dispute moderation (Web: /claude-ai-dispute-moderation-center)
  static const String claudeAiDisputeModerationCenter =
      '$webAppBase/claude-ai-dispute-moderation-center';

  // —— Web admin parity (open in browser; same paths as React `Routes.jsx`) ——
  static const String unifiedAiDecisionOrchestrationCommandCenter =
      '$webAppBase/unified-ai-decision-orchestration-command-center';
  static const String unifiedAiOrchestrationCommandCenter =
      '$webAppBase/unified-ai-orchestration-command-center';
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
}
