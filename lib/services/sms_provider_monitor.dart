import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import './telnyx_sms_service.dart';
import './claude_service.dart';
import './supabase_service.dart';

/// SMS Provider Monitor
/// AI-powered health monitoring with intelligent failover decisions
class SMSProviderMonitor {
  static SMSProviderMonitor? _instance;
  static SMSProviderMonitor get instance =>
      _instance ??= SMSProviderMonitor._();

  SMSProviderMonitor._();

  final _supabase = SupabaseService.instance.client;
  final _telnyxService = TelnyxSMSService.instance;
  final _claudeService = ClaudeService.instance;

  Timer? _monitoringTimer;
  String _currentProvider = 'telnyx';
  final StreamController<ProviderChangeEvent> _providerStream =
      StreamController.broadcast();

  /// Start continuous monitoring (every 60 seconds)
  void startMonitoring() {
    _monitoringTimer?.cancel();
    _loadCurrentProvider();
    _monitoringTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _performHealthCheck(),
    );
    debugPrint('✅ SMS Provider Monitor started');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    debugPrint('⏹️ SMS Provider Monitor stopped');
  }

  /// Get current provider
  String getCurrentProvider() => _currentProvider;

  /// Load current provider from database
  Future<void> _loadCurrentProvider() async {
    try {
      final result = await _supabase
          .from('sms_provider_state')
          .select('current_provider')
          .order('switched_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result != null) {
        _currentProvider = result['current_provider'] as String? ?? 'telnyx';
      }
      debugPrint('📱 Current SMS Provider: $_currentProvider');
    } catch (e) {
      debugPrint('Error loading current provider: $e');
    }
  }

  /// Perform health check and failover analysis
  Future<void> _performHealthCheck() async {
    try {
      // Check both providers
      final telnyxHealth = await _telnyxService.healthCheck();
      final twilioHealth = await _checkTwilioHealth();

      // Get recent health metrics
      final telnyxMetrics = await _getRecentHealthMetrics('telnyx');
      final twilioMetrics = await _getRecentHealthMetrics('twilio');

      // Analyze with Claude AI
      final analysis = await _analyzeHealthWithClaude(
        telnyxHealth: telnyxHealth,
        twilioHealth: twilioHealth,
        telnyxMetrics: telnyxMetrics,
        twilioMetrics: twilioMetrics,
        currentProvider: _currentProvider,
      );

      // Execute failover if recommended
      if (analysis['should_failover'] == true &&
          (analysis['confidence'] as num) > 0.85) {
        await _executeFailover(
          toProvider: analysis['recommended_provider'] as String,
          reason: analysis['reasoning'] as String,
          confidence: (analysis['confidence'] as num).toDouble(),
        );
      }

      // Check for restoration
      if (_currentProvider == 'twilio' && telnyxHealth.isHealthy) {
        await _checkTelnyxRestoration(telnyxMetrics);
      }
    } catch (e) {
      debugPrint('Health check error: $e');
    }
  }

  /// Check Twilio health (simplified)
  Future<Map<String, dynamic>> _checkTwilioHealth() async {
    try {
      // Twilio health check would go here
      // For now, assume healthy
      return {'is_healthy': true, 'latency_ms': 800, 'error_rate': 0.0};
    } catch (e) {
      return {'is_healthy': false, 'latency_ms': 5000, 'error_rate': 100.0};
    }
  }

  /// Get recent health metrics
  Future<List<Map<String, dynamic>>> _getRecentHealthMetrics(
    String provider,
  ) async {
    try {
      final response = await _supabase
          .from('provider_health_metrics')
          .select()
          .eq('provider_name', provider)
          .gte(
            'checked_at',
            DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
          )
          .order('checked_at', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Analyze health with Claude AI
  Future<Map<String, dynamic>> _analyzeHealthWithClaude({
    required HealthCheckResult telnyxHealth,
    required Map<String, dynamic> twilioHealth,
    required List<Map<String, dynamic>> telnyxMetrics,
    required List<Map<String, dynamic>> twilioMetrics,
    required String currentProvider,
  }) async {
    try {
      final consecutiveTelnyxFailures = telnyxMetrics
          .where((m) => m['is_healthy'] == false)
          .length;
      final avgTelnyxLatency = telnyxMetrics.isEmpty
          ? 0
          : telnyxMetrics
                    .map((m) => m['latency_ms'] as int)
                    .reduce((a, b) => a + b) ~/
                telnyxMetrics.length;

      final prompt =
          '''
Analyze SMS provider health and determine if failover is needed.

**Current Provider**: $currentProvider

**Telnyx Health**:
- Healthy: ${telnyxHealth.isHealthy}
- Latency: ${telnyxHealth.latencyMs}ms
- Consecutive Failures: $consecutiveTelnyxFailures
- Average Latency (5 checks): ${avgTelnyxLatency}ms
- Error: ${telnyxHealth.error ?? 'None'}

**Twilio Health**:
- Healthy: ${twilioHealth['is_healthy']}
- Latency: ${twilioHealth['latency_ms']}ms

**Failover Criteria**:
- Telnyx failure: 3+ consecutive failures OR latency > 5000ms OR error rate > 20%
- Telnyx restoration: 3+ consecutive successes AND latency < 2000ms AND error rate < 5%

**Decision Required**:
1. Should we failover? (yes/no with confidence 0-1)
2. Which provider to use? (telnyx/twilio)
3. Reasoning (brief explanation)

Return JSON only:
{
  "should_failover": true/false,
  "confidence": 0.0-1.0,
  "recommended_provider": "telnyx" or "twilio",
  "reasoning": "brief explanation"
}''';

      final response = await _claudeService.callClaudeAPI(prompt);
      return _parseClaudeResponse(response);
    } catch (e) {
      debugPrint('Claude analysis error: $e');
      return {
        'should_failover': false,
        'confidence': 0.0,
        'recommended_provider': currentProvider,
        'reasoning': 'Analysis failed',
      };
    }
  }

  /// Parse Claude response
  Map<String, dynamic> _parseClaudeResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        return Map<String, dynamic>.from(jsonDecode(jsonStr));
      }
    } catch (e) {
      debugPrint('Failed to parse Claude response: $e');
    }

    return {
      'should_failover': false,
      'confidence': 0.0,
      'recommended_provider': _currentProvider,
      'reasoning': 'Parse error',
    };
  }

  /// Execute failover
  Future<void> _executeFailover({
    required String toProvider,
    required String reason,
    required double confidence,
  }) async {
    try {
      debugPrint('🔄 Executing failover to $toProvider');

      final previousProvider = _currentProvider;

      // Update provider state
      await _supabase.from('sms_provider_state').insert({
        'current_provider': toProvider,
        'previous_provider': previousProvider,
        'switch_reason': reason,
        'is_manual_override': false,
      });

      // Log failover event
      await _supabase.from('provider_failover_log').insert({
        'from_provider': previousProvider,
        'to_provider': toProvider,
        'failover_reason': reason,
        'confidence_score': confidence,
        'triggered_by': 'automatic',
      });

      _currentProvider = toProvider;

      // Notify admins
      await _notifyAdmins(
        'SMS Provider Failover',
        'Switched from $previousProvider to $toProvider. Reason: $reason',
      );

      // Broadcast event
      _providerStream.add(
        ProviderChangeEvent(
          fromProvider: previousProvider,
          toProvider: toProvider,
          reason: reason,
          timestamp: DateTime.now(),
        ),
      );

      debugPrint('✅ Failover completed: $previousProvider → $toProvider');
    } catch (e) {
      debugPrint('Failover execution error: $e');
    }
  }

  /// Check Telnyx restoration
  Future<void> _checkTelnyxRestoration(
    List<Map<String, dynamic>> telnyxMetrics,
  ) async {
    try {
      // Check if Telnyx is stable
      final consecutiveSuccesses = telnyxMetrics
          .where((m) => m['is_healthy'] == true)
          .length;
      final avgLatency = telnyxMetrics.isEmpty
          ? 0
          : telnyxMetrics
                    .map((m) => m['latency_ms'] as int)
                    .reduce((a, b) => a + b) ~/
                telnyxMetrics.length;

      if (consecutiveSuccesses >= 3 && avgLatency < 2000) {
        // Request Claude confirmation
        final prompt =
            '''
Telnyx service appears restored. Confirm stability:

- Consecutive successes: $consecutiveSuccesses
- Average latency: ${avgLatency}ms
- Current provider: $_currentProvider

Should we restore Telnyx as primary? Return JSON:
{
  "should_restore": true/false,
  "confidence": 0.0-1.0,
  "reasoning": "brief explanation"
}''';

        final response = await _claudeService.callClaudeAPI(prompt);
        final analysis = _parseClaudeResponse(response);

        if (analysis['should_restore'] == true &&
            (analysis['confidence'] as num) > 0.90) {
          await _executeRestoration(
            reason: analysis['reasoning'] as String,
            confidence: (analysis['confidence'] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      debugPrint('Restoration check error: $e');
    }
  }

  /// Execute restoration to Telnyx
  Future<void> _executeRestoration({
    required String reason,
    required double confidence,
  }) async {
    try {
      debugPrint('🔄 Restoring Telnyx as primary provider');

      await _executeFailover(
        toProvider: 'telnyx',
        reason: 'Telnyx service restored: $reason',
        confidence: confidence,
      );

      // Process queued gamification messages
      await _processQueuedMessages();

      debugPrint('✅ Telnyx restoration completed');
    } catch (e) {
      debugPrint('Restoration error: $e');
    }
  }

  /// Process queued gamification messages
  Future<void> _processQueuedMessages() async {
    try {
      final queuedMessages = await _supabase
          .from('blocked_sms_log')
          .select()
          .eq('resend_status', 'pending')
          .order('blocked_at', ascending: true)
          .limit(100);

      final messages = List<Map<String, dynamic>>.from(queuedMessages);

      debugPrint('📤 Processing ${messages.length} queued messages');

      for (final msg in messages) {
        try {
          final result = await _telnyxService.sendSMS(
            toPhone: msg['recipient_phone'] as String,
            messageBody: msg['message_body'] as String,
            messageCategory: msg['message_category'] as String,
          );

          // Update status
          await _supabase
              .from('blocked_sms_log')
              .update({
                'resend_status': result.success ? 'sent' : 'failed',
                'resent_at': DateTime.now().toIso8601String(),
              })
              .eq('id', msg['id']);
        } catch (e) {
          debugPrint('Failed to resend message ${msg['id']}: $e');
        }
      }
    } catch (e) {
      debugPrint('Queue processing error: $e');
    }
  }

  /// Notify admins
  Future<void> _notifyAdmins(String title, String message) async {
    try {
      // Log to system_alerts
      await _supabase.from('system_alerts').insert({
        'alert_type': 'sms_provider_failover',
        'severity': 'high',
        'title': title,
        'message': message,
      });

      debugPrint('📧 Admin notification sent: $title');
    } catch (e) {
      debugPrint('Admin notification error: $e');
    }
  }

  /// Get provider stream
  Stream<ProviderChangeEvent> getProviderStream() => _providerStream.stream;

  /// Manual failover
  Future<bool> manualFailover(String toProvider) async {
    try {
      await _executeFailover(
        toProvider: toProvider,
        reason: 'Manual failover by admin',
        confidence: 1.0,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider Change Event
class ProviderChangeEvent {
  final String fromProvider;
  final String toProvider;
  final String reason;
  final DateTime timestamp;

  ProviderChangeEvent({
    required this.fromProvider,
    required this.toProvider,
    required this.reason,
    required this.timestamp,
  });
}
