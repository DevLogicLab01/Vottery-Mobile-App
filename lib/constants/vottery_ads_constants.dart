/// Vottery Ads Studio – shared constants (Web + Mobile parity).
/// Sync with Web: src/constants/votteryAdsConstants.js

class VotteryAdsConstants {
  VotteryAdsConstants._();

  static const String votteryAdsStudioRoute = '/votteryAdsStudio';
  static const String campaignManagementRoute = '/campaignManagementDashboard';
  static const String advertiserAnalyticsRoute = '/advertiserAnalyticsDashboard';

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
}
