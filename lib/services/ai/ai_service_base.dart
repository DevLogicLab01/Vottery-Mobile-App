import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception thrown when AI service encounters an error
class AIServiceException implements Exception {
  final String message;
  final dynamic originalError;

  AIServiceException(this.message, [this.originalError]);

  @override
  String toString() => 'AIServiceException: $message';
}

/// Base class for all AI service integrations
/// Provides universal request handling with automatic Gemini failover
abstract class AIServiceBase {
  static const String baseUrl = String.fromEnvironment('SUPABASE_URL');
  static final SupabaseClient supabase = Supabase.instance.client;

  /// Universal AI request handler with failover support
  ///
  /// Invokes Supabase Edge Functions for AI operations with automatic
  /// Gemini fallback when primary service fails
  ///
  /// [functionName] - Name of the Supabase Edge Function to invoke
  /// [params] - Parameters to pass to the function
  ///
  /// Returns the response data as a Map
  /// Throws [AIServiceException] if both primary and fallback fail
  static Future<Map<String, dynamic>> invokeAIFunction(
    String functionName,
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await supabase.functions.invoke(
        functionName,
        body: params,
      );

      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw AIServiceException(
        'Service error: ${response.status}',
        response.data,
      );
    } catch (e) {
      // Automatic Gemini fallback for disruptions
      return await _handleAIFailover(functionName, params, e);
    }
  }

  /// Handles AI service failover to Gemini
  ///
  /// Automatically switches to Gemini when primary AI service fails
  /// Logs the failure and attempts recovery
  ///
  /// [function] - Original function name that failed
  /// [params] - Original parameters
  /// [error] - Error that triggered the failover
  ///
  /// Returns the fallback response data
  /// Throws [AIServiceException] if fallback also fails
  static Future<Map<String, dynamic>> _handleAIFailover(
    String function,
    Map<String, dynamic> params,
    dynamic error,
  ) async {
    try {
      // Log the failover event
      await _logFailoverEvent(function, error);

      // Invoke Gemini fallback handler
      final response = await supabase.functions.invoke(
        'gemini-fallback-handler',
        body: {
          'original_function': function,
          'params': params,
          'error': error.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw AIServiceException(
        'Failover failed: ${response.status}',
        response.data,
      );
    } catch (e) {
      throw AIServiceException('Both primary and fallback services failed', e);
    }
  }

  /// Logs failover events for monitoring and analytics
  static Future<void> _logFailoverEvent(String function, dynamic error) async {
    try {
      await supabase.from('ai_service_logs').insert({
        'function_name': function,
        'error_message': error.toString(),
        'event_type': 'failover',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail - don't block failover if logging fails
      print('Failed to log failover event: $e');
    }
  }

  /// Validates AI service response structure
  ///
  /// Ensures the response contains required fields
  /// Throws [AIServiceException] if validation fails
  static void validateResponse(
    Map<String, dynamic> response,
    List<String> requiredFields,
  ) {
    for (final field in requiredFields) {
      if (!response.containsKey(field)) {
        throw AIServiceException(
          'Invalid response: missing required field "$field"',
        );
      }
    }
  }

  /// Handles rate limiting with exponential backoff
  ///
  /// Retries the request with increasing delays
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [initialDelay] - Initial delay in milliseconds (default: 1000)
  static Future<Map<String, dynamic>> invokeWithRetry(
    String functionName,
    Map<String, dynamic> params, {
    int maxRetries = 3,
    int initialDelay = 1000,
  }) async {
    int retryCount = 0;
    int delay = initialDelay;

    while (retryCount < maxRetries) {
      try {
        return await invokeAIFunction(functionName, params);
      } catch (e) {
        retryCount++;

        if (retryCount >= maxRetries) {
          rethrow;
        }

        // Exponential backoff
        await Future.delayed(Duration(milliseconds: delay));
        delay *= 2;
      }
    }

    throw AIServiceException('Max retries exceeded');
  }

  /// Checks if AI services are available
  ///
  /// Returns true if at least one AI service is operational
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await supabase.functions.invoke(
        'health-check',
        body: {'service': 'ai'},
      );

      return response.status == 200;
    } catch (e) {
      return false;
    }
  }
}
