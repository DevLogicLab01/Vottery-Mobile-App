class AppRoutes {
  // Core routes
  static const String splash = '/splash';
  static const String initial = splash;
  static const String socialMediaHomeFeed = '/socialMediaHomeFeed';
  static const String socialHomeFeed = '/socialHomeFeed';
  static const String voteDashboard = '/voteDashboard';
  /// Web parity: `/vote-in-elections-hub`
  static const String voteInElectionsHubWebCanonical = '/vote-in-elections-hub';
  static const String electionsDashboard = '/electionsDashboard';
  /// Web parity: `/elections-dashboard`
  static const String electionsDashboardWebCanonical = '/elections-dashboard';
  static const String voteDashboardInitialPage = '/voteDashboardInitialPage';
  static const String voteCasting = '/voteCasting';
  /// Web parity: `/secure-voting-interface`
  static const String secureVotingInterfaceWebCanonical =
      '/secure-voting-interface';
  static const String voteResults = '/voteResults';
  static const String voteHistory = '/voteHistory';
  static const String voteAnalytics = '/voteAnalytics';
  static const String voteDiscovery = '/voteDiscovery';
  /// Web parity: `/voting-categories`
  static const String votingCategoriesWebCanonical = '/voting-categories';
  static const String createVote = '/createVote';
  static const String electionCreationStudio = '/electionCreationStudio';
  /// Web parity: `/election-creation-studio`
  static const String electionCreationStudioWebCanonical =
      '/election-creation-studio';
  static const String userProfile = '/userProfile';
  /// Web parity: `/user-profile-hub`
  static const String userProfileWebCanonical = '/user-profile-hub';
  static const String adminDashboard = '/adminDashboard';
  static const String facebookStyleProfileMenu = '/facebookStyleProfileMenu';

  // Gamification
  static const String gamificationHub = '/gamificationHub';
  static const String unifiedGamificationDashboard =
      '/unifiedGamificationDashboard';
  /// Web parity: `/unified-gamification-dashboard`
  static const String unifiedGamificationDashboardWebCanonical =
      '/unified-gamification-dashboard';
  static const String questManagementDashboard = '/questManagementDashboard';
  /// Web parity: `/dynamic-quest-management-dashboard`
  static const String questManagementDashboardWebCanonical =
      '/dynamic-quest-management-dashboard';
  static const String seasonalChallengesHub = '/seasonalChallengesHub';
  /// Web parity: `/seasonal-challenges`
  static const String seasonalChallengesHubWebCanonical =
      '/seasonal-challenges';
  static const String aiQuestGeneration = '/aiQuestGeneration';
  static const String feedQuestDashboard = '/feedQuestDashboard';
  static const String adventurePaths = '/adventurePaths';
  static const String vpEconomyDashboard = '/vpEconomyDashboard';
  /// Web parity: `/vottery-points-vp-universal-currency-center`
  static const String vpUniversalCurrencyCenterWebCanonical =
      '/vottery-points-vp-universal-currency-center';
  static const String vpEconomyHealthMonitor = '/vpEconomyHealthMonitor';
  /// Web parity: `/vp-economy-health-monitor-dashboard` (same admin VP tooling as Web)
  static const String vpEconomyHealthMonitorWebCanonical =
      '/vp-economy-health-monitor-dashboard';
  static const String vpEconomyManagementDashboard =
      '/vpEconomyManagementDashboard';
  static const String completeGamifiedLotteryDrawingSystem =
      '/completeGamifiedLotteryDrawingSystem';
  static const String gamifiedPrizeConfigurationStudio =
      '/gamifiedPrizeConfigurationStudio';
  static const String winnerRevealCeremony = '/winnerRevealCeremony';
  static const String nftAchievementSystemHub = '/nftAchievementSystemHub';
  static const String rewardsShopHub = '/rewardsShopHub';
  static const String realTimeGamificationNotificationCenter =
      '/realTimeGamificationNotificationCenter';
  static const String realTimeGamificationNotificationsCenter =
      '/realTimeGamificationNotificationsCenter';
  static const String realTimeGamificationSyncOptimizationCenter =
      '/realTimeGamificationSyncOptimizationCenter';
  static const String gamificationE2eTestingSuiteDashboard =
      '/gamificationE2eTestingSuiteDashboard';
  static const String adminGamificationTogglePanel =
      '/adminGamificationTogglePanel';
  /// Web parity: `/comprehensive-gamification-admin-control-center`
  static const String comprehensiveGamificationAdminControlCenterWebCanonical =
      '/comprehensive-gamification-admin-control-center';

  // Wallet & Payments
  static const String digitalWalletScreen = '/digitalWalletScreen';
  /// Web parity: `/digital-wallet-hub`
  static const String digitalWalletScreenWebCanonical = '/digital-wallet-hub';
  static const String walletDashboard = '/walletDashboard';
  static const String walletPrizeDistributionCenter =
      '/walletPrizeDistributionCenter';
  /// Web parity: `/prize-distribution-tracking-center`
  static const String walletPrizeDistributionCenterWebCanonical =
      '/prize-distribution-tracking-center';
  static const String digitalWalletPrizeRedemptionSystem =
      '/digitalWalletPrizeRedemptionSystem';
  static const String vpCharityHub = '/vpCharityHub';
  /// Web parity: `/vp-redemption-marketplace-charity-hub`
  static const String vpRedemptionMarketplaceCharityHubWebCanonical =
      '/vp-redemption-marketplace-charity-hub';
  static const String unifiedPaymentOrchestrationHub =
      '/unifiedPaymentOrchestrationHub';
  /// Web parity: `/unified-payment-orchestration-hub`
  static const String unifiedPaymentOrchestrationHubWebCanonical =
      '/unified-payment-orchestration-hub';
  static const String automatedPaymentProcessingHub =
      '/automatedPaymentProcessingHub';
  static const String multiCurrencySettlementDashboard =
      '/multiCurrencySettlementDashboard';
  /// Web parity: `/multi-currency-settlement-dashboard`
  static const String multiCurrencySettlementDashboardWebCanonical =
      '/multi-currency-settlement-dashboard';
  static const String enhancedMultiCurrencySettlementDashboard =
      '/enhancedMultiCurrencySettlementDashboard';
  /// Web parity: `/enhanced-multi-currency-settlement-dashboard` (Web redirects to multi-currency hub)
  static const String enhancedMultiCurrencySettlementDashboardWebCanonical =
      '/enhanced-multi-currency-settlement-dashboard';
  static const String stripeConnectPayoutManagementHub =
      '/stripeConnectPayoutManagementHub';
  static const String settlementReconciliationHub =
      '/settlementReconciliationHub';
  static const String payoutHistoryScreen = '/payoutHistoryScreen';
  static const String payoutScheduleSettingsScreen =
      '/payoutScheduleSettingsScreen';
  static const String bankAccountLinkingScreen = '/bankAccountLinkingScreen';
  static const String enhancedBankAccountLinkingHub =
      '/enhancedBankAccountLinkingHub';
  static const String taxComplianceDashboard = '/taxComplianceDashboard';
  static const String participationFeePayment = '/participationFeePayment';
  static const String premiumSubscriptionCenter = '/premiumSubscriptionCenter';
  /// Web parity: `/enhanced-premium-subscription-center`
  static const String premiumSubscriptionCenterWebCanonical =
      '/enhanced-premium-subscription-center';
  /// Web parity: `/user-subscription-dashboard` (native: [PremiumSubscriptionCenter])
  static const String userSubscriptionDashboardWebCanonical =
      '/user-subscription-dashboard';
  static const String walletAuthenticationScreen =
      '/walletAuthenticationScreen';

  // Creator
  static const String creatorAnalyticsDashboard = '/creatorAnalyticsDashboard';
  static const String creatorMonetizationHub = '/creatorMonetizationHub';
  static const String creatorMonetizationStudio = '/creatorMonetizationStudio';
  static const String creatorPayoutDashboard = '/creatorPayoutDashboard';
  static const String creatorEarningsCommandCenter =
      '/creatorEarningsCommandCenter';
  static const String creatorMarketplace = '/creatorMarketplace';
  static const String creatorMarketplaceStore = '/creatorMarketplaceStore';
  static const String creatorBrandPartnershipHub =
      '/creatorBrandPartnershipHub';
  static const String creatorSuccessAcademy = '/creatorSuccessAcademy';
  static const String creatorStudioDashboard = '/creatorStudioDashboard';
  static const String creatorTierDashboardScreen =
      '/creatorTierDashboardScreen';
  static const String creatorVerificationKycScreen =
      '/creatorVerificationKycScreen';
  static const String creatorOnboardingWizard = '/creatorOnboardingWizard';
  static const String creatorSupportHub = '/creatorSupportHub';
  /// Tabs: Help Center, Support Inbox, Report Problem, Terms & Policies
  static const String helpSupportCenter = '/helpSupportCenter';
  /// Native support tickets + FAQ (Web path alias below)
  static const String supportTicketingSystem = '/supportTicketingSystem';
  /// Web parity: `/centralized-support-ticketing-system`
  static const String centralizedSupportTicketingSystemWebCanonical =
      '/centralized-support-ticketing-system';
  static const String creatorQaManagementCenter = '/creatorQaManagementCenter';
  static const String creatorFeedbackLoop = '/creatorFeedbackLoop';
  static const String creatorGrowthAnalyticsDashboard =
      '/creatorGrowthAnalyticsDashboard';
  static const String creatorChurnPredictionDashboard =
      '/creatorChurnPredictionDashboard';
  static const String creatorChurnAutoTriggerRetentionHub =
      '/creatorChurnAutoTriggerRetentionHub';
  static const String creatorRevenueTransparencyHub =
      '/creatorRevenueTransparencyHub';
  static const String creatorMonetizationAnalyticsDashboard =
      '/creatorMonetizationAnalyticsDashboard';
  static const String creatorOptimizationStudio = '/creatorOptimizationStudio';
  static const String creatorPredictiveInsightsHub =
      '/creatorPredictiveInsightsHub';
  static const String creatorRevenueForecastingDashboard =
      '/creatorRevenueForecastingDashboard';
  static const String mcqAnalyticsIntelligenceDashboard =
      '/mcqAnalyticsIntelligenceDashboard';
  static const String mcqAbTestingAnalyticsDashboard =
      '/mcqAbTestingAnalyticsDashboard';
  // Web-canonical path aliases for parity-safe deep links
  static const String mcqAbTestingAnalyticsDashboardWeb =
      '/mcq-a-b-testing-analytics-dashboard';
  static const String claudeCreatorSuccessAgent =
      '/claudeCreatorSuccessAgent';
  static const String claudeCreatorSuccessAgentWeb =
      '/claude-creator-success-agent';
  /// Web parity: `/creator-monetization-studio`
  static const String creatorMonetizationStudioWebCanonical =
      '/creator-monetization-studio';
  /// Web parity: `/creator-success-academy`
  static const String creatorSuccessAcademyWebCanonical =
      '/creator-success-academy';
  /// Web parity: `/creator-growth-analytics-dashboard`
  static const String creatorGrowthAnalyticsDashboardWebCanonical =
      '/creator-growth-analytics-dashboard';
  /// Web parity: `/creator-revenue-forecasting-dashboard`
  static const String creatorRevenueForecastingDashboardWebCanonical =
      '/creator-revenue-forecasting-dashboard';
  /// Web parity: `/advanced-search-discovery-intelligence-hub`
  static const String advancedUnifiedSearchScreenWebCanonical =
      '/advanced-search-discovery-intelligence-hub';
  /// Alias for Web path (same value as [advancedUnifiedSearchScreenWebCanonical]).
  static const String advancedSearchDiscoveryIntelligenceHubWebCanonical =
      advancedUnifiedSearchScreenWebCanonical;
  static const String contentQualityScoringClaude =
      '/contentQualityScoringClaude';
  static const String contentQualityScoringClaudeWeb =
      '/content-quality-scoring-claude';
  static const String creatorSettlementReconciliationCenter =
      '/creatorSettlementReconciliationCenter';
  static const String enhancedCreatorAnalyticsDashboard =
      '/enhancedCreatorAnalyticsDashboard';
  static const String enhancedCreatorEarningsDashboard =
      '/enhancedCreatorEarningsDashboard';
  static const String enhancedCreatorRevenueAnalytics =
      '/enhancedCreatorRevenueAnalytics';
  static const String advancedCreatorPayoutManagementHub =
      '/advancedCreatorPayoutManagementHub';
  static const String realTimeCreatorMetricsMonitor =
      '/realTimeCreatorMetricsMonitor';
  static const String realTimeCreatorEarningsWidget =
      '/realTimeCreatorEarningsWidget';

  // Advertising
  static const String campaignManagementDashboard =
      '/campaignManagementDashboard';
  /// Web parity: `/campaign-management-dashboard` (deep links / universal links)
  static const String campaignManagementDashboardWebCanonical =
      '/campaign-management-dashboard';
  /// Web parity: `/sponsored-elections-schema-cpe-management-hub` (same screen as campaign management)
  static const String sponsoredElectionsSchemaCpeManagementHubWebCanonical =
      '/sponsored-elections-schema-cpe-management-hub';
  static const String campaignOptimizationDashboard =
      '/campaignOptimizationDashboard';
  static const String campaignTemplateGallery = '/campaignTemplateGallery';
  /// Web parity: `/campaign-template-gallery`
  static const String campaignTemplateGalleryWebCanonical =
      '/campaign-template-gallery';
  static const String participatoryAdsStudio = '/participatoryAdsStudio';
  /// Web parity: `/participatory-ads-studio`
  static const String participatoryAdsStudioWebCanonical =
      '/participatory-ads-studio';
  /// Web parity: `/vottery-ads-studio` — same value as `VotteryAdsConstants.votteryAdsStudioWebRoute`.
  static const String votteryAdsStudioWebCanonical = '/vottery-ads-studio';
  /// Flutter `Navigator.pushNamed` path for [VotteryAdsStudio] (matches [VotteryAdsConstants.votteryAdsStudioRoute]).
  static const String votteryAdsStudio = '/votteryAdsStudio';
  static const String participatoryAdsGamificationCenter =
      '/participatoryAdsGamificationCenter';
  static const String advertiserAnalyticsDashboard =
      '/advertiserAnalyticsDashboard';
  /// Web parity: `/advertiser-analytics-roi-dashboard`
  static const String advertiserAnalyticsDashboardWebCanonical =
      '/advertiser-analytics-roi-dashboard';
  static const String advertiserPortalScreen = '/advertiserPortalScreen';
  static const String realTimeAdvertiserRoiDashboard =
      '/realTimeAdvertiserRoiDashboard';
  static const String brandAdvertiserRegistrationPortal =
      '/brandAdvertiserRegistrationPortal';
  /// Web parity: `/brand-advertiser-registration-portal`
  static const String brandAdvertiserRegistrationPortalWebCanonical =
      '/brand-advertiser-registration-portal';
  static const String brandPartnershipHub = '/brandPartnershipHub';
  static const String brandOnboardingWizard = '/brandOnboardingWizard';
  static const String dynamicCpePricingEngineDashboard =
      '/dynamicCpePricingEngineDashboard';
  /// Web parity: `/dynamic-cpe-pricing-engine-dashboard`
  static const String dynamicCpePricingEngineDashboardWebCanonical =
      '/dynamic-cpe-pricing-engine-dashboard';
  static const String googleAdSenseLiveIntegrationHub =
      '/googleAdSenseLiveIntegrationHub';
  static const String googleAdSenseMonetizationHub =
      '/googleAdSenseMonetizationHub';
  static const String realTimeBrandAlertSalesOutreachHub =
      '/realTimeBrandAlertSalesOutreachHub';
  /// Web parity: `/real-time-brand-alert-budget-monitoring-center`
  static const String realTimeBrandAlertBudgetMonitoringCenterWebCanonical =
      '/real-time-brand-alert-budget-monitoring-center';

  // Admin
  static const String adminFeatureTogglePanel = '/adminFeatureTogglePanel';
  static const String enhancedAdminFeatureTogglePanel =
      '/enhancedAdminFeatureTogglePanel';
  static const String adminRevenueSharingManagementPanel =
      '/adminRevenueSharingManagementPanel';
  static const String creatorRevenueShareScreen = '/creatorRevenueShareScreen';
  static const String adminCountryAccessControlPanel =
      '/adminCountryAccessControlPanel';
  /// Web parity: opens /country-restrictions-admin in browser
  static const String countryRestrictionsAdmin = '/country-restrictions-admin';
  /// Web parity: opens /platform-integrations-admin in browser
  static const String platformIntegrationsAdmin = '/platform-integrations-admin';
  /// Web parity: country revenue share management, regional analytics, dispute, multi-currency
  static const String countryRevenueShareAdmin = '/country-revenue-share-admin';
  static const String regionalRevenueAnalyticsAdmin = '/regional-revenue-analytics-admin';
  /// Web parity: `/country-revenue-share-management-center` (`COUNTRY_REVENUE_SHARE_MANAGEMENT_CENTER_ROUTE`)
  static const String countryRevenueShareManagementCenterWebCanonical =
      '/country-revenue-share-management-center';
  /// Web parity: `/regional-revenue-analytics-dashboard` (`REGIONAL_REVENUE_ANALYTICS_DASHBOARD_ROUTE`)
  static const String regionalRevenueAnalyticsDashboardWebCanonical =
      '/regional-revenue-analytics-dashboard';
  static const String claudeDisputeResolutionAdmin = '/claude-dispute-resolution-admin';
  static const String multiCurrencySettlementAdmin = '/multi-currency-settlement-admin';

  /// Web parity launchers (same paths as Vottery Web React routes)
  static const String adminSubscriptionAnalyticsAdmin =
      '/admin-subscription-analytics-web';
  /// Web parity: `/admin-subscription-analytics-hub`
  static const String adminSubscriptionAnalyticsHubWebCanonical =
      '/admin-subscription-analytics-hub';
  static const String stripeSubscriptionManagementAdmin =
      '/stripe-subscription-management-web';
  /// Web parity: `/stripe-subscription-management-center`
  static const String stripeSubscriptionManagementCenterWebCanonical =
      '/stripe-subscription-management-center';
  static const String stripePaymentIntegrationHubAdmin =
      '/stripe-payment-integration-hub-web';
  static const String automatedPayoutCalculationEngineAdmin =
      '/automated-payout-calculation-engine-web';
  static const String countryBasedPayoutProcessingEngineAdmin =
      '/country-based-payout-processing-engine-web';
  static const String comprehensiveGamificationAdminWeb =
      '/comprehensive-gamification-admin-web';
  static const String platformGamificationCoreEngineAdmin =
      '/platform-gamification-core-engine-web';
  static const String gamificationCampaignManagementAdmin =
      '/gamification-campaign-management-web';
  static const String gamificationRewardsManagementAdmin =
      '/gamification-rewards-management-web';
  static const String securityComplianceAutomationAdmin =
      '/security-compliance-automation-web';
  /// Web parity: `/security-compliance-automation-center`
  static const String securityComplianceAutomationCenterWebCanonical =
      '/security-compliance-automation-center';
  static const String localizationTaxReportingAdmin =
      '/localization-tax-reporting-web';
  static const String complianceDashboardWeb = '/compliance-dashboard-web';
  static const String complianceAuditDashboardWeb =
      '/compliance-audit-dashboard-web';
  static const String regulatoryComplianceAutomationWeb =
      '/regulatory-compliance-automation-web';
  static const String claudeAiDisputeModerationAdmin =
      '/claude-ai-dispute-moderation-web';

  /// Public transparency (opens Web vote verification / bulletin)
  static const String publicBulletinBoardWeb = '/public-bulletin-board-web';
  static const String voteVerificationPortalWeb =
      '/vote-verification-portal-web';
  static const String adminQuestConfigurationControlCenterWeb =
      '/admin-quest-configuration-control-center-web';
  /// Web parity: `/vote-verification-portal` (same URL as [AppUrls.voteVerificationPortal])
  static const String voteVerificationPortalWebCanonical =
      '/vote-verification-portal';
  static const String enhancedAdminControlPanel = '/enhancedAdminControlPanel';
  static const String enhancedMobileAdminDashboard =
      '/enhancedMobileAdminDashboard';
  static const String mobileOperationsCommandConsole =
      '/mobileOperationsCommandConsole';
  /// Web parity: `/mobile-operations-command-console`
  static const String mobileOperationsCommandConsoleWebCanonical =
      '/mobile-operations-command-console';
  static const String multiRoleAdminControlCenter =
      '/multiRoleAdminControlCenter';

  // Developer & API
  static const String apiDocumentationPortal = '/apiDocumentationPortal';
  /// Web parity: `/api-documentation-portal`
  static const String apiDocumentationPortalWebCanonical =
      '/api-documentation-portal';
  static const String apiRateLimitingDashboard = '/apiRateLimitingDashboard';
  /// Web parity: `/api-rate-limiting-dashboard`
  static const String apiRateLimitingDashboardWebCanonical =
      '/api-rate-limiting-dashboard';

  // Diagnostics
  static const String offlineSyncDiagnostics = '/offlineSyncDiagnostics';

  // Settings & Profile
  static const String comprehensiveSettingsHub = '/comprehensiveSettingsHub';
  static const String enhancedSettingsAccountDashboard =
      '/enhancedSettingsAccountDashboard';
  /// Web: `SETTINGS_ACCOUNT_DASHBOARD_ROUTE` in `navigationHubRoutes.js`
  static const String settingsAccountDashboardWebCanonical =
      '/settings-account-dashboard';
  static const String enhancedPrivacySettingsHub =
      '/enhancedPrivacySettingsHub';
  static const String enhancedProfilePrivacyControls =
      '/enhancedProfilePrivacyControls';
  static const String enhancedProfilePrivacyControlsCenter =
      '/enhancedProfilePrivacyControlsCenter';
  static const String accessibilitySettingsHub = '/accessibilitySettingsHub';
  static const String globalLanguageSettingsHub = '/globalLanguageSettingsHub';
  static const String familySharingManagementHub =
      '/familySharingManagementHub';

  // Auth & Security
  static const String userSecurityCenter = '/userSecurityCenter';
  /// Web parity: `/user-security-center`
  static const String userSecurityCenterWebCanonical = '/user-security-center';
  static const String passkeyAuthenticationCenter =
      '/passkeyAuthenticationCenter';
  static const String biometricAuthentication = '/biometricAuthentication';
  static const String otpEmailVerificationHub = '/otpEmailVerificationHub';
  static const String quickRegistrationScreen = '/quickRegistrationScreen';
  static const String comprehensiveOnboardingFlow =
      '/comprehensiveOnboardingFlow';
  static const String interactiveOnboardingTutorialSystem =
      '/interactiveOnboardingTutorialSystem';
  static const String interactiveOnboardingToursHub =
      '/interactiveOnboardingToursHub';
  static const String aiGuidedInteractiveTutorial =
      '/aiGuidedInteractiveTutorial';
  /// Web parity: `/ai-guided-interactive-tutorial-system`
  static const String aiGuidedInteractiveTutorialSystemWebCanonical =
      '/ai-guided-interactive-tutorial-system';
  /// Web parity: `/interactive-onboarding-wizard`
  static const String interactiveOnboardingWizardWebCanonical =
      '/interactive-onboarding-wizard';
  static const String topicPreferenceCollectionHub =
      '/topicPreferenceCollectionHub';
  /// Web parity: `/interactive-topic-preference-collection-hub`
  static const String topicPreferenceCollectionHubWebCanonical =
      '/interactive-topic-preference-collection-hub';
  static const String roleUpgrade = '/roleUpgrade';

  // Notifications
  static const String notificationCenterHub = '/notificationCenterHub';
  /// Web parity: `NOTIFICATION_CENTER_HUB_ROUTE` in `navigationHubRoutes.js`
  static const String notificationCenterHubWebCanonical =
      '/notification-center-hub';
  static const String aiNotificationCenter = '/aiNotificationCenter';
  static const String pushNotificationManagementCenter =
      '/pushNotificationManagementCenter';
  /// Web parity: `/smart-push-notifications-optimization-center`
  static const String pushNotificationManagementCenterWebCanonical =
      '/smart-push-notifications-optimization-center';
  static const String pushNotificationDashboard = '/pushNotificationDashboard';
  static const String pushNotificationIntelligenceHub =
      '/pushNotificationIntelligenceHub';
  static const String logNotificationCenter = '/logNotificationCenter';

  // Social
  static const String socialConnectionsManager = '/socialConnectionsManager';
  static const String friendRequestsHub = '/friendRequestsHub';
  static const String friendsManagementHub = '/friendsManagementHub';
  /// Web: `FRIENDS_MANAGEMENT_HUB_ROUTE` in `navigationHubRoutes.js`
  static const String friendsManagementHubWebCanonical =
      '/friends-management-hub';
  static const String socialActivityTimeline = '/socialActivityTimeline';
  /// Web parity: `/social-activity-timeline`
  static const String socialActivityTimelineWebCanonical =
      '/social-activity-timeline';
  static const String realTimeAnalyticsDashboard = '/realTimeAnalyticsDashboard';
  static const String realTimeAnalyticsDashboardWeb =
      '/real-time-analytics-dashboard';
  static const String livePlatformMonitoringDashboard =
      '/livePlatformMonitoringDashboard';
  static const String personalAnalyticsDashboard = '/personalAnalyticsDashboard';
  /// Web parity: `/personal-analytics-dashboard`
  static const String personalAnalyticsDashboardWebCanonical =
      '/personal-analytics-dashboard';
  static const String userAnalyticsDashboard = '/userAnalyticsDashboard';
  /// Web parity: `/user-analytics-dashboard`
  static const String userAnalyticsDashboardWeb = '/user-analytics-dashboard';
  static const String directMessagingScreen = '/directMessagingScreen';
  /// Web: `DIRECT_MESSAGING_CENTER_ROUTE` in `navigationHubRoutes.js`
  static const String directMessagingScreenWebCanonical =
      '/direct-messaging-center';
  static const String directMessagingSystem = '/directMessagingSystem';
  static const String enhancedDirectMessagingScreen =
      '/enhancedDirectMessagingScreen';
  static const String groupsHub = '/groupsHub';
  static const String enhancedGroupsHub = '/enhancedGroupsHub';
  /// Web: `ENHANCED_GROUPS_DISCOVERY_MANAGEMENT_HUB_ROUTE` in `navigationHubRoutes.js`
  static const String enhancedGroupsHubWebCanonical =
      '/enhanced-groups-discovery-management-hub';
  static const String momentsStoriesHub = '/momentsStoriesHub';
  static const String socialPostComposer = '/socialPostComposer';
  static const String enhancedPostsFeedsComposer =
      '/enhancedPostsFeedsComposer';
  static const String socialMediaNavigationHub = '/socialMediaNavigationHub';
  static const String joltsVideoFeed = '/joltsVideoFeed';
  static const String joltsVideoStudio = '/joltsVideoStudio';
  static const String joltsAnalyticsDashboard = '/joltsAnalyticsDashboard';
  static const String joltsCreatorGamificationHub =
      '/joltsCreatorGamificationHub';
  static const String enhancedSocialMediaHomeFeed =
      '/enhancedSocialMediaHomeFeed';
  /// Web parity: `/enhanced-home-feed-dashboard`
  static const String enhancedHomeFeedDashboardWebCanonical =
      '/enhanced-home-feed-dashboard';
  static const String communityElectionsHub = '/communityElectionsHub';
  /// Web parity: `/community-elections-hub`
  static const String communityElectionsHubWebCanonical =
      '/community-elections-hub';
  /// Web parity: `/topic-based-community-elections-hub`
  static const String topicBasedCommunityElectionsHubWebCanonical =
      '/topic-based-community-elections-hub';
  static const String communityEngagementDashboard =
      '/communityEngagementDashboard';
  /// Web parity: `/community-engagement-dashboard`
  static const String communityEngagementDashboardWebCanonical =
      '/community-engagement-dashboard';
  static const String voterEducationHub = '/voterEducationHub';
  /// Web parity: `/voter-education-hub`
  static const String voterEducationHubWebCanonical = '/voter-education-hub';
  static const String userFeedbackPortal = '/userFeedbackPortal';
  static const String featureImplementationTracking =
      '/featureImplementationTracking';
  static const String realTimeRevenueOptimization =
      '/realTimeRevenueOptimization';
  static const String analyticsExportReportingHub =
      '/analyticsExportReportingHub';
  /// Web parity: `/analytics-export-reporting-hub`
  static const String analyticsExportReportingHubWebCanonical =
      '/analytics-export-reporting-hub';
  static const String performanceTestingDashboard =
      '/performanceTestingDashboard';
  /// Web parity: `/real-time-performance-testing-suite`
  static const String performanceTestingDashboardWebCanonical =
      '/real-time-performance-testing-suite';

  // Voting & Elections
  static const String blockchainVoteVerificationHub =
      '/blockchainVoteVerificationHub';
  static const String enhancedBlockchainVoteVerificationHub =
      '/enhancedBlockchainVoteVerificationHub';
  static const String blockchainVoteReceiptCenter =
      '/blockchainVoteReceiptCenter';
  static const String blockchainGamificationLoggingHub =
      '/blockchainGamificationLoggingHub';
  static const String verifyAuditElectionsHub = '/verifyAuditElectionsHub';
  static const String electionIntegrityMonitoringHub =
      '/electionIntegrityMonitoringHub';
  static const String tieHandlingResolutionCenter =
      '/tieHandlingResolutionCenter';
  static const String abstentionsTrackingDashboard =
      '/abstentionsTrackingDashboard';
  static const String voteChangeManagementCenter =
      '/voteChangeManagementCenter';
  static const String anonymousVotingConfigurationHub =
      '/anonymousVotingConfigurationHub';
  static const String collaborativeVotingRoom = '/collaborativeVotingRoom';
  /// Web parity: `/collaborative-voting-room`
  static const String collaborativeVotingRoomWebCanonical =
      '/collaborative-voting-room';
  static const String locationVoting = '/locationVoting';
  /// Web parity: `/location-based-voting`
  static const String locationVotingWebCanonical = '/location-based-voting';
  static const String enhancedVoteCasting = '/enhancedVoteCasting';
  static const String enhancedVoteCastingWithPredictionIntegration =
      '/enhancedVoteCastingWithPredictionIntegration';
  /// Web parity: `/election-prediction-pools-interface`
  static const String electionPredictionPoolsInterfaceWebCanonical =
      '/election-prediction-pools-interface';
  static const String liveQuestionInjectionControlCenter =
      '/liveQuestionInjectionControlCenter';
  static const String advancedAiFraudPreventionCommandCenter =
      '/advanced-ai-fraud-prevention-command-center';
  static const String advancedPerplexityFraudIntelligenceCenter =
      '/advanced-perplexity-fraud-intelligence-center';
  static const String advancedPerplexityFraudForecastingCenter =
      '/advanced-perplexity-fraud-forecasting-center';
  static const String advancedPerplexity6090DayThreatForecastingCenter =
      '/advanced-perplexity-60-90-day-threat-forecasting-center';
  /// Web-canonical aliases (same screens as enhanced threat + auto-improving + Perplexity hubs)
  static const String advancedMlThreatDetectionCenterWebCanonical =
      '/advanced-ml-threat-detection-center';
  static const String continuousMlFeedbackOutcomeLearningCenterWebCanonical =
      '/continuous-ml-feedback-outcome-learning-center';
  static const String perplexityMarketResearchIntelligenceCenterWebCanonical =
      '/perplexity-market-research-intelligence-center';
  static const String perplexityStrategicPlanningCenterWebCanonical =
      '/perplexity-strategic-planning-center';
  static const String perplexityCarouselIntelligenceDashboardWebCanonical =
      '/perplexity-carousel-intelligence-dashboard';
  static const String anthropicClaudeRevenueRiskIntelligenceCenterWebCanonical =
      '/anthropic-claude-revenue-risk-intelligence-center';
  static const String claudeAnalyticsDashboardForCampaignIntelligenceWebCanonical =
      '/claude-analytics-dashboard-for-campaign-intelligence';
  static const String claudePredictiveAnalyticsDashboardWebCanonical =
      '/claude-predictive-analytics-dashboard';
  static const String claudeAiContentCurationIntelligenceCenterWebCanonical =
      '/claude-ai-content-curation-intelligence-center';
  static const String claudeModelComparisonCenterWebCanonical =
      '/claude-model-comparison-center';
  static const String claudeContentOptimizationEngineWebCanonical =
      '/claude-content-optimization-engine';
  static const String automaticAiFailoverEngineControlCenterWebCanonical =
      '/automatic-ai-failover-engine-control-center';
  static const String aiPerformanceOrchestrationDashboardWebCanonical =
      '/ai-performance-orchestration-dashboard';
  static const String aiPoweredPerformanceAdvisorHubWebCanonical =
      '/ai-powered-performance-advisor-hub';
  static const String openAiCarouselContentIntelligenceCenterWebCanonical =
      '/open-ai-carousel-content-intelligence-center';
  static const String autonomousClaudeAgentOrchestrationHubWebCanonical =
      '/autonomous-claude-agent-orchestration-hub';
  static const String enhancedRealTimeBehavioralHeatmapsCenterWebCanonical =
      '/enhanced-real-time-behavioral-heatmaps-center';
  static const String geminiCostEfficiencyAnalyzerCaseReportGeneratorWebCanonical =
      '/gemini-cost-efficiency-analyzer-case-report-generator';
  /// Web parity — deep-link to React admin (see `AppUrls`)
  static const String unifiedAiDecisionOrchestrationCommandCenterWebCanonical =
      '/unified-ai-decision-orchestration-command-center';
  static const String unifiedAiOrchestrationCommandCenterWebCanonical =
      '/unified-ai-orchestration-command-center';
  static const String queryPerformanceMonitoringDashboardWebCanonical =
      '/query-performance-monitoring-dashboard';
  static const String comprehensiveHealthMonitoringDashboardWebCanonical =
      '/comprehensive-health-monitoring-dashboard';
  static const String productionMonitoringDashboardWebCanonical =
      '/production-monitoring-dashboard';
  static const String mlModelTrainingInterfaceWebCanonical =
      '/ml-model-training-interface';
  static const String loadTestingPerformanceAnalyticsCenterWebCanonical =
      '/load-testing-performance-analytics-center';
  static const String performanceOptimizationEngineDashboardWebCanonical =
      '/performance-optimization-engine-dashboard';
  /// Web parity: `/performance-regression-detection` (same surface)
  static const String performanceRegressionDetectionWebCanonical =
      '/performance-regression-detection';
  static const String advancedSupabaseRealtimeCoordinationHubWebCanonical =
      '/advanced-supabase-real-time-coordination-hub';
  static const String enhancedRealtimeWebSocketCoordinationHubWebCanonical =
      '/enhanced-real-time-web-socket-coordination-hub';
  static const String realtimeWebSocketMonitoringCommandCenterWebCanonical =
      '/real-time-web-socket-monitoring-command-center';
  static const String automatedDataCacheManagementHubWebCanonical =
      '/automated-data-cache-management-hub';
  static const String autoImprovingFraudDetectionIntelligenceCenter =
      '/auto-improving-fraud-detection-intelligence-center';
  static const String realTimeThreatCorrelationIntelligenceHub =
      '/real-time-threat-correlation-intelligence-hub';
  static const String enhancedPredictiveThreatIntelligenceCenter =
      '/enhanced-predictive-threat-intelligence-center';
  static const String securityVulnerabilityRemediationControlCenter =
      '/security-vulnerability-remediation-control-center';
  static const String securityMonitoringDashboardWebCanonical =
      '/security-monitoring-dashboard';
  static const String automatedSecurityTestingFramework =
      '/automated-security-testing-framework';
  static const String cryptographicSecurityManagementCenter =
      '/cryptographic-security-management-center';
  static const String anthropicSecurityReasoningIntegrationHub =
      '/anthropic-security-reasoning-integration-hub';
  static const String enhancedAdminRevenueAnalyticsHub =
      '/enhanced-admin-revenue-analytics-hub';
  static const String unifiedBusinessIntelligenceHubWebCanonical =
      '/unified-business-intelligence-hub';
  static const String livePlatformMonitoringDashboardWebCanonical =
      '/live-platform-monitoring-dashboard';
  static const String advancedAnalyticsAndPredictiveForecastingCenter =
      '/advanced-analytics-and-predictive-forecasting-center';
  static const String financialTrackingZoneAnalyticsCenter =
      '/financial-tracking-zone-analytics-center';
  static const String enhancedMcqImageOptionsInterface =
      '/enhancedMcqImageOptionsInterface';
  static const String openEndedAnswerQuestionsBuilder =
      '/openEndedAnswerQuestionsBuilder';
  static const String audienceQuestionsHub = '/audienceQuestionsHub';
  static const String presentationSlidesViewer = '/presentationSlidesViewer';
  // Web-canonical parity aliases
  static const String presentationBuilderAudienceQaHub =
      '/presentation-builder-audience-q-a-hub';
  static const String ageVerificationDigitalIdentityCenter =
      '/age-verification-digital-identity-center';
  static const String socialProofIndicatorsDashboard =
      '/socialProofIndicatorsDashboard';
  static const String personalizationDashboard = '/personalizationDashboard';

  // Search
  static const String unifiedSearchSystemHub = '/unifiedSearchSystemHub';
  static const String advancedUnifiedSearchScreen =
      '/advancedUnifiedSearchScreen';

  // Moderation & Compliance
  static const String contentModerationTools = '/contentModerationTools';
  static const String contentModerationControlCenter =
      '/contentModerationControlCenter';
  /// Web parity: `/content-moderation-control-center`
  static const String contentModerationControlCenterWebCanonical =
      '/content-moderation-control-center';
  static const String bulkManagementScreen = '/bulk-management-screen';

  /// Enterprise hub (native); Web: `enterprise-operations-center` page when routed.
  static const String enterpriseOperationsCenter = '/enterprise-operations-center';
  /// Web parity: `/unified-admin-activity-log`
  static const String unifiedAdminActivityLogWebCanonical =
      '/unified-admin-activity-log';
  /// Web parity: `/admin-platform-logs-center`
  static const String adminPlatformLogsCenterWebCanonical =
      '/admin-platform-logs-center';
  /// Web parity: `/white-label-election-platform`
  static const String whiteLabelElectionPlatformWebCanonical =
      '/white-label-election-platform';
  /// Web parity: `/enterprise-sso-integration-hub`
  static const String enterpriseSsoIntegrationWebCanonical =
      '/enterprise-sso-integration-hub';
  /// Web parity: `/bulk-election-creation-hub`
  static const String bulkElectionCreationHubWebCanonical =
      '/bulk-election-creation-hub';
  /// Web parity: `/enterprise-analytics-hub`
  static const String enterpriseAnalyticsHubWebCanonical =
      '/enterprise-analytics-hub';
  /// Web parity: `/enterprise-api-access-center`
  static const String enterpriseApiAccessCenterWebCanonical =
      '/enterprise-api-access-center';
  /// Web parity: `/custom-branding-options-center`
  static const String customBrandingOptionsCenterWebCanonical =
      '/custom-branding-options-center';
  /// Web parity: `/sla-backed-infrastructure-center`
  static const String slaBackedInfrastructureCenterWebCanonical =
      '/sla-backed-infrastructure-center';
  /// Web parity: `/enterprise-compliance-reports-center`
  static const String enterpriseComplianceReportsCenterWebCanonical =
      '/enterprise-compliance-reports-center';
  /// Web parity: `/volume-pricing-licensing-center`
  static const String volumePricingLicensingCenterWebCanonical =
      '/volume-pricing-licensing-center';
  /// Web parity: `/dedicated-account-manager-center`
  static const String dedicatedAccountManagerCenterWebCanonical =
      '/dedicated-account-manager-center';
  /// Web parity: `/whatsapp-notifications-center`
  static const String whatsappNotificationsCenterWebCanonical =
      '/whatsapp-notifications-center';
  static const String aiContentModerationDashboard =
      '/aiContentModerationDashboard';
  static const String contentRemovedAppeal = '/contentRemovedAppeal';
  static const String ageVerificationControlCenter =
      '/ageVerificationControlCenter';
  static const String countryRestrictionControls =
      '/countryRestrictionControls';
  static const String countryBiometricComplianceDashboard =
      '/countryBiometricComplianceDashboard';
  static const String enhancedComplianceDashboard =
      '/enhancedComplianceDashboard';
  static const String enhancedComplianceReportsDashboard =
      '/enhancedComplianceReportsDashboard';
  static const String complianceReportsGeneratorDashboard =
      '/complianceReportsGeneratorDashboard';

  // Fraud & Security
  static const String fraudMonitoringDashboard = '/fraudMonitoringDashboard';
  /// Web parity: `/fraud-detection-alert-management-center`
  static const String fraudDetectionAlertManagementCenterWebCanonical =
      '/fraud-detection-alert-management-center';
  static const String advancedFraudDetectionCenter =
      '/advancedFraudDetectionCenter';
  static const String fraudAppealScreen = '/fraudAppealScreen';
  static const String perplexityFraudDashboardScreen =
      '/perplexityFraudDashboardScreen';
  static const String enhancedFraudInvestigationWorkflowsHub =
      '/enhancedFraudInvestigationWorkflowsHub';
  static const String enhancedPerplexityAiFraudForecastingHub =
      '/enhancedPerplexityAiFraudForecastingHub';
  static const String enhancedPerplexity90DayThreatForecastingHub =
      '/enhancedPerplexity90DayThreatForecastingHub';
  static const String coordinatedVotingDetectionScreen =
      '/coordinatedVotingDetectionScreen';
  static const String behavioralBiometricFraudPreventionCenter =
      '/behavioralBiometricFraudPreventionCenter';
  static const String revenueFraudDetectionEngine =
      '/revenueFraudDetectionEngine';
  static const String aiAnomalyDetectionFraudPreventionHub =
      '/aiAnomalyDetectionFraudPreventionHub';
  /// Web parity: `/predictive-anomaly-alerting-deviation-monitoring-hub`
  static const String predictiveAnomalyAlertingDeviationMonitoringHubWebCanonical =
      '/predictive-anomaly-alerting-deviation-monitoring-hub';
  static const String advancedThreatPredictionDashboard =
      '/advancedThreatPredictionDashboard';
  static const String zoneSpecificThreatHeatmapsDashboard =
      '/zoneSpecificThreatHeatmapsDashboard';
  static const String realTimeThreatCorrelationDashboard =
      '/realTimeThreatCorrelationDashboard';
  static const String automatedThreatResponseExecution =
      '/automatedThreatResponseExecution';
  static const String multiAiThreatOrchestrationHub =
      '/multi-ai-threat-orchestration-hub';
  static const String predictiveIncidentPreventionEngine =
      '/predictiveIncidentPreventionEngine';
  /// Web parity: `/predictive-incident-prevention-24h`
  static const String predictiveIncidentPreventionEngineWebCanonical =
      '/predictive-incident-prevention-24h';
  static const String automatedIncidentPreventionHub =
      '/automatedIncidentPreventionHub';
  static const String automatedIncidentResponseCenter =
      '/automatedIncidentResponseCenter';
  /// Web parity: `/automated-incident-response-portal`
  static const String automatedIncidentResponsePortalWebCanonical =
      '/automated-incident-response-portal';
  static const String unifiedIncidentOrchestrationCenter =
      '/unifiedIncidentOrchestrationCenter';
  /// Web parity: `/unified-incident-response-orchestration-center`
  static const String unifiedIncidentResponseOrchestrationCenterWebCanonical =
      '/unified-incident-response-orchestration-center';
  static const String unifiedIncidentManagementDashboard =
      '/unifiedIncidentManagementDashboard';
  /// Web parity: `/unified-incident-response-command-center`
  static const String unifiedIncidentResponseCommandCenterWebCanonical =
      '/unified-incident-response-command-center';
  /// Web parity: `/stakeholder-incident-communication-hub`
  static const String stakeholderIncidentCommunicationHubWebCanonical =
      '/stakeholder-incident-communication-hub';
  static const String teamIncidentWarRoom = '/team-incident-war-room';
  static const String incidentTestingSuiteDashboard =
      '/incidentTestingSuiteDashboard';
  static const String enhancedIncidentCorrelationEngine =
      '/enhancedIncidentCorrelationEngine';
  /// Web parity: `/enhanced-incident-response-analytics` (legacy `/incident-response-analytics` redirects on Web)
  static const String incidentResponseAnalytics =
      '/enhanced-incident-response-analytics';
  static const String enhancedIncidentResponseAnalyticsWebCanonical =
      incidentResponseAnalytics;
  /// Web parity: `/advanced-monitoring-hub-with-automated-incident-response`
  static const String advancedMonitoringWithAutomatedIncidentResponseWebCanonical =
      '/advanced-monitoring-hub-with-automated-incident-response';
  static const String subscriptionArchitecture = '/subscription-architecture';
  static const String securityMonitoringDashboard =
      '/securityMonitoringDashboard';
  static const String aiSecurityDashboard = '/aiSecurityDashboard';
  static const String owaspSecurityTestingDashboard =
      '/owaspSecurityTestingDashboard';
  static const String productionSecurityHardeningSprintDashboard =
      '/productionSecurityHardeningSprintDashboard';
  static const String securityFeatureAdoptionAnalytics =
      '/securityFeatureAdoptionAnalytics';
  static const String comprehensiveAuditLogScreen =
      '/comprehensiveAuditLogScreen';
  static const String comprehensiveAuditLogViewer =
      '/comprehensiveAuditLogViewer';
  static const String userActivityLogViewer = '/userActivityLogViewer';

  // Monitoring & Performance
  static const String realTimeSystemMonitoringDashboard =
      '/realTimeSystemMonitoringDashboard';
  static const String datadogApmMonitoringDashboard =
      '/datadogApmMonitoringDashboard';
  static const String datadogApmDistributedTracingHub =
      '/datadogApmDistributedTracingHub';
  static const String datadogApmPerformanceMonitoringHub =
      '/datadogApmPerformanceMonitoringHub';
  static const String realTimePerformanceMonitoringWithDatadogApmDashboard =
      '/realTimePerformanceMonitoringWithDatadogApmDashboard';
  static const String sentryErrorTrackingDashboard =
      '/sentryErrorTrackingDashboard';
  static const String sentryErrorTrackingIntegrationHub =
      '/sentryErrorTrackingIntegrationHub';
  static const String sentrySlackAlertPipelineDashboard =
      '/sentrySlackAlertPipelineDashboard';
  static const String enhancedSentryAutomatedAlertingHub =
      '/enhancedSentryAutomatedAlertingHub';
  static const String slackIncidentNotificationsDashboard =
      '/slackIncidentNotificationsDashboard';
  static const String redisCacheMonitoringDashboard =
      '/redisCacheMonitoringDashboard';
  static const String advancedRedisCachingManagementHub =
      '/advancedRedisCachingManagementHub';
  static const String supabaseQueryResultCachingManagementHub =
      '/supabaseQueryResultCachingManagementHub';
  static const String aiCacheManagementDashboard =
      '/aiCacheManagementDashboard';
  static const String mobileAppPerformanceOptimizationHub =
      '/mobileAppPerformanceOptimizationHub';
  static const String mobilePerformanceOptimizationDashboard =
      '/mobilePerformanceOptimizationDashboard';
  static const String mobilePerformanceOptimizationHub =
      '/mobilePerformanceOptimizationHub';
  static const String advancedPerformanceProfilingDashboard =
      '/advancedPerformanceProfilingDashboard';
  static const String flutterClientSidePerformanceProfilingDashboard =
      '/flutterClientSidePerformanceProfilingDashboard';
  static const String performanceMonitoringDashboard =
      '/performanceMonitoringDashboard';
  static const String performanceTestDashboard = '/performanceTestDashboard';
  static const String appPerformanceDashboard = '/appPerformanceDashboard';
  static const String productionPerformanceMonitoringDashboard =
      '/productionPerformanceMonitoringDashboard';
  static const String productionSlaMonitoringDashboard =
      '/productionSlaMonitoringDashboard';
  static const String productionLoadTestingSuiteDashboard =
      '/productionLoadTestingSuiteDashboard';
  static const String productionLoadTestAutoResponseHub =
      '/productionLoadTestAutoResponseHub';
  static const String productionDeploymentHub = '/productionDeploymentHub';
  static const String gitHubActionsCiCdPipelineDashboard =
      '/gitHubActionsCiCdPipelineDashboard';
  static const String automatedTestingPerformanceDashboard =
      '/automatedTestingPerformanceDashboard';
  static const String automatedTestingSuiteRunner =
      '/automatedTestingSuiteRunner';
  static const String e2eTestingCoverageDashboard =
      '/e2eTestingCoverageDashboard';
  static const String mobileLaunchReadinessChecklist =
      '/mobileLaunchReadinessChecklist';
  static const String apiGatewayOptimizationDashboard =
      '/apiGatewayOptimizationDashboard';
  static const String apiPerformanceOptimizationDashboard =
      '/apiPerformanceOptimizationDashboard';
  static const String resTfulApiManagementHub = '/resTfulApiManagementHub';
  /// Web parity: `/res-tful-api-management-center`
  static const String resTfulApiManagementHubWebCanonical =
      '/res-tful-api-management-center';
  static const String webhookIntegrationManagementHub =
      '/webhookIntegrationManagementHub';
  /// Web parity: `/webhook-integration-hub`
  static const String webhookIntegrationHubWebCanonical =
      '/webhook-integration-hub';
  /// Web parity: `/advanced-webhook-orchestration-hub`
  static const String advancedWebhookOrchestrationHubWebCanonical =
      '/advanced-webhook-orchestration-hub';
  /// Web parity: `/sms-webhook-delivery-analytics-hub`
  static const String smsWebhookDeliveryAnalyticsHubWebCanonical =
      '/sms-webhook-delivery-analytics-hub';
  /// Web parity: `/custom-alert-rules-engine`
  static const String customAlertRulesEngineWebCanonical =
      '/custom-alert-rules-engine';
  /// Web parity: `/advanced-custom-alert-rules-engine`
  static const String advancedCustomAlertRulesEngineWebCanonical =
      '/advanced-custom-alert-rules-engine';
  /// Web parity: `/unified-alert-management-center`
  static const String unifiedAlertManagementCenterWebCanonical =
      '/unified-alert-management-center';
  static const String codeSplittingPerformanceOptimizationHub =
      '/codeSplittingPerformanceOptimizationHub';
  static const String hiveOfflineStorageManagementHub =
      '/hiveOfflineStorageManagementHub';
  static const String enhancedHiveOfflineFirstArchitectureHub =
      '/enhancedHiveOfflineFirstArchitectureHub';
  static const String enhancedMobileOfflineSyncHub =
      '/enhancedMobileOfflineSyncHub';
  static const String crossDomainDataSyncHub = '/crossDomainDataSyncHub';
  static const String pwaOfflineVotingHub = '/pwaOfflineVotingHub';
  static const String statusPageScreen = '/statusPageScreen';
  /// Web parity: `/public-status-page`
  static const String statusPageScreenWebCanonical = '/public-status-page';
  /// Web parity: `/status` (same feature gate + screen as [statusPageScreenWebCanonical])
  static const String statusRouteWebCanonical = '/status';
  static const String automatedThresholdBasedAlertingHub =
      '/automatedThresholdBasedAlertingHub';
  static const String unifiedAlertManagementCenter =
      '/unifiedAlertManagementCenter';
  static const String realTimeAlertDashboard = '/realTimeAlertDashboard';
  static const String realTimeEngagementDashboard =
      '/realTimeEngagementDashboard';
  static const String realTimeDashboardRefreshControlCenter =
      '/realTimeDashboardRefreshControlCenter';
  static const String mobileLoggingDashboard = '/mobileLoggingDashboard';
  static const String logRocketSessionReplayMonitoringCenter =
      '/logRocketSessionReplayMonitoringCenter';

  // AI
  static const String aiFailoverDashboardScreen = '/aiFailoverDashboardScreen';
  static const String aiServiceFailoverControlCenter =
      '/aiServiceFailoverControlCenter';
  static const String automaticAiFailoverEngineControlCenter =
      '/automaticAiFailoverEngineControlCenter';
  static const String aiVoiceInteractionHub = '/aiVoiceInteractionHub';
  static const String multiLanguageAiTranslationHub =
      '/multiLanguageAiTranslationHub';
  static const String claudeModelComparisonCenter =
      '/claudeModelComparisonCenter';
  static const String claudeRevenueOptimizationCoach =
      '/claudeRevenueOptimizationCoach';
  static const String claudeContextualInsightsOverlaySystem =
      '/claudeContextualInsightsOverlaySystem';
  static const String claudeAutonomousActionsHub =
      '/claudeAutonomousActionsHub';
  static const String realTimeClaudeCoachingApiHub =
      '/realTimeClaudeCoachingApiHub';
  static const String geminiCostEfficiencyAnalyzer =
      '/geminiCostEfficiencyAnalyzer';
  static const String anthropicContentIntelligenceHub =
      '/anthropicContentIntelligenceHub';
  static const String anthropicAdvancedContentAnalysisCenter =
      '/anthropicAdvancedContentAnalysisCenter';
  static const String aiRecommendationsCenter = '/aiRecommendationsCenter';
  static const String aiPoweredPredictiveAnalyticsEngine =
      '/aiPoweredPredictiveAnalyticsEngine';
  /// Web parity: `/ai-powered-predictive-analytics-engine`
  static const String aiPoweredPredictiveAnalyticsEngineWebCanonical =
      '/ai-powered-predictive-analytics-engine';
  static const String aiPredictiveModelingScreen =
      '/aiPredictiveModelingScreen';
  static const String aiVoterSentimentDashboard = '/aiVoterSentimentDashboard';
  static const String aiAnalyticsHub = '/aiAnalyticsHub';
  static const String unifiedAiPerformanceDashboard =
      '/unifiedAiPerformanceDashboard';
  /// Web parity: `/unified-ai-performance-dashboard`
  static const String unifiedAiPerformanceDashboardWebCanonical =
      '/unified-ai-performance-dashboard';
  static const String contextAwareRecommendationsOverlay =
      '/contextAwareRecommendationsOverlay';
  // Gemini Recommendation & Sync (replaces Shaped AI); Web path: /shaped-ai-sync-docker-automation-hub
  static const String geminiRecommendationSyncHub =
      '/geminiRecommendationSyncHub';

  // Analytics
  static const String unifiedAnalyticsDashboard = '/unifiedAnalyticsDashboard';
  static const String unifiedBusinessIntelligenceHub =
      '/unifiedBusinessIntelligenceHub';
  static const String executiveBusinessIntelligenceSuite =
      '/executiveBusinessIntelligenceSuite';
  /// Web parity: `/executive-reporting-compliance-automation-hub`
  static const String executiveReportingComplianceAutomationHubWebCanonical =
      '/executive-reporting-compliance-automation-hub';
  /// Web parity: `/automated-executive-reporting-claude-intelligence-hub`
  static const String automatedExecutiveReportingClaudeIntelligenceHubWebCanonical =
      '/automated-executive-reporting-claude-intelligence-hub';
  static const String revenueAnalytics = '/revenueAnalytics';
  static const String revenueSplitAnalyticsDashboard =
      '/revenueSplitAnalyticsDashboard';
  static const String revenueSplitAdminControlCenter =
      '/revenueSplitAdminControlCenter';
  static const String unifiedRevenueIntelligenceDashboard =
      '/unifiedRevenueIntelligenceDashboard';
  /// Web parity: `/unified-revenue-intelligence-dashboard` (`UNIFIED_REVENUE_INTELLIGENCE_DASHBOARD_ROUTE`)
  static const String unifiedRevenueIntelligenceDashboardWebCanonical =
      '/unified-revenue-intelligence-dashboard';
  static const String googleAnalyticsIntegrationDashboard =
      '/googleAnalyticsIntegrationDashboard';
  static const String advancedGoogleAnalyticsTrackingHub =
      '/advancedGoogleAnalyticsTrackingHub';
  static const String ga4EnhancedAnalyticsDashboard =
      '/ga4EnhancedAnalyticsDashboard';
  static const String googleAnalyticsGamificationTrackingHub =
      '/googleAnalyticsGamificationTrackingHub';
  static const String googleAnalyticsMonetizationTrackingHub =
      '/googleAnalyticsMonetizationTrackingHub';
  static const String googleAnalyticsAiFeatureAdoptionDashboard =
      '/googleAnalyticsAiFeatureAdoptionDashboard';
  static const String mlModelMonitoringDashboard =
      '/mlModelMonitoringDashboard';
  static const String enhancedAnalyticsWithCdnIntegrationHub =
      '/enhancedAnalyticsWithCdnIntegrationHub';
  static const String advancedBehavioralHeatmapsMlAnalyticsHub =
      '/advancedBehavioralHeatmapsMlAnalyticsHub';
  static const String collaborativeAnalyticsWorkspace =
      '/collaborativeAnalyticsWorkspace';
  static const String feedRankingAnalyticsDashboard =
      '/feedRankingAnalyticsDashboard';
  static const String enhancedFeedRankingWithClaudeIntegrationHub =
      '/enhancedFeedRankingWithClaudeIntegrationHub';
  static const String feedOrchestrationEngineControlCenter =
      '/feedOrchestrationEngineControlCenter';
  static const String contentDistributionControlCenter =
      '/contentDistributionControlCenter';
  static const String participationFeeControls = '/participationFeeControls';
  static const String unifiedCrossDomainRecommendationEngineHub =
      '/unifiedCrossDomainRecommendationEngineHub';
  static const String crossDomainIntelligenceHub =
      '/crossDomainIntelligenceHub';
  static const String predictionAnalyticsDashboard =
      '/predictionAnalyticsDashboard';
  /// Web parity: `/prediction-analytics-dashboard`
  static const String predictionAnalyticsDashboardWebCanonical =
      '/prediction-analytics-dashboard';
  static const String predictionPoolNotificationsHub =
      '/predictionPoolNotificationsHub';
  /// Web parity: `/prediction-pool-notifications-hub`
  static const String predictionPoolNotificationsHubWebCanonical =
      '/prediction-pool-notifications-hub';
  static const String dedicatedMarketResearchDashboard =
      '/dedicatedMarketResearchDashboard';
  /// Web parity: `/dedicated-market-research-dashboard`
  static const String dedicatedMarketResearchDashboardWebCanonical =
      '/dedicated-market-research-dashboard';
  static const String mobileElectionInsightsAnalytics =
      '/mobileElectionInsightsAnalytics';
  /// Web parity: `/election-insights-predictive-analytics`
  static const String electionInsightsPredictiveWebCanonical =
      '/election-insights-predictive-analytics';
  static const String engagementMetricsDashboard =
      '/engagementMetricsDashboard';
  static const String featurePerformanceDashboard =
      '/featurePerformanceDashboard';
  static const String featureFlagManagementDashboard =
      '/featureFlagManagementDashboard';
  static const String analyticsPerformanceControlCenter =
      '/analyticsPerformanceControlCenter';
  static const String advancedABTestingCenter = '/advancedABTestingCenter';
  static const String carouselAnalyticsDashboard =
      '/carouselAnalyticsDashboard';
  static const String carouselAnalyticsIntelligenceCenter =
      '/carouselAnalyticsIntelligenceCenter';
  static const String carouselPerformanceAnalyticsDashboard =
      '/carouselPerformanceAnalyticsDashboard';
  static const String carouselPerformanceMonitorDashboard =
      '/carouselPerformanceMonitorDashboard';
  static const String carouselHealthAlertingDashboard =
      '/carouselHealthAlertingDashboard';
  static const String carouselHealthScalingDashboard =
      '/carouselHealthScalingDashboard';
  static const String carouselRoiAnalyticsDashboard =
      '/carouselRoiAnalyticsDashboard';
  static const String carouselSecurityAuditDashboard =
      '/carouselSecurityAuditDashboard';
  static const String carouselTemplateMarketplace =
      '/carouselTemplateMarketplace';
  static const String carouselCreatorTiersManagementHub =
      '/carouselCreatorTiersManagementHub';
  static const String carouselContentDiscoveryFilterCenter =
      '/carouselContentDiscoveryFilterCenter';
  static const String carouselPersonalizationEngineDashboard =
      '/carouselPersonalizationEngineDashboard';
  static const String carouselABTestingFrameworkDashboard =
      '/carouselABTestingFrameworkDashboard';
  static const String carouselRealTimeBiddingSystemHub =
      '/carouselRealTimeBiddingSystemHub';
  static const String carouselContentModerationAutomationCenter =
      '/carouselContentModerationAutomationCenter';
  static const String carouselMobileOptimizationSuiteDashboard =
      '/carouselMobileOptimizationSuiteDashboard';
  static const String carouselClaudeObservabilityHub =
      '/carouselClaudeObservabilityHub';
  static const String unifiedCarouselObservabilityHub =
      '/unifiedCarouselObservabilityHub';
  static const String unifiedCarouselOperationsCommandCenter =
      '/unifiedCarouselOperationsCommandCenter';
  static const String advancedCarouselFilterControlCenter =
      '/advancedCarouselFilterControlCenter';
  static const String smsProviderDashboard = '/smsProviderDashboard';
  static const String smsFailoverConfigurationCenter =
      '/smsFailoverConfigurationCenter';
  static const String smsRateLimitingQueueControlCenter =
      '/smsRateLimitingQueueControlCenter';
  static const String smsQueueManagementDashboard =
      '/smsQueueManagementDashboard';
  static const String smsDeliveryAnalyticsDashboard =
      '/smsDeliveryAnalyticsDashboard';
  static const String smsComplianceManagerDashboard =
      '/smsComplianceManagerDashboard';
  static const String smsWebhookManagementDashboard =
      '/smsWebhookManagementDashboard';
  static const String smsAlertTemplateManagementCenter =
      '/smsAlertTemplateManagementCenter';
  static const String smsEmergencyAlertsHub = '/smsEmergencyAlertsHub';
  /// Web parity: `/sms-emergency-alerts-hub`
  static const String smsEmergencyAlertsHubWebCanonical =
      '/sms-emergency-alerts-hub';
  static const String twilioSmsEmergencyAlertManagementCenter =
      '/twilioSmsEmergencyAlertManagementCenter';
  static const String twilioVideoLiveStreamingHub =
      '/twilioVideoLiveStreamingHub';
  static const String telnyxSmsProviderManagementDashboard =
      '/telnyxSmsProviderManagementDashboard';
  /// Web parity: `/telnyx-sms-provider-management-center`
  static const String telnyxSmsProviderManagementCenterWebCanonical =
      '/telnyx-sms-provider-management-center';
  static const String openAiSmsOptimizationHub = '/openAiSmsOptimizationHub';

  // Monitoring Hub
  static const String unifiedProductionMonitoringHub =
      '/unified-production-monitoring-hub';
  static const String performanceOptimizationRecommendationsEngineDashboard =
      '/performance-optimization-recommendations-engine-dashboard';
  static const String flutterMobileImplementationFrameworkHub =
      '/flutter-mobile-implementation-framework-hub';
  static const String realtimeGamificationErrorRecoveryHub =
      '/realtime-gamification-error-recovery-hub';
  static const String automatedDatadogResponseCommandCenter =
      '/automated-datadog-response-command-center';
  static const String predictivePerformanceTuningDashboard =
      '/predictive-performance-tuning';
  static const String costAnalyticsRoiDashboard =
      '/cost-analytics-roi-dashboard';

  // AI Decision & Automation
  static const String claudeDecisionReasoningHub =
      '/claude-decision-reasoning-hub';
  static const String adminAutomationControlPanel =
      '/admin-automation-control-panel';
  static const String multiRegionFailoverDashboard =
      '/multi-region-failover-dashboard';
  static const String securityComplianceAudit =
      '/security-compliance-audit';
  /// Web parity: `/security-compliance-audit-screen`
  static const String securityComplianceAuditWebCanonical =
      '/security-compliance-audit-screen';
  static const String securityAuditDashboard = '/security-audit-dashboard';
  static const String creatorCommunityHub = '/creator-community-hub';
  static const String incidentDetail = '/incident-detail';

  // Audit & Live Streaming
  static const String blockchainAuditPortal = '/blockchain-audit-portal';
  static const String liveStreamingCenter = '/live-streaming-center';
}
