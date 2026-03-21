import 'package:flutter_test/flutter_test.dart';

import 'package:vottery/config/route_feature_keys.dart';
import 'package:vottery/routes/app_routes.dart';

void main() {
  group('Voting role route constants checks', () {
    test('core voting role routes are defined', () {
      expect(AppRoutes.enhancedVoteCasting, isNotEmpty);
      expect(AppRoutes.enhancedVoteCastingWithPredictionIntegration, isNotEmpty);
      expect(AppRoutes.collaborativeVotingRoom, isNotEmpty);
      expect(AppRoutes.locationVoting, isNotEmpty);
      expect(AppRoutes.enhancedMcqImageOptionsInterface, isNotEmpty);
    });
  });

  group('Voting role feature-key parity checks', () {
    test('secure voting key is mapped', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('enhancedVoteCasting'),
        'secure_voting_interface',
      );
    });

    test('collaborative voting key is mapped', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('collaborativeVotingRoom'),
        'collaborative_voting_room',
      );
    });

    test('location voting key is mapped', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('locationVoting'),
        'location_based_voting',
      );
    });

    test('prediction pool key is mapped', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute(
          'enhancedVoteCastingWithPredictionIntegration',
        ),
        'prediction_pools',
      );
    });

    test('mcq image interface key is mapped', () {
      expect(
        RouteFeatureKeys.getFeatureKeyForRoute('enhancedMcqImageOptionsInterface'),
        'enhanced_mcq_image_interface',
      );
    });
  });
}
