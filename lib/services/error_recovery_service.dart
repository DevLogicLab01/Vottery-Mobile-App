import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ErrorRecoveryService {
  static final ErrorRecoveryService _instance =
      ErrorRecoveryService._internal();
  factory ErrorRecoveryService() => _instance;
  ErrorRecoveryService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Retry with exponential backoff
  Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow;
        }

        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(
            0,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }

    throw Exception('Max retry attempts reached');
  }

  /// Check network connectivity
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.first != ConnectivityResult.none;
  }

  /// Execute with network check
  Future<T> executeWithNetworkCheck<T>({
    required Future<T> Function() operation,
    required T Function() offlineFallback,
  }) async {
    if (await isConnected()) {
      try {
        return await operation();
      } catch (e) {
        return offlineFallback();
      }
    } else {
      return offlineFallback();
    }
  }

  /// Execute with timeout and retry
  Future<T> executeWithTimeout<T>({
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    return retryWithBackoff(
      operation: () => operation().timeout(
        timeout,
        onTimeout: () => throw TimeoutException('Operation timed out'),
      ),
      maxAttempts: maxRetries,
    );
  }
}
