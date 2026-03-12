import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import './supabase_service.dart';

/// Quality levels for adaptive rendering
enum QualityLevel {
  high, // All effects enabled
  medium, // Simplified effects
  low, // Basic rendering only
  auto, // Automatic based on performance
}

/// Performance monitoring service for carousels
class CarouselPerformanceMonitor {
  static CarouselPerformanceMonitor? _instance;
  static CarouselPerformanceMonitor get instance =>
      _instance ??= CarouselPerformanceMonitor._();

  CarouselPerformanceMonitor._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // FPS Tracking
  final List<Duration> _frameDurations = [];
  double _currentFPS = 60.0;
  int _frameDrops = 0;
  Timer? _fpsCalculationTimer;
  TimingsCallback? _frameCallback;

  // Battery Monitoring
  double? _batteryStartLevel;
  DateTime? _monitoringStartTime;
  StreamSubscription<BatteryState>? _batteryStateSubscription;

  // Quality Management
  QualityLevel _currentQuality = QualityLevel.auto;
  bool _isLowEndDevice = false;
  int _totalRAM = 0;

  // Thermal State
  bool _isThermalThrottling = false;

  // Getters
  double get currentFPS => _currentFPS;
  int get frameDrops => _frameDrops;
  QualityLevel get currentQuality => _currentQuality;
  bool get isLowEndDevice => _isLowEndDevice;
  bool get isThermalThrottling => _isThermalThrottling;

  /// Initialize performance monitoring
  Future<void> initialize() async {
    await _detectDeviceCapabilities();
    _startFPSMonitoring();
    _startBatteryMonitoring();
    _determineInitialQuality();
  }

  /// Dispose monitoring
  void dispose() {
    _fpsCalculationTimer?.cancel();
    _batteryStateSubscription?.cancel();
    if (_frameCallback != null) {
      SchedulerBinding.instance.removeTimingsCallback(_frameCallback!);
    }
  }

  // ============================================
  // FPS MONITORING
  // ============================================

