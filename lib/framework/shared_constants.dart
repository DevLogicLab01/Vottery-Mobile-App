/// SharedConstants - Single source of truth for all Web/Mobile shared constants.
/// Ensures 100% synchronization between Flutter Mobile and Web implementations.
class SharedConstants {
  SharedConstants._();

  // ─── Database Tables ───────────────────────────────────────────────────────
  static const String sponsoredElections = 'sponsored_elections';
  static const String platformGamificationCampaigns =
      'platform_gamification_campaigns';
  static const String userVpTransactions = 'user_vp_transactions';
  static const String featureRequests = 'feature_requests';
  static const String electionsTable = 'elections';
  static const String payoutSettings = 'payout_settings';
  static const String userSubscriptions = 'user_subscriptions';
  static const String userPaymentMethods = 'user_payment_methods';
  static const String adImpressions = 'ad_impressions';
  static const String adClicks = 'ad_clicks';
  static const String adFrequencyCaps = 'ad_frequency_caps';
  static const String cpePricingZones = 'cpe_pricing_zones';
  static const String userQuests = 'user_quests';
  static const String userAchievements = 'user_achievements';
  static const String userStreaks = 'user_streaks';
  static const String leaderboardPositions = 'leaderboard_positions';
  static const String performanceProfilingResults =
      'performance_profiling_results';
  static const String performanceOptimizationRecommendations =
      'performance_optimization_recommendations';
  static const String abTestExperiments = 'ab_test_experiments';
  static const String unifiedAlerts = 'unified_alerts';
  static const String systemAlerts = 'system_alerts';

  // ─── Ad / Organic ratio (sync with Web: AD_ORGANIC_RATIO.ORGANIC_ITEMS_PER_AD = 7) ───
  static const int organicItemsPerAd = 7;

  // ─── Route Paths (sync with Web: src/constants/SHARED_CONSTANTS.js ROUTE_PATHS) ───
  static const String contentModerationControlCenter =
      '/contentModerationControlCenter';
  static const String bulkManagementScreen = '/bulk-management-screen';
  static const String campaignManagementDashboard =
      '/campaign-management-dashboard';
  static const String participatoryAdsStudio = '/participatory-ads-studio';
  static const String communityEngagementDashboard =
      '/community-engagement-dashboard';
  static const String incidentResponseAnalytics =
      '/incident-response-analytics';
  static const String contentRemovedAppeal = '/contentRemovedAppeal';
  static const String userFeedbackPortal = '/userFeedbackPortal';
  static const String featureImplementationTracking =
      '/featureImplementationTracking';
  static const String subscriptionArchitecture = '/subscription-architecture';
  static const String unifiedPaymentOrchestration =
      '/unified-payment-orchestration-hub';
  static const String flutterMobileFrameworkHub =
      '/flutter-mobile-implementation-framework-hub';
  static const String unifiedProductionMonitoringHub =
      '/unified-production-monitoring-hub';
  static const String performanceOptimizationEngine =
      '/performance-optimization-recommendations-engine-dashboard';

  // ─── Ad Slot IDs ──────────────────────────────────────────────────────────
  static const String homeFeed1 = 'home_feed_1';
  static const String homeFeed2 = 'home_feed_2';
  static const String profileTop = 'profile_top';
  static const String electionDetailBottom = 'election_detail_bottom';

  // ─── Stripe Product IDs ───────────────────────────────────────────────────
  static const String stripeProductBasic = 'prod_basic_vp_2x';
  static const String stripeProductPro = 'prod_pro_vp_3x';
  static const String stripeProductElite = 'prod_elite_vp_5x';

  // ─── VP Multipliers ───────────────────────────────────────────────────────
  static const int vpMultiplierBasic = 2;
  static const int vpMultiplierPro = 3;
  static const int vpMultiplierElite = 5;

  // ─── Error Codes ──────────────────────────────────────────────────────────
  static const String paymentFailed = 'PAYMENT_FAILED';
  static const String subscriptionExpired = 'SUBSCRIPTION_EXPIRED';
  static const String insufficientVp = 'INSUFFICIENT_VP';
  static const String adSlotUnfilled = 'AD_SLOT_UNFILLED';
  static const String realtimeDisconnected = 'REALTIME_DISCONNECTED';

  // ─── Edge Function Names ──────────────────────────────────────────────────
  static const String stripeSecureProxy = 'stripe-secure-proxy';
  static const String sendComplianceReport = 'send-compliance-report';
  static const String predictionPoolWebhooks = 'prediction_pool_webhooks';
  static const String userActivityAnalyzer = 'user_activity_analyzer';

  /// Per-creator churn scoring refresh (Edge); max 1×/UTC day per user (server-enforced).
  /// Sync with Web: SHARED_CONSTANTS.js API_PATHS.CREATOR_CHURN_USER_REFRESH
  static const String creatorChurnUserRefresh = 'creator-churn-user-refresh';

  /// Geo snapshot after login (Edge). Sync with Web `API_PATHS.RECORD_LOGIN_GEO`.
  static const String recordLoginGeo = 'record-login-geo';

  /// Gemini recommendation worker / Shaped replacement (sync with Web geminiRecommendationService.js).
  static const int geminiRecommendationSyncIntervalSeconds = 60;
  static const double sponsoredElectionRankingWeightMultiplier = 2.0;
  static const int recommendationLatencyBudgetMs = 100;

  // ─── Election Column Names ────────────────────────────────────────────────
  static const String allowComments = 'allow_comments';
  static const String isGamified = 'is_gamified';
  static const String prizeConfig = 'prize_config';

  // ─── Auto-Refresh Intervals ───────────────────────────────────────────────
  static const Duration campaignRefreshInterval = Duration(seconds: 30);
  static const Duration metricsRefreshInterval = Duration(seconds: 60);
  static const Duration alertsRefreshInterval = Duration(seconds: 30);

  // ─── Purchasing Power Zones ───────────────────────────────────────────────
  static const List<String> purchasingPowerZones = [
    'zone_1',
    'zone_2',
    'zone_3',
    'zone_4',
    'zone_5',
    'zone_6',
    'zone_7',
    'zone_8',
  ];

  // ─── Subscription Tier Names ──────────────────────────────────────────────
  static const String tierBasic = 'Basic';
  static const String tierPro = 'Pro';
  static const String tierElite = 'Elite';

  // ─── Realtime Channel Prefixes ────────────────────────────────────────────
  static const String campaignsChannelPrefix = 'campaigns_';
  static const String gamificationChannelPrefix = 'gamification_';
  static const String alertsChannel = 'unified_alerts';

  // ─── Payment notification types (sync with Web: PAYMENT_NOTIFICATION_TYPES) ─
  static const String paymentNotificationSettlementProcessing =
      'settlement_processing';
  static const String paymentNotificationPayoutDelayed = 'payout_delayed';
  static const String paymentNotificationPaymentMethodFailed =
      'payment_method_failed';
  static const String paymentNotificationPayoutCompleted = 'payout_completed';
  static const List<String> paymentNotificationTypes = [
    paymentNotificationSettlementProcessing,
    paymentNotificationPayoutDelayed,
    paymentNotificationPaymentMethodFailed,
    paymentNotificationPayoutCompleted,
  ];

  // ─── Moderation audit (sync with Web: MODERATION_AUDIT in SHARED_CONSTANTS.js) ─
  static const String moderationOverrideAiPrefix = 'OVERRIDE_AI|';
  static const int moderationMinOverrideReasonLength = 12;
}
