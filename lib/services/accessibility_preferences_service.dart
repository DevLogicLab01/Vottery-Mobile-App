import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './ga4_analytics_service.dart';

class AccessibilityPreferencesService {
  static AccessibilityPreferencesService? _instance;
  static AccessibilityPreferencesService get instance =>
      _instance ??= AccessibilityPreferencesService._();

  AccessibilityPreferencesService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  GA4AnalyticsService get _analytics => GA4AnalyticsService.instance;

  static const String _fontScaleKey = 'font_scale_factor';
  static const double _minScale = 0.8;
  static const double _maxScale = 1.2;
  static const double _defaultScale = 1.0;
  /// Web uses 12-18px in user_profiles.preferences.fontSize; map to scale (12→0.8, 15→1.0, 18→1.2)
  static const int _webMinFontSize = 12;
  static const int _webMaxFontSize = 18;

  double _currentFontScale = _defaultScale;
  final ValueNotifier<double> fontScaleNotifier = ValueNotifier<double>(_defaultScale);

  /// Initialize and load saved preferences (local + user_accessibility_preferences + user_profiles.preferences for Web sync)
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentFontScale = prefs.getDouble(_fontScaleKey) ?? _defaultScale;

      if (_auth.isAuthenticated) {
        await _syncWithSupabase();
        await _syncWithUserProfilesPreferences();
      }
      fontScaleNotifier.value = _currentFontScale;
    } catch (e) {
      debugPrint('Initialize accessibility preferences error: $e');
    }
  }

  /// Get current font scale factor
  double get fontScaleFactor => _currentFontScale;

  /// Update font scale factor
  Future<bool> updateFontScale(double scale) async {
    try {
      // Validate scale range
      if (scale < _minScale || scale > _maxScale) {
        debugPrint('Font scale out of range: $scale');
        return false;
      }

      _currentFontScale = scale;
      fontScaleNotifier.value = scale;

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontScaleKey, scale);

      if (_auth.isAuthenticated) {
        await _saveToSupabase(scale);
        await _saveFontSizeToUserProfiles(scale);
      }

      // Track with GA4 - NEW
      String sizeLabel;
      if (scale <= 0.8) {
        sizeLabel = 'small';
      } else if (scale <= 1.0) {
        sizeLabel = 'medium';
      } else if (scale <= 1.1) {
        sizeLabel = 'large';
      } else {
        sizeLabel = 'extra_large';
      }

      await _analytics.trackFontSizeAdjustment(
        size: sizeLabel,
        scaleFactor: scale,
      );

      return true;
    } catch (e) {
      debugPrint('Update font scale error: $e');
      return false;
    }
  }

  /// Reset to default font scale
  Future<bool> resetFontScale() async {
    return await updateFontScale(_defaultScale);
  }

  /// Get font scale range
  Map<String, double> get fontScaleRange => {
    'min': _minScale,
    'max': _maxScale,
    'default': _defaultScale,
  };

  /// Get preset font scales
  Map<String, double> get presetScales => {
    'Small': 0.8,
    'Default': 1.0,
    'Large': 1.2,
  };

  /// Track accessibility settings opened
  Future<void> trackAccessibilitySettingsOpened() async {
    try {
      await _analytics.trackScreenView(screenName: 'accessibility_settings');
    } catch (e) {
      debugPrint('Track accessibility settings opened error: $e');
    }
  }

  /// Track font preview viewed
  Future<void> trackFontPreviewViewed(double previewScale) async {
    try {
      await _analytics.trackScreenView(screenName: 'font_preview');
    } catch (e) {
      debugPrint('Track font preview viewed error: $e');
    }
  }

  /// Track theme preference change
  Future<void> trackThemePreferenceChanged(String theme) async {
    try {
      await _analytics.trackThemePreferenceChange(theme: theme);

      if (_auth.isAuthenticated) {
        await _client.from('user_accessibility_preferences').upsert({
          'user_id': _auth.currentUser!.id,
          'theme_preference': theme,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Track theme preference changed error: $e');
    }
  }

  /// Track accessibility feature usage
  Future<void> trackAccessibilityFeatureUsage(
    String featureName,
    bool enabled,
  ) async {
    try {
      await _analytics.trackAccessibilityFeatureUsage(
        featureName: featureName,
        enabled: enabled,
      );
    } catch (e) {
      debugPrint('Track accessibility feature usage error: $e');
    }
  }

  /// Get accessibility optimization reports
  Future<Map<String, dynamic>> getAccessibilityOptimizationReports() async {
    try {
      final response = await _client.rpc('get_accessibility_analytics');
      return response ?? _getDefaultOptimizationReport();
    } catch (e) {
      debugPrint('Get accessibility optimization reports error: $e');
      return _getDefaultOptimizationReport();
    }
  }

  /// Get accessibility adoption rates by user segment
  Future<Map<String, dynamic>> getAccessibilityAdoptionRates() async {
    try {
      final response = await _client.rpc('get_accessibility_adoption_rates');
      return response ?? _getDefaultAdoptionRates();
    } catch (e) {
      debugPrint('Get accessibility adoption rates error: $e');
      return _getDefaultAdoptionRates();
    }
  }

  Map<String, dynamic> _getDefaultOptimizationReport() {
    return {
      'high_usage_settings': [],
      'recommendations': [],
      'total_users_with_preferences': 0,
    };
  }

  Map<String, dynamic> _getDefaultAdoptionRates() {
    return {
      'font_scaling_adoption': 0.0,
      'theme_preference_adoption': 0.0,
      'total_accessibility_users': 0,
    };
  }

  // Private helper methods
  Future<void> _syncWithSupabase() async {
    try {
      final response = await _client
          .from('user_accessibility_preferences')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (response != null) {
        final serverScale = response['font_scale_factor'] as double?;
        if (serverScale != null && serverScale != _currentFontScale) {
          // Server has newer preference
          _currentFontScale = serverScale;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble(_fontScaleKey, serverScale);
        }
      }
    } catch (e) {
      debugPrint('Sync with Supabase error: $e');
    }
  }

  Future<void> _saveToSupabase(double scale) async {
    try {
      await _client.from('user_accessibility_preferences').upsert({
        'user_id': _auth.currentUser!.id,
        'font_scale_factor': scale,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Save to Supabase error: $e');
    }
  }

  /// Sync with Web: user_profiles.preferences.fontSize (12-18px). Scale 0.8→12, 1.0→15, 1.2→18.
  int _scaleToFontSize(double scale) {
    if (scale <= _minScale) return _webMinFontSize;
    if (scale >= _maxScale) return _webMaxFontSize;
    return (_webMinFontSize + (scale - _minScale) / (_maxScale - _minScale) * (_webMaxFontSize - _webMinFontSize)).round().clamp(_webMinFontSize, _webMaxFontSize);
  }

  double _fontSizeToScale(int? fontSize) {
    if (fontSize == null) return _defaultScale;
    final v = (fontSize - _webMinFontSize) / (_webMaxFontSize - _webMinFontSize) * (_maxScale - _minScale) + _minScale;
    return v.clamp(_minScale, _maxScale);
  }

  Future<void> _syncWithUserProfilesPreferences() async {
    try {
      final res = await _client.from('user_profiles').select('preferences').eq('id', _auth.currentUser!.id).maybeSingle();
      final prefs = res != null ? res['preferences'] as Map<String, dynamic>? : null;
      final fontSize = prefs?['fontSize'] is int ? prefs!['fontSize'] as int : null;
      if (fontSize != null) {
        final scale = _fontSizeToScale(fontSize);
        if ((scale - _currentFontScale).abs() > 0.01) {
          _currentFontScale = scale;
          fontScaleNotifier.value = scale;
          final sp = await SharedPreferences.getInstance();
          await sp.setDouble(_fontScaleKey, scale);
        }
      }
    } catch (e) {
      debugPrint('Sync user_profiles preferences error: $e');
    }
  }

  Future<void> _saveFontSizeToUserProfiles(double scale) async {
    try {
      final fontSize = _scaleToFontSize(scale);
      final res = await _client.from('user_profiles').select('preferences').eq('id', _auth.currentUser!.id).maybeSingle();
      final current = res != null ? res['preferences'] as Map<String, dynamic>? : null;
      final updated = Map<String, dynamic>.from(current ?? {});
      updated['fontSize'] = fontSize;
      await _client.from('user_profiles').update({'preferences': updated}).eq('id', _auth.currentUser!.id);
    } catch (e) {
      debugPrint('Save fontSize to user_profiles error: $e');
    }
  }
}
