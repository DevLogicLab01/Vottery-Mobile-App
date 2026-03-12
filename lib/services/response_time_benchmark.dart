import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

/// Response Time Benchmark Service
/// Measures MTTD, MTTA, MTTR for incident response
class ResponseTimeBenchmark {
  static ResponseTimeBenchmark? _instance;
  static ResponseTimeBenchmark get instance =>
      _instance ??= ResponseTimeBenchmark._();

  ResponseTimeBenchmark._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Run benchmark test for specific incident type
  Future<Map<String, dynamic>> runBenchmark({
    required String incidentType,
    String? testScenario,
  }) async {
    try {
      debugPrint('📊 Running benchmark for $incidentType');

      // Get recent incidents of this type
      final incidents = await _client
          .from('incidents')
          .select()
          .eq('type', incidentType)
          .gte(
            'detected_at',
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .toIso8601String(),
          )
          .order('detected_at', ascending: false)
          .limit(50);

      if (incidents.isEmpty) {
        return {
          'success': false,
          'message': 'No incidents found for benchmarking',
        };
      }

      int totalDetectionTime = 0;
      int totalAcknowledgmentTime = 0;
      int totalResolutionTime = 0;
      int detectionCount = 0;
      int acknowledgmentCount = 0;
      int resolutionCount = 0;

      for (final incident in incidents) {
        final detectedAt = DateTime.parse(incident['detected_at']);

        // Calculate detection time (assuming created_at is when incident occurred)
        if (incident['created_at'] != null) {
          final createdAt = DateTime.parse(incident['created_at']);
          totalDetectionTime += detectedAt.difference(createdAt).inMilliseconds;
          detectionCount++;
        }

        // Calculate acknowledgment time
        if (incident['acknowledged_at'] != null) {
          final acknowledgedAt = DateTime.parse(incident['acknowledged_at']);
          totalAcknowledgmentTime += acknowledgedAt
              .difference(detectedAt)
              .inMilliseconds;
          acknowledgmentCount++;
        }

        // Calculate resolution time
        if (incident['resolved_at'] != null) {
          final resolvedAt = DateTime.parse(incident['resolved_at']);
          totalResolutionTime += resolvedAt
              .difference(detectedAt)
              .inMilliseconds;
          resolutionCount++;
        }
      }

      final mttd = detectionCount > 0
          ? (totalDetectionTime / detectionCount).round()
          : 0;
      final mtta = acknowledgmentCount > 0
          ? (totalAcknowledgmentTime / acknowledgmentCount).round()
          : 0;
      final mttr = resolutionCount > 0
          ? (totalResolutionTime / resolutionCount).round()
          : 0;

      // Store benchmark result
      await _client.from('incident_response_benchmarks').insert({
        'incident_type': incidentType,
        'detection_time_ms': mttd,
        'acknowledgment_time_ms': mtta,
        'resolution_time_ms': mttr,
        'test_scenario': testScenario,
      });

      debugPrint(
        '✅ Benchmark complete: MTTD=${mttd}ms, MTTA=${mtta}ms, MTTR=${mttr}ms',
      );

      return {
        'success': true,
        'incident_type': incidentType,
        'mttd_ms': mttd,
        'mtta_ms': mtta,
        'mttr_ms': mttr,
        'incidents_analyzed': incidents.length,
      };
    } catch (e) {
      debugPrint('❌ Run benchmark error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get benchmark history for incident type
  Future<List<Map<String, dynamic>>> getBenchmarkHistory({
    required String incidentType,
    int days = 30,
  }) async {
    try {
      final response = await _client
          .from('incident_response_benchmarks')
          .select()
          .eq('incident_type', incidentType)
          .gte(
            'benchmark_date',
            DateTime.now().subtract(Duration(days: days)).toIso8601String(),
          )
          .order('benchmark_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Get benchmark history error: $e');
      return [];
    }
  }

  /// Get benchmark targets
  Future<Map<String, dynamic>> getBenchmarkTargets(String incidentType) async {
    try {
      final response = await _client
          .from('benchmark_targets')
          .select()
          .eq('incident_type', incidentType)
          .maybeSingle();

      if (response == null) {
        return _getDefaultTargets(incidentType);
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ Get benchmark targets error: $e');
      return _getDefaultTargets(incidentType);
    }
  }

  /// Update benchmark targets
  Future<bool> updateBenchmarkTargets({
    required String incidentType,
    required int targetMttdMs,
    required int targetMttaMs,
    required int targetMttrMs,
  }) async {
    try {
      await _client.from('benchmark_targets').upsert({
        'incident_type': incidentType,
        'target_mttd_ms': targetMttdMs,
        'target_mtta_ms': targetMttaMs,
        'target_mttr_ms': targetMttrMs,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('❌ Update benchmark targets error: $e');
      return false;
    }
  }

  Map<String, dynamic> _getDefaultTargets(String incidentType) {
    // Default targets based on incident type
    switch (incidentType) {
      case 'fraud':
        return {
          'target_mttd_ms': 5000, // 5 seconds
          'target_mtta_ms': 60000, // 1 minute
          'target_mttr_ms': 300000, // 5 minutes
        };
      case 'ai_failover':
        return {
          'target_mttd_ms': 2000, // 2 seconds
          'target_mtta_ms': 5000, // 5 seconds
          'target_mttr_ms': 30000, // 30 seconds
        };
      case 'security':
        return {
          'target_mttd_ms': 10000, // 10 seconds
          'target_mtta_ms': 120000, // 2 minutes
          'target_mttr_ms': 600000, // 10 minutes
        };
      default:
        return {
          'target_mttd_ms': 30000, // 30 seconds
          'target_mtta_ms': 300000, // 5 minutes
          'target_mttr_ms': 1800000, // 30 minutes
        };
    }
  }
}
