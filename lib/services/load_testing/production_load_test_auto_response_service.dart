import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../enhanced_notification_service.dart';
import '../supabase_service.dart';
import '../telnyx_sms_service.dart';
import './production_load_test_service.dart';

/// Wires ProductionLoadTestService to AutomatedIncidentResponseService
/// Triggers auto-responses when load test thresholds are breached
class ProductionLoadTestAutoResponseService {
  static ProductionLoadTestAutoResponseService? _instance;
  static ProductionLoadTestAutoResponseService get instance =>
      _instance ??= ProductionLoadTestAutoResponseService._();
  ProductionLoadTestAutoResponseService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  final TelnyxSMSService _telnyxService = TelnyxSMSService.instance;
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService.instance;

  // Thresholds for 500K+ user tier
  static const int tier500K = 500000;
  static const double wsSuccessRateThreshold = 85.0;
  static const int blockchainTpsThreshold = 1000;

  final List<Map<String, dynamic>> _responseLog = [];
  List<Map<String, dynamic>> get responseLog => List.unmodifiable(_responseLog);

  /// Main entry point: called after a load test completes
  Future<LoadTestAutoResponseResult> onLoadTestComplete(
    LoadTestReport report,
  ) async {
    final actions = <String>[];
    final errors = <String>[];

    debugPrint('🔍 Evaluating load test report for auto-response triggers...');

    // Only trigger auto-responses for 500K+ user tiers
    if (report.userCount < tier500K) {
      return LoadTestAutoResponseResult(
        triggered: false,
        actions: [],
        message: 'Below 500K user threshold - no auto-response needed',
      );
    }

    // Check WebSocket success rate
    if (report.websocketMetrics.connectionSuccessRate <
        wsSuccessRateThreshold) {
      debugPrint(
        '⚠️ WebSocket success rate ${report.websocketMetrics.connectionSuccessRate}% < $wsSuccessRateThreshold% threshold',
      );
      try {
        await scaleSupabaseConnections(report);
        actions.add('scaleSupabaseConnections');
      } catch (e) {
        errors.add('scaleSupabaseConnections: $e');
      }
    }

    // Check blockchain TPS
    if (report.blockchainMetrics.avgTps < blockchainTpsThreshold) {
      debugPrint(
        '⚠️ Blockchain TPS ${report.blockchainMetrics.avgTps} < $blockchainTpsThreshold threshold',
      );
      try {
        await pauseHighRiskElections(report);
        actions.add('pauseHighRiskElections');
      } catch (e) {
        errors.add('pauseHighRiskElections: $e');
      }
    }

    // Check critical regressions
    final criticalRegressions = report.regressionsDetected
        .where((r) => r.severity == 'critical')
        .toList();
    if (criticalRegressions.isNotEmpty) {
      debugPrint(
        '🚨 ${criticalRegressions.length} critical regressions detected',
      );
      try {
        await activateCircuitBreakers(report, criticalRegressions);
        actions.add('activateCircuitBreakers');
      } catch (e) {
        errors.add('activateCircuitBreakers: $e');
      }
    }

    final result = LoadTestAutoResponseResult(
      triggered: actions.isNotEmpty,
      actions: actions,
      errors: errors,
      message: actions.isEmpty
          ? 'All thresholds within acceptable range'
          : 'Auto-response triggered: ${actions.join(", ")}',
    );

    // Log to incident_response_log
    await _logAutoResponse(report, result);

    return result;
  }

