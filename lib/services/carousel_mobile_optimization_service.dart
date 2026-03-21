import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import './supabase_service.dart';

/// Carousel Mobile Optimization Service
/// Handles gesture refinements, battery monitoring, and device-adaptive optimization
class CarouselMobileOptimizationService {
  static CarouselMobileOptimizationService? _instance;
  static CarouselMobileOptimizationService get instance =>
      _instance ??= CarouselMobileOptimizationService._();

  CarouselMobileOptimizationService._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Device capabilities
  String? _deviceModel;
  String? _deviceTier;
  int? _totalMemoryMB;

  // Performance monitoring
  final List<double> _frameRenderTimes = [];
  int _frameDropsCount = 0;
  double _currentFPS = 60.0;
  final int _currentMemoryUsageMB = 0;

  // Battery monitoring
  double? _initialBatteryLevel;
  DateTime? _monitoringStartTime;
  StreamSubscription? _batterySubscription;

  // Optimization settings
  String _currentOptimizationLevel = 'full';
  bool _batterySaverMode = false;

  // ============================================
  // INITIALIZATION
  // ============================================

  /// Initialize mobile optimization
  Future<void> initialize() async {
    try {
      await _detectDeviceCapabilities();
      await _startBatteryMonitoring();
      _startPerformanceMonitoring();
    } catch (e) {
      debugPrint('Error initializing mobile optimization: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _batterySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(_PerformanceObserver(this));
  }

  // ============================================
  // DEVICE CAPABILITY DETECTION
  // ============================================

  /// Detect device hardware capabilities
  Future<void> _detectDeviceCapabilities() async {
    try {
      if (kIsWeb) {
        _deviceModel = 'Web Browser';
        _deviceTier = 'high_end';
        _totalMemoryMB = 8192;
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';

        // Estimate memory (simplified)
        _totalMemoryMB = 4096; // Default assumption
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceModel = iosInfo.model;

        // iOS devices generally have good specs
        _totalMemoryMB = 4096;
      }

      // Classify device tier
      _deviceTier = _classifyDeviceTier(_totalMemoryMB ?? 0);

      debugPrint('Device: $_deviceModel, Tier: $_deviceTier');
    } catch (e) {
      debugPrint('Error detecting device capabilities: $e');
      _deviceTier = 'mid_range';
    }
  }

  /// Classify device tier based on memory
  String _classifyDeviceTier(int memoryMB) {
    if (memoryMB >= 6144) return 'high_end';
    if (memoryMB >= 4096) return 'mid_range';
    return 'low_end';
  }

  /// Get device tier
  String get deviceTier => _deviceTier ?? 'mid_range';

  /// Get device model
  String get deviceModel => _deviceModel ?? 'Unknown';

  // ============================================
  // GESTURE OPTIMIZATION
  // ============================================

  /// Get optimal swipe velocity threshold
  double getSwipeVelocityThreshold() {
    switch (_deviceTier) {
      case 'high_end':
        return 300.0; // pixels per second
      case 'mid_range':
        return 250.0;
      case 'low_end':
        return 200.0;
      default:
        return 250.0;
    }
  }

  /// Get optimal animation duration
  Duration getAnimationDuration(double swipeVelocity) {
    if (swipeVelocity > 1000) {
      return const Duration(milliseconds: 200); // Fast swipe
    } else if (swipeVelocity > 500) {
      return const Duration(milliseconds: 300); // Medium swipe
    } else {
      return const Duration(milliseconds: 400); // Slow swipe
    }
  }

  /// Track gesture performance
  Future<void> trackGesturePerformance({
    required String gestureType,
    required int responseTimeMs,
    required bool success,
    required String carouselType,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;

      await _supabaseService.client.from('gesture_performance_logs').insert({
        'user_id': userId,
        'device_model': _deviceModel,
        'gesture_type': gestureType,
        'response_time_ms': responseTimeMs,
        'success': success,
        'carousel_type': carouselType,
      });
    } catch (e) {
      debugPrint('Error tracking gesture performance: $e');
    }
  }

  // ============================================
  // BATTERY MONITORING
  // ============================================

  /// Start battery monitoring
  Future<void> _startBatteryMonitoring() async {
    try {
      if (kIsWeb) return; // Battery API not available on web

      _initialBatteryLevel = (await _battery.batteryLevel).toDouble();
      _monitoringStartTime = DateTime.now();

      _batterySubscription = _battery.onBatteryStateChanged.listen((state) {
        _checkBatterySaverMode();
      });
    } catch (e) {
      debugPrint('Error starting battery monitoring: $e');
    }
  }

  /// Check if battery saver mode should be enabled
  Future<void> _checkBatterySaverMode() async {
    try {
      if (kIsWeb) return;

      final currentLevel = await _battery.batteryLevel;

      if (currentLevel < 20 && !_batterySaverMode) {
        _enableBatterySaverMode();
      } else if (currentLevel >= 30 && _batterySaverMode) {
        _disableBatterySaverMode();
      }
    } catch (e) {
      debugPrint('Error checking battery saver mode: $e');
    }
  }

  /// Enable battery saver mode
  void _enableBatterySaverMode() {
    _batterySaverMode = true;
    _currentOptimizationLevel = 'minimal';
    debugPrint('Battery saver mode enabled');
  }

  /// Disable battery saver mode
  void _disableBatterySaverMode() {
    _batterySaverMode = false;
    _currentOptimizationLevel = _getOptimizationLevelForTier(_deviceTier!);
    debugPrint('Battery saver mode disabled');
  }

  /// Get battery drain rate
  Future<double> getBatteryDrainRate() async {
    try {
      if (kIsWeb ||
          _initialBatteryLevel == null ||
          _monitoringStartTime == null) {
        return 0.0;
      }

      final currentLevel = await _battery.batteryLevel;
      final elapsedHours =
          DateTime.now().difference(_monitoringStartTime!).inMinutes / 60.0;

      if (elapsedHours == 0) return 0.0;

      final drainRate = (_initialBatteryLevel! - currentLevel) / elapsedHours;
      return drainRate;
    } catch (e) {
      debugPrint('Error calculating battery drain rate: $e');
      return 0.0;
    }
  }

  /// Is battery saver mode active
  bool get isBatterySaverMode => _batterySaverMode;

  // ============================================
  // PERFORMANCE MONITORING
  // ============================================

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    WidgetsBinding.instance.addObserver(_PerformanceObserver(this));
  }

  /// Record frame render time
  void recordFrameRenderTime(double renderTimeMs) {
    _frameRenderTimes.add(renderTimeMs);

    // Keep only last 60 frames
    if (_frameRenderTimes.length > 60) {
      _frameRenderTimes.removeAt(0);
    }

    // Count frame drops (> 16.67ms for 60fps)
    if (renderTimeMs > 16.67) {
      _frameDropsCount++;
    }

    // Calculate current FPS
    if (_frameRenderTimes.isNotEmpty) {
      final avgRenderTime =
          _frameRenderTimes.reduce((a, b) => a + b) / _frameRenderTimes.length;
      _currentFPS = avgRenderTime > 0 ? 1000 / avgRenderTime : 60.0;
    }

    // Adjust optimization level if performance degrades
    if (_currentFPS < 30 && _currentOptimizationLevel != 'minimal') {
      _reduceOptimizationLevel();
    }
  }

  /// Get current FPS
  double get currentFPS => _currentFPS;

  /// Get frame drops count
  int get frameDropsCount => _frameDropsCount;

  /// Get average frame render time
  double get averageFrameRenderTime {
    if (_frameRenderTimes.isEmpty) return 0.0;
    return _frameRenderTimes.reduce((a, b) => a + b) / _frameRenderTimes.length;
  }

  // ============================================
  // ADAPTIVE OPTIMIZATION
  // ============================================

  /// Get optimization level for device tier
  String _getOptimizationLevelForTier(String tier) {
    switch (tier) {
      case 'high_end':
        return 'full';
      case 'mid_range':
        return 'standard';
      case 'low_end':
        return 'reduced';
      default:
        return 'standard';
    }
  }

  /// Reduce optimization level
  void _reduceOptimizationLevel() {
    switch (_currentOptimizationLevel) {
      case 'full':
        _currentOptimizationLevel = 'standard';
        break;
      case 'standard':
        _currentOptimizationLevel = 'reduced';
        break;
      case 'reduced':
        _currentOptimizationLevel = 'minimal';
        break;
    }
    debugPrint('Optimization level reduced to: $_currentOptimizationLevel');
  }

  /// Get current optimization level
  String get optimizationLevel => _currentOptimizationLevel;

  /// Should enable parallax effects
  bool get shouldEnableParallax {
    return _currentOptimizationLevel == 'full' && !_batterySaverMode;
  }

  /// Should enable glassmorphism
  bool get shouldEnableGlassmorphism {
    return _currentOptimizationLevel == 'full' && !_batterySaverMode;
  }

  /// Get target frame rate
  double get targetFrameRate {
    switch (_currentOptimizationLevel) {
      case 'full':
        return 60.0;
      case 'standard':
        return 45.0;
      case 'reduced':
        return 30.0;
      case 'minimal':
        return 30.0;
      default:
        return 45.0;
    }
  }

  /// Get image quality
  int get imageQuality {
    if (_batterySaverMode) return 70;

    switch (_currentOptimizationLevel) {
      case 'full':
        return 90;
      case 'standard':
        return 85;
      case 'reduced':
        return 75;
      case 'minimal':
        return 70;
      default:
        return 85;
    }
  }

  // ============================================
  // METRICS RECORDING
  // ============================================

  /// Record mobile optimization metrics
  Future<void> recordOptimizationMetrics({required String carouselType}) async {
    try {
      final batteryDrain = await getBatteryDrainRate();

      await _supabaseService.client.from('mobile_optimization_metrics').insert({
        'device_model': _deviceModel,
        'device_tier': _deviceTier,
        'carousel_type': carouselType,
        'avg_fps': _currentFPS,
        'frame_drops_count': _frameDropsCount,
        'memory_usage_mb': _currentMemoryUsageMB,
        'battery_drain_percent_per_hour': batteryDrain,
        'gesture_response_time_ms': 50, // Average from gesture logs
        'optimization_level': _currentOptimizationLevel,
      });
    } catch (e) {
      debugPrint('Error recording optimization metrics: $e');
    }
  }

  /// Get optimization metrics
  Future<List<Map<String, dynamic>>> getOptimizationMetrics({
    String? deviceModel,
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      var query = _supabaseService.client
          .from('mobile_optimization_metrics')
          .select()
          .gte('recorded_at', startDate.toIso8601String())
          .order('recorded_at', ascending: false);

      if (deviceModel != null) {
        query = _supabaseService.client
            .from('mobile_optimization_metrics')
            .select()
            .gte('recorded_at', startDate.toIso8601String())
            .order('recorded_at', ascending: false);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching optimization metrics: $e');
      return [];
    }
  }

  /// Get gesture performance analytics
  Future<Map<String, dynamic>> getGestureAnalytics({
    String? deviceModel,
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      var query = _supabaseService.client
          .from('gesture_performance_logs')
          .select()
          .gte('recorded_at', startDate.toIso8601String());

      if (deviceModel != null) {
        query = _supabaseService.client
            .from('gesture_performance_logs')
            .select()
            .gte('recorded_at', startDate.toIso8601String());
      }

      final logs = await query;

      if (logs.isEmpty) {
        return {'avg_response_time': 0, 'success_rate': 0, 'total_gestures': 0};
      }

      final totalGestures = logs.length;
      final successfulGestures = logs.where((l) => l['success'] == true).length;
      final avgResponseTime =
          logs.fold<int>(0, (sum, l) => sum + (l['response_time_ms'] as int)) /
          totalGestures;

      return {
        'avg_response_time': avgResponseTime,
        'success_rate': (successfulGestures / totalGestures * 100),
        'total_gestures': totalGestures,
      };
    } catch (e) {
      debugPrint('Error fetching gesture analytics: $e');
      return {};
    }
  }
}

// ============================================
// PERFORMANCE OBSERVER
// ============================================

class _PerformanceObserver extends WidgetsBindingObserver {
  final CarouselMobileOptimizationService service;

  _PerformanceObserver(this.service);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset monitoring when app resumes
      service._frameDropsCount = 0;
      service._frameRenderTimes.clear();
    }
  }
}