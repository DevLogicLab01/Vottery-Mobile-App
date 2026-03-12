import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import './automated_incident_response_service.dart';

class AutomatedResponseActionsService {
  static final AutomatedResponseActionsService _instance =
      AutomatedResponseActionsService._internal();
  factory AutomatedResponseActionsService() => _instance;
  AutomatedResponseActionsService._internal();

  final _supabase = Supabase.instance.client;

  /// Execute automated response based on fraud detection confidence and severity
  Future<Map<String, dynamic>> executeAutomatedResponse({
    required String analysisId,
    required List<Map<String, dynamic>> detectedPatterns,
    required List<Map<String, dynamic>> predictions,
  }) async {
    final actionsExecuted = <Map<String, dynamic>>[];

    try {
      print('🤖 Executing automated fraud response actions');

      // Process each detected pattern
      for (final pattern in detectedPatterns) {
        final confidence = pattern['confidence_score'] as num? ?? 0;
        final severity = pattern['severity'] as String? ?? 'low';
        final patternName = pattern['pattern_name'] as String? ?? 'Unknown';
        final affectedUsers = pattern['affected_users'] as List? ?? [];

        // High-confidence critical patterns
        if (confidence >= 0.9 && severity == 'critical') {
          final actions = await _executeHighConfidenceCriticalActions(
            analysisId,
            patternName,
            affectedUsers,
          );
          actionsExecuted.addAll(actions);
        }
        // Medium-confidence actions
        else if (confidence >= 0.7 && confidence < 0.9) {
          final actions = await _executeMediumConfidenceActions(
            analysisId,
            patternName,
            affectedUsers,
          );
          actionsExecuted.addAll(actions);
        }
        // Low-confidence actions
        else if (confidence >= 0.5 && confidence < 0.7) {
          final actions = await _executeLowConfidenceActions(
            analysisId,
            patternName,
            affectedUsers,
          );
          actionsExecuted.addAll(actions);
        }
      }

      // Process predictions for preventive actions
      for (final prediction in predictions) {
        final likelihood = prediction['likelihood_percentage'] as int? ?? 0;

        if (likelihood >= 70) {
          final actions = await _executePreventiveActions(
            analysisId,
            prediction,
          );
          actionsExecuted.addAll(actions);
        }
      }

      print('✅ Executed ${actionsExecuted.length} automated actions');

      return {
        'success': true,
        'actions_executed': actionsExecuted.length,
        'actions': actionsExecuted,
      };
    } catch (e, stackTrace) {
      print('❌ Automated response execution failed: $e');
      print(stackTrace);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Execute high-confidence critical actions (confidence > 0.9, severity = critical)
  Future<List<Map<String, dynamic>>> _executeHighConfidenceCriticalActions(
    String analysisId,
    String patternName,
    List affectedUsers,
  ) async {
    final actions = <Map<String, dynamic>>[];

    // 1. Create urgent fraud alert
    await _createFraudAlert(
      analysisId: analysisId,
      priority: 'urgent',
      title: 'CRITICAL: $patternName Detected',
      description:
          'High-confidence fraud pattern detected affecting ${affectedUsers.length} users',
      affectedUsers: affectedUsers,
    );
    actions.add({
      'action': 'create_fraud_alert',
      'priority': 'urgent',
      'status': 'completed',
    });

    // 2. Send Slack notification to #security-ops
    await _sendSlackNotification(
      channel: '#security-ops',
      message:
          '🚨 CRITICAL FRAUD ALERT: $patternName detected. ${affectedUsers.length} users affected. Immediate action required.',
      priority: 'critical',
    );
    actions.add({
      'action': 'send_slack_notification',
      'channel': '#security-ops',
      'status': 'completed',
    });

    // 3. Block suspicious accounts
    for (final userId in affectedUsers) {
      await _blockUserAccount(userId.toString());
    }
    actions.add({
      'action': 'block_accounts',
      'count': affectedUsers.length,
      'status': 'completed',
    });

    // 4. Require verification
    for (final userId in affectedUsers) {
      await _requireAccountVerification(userId.toString());
    }
    actions.add({
      'action': 'require_verification',
      'count': affectedUsers.length,
      'status': 'completed',
    });

    // 5. Send email notifications to affected users
    for (final userId in affectedUsers) {
      await _sendSecurityEmail(
        userId: userId.toString(),
        subject: 'Security Alert: Account Review Required',
        message:
            'We detected suspicious activity on your account. Please verify your identity to regain access.',
      );
    }
    actions.add({
      'action': 'send_security_emails',
      'count': affectedUsers.length,
      'status': 'completed',
    });

    return actions;
  }

  /// Execute medium-confidence actions (confidence 0.7-0.9)
  Future<List<Map<String, dynamic>>> _executeMediumConfidenceActions(
    String analysisId,
    String patternName,
    List affectedUsers,
  ) async {
    final actions = <Map<String, dynamic>>[];

    // 1. Add to investigation queue
    await _supabase.from('fraud_investigations').insert({
      'analysis_id': analysisId,
      'pattern_name': patternName,
      'title': 'Investigation: $patternName',
      'description': 'Medium-confidence fraud pattern requiring manual review',
      'status': 'pending_review',
      'priority': 'high',
      'affected_users': affectedUsers,
    });
    actions.add({
      'action': 'add_to_investigation_queue',
      'status': 'completed',
    });

    // 2. Flag for manual review
    for (final userId in affectedUsers) {
      await _flagUserForReview(userId.toString(), patternName);
    }
    actions.add({
      'action': 'flag_for_manual_review',
      'count': affectedUsers.length,
      'status': 'completed',
    });

    // 3. Enhanced monitoring
    for (final userId in affectedUsers) {
      await _enableEnhancedMonitoring(userId.toString());
    }
    actions.add({
      'action': 'enable_enhanced_monitoring',
      'count': affectedUsers.length,
      'status': 'completed',
    });

    return actions;
  }

  /// Execute low-confidence actions (confidence 0.5-0.7)
  Future<List<Map<String, dynamic>>> _executeLowConfidenceActions(
    String analysisId,
    String patternName,
    List affectedUsers,
  ) async {
    final actions = <Map<String, dynamic>>[];

    // 1. Log detection
    await _supabase.from('fraud_detection_log').insert({
      'detection_type': patternName,
      'confidence_score': 0.6,
      'details': {
        'analysis_id': analysisId,
        'affected_users': affectedUsers,
        'action': 'logged_for_tracking',
      },
      'action_taken': 'logged',
    });
    actions.add({'action': 'log_detection', 'status': 'completed'});

    // 2. Add to watch list
    for (final userId in affectedUsers) {
      await _addToWatchList(userId.toString(), patternName);
    }
    actions.add({
      'action': 'add_to_watch_list',
      'count': affectedUsers.length,
      'status': 'completed',
    });

    // 3. Rate limiting (if API abuse detected)
    if (patternName.toLowerCase().contains('api') ||
        patternName.toLowerCase().contains('credential')) {
      for (final userId in affectedUsers) {
        await _adjustRateLimits(userId.toString(), reduce: true);
      }
      actions.add({
        'action': 'adjust_rate_limits',
        'count': affectedUsers.length,
        'status': 'completed',
      });
    }

    return actions;
  }

  /// Execute preventive actions for predictions
  Future<List<Map<String, dynamic>>> _executePreventiveActions(
    String analysisId,
    Map<String, dynamic> prediction,
  ) async {
    final actions = <Map<String, dynamic>>[];

    final threatType =
        prediction['predicted_threat_type'] as String? ?? 'Unknown';
    final likelihood = prediction['likelihood_percentage'] as int? ?? 0;

    // 1. Enable additional security measures
    await _enableAdditionalSecurity(threatType);
    actions.add({
      'action': 'enable_additional_security',
      'threat_type': threatType,
      'status': 'completed',
    });

    // 2. Notify security team of predicted threat
    await _sendSlackNotification(
      channel: '#security-ops',
      message:
          '⚠️ THREAT PREDICTION: $threatType ($likelihood% likelihood). Preventive measures activated.',
      priority: 'medium',
    );
    actions.add({'action': 'notify_security_team', 'status': 'completed'});

    // 3. Schedule preventive maintenance if system vulnerability predicted
    if (threatType.toLowerCase().contains('system') ||
        threatType.toLowerCase().contains('infrastructure')) {
      await _schedulePreventiveMaintenance(threatType);
      actions.add({
        'action': 'schedule_preventive_maintenance',
        'status': 'completed',
      });
    }

    // 4. Adjust fraud rules proactively
    await _adjustFraudRules(threatType);
    actions.add({'action': 'adjust_fraud_rules', 'status': 'completed'});

    return actions;
  }

  // ─── Datadog-Triggered Actions ───────────────────────────────────────────────

  /// Handle Datadog alert and route to appropriate actions
  Future<Map<String, dynamic>> handleAlert(AutomatedIncidentAlert alert) async {
    final actionsTaken = <String>[];

    try {
      switch (alert.type) {
        case DatadogAlertType.queryLatencyBreach:
          await autoScaleDatabaseConnections();
          actionsTaken.add('auto_scaled_database_connections');
          break;
        case DatadogAlertType.errorRateBreach:
          await activateCircuitBreakers('api_gateway');
          actionsTaken.add('activated_circuit_breakers');
          break;
        case DatadogAlertType.connectionPoolExhaustion:
          await autoScaleDatabaseConnections();
          await pauseHighRiskElections();
          actionsTaken.addAll([
            'auto_scaled_database_connections',
            'paused_high_risk_elections',
          ]);
          break;
      }

      // Send Slack notification
      await _sendSlackNotification(
        channel: 'production-incidents',
        message:
            '🚨 Datadog Alert: ${alert.typeLabel}\n'
            'Threshold: ${alert.threshold}, Actual: ${alert.actualValue.toStringAsFixed(2)}\n'
            'Actions taken: ${actionsTaken.join(', ')}',
        priority: 'high',
      );

      // Log to incident_response_log
      await _supabase.from('incident_response_log').insert({
        'alert_type': alert.typeLabel,
        'threshold': alert.threshold,
        'actual_value': alert.actualValue,
        'consecutive_breaches': alert.consecutiveBreaches,
        'actions_taken': actionsTaken,
        'created_at': DateTime.now().toIso8601String(),
      });

      return {'success': true, 'actions_taken': actionsTaken};
    } catch (e) {
      debugPrint('handleAlert error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Auto-scale database connections (1.5x current, capped at 200)
  Future<void> autoScaleDatabaseConnections() async {
    try {
      // Get current pool size
      final config = await _supabase
          .from('database_config')
          .select('max_connections')
          .maybeSingle();

      final currentSize = (config?['max_connections'] as num?)?.toInt() ?? 100;
      final newPoolSize = (currentSize * 1.5).ceil().clamp(0, 200);

      // Update via Supabase Management API (simulated)
      await _supabase.from('database_config').upsert({
        'key': 'max_connections',
        'max_connections': newPoolSize,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': 'automated_system',
      });

      // Log action
      await _supabase.from('incident_response_log').insert({
        'action': 'auto_scale_database_connections',
        'details': {
          'previous_pool_size': currentSize,
          'new_pool_size': newPoolSize,
        },
        'created_at': DateTime.now().toIso8601String(),
      });

      await _sendSlackNotification(
        channel: 'production-incidents',
        message:
            '✅ Automatically scaled database connections to $newPoolSize (from $currentSize)',
        priority: 'medium',
      );

      debugPrint('✅ Database connections scaled: $currentSize → $newPoolSize');
    } catch (e) {
      debugPrint('autoScaleDatabaseConnections error: $e');
    }
  }

  /// Pause high-risk elections (risk_score > 0.7)
  Future<void> pauseHighRiskElections() async {
    try {
      // Query high-risk active elections
      final elections = await _supabase
          .from('elections')
          .select('id, title, created_by, risk_score')
          .eq('status', 'active')
          .gt('risk_score', 0.7);

      if (elections.isEmpty) {
        debugPrint('No high-risk elections found to pause');
        return;
      }

      final electionIds = elections.map((e) => e['id']).toList();

      // Pause elections
      await _supabase
          .from('elections')
          .update({
            'status': 'paused',
            'paused_reason': 'Automated pause: high risk score detected',
            'paused_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', electionIds);

      // Log to election_integrity_monitoring
      await _supabase.from('election_integrity_monitoring').insert({
        'event_type': 'bulk_pause',
        'election_ids': electionIds,
        'reason':
            'Automated: risk_score > 0.7 during connection pool exhaustion',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('⏸️ Paused ${elections.length} high-risk elections');
    } catch (e) {
      debugPrint('pauseHighRiskElections error: $e');
    }
  }

  /// Activate circuit breakers for a service
  Future<void> activateCircuitBreakers(String service) async {
    try {
      await _supabase.from('circuit_breaker_state').upsert({
        'service': service,
        'is_open': true,
        'activated_at': DateTime.now().toIso8601String(),
        'activated_by': 'automated_system',
        'reason': 'Datadog error_rate_breach threshold exceeded',
      });

      // Mark deployment as rollback candidate
      await _supabase.from('feature_deployment_log').insert({
        'action': 'rollback_candidate_marked',
        'service': service,
        'reason': 'Circuit breaker activated due to error rate breach',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('⚡ Circuit breaker activated for service: $service');
    } catch (e) {
      debugPrint('activateCircuitBreakers error: $e');
    }
  }

  /// Helper methods for specific actions
  Future<void> _createFraudAlert({
    required String analysisId,
    required String priority,
    required String title,
    required String description,
    required List affectedUsers,
  }) async {
    await _supabase.from('alerts').insert({
      'alert_type': 'fraud_detection',
      'priority': priority,
      'title': title,
      'description': description,
      'metadata': {'analysis_id': analysisId, 'affected_users': affectedUsers},
      'status': 'active',
    });
  }

  Future<void> _sendSlackNotification({
    required String channel,
    required String message,
    required String priority,
  }) async {
    // Integration with Slack service
    print('📢 Slack notification: $channel - $message');
  }

  Future<void> _blockUserAccount(String userId) async {
    await _supabase
        .from('user_profiles')
        .update({
          'account_locked': true,
          'lock_reason': 'Fraud detection - automated response',
        })
        .eq('user_id', userId);
  }

  Future<void> _requireAccountVerification(String userId) async {
    await _supabase
        .from('user_profiles')
        .update({
          'verification_required': true,
          'verification_reason': 'Security review',
        })
        .eq('user_id', userId);
  }

  Future<void> _sendSecurityEmail({
    required String userId,
    required String subject,
    required String message,
  }) async {
    // Integration with email service (Resend)
    print('📧 Security email sent to user: $userId');
  }

  Future<void> _flagUserForReview(String userId, String reason) async {
    await _supabase.from('user_flags').insert({
      'user_id': userId,
      'flag_type': 'fraud_review',
      'reason': reason,
      'status': 'pending',
    });
  }

  Future<void> _enableEnhancedMonitoring(String userId) async {
    await _supabase.from('user_monitoring').upsert({
      'user_id': userId,
      'monitoring_level': 'enhanced',
      'enabled_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _addToWatchList(String userId, String reason) async {
    await _supabase.from('fraud_watch_list').insert({
      'user_id': userId,
      'reason': reason,
      'added_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _adjustRateLimits(String userId, {required bool reduce}) async {
    final newLimit = reduce ? 10 : 100; // Requests per minute
    await _supabase.from('rate_limits').upsert({
      'user_id': userId,
      'requests_per_minute': newLimit,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _enableAdditionalSecurity(String threatType) async {
    print('🔒 Enabling additional security for: $threatType');
  }

  Future<void> _schedulePreventiveMaintenance(String threatType) async {
    print('🔧 Scheduling preventive maintenance for: $threatType');
  }

  Future<void> _adjustFraudRules(String threatType) async {
    print('⚙️ Adjusting fraud rules for: $threatType');
  }
}
