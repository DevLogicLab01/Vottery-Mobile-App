import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Creator suite - Web/Mobile contract', () {
    test('creator suite URLs stay aligned', () {
      expect(AppUrls.electionCreationStudio, endsWith('/election-creation-studio'));
      expect(
        AppUrls.creatorMonetizationStudio,
        endsWith('/creator-monetization-studio'),
      );
      expect(AppUrls.creatorSuccessAcademy, endsWith('/creator-success-academy'));
      expect(
        AppUrls.creatorRevenueForecastingDashboard,
        endsWith('/creator-revenue-forecasting-dashboard'),
      );
      expect(
        AppUrls.realTimeAnalyticsDashboard,
        endsWith('/real-time-analytics-dashboard'),
      );
      expect(
        AppUrls.creatorMarketplaceScreen,
        endsWith('/creator-marketplace-screen'),
      );
    });

    test('route registry keeps creator suite canonical mappings', () {
      expect(
        screenForRoute(AppRoutes.electionCreationStudioWebCanonical)
            .runtimeType
            .toString(),
        'ElectionCreationStudio',
      );
      expect(
        screenForRoute(AppRoutes.creatorMonetizationStudioWebCanonical)
            .runtimeType
            .toString(),
        'CreatorMonetizationStudio',
      );
      expect(
        screenForRoute(AppRoutes.creatorSuccessAcademyWebCanonical)
            .runtimeType
            .toString(),
        'CreatorSuccessAcademy',
      );
      expect(
        screenForRoute(AppRoutes.creatorRevenueForecastingDashboardWebCanonical)
            .runtimeType
            .toString(),
        'CreatorRevenueForecastingDashboard',
      );
      expect(
        screenForRoute(AppRoutes.realTimeAnalyticsDashboardWeb)
            .runtimeType
            .toString(),
        'RealTimeAnalyticsDashboardScreen',
      );
    });
  });
}
