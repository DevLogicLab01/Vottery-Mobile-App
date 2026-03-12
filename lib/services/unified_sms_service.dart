import 'dart:async';
import 'package:flutter/foundation.dart';
import './telnyx_sms_service.dart';
import './twilio_notification_service.dart';
import './sms_provider_monitor.dart';
import './claude_service.dart';
import './supabase_service.dart';

/// Unified SMS Service
/// Orchestrates Telnyx/Twilio routing with gamification filtering
class UnifiedSMSService {
  static UnifiedSMSService? _instance;
  static UnifiedSMSService get instance => _instance ??= UnifiedSMSService._();

  UnifiedSMSService._();

  final _telnyxService = TelnyxSMSService.instance;
  final _twilioService = TwilioNotificationService.instance;
  final _providerMonitor = SMSProviderMonitor.instance;
  final _claudeService = ClaudeService.instance;
  final _supabase = SupabaseService.instance.client;

  bool _initialized = false;

  /// Initialize service
  Future<void> initialize() async {
    if (_initialized) return;

    _telnyxService.initialize();
    await _twilioService.initialize();
    _providerMonitor.startMonitoring();
    _initialized = true;

    debugPrint('✅ UnifiedSMSService initialized');
  }

  /// Send SMS with intelligent routing
  Future<SMSSendResult> sendSMS({
    required String toPhone,
    required String messageBody,
    String? messageType,
  }) async {
    try {
      // Categorize message if type not provided
      final category = messageType ?? await _categorizeMessage(messageBody);

      // Get current provider
      final currentProvider = _providerMonitor.getCurrentProvider();

      // Check gamification filter
      if (currentProvider == 'twilio' && category == 'gamification') {
        return await _blockGamificationMessage(
          toPhone: toPhone,
          messageBody: messageBody,
          category: category,
        );
      }

      // Route to appropriate provider
      if (currentProvider == 'telnyx') {
        return await _sendViaTelnyx(
          toPhone: toPhone,
          messageBody: messageBody,
          category: category,
        );
      } else {
        return await _sendViaTwilio(
          toPhone: toPhone,
          messageBody: messageBody,
          category: category,
        );
      }
    } catch (e) {
      debugPrint('UnifiedSMSService send error: $e');
      return SMSSendResult(
        success: false,
        provider: 'none',
        error: e.toString(),
      );
    }
  }

  /// Categorize message using Claude AI
  Future<String> _categorizeMessage(String messageBody) async {
    try {
      final prompt =
          '''
Categorize this SMS message into ONE category:

Message: "$messageBody"

Categories:
- operational: Account alerts, security notifications, payment confirmations, 2FA codes
- gamification: Lottery winners, prize notifications, contest results, election winners, reward alerts
- marketing: Promotional messages, campaign updates, newsletters
- support: Customer service, password resets, account recovery

Return ONLY the category name (lowercase, no explanation).''';

      final response = await _claudeService.callClaudeAPI(prompt);
      final category = response.trim().toLowerCase();

      // Validate category
      if ([
        'operational',
        'gamification',
        'marketing',
        'support',
      ].contains(category)) {
        return category;
      }

      return 'operational'; // Default
    } catch (e) {
      debugPrint('Message categorization error: $e');
      return 'operational'; // Default on error
    }
  }

  /// Send via Telnyx
  Future<SMSSendResult> _sendViaTelnyx({
    required String toPhone,
    required String messageBody,
    required String category,
  }) async {
    final result = await _telnyxService.sendSMS(
      toPhone: toPhone,
      messageBody: messageBody,
      messageCategory: category,
    );

    return SMSSendResult(
      success: result.success,
      provider: 'telnyx',
      messageId: result.messageId,
      category: category,
      error: result.error,
    );
  }

