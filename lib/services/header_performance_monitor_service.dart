import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeaderPerformanceMetric {
  final String screenName;
  final double frameRate;
  final int avgFrameTimeMs;
  final int layoutTimeMs;
  final int iconRenderTimeMs;
  final int sampleSize;
  final DateTime recordedAt;

  HeaderPerformanceMetric({
    required this.screenName,
    required this.frameRate,
    required this.avgFrameTimeMs,
    required this.layoutTimeMs,
    required this.iconRenderTimeMs,
    this.sampleSize = 1,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'screen_name': screenName,
    'frame_rate': frameRate,
    'avg_frame_time_ms': avgFrameTimeMs,
    'layout_time_ms': layoutTimeMs,
    'icon_render_time_ms': iconRenderTimeMs,
    'sample_size': sampleSize,
    'recorded_at': recordedAt.toIso8601String(),
  };

  String get status {
    if (frameRate >= 55) return 'good';
    if (frameRate >= 45) return 'warning';
    return 'poor';
  }

  Color get statusColor {
    if (frameRate >= 55) return const Color(0xFF10B981);
    if (frameRate >= 45) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

class HeaderPerformanceMonitorService {
  static final HeaderPerformanceMonitorService _instance =
      HeaderPerformanceMonitorService._internal();
  factory HeaderPerformanceMonitorService() => _instance;
  HeaderPerformanceMonitorService._internal();

  static HeaderPerformanceMonitorService get instance => _instance;

  final _supabase = Supabase.instance.client;
  final Map<String, List<double>> _frameTimings = {};
  final Map<String, int> _layoutTimes = {};
  final Map<String, int> _iconRenderTimes = {};
  final Map<String, int> _sampleCounts = {};

  String? _currentScreen;
  Stopwatch? _layoutStopwatch;
  bool _isMonitoring = false;

  // Alert threshold: < 30fps for 3 seconds triggers alert
  final Map<String, DateTime> _poorPerformanceStart = {};
  static const double _alertThresholdFps = 30.0;
  static const Duration _alertDuration = Duration(seconds: 3);

  void startMonitoring(String screenName) {
    _currentScreen = screenName;
    _isMonitoring = true;
    _frameTimings[screenName] ??= [];
    _sampleCounts[screenName] = (_sampleCounts[screenName] ?? 0) + 1;

    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
  }

  void stopMonitoring() {
    if (_currentScreen != null) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
      _flushMetrics(_currentScreen!);
    }
    _isMonitoring = false;
    _currentScreen = null;
  }

  void startLayoutMeasurement(String screenName) {
    _layoutStopwatch = Stopwatch()..start();
  }

  void endLayoutMeasurement(String screenName) {
    if (_layoutStopwatch != null) {
      _layoutTimes[screenName] = _layoutStopwatch!.elapsedMilliseconds;
      _layoutStopwatch!.stop();
      _layoutStopwatch = null;
    }
  }

  void recordIconRenderTime(String screenName, int milliseconds) {
    _iconRenderTimes[screenName] = milliseconds;
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (_currentScreen == null) return;
    for (final timing in timings) {
      final frameTimeMs = timing.totalSpan.inMicroseconds / 1000.0;
      _frameTimings[_currentScreen!]!.add(frameTimeMs);
      // Keep only last 60 frames
      if (_frameTimings[_currentScreen!]!.length > 60) {
        _frameTimings[_currentScreen!]!.removeAt(0);
      }
    }
    _checkAlertThreshold(_currentScreen!);
  }

  void _checkAlertThreshold(String screenName) {
    final fps = _calculateFps(screenName);
    if (fps < _alertThresholdFps) {
      _poorPerformanceStart[screenName] ??= DateTime.now();
      final elapsed = DateTime.now().difference(
        _poorPerformanceStart[screenName]!,
      );
      if (elapsed >= _alertDuration) {
        debugPrint(
          '[HeaderPerformanceMonitor] ALERT: $screenName has poor frame rate (${fps.toStringAsFixed(1)} fps)',
        );
        _poorPerformanceStart.remove(screenName);
      }
    } else {
      _poorPerformanceStart.remove(screenName);
    }
  }

  double _calculateFps(String screenName) {
    final timings = _frameTimings[screenName];
    if (timings == null || timings.isEmpty) return 60.0;
    final avgFrameTimeMs = timings.reduce((a, b) => a + b) / timings.length;
    if (avgFrameTimeMs <= 0) return 60.0;
    return (1000.0 / avgFrameTimeMs).clamp(0.0, 120.0);
  }

  HeaderPerformanceMetric getMetricForScreen(String screenName) {
    final fps = _calculateFps(screenName);
    final timings = _frameTimings[screenName] ?? [];
    final avgFrameTimeMs = timings.isEmpty
        ? 16
        : (timings.reduce((a, b) => a + b) / timings.length).round();

    return HeaderPerformanceMetric(
      screenName: screenName,
      frameRate: fps,
      avgFrameTimeMs: avgFrameTimeMs,
      layoutTimeMs: _layoutTimes[screenName] ?? 0,
      iconRenderTimeMs: _iconRenderTimes[screenName] ?? 0,
      sampleSize: _sampleCounts[screenName] ?? 1,
    );
  }

  Future<void> _flushMetrics(String screenName) async {
    try {
      final metric = getMetricForScreen(screenName);
      await _supabase
          .from('header_performance_metrics')
          .insert(metric.toJson());
    } catch (e) {
      debugPrint('[HeaderPerformanceMonitor] Failed to save metrics: $e');
    }
  }

  Future<List<HeaderPerformanceMetric>> loadMetrics({
    String? screenName,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('header_performance_metrics')
          .select()
          .order('recorded_at', ascending: false)
          .limit(limit);

      if (screenName != null) {
        query = _supabase
            .from('header_performance_metrics')
            .select()
            .eq('screen_name', screenName)
            .order('recorded_at', ascending: false)
            .limit(limit);
      }

      final data = await query;
      return List<Map<String, dynamic>>.from(data)
          .map(
            (row) => HeaderPerformanceMetric(
              screenName: row['screen_name'] as String,
              frameRate: (row['frame_rate'] as num).toDouble(),
              avgFrameTimeMs: (row['avg_frame_time_ms'] as num).toInt(),
              layoutTimeMs: (row['layout_time_ms'] as num).toInt(),
              iconRenderTimeMs: (row['icon_render_time_ms'] as num).toInt(),
              sampleSize: (row['sample_size'] as num? ?? 1).toInt(),
              recordedAt: DateTime.parse(row['recorded_at'] as String),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[HeaderPerformanceMonitor] Failed to load metrics: $e');
      return _mockMetrics();
    }
  }

  Future<Map<String, dynamic>> loadAggregatedStats() async {
    try {
      final data = await _supabase
          .from('header_performance_metrics')
          .select(
            'screen_name, frame_rate, layout_time_ms, icon_render_time_ms',
          )
          .order('recorded_at', ascending: false)
          .limit(200);

      final records = List<Map<String, dynamic>>.from(data);
      if (records.isEmpty) return _mockAggregatedStats();

      double totalFps = 0;
      double totalLayout = 0;
      double totalIcon = 0;
      final Map<String, List<double>> screenFps = {};

      for (final r in records) {
        final fps = (r['frame_rate'] as num).toDouble();
        final layout = (r['layout_time_ms'] as num).toDouble();
        final icon = (r['icon_render_time_ms'] as num).toDouble();
        final screen = r['screen_name'] as String;
        totalFps += fps;
        totalLayout += layout;
        totalIcon += icon;
        screenFps[screen] ??= [];
        screenFps[screen]!.add(fps);
      }

      final avgFps = totalFps / records.length;
      final avgLayout = totalLayout / records.length;
      final avgIcon = totalIcon / records.length;

      // Top 10 slowest screens
      final screenAvgFps = screenFps.map(
        (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
      );
      final sortedScreens = screenAvgFps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final slowestScreens = sortedScreens.take(10).toList();

      // Layout time distribution
      final layoutBuckets = {
        '0-5ms': 0,
        '5-10ms': 0,
        '10-16ms': 0,
        '16-30ms': 0,
        '>30ms': 0,
      };
      for (final r in records) {
        final lt = (r['layout_time_ms'] as num).toInt();
        if (lt <= 5) {
          layoutBuckets['0-5ms'] = layoutBuckets['0-5ms']! + 1;
        } else if (lt <= 10)
          layoutBuckets['5-10ms'] = layoutBuckets['5-10ms']! + 1;
        else if (lt <= 16)
          layoutBuckets['10-16ms'] = layoutBuckets['10-16ms']! + 1;
        else if (lt <= 30)
          layoutBuckets['16-30ms'] = layoutBuckets['16-30ms']! + 1;
        else
          layoutBuckets['>30ms'] = layoutBuckets['>30ms']! + 1;
      }

      return {
        'avg_fps': avgFps,
        'avg_layout_ms': avgLayout,
        'avg_icon_ms': avgIcon,
        'total_samples': records.length,
        'slowest_screens': slowestScreens
            .map((e) => {'screen': e.key, 'fps': e.value})
            .toList(),
        'layout_distribution': layoutBuckets,
      };
    } catch (e) {
      debugPrint('[HeaderPerformanceMonitor] Failed to load stats: $e');
      return _mockAggregatedStats();
    }
  }

  List<HeaderPerformanceMetric> _mockMetrics() {
    final screens = [
      'vote_dashboard',
      'feature_performance_dashboard',
      'creator_analytics',
      'admin_dashboard',
      'vote_casting',
      'social_media_home_feed',
      'fraud_monitoring',
      'wallet_dashboard',
      'creator_marketplace',
      'blockchain_vote_verification',
    ];
    return screens.map((s) {
      final fps = 45.0 + (screens.indexOf(s) * 2.5);
      return HeaderPerformanceMetric(
        screenName: s,
        frameRate: fps.clamp(30.0, 60.0),
        avgFrameTimeMs: (1000 / fps.clamp(30.0, 60.0)).round(),
        layoutTimeMs: 5 + screens.indexOf(s),
        iconRenderTimeMs: 2 + screens.indexOf(s),
        sampleSize: 10 + screens.indexOf(s) * 3,
        recordedAt: DateTime.now().subtract(
          Duration(minutes: screens.indexOf(s) * 5),
        ),
      );
    }).toList();
  }

  Map<String, dynamic> _mockAggregatedStats() => {
    'avg_fps': 57.3,
    'avg_layout_ms': 8.4,
    'avg_icon_ms': 3.2,
    'total_samples': 1247,
    'slowest_screens': [
      {'screen': 'blockchain_vote_verification', 'fps': 38.2},
      {'screen': 'advanced_fraud_detection', 'fps': 42.1},
      {'screen': 'creator_analytics_dashboard', 'fps': 44.7},
      {'screen': 'social_media_home_feed', 'fps': 46.3},
      {'screen': 'carousel_performance_analytics', 'fps': 48.9},
    ],
    'layout_distribution': {
      '0-5ms': 423,
      '5-10ms': 512,
      '10-16ms': 234,
      '16-30ms': 67,
      '>30ms': 11,
    },
  };
}
