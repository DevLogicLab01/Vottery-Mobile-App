import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import './supabase_service.dart';

/// Quality Level Enum
enum QualityLevel { high, medium, low }

/// Carousel Performance Monitoring Service
/// Tracks FPS, battery impact, and manages adaptive quality
class CarouselPerformanceService {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final Battery _battery = Battery();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // FPS Tracking
  final List<Duration> _frameDurations = [];
  int _frameDrops = 0;
  DateTime? _sessionStart;
  QualityLevel _currentQuality = QualityLevel.high;

  // Battery Tracking
  int? _batteryLevelStart;
  DateTime? _batteryTrackingStart;

  // Device Info
  String? _deviceModel;
  int? _deviceRAM;

  // Callbacks
  Function(QualityLevel)? onQualityChanged;
  Function(double)? onFPSUpdate;

  QualityLevel get currentQuality => _currentQuality;

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> initialize() async {
    await _loadDeviceInfo();
    await _startBatteryTracking();
    _startFPSTracking();
    _checkDeviceCapabilities();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        // Estimate RAM (not directly available)
        _deviceRAM = 4096; // Default 4GB
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceModel = '${iosInfo.name} ${iosInfo.model}';
        _deviceRAM = 4096; // Default 4GB
      }
    } catch (e) {
      debugPrint('Error loading device info: $e');
    }
  }

  // ============================================
  // FPS TRACKING
  // ============================================

  void _startFPSTracking() {
    _sessionStart = DateTime.now();
    SchedulerBinding.instance.addTimingsCallback(_onFrameRendered);
  }

  void _onFrameRendered(List<FrameTiming> timings) {
    for (var timing in timings) {
      final frameDuration = timing.totalSpan;
      _frameDurations.add(frameDuration);

      // Check for frame drops (>16.67ms = missed 60fps frame)
      if (frameDuration.inMilliseconds > 16.67) {
        _frameDrops++;
      }

      // Keep only last 60 frames for rolling average
      if (_frameDurations.length > 60) {
        _frameDurations.removeAt(0);
      }
    }

    // Calculate current FPS
    final avgFPS = _calculateCurrentFPS();
    onFPSUpdate?.call(avgFPS);

    // Check for sustained low FPS
    if (avgFPS < 45 && _frameDurations.length >= 60) {
      _handleLowFPS(avgFPS);
    }
  }

  double _calculateCurrentFPS() {
    if (_frameDurations.isEmpty) return 60.0;

    final avgDuration =
        _frameDurations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) /
        _frameDurations.length;

    final fps = 1000000 / avgDuration; // Convert microseconds to FPS
    return fps.clamp(0.0, 60.0);
  }

  void _handleLowFPS(double avgFPS) {
    if (_currentQuality == QualityLevel.high) {
      _degradeQuality();
      _logPerformanceEvent(
        eventType: 'low_fps',
        severity: 'medium',
        metrics: {'avg_fps': avgFPS, 'frame_drops': _frameDrops},
      );
    } else if (_currentQuality == QualityLevel.medium && avgFPS < 30) {
      _degradeQuality();
      _logPerformanceEvent(
        eventType: 'low_fps',
        severity: 'high',
        metrics: {'avg_fps': avgFPS, 'frame_drops': _frameDrops},
      );
    }
  }

  Future<void> saveFPSMetrics({
    required String userId,
    required String screenName,
    String? carouselType,
  }) async {
    try {
      final avgFPS = _calculateCurrentFPS();
      final sessionDuration = _sessionStart != null
          ? DateTime.now().difference(_sessionStart!).inSeconds
          : 0;

      await _supabaseService.client.from('performance_metrics_fps').insert({
        'user_id': userId,
        'screen_name': screenName,
        'carousel_type': carouselType,
        'avg_fps': avgFPS,
        'frame_drops_count': _frameDrops,
        'session_duration_seconds': sessionDuration,
        'device_model': _deviceModel,
        'quality_level': _currentQuality.name,
        'recorded_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving FPS metrics: $e');
    }
  }

  // ============================================
  // BATTERY TRACKING
  // ============================================

  Future<void> _startBatteryTracking() async {
    try {
      _batteryLevelStart = await _battery.batteryLevel;
      _batteryTrackingStart = DateTime.now();

      // Listen to battery level changes
      _battery.onBatteryStateChanged.listen((state) {
        _checkBatteryImpact();
      });
    } catch (e) {
      debugPrint('Error starting battery tracking: $e');
    }
  }

  Future<void> _checkBatteryImpact() async {
    try {
      final currentLevel = await _battery.batteryLevel;

      if (_batteryLevelStart != null && _batteryTrackingStart != null) {
        final elapsedHours =
            DateTime.now().difference(_batteryTrackingStart!).inMinutes / 60.0;
        final drainPercent = _batteryLevelStart! - currentLevel;

        if (elapsedHours > 0) {
          final drainRate = drainPercent / elapsedHours;

          // High battery drain (>5% per hour)
          if (drainRate > 5.0 && _currentQuality == QualityLevel.high) {
            _degradeQuality();
            _logPerformanceEvent(
              eventType: 'high_battery_drain',
              severity: 'medium',
              metrics: {'drain_rate': drainRate},
            );
          }
        }

        // Low battery level (<20%)
        if (currentLevel < 20 && _currentQuality != QualityLevel.low) {
          setQuality(QualityLevel.low);
          _logPerformanceEvent(
            eventType: 'low_battery_level',
            severity: 'high',
            metrics: {'battery_level': currentLevel},
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking battery impact: $e');
    }
  }

  Future<void> saveBatteryMetrics({
    required String userId,
    required String carouselType,
  }) async {
    try {
      final currentLevel = await _battery.batteryLevel;

      if (_batteryLevelStart != null && _batteryTrackingStart != null) {
        final elapsedMinutes = DateTime.now()
            .difference(_batteryTrackingStart!)
            .inMinutes;
        final drainPercent = _batteryLevelStart! - currentLevel;
        final elapsedHours = elapsedMinutes / 60.0;
        final drainRate = elapsedHours > 0 ? drainPercent / elapsedHours : 0.0;

        await _supabaseService.client.from('battery_impact_metrics').insert({
          'user_id': userId,
          'carousel_type': carouselType,
          'battery_drain_rate': drainRate,
          'usage_duration_minutes': elapsedMinutes,
          'device_model': _deviceModel,
          'quality_level': _currentQuality.name,
          'battery_level_start': _batteryLevelStart,
          'battery_level_end': currentLevel,
          'recorded_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error saving battery metrics: $e');
    }
  }

  // ============================================
  // QUALITY MANAGEMENT
  // ============================================

  void _checkDeviceCapabilities() {
    // Auto-degrade quality for low-end devices
    if (_deviceRAM != null && _deviceRAM! < 4096) {
      setQuality(QualityLevel.medium);
    }
  }

  void _degradeQuality() {
    if (_currentQuality == QualityLevel.high) {
      setQuality(QualityLevel.medium);
    } else if (_currentQuality == QualityLevel.medium) {
      setQuality(QualityLevel.low);
    }
  }

  void setQuality(QualityLevel quality) {
    if (_currentQuality != quality) {
      _currentQuality = quality;
      onQualityChanged?.call(quality);
      debugPrint('Quality changed to: ${quality.name}');
    }
  }

  // ============================================
  // PERFORMANCE EVENTS
  // ============================================

  Future<void> _logPerformanceEvent({
    required String eventType,
    required String severity,
    required Map<String, dynamic> metrics,
  }) async {
    try {
      await _supabaseService.client.from('performance_events').insert({
        'event_type': eventType,
        'severity': severity,
        'device_info': {'model': _deviceModel, 'ram': _deviceRAM},
        'metrics': metrics,
        'action_taken': 'Quality degraded to ${_currentQuality.name}',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging performance event: $e');
    }
  }

  // ============================================
  // CLEANUP
  // ============================================

  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onFrameRendered);
    _frameDurations.clear();
  }
}