  /// Send via Twilio
  Future<SMSSendResult> _sendViaTwilio({
    required String toPhone,
    required String messageBody,
    required String category,
  }) async {
    try {
      final success = await _twilioService.sendUserActivityNotification(
        phoneNumber: toPhone,
        activityType: 'SMS Alert',
        details: messageBody,
      );

      // Log delivery
      await _supabase.from('sms_delivery_log').insert({
        'provider_used': 'twilio',
        'message_category': category,
        'recipient_phone': toPhone,
        'message_body': messageBody,
        'delivery_status': success ? 'sent' : 'failed',
      });

      return SMSSendResult(
        success: success,
        provider: 'twilio',
        category: category,
        error: success ? null : 'Twilio send failed',
      );
    } catch (e) {
      return SMSSendResult(
        success: false,
        provider: 'twilio',
        category: category,
        error: e.toString(),
      );
    }
  }

  /// Block gamification message on Twilio
  Future<SMSSendResult> _blockGamificationMessage({
    required String toPhone,
    required String messageBody,
    required String category,
  }) async {
    try {
      debugPrint('⛔ Blocking gamification SMS on Twilio fallback');

      // Log blocked message
      await _supabase.from('blocked_sms_log').insert({
        'message_category': category,
        'recipient_phone': toPhone,
        'message_body': messageBody,
        'provider_when_blocked': 'twilio',
        'resend_status': 'pending',
      });

      return SMSSendResult(
        success: false,
        provider: 'twilio',
        category: category,
        blocked: true,
        error: 'Gamification SMS blocked on Twilio fallback',
      );
    } catch (e) {
      return SMSSendResult(
        success: false,
        provider: 'twilio',
        category: category,
        error: 'Failed to block message: $e',
      );
    }
  }

  /// Get delivery statistics
  Future<Map<String, dynamic>> getDeliveryStats() async {
    try {
      final response = await _supabase
          .from('sms_delivery_log')
          .select()
          .gte(
            'sent_at',
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          );

      final logs = List<Map<String, dynamic>>.from(response);

      final telnyxCount = logs
          .where((l) => l['provider_used'] == 'telnyx')
          .length;
      final twilioCount = logs
          .where((l) => l['provider_used'] == 'twilio')
          .length;
      final successCount = logs
          .where(
            (l) =>
                l['delivery_status'] == 'sent' ||
                l['delivery_status'] == 'delivered',
          )
          .length;

      return {
        'total_sent': logs.length,
        'telnyx_count': telnyxCount,
        'twilio_count': twilioCount,
        'success_rate': logs.isEmpty
            ? 0.0
            : (successCount / logs.length * 100).toStringAsFixed(1),
        'by_category': _groupByCategory(logs),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Group logs by category
  Map<String, int> _groupByCategory(List<Map<String, dynamic>> logs) {
    final grouped = <String, int>{};
    for (final log in logs) {
      final category = log['message_category'] ?? 'unknown';
      grouped[category] = (grouped[category] ?? 0) + 1;
    }
    return grouped;
  }

  /// Get blocked messages
  Future<List<Map<String, dynamic>>> getBlockedMessages() async {
    try {
      final response = await _supabase
          .from('blocked_sms_log')
          .select()
          .eq('resend_status', 'pending')
          .order('blocked_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get failover history
  Future<List<Map<String, dynamic>>> getFailoverHistory() async {
    try {
      final response = await _supabase
          .from('provider_failover_log')
          .select()
          .order('failed_at', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Manual provider switch
  Future<bool> switchProvider(String toProvider) async {
    return await _providerMonitor.manualFailover(toProvider);
  }

  /// Get current provider
  String getCurrentProvider() => _providerMonitor.getCurrentProvider();

  /// Subscribe to provider changes
  Stream<ProviderChangeEvent> getProviderChangeStream() {
    return _providerMonitor.getProviderStream();
  }
}

/// SMS Send Result
class SMSSendResult {
  final bool success;
  final String provider;
  final String? messageId;
  final String? category;
  final bool blocked;
  final String? error;

  SMSSendResult({
    required this.success,
    required this.provider,
    this.messageId,
    this.category,
    this.blocked = false,
    this.error,
  });
}
