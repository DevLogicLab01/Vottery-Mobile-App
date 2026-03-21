import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/presentation/web_admin_launcher_screen/web_admin_launcher_screen.dart';
import 'package:vottery/routes/app_routes.dart';

/// Web-canonical infra / monitoring paths that must open native Flutter
/// dashboards (not the embedded web launcher).
void main() {
  group('Admin web-canonical routes use native Flutter screens', () {
    final shouldBeNative = <String>[
      AppRoutes.unifiedAiDecisionOrchestrationCommandCenterWebCanonical,
      AppRoutes.unifiedAiOrchestrationCommandCenterWebCanonical,
      AppRoutes.queryPerformanceMonitoringDashboardWebCanonical,
      AppRoutes.comprehensiveHealthMonitoringDashboardWebCanonical,
      AppRoutes.productionMonitoringDashboardWebCanonical,
      AppRoutes.mlModelTrainingInterfaceWebCanonical,
      AppRoutes.loadTestingPerformanceAnalyticsCenterWebCanonical,
      AppRoutes.performanceOptimizationEngineDashboardWebCanonical,
      AppRoutes.performanceRegressionDetectionWebCanonical,
      AppRoutes.advancedSupabaseRealtimeCoordinationHubWebCanonical,
      AppRoutes.enhancedRealtimeWebSocketCoordinationHubWebCanonical,
      AppRoutes.realtimeWebSocketMonitoringCommandCenterWebCanonical,
      AppRoutes.automatedDataCacheManagementHubWebCanonical,
      AppRoutes.aiPerformanceOrchestrationDashboardWebCanonical,
      AppRoutes.automaticAiFailoverEngineControlCenterWebCanonical,
      AppRoutes.claudeModelComparisonCenterWebCanonical,
      AppRoutes.predictiveIncidentPreventionEngineWebCanonical,
      AppRoutes.automatedIncidentResponsePortalWebCanonical,
      AppRoutes.unifiedIncidentResponseOrchestrationCenterWebCanonical,
      AppRoutes.unifiedIncidentResponseCommandCenterWebCanonical,
      AppRoutes.securityMonitoringDashboardWebCanonical,
      AppRoutes.unifiedBusinessIntelligenceHubWebCanonical,
      AppRoutes.livePlatformMonitoringDashboardWebCanonical,
    ];

    for (final route in shouldBeNative) {
      test('$route resolves to native screen (not web launcher)', () {
        final screen = screenForRoute(route);
        expect(screen, isNotNull);
        expect(screen is WebAdminLauncherScreen, isFalse);
      });
    }
  });
}
