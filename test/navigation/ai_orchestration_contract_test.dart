import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('AI orchestration - Web/Mobile contract', () {
    test('AI orchestration web URLs stay aligned', () {
      expect(
        AppUrls.unifiedAiDecisionOrchestrationCommandCenter,
        endsWith('/unified-ai-decision-orchestration-command-center'),
      );
      expect(
        AppUrls.unifiedAiOrchestrationCommandCenter,
        endsWith('/unified-ai-orchestration-command-center'),
      );
      expect(
        AppUrls.automaticAiFailoverEngineControlCenter,
        endsWith('/automatic-ai-failover-engine-control-center'),
      );
      expect(
        AppUrls.aiPerformanceOrchestrationDashboard,
        endsWith('/ai-performance-orchestration-dashboard'),
      );
      expect(
        AppUrls.unifiedIncidentResponseOrchestrationCenter,
        endsWith('/unified-incident-response-orchestration-center'),
      );
    });

    test('route registry keeps canonical AI orchestration mappings', () {
      expect(
        screenForRoute(
          AppRoutes.unifiedAiDecisionOrchestrationCommandCenterWebCanonical,
        ).runtimeType.toString(),
        'UnifiedIncidentOrchestrationCenter',
      );
      expect(
        screenForRoute(AppRoutes.unifiedAiOrchestrationCommandCenterWebCanonical)
            .runtimeType
            .toString(),
        'MultiAiThreatOrchestrationHub',
      );
      expect(
        screenForRoute(
          AppRoutes.automaticAiFailoverEngineControlCenterWebCanonical,
        ).runtimeType.toString(),
        'AutomaticAIFailoverEngineControlCenter',
      );
      expect(
        screenForRoute(AppRoutes.aiPerformanceOrchestrationDashboardWebCanonical)
            .runtimeType
            .toString(),
        'UnifiedAIPerformanceDashboard',
      );
      expect(
        screenForRoute(
          AppRoutes.unifiedIncidentResponseOrchestrationCenterWebCanonical,
        ).runtimeType.toString(),
        'UnifiedIncidentOrchestrationCenter',
      );
    });
  });
}