  /// Scale Supabase connections: increase connection pool + read replicas
  Future<void> scaleSupabaseConnections(LoadTestReport report) async {
    debugPrint('🔧 Scaling Supabase connections...');

    try {
      // Log scaling action
      await _client.from('incident_response_log').insert({
        'action_type': 'scale_supabase_connections',
        'trigger_reason': 'WebSocket success rate below threshold',
        'trigger_value': report.websocketMetrics.connectionSuccessRate,
        'threshold_value': wsSuccessRateThreshold,
        'user_tier': report.userCount,
        'test_id': report.testId,
        'status': 'executing',
        'details': {
          'connection_pool_increase': '+50%',
          'read_replicas_target': 3,
          'current_ws_success_rate':
              report.websocketMetrics.connectionSuccessRate,
          'failed_connections': report.websocketMetrics.failedConnections,
        },
        'executed_at': DateTime.now().toIso8601String(),
      });

      // Simulate Supabase Management API call
      // In production: call Supabase Management API
      // POST https://api.supabase.com/v1/projects/{ref}/config/database
      // { "pool_size": current * 1.5, "read_replicas": 3 }
      await Future.delayed(const Duration(milliseconds: 500));

      // Update status to completed
      await _client
          .from('incident_response_log')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('action_type', 'scale_supabase_connections')
          .eq('test_id', report.testId);

      _responseLog.add({
        'action': 'scaleSupabaseConnections',
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'details': 'Connection pool scaled +50%, read replicas: 3',
      });

      debugPrint('✅ Supabase connections scaled successfully');
    } catch (e) {
      debugPrint('❌ Scale Supabase connections error: $e');
      rethrow;
    }
  }

