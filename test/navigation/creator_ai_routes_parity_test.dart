import 'package:flutter_test/flutter_test.dart';

import 'package:vottery/config/route_feature_keys.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Creator AI route parity checks', () {
    test('new creator AI routes are defined', () {
      expect(AppRoutes.mcqAbTestingAnalyticsDashboard, isNotEmpty);
      expect(AppRoutes.claudeCreatorSuccessAgent, isNotEmpty);
      expect(AppRoutes.contentQualityScoringClaude, isNotEmpty);
    });

    test('new creator AI routes map to expected feature keys', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('mcqAbTestingAnalyticsDashboard'),
        'mcq_ab_testing_analytics_dashboard',
      );
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('claudeCreatorSuccessAgent'),
        'claude_creator_success_agent',
      );
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('contentQualityScoringClaude'),
        'content_quality_scoring_claude',
      );
    });
  });
}
