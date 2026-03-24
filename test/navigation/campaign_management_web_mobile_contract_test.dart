import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/vottery_ads_constants.dart';
import 'package:vottery/presentation/campaign_management_dashboard/campaign_management_dashboard.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Campaign management - Web/Mobile contract', () {
    test('paths match Web and shared constants', () {
      expect(
        AppRoutes.campaignManagementDashboardWebCanonical,
        VotteryAdsConstants.campaignManagementRoute,
      );
      expect(
        AppRoutes.sponsoredElectionsSchemaCpeManagementHubWebCanonical,
        VotteryAdsConstants.sponsoredElectionsSchemaCpeHubRoute,
      );
      expect(
        AppRoutes.campaignManagementDashboardWebCanonical,
        '/campaign-management-dashboard',
      );
      expect(
        AppRoutes.sponsoredElectionsSchemaCpeManagementHubWebCanonical,
        '/sponsored-elections-schema-cpe-management-hub',
      );
    });

    test('screenForRoute: in-app and Web canonical -> CampaignManagementDashboard', () {
      expect(
        screenForRoute(AppRoutes.campaignManagementDashboard),
        isA<CampaignManagementDashboard>(),
      );
      expect(
        screenForRoute(AppRoutes.campaignManagementDashboardWebCanonical),
        isA<CampaignManagementDashboard>(),
      );
    });

    test('screenForRoute: sponsored-elections-schema CPE hub alias -> same dashboard', () {
      expect(
        screenForRoute(
          AppRoutes.sponsoredElectionsSchemaCpeManagementHubWebCanonical,
        ),
        isA<CampaignManagementDashboard>(),
      );
    });
  });
}