  void _startFPSMonitoring() {
    _frameCallback = (List<FrameTiming> timings) {
      for (final timing in timings) {
        final frameDuration = timing.totalSpan;
        _frameDurations.add(frameDuration);

        // Check for frame drop (>16.67ms at 60fps)
        if (frameDuration.inMilliseconds > 16.67) {
          _frameDrops++;
        }

        // Keep only last 60 frames
        if (_frameDurations.length > 60) {
          _frameDurations.removeAt(0);
        }
      }
    };

    SchedulerBinding.instance.addTimingsCallback(_frameCallback!);

    // Calculate FPS every second
    _fpsCalculationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateFPS();
    });
  }

  void _calculateFPS() {
    if (_frameDurations.isEmpty) return;

    final avgDuration =
        _frameDurations.fold<int>(
          0,
          (sum, duration) => sum + duration.inMilliseconds,
        ) /
        _frameDurations.length;

    _currentFPS = avgDuration > 0 ? 1000 / avgDuration : 60.0;

    // Check for sustained low FPS
    if (_currentFPS < 30 && _currentQuality != QualityLevel.low) {
      _triggerQualityDegradation('Sustained low FPS detected');
    }
  }

  /// Record FPS metrics to database
  Future<void> recordFPSMetrics({
    required String screenName,
    required String carouselType,
  }) async {
    try {
      await _supabaseService.client.from('performance_metrics_fps').insert({
        'screen_name': screenName,
        'carousel_type': carouselType,
        'avg_fps': _currentFPS,
        'frame_drops_count': _frameDrops,
        'recorded_at': DateTime.now().toIso8601String(),
      });

      // Reset frame drops counter
      _frameDrops = 0;
    } catch (e) {
      debugPrint('Error recording FPS metrics: $e');
    }
  }

  // ============================================
  // BATTERY MONITORING
  // ============================================

  Future<void> _startBatteryMonitoring() async {
    try {
      _batteryStartLevel = (await _battery.batteryLevel).toDouble();
      _monitoringStartTime = DateTime.now();

      _batteryStateSubscription = _battery.onBatteryStateChanged.listen((
        state,
      ) {
        if (state == BatteryState.discharging) {
          _checkBatteryDrain();
        }
      });
    } catch (e) {
      debugPrint('Error starting battery monitoring: $e');
    }
  }

  Future<void> _checkBatteryDrain() async {
    if (_batteryStartLevel == null || _monitoringStartTime == null) return;

    try {
      final currentLevel = (await _battery.batteryLevel).toDouble();
      final elapsedHours =
          DateTime.now().difference(_monitoringStartTime!).inMinutes / 60.0;

      if (elapsedHours > 0) {
        final drainRate = (_batteryStartLevel! - currentLevel) / elapsedHours;

        // Trigger quality reduction if battery < 20%
        if (currentLevel < 20 && _currentQuality != QualityLevel.low) {
          _triggerQualityDegradation('Low battery level');
        }
      }
    } catch (e) {
      debugPrint('Error checking battery drain: $e');
    }
  }

  /// Record battery impact metrics
  Future<void> recordBatteryImpact({
    required String carouselType,
    required int usageDurationMinutes,
  }) async {
    if (_batteryStartLevel == null) return;

    try {
      final currentLevel = (await _battery.batteryLevel).toDouble();
      final drainRate = _batteryStartLevel! - currentLevel;

      String deviceModel = 'Unknown';
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceModel = '${iosInfo.name} ${iosInfo.model}';
      }

      await _supabaseService.client.from('battery_impact_metrics').insert({
        'carousel_type': carouselType,
        'battery_drain_rate': drainRate,
        'usage_duration_minutes': usageDurationMinutes,
        'device_model': deviceModel,
        'quality_level': _currentQuality.name,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error recording battery impact: $e');
    }
  }

  // ============================================
  // DEVICE CAPABILITIES
  // ============================================

  Future<void> _detectDeviceCapabilities() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Estimate RAM (not directly available, use heuristics)
        _totalRAM = 4; // Default assumption
        _isLowEndDevice = _totalRAM < 4;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // iOS devices generally have good performance
        _isLowEndDevice = false;
        _totalRAM = 4;
      } else {
        // Web or other platforms
        _isLowEndDevice = false;
        _totalRAM = 8;
      }
    } catch (e) {
      debugPrint('Error detecting device capabilities: $e');
      _isLowEndDevice = false;
    }
  }

  // ============================================
  // QUALITY MANAGEMENT
  // ============================================

  void _determineInitialQuality() {
    if (_isLowEndDevice) {
      _currentQuality = QualityLevel.low;
    } else {
      _currentQuality = QualityLevel.high;
    }
  }

  void _triggerQualityDegradation(String reason) {
    if (_currentQuality == QualityLevel.high) {
      _currentQuality = QualityLevel.medium;
    } else if (_currentQuality == QualityLevel.medium) {
      _currentQuality = QualityLevel.low;
    }

    debugPrint('Quality degraded to ${_currentQuality.name}: $reason');
  }

  /// Manually set quality level
  void setQualityLevel(QualityLevel level) {
    _currentQuality = level;
  }

  /// Check if effect should be enabled based on quality
  bool shouldEnableEffect(String effectName) {
    switch (_currentQuality) {
      case QualityLevel.high:
        return true;
      case QualityLevel.medium:
        return effectName != 'parallax' && effectName != 'glassmorphism';
      case QualityLevel.low:
        return false;
      case QualityLevel.auto:
        return _currentFPS >= 45;
    }
  }

  // ============================================
  // THERMAL THROTTLING
  // ============================================

  void checkThermalState() {
    // Platform-specific thermal state detection would go here
    // For now, use FPS as proxy
    if (_currentFPS < 30 && _frameDrops > 10) {
      _isThermalThrottling = true;
      _triggerQualityDegradation('Thermal throttling detected');
    } else {
      _isThermalThrottling = false;
    }
  }
}
