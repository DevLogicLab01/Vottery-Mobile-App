import 'package:flutter_test/flutter_test.dart';

import 'package:vottery/config/route_feature_keys.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Creator analytics route parity checks', () {
    test('creator analytics routes are defined', () {
      expect(AppRoutes.creatorGrowthAnalyticsDashboard, isNotEmpty);
      expect(AppRoutes.creatorPredictiveInsightsHub, isNotEmpty);
      expect(AppRoutes.creatorRevenueForecastingDashboard, isNotEmpty);
      expect(AppRoutes.creatorChurnPredictionDashboard, isNotEmpty);
    });

    test('creator analytics routes map to expected feature keys', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('creatorGrowthAnalytics'),
        'creator_growth_analytics_dashboard',
      );
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('predictiveCreatorInsights'),
        'predictive_creator_insights_dashboard',
      );
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute(
          'creatorRevenueForecastingDashboard',
        ),
        'creator_revenue_forecasting_dashboard',
      );
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('creatorChurnPrediction'),
        'creator_churn_prediction_intelligence_center',
      );
    });
  });
}
