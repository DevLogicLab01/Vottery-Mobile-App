import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/route_registry.dart';
import 'package:vottery/constants/app_urls.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Fraud/perplexity - Web/Mobile contract', () {
    test('fraud/perplexity web URLs stay aligned', () {
      expect(
        AppUrls.fraudDetectionAlertManagementCenter,
        endsWith('/fraud-detection-alert-management-center'),
      );
      expect(
        AppUrls.advancedPerplexityFraudIntelligenceCenter,
        endsWith('/advanced-perplexity-fraud-intelligence-center'),
      );
      expect(
        AppUrls.advancedPerplexityFraudForecastingCenter,
        endsWith('/advanced-perplexity-fraud-forecasting-center'),
      );
      expect(
        AppUrls.advancedMlThreatDetectionCenter,
        endsWith('/advanced-ml-threat-detection-center'),
      );
      expect(
        AppUrls.predictiveAnomalyAlertingDeviationMonitoringHub,
        endsWith('/predictive-anomaly-alerting-deviation-monitoring-hub'),
      );
      expect(
        AppUrls.perplexityMarketResearchIntelligenceCenter,
        endsWith('/perplexity-market-research-intelligence-center'),
      );
      expect(
        AppUrls.perplexityStrategicPlanningCenter,
        endsWith('/perplexity-strategic-planning-center'),
      );
      expect(
        AppUrls.perplexityCarouselIntelligenceDashboard,
        endsWith('/perplexity-carousel-intelligence-dashboard'),
      );
    });

    test('route registry keeps canonical fraud/perplexity mappings', () {
      expect(
        screenForRoute(AppRoutes.fraudDetectionAlertManagementCenterWebCanonical)
            .runtimeType
            .toString(),
        'FraudMonitoringDashboard',
      );
      expect(
        screenForRoute(AppRoutes.advancedMlThreatDetectionCenterWebCanonical)
            .runtimeType
            .toString(),
        'AdvancedThreatPredictionDashboard',
      );
      expect(
        screenForRoute(
          AppRoutes.predictiveAnomalyAlertingDeviationMonitoringHubWebCanonical,
        ).runtimeType.toString(),
        'AiAnomalyDetectionFraudPreventionHub',
      );
      expect(
        screenForRoute(
          AppRoutes.perplexityMarketResearchIntelligenceCenterWebCanonical,
        ).runtimeType.toString(),
        'DedicatedMarketResearchDashboard',
      );
      expect(
        screenForRoute(
          AppRoutes.perplexityCarouselIntelligenceDashboardWebCanonical,
        ).runtimeType.toString(),
        'DedicatedMarketResearchDashboard',
      );
      expect(
        screenForRoute(AppRoutes.perplexityStrategicPlanningCenterWebCanonical)
            .runtimeType
            .toString(),
        'PredictionAnalyticsDashboard',
      );
    });
  });
}
