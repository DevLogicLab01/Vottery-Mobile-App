import 'dart:async';
import 'dart:math';

/// Retry Service with Exponential Backoff
/// Implements retry logic with exponential backoff and jitter
class RetryService {
  static RetryService? _instance;
  static RetryService get instance => _instance ??= RetryService._();

  RetryService._();

  final RetryConfig defaultConfig = RetryConfig(
    initialDelay: const Duration(seconds: 1),
    maxDelay: const Duration(seconds: 30),
    multiplier: 2.0,
    maxAttempts: 3,
    jitterFactor: 0.1,
  );

  /// Retry operation with exponential backoff
  Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    RetryConfig? config,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    final retryConfig = config ?? defaultConfig;
    int attempt = 1;
    Duration currentDelay = retryConfig.initialDelay;

    while (attempt <= retryConfig.maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        // Check if error is retryable
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        if (attempt >= retryConfig.maxAttempts) {
          rethrow;
        }

        // Calculate next delay with exponential backoff
        final nextDelay = Duration(
          milliseconds: min(
            (currentDelay.inMilliseconds * retryConfig.multiplier).toInt(),
            retryConfig.maxDelay.inMilliseconds,
          ),
        );

        // Add jitter
        final jitter = Random().nextDouble() * retryConfig.jitterFactor;
        final delayWithJitter = Duration(
          milliseconds: (nextDelay.inMilliseconds * (1 + jitter)).toInt(),
        );

        await Future.delayed(delayWithJitter);

        currentDelay = nextDelay;
        attempt++;
      }
    }

    throw Exception('Max retry attempts exceeded');
  }

  /// Check if error is retryable
  bool isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Retryable errors
    if (errorString.contains('timeout')) return true;
    if (errorString.contains('connection refused')) return true;
    if (errorString.contains('5xx')) return true;
    if (errorString.contains('429')) return true;
    if (errorString.contains('rate limit')) return true;

    // Non-retryable errors
    if (errorString.contains('401')) return false;
    if (errorString.contains('403')) return false;
    if (errorString.contains('invalid api key')) return false;

    return true;
  }
}

/// Retry Configuration
class RetryConfig {
  final Duration initialDelay;
  final Duration maxDelay;
  final double multiplier;
  final int maxAttempts;
  final double jitterFactor;

  RetryConfig({
    required this.initialDelay,
    required this.maxDelay,
    required this.multiplier,
    required this.maxAttempts,
    required this.jitterFactor,
  });
}
