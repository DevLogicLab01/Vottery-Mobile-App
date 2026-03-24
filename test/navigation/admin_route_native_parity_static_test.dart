import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Static route registry parity checks', () {
    final routeRegistryPath = 'lib/config/route_registry.dart';

    test('web-canonical infra routes are mapped away from web launcher', () {
      final source = File(routeRegistryPath).readAsStringSync();

      final expectedNativeCases = <String>[
        'AppRoutes.unifiedAiDecisionOrchestrationCommandCenterWebCanonical',
        'AppRoutes.unifiedAiOrchestrationCommandCenterWebCanonical',
        'AppRoutes.queryPerformanceMonitoringDashboardWebCanonical',
        'AppRoutes.comprehensiveHealthMonitoringDashboardWebCanonical',
        'AppRoutes.productionMonitoringDashboardWebCanonical',
        'AppRoutes.mlModelTrainingInterfaceWebCanonical',
        'AppRoutes.loadTestingPerformanceAnalyticsCenterWebCanonical',
        'AppRoutes.performanceOptimizationEngineDashboardWebCanonical',
        'AppRoutes.performanceRegressionDetectionWebCanonical',
        'AppRoutes.advancedSupabaseRealtimeCoordinationHubWebCanonical',
        'AppRoutes.enhancedRealtimeWebSocketCoordinationHubWebCanonical',
        'AppRoutes.realtimeWebSocketMonitoringCommandCenterWebCanonical',
        'AppRoutes.automatedDataCacheManagementHubWebCanonical',
        'AppRoutes.aiPerformanceOrchestrationDashboardWebCanonical',
        'AppRoutes.automaticAiFailoverEngineControlCenterWebCanonical',
        'AppRoutes.claudeModelComparisonCenterWebCanonical',
        'AppRoutes.predictiveIncidentPreventionEngineWebCanonical',
        'AppRoutes.automatedIncidentResponsePortalWebCanonical',
        'AppRoutes.unifiedIncidentResponseOrchestrationCenterWebCanonical',
        'AppRoutes.unifiedIncidentResponseCommandCenterWebCanonical',
        'AppRoutes.securityMonitoringDashboardWebCanonical',
        'AppRoutes.unifiedBusinessIntelligenceHubWebCanonical',
        'AppRoutes.livePlatformMonitoringDashboardWebCanonical',
        // Feature-key / web-canonical parity (route_feature_keys → screenForRoute)
        'AppRoutes.userSubscriptionDashboardWebCanonical',
        'AppRoutes.aiGuidedInteractiveTutorialSystemWebCanonical',
        'AppRoutes.interactiveOnboardingWizardWebCanonical',
        'AppRoutes.enhancedHomeFeedDashboardWebCanonical',
        'AppRoutes.topicBasedCommunityElectionsHubWebCanonical',
        'AppRoutes.mobileOperationsCommandConsoleWebCanonical',
        'AppRoutes.statusRouteWebCanonical',
        'AppRoutes.dedicatedMarketResearchDashboardWebCanonical',
        'AppRoutes.predictionAnalyticsDashboardWebCanonical',
        'AppRoutes.unifiedAiPerformanceDashboardWebCanonical',
        'AppRoutes.aiPoweredPredictiveAnalyticsEngineWebCanonical',
        'AppRoutes.costAnalyticsRoiDashboard',
        'AppRoutes.unifiedRevenueIntelligenceDashboardWebCanonical',
      ];

      for (final routeCase in expectedNativeCases) {
        final caseIdx = source.indexOf('case $routeCase:');
        expect(caseIdx, isNonNegative, reason: 'Missing case for $routeCase');

        final returnIdx = source.indexOf('return ', caseIdx);
        expect(returnIdx, isNonNegative, reason: 'Missing return after $routeCase');

        final statementEnd = source.indexOf(';', returnIdx);
        expect(statementEnd, isNonNegative, reason: 'Malformed return statement after $routeCase');

        final returnStatement = source.substring(returnIdx, statementEnd + 1);
        expect(
          returnStatement.contains('WebAdminLauncherScreen'),
          isFalse,
          reason: '$routeCase should map to native screen, not WebAdminLauncherScreen',
        );
      }
    });
  });
}
