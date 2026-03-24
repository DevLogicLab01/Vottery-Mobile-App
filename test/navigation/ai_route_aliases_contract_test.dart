import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('AI route aliases - Web/Mobile contract', () {
    test('AI alias web URLs stay aligned', () {
      expect(
        AppUrls.advancedMlThreatDetectionCenter,
        endsWith('/advanced-ml-threat-detection-center'),
      );
      expect(
        AppUrls.zoneSpecificThreatHeatmapsDashboard,
        endsWith('/zone-specific-threat-heatmaps-dashboard'),
      );
      expect(
        AppUrls.predictionAnalyticsDashboard,
        endsWith('/prediction-analytics-dashboard'),
      );
      expect(
        AppUrls.perplexityMarketResearchIntelligenceCenter,
        endsWith('/perplexity-market-research-intelligence-center'),
      );
      expect(
        AppUrls.predictiveAnomalyAlertingDeviationMonitoringHub,
        endsWith('/predictive-anomaly-alerting-deviation-monitoring-hub'),
      );
      expect(
        AppUrls.continuousMlFeedbackOutcomeLearningCenter,
        endsWith('/continuous-ml-feedback-outcome-learning-center'),
      );
    });

    test('route registry keeps canonical AI alias mappings', () {
      expect(
        screenForRoute(AppRoutes.advancedMlThreatDetectionCenterWebCanonical)
            .runtimeType
            .toString(),
        'AdvancedThreatPredictionDashboard',
      );
      expect(
        screenForRoute(AppRoutes.zoneSpecificThreatHeatmapsDashboardWebCanonical)
            .runtimeType
            .toString(),
        'ZoneSpecificThreatHeatmapsDashboard',
      );
      expect(
        screenForRoute(AppRoutes.predictionAnalyticsDashboardWebCanonical)
            .runtimeType
            .toString(),
        'PredictionAnalyticsDashboard',
      );
      expect(
        screenForRoute(
          AppRoutes.perplexityMarketResearchIntelligenceCenterWebCanonical,
        ).runtimeType.toString(),
        'DedicatedMarketResearchDashboard',
      );
      expect(
        screenForRoute(
          AppRoutes.predictiveAnomalyAlertingDeviationMonitoringHubWebCanonical,
        ).runtimeType.toString(),
        'AiAnomalyDetectionFraudPreventionHub',
      );
      expect(
        screenForRoute(AppRoutes.continuousMlFeedbackOutcomeLearningCenterWebCanonical)
            .runtimeType
            .toString(),
        'PredictiveIncidentPreventionEngine',
      );
    });
  });
}
