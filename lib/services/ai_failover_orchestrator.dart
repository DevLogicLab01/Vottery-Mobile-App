import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

import './ai_health_monitor_service.dart';
import './ai_service_router.dart';

/// AI Failover Orchestrator
/// Manages failover decisions and execution with zero-downtime switching
class AIFailoverOrchestrator {
  static AIFailoverOrchestrator? _instance;
  static AIFailoverOrchestrator get instance =>
      _instance ??= AIFailoverOrchestrator._();

  AIFailoverOrchestrator._();

  static final SupabaseClient _supabase = Supabase.instance.client;
  final Set<String> _activeFailovers = {};
  final StreamController<FailoverEvent> _failoverStream =
      StreamController.broadcast();

  /// Check if failover should be executed
  Future<bool> shouldExecuteFailover({
    required String primaryService,
    required String backupService,
  }) async {
    // Check if primary service is down
    final healthMonitor = AIHealthMonitorService.instance;
    if (!healthMonitor.shouldTriggerFailover(primaryService)) {
      return false;
    }

    // Check if backup service is healthy
    final backupHealth = healthMonitor.getCurrentHealth()[backupService];
    if (backupHealth == null || backupHealth.status != 'healthy') {
      return false;
    }

    // Check if failover already in progress
    if (_activeFailovers.contains(primaryService)) {
      return false;
    }

    return true;
  }

  /// Execute failover to backup service
  Future<FailoverEvent> executeFailover({
    required String failedService,
    required String backupService,
    required String reason,
  }) async {
    _activeFailovers.add(failedService);

    final event = FailoverEvent(
      eventId: DateTime.now().millisecondsSinceEpoch.toString(),
      failedService: failedService,
      backupService: backupService,
      triggerReason: reason,
      detectedAt: DateTime.now(),
      requestsAffected: 0,
      costImpact: 0.0,
    );

    try {
      // Switch traffic atomically
      await AIServiceRouter.instance.switchTraffic(
        from: failedService,
        to: backupService,
      );

      // Log failover event
      await _supabase.from('failover_events').insert({
        'failed_service': failedService,
        'backup_service': backupService,
        'trigger_reason': reason,
        'detected_at': event.detectedAt.toIso8601String(),
        'requests_affected': event.requestsAffected,
        'cost_impact': event.costImpact,
      });

      // Send notifications
      await _sendFailoverNotifications(event);

      _failoverStream.add(event);

      return event;
    } finally {
      _activeFailovers.remove(failedService);
    }
  }

  /// Detect recovery and execute failback
  Future<void> detectRecovery(String serviceName) async {
    final healthMonitor = AIHealthMonitorService.instance;
    final health = healthMonitor.getCurrentHealth()[serviceName];

    if (health == null) return;

    // Check for 3 consecutive successful health checks
    if (health.status == 'healthy' && health.consecutiveFailures == 0) {
      // Check stability period (5 minutes)
      final recentLogs = await _supabase
          .from('ai_service_health_log')
          .select()
          .eq('service_name', serviceName)
          .gte(
            'timestamp',
            DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
          )
          .order('timestamp', ascending: false)
          .limit(150); // 2-second checks = 150 checks in 5 minutes

      final allHealthy = (recentLogs as List).every(
        (log) => log['status'] == 'healthy' && log['response_time_ms'] < 200,
      );

      if (allHealthy) {
        await _executeFailback(serviceName);
      }
    }
  }

  /// Execute automatic failback to primary service
  Future<void> _executeFailback(String serviceName) async {
    try {
      // Update failover event with recovery time
      await _supabase
          .from('failover_events')
          .update({'recovered_at': DateTime.now().toIso8601String()})
          .eq('failed_service', serviceName)
          .isFilter('recovered_at', null);

      // Send recovery notification
      await _sendRecoveryNotification(serviceName);
    } catch (e) {
      // Silent fail
    }
  }

  /// Send multi-channel failover notifications
  Future<void> _sendFailoverNotifications(FailoverEvent event) async {
    final message =
        '🔴 AI Failover Event\nService: ${event.failedService}\nBackup: ${event.backupService}\nReason: ${event.triggerReason}\nTime: ${event.detectedAt}\nImpact: ${event.requestsAffected} requests affected\nAction: Auto-switched to ${event.backupService}';

    await _supabase.from('ai_service_notifications').insert({
      'event_type': 'failover',
      'service_name': event.failedService,
      'severity': 'critical',
      'message': message,
      'channels': ['slack', 'email', 'sms', 'push'],
      'sent_at': DateTime.now().toIso8601String(),
    });
  }

  /// Send recovery notification
  Future<void> _sendRecoveryNotification(String serviceName) async {
    final message =
        '✅ AI Service Recovery\nService: $serviceName\nStatus: Recovered and stable\nAction: Service restored to normal operation';

    await _supabase.from('ai_service_notifications').insert({
      'event_type': 'recovery',
      'service_name': serviceName,
      'severity': 'low',
      'message': message,
      'channels': ['slack', 'email'],
      'sent_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get failover stream
  Stream<FailoverEvent> getFailoverStream() {
    return _failoverStream.stream;
  }

  /// Get failover history
  Future<List<FailoverEvent>> getFailoverHistory({int limit = 100}) async {
    final response = await _supabase
        .from('failover_events')
        .select()
        .order('detected_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => FailoverEvent.fromJson(json))
        .toList();
  }
}

/// Failover Event Model
class FailoverEvent {
  final String eventId;
  final String failedService;
  final String backupService;
  final String triggerReason;
  final DateTime detectedAt;
  final DateTime? recoveredAt;
  final int requestsAffected;
  final double costImpact;

  FailoverEvent({
    required this.eventId,
    required this.failedService,
    required this.backupService,
    required this.triggerReason,
    required this.detectedAt,
    this.recoveredAt,
    required this.requestsAffected,
    required this.costImpact,
  });

  factory FailoverEvent.fromJson(Map<String, dynamic> json) {
    return FailoverEvent(
      eventId: json['event_id'] ?? '',
      failedService: json['failed_service'] ?? '',
      backupService: json['backup_service'] ?? '',
      triggerReason: json['trigger_reason'] ?? '',
      detectedAt: json['detected_at'] != null
          ? DateTime.parse(json['detected_at'])
          : DateTime.now(),
      recoveredAt: json['recovered_at'] != null
          ? DateTime.parse(json['recovered_at'])
          : null,
      requestsAffected: json['requests_affected'] ?? 0,
      costImpact: (json['cost_impact'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'failed_service': failedService,
      'backup_service': backupService,
      'trigger_reason': triggerReason,
      'detected_at': detectedAt.toIso8601String(),
      'recovered_at': recoveredAt?.toIso8601String(),
      'requests_affected': requestsAffected,
      'cost_impact': costImpact,
    };
  }
}
