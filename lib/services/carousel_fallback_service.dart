import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Carousel Fallback Service
/// Detects low-end devices and provides graceful degradation
class CarouselFallbackService {
  static CarouselFallbackService? _instance;
  static CarouselFallbackService get instance =>
      _instance ??= CarouselFallbackService._();

  CarouselFallbackService._();

  static const String _prefKey = 'device_capability_profile';
  static const String _advancedCarouselKey = 'supports_advanced_carousels';
  static const int _lowEndMemoryThresholdMb = 2048; // 2GB

  bool _supportsAdvancedCarousels = true;
  String _preferredQualityLevel = 'high';
  bool _initialized = false;
  final Map<String, bool> _carouselFailureLog = {};

  /// Initialize and detect device capabilities
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _supportsAdvancedCarousels = prefs.getBool(_advancedCarouselKey) ?? true;
      _preferredQualityLevel =
          prefs.getString('preferred_quality_level') ?? 'high';
      _initialized = true;
      debugPrint(
        '✅ CarouselFallback: advanced=$_supportsAdvancedCarousels, quality=$_preferredQualityLevel',
      );
    } catch (e) {
      debugPrint('CarouselFallback init error: $e');
      _initialized = true;
    }
  }

  /// Check if device supports advanced carousels
  bool get supportsAdvancedCarousels => _supportsAdvancedCarousels;

  /// Get preferred quality level
  String get preferredQualityLevel => _preferredQualityLevel;

  /// Record a carousel render failure
  void recordRenderFailure(String carouselType, Object error) {
    _carouselFailureLog[carouselType] = true;
    debugPrint('⚠️ Carousel render failure: $carouselType - $error');

    // After 3 failures, disable advanced carousels
    final failureCount = _carouselFailureLog.values.where((v) => v).length;
    if (failureCount >= 3) {
      _disableAdvancedCarousels();
    }
  }

  /// Disable advanced carousels and save preference
  Future<void> _disableAdvancedCarousels() async {
    _supportsAdvancedCarousels = false;
    _preferredQualityLevel = 'low';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_advancedCarouselKey, false);
      await prefs.setString('preferred_quality_level', 'low');
    } catch (e) {
      debugPrint('Prefs save error: $e');
    }
    debugPrint('⚠️ Advanced carousels disabled due to render failures');
  }

  /// Allow manual override from settings
  Future<void> setAdvancedCarousels(bool enabled) async {
    _supportsAdvancedCarousels = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_advancedCarouselKey, enabled);
    } catch (e) {
      debugPrint('Prefs save error: $e');
    }
  }

  /// Check if a specific carousel has failed
  bool hasCarouselFailed(String carouselType) {
    return _carouselFailureLog[carouselType] ?? false;
  }

  /// Clear failure log
  void clearFailureLog() {
    _carouselFailureLog.clear();
  }
}
