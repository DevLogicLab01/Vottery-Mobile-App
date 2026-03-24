/// Vottery Ads Studio – shared constants (Web + Mobile parity).
/// Sync with Web: src/constants/votteryAdsConstants.js

class VotteryAdsConstants {
  VotteryAdsConstants._();

  /// Public Web URL — sync with JS `VOTTERY_ADS_ROUTE` and [AppRoutes.votteryAdsStudioWebCanonical].
  static const String votteryAdsStudioWebRoute = '/vottery-ads-studio';

  /// Flutter `Navigator.pushNamed` path for [VotteryAdsStudio] (not the kebab-case public URL).
  static const String votteryAdsStudioRoute = '/votteryAdsStudio';
  /// Web parity: `/participatory-ads-studio` — sponsored-election wizard.
  static const String participatoryAdsStudioRoute = '/participatory-ads-studio';
  /// Same path as Web `CAMPAIGN_MANAGEMENT_ROUTE` (React Router).
  static const String campaignManagementRoute = '/campaign-management-dashboard';
  /// Web React alias route (same hub UI as [campaignManagementRoute]).
  static const String sponsoredElectionsSchemaCpeHubRoute =
      '/sponsored-elections-schema-cpe-management-hub';
  /// Web parity: `/dynamic-cpe-pricing-engine-dashboard`
  static const String dynamicCpePricingEngineRoute =
      '/dynamic-cpe-pricing-engine-dashboard';
  /// Web parity: `/campaign-template-gallery`
  static const String campaignTemplateGalleryRoute = '/campaign-template-gallery';
  /// Same path as Web `ADVERTISER_ANALYTICS_ROUTE`.
  static const String advertiserAnalyticsRoute =
      '/advertiser-analytics-roi-dashboard';
  /// Flutter `Navigator.pushNamed` — use with [AppRoutes.campaignManagementDashboard].
  static const String campaignManagementAppRoute = '/campaignManagementDashboard';
  /// Flutter in-app route for advertiser analytics screen.
  static const String advertiserAnalyticsAppRoute =
      '/advertiserAnalyticsDashboard';
  /// Web parity: `/api-documentation-portal`
  static const String apiDocumentationPortalRoute = '/api-documentation-portal';
  /// Web parity: `/brand-advertiser-registration-portal`
  static const String brandAdvertiserRegistrationPortalRoute =
      '/brand-advertiser-registration-portal';
  /// Web parity: `/res-tful-api-management-center`
  static const String restfulApiManagementCenterRoute =
      '/res-tful-api-management-center';
  /// Web parity: `/webhook-integration-hub`
  static const String webhookIntegrationHubRoute = '/webhook-integration-hub';

  static const String campaignObjectiveReach = 'reach';
  static const String campaignObjectiveTraffic = 'traffic';
  static const String campaignObjectiveAppInstalls = 'app_installs';
  static const String campaignObjectiveConversions = 'conversions';

  static const String adTypeDisplay = 'display';
  static const String adTypeVideo = 'video';
  static const String adTypeParticipatory = 'participatory';
  static const String adTypeSpark = 'spark';

  static const String pricingModelCpm = 'cpm';
  static const String pricingModelCpc = 'cpc';
  static const String pricingModelOcpm = 'ocpm';
  static const String pricingModelCpv = 'cpv';

  static const String placementStyleTiktok = 'tiktok_style';
  static const String placementStyleFacebook = 'facebook_style';
  static const String placementStylePremium = 'premium';

  /// Purchasing-power zones 1–8
  static const List<int> zoneValues = [1, 2, 3, 4, 5, 6, 7, 8];

  static const List<String> placementSlotsTiktok = [
    'top_view',
    'feed_post',
    'moments',
    'jolts',
  ];

  static const List<String> placementSlotsFacebook = [
    'creators_marketplace',
    'recommended_groups',
    'trending_topics',
    'recommended_elections',
    'elections_voting_ui',
    'elections_verification_ui',
    'elections_audit_ui',
    'top_earners',
    'accuracy_champions',
    // 'right_column' – web only
  ];

  static const Map<String, String> placementSlotLabels = {
    'top_view': 'TopView',
    'feed_post': 'Feed/Post',
    'moments': 'Moments',
    'jolts': 'Jolts',
    'creators_marketplace': 'Creators Services/Marketplace',
    'recommended_groups': 'Recommended Groups',
    'trending_topics': 'Trending Topics',
    'recommended_elections': 'Recommended Elections',
    'elections_voting_ui': 'Elections Voting Screen',
    'elections_verification_ui': 'Elections Verification Screen',
    'elections_audit_ui': 'Elections Audit Screen',
    'top_earners': 'Top Earners',
    'accuracy_champions': 'Accuracy Champions',
  };

  static const String eventImpression = 'IMPRESSION';
  static const String eventView2s = 'VIEW_2S';
  static const String eventView6s = 'VIEW_6S';
  static const String eventComplete = 'COMPLETE';
  static const String eventClick = 'CLICK';
  static const String eventHide = 'HIDE';
  static const String eventReport = 'REPORT';

  static const int defaultMinDailyBudgetCents = 500; // $5
  static const int defaultMinCampaignBudgetCents = 10000; // $100

  static const double pricingCpmMin = 3.20;
  static const double pricingCpmMax = 10.0;
  static const double pricingCpcMin = 0.10;
  static const double pricingCpcMax = 1.0;
  static const double pricingPremiumSlotDayMin = 40000;
  static const double pricingPremiumSlotDayMax = 160000;

  /// Batch-1 internal ads — keep identical to Web `votteryAdsConstants.js` (`BATCH1_*`).
  static const String batch1InternalAdsDisabledTitle = 'Internal Ads Disabled for Batch 1';
  static const String batch1InternalAdsDisabledBody =
      'Vottery internal ads are intentionally disabled in Batch 1. Use external ad network integrations from the admin integrations panel.';
  static const String batch1ParticipatoryAdsDisabledTitle = 'Participatory Ads Disabled for Batch 1';
  static const String batch1ParticipatoryAdsDisabledBody =
      'Participatory/gamified internal ads are disabled in Batch 1. Continue with external ad network partners only.';

  // Batch-1 hard guard: internal ad studios must stay disabled.
  static const bool internalAdsBatch1Disabled = true;
  static const List<String> externalAdNetworkIntegrations = ['Google AdSense'];
}
