import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/vottery_ads_constants.dart';
import 'package:vottery/presentation/api_documentation_portal/api_documentation_portal.dart';
import 'package:vottery/presentation/campaign_template_gallery/campaign_template_gallery.dart';
import 'package:vottery/routes/app_routes.dart';

/// Contract: `/campaign-template-gallery` and `/api-documentation-portal` match Web Router;
/// [screenForRoute] returns the correct widgets.
///
/// Run: `flutter test integration_test/template_gallery_api_docs_contract_test.dart`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Template gallery & API docs — Web/Mobile contract', () {
    test('canonical paths match Web and VotteryAdsConstants', () {
      expect(
        AppRoutes.campaignTemplateGalleryWebCanonical,
        VotteryAdsConstants.campaignTemplateGalleryRoute,
      );
      expect(
        AppRoutes.campaignTemplateGalleryWebCanonical,
        '/campaign-template-gallery',
      );
      expect(
        AppRoutes.apiDocumentationPortalWebCanonical,
        VotteryAdsConstants.apiDocumentationPortalRoute,
      );
    });

    test('screenForRoute: template gallery (in-app + Web canonical)', () {
      expect(
        screenForRoute(AppRoutes.campaignTemplateGallery),
        isA<CampaignTemplateGallery>(),
      );
      expect(
        screenForRoute(AppRoutes.campaignTemplateGalleryWebCanonical),
        isA<CampaignTemplateGallery>(),
      );
    });

    test('screenForRoute: API documentation portal', () {
      expect(
        screenForRoute(AppRoutes.apiDocumentationPortal),
        isA<ApiDocumentationPortalScreen>(),
      );
      expect(
        screenForRoute(AppRoutes.apiDocumentationPortalWebCanonical),
        isA<ApiDocumentationPortalScreen>(),
      );
    });
  });
}
