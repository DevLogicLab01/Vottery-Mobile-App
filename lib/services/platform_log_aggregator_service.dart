import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PlatformLogAggregatorService {
  static final PlatformLogAggregatorService _instance =
      PlatformLogAggregatorService._internal();
  factory PlatformLogAggregatorService() => _instance;
  PlatformLogAggregatorService._internal();

  final _supabase = Supabase.instance.client;
  Timer? _aggregationTimer;
  bool _isRunning = false;
  static const int _aggregationIntervalMinutes = 15;
  static const int _maxLogsPerBatch = 10000;

  /// Start automatic log aggregation every 15 minutes
  void startAggregation() {
    if (_isRunning) return;

    _isRunning = true;
    print(
      '🔄 Starting log aggregation (every $_aggregationIntervalMinutes minutes)',
    );

    // Run immediately on start
    _runAggregation();

    // Schedule periodic runs
    _aggregationTimer = Timer.periodic(
      Duration(minutes: _aggregationIntervalMinutes),
      (_) => _runAggregation(),
    );
  }

  /// Stop automatic log aggregation
  void stopAggregation() {
    _aggregationTimer?.cancel();
    _aggregationTimer = null;
    _isRunning = false;
    print('⏸️ Stopped log aggregation');
  }

  /// Run single aggregation cycle
  Future<Map<String, dynamic>> _runAggregation() async {
    final runId = _generateUuid();
    final startTime = DateTime.now();

    try {
      print('📊 Starting log aggregation run: $runId');

      // Create aggregation run record
      await _supabase.from('log_aggregation_runs').insert({
        'run_id': runId,
        'start_time': startTime.toIso8601String(),
        'status': 'running',
      });

      final cutoffTime = startTime.subtract(
        Duration(minutes: _aggregationIntervalMinutes),
      );
      final allLogs = <Map<String, dynamic>>[];
      final sourcesProcessed = <String>[];

      // 1. Collect Supabase logs (database queries, API calls, auth events)
      try {
        final supabaseLogs = await _collectSupabaseLogs(cutoffTime);
        allLogs.addAll(supabaseLogs);
        sourcesProcessed.add('supabase_logs');
        print('✅ Collected ${supabaseLogs.length} Supabase logs');
      } catch (e) {
        print('❌ Error collecting Supabase logs: $e');
      }

      // 2. Collect security incidents
      try {
        final securityLogs = await _collectSecurityIncidents(cutoffTime);
        allLogs.addAll(securityLogs);
        sourcesProcessed.add('security_incidents');
        print('✅ Collected ${securityLogs.length} security incidents');
      } catch (e) {
        print('❌ Error collecting security incidents: $e');
      }

      // 3. Collect payment transaction logs
      try {
        final paymentLogs = await _collectPaymentLogs(cutoffTime);
        allLogs.addAll(paymentLogs);
        sourcesProcessed.add('payment_transactions');
        print('✅ Collected ${paymentLogs.length} payment logs');
      } catch (e) {
        print('❌ Error collecting payment logs: $e');
      }

      // 4. Collect user activity logs
      try {
        final activityLogs = await _collectUserActivityLogs(cutoffTime);
        allLogs.addAll(activityLogs);
        sourcesProcessed.add('user_activity_logs');
        print('✅ Collected ${activityLogs.length} user activity logs');
      } catch (e) {
        print('❌ Error collecting user activity logs: $e');
      }

      // 5. Collect audit trail logs
      try {
        final auditLogs = await _collectAuditLogs(cutoffTime);
        allLogs.addAll(auditLogs);
        sourcesProcessed.add('immutable_audit_log');
        print('✅ Collected ${auditLogs.length} audit logs');
      } catch (e) {
        print('❌ Error collecting audit logs: $e');
      }

      // 6. Collect error logs
      try {
        final errorLogs = await _collectErrorLogs(cutoffTime);
        allLogs.addAll(errorLogs);
        sourcesProcessed.add('error_tracking');
        print('✅ Collected ${errorLogs.length} error logs');
      } catch (e) {
        print('❌ Error collecting error logs: $e');
      }

      // Normalize and deduplicate logs
      final normalizedLogs = _normalizeLogs(allLogs);
      final deduplicatedLogs = _deduplicateLogs(normalizedLogs);

      // Batch and insert logs (limit to max batch size)
      final logsToInsert = deduplicatedLogs.take(_maxLogsPerBatch).toList();

      if (logsToInsert.isNotEmpty) {
        await _insertLogs(logsToInsert);
        print('💾 Inserted ${logsToInsert.length} deduplicated logs');
      }

      // Update aggregation run record
      final endTime = DateTime.now();
      await _supabase
          .from('log_aggregation_runs')
          .update({
            'end_time': endTime.toIso8601String(),
            'logs_collected': logsToInsert.length,
            'sources_processed': sourcesProcessed,
            'status': 'completed',
          })
          .eq('run_id', runId);

      print(
        '✅ Log aggregation completed: ${logsToInsert.length} logs in ${endTime.difference(startTime).inSeconds}s',
      );

      return {
        'success': true,
        'run_id': runId,
        'logs_collected': logsToInsert.length,
        'sources_processed': sourcesProcessed,
        'duration_seconds': endTime.difference(startTime).inSeconds,
      };
    } catch (e, stackTrace) {
      print('❌ Log aggregation failed: $e');
      print(stackTrace);

      // Update run record with error
      await _supabase
          .from('log_aggregation_runs')
          .update({
            'end_time': DateTime.now().toIso8601String(),
            'status': 'failed',
            'error_message': e.toString(),
          })
          .eq('run_id', runId);

      return {'success': false, 'error': e.toString()};
    }
  }

  /// Collect logs from Supabase logs table
  Future<List<Map<String, dynamic>>> _collectSupabaseLogs(
    DateTime cutoffTime,
  ) async {
    try {
      final response = await _supabase
          .from('supabase_logs')
          .select()
          .gte('timestamp', cutoffTime.toIso8601String())
          .order('timestamp', ascending: false)
          .limit(5000);

      return (response as List)
          .map(
            (log) => {
              'event_type': _mapSupabaseEventType(log['event_type']),
              'user_id': log['user_id'],
              'ip_address': log['ip_address'],
              'action': log['action'] ?? 'unknown',
              'resource': log['resource'],
              'metadata': log['metadata'] ?? {},
              'severity': log['severity'] ?? 'low',
              'timestamp': log['timestamp'],
              'source_table': 'supabase_logs',
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching Supabase logs: $e');
      return [];
    }
  }

  /// Collect security incidents
  Future<List<Map<String, dynamic>>> _collectSecurityIncidents(
    DateTime cutoffTime,
  ) async {
    try {
      final response = await _supabase
          .from('security_incidents')
          .select()
          .gte('created_at', cutoffTime.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1000);

      return (response as List)
          .map(
            (incident) => {
              'event_type': 'security_event',
              'user_id': incident['user_id'],
              'ip_address': incident['ip_address'],
              'action': incident['incident_type'] ?? 'security_incident',
              'resource': incident['resource'],
              'metadata': incident['details'] ?? {},
              'severity': incident['severity'] ?? 'high',
              'timestamp': incident['created_at'],
              'source_table': 'security_incidents',
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching security incidents: $e');
      return [];
    }
  }

  /// Collect payment transaction logs
  Future<List<Map<String, dynamic>>> _collectPaymentLogs(
    DateTime cutoffTime,
  ) async {
    try {
      final response = await _supabase
          .from('payment_transactions')
          .select()
          .gte('created_at', cutoffTime.toIso8601String())
          .order('created_at', ascending: false)
          .limit(2000);

      return (response as List)
          .map(
            (payment) => {
              'event_type': 'payment_transaction',
              'user_id': payment['user_id'],
              'ip_address': payment['ip_address'],
              'action': payment['status'] == 'failed'
                  ? 'payment_failed'
                  : 'payment_success',
              'resource': 'payments/${payment['payment_id']}',
              'metadata': {
                'amount': payment['amount'],
                'currency': payment['currency'],
                'status': payment['status'],
                'payment_method': payment['payment_method'],
              },
              'severity': payment['status'] == 'failed' ? 'medium' : 'low',
              'timestamp': payment['created_at'],
              'source_table': 'payment_transactions',
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching payment logs: $e');
      return [];
    }
  }

  /// Collect user activity logs
  Future<List<Map<String, dynamic>>> _collectUserActivityLogs(
    DateTime cutoffTime,
  ) async {
    try {
      final response = await _supabase
          .from('user_activity_logs')
          .select()
          .gte('created_at', cutoffTime.toIso8601String())
          .order('created_at', ascending: false)
          .limit(5000);

      return (response as List)
          .map(
            (activity) => {
              'event_type': 'user_action',
              'user_id': activity['user_id'],
              'ip_address': activity['ip_address'],
              'action': activity['action_type'] ?? 'user_action',
              'resource': activity['resource'],
              'metadata': activity['metadata'] ?? {},
              'severity': 'low',
              'timestamp': activity['created_at'],
              'source_table': 'user_activity_logs',
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching user activity logs: $e');
      return [];
    }
  }

  /// Collect audit trail logs
  Future<List<Map<String, dynamic>>> _collectAuditLogs(
    DateTime cutoffTime,
  ) async {
    try {
      final response = await _supabase
          .from('immutable_audit_log')
          .select()
          .gte('created_at', cutoffTime.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1000);

      return (response as List)
          .map(
            (audit) => {
              'event_type': 'system_event',
              'user_id': audit['user_id'],
              'ip_address': audit['ip_address'],
              'action': audit['action'] ?? 'audit_event',
              'resource': audit['resource'],
              'metadata': audit['metadata'] ?? {},
              'severity': audit['severity'] ?? 'medium',
              'timestamp': audit['created_at'],
              'source_table': 'immutable_audit_log',
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }

  /// Collect error logs
  Future<List<Map<String, dynamic>>> _collectErrorLogs(
    DateTime cutoffTime,
  ) async {
    try {
      final response = await _supabase
          .from('error_tracking')
          .select()
          .gte('created_at', cutoffTime.toIso8601String())
          .order('created_at', ascending: false)
          .limit(2000);

      return (response as List)
          .map(
            (error) => {
              'event_type': 'error',
              'user_id': error['user_id'],
              'ip_address': error['ip_address'],
              'action': 'application_error',
              'resource': error['error_location'],
              'metadata': {
                'error_message': error['error_message'],
                'error_type': error['error_type'],
                'stack_trace': error['stack_trace'],
              },
              'severity': error['severity'] ?? 'high',
              'timestamp': error['created_at'],
              'source_table': 'error_tracking',
            },
          )
          .toList();
    } catch (e) {
      print('Error fetching error logs: $e');
      return [];
    }
  }

  /// Normalize logs to unified LogEntry format
  List<Map<String, dynamic>> _normalizeLogs(List<Map<String, dynamic>> logs) {
    return logs.map((log) {
      return {
        'timestamp': log['timestamp'] ?? DateTime.now().toIso8601String(),
        'event_type': log['event_type'] ?? 'system_event',
        'user_id': log['user_id'],
        'ip_address': log['ip_address'],
        'action': log['action'] ?? 'unknown',
        'resource': log['resource'],
        'metadata': log['metadata'] ?? {},
        'severity': log['severity'] ?? 'low',
        'source_table': log['source_table'],
      };
    }).toList();
  }

  /// Deduplicate logs using fingerprint hash
  List<Map<String, dynamic>> _deduplicateLogs(List<Map<String, dynamic>> logs) {
    final seen = <String>{};
    final deduplicated = <Map<String, dynamic>>[];

    for (final log in logs) {
      final fingerprint = _generateFingerprint(log);
      if (!seen.contains(fingerprint)) {
        seen.add(fingerprint);
        deduplicated.add({...log, 'fingerprint': fingerprint});
      }
    }

    return deduplicated;
  }

  /// Generate unique fingerprint for deduplication
  String _generateFingerprint(Map<String, dynamic> log) {
    final components = [
      log['timestamp']?.toString() ?? '',
      log['event_type']?.toString() ?? '',
      log['user_id']?.toString() ?? '',
      log['action']?.toString() ?? '',
    ].join('|');

    return md5.convert(utf8.encode(components)).toString();
  }

  /// Insert logs into platform_logs_aggregated table
  Future<void> _insertLogs(List<Map<String, dynamic>> logs) async {
    if (logs.isEmpty) return;

    // Insert in batches of 500 to avoid payload size limits
    const batchSize = 500;
    for (var i = 0; i < logs.length; i += batchSize) {
      final batch = logs.skip(i).take(batchSize).toList();
      await _supabase
          .from('platform_logs_aggregated')
          .upsert(batch, onConflict: 'fingerprint');
    }
  }

  /// Map Supabase event types to standard event types
  String _mapSupabaseEventType(String? eventType) {
    if (eventType == null) return 'system_event';

    if (eventType.contains('auth')) return 'auth_event';
    if (eventType.contains('api')) return 'api_call';
    if (eventType.contains('database') || eventType.contains('query')) {
      return 'database_query';
    }

    return 'system_event';
  }

  /// Generate UUID
  String _generateUuid() {
    return '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond % 1000}';
  }

  /// Manual trigger for immediate aggregation
  Future<Map<String, dynamic>> triggerManualAggregation() async {
    print('🔄 Manual log aggregation triggered');
    return await _runAggregation();
  }

  /// Get aggregation status
  bool get isRunning => _isRunning;

  /// Dispose resources
  void dispose() {
    stopAggregation();
  }
}
