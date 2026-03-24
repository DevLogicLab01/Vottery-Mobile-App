import '../routes/app_routes.dart';

class Batch1RouteAllowlist {
  Batch1RouteAllowlist._();
  static const bool _fullFeatureCertificationMode = bool.fromEnvironment(
    'FULL_FEATURE_CERTIFICATION',
    defaultValue: false,
  );

  static final Set<String> _allowed = {
    AppRoutes.initial,
    AppRoutes.splash,
    AppRoutes.socialMediaHomeFeed,
    AppRoutes.socialHomeFeed,
    AppRoutes.voteDashboard,
    AppRoutes.voteInElectionsHubWebCanonical,
    AppRoutes.electionsDashboard,
    AppRoutes.electionsDashboardWebCanonical,
    AppRoutes.secureVotingInterfaceWebCanonical,
    AppRoutes.voteDiscovery,
    AppRoutes.votingCategoriesWebCanonical,
    AppRoutes.electionCreationStudio,
    AppRoutes.electionCreationStudioWebCanonical,
    AppRoutes.userProfile,
    AppRoutes.userProfileWebCanonical,
    AppRoutes.enhancedSettingsAccountDashboard,
    AppRoutes.settingsAccountDashboardWebCanonical,
    AppRoutes.digitalWalletScreen,
    AppRoutes.digitalWalletScreenWebCanonical,
    AppRoutes.vpEconomyDashboard,
    AppRoutes.vpUniversalCurrencyCenterWebCanonical,
    AppRoutes.vpCharityHub,
    AppRoutes.vpRedemptionMarketplaceCharityHubWebCanonical,
    AppRoutes.unifiedPaymentOrchestrationHub,
    AppRoutes.unifiedPaymentOrchestrationHubWebCanonical,
    AppRoutes.premiumSubscriptionCenter,
    AppRoutes.premiumSubscriptionCenterWebCanonical,
    AppRoutes.userSubscriptionDashboardWebCanonical,
    AppRoutes.stripeSubscriptionManagementCenterWebCanonical,
    AppRoutes.stripePaymentIntegrationHubAdmin,
    AppRoutes.countryRestrictionsAdmin,
    AppRoutes.platformIntegrationsAdmin,
    AppRoutes.notificationCenterHub,
    AppRoutes.notificationCenterHubWebCanonical,
    AppRoutes.directMessagingScreen,
    AppRoutes.directMessagingScreenWebCanonical,
    AppRoutes.socialConnectionsManager,
    AppRoutes.friendsManagementHub,
    AppRoutes.friendsManagementHubWebCanonical,
    AppRoutes.socialActivityTimeline,
    AppRoutes.socialActivityTimelineWebCanonical,
    AppRoutes.enhancedGroupsHub,
    AppRoutes.enhancedGroupsHubWebCanonical,
    AppRoutes.apiDocumentationPortal,
    AppRoutes.apiDocumentationPortalWebCanonical,
    AppRoutes.adminDashboard,
    AppRoutes.bulkManagementScreen,
    AppRoutes.enhancedMobileAdminDashboard,
    AppRoutes.brandAdvertiserRegistrationPortal,
    AppRoutes.brandAdvertiserRegistrationPortalWebCanonical,
    AppRoutes.votteryAdsStudio,
    AppRoutes.votteryAdsStudioWebCanonical,
    AppRoutes.participatoryAdsStudio,
    AppRoutes.participatoryAdsStudioWebCanonical,
    AppRoutes.statusPageScreen,
    AppRoutes.statusPageScreenWebCanonical,
    AppRoutes.statusRouteWebCanonical,
    AppRoutes.comprehensiveOnboardingFlow,
    AppRoutes.interactiveOnboardingWizardWebCanonical,
    AppRoutes.aiGuidedInteractiveTutorial,
    AppRoutes.aiGuidedInteractiveTutorialSystemWebCanonical,
    AppRoutes.userSecurityCenter,
    AppRoutes.userSecurityCenterWebCanonical,
    AppRoutes.supportTicketingSystem,
    AppRoutes.centralizedSupportTicketingSystemWebCanonical,
    AppRoutes.helpSupportCenter,
  };

  static bool isAllowed(String? routeName) {
    if (_fullFeatureCertificationMode) return true;
    final normalized = _normalize(routeName);
    if (normalized == null || normalized.isEmpty) return true;
    return _allowed.contains(normalized);
  }

  static String? _normalize(String? routeName) {
    if (routeName == null) return null;
    final trimmed = routeName.trim();
    if (trimmed.isEmpty) return null;
    final withoutHash = trimmed.split('#').first;
    final withoutQuery = withoutHash.split('?').first;
    if (withoutQuery.isEmpty) return null;
    return withoutQuery.endsWith('/') && withoutQuery.length > 1
        ? withoutQuery.substring(0, withoutQuery.length - 1)
        : withoutQuery;
  }
}
