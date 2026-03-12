import 'dart:io';

import 'package:flutter/foundation.dart';

import './auth_service.dart';
import './carousel_fraud_detection_service.dart';
import './supabase_service.dart';

/// Logs carousel interactions for fraud detection
class CarouselInteractionLogger {
  static CarouselInteractionLogger? _instance;
  static CarouselInteractionLogger get instance =>
      _instance ??= CarouselInteractionLogger._();

  CarouselInteractionLogger._();

  static const int _swipesBeforeFraudCheck = 20;
  int _swipeCountSinceLastCheck = 0;

  /// Log a swipe (page change) - call when user swipes to new card
  Future<void> logSwipe({
    required String itemId,
    required String interactionType,
    required double viewDurationSeconds,
    String? deviceFingerprint,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;

    try {
      await SupabaseService.instance.client.from('carousel_interactions').insert({
        'user_id': userId,
        'item_id': itemId,
        'interaction_type': interactionType,
        'view_duration_seconds': viewDurationSeconds,
        'device_fingerprint': deviceFingerprint ?? _getDeviceFingerprint(),
        'interaction_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('CarouselInteractionLogger: $e');
    }

    _swipeCountSinceLastCheck++;
    if (_swipeCountSinceLastCheck >= _swipesBeforeFraudCheck) {
      _swipeCountSinceLastCheck = 0;
      _runFraudCheck(userId);
    }
  }

  void _runFraudCheck(String userId) {
    CarouselFraudDetectionService.instance
        .runComprehensiveFraudCheck(userId)
        .then((result) {
      if (result['fraud_detected'] == true) {
        debugPrint('Carousel fraud detected for $userId: $result');
      }
    }).catchError((e) => debugPrint('Fraud check error: $e'));
  }

  String _getDeviceFingerprint() {
    if (kIsWeb) return 'web';
    try {
      return Platform.operatingSystem;
    } catch (_) {
      return 'unknown';
    }
  }
}
