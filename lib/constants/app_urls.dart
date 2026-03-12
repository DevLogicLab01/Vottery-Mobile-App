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

  /// Claude dispute resolution (Web path: /claude-ai-dispute-moderation-center)
  static const String claudeDisputeResolution =
      '$webAppBase/claude-ai-dispute-moderation-center';

  /// Multi-currency settlement (Web path: /multi-currency-settlement-dashboard)
  static const String multiCurrencySettlement =
      '$webAppBase/multi-currency-settlement-dashboard';
}
