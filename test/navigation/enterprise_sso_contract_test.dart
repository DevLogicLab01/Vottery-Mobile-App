import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Enterprise SSO - Web/Mobile contract', () {
    test('enterprise web URLs stay aligned', () {
      expect(
        AppUrls.enterpriseSsoIntegrationHub,
        endsWith('/enterprise-sso-integration-hub'),
      );
      expect(
        AppUrls.enterpriseOperationsCenter,
        endsWith('/enterprise-operations-center'),
      );
      expect(
        AppUrls.enterpriseAnalyticsHub,
        endsWith('/enterprise-analytics-hub'),
      );
      expect(
        AppUrls.enterpriseApiAccessCenter,
        endsWith('/enterprise-api-access-center'),
      );
      expect(
        AppUrls.enterpriseComplianceReportsCenter,
        endsWith('/enterprise-compliance-reports-center'),
      );
    });

    test('route registry keeps enterprise canonical mappings', () {
      expect(
        screenForRoute(AppRoutes.enterpriseSsoIntegrationWebCanonical)
            .runtimeType
            .toString(),
        'EnterpriseOperationsCenter',
      );
      expect(
        screenForRoute(AppRoutes.enterpriseAnalyticsHubWebCanonical)
            .runtimeType
            .toString(),
        'EnterpriseOperationsCenter',
      );
      expect(
        screenForRoute(AppRoutes.enterpriseApiAccessCenterWebCanonical)
            .runtimeType
            .toString(),
        'EnterpriseOperationsCenter',
      );
      expect(
        screenForRoute(AppRoutes.enterpriseComplianceReportsCenterWebCanonical)
            .runtimeType
            .toString(),
        'EnterpriseOperationsCenter',
      );
    });
  });
}
