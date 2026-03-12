import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import './supabase_service.dart';

/// Failover Simulator Service
/// Simulates AI service failures to test failover detection and switching
class FailoverSimulator {
  static FailoverSimulator? _instance;
  static FailoverSimulator get instance => _instance ??= FailoverSimulator._();

  FailoverSimulator._();

  SupabaseClient get _client => SupabaseService.instance.client;
  final Map<String, Timer?> _activeSimulations = {};

  /// Simulate service failure with automatic restoration
  Future<Map<String, dynamic>> simulateServiceFailure({
    required String serviceName,
    required int durationSeconds,
    String failureReason = 'timeout',
  }) async {
    try {
      final simulationId =
          '${serviceName}_${DateTime.now().millisecondsSinceEpoch}';
      final startTime = DateTime.now();

      debugPrint(
        '🔴 Starting failover simulation for $serviceName ($durationSeconds seconds)',
      );

      // Mark service as down
      await _client.from('ai_service_health_log').insert({
        'service_name': serviceName,
        'status': 'down',
        'response_time_ms': 5000,
        'consecutive_failures': 5,
        'health_score': 0,
        'error_message': 'Simulated failure: $failureReason',
        'timestamp': startTime.toIso8601String(),
      });

      // Wait for failover detection (should happen within 2-5 seconds)
      await Future.delayed(const Duration(seconds: 3));
      final detectionTime = DateTime.now().difference(startTime).inMilliseconds;

      // Check if failover event was created
      final failoverEvents = await _client
          .from('failover_events')
          .select()
          .eq('failed_service', serviceName)
          .gte('detected_at', startTime.toIso8601String())
          .order('detected_at', ascending: false)
          .limit(1);

      final failoverDetected = failoverEvents.isNotEmpty;
      final backupService = failoverDetected
          ? failoverEvents.first['backup_service']
          : 'unknown';

      // Schedule automatic restoration
      _activeSimulations[simulationId] = Timer(
        Duration(seconds: durationSeconds),
        () => _restoreService(serviceName, startTime),
      );

      return {
        'success': true,
        'simulation_id': simulationId,
        'service_name': serviceName,
        'duration_seconds': durationSeconds,
        'detection_time_ms': detectionTime,
        'failover_detected': failoverDetected,
        'backup_service': backupService,
        'start_time': startTime.toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Simulate service failure error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Restore service to healthy status
  Future<void> _restoreService(String serviceName, DateTime startTime) async {
    try {
      debugPrint('🟢 Restoring service: $serviceName');

      // Mark service as healthy
      await _client.from('ai_service_health_log').insert({
        'service_name': serviceName,
        'status': 'healthy',
        'response_time_ms': 150,
        'consecutive_failures': 0,
        'health_score': 100,
        'error_message': null,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Calculate total failover duration
      final totalDuration = DateTime.now().difference(startTime).inSeconds;

      debugPrint(
        '✅ Service restored: $serviceName (total duration: ${totalDuration}s)',
      );
    } catch (e) {
      debugPrint('❌ Restore service error: $e');
    }
  }

  /// Get simulation status
  Future<Map<String, dynamic>> getSimulationStatus(String simulationId) async {
    final isActive = _activeSimulations.containsKey(simulationId);
    return {
      'simulation_id': simulationId,
      'is_active': isActive,
      'status': isActive ? 'running' : 'completed',
    };
  }

  /// Cancel active simulation
  Future<void> cancelSimulation(String simulationId) async {
    final timer = _activeSimulations[simulationId];
    if (timer != null) {
      timer.cancel();
      _activeSimulations.remove(simulationId);
      debugPrint('🛑 Cancelled simulation: $simulationId');
    }
  }

  /// Get all active simulations
  List<String> getActiveSimulations() {
    return _activeSimulations.keys.toList();
  }
}
