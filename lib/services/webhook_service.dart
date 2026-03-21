import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import './supabase_service.dart';
import './auth_service.dart';
import './supabase_query_cache_service.dart';

/// Webhook Service for lottery event delivery and management
class WebhookService {
  static WebhookService? _instance;
  static WebhookService get instance => _instance ??= WebhookService._();

  WebhookService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 1);

  /// Create webhook configuration
  Future<Map<String, dynamic>?> createWebhookConfiguration({
    String? name,
    required String webhookUrl,
    required List<String> eventTypes,
    String? description,
    bool retryEnabled = true,
    int maxRetries = 5,
    int timeoutSeconds = 30,
    Map<String, String>? customHeaders,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final userId = _auth.currentUser!.id;
      final secretKey = _generateSecretKey();

      final response = await _client
          .from('webhook_configurations')
          .insert({
            'user_id': userId,
            'name': name,
            'webhook_url': webhookUrl,
            'event_types': eventTypes,
            'description': description,
            'retry_enabled': retryEnabled,
            'max_retries': maxRetries,
            'timeout_seconds': timeoutSeconds,
            'secret_key': secretKey,
            'custom_headers': customHeaders ?? {},
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Create webhook configuration error: $e');
      return null;
    }
  }

  /// Get webhook configurations for current user
  Future<List<Map<String, dynamic>>> getWebhookConfigurations() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('webhook_configurations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get webhook configurations error: $e');
      return [];
    }
  }

  /// Update webhook configuration
  Future<bool> updateWebhookConfiguration({
    required String configId,
    String? webhookUrl,
    List<String>? eventTypes,
    bool? isActive,
    String? description,
    Map<String, String>? customHeaders,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final updates = <String, dynamic>{};
      if (webhookUrl != null) updates['webhook_url'] = webhookUrl;
      if (eventTypes != null) updates['event_types'] = eventTypes;
      if (isActive != null) updates['is_active'] = isActive;
      if (description != null) updates['description'] = description;
      if (customHeaders != null) updates['custom_headers'] = customHeaders;

      await _client
          .from('webhook_configurations')
          .update(updates)
          .eq('id', configId);

      return true;
    } catch (e) {
      debugPrint('Update webhook configuration error: $e');
      return false;
    }
  }

  /// Delete webhook configuration
  Future<bool> deleteWebhookConfiguration(String configId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('webhook_configurations').delete().eq('id', configId);

      return true;
    } catch (e) {
      debugPrint('Delete webhook configuration error: $e');
      return false;
    }
  }

  /// Trigger webhook for lottery event
  Future<bool> triggerWebhook({
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final configs = await _client
          .from('webhook_configurations')
          .select()
          .eq('is_active', true)
          .contains('event_types', [eventType]);

      for (var config in configs) {
        await _deliverWebhook(
          configId: config['id'],
          eventType: eventType,
          payload: payload,
          webhookUrl: config['webhook_url'],
          secretKey: config['secret_key'],
          customHeaders: Map<String, String>.from(
            config['custom_headers'] ?? {},
          ),
          timeoutSeconds: config['timeout_seconds'],
        );
      }

      return true;
    } catch (e) {
      debugPrint('Trigger webhook error: $e');
      return false;
    }
  }

  /// Deliver webhook with retry logic
  Future<void> _deliverWebhook({
    required String configId,
    required String eventType,
    required Map<String, dynamic> payload,
    required String webhookUrl,
    required String secretKey,
    required Map<String, String> customHeaders,
    required int timeoutSeconds,
  }) async {
    try {
      final signature = _generateHMACSignature(payload, secretKey);
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final idempotencyKey = _buildIdempotencyKey(
        configId: configId,
        eventType: eventType,
        payload: payload,
        timestamp: timestamp,
      );

      final logId = await _createDeliveryLog(
        configId: configId,
        eventType: eventType,
        payload: payload,
      );
      final requestBody = jsonEncode(payload);

      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        final stopwatch = Stopwatch()..start();
        try {
          final response = await http
              .post(
                Uri.parse(webhookUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'X-Vottery-Event': eventType,
                  'X-Vottery-Timestamp': timestamp,
                  'X-Vottery-Attempt': '$attempt',
                  'X-Vottery-Signature': signature,
                  'Idempotency-Key': idempotencyKey,
                  ...customHeaders,
                },
                body: requestBody,
              )
              .timeout(Duration(seconds: timeoutSeconds));
          stopwatch.stop();

          final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
          final shouldRetry = !isSuccess && response.statusCode >= 500 && attempt < _maxRetries;

          if (isSuccess) {
            await _updateDeliveryLog(
              logId: logId,
              status: 'delivered',
              httpStatusCode: response.statusCode,
              responseBody: response.body,
              attemptCount: attempt,
              responseTimeMs: stopwatch.elapsedMilliseconds,
            );
            SupabaseQueryCacheService.instance
                .onWebhookDeliveryLogged(webhookId: configId);
            return;
          }

          await _updateDeliveryLog(
            logId: logId,
            status: shouldRetry ? 'retrying' : 'failed',
            httpStatusCode: response.statusCode,
            responseBody: response.body,
            errorMessage: 'HTTP ${response.statusCode}',
            attemptCount: attempt,
            responseTimeMs: stopwatch.elapsedMilliseconds,
          );

          if (shouldRetry) {
            await Future.delayed(_retryDelayForAttempt(attempt));
            continue;
          }
          SupabaseQueryCacheService.instance
              .onWebhookDeliveryLogged(webhookId: configId);
          return;
        } catch (deliveryError) {
          stopwatch.stop();
          final shouldRetry = attempt < _maxRetries;
          await _updateDeliveryLog(
            logId: logId,
            status: shouldRetry ? 'retrying' : 'failed',
            errorMessage: deliveryError.toString(),
            attemptCount: attempt,
            responseTimeMs: stopwatch.elapsedMilliseconds,
          );
          if (shouldRetry) {
            await Future.delayed(_retryDelayForAttempt(attempt));
            continue;
          }
          SupabaseQueryCacheService.instance
              .onWebhookDeliveryLogged(webhookId: configId);
          return;
        }
      }
    } catch (e) {
      debugPrint('Deliver webhook error: $e');
    }
  }

  /// Create delivery log entry
  Future<String> _createDeliveryLog({
    required String configId,
    required String eventType,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _client
        .from('webhook_delivery_logs')
        .insert({
          'webhook_config_id': configId,
          'webhook_id': configId,
          'event_type': eventType,
          'payload': payload,
          'delivery_status': 'pending',
          'status': 'pending',
          'attempt_count': 1,
          'attempts': 1,
        })
        .select('id')
        .single();

    return response['id'];
  }

  /// Update delivery log
  Future<void> _updateDeliveryLog({
    required String logId,
    required String status,
    int? httpStatusCode,
    String? responseBody,
    String? errorMessage,
    int? attemptCount,
    int? responseTimeMs,
  }) async {
    final updates = <String, dynamic>{
      'delivery_status': status,
      'status': status,
    };

    if (httpStatusCode != null) updates['http_status_code'] = httpStatusCode;
    if (httpStatusCode != null) updates['status_code'] = httpStatusCode;
    if (responseBody != null) updates['response_body'] = responseBody;
    if (errorMessage != null) updates['error_message'] = errorMessage;
    if (attemptCount != null) {
      updates['attempt_count'] = attemptCount;
      updates['attempts'] = attemptCount;
    }
    if (responseTimeMs != null) {
      updates['response_time_ms'] = responseTimeMs;
      updates['duration_ms'] = responseTimeMs;
    }
    if (status == 'success' || status == 'delivered') {
      updates['delivered_at'] = DateTime.now().toIso8601String();
    }

    await _client.from('webhook_delivery_logs').update(updates).eq('id', logId);
  }

  /// Get webhook delivery logs
  Future<List<Map<String, dynamic>>> getDeliveryLogs({
    String? configId,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('webhook_delivery_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      if (configId != null && configId.isNotEmpty) {
        query = query.eq('webhook_config_id', configId);
      }
      final response = await query;

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get delivery logs error: $e');
      return [];
    }
  }

  /// Get webhook delivery analytics
  Future<Map<String, dynamic>> getDeliveryAnalytics({
    required String configId,
    int days = 30,
  }) async {
    try {
      final response = await _client.rpc(
        'get_webhook_delivery_analytics',
        params: {'p_webhook_config_id': configId, 'p_days': days},
      );

      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response.first);
      }

      return {
        'total_deliveries': 0,
        'successful_deliveries': 0,
        'failed_deliveries': 0,
        'success_rate': 0.0,
        'average_response_time': 0.0,
        'retry_count': 0,
      };
    } catch (e) {
      debugPrint('Get delivery analytics error: $e');
      return {
        'total_deliveries': 0,
        'successful_deliveries': 0,
        'failed_deliveries': 0,
        'success_rate': 0.0,
        'average_response_time': 0.0,
        'retry_count': 0,
      };
    }
  }

  /// Test webhook with sample payload
  Future<Map<String, dynamic>> testWebhook({required String configId}) async {
    try {
      final config = await _client
          .from('webhook_configurations')
          .select()
          .eq('id', configId)
          .maybeSingle();
      if (config == null) {
        return {'success': false, 'message': 'Webhook configuration not found'};
      }

      final testPayload = {
        'event_type': 'test',
        'timestamp': DateTime.now().toIso8601String(),
        'data': {'message': 'This is a test webhook delivery'},
      };

      await _deliverWebhook(
        configId: configId,
        eventType: 'test.webhook',
        payload: testPayload,
        webhookUrl: config['webhook_url']?.toString() ?? '',
        secretKey: config['secret_key']?.toString() ?? '',
        customHeaders: Map<String, String>.from(config['custom_headers'] ?? {}),
        timeoutSeconds: (config['timeout_seconds'] as int?) ?? 30,
      );

      return {'success': true, 'message': 'Test webhook sent successfully'};
    } catch (e) {
      debugPrint('Test webhook error: $e');
      return {'success': false, 'message': 'Test webhook failed: $e'};
    }
  }

  /// Retry a failed delivery using its original webhook configuration.
  Future<Map<String, dynamic>> retryDelivery({required String logId}) async {
    try {
      final log = await _client
          .from('webhook_delivery_logs')
          .select()
          .eq('id', logId)
          .maybeSingle();
      if (log == null) {
        return {'success': false, 'message': 'Delivery log not found'};
      }

      final configId = log['webhook_config_id']?.toString();
      if (configId == null || configId.isEmpty) {
        return {'success': false, 'message': 'Missing webhook configuration id'};
      }

      final config = await _client
          .from('webhook_configurations')
          .select()
          .eq('id', configId)
          .maybeSingle();
      if (config == null) {
        return {'success': false, 'message': 'Webhook configuration not found'};
      }

      await _deliverWebhook(
        configId: configId,
        eventType: log['event_type']?.toString() ?? 'retry.webhook',
        payload: Map<String, dynamic>.from(log['payload'] ?? {}),
        webhookUrl: config['webhook_url']?.toString() ?? '',
        secretKey: config['secret_key']?.toString() ?? '',
        customHeaders: Map<String, String>.from(config['custom_headers'] ?? {}),
        timeoutSeconds: (config['timeout_seconds'] as int?) ?? 30,
      );

      return {'success': true, 'message': 'Retry initiated successfully'};
    } catch (e) {
      debugPrint('Retry delivery error: $e');
      return {'success': false, 'message': 'Retry failed: $e'};
    }
  }

  /// Generate HMAC signature for webhook security
  String _generateHMACSignature(
    Map<String, dynamic> payload,
    String secretKey,
  ) {
    final payloadString = jsonEncode(payload);
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(payloadString);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Generate random secret key
  String _generateSecretKey() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = sha256.convert(bytes);
    return 'whsec_${digest.toString().substring(0, 32)}';
  }

  Duration _retryDelayForAttempt(int attempt) {
    final exponent = attempt - 1;
    final multiplier = 1 << exponent;
    return Duration(seconds: _baseRetryDelay.inSeconds * multiplier);
  }

  String _buildIdempotencyKey({
    required String configId,
    required String eventType,
    required Map<String, dynamic> payload,
    required String timestamp,
  }) {
    final raw = '$configId|$eventType|$timestamp|${jsonEncode(payload)}';
    return sha256.convert(utf8.encode(raw)).toString();
  }
}
