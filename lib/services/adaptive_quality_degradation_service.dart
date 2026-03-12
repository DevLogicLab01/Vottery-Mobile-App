import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Adaptive Quality Degradation Service
/// Device capability detection, resolution/fps targeting for carousels and video.
enum QualityLevel { high, medium, low, minimal }

class AdaptiveQualityDegradationService {
  static AdaptiveQualityDegradationService? _instance;
  static AdaptiveQualityDegradationService get instance =>
      _instance ??= AdaptiveQualityDegradationService._();

  AdaptiveQualityDegradationService._();

  double _lastFps = 60;
  QualityLevel _lastQuality = QualityLevel.high;
  String? _deviceTier;
  int? _cores;
  int? _memMb;

  /// Detect device capability
  Future<Map<String, dynamic>> detectDeviceCapability() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      int cores = 4;
      int memMb = 4;

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        cores = android.numberOfCores;
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        // iOS doesn't expose cores; use model heuristics
        cores = ios.model?.toLowerCase().contains('pro') == true ? 8 : 6;
      }

      _cores = cores;
      _memMb = memMb;

      String tier = 'high';
      if (cores <= 2 || memMb <= 2) tier = 'low';
      else if (cores <= 4 || memMb <= 4) tier = 'medium';

      _deviceTier = tier;
      final resolution = tier == 'high' ? 1080 : tier == 'medium' ? 720 : 480;
      final fpsTarget = tier == 'high' ? 60 : tier == 'medium' ? 45 : 30;

      return {
        'tier': tier,
        'resolution': resolution,
        'fpsTarget': fpsTarget,
        'cores': cores,
      };
    } catch (e) {
      debugPrint('AdaptiveQuality detectDeviceCapability: $e');
      return {'tier': 'medium', 'resolution': 720, 'fpsTarget': 45};
    }
  }

  /// Get target quality based on current FPS
  double getTargetQuality([double? currentFps]) {
    _lastFps = currentFps ?? _lastFps;
    final fpsTarget = _deviceTier == 'high' ? 60 : _deviceTier == 'medium' ? 45 : 30;
    if (_lastFps >= fpsTarget) {
      _lastQuality = QualityLevel.high;
      return 1.0;
    }
    if (_lastFps >= fpsTarget * 0.75) {
      _lastQuality = QualityLevel.medium;
      return 0.7;
    }
    if (_lastFps >= fpsTarget * 0.5) {
      _lastQuality = QualityLevel.low;
      return 0.5;
    }
    _lastQuality = QualityLevel.minimal;
    return 0.3;
  }

  /// Resolution multiplier for image/video (0.3–1)
  double getResolutionMultiplier([double? currentFps]) =>
      getTargetQuality(currentFps);

  int getFpsTarget() =>
      _deviceTier == 'high' ? 60 : _deviceTier == 'medium' ? 45 : 30;
}
