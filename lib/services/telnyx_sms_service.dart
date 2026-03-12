import 'package:flutter/foundation.dart';
import './sms/telnyx_http_client.dart';
import './supabase_service.dart';

/// Telnyx SMS Service
/// Primary SMS provider with health monitoring and categorization
class TelnyxSMSService {
  static TelnyxSMSService? _instance;
  static TelnyxSMSService get instance => _instance ??= TelnyxSMSService._();

  TelnyxSMSService._();

  static const String apiKey = String.fromEnvironment('TELNYX_API_KEY');
  static const String messagingProfileId = String.fromEnvironment(
    'TELNYX_MESSAGING_PROFILE_ID',
  );
  static const String fromNumber = String.fromEnvironment(
    'TELNYX_PHONE_NUMBER',
  );

  final _supabase = SupabaseService.instance.client;
  TelnyxHttpClient? _httpClient;

  /// Initialize Telnyx HTTP client
  void initialize() {
    if (apiKey.isEmpty || messagingProfileId.isEmpty || fromNumber.isEmpty) {
      debugPrint('⚠️ Telnyx credentials not configured');
      return;
    }
    _httpClient = TelnyxHttpClient(
      apiKey: apiKey,
      messagingProfileId: messagingProfileId,
      fromNumber: fromNumber,
    );
    debugPrint('✅ TelnyxSMSService initialized');
  }

  /// Send SMS via Telnyx
  Future<SMSResult> sendSMS({
    required String toPhone,
    required String messageBody,
    required String messageCategory,
  }) async {
    try {
      if (_httpClient == null) {
        initialize();
        if (_httpClient == null) {
          return SMSResult(
            success: false,
            provider: 'telnyx',
            error: 'Telnyx not configured',
          );
        }
      }

      // Validate and format phone number
      final formattedPhone = _formatPhoneNumber(toPhone);
      if (formattedPhone == null) {
        return SMSResult(
          success: false,
          provider: 'telnyx',
          error: 'Invalid phone number format',
        );
      }

      // Send via HTTP client
      final result = await _httpClient!.sendMessage(
        toNumber: formattedPhone,
        messageBody: messageBody,
        messageType: messageCategory,
      );

      // Log delivery
      await _logDelivery(
        toPhone: formattedPhone,
        messageBody: messageBody,
        messageCategory: messageCategory,
        messageId: result.messageId,
        deliveryStatus: result.deliveryStatus ?? 'unknown',
        success: result.success,
        error: result.error,
      );

      return SMSResult(
        success: result.success,
        provider: 'telnyx',
        messageId: result.messageId,
        category: messageCategory,
        error: result.error,
      );
    } catch (e) {
      debugPrint('Telnyx SMS send error: $e');
      await _logDelivery(
        toPhone: toPhone,
        messageBody: messageBody,
        messageCategory: messageCategory,
        deliveryStatus: 'failed',
        success: false,
        error: e.toString(),
      );

      return SMSResult(
        success: false,
        provider: 'telnyx',
        category: messageCategory,
        error: e.toString(),
      );
    }
  }

  /// Check Telnyx service health
  Future<HealthCheckResult> healthCheck() async {
    try {
      if (_httpClient == null) {
        return HealthCheckResult(
          isHealthy: false,
          latencyMs: 0,
          lastCheck: DateTime.now(),
          error: 'Telnyx not initialized',
        );
      }

      final result = await _httpClient!.checkHealth();

      // Log health metric
      await _supabase.from('provider_health_metrics').insert({
        'provider_name': 'telnyx',
        'is_healthy': result.isHealthy,
        'latency_ms': result.latencyMs,
        'error_rate': result.isHealthy ? 0.0 : 100.0,
        'consecutive_failures': result.isHealthy ? 0 : 1,
        'last_error': result.error,
      });

      return HealthCheckResult(
        isHealthy: result.isHealthy,
        latencyMs: result.latencyMs,
        lastCheck: result.checkedAt,
        error: result.error,
      );
    } catch (e) {
      debugPrint('Telnyx health check error: $e');

      // Log failed health check
      await _supabase.from('provider_health_metrics').insert({
        'provider_name': 'telnyx',
        'is_healthy': false,
        'latency_ms': 0,
        'error_rate': 100.0,
        'consecutive_failures': 1,
        'last_error': e.toString(),
      });

      return HealthCheckResult(
        isHealthy: false,
        latencyMs: 0,
        lastCheck: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Format phone number to E.164 format
  String? _formatPhoneNumber(String phone) {
    // Remove all non-digit characters except +
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    // Check if already in E.164 format
    if (digits.startsWith('+') && digits.length >= 11 && digits.length <= 16) {
      return digits;
    }

    // Add + if missing and has valid length
    if (digits.length >= 10 && digits.length <= 15) {
      return '+$digits';
    }

    return null;
  }

  /// Log SMS delivery
  Future<void> _logDelivery({
    required String toPhone,
    required String messageBody,
    required String messageCategory,
    required String deliveryStatus,
    required bool success,
    String? messageId,
    String? error,
  }) async {
    try {
      await _supabase.from('sms_delivery_log').insert({
        'provider_used': 'telnyx',
        'message_category': messageCategory,
        'recipient_phone': toPhone,
        'message_body': messageBody,
        'delivery_status': deliveryStatus,
        'provider_message_id': messageId,
        'error_message': error,
      });
    } catch (e) {
      debugPrint('Failed to log SMS delivery: $e');
    }
  }
}

/// SMS Result
class SMSResult {
  final bool success;
  final String provider;
  final String? messageId;
  final String? category;
  final String? error;

  SMSResult({
    required this.success,
    required this.provider,
    this.messageId,
    this.category,
    this.error,
  });
}

/// Health Check Result
class HealthCheckResult {
  final bool isHealthy;
  final int latencyMs;
  final DateTime lastCheck;
  final String? error;

  HealthCheckResult({
    required this.isHealthy,
    required this.latencyMs,
    required this.lastCheck,
    this.error,
  });
}
