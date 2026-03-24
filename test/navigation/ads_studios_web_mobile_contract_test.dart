import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/vottery_ads_constants.dart';
import 'package:vottery/presentation/advertiser_analytics_dashboard/advertiser_analytics_dashboard.dart';
import 'package:vottery/presentation/participatory_ads_studio/participatory_ads_studio.dart';
import 'package:vottery/presentation/vottery_ads_studio/vottery_ads_studio.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Ads studios & advertiser analytics - Web/Mobile contract', () {
    test('canonical paths match Web Router', () {
      expect(
        AppRoutes.participatoryAdsStudioWebCanonical,
        '/participatory-ads-studio',
      );
      expect(AppRoutes.votteryAdsStudioWebCanonical, '/vottery-ads-studio');
      expect(
        AppRoutes.advertiserAnalyticsDashboardWebCanonical,
        '/advertiser-analytics-roi-dashboard',
      );
      expect(
        VotteryAdsConstants.participatoryAdsStudioRoute,
        '/participatory-ads-studio',
      );
      expect(VotteryAdsConstants.votteryAdsStudioRoute, '/votteryAdsStudio');
      expect(
        VotteryAdsConstants.advertiserAnalyticsRoute,
        '/advertiser-analytics-roi-dashboard',
      );
    });

    test('screenForRoute: unified Vottery Ads -> VotteryAdsStudio', () {
      expect(screenForRoute(AppRoutes.votteryAdsStudio), isA<VotteryAdsStudio>());
      expect(
        screenForRoute(AppRoutes.votteryAdsStudioWebCanonical),
        isA<VotteryAdsStudio>(),
      );
    });

    test('screenForRoute: participatory -> ParticipatoryAdsStudio', () {
      expect(
        screenForRoute(AppRoutes.participatoryAdsStudio),
        isA<ParticipatoryAdsStudio>(),
      );
      expect(
        screenForRoute(AppRoutes.participatoryAdsStudioWebCanonical),
        isA<ParticipatoryAdsStudio>(),
      );
    });

    test('screenForRoute: advertiser analytics -> AdvertiserAnalyticsDashboard', () {
      expect(
        screenForRoute(AppRoutes.advertiserAnalyticsDashboard),
        isA<AdvertiserAnalyticsDashboard>(),
      );
      expect(
        screenForRoute(AppRoutes.advertiserAnalyticsDashboardWebCanonical),
        isA<AdvertiserAnalyticsDashboard>(),
      );
    });
  });
}
