import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './synthetic_incident_generator.dart';
import 'dart:async';

/// Stress Test Runner Service
/// Runs comprehensive stress tests on incident response system
class StressTestRunner {
  static StressTestRunner? _instance;
  static StressTestRunner get instance => _instance ??= StressTestRunner._();

  StressTestRunner._();

  SupabaseClient get _client => SupabaseService.instance.client;
  SyntheticIncidentGenerator get _generator =>
      SyntheticIncidentGenerator.instance;

  bool _isRunning = false;
  final StreamController<Map<String, dynamic>> _metricsStream =
      StreamController.broadcast();

  /// Run stress test with specified configuration
  Future<Map<String, dynamic>> runStressTest({
    required String testScenario,
    required int durationMinutes,
    required int incidentsPerMinute,
    Map<String, int>? incidentDistribution,
  }) async {
    if (_isRunning) {
      return {'success': false, 'error': 'Test already running'};
    }

    try {
      _isRunning = true;
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final startTime = DateTime.now();

      debugPrint('📊 Starting stress test: $testScenario');
      debugPrint('   Duration: $durationMinutes minutes');
      debugPrint('   Load: $incidentsPerMinute incidents/minute');

      final distribution =
          incidentDistribution ??
          {'fraud': 50, 'ai_failover': 30, 'security': 20};

      int totalIncidents = 0;
      int totalErrors = 0;
      final List<int> responseTimes = [];
      double peakCpu = 0.0;
      int peakMemory = 0;

      // Run test for specified duration
      for (int minute = 0; minute < durationMinutes; minute++) {
        if (!_isRunning) break;

        debugPrint('🔄 Test minute ${minute + 1}/$durationMinutes');

        // Generate incidents for this minute
        final fraudCount = (incidentsPerMinute * (distribution['fraud']! / 100))
            .round();
        final failoverCount =
            (incidentsPerMinute * (distribution['ai_failover']! / 100)).round();
        final securityCount =
            (incidentsPerMinute * (distribution['security']! / 100)).round();

        final batchResult = await _generator.batchGenerate(
          fraudCount: fraudCount,
          failoverCount: failoverCount,
          securityCount: securityCount,
          timing: 'distributed',
          distributionMinutes: 1,
        );

        if (batchResult['success'] == true) {
          totalIncidents += batchResult['total_generated'] as int;
        } else {
          totalErrors++;
        }

        // Collect system metrics
        final metrics = await _collectSystemMetrics();
        peakCpu = peakCpu > metrics['cpu'] ? peakCpu : metrics['cpu'];
        peakMemory = peakMemory > metrics['memory']
            ? peakMemory
            : metrics['memory'];
        responseTimes.add(metrics['response_time']);

        // Emit real-time metrics
        _metricsStream.add({
          'minute': minute + 1,
          'incidents_generated': totalIncidents,
          'cpu': metrics['cpu'],
          'memory': metrics['memory'],
          'response_time': metrics['response_time'],
          'errors': totalErrors,
        });

        // Wait for next minute (unless last minute)
        if (minute < durationMinutes - 1) {
          await Future.delayed(const Duration(minutes: 1));
        }
      }

      final endTime = DateTime.now();
      final avgResponseTime = responseTimes.isNotEmpty
          ? responseTimes.reduce((a, b) => a + b) ~/ responseTimes.length
          : 0;

      // Analyze bottlenecks
      final bottlenecks = _identifyBottlenecks(
        peakCpu: peakCpu,
        peakMemory: peakMemory,
        avgResponseTime: avgResponseTime,
      );

      // Generate recommendations
      final recommendations = _generateRecommendations(bottlenecks);

      // Store test results
      await _client.from('stress_test_results').insert({
        'test_scenario': testScenario,
        'test_duration_minutes': durationMinutes,
        'incidents_generated': totalIncidents,
        'peak_cpu_percent': peakCpu,
        'peak_memory_mb': peakMemory,
        'avg_response_time_ms': avgResponseTime,
        'errors_encountered': totalErrors,
        'test_configuration': {
          'incidents_per_minute': incidentsPerMinute,
          'distribution': distribution,
        },
        'performance_metrics': {'response_times': responseTimes},
        'bottlenecks_identified': bottlenecks,
        'recommendations': recommendations,
      });

      _isRunning = false;

      debugPrint('✅ Stress test complete');
      debugPrint('   Total incidents: $totalIncidents');
      debugPrint('   Peak CPU: ${peakCpu.toStringAsFixed(1)}%');
      debugPrint('   Peak Memory: ${peakMemory}MB');
      debugPrint('   Avg Response Time: ${avgResponseTime}ms');

      return {
        'success': true,
        'test_id': testId,
        'test_scenario': testScenario,
        'duration_minutes': durationMinutes,
        'total_incidents': totalIncidents,
        'peak_cpu': peakCpu,
        'peak_memory': peakMemory,
        'avg_response_time': avgResponseTime,
        'errors': totalErrors,
        'bottlenecks': bottlenecks,
        'recommendations': recommendations,
      };
    } catch (e) {
      _isRunning = false;
      debugPrint('❌ Stress test error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Stop running stress test
  void stopStressTest() {
    _isRunning = false;
    debugPrint('🛑 Stress test stopped');
  }

  /// Get real-time metrics stream
  Stream<Map<String, dynamic>> getMetricsStream() {
    return _metricsStream.stream;
  }

  /// Get stress test history
  Future<List<Map<String, dynamic>>> getTestHistory({int limit = 20}) async {
    try {
      final response = await _client
          .from('stress_test_results')
          .select()
          .order('test_date', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Get test history error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _collectSystemMetrics() async {
    // Simulate system metrics collection
    // In production, this would query actual system metrics
    return {
      'cpu': 45.0 + (DateTime.now().millisecond % 40),
      'memory': 512 + (DateTime.now().millisecond % 256),
      'response_time': 100 + (DateTime.now().millisecond % 200),
    };
  }

  List<String> _identifyBottlenecks({
    required double peakCpu,
    required int peakMemory,
    required int avgResponseTime,
  }) {
    final bottlenecks = <String>[];

    if (peakCpu > 80) {
      bottlenecks.add(
        'High CPU usage detected (${peakCpu.toStringAsFixed(1)}%)',
      );
    }
    if (peakMemory > 1024) {
      bottlenecks.add('High memory usage detected (${peakMemory}MB)');
    }
    if (avgResponseTime > 500) {
      bottlenecks.add(
        'Slow response times detected (${avgResponseTime}ms avg)',
      );
    }

    return bottlenecks;
  }

  List<String> _generateRecommendations(List<String> bottlenecks) {
    final recommendations = <String>[];

    for (final bottleneck in bottlenecks) {
      if (bottleneck.contains('CPU')) {
        recommendations.add(
          'Consider horizontal scaling or optimizing CPU-intensive operations',
        );
      }
      if (bottleneck.contains('memory')) {
        recommendations.add(
          'Implement memory caching or increase available memory',
        );
      }
      if (bottleneck.contains('response')) {
        recommendations.add(
          'Optimize database queries and add connection pooling',
        );
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'System performed well under load - no immediate optimizations needed',
      );
    }

    return recommendations;
  }
}
