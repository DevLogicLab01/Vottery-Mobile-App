import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/vottery_ads_constants.dart';
import 'package:vottery/presentation/brand_advertiser_registration_portal/brand_advertiser_registration_portal.dart';
import 'package:vottery/presentation/res_tful_api_management_hub/res_tful_api_management_hub.dart';
import 'package:vottery/presentation/webhook_integration_management_hub/webhook_integration_management_hub.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Brand, REST API & Webhook hub - Web/Mobile contract', () {
    test('canonical paths match Web and VotteryAdsConstants', () {
      expect(
        AppRoutes.brandAdvertiserRegistrationPortalWebCanonical,
        VotteryAdsConstants.brandAdvertiserRegistrationPortalRoute,
      );
      expect(
        AppRoutes.resTfulApiManagementHubWebCanonical,
        VotteryAdsConstants.restfulApiManagementCenterRoute,
      );
      expect(
        AppRoutes.webhookIntegrationHubWebCanonical,
        VotteryAdsConstants.webhookIntegrationHubRoute,
      );
    });

    test('screenForRoute: brand advertiser registration', () {
      expect(
        screenForRoute(AppRoutes.brandAdvertiserRegistrationPortal),
        isA<BrandAdvertiserRegistrationPortal>(),
      );
      expect(
        screenForRoute(AppRoutes.brandAdvertiserRegistrationPortalWebCanonical),
        isA<BrandAdvertiserRegistrationPortal>(),
      );
    });

    test('screenForRoute: RESTful API management hub', () {
      expect(
        screenForRoute(AppRoutes.resTfulApiManagementHub),
        isA<RestfulApiManagementHub>(),
      );
      expect(
        screenForRoute(AppRoutes.resTfulApiManagementHubWebCanonical),
        isA<RestfulApiManagementHub>(),
      );
    });

    test('screenForRoute: webhook integration management hub', () {
      expect(
        screenForRoute(AppRoutes.webhookIntegrationManagementHub),
        isA<WebhookIntegrationManagementHub>(),
      );
      expect(
        screenForRoute(AppRoutes.webhookIntegrationHubWebCanonical),
        isA<WebhookIntegrationManagementHub>(),
      );
    });
  });
}
