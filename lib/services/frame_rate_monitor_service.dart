import 'dart:async';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart'; // Add this import for WidgetsBinding

/// Frame Rate Monitor Service
/// Tracks FPS, identifies dropped frames, and logs problematic screens
class FrameRateMonitorService {
  static FrameRateMonitorService? _instance;
  static FrameRateMonitorService get instance =>
      _instance ??= FrameRateMonitorService._();

  FrameRateMonitorService._();

  static const double _targetFps = 60.0;
  static const double _targetFrameMs = 1000.0 / _targetFps; // 16.67ms
  static const double _criticalFps = 45.0;

  final Map<String, List<double>> _screenFpsHistory = {};
  final Map<String, int> _droppedFramesByScreen = {};
  final List<String> _problematicScreens = [];
  String _currentScreen = 'unknown';
  double _currentFps = 60.0;
  bool _isMonitoring = false;

  final StreamController<FrameRateEvent> _fpsStream =
      StreamController.broadcast();

  Stream<FrameRateEvent> get fpsStream => _fpsStream.stream;
  double get currentFps => _currentFps;
  List<String> get problematicScreens => List.unmodifiable(_problematicScreens);

  /// Start monitoring frame rates
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    WidgetsBinding.instance.addTimingsCallback(_onFrameTimings);
    debugPrint('✅ FrameRateMonitor started - target: ${_targetFps}fps');
  }

  /// Stop monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    _isMonitoring = false;
    WidgetsBinding.instance.removeTimingsCallback(_onFrameTimings);
    debugPrint('⏹️ FrameRateMonitor stopped');
  }

  /// Set current screen name for tracking
  void setCurrentScreen(String screenName) {
    _currentScreen = screenName;
  }

  /// Called by Flutter's timing callback
  void _onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      final frameDurationMs = timing.totalSpan.inMicroseconds / 1000.0;
      final fps = frameDurationMs > 0 ? 1000.0 / frameDurationMs : 60.0;

      _currentFps = fps;

      // Track per-screen
      _screenFpsHistory.putIfAbsent(_currentScreen, () => []);
      final history = _screenFpsHistory[_currentScreen]!;
      history.add(fps);
      if (history.length > 120) history.removeAt(0); // Keep last 2 seconds

      // Detect dropped frames (> 16.67ms)
      if (frameDurationMs > _targetFrameMs) {
        _droppedFramesByScreen[_currentScreen] =
            (_droppedFramesByScreen[_currentScreen] ?? 0) + 1;
      }

      // Check if screen is problematic (avg fps < 45)
      if (history.length >= 30) {
        final avgFps = history.reduce((a, b) => a + b) / history.length;
        if (avgFps < _criticalFps &&
            !_problematicScreens.contains(_currentScreen)) {
          _problematicScreens.add(_currentScreen);
          debugPrint(
            '⚠️ Problematic screen detected: $_currentScreen (${avgFps.toStringAsFixed(1)}fps)',
          );
        }
      }

      // Emit event
      if (!_fpsStream.isClosed) {
        _fpsStream.add(
          FrameRateEvent(
            screen: _currentScreen,
            fps: fps,
            frameDurationMs: frameDurationMs,
            isDropped: frameDurationMs > _targetFrameMs,
            buildTimeMs: timing.buildDuration.inMicroseconds / 1000.0,
            layoutTimeMs: 0.0, // layoutDuration not available in FrameTiming
            paintTimeMs: timing.rasterDuration.inMicroseconds / 1000.0,
          ),
        );
      }
    }
  }

  /// Get average FPS for a screen
  double getAverageFps(String screenName) {
    final history = _screenFpsHistory[screenName];
    if (history == null || history.isEmpty) return 60.0;
    return history.reduce((a, b) => a + b) / history.length;
  }

  /// Get dropped frame count for a screen
  int getDroppedFrames(String screenName) {
    return _droppedFramesByScreen[screenName] ?? 0;
  }

  /// Get performance report
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{};
    _screenFpsHistory.forEach((screen, history) {
      if (history.isNotEmpty) {
        final avg = history.reduce((a, b) => a + b) / history.length;
        report[screen] = {
          'avg_fps': avg.toStringAsFixed(1),
          'dropped_frames': _droppedFramesByScreen[screen] ?? 0,
          'is_problematic': avg < _criticalFps,
        };
      }
    });
    return report;
  }

  void dispose() {
    stopMonitoring();
    _fpsStream.close();
  }
}

class FrameRateEvent {
  final String screen;
  final double fps;
  final double frameDurationMs;
  final bool isDropped;
  final double buildTimeMs;
  final double layoutTimeMs;
  final double paintTimeMs;

  const FrameRateEvent({
    required this.screen,
    required this.fps,
    required this.frameDurationMs,
    required this.isDropped,
    required this.buildTimeMs,
    required this.layoutTimeMs,
    required this.paintTimeMs,
  });
}