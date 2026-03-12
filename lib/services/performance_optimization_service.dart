import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './supabase_service.dart';
import './auth_service.dart';
import './datadog_tracing_service.dart';
import './claude_service.dart';
import './perplexity_service.dart';

class PerformanceOptimizationService {
  static PerformanceOptimizationService? _instance;
  static PerformanceOptimizationService get instance =>
      _instance ??= PerformanceOptimizationService._();

  PerformanceOptimizationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  DatadogTracingService get _datadog => DatadogTracingService.instance;

  static const String datadogApiKey = String.fromEnvironment('DATADOG_API_KEY');
  static const String datadogAppKey = String.fromEnvironment('DATADOG_APP_KEY');
  static const String datadogApiUrl = 'https://api.datadoghq.com/api/v1';

  /// Analyze Datadog APM traces for performance issues
  Future<Map<String, dynamic>> analyzeDatadogTraces() async {
    try {
      if (datadogApiKey.isEmpty || datadogAppKey.isEmpty) {
        return _getDefaultAnalysis();
      }

      // Fetch last 7 days of trace data
      final endTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final startTime = endTime - (7 * 24 * 60 * 60); // 7 days ago

      final response = await http.get(
        Uri.parse(
          '$datadogApiUrl/traces?start=$startTime&end=$endTime&service=vottery',
        ),
        headers: {
          'DD-API-KEY': datadogApiKey,
          'DD-APPLICATION-KEY': datadogAppKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return await _processTraceData(data);
      } else {
        debugPrint('Datadog API error: ${response.statusCode}');
        return _getDefaultAnalysis();
      }
    } catch (e) {
      debugPrint('Analyze Datadog traces error: $e');
      return _getDefaultAnalysis();
    }
  }

  /// Process trace data and identify optimization opportunities
  Future<Map<String, dynamic>> _processTraceData(
    Map<String, dynamic> traceData,
  ) async {
    try {
      final slowQueries = await _identifySlowQueries(traceData);
      final apiBottlenecks = await _identifyApiBottlenecks(traceData);
      final aiRecommendations = await _generateAiRecommendations(
        slowQueries,
        apiBottlenecks,
      );

      return {
        'slow_queries': slowQueries,
        'api_bottlenecks': apiBottlenecks,
        'ai_recommendations': aiRecommendations,
        'analyzed_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Process trace data error: $e');
      return _getDefaultAnalysis();
    }
  }

  /// Identify slow database queries
  Future<List<Map<String, dynamic>>> _identifySlowQueries(
    Map<String, dynamic> traceData,
  ) async {
    try {
      final slowQueries = <Map<String, dynamic>>[];
      final traces = traceData['traces'] as List<dynamic>? ?? [];

      for (final trace in traces) {
        final spans = trace['spans'] as List<dynamic>? ?? [];
        for (final span in spans) {
          final resource = span['resource'] as String? ?? '';
          final duration = span['duration'] as num? ?? 0;

          // Identify database queries over 500ms
          if ((resource.contains('SELECT') ||
                  resource.contains('UPDATE') ||
                  resource.contains('INSERT')) &&
              duration > 500000000) {
            // nanoseconds
            slowQueries.add({
              'query_text': resource,
              'avg_duration_ms': duration / 1000000,
              'span_type': span['type'] ?? 'database',
              'optimization_potential': _calculateOptimizationPotential(
                duration / 1000000,
              ),
            });
          }
        }
      }

      return slowQueries;
    } catch (e) {
      debugPrint('Identify slow queries error: $e');
      return [];
    }
  }

  /// Identify API bottlenecks
  Future<List<Map<String, dynamic>>> _identifyApiBottlenecks(
    Map<String, dynamic> traceData,
  ) async {
    try {
      final bottlenecks = <Map<String, dynamic>>[];
      final traces = traceData['traces'] as List<dynamic>? ?? [];

      final endpointMetrics = <String, Map<String, dynamic>>{};

      for (final trace in traces) {
        final spans = trace['spans'] as List<dynamic>? ?? [];
        for (final span in spans) {
          if (span['type'] == 'http') {
            final endpoint = span['resource'] as String? ?? '';
            final duration = span['duration'] as num? ?? 0;
            final error = span['error'] as num? ?? 0;

            if (!endpointMetrics.containsKey(endpoint)) {
              endpointMetrics[endpoint] = {
                'total_requests': 0,
                'total_duration': 0.0,
                'errors': 0,
                'durations': <double>[],
              };
            }

            endpointMetrics[endpoint]!['total_requests'] =
                (endpointMetrics[endpoint]!['total_requests'] as int) + 1;
            endpointMetrics[endpoint]!['total_duration'] =
                (endpointMetrics[endpoint]!['total_duration'] as double) +
                (duration / 1000000);
            endpointMetrics[endpoint]!['errors'] =
                (endpointMetrics[endpoint]!['errors'] as int) + error.toInt();
            (endpointMetrics[endpoint]!['durations'] as List<double>).add(
              duration / 1000000,
            );
          }
        }
      }

      // Identify bottlenecks
      endpointMetrics.forEach((endpoint, metrics) {
        final avgLatency =
            (metrics['total_duration'] as double) /
            (metrics['total_requests'] as int);
        final errorRate =
            ((metrics['errors'] as int) / (metrics['total_requests'] as int)) *
            100;

        final durations = metrics['durations'] as List<double>;
        durations.sort();
        final p95Index = (durations.length * 0.95).floor();
        final p95Latency = durations.isNotEmpty
            ? durations[p95Index]
            : avgLatency;

        if (p95Latency > 2000 || errorRate > 5) {
          bottlenecks.add({
            'endpoint': endpoint,
            'avg_latency': avgLatency,
            'p95_latency': p95Latency,
            'error_rate': errorRate,
            'throughput':
                (metrics['total_requests'] as int) / (7 * 24 * 60 * 60),
            'bottleneck_type': p95Latency > 2000
                ? 'high_latency'
                : 'high_error_rate',
          });
        }
      });

      return bottlenecks;
    } catch (e) {
      debugPrint('Identify API bottlenecks error: $e');
      return [];
    }
  }

  /// Generate AI-powered optimization recommendations
  Future<Map<String, dynamic>> _generateAiRecommendations(
    List<Map<String, dynamic>> slowQueries,
    List<Map<String, dynamic>> apiBottlenecks,
  ) async {
    try {
      final recommendations = <String, dynamic>{
        'query_optimizations': [],
        'api_optimizations': [],
        'infrastructure_recommendations': [],
      };

      // Claude for API bottleneck analysis
      for (final bottleneck in apiBottlenecks.take(3)) {
        final prompt =
            '''
Analyze this API endpoint performance issue:

Endpoint: ${bottleneck['endpoint']}
P95 Latency: ${bottleneck['p95_latency']}ms
Error Rate: ${bottleneck['error_rate']}%

Provide JSON response:
{
  "root_cause": "...",
  "optimization_strategy": "...",
  "expected_latency_reduction": 0-100,
  "implementation_complexity": "low|medium|high"
}
''';

        final response = await ClaudeService.instance.callClaudeAPI(prompt);
        try {
          final recommendation = jsonDecode(response);
          recommendations['api_optimizations'].add(recommendation);
        } catch (e) {
          debugPrint('Parse Claude response error: $e');
        }
      }

      // Perplexity for infrastructure optimization
      final infraPrompt =
          '''
Based on these performance patterns, recommend infrastructure optimizations:

Slow Queries: ${slowQueries.length}
API Bottlenecks: ${apiBottlenecks.length}

Provide JSON response:
{
  "recommendations": [
    {
      "category": "database|caching|scaling|optimization",
      "recommendation": "...",
      "expected_impact": "...",
      "cost_implications": "..."
    }
  ]
}
''';

      final infraResponse = await PerplexityService.instance.callPerplexityAPI(
        infraPrompt,
      );
      try {
        final infraData = jsonDecode(
          infraResponse['choices']?[0]?['message']?['content'] ?? '{}',
        );
        recommendations['infrastructure_recommendations'] =
            infraData['recommendations'] ?? [];
      } catch (e) {
        debugPrint('Parse Perplexity response error: $e');
      }

      return recommendations;
    } catch (e) {
      debugPrint('Generate AI recommendations error: $e');
      return {
        'query_optimizations': [],
        'api_optimizations': [],
        'infrastructure_recommendations': [],
      };
    }
  }

  /// Calculate optimization potential score
  int _calculateOptimizationPotential(double durationMs) {
    if (durationMs > 5000) return 100;
    if (durationMs > 2000) return 80;
    if (durationMs > 1000) return 60;
    if (durationMs > 500) return 40;
    return 20;
  }

  /// Store optimization opportunity
  Future<String?> storeOptimization({
    required String optimizationType,
    required String severity,
    required String affectedComponent,
    required Map<String, dynamic> currentMetrics,
    required Map<String, dynamic> recommendedActions,
    required Map<String, dynamic> estimatedImprovement,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('performance_optimizations')
          .insert({
            'optimization_type': optimizationType,
            'severity': severity,
            'affected_component': affectedComponent,
            'current_metrics': currentMetrics,
            'recommended_actions': recommendedActions,
            'estimated_improvement': estimatedImprovement,
            'created_by': _auth.currentUser!.id,
          })
          .select()
          .single();

      return response['optimization_id'] as String?;
    } catch (e) {
      debugPrint('Store optimization error: $e');
      return null;
    }
  }

  /// Get optimization opportunities
  Future<List<Map<String, dynamic>>> getOptimizations({
    String? type,
    String? severity,
    String? status,
  }) async {
    try {
      var query = _client.from('performance_optimizations').select();

      if (type != null) {
        query = query.eq('optimization_type', type);
      }
      if (severity != null) {
        query = query.eq('severity', severity);
      }
      if (status != null) {
        query = query.eq('implementation_status', status);
      }

      final response = await query
          .order('detected_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get optimizations error: $e');
      return [];
    }
  }

  /// Update optimization status
  Future<bool> updateOptimizationStatus({
    required String optimizationId,
    required String status,
    String? implementationNotes,
  }) async {
    try {
      await _client
          .from('performance_optimizations')
          .update({
            'implementation_status': status,
            if (implementationNotes != null)
              'implementation_notes': implementationNotes,
            if (status == 'completed')
              'implemented_at': DateTime.now().toIso8601String(),
          })
          .eq('optimization_id', optimizationId);

      return true;
    } catch (e) {
      debugPrint('Update optimization status error: $e');
      return false;
    }
  }

  Map<String, dynamic> _getDefaultAnalysis() {
    return {
      'slow_queries': [],
      'api_bottlenecks': [],
      'ai_recommendations': {
        'query_optimizations': [],
        'api_optimizations': [],
        'infrastructure_recommendations': [],
      },
      'analyzed_at': DateTime.now().toIso8601String(),
    };
  }
}
