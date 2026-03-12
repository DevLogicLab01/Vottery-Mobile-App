import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// AI Timeout Fallback Service
/// Handles AI service timeouts with retry, exponential backoff, and local ML fallbacks
class AITimeoutFallbackService {
  static AITimeoutFallbackService? _instance;
  static AITimeoutFallbackService get instance =>
      _instance ??= AITimeoutFallbackService._();

  AITimeoutFallbackService._();

  static const Duration _defaultTimeout = Duration(seconds: 15);
  static const Duration _complexTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  bool _isOfflineMode = false;

  /// Execute AI call with timeout, retry, and fallback
  Future<T> executeWithFallback<T>({
    required Future<T> Function() aiCall,
    required T Function() localFallback,
    Duration? timeout,
    bool isComplex = false,
    String? operationName,
  }) async {
    final timeoutDuration =
        timeout ?? (isComplex ? _complexTimeout : _defaultTimeout);
    int attempt = 0;

    while (attempt < _maxRetries) {
      try {
        final result = await aiCall().timeout(timeoutDuration);
        _isOfflineMode = false;
        return result;
      } on TimeoutException {
        attempt++;
        debugPrint(
          '⏱️ AI timeout (${operationName ?? "unknown"}) attempt $attempt/$_maxRetries',
        );
        if (attempt < _maxRetries) {
          // Exponential backoff: 2s, 4s, 8s
          final waitMs = pow(2, attempt).toInt() * 1000;
          await Future.delayed(Duration(milliseconds: waitMs));
        }
      } catch (e) {
        attempt++;
        debugPrint(
          '❌ AI error (${operationName ?? "unknown"}) attempt $attempt: $e',
        );
        if (attempt < _maxRetries) {
          final waitMs = pow(2, attempt).toInt() * 1000;
          await Future.delayed(Duration(milliseconds: waitMs));
        }
      }
    }

    // All retries failed - use local fallback
    debugPrint('🔄 Using local ML fallback for ${operationName ?? "unknown"}');
    _isOfflineMode = true;
    return localFallback();
  }

  /// Content moderation fallback (rule-based)
  Map<String, dynamic> contentModerationFallback(String content) {
    final lowerContent = content.toLowerCase();
    final inappropriateKeywords = [
      'spam',
      'scam',
      'fraud',
      'hack',
      'illegal',
      'abuse',
    ];
    final isInappropriate = inappropriateKeywords.any(
      (kw) => lowerContent.contains(kw),
    );
    return {
      'is_appropriate': !isInappropriate,
      'confidence': 0.7,
      'method': 'local_rule_based',
      'reason': isInappropriate
          ? 'Contains flagged keywords'
          : 'Passed basic checks',
    };
  }

  /// Fraud detection fallback (rule-based heuristics)
  Map<String, dynamic> fraudDetectionFallback(Map<String, dynamic> data) {
    double riskScore = 0.0;
    final reasons = <String>[];

    // Basic heuristics
    if ((data['amount'] as num? ?? 0) > 10000) {
      riskScore += 0.3;
      reasons.add('High transaction amount');
    }
    if ((data['velocity'] as num? ?? 0) > 10) {
      riskScore += 0.4;
      reasons.add('High transaction velocity');
    }
    if (data['new_device'] == true) {
      riskScore += 0.2;
      reasons.add('New device detected');
    }

    return {
      'risk_score': riskScore.clamp(0.0, 1.0),
      'is_fraudulent': riskScore > 0.7,
      'reasons': reasons,
      'method': 'local_heuristics',
    };
  }

  /// Content ranking fallback (engagement score formula)
  List<Map<String, dynamic>> rankingFallback(List<Map<String, dynamic>> items) {
    final now = DateTime.now();
    final scored = items.map((item) {
      final views = (item['views'] as num? ?? 0).toDouble();
      final likes = (item['likes'] as num? ?? 0).toDouble();
      final createdAt = item['created_at'] != null
          ? DateTime.tryParse(item['created_at'] as String) ?? now
          : now;
      final recencyHours = now.difference(createdAt).inHours.toDouble();
      final recencyScore = 1.0 / (1.0 + recencyHours / 24.0);
      final engagementScore = (views * 0.3 + likes * 0.7) / 1000.0;
      final totalScore = engagementScore * 0.6 + recencyScore * 0.4;
      return {...item, '_score': totalScore};
    }).toList();

    scored.sort(
      (a, b) => (b['_score'] as double).compareTo(a['_score'] as double),
    );
    return scored;
  }

  bool get isOfflineMode => _isOfflineMode;
}
