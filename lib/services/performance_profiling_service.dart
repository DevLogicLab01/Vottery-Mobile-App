import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Performance Profiling Service for per-screen monitoring
class PerformanceProfilingService {
  static PerformanceProfilingService? _instance;
  static PerformanceProfilingService get instance =>
      _instance ??= PerformanceProfilingService._();

  PerformanceProfilingService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  final Map<String, DateTime> _screenLoadTimes = {};
  final Map<String, List<double>> _frameRenderTimes = {};
  Timer? _metricsCollectionTimer;
  String? _currentSessionId;

  /// Start performance profiling session
  void startProfilingSession() {
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _startMetricsCollection();
  }

  /// Stop performance profiling session
  void stopProfilingSession() {
    _metricsCollectionTimer?.cancel();
    _currentSessionId = null;
  }

  /// Record screen load start
  void recordScreenLoadStart(String screenName) {
    _screenLoadTimes[screenName] = DateTime.now();
  }

  /// Record screen load complete
  Future<void> recordScreenLoadComplete(String screenName) async {
    if (!_screenLoadTimes.containsKey(screenName)) return;

    final loadTime = DateTime.now()
        .difference(_screenLoadTimes[screenName]!)
        .inMilliseconds;
    _screenLoadTimes.remove(screenName);

    await _recordPerformanceMetric(
      screenName: screenName,
      loadTimeMs: loadTime,
    );
  }

  /// Record frame render time
  void recordFrameRenderTime(String screenName, double renderTimeMs) {
    if (!_frameRenderTimes.containsKey(screenName)) {
      _frameRenderTimes[screenName] = [];
    }
    _frameRenderTimes[screenName]!.add(renderTimeMs);

    // Keep only last 60 frames
    if (_frameRenderTimes[screenName]!.length > 60) {
      _frameRenderTimes[screenName]!.removeAt(0);
    }
  }

  /// Get screen performance metrics
  Future<List<Map<String, dynamic>>> getScreenPerformanceMetrics({
    required String screenName,
    int hours = 24,
  }) async {
    try {
      final response = await _client
          .from('screen_performance_metrics')
          .select()
          .eq('screen_name', screenName)
          .gte(
            'timestamp',
            DateTime.now().subtract(Duration(hours: hours)).toIso8601String(),
          )
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get screen performance metrics error: $e');
      return [];
    }
  }

  /// Get performance bottlenecks
  Future<List<Map<String, dynamic>>> getPerformanceBottlenecks({
    String? screenName,
    String? severity,
    bool unresolvedOnly = false,
  }) async {
    try {
      var query = _client.from('performance_bottlenecks').select();

      if (screenName != null) {
        query = query.eq('screen_name', screenName);
      }

      if (severity != null) {
        query = query.eq('severity', severity);
      }

      if (unresolvedOnly) {
        query = query.isFilter('resolved_at', null);
      }

      final response = await query.order('detected_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get performance bottlenecks error: $e');
      return [];
    }
  }

