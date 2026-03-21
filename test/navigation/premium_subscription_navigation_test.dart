import 'package:flutter_test/flutter_test.dart';

import 'package:vottery/config/route_feature_keys.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Premium subscription route checks', () {
    test('premium subscription route is defined', () {
      expect(AppRoutes.premiumSubscriptionCenter, isNotEmpty);
    });

    test('premium subscription route maps to expected feature key', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('premiumSubscriptionCenter'),
        'enhanced_premium_subscription_center',
      );
    });
  });
}