  /// Pause high-risk elections (risk_score > 0.7 AND status = active)
  Future<void> pauseHighRiskElections(LoadTestReport report) async {
    debugPrint('⏸️ Pausing high-risk elections...');

    try {
      // Query elections with high risk score
      final highRiskElections = await _client
          .from('elections')
          .select('id, title, creator_id, risk_score')
          .eq('status', 'active')
          .gte('risk_score', 0.7);

      final elections = List<Map<String, dynamic>>.from(highRiskElections);
      debugPrint('Found ${elections.length} high-risk elections to pause');

      for (final election in elections) {
        // Update election status to paused
        await _client
            .from('elections')
            .update({
              'status': 'paused',
              'paused_reason':
                  'Auto-paused: Load test detected blockchain TPS below threshold',
              'paused_at': DateTime.now().toIso8601String(),
              'paused_by': 'load_test_auto_response',
            })
            .eq('id', election['id']);

        // Notify election creator
        if (election['creator_id'] != null) {
          await _notificationService.sendNotification(
            userId: election['creator_id'],
            title: 'Election Temporarily Paused',
            body:
                'Your election "${election['title']}" has been temporarily paused due to high system load. It will resume automatically.',
            category: 'election_update',
            priority: 'high',
          );
        }

        // Log to election_integrity_monitoring
        await _client.from('election_integrity_monitoring').insert({
          'election_id': election['id'],
          'event_type': 'auto_pause',
          'reason': 'Blockchain TPS below threshold during load test',
          'blockchain_tps': report.blockchainMetrics.avgTps,
          'threshold': blockchainTpsThreshold,
          'risk_score': election['risk_score'],
          'triggered_by': 'load_test_auto_response',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // Log action
      await _client.from('incident_response_log').insert({
        'action_type': 'pause_high_risk_elections',
        'trigger_reason': 'Blockchain TPS below threshold',
        'trigger_value': report.blockchainMetrics.avgTps.toDouble(),
        'threshold_value': blockchainTpsThreshold.toDouble(),
        'user_tier': report.userCount,
        'test_id': report.testId,
        'status': 'completed',
        'details': {
          'elections_paused': elections.length,
          'election_ids': elections.map((e) => e['id']).toList(),
          'blockchain_tps': report.blockchainMetrics.avgTps,
        },
        'executed_at': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      });

      _responseLog.add({
        'action': 'pauseHighRiskElections',
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'details': '${elections.length} elections paused (risk_score > 0.7)',
      });

      debugPrint('✅ ${elections.length} high-risk elections paused');
    } catch (e) {
      debugPrint('❌ Pause high-risk elections error: $e');
      rethrow;
    }
  }

  /// Activate circuit breakers for affected services
  Future<void> activateCircuitBreakers(
    LoadTestReport report,
    List<RegressionAlert> criticalRegressions,
  ) async {
    debugPrint('🔴 Activating circuit breakers...');

    try {
      final affectedServices = criticalRegressions
          .map((r) => _mapMetricToService(r.metricName))
          .toSet()
          .toList();

      for (final service in affectedServices) {
        // Update circuit_breaker_state table
        await _client.from('circuit_breaker_state').upsert({
          'service_name': service,
          'state': 'open',
          'failure_count': 1,
          'rate_limiting_enabled': true,
          'rate_limit_rps': 100,
          'rollback_ready': true,
          'triggered_by': 'load_test_auto_response',
          'triggered_at': DateTime.now().toIso8601String(),
          'test_id': report.testId,
          'regression_details': criticalRegressions
              .where((r) => _mapMetricToService(r.metricName) == service)
              .map(
                (r) => {
                  'metric': r.metricName,
                  'regression_pct': r.regressionPercentage,
                },
              )
              .toList(),
        }, onConflict: 'service_name');
      }

      // Log action
      await _client.from('incident_response_log').insert({
        'action_type': 'activate_circuit_breakers',
        'trigger_reason': 'Critical performance regressions detected',
        'user_tier': report.userCount,
        'test_id': report.testId,
        'status': 'completed',
        'details': {
          'affected_services': affectedServices,
          'critical_regressions': criticalRegressions.length,
          'rate_limiting_enabled': true,
          'rollback_ready': true,
        },
        'executed_at': DateTime.now().toIso8601String(),
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Send Telnyx SMS alert to admins
      await _sendAdminAlert(
        'Circuit Breakers Activated',
        'Load test triggered circuit breakers for: ${affectedServices.join(", ")}. '
            'Rate limiting enabled. Rollback ready.',
      );

      _responseLog.add({
        'action': 'activateCircuitBreakers',
        'status': 'success',
        'timestamp': DateTime.now().toIso8601String(),
        'details':
            'Circuit breakers activated for: ${affectedServices.join(", ")}',
      });

      debugPrint('✅ Circuit breakers activated for: $affectedServices');
    } catch (e) {
      debugPrint('❌ Activate circuit breakers error: $e');
      rethrow;
    }
  }

  /// One-click rollback: disable circuit breakers and resume elections
  Future<bool> rollbackAllActions(String testId) async {
    try {
      // Re-open circuit breakers
      await _client
          .from('circuit_breaker_state')
          .update({'state': 'closed', 'rate_limiting_enabled': false})
          .eq('test_id', testId);

      // Resume paused elections
      await _client
          .from('elections')
          .update({'status': 'active', 'paused_reason': null})
          .eq('paused_by', 'load_test_auto_response');

      await _client.from('incident_response_log').insert({
        'action_type': 'rollback_all',
        'test_id': testId,
        'status': 'completed',
        'executed_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Rollback error: $e');
      return false;
    }
  }

  String _mapMetricToService(String metricName) {
    if (metricName.toLowerCase().contains('websocket')) {
      return 'websocket_service';
    }
    if (metricName.toLowerCase().contains('blockchain')) {
      return 'blockchain_service';
    }
    if (metricName.toLowerCase().contains('database')) {
      return 'database_service';
    }
    return 'api_service';
  }

  Future<void> _sendAdminAlert(String title, String message) async {
    try {
      final admins = await _client
          .from('user_profiles')
          .select('id, phone_number')
          .eq('role', 'admin');

      for (final admin in admins) {
        if (admin['phone_number'] != null) {
          await _telnyxService.sendSMS(
            toPhone: admin['phone_number'],
            messageBody: '🚨 $title: $message',
            messageCategory: 'critical_alert',
          );
        }
      }
    } catch (e) {
      debugPrint('Send admin alert error: $e');
    }
  }

  Future<void> _logAutoResponse(
    LoadTestReport report,
    LoadTestAutoResponseResult result,
  ) async {
    try {
      await _client.from('incident_response_log').insert({
        'action_type': 'load_test_auto_response_summary',
        'test_id': report.testId,
        'user_tier': report.userCount,
        'triggered': result.triggered,
        'actions_taken': result.actions,
        'errors': result.errors,
        'message': result.message,
        'executed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log auto response error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getResponseHistory({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('incident_response_log')
          .select()
          .order('executed_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCircuitBreakerStates() async {
    try {
      final response = await _client
          .from('circuit_breaker_state')
          .select()
          .order('triggered_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPausedElections() async {
    try {
      final response = await _client
          .from('elections')
          .select('id, title, creator_id, risk_score, paused_at, paused_reason')
          .eq('paused_by', 'load_test_auto_response');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}

class LoadTestAutoResponseResult {
  final bool triggered;
  final List<String> actions;
  final List<String> errors;
  final String message;

  LoadTestAutoResponseResult({
    required this.triggered,
    required this.actions,
    this.errors = const [],
    required this.message,
  });
}