  /// Get optimization recommendations
  Future<List<Map<String, dynamic>>> getOptimizationRecommendations({
    required String screenName,
    String? status,
  }) async {
    try {
      var query = _client
          .from('optimization_recommendations')
          .select()
          .eq('screen_name', screenName);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('priority', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get optimization recommendations error: $e');
      return [];
    }
  }

  /// Get flame graph data
  Future<Map<String, dynamic>?> getFlameGraphData({
    required String screenName,
    String? sessionId,
  }) async {
    try {
      var query = _client
          .from('flame_graph_data')
          .select()
          .eq('screen_name', screenName);

      if (sessionId != null) {
        query = query.eq('session_id', sessionId);
      }

      final response = await query
          .order('captured_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get flame graph data error: $e');
      return null;
    }
  }

  /// Get performance timeline events
  Future<List<Map<String, dynamic>>> getPerformanceTimelineEvents({
    required String screenName,
    String? sessionId,
    String? eventType,
  }) async {
    try {
      var query = _client
          .from('performance_timeline_events')
          .select()
          .eq('screen_name', screenName);

      if (sessionId != null) {
        query = query.eq('session_id', sessionId);
      }

      if (eventType != null) {
        query = query.eq('event_type', eventType);
      }

      final response = await query.order('timestamp', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get performance timeline events error: $e');
      return [];
    }
  }

  /// Create performance comparison report
  Future<String?> createPerformanceComparisonReport({
    required String screenName,
    required String baselineSessionId,
    required String optimizedSessionId,
  }) async {
    try {
      final baselineMetrics = await _getSessionMetrics(
        screenName,
        baselineSessionId,
      );
      final optimizedMetrics = await _getSessionMetrics(
        screenName,
        optimizedSessionId,
      );

      if (baselineMetrics.isEmpty || optimizedMetrics.isEmpty) {
        return null;
      }

      final cpuImprovement = _calculateImprovement(
        baselineMetrics['cpu_usage_percentage'],
        optimizedMetrics['cpu_usage_percentage'],
      );

      final memoryImprovement = _calculateImprovement(
        baselineMetrics['memory_usage_mb'],
        optimizedMetrics['memory_usage_mb'],
      );

      final networkImprovement = _calculateImprovement(
        baselineMetrics['network_bandwidth_mbps'],
        optimizedMetrics['network_bandwidth_mbps'],
      );

      final fpsImprovement = _calculateImprovement(
        optimizedMetrics['fps'],
        baselineMetrics['fps'],
        inverse: true,
      );

      final loadTimeImprovement =
          (baselineMetrics['load_time_ms'] ?? 0) -
          (optimizedMetrics['load_time_ms'] ?? 0);

      final reportJson = {
        'baseline_metrics': baselineMetrics,
        'optimized_metrics': optimizedMetrics,
        'improvements': {
          'cpu': cpuImprovement,
          'memory': memoryImprovement,
          'network': networkImprovement,
          'fps': fpsImprovement,
          'load_time_ms': loadTimeImprovement,
        },
      };

      final response = await _client
          .from('performance_comparison_reports')
          .insert({
            'screen_name': screenName,
            'baseline_session_id': baselineSessionId,
            'optimized_session_id': optimizedSessionId,
            'cpu_improvement_percentage': cpuImprovement,
            'memory_improvement_percentage': memoryImprovement,
            'network_improvement_percentage': networkImprovement,
            'fps_improvement_percentage': fpsImprovement,
            'load_time_improvement_ms': loadTimeImprovement,
            'report_json': reportJson,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Create performance comparison report error: $e');
      return null;
    }
  }

  /// Get performance bottleneck summary
  Future<Map<String, dynamic>> getPerformanceBottleneckSummary({
    int hours = 24,
  }) async {
    try {
      final response = await _client.rpc(
        'get_performance_bottleneck_summary',
        params: {'p_hours': hours},
      );

      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      debugPrint('Get performance bottleneck summary error: $e');
      return {};
    }
  }

  /// Export performance report as JSON
  Future<String> exportPerformanceReportJSON({
    required String screenName,
    int hours = 24,
  }) async {
    try {
      final metrics = await getScreenPerformanceMetrics(
        screenName: screenName,
        hours: hours,
      );
      final bottlenecks = await getPerformanceBottlenecks(
        screenName: screenName,
      );
      final recommendations = await getOptimizationRecommendations(
        screenName: screenName,
      );

      final report = {
        'screen_name': screenName,
        'generated_at': DateTime.now().toIso8601String(),
        'time_range_hours': hours,
        'metrics': metrics,
        'bottlenecks': bottlenecks,
        'recommendations': recommendations,
      };

      return report.toString();
    } catch (e) {
      debugPrint('Export performance report JSON error: $e');
      return '{}';
    }
  }

  /// Mark optimization recommendation as implemented
  Future<bool> markRecommendationImplemented(String recommendationId) async {
    try {
      await _client
          .from('optimization_recommendations')
          .update({
            'status': 'implemented',
            'implemented_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recommendationId);

      return true;
    } catch (e) {
      debugPrint('Mark recommendation implemented error: $e');
      return false;
    }
  }

  /// Resolve performance bottleneck
  Future<bool> resolveBottleneck({
    required String bottleneckId,
    String? resolutionNotes,
  }) async {
    try {
      await _client
          .from('performance_bottlenecks')
          .update({
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution_notes': resolutionNotes,
          })
          .eq('id', bottleneckId);

      return true;
    } catch (e) {
      debugPrint('Resolve bottleneck error: $e');
      return false;
    }
  }

  /// Get performance thresholds
  Future<Map<String, dynamic>> getPerformanceThresholds() async {
    try {
      final response = await _client
          .from('performance_thresholds')
          .select()
          .maybeSingle();

      return response ?? _getDefaultThresholds();
    } catch (e) {
      debugPrint('Get performance thresholds error: $e');
      return _getDefaultThresholds();
    }
  }

  Map<String, dynamic> _getDefaultThresholds() {
    return {
      'cpu_threshold': 80.0,
      'memory_threshold': 85.0,
      'network_threshold': 90.0,
      'fps_threshold': 30.0,
    };
  }

  // Private helper methods

  void _startMetricsCollection() {
    _metricsCollectionTimer?.cancel();
    _metricsCollectionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _collectMetrics(),
    );
  }

  Future<void> _collectMetrics() async {
    if (_currentSessionId == null) return;

    // Collect system metrics (simulated for now)
    // In production, use platform-specific APIs
    final cpuUsage = _simulateCPUUsage();
    final memoryUsage = _simulateMemoryUsage();
    final networkBandwidth = _simulateNetworkBandwidth();

    // This would be called for each active screen
    // For now, we'll skip automatic collection
  }

  Future<void> _recordPerformanceMetric({
    required String screenName,
    int? loadTimeMs,
    double? cpuUsage,
    double? memoryUsage,
    double? networkBandwidth,
    double? frameRenderTime,
    double? fps,
  }) async {
    try {
      if (_currentSessionId == null) return;

      await _client.from('screen_performance_metrics').insert({
        'user_id': _auth.isAuthenticated ? _auth.currentUser!.id : null,
        'screen_name': screenName,
        'session_id': _currentSessionId,
        'cpu_usage_percentage': cpuUsage ?? 0.0,
        'memory_usage_mb': memoryUsage ?? 0.0,
        'network_bandwidth_mbps': networkBandwidth ?? 0.0,
        'frame_render_time_ms': frameRenderTime ?? 0.0,
        'fps': fps ?? 60.0,
        'load_time_ms': loadTimeMs ?? 0,
      });

      // Check for bottlenecks
      await _detectBottlenecks(
        screenName: screenName,
        cpuUsage: cpuUsage ?? 0.0,
        memoryUsage: memoryUsage ?? 0.0,
        networkBandwidth: networkBandwidth ?? 0.0,
        fps: fps ?? 60.0,
      );
    } catch (e) {
      debugPrint('Record performance metric error: $e');
    }
  }

  Future<void> _detectBottlenecks({
    required String screenName,
    required double cpuUsage,
    required double memoryUsage,
    required double networkBandwidth,
    required double fps,
  }) async {
    try {
      // CPU bottleneck
      if (cpuUsage > 70.0) {
        await _createBottleneck(
          screenName: screenName,
          type: 'cpu',
          severity: cpuUsage > 90.0 ? 'critical' : 'high',
          thresholdExceeded: 'CPU usage > 70%',
          actualValue: cpuUsage,
          thresholdValue: 70.0,
        );
      }

      // Memory bottleneck
      if (memoryUsage > 500.0) {
        await _createBottleneck(
          screenName: screenName,
          type: 'memory',
          severity: memoryUsage > 800.0 ? 'critical' : 'high',
          thresholdExceeded: 'Memory usage > 500MB',
          actualValue: memoryUsage,
          thresholdValue: 500.0,
        );
      }

      // Network bottleneck
      if (networkBandwidth > 5.0) {
        await _createBottleneck(
          screenName: screenName,
          type: 'network',
          severity: networkBandwidth > 10.0 ? 'critical' : 'high',
          thresholdExceeded: 'Network bandwidth > 5MB/s',
          actualValue: networkBandwidth,
          thresholdValue: 5.0,
        );
      }

      // Rendering bottleneck
      if (fps < 45.0) {
        await _createBottleneck(
          screenName: screenName,
          type: 'rendering',
          severity: fps < 30.0 ? 'critical' : 'high',
          thresholdExceeded: 'FPS < 45',
          actualValue: fps,
          thresholdValue: 45.0,
        );
      }
    } catch (e) {
      debugPrint('Detect bottlenecks error: $e');
    }
  }

  Future<void> _createBottleneck({
    required String screenName,
    required String type,
    required String severity,
    required String thresholdExceeded,
    required double actualValue,
    required double thresholdValue,
  }) async {
    try {
      await _client.from('performance_bottlenecks').insert({
        'screen_name': screenName,
        'bottleneck_type': type,
        'severity': severity,
        'threshold_exceeded': thresholdExceeded,
        'actual_value': actualValue,
        'threshold_value': thresholdValue,
        'detection_algorithm': 'threshold_based',
      });

      // Generate optimization recommendation
      await _generateOptimizationRecommendation(
        screenName: screenName,
        bottleneckType: type,
        severity: severity,
      );
    } catch (e) {
      debugPrint('Create bottleneck error: $e');
    }
  }

  Future<void> _generateOptimizationRecommendation({
    required String screenName,
    required String bottleneckType,
    required String severity,
  }) async {
    try {
      String recommendationType;
      String recommendationText;
      double estimatedImprovement;

      switch (bottleneckType) {
        case 'cpu':
          recommendationType = 'reduce_rebuilds';
          recommendationText =
              'Reduce widget rebuilds by using const constructors and memoization. Consider using Provider or Riverpod for state management.';
          estimatedImprovement = 25.0;
          break;
        case 'memory':
          recommendationType = 'lazy_load';
          recommendationText =
              'Implement lazy loading for lists and images. Use ListView.builder instead of ListView for large datasets.';
          estimatedImprovement = 30.0;
          break;
        case 'network':
          recommendationType = 'optimize_network';
          recommendationText =
              'Optimize network calls by implementing caching, request batching, and compression. Consider using pagination.';
          estimatedImprovement = 40.0;
          break;
        case 'rendering':
          recommendationType = 'image_optimization';
          recommendationText =
              'Optimize images by using CachedNetworkImage, implementing proper image sizes, and using WebP format.';
          estimatedImprovement = 35.0;
          break;
        default:
          return;
      }

      await _client.from('optimization_recommendations').insert({
        'screen_name': screenName,
        'recommendation_type': recommendationType,
        'recommendation_text': recommendationText,
        'priority': severity,
        'estimated_improvement_percentage': estimatedImprovement,
        'implementation_complexity': 'medium',
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('Generate optimization recommendation error: $e');
    }
  }

  Future<Map<String, dynamic>> _getSessionMetrics(
    String screenName,
    String sessionId,
  ) async {
    try {
      final response = await _client
          .from('screen_performance_metrics')
          .select()
          .eq('screen_name', screenName)
          .eq('session_id', sessionId);

      final metrics = List<Map<String, dynamic>>.from(response);

      if (metrics.isEmpty) return {};

      // Calculate averages
      final avgCpu =
          metrics
              .map((m) => m['cpu_usage_percentage'] as num)
              .reduce((a, b) => a + b) /
          metrics.length;
      final avgMemory =
          metrics
              .map((m) => m['memory_usage_mb'] as num)
              .reduce((a, b) => a + b) /
          metrics.length;
      final avgNetwork =
          metrics
              .map((m) => m['network_bandwidth_mbps'] as num)
              .reduce((a, b) => a + b) /
          metrics.length;
      final avgFps =
          metrics.map((m) => m['fps'] as num).reduce((a, b) => a + b) /
          metrics.length;
      final avgLoadTime =
          metrics.map((m) => m['load_time_ms'] as num).reduce((a, b) => a + b) /
          metrics.length;

      return {
        'cpu_usage_percentage': avgCpu,
        'memory_usage_mb': avgMemory,
        'network_bandwidth_mbps': avgNetwork,
        'fps': avgFps,
        'load_time_ms': avgLoadTime.toInt(),
      };
    } catch (e) {
      debugPrint('Get session metrics error: $e');
      return {};
    }
  }

  double _calculateImprovement(
    num baseline,
    num optimized, {
    bool inverse = false,
  }) {
    if (baseline == 0) return 0.0;

    if (inverse) {
      return ((optimized - baseline) / baseline * 100).toDouble();
    } else {
      return ((baseline - optimized) / baseline * 100).toDouble();
    }
  }

  double _simulateCPUUsage() {
    return 30.0 + (DateTime.now().millisecond % 40);
  }

  double _simulateMemoryUsage() {
    return 200.0 + (DateTime.now().millisecond % 300);
  }

  double _simulateNetworkBandwidth() {
    return 1.0 + (DateTime.now().millisecond % 3);
  }
}
