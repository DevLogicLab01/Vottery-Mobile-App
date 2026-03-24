import 'package:flutter_test/flutter_test.dart';

import 'package:vottery/config/route_feature_keys.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Feature parity routes are defined', () {
    test('social and notification routes exist', () {
      expect(AppRoutes.creatorCommunityHub, isNotEmpty);
      expect(AppRoutes.joltsVideoStudio, isNotEmpty);
      expect(AppRoutes.notificationCenterHub, isNotEmpty);
      expect(AppRoutes.pushNotificationManagementCenter, isNotEmpty);
      expect(AppRoutes.voterEducationHub, isNotEmpty);
    });
  });

  group('Feature key mapping parity checks', () {
    test('creator community route maps to expected feature key', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('creator-community-hub'),
        'creator_community_hub',
      );
    });

    test('notification center route maps to expected feature key', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('notificationCenterHub'),
        'notification_center_hub',
      );
    });

    test('jolts studio route maps to expected feature key', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('joltsVideoStudio'),
        'jolts_video_studio',
      );
    });

    test('push notification management maps to smart push key', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('pushNotificationManagementCenter'),
        'smart_push_notifications_optimization_center',
      );
    });

    test('voter education maps to voter education key', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('voterEducationHub'),
        'voter_education_hub',
      );
    });

    test('unified revenue intelligence Web path maps to DB feature toggle key', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute(
          'unified-revenue-intelligence-dashboard',
        ),
        'unified_revenue_intelligence_dashboard',
      );
    });

    test('country revenue share management Web path maps to DB feature toggle key', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute(
          'country-revenue-share-management-center',
        ),
        'country_revenue_share_management_center',
      );
    });

    test('regional revenue analytics Web path maps to DB feature toggle key', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute(
          'regional-revenue-analytics-dashboard',
        ),
        'regional_revenue_analytics_dashboard',
      );
    });
  });
}
