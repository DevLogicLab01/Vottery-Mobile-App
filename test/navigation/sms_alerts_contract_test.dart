import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('SMS and alerts - Web/Mobile contract', () {
    test('SMS/alert web URLs stay aligned', () {
      expect(
        AppUrls.smsWebhookDeliveryAnalyticsHub,
        endsWith('/sms-webhook-delivery-analytics-hub'),
      );
      expect(
        AppUrls.smsEmergencyAlertsHub,
        endsWith('/sms-emergency-alerts-hub'),
      );
      expect(
        AppUrls.telnyxSmsProviderManagementCenter,
        endsWith('/telnyx-sms-provider-management-center'),
      );
      expect(
        AppUrls.customAlertRulesEngine,
        endsWith('/custom-alert-rules-engine'),
      );
      expect(
        AppUrls.advancedCustomAlertRulesEngine,
        endsWith('/advanced-custom-alert-rules-engine'),
      );
      expect(
        AppUrls.unifiedAlertManagementCenter,
        endsWith('/unified-alert-management-center'),
      );
    });

    test('route registry keeps canonical SMS/alert mappings', () {
      expect(
        screenForRoute(AppRoutes.smsWebhookDeliveryAnalyticsHubWebCanonical)
            .runtimeType
            .toString(),
        'SmsWebhookManagementDashboard',
      );
      expect(
        screenForRoute(AppRoutes.smsEmergencyAlertsHubWebCanonical)
            .runtimeType
            .toString(),
        'SmsEmergencyAlertsHub',
      );
      expect(
        screenForRoute(AppRoutes.telnyxSmsProviderManagementCenterWebCanonical)
            .runtimeType
            .toString(),
        'TelnyxSmsProviderManagementDashboard',
      );
      expect(
        screenForRoute(AppRoutes.customAlertRulesEngineWebCanonical)
            .runtimeType
            .toString(),
        'AutomatedThresholdBasedAlertingHub',
      );
      expect(
        screenForRoute(AppRoutes.advancedCustomAlertRulesEngineWebCanonical)
            .runtimeType
            .toString(),
        'AutomatedThresholdBasedAlertingHub',
      );
      expect(
        screenForRoute(AppRoutes.unifiedAlertManagementCenterWebCanonical)
            .runtimeType
            .toString(),
        'UnifiedAlertManagementCenter',
      );
    });
  });
}
