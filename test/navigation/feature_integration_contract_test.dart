import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Feature integration - Web/Mobile contract', () {
    test('integration web URLs stay aligned', () {
      expect(
        AppUrls.adminPlatformLogsCenter,
        endsWith('/admin-platform-logs-center'),
      );
      expect(
        AppUrls.analyticsExportReportingHub,
        endsWith('/analytics-export-reporting-hub'),
      );
      expect(AppUrls.webhookIntegrationHub, endsWith('/webhook-integration-hub'));
      expect(
        AppUrls.advancedWebhookOrchestrationHub,
        endsWith('/advanced-webhook-orchestration-hub'),
      );
      expect(
        AppUrls.executiveReportingComplianceAutomationHub,
        endsWith('/executive-reporting-compliance-automation-hub'),
      );
      expect(
        AppUrls.automatedExecutiveReportingClaudeIntelligenceHub,
        endsWith('/automated-executive-reporting-claude-intelligence-hub'),
      );
      expect(AppUrls.crossDomainDataSyncHub, endsWith('/cross-domain-data-sync-hub'));
    });

    test('route registry keeps integration canonical mappings', () {
      expect(
        screenForRoute(AppRoutes.adminPlatformLogsCenterWebCanonical)
            .runtimeType
            .toString(),
        'WebAdminLauncherScreen',
      );
      expect(
        screenForRoute(AppRoutes.analyticsExportReportingHubWebCanonical)
            .runtimeType
            .toString(),
        'AnalyticsExportReportingHubScreen',
      );
      expect(
        screenForRoute(AppRoutes.webhookIntegrationHubWebCanonical)
            .runtimeType
            .toString(),
        'WebhookIntegrationManagementHub',
      );
      expect(
        screenForRoute(AppRoutes.advancedWebhookOrchestrationHubWebCanonical)
            .runtimeType
            .toString(),
        'AdvancedWebhookOrchestrationHub',
      );
      expect(
        screenForRoute(AppRoutes.executiveReportingComplianceAutomationHubWebCanonical)
            .runtimeType
            .toString(),
        'ExecutiveBusinessIntelligenceSuite',
      );
      expect(
        screenForRoute(
          AppRoutes.automatedExecutiveReportingClaudeIntelligenceHubWebCanonical,
        ).runtimeType.toString(),
        'AutomatedExecutiveReportingClaudeIntelligenceHub',
      );
      expect(
        screenForRoute(AppRoutes.crossDomainDataSyncHub).runtimeType.toString(),
        'CrossDomainDataSyncHub',
      );
    });
  });
}
