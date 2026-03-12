import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Reads platform feature toggles from Supabase (admin On/Off panel).
/// Use for gating routes/screens: when a feature is disabled, hide or redirect.
/// Same table and keys as Web: platform_feature_toggles.
class PlatformFeatureToggleService {
  static PlatformFeatureToggleService? _instance;
  static PlatformFeatureToggleService get instance =>
      _instance ??= PlatformFeatureToggleService._();

  PlatformFeatureToggleService._();

  static const _cacheTtlMs = 5 * 60 * 1000; // 5 minutes

  Set<String>? _enabledKeys;
  int _cacheTimestamp = 0;

  dynamic get _client => SupabaseService.instance.client;

  bool get _isCacheValid =>
      _enabledKeys != null &&
      (DateTime.now().millisecondsSinceEpoch - _cacheTimestamp) < _cacheTtlMs;

  /// Fetch all toggles (feature_key, is_enabled). Public read allowed by RLS.
  Future<List<Map<String, dynamic>>> getPlatformFeatureToggles() async {
    try {
      final res = await _client
          .from('platform_feature_toggles')
          .select('feature_key, feature_name, is_enabled')
          .order('feature_name');

      final list = res as List<dynamic>? ?? [];
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('getPlatformFeatureToggles error: $e');
      return [];
    }
  }

  /// Get set of enabled feature keys (cached). Use for gating.
  Future<Set<String>> getEnabledFeatureKeys() async {
    if (_isCacheValid) return _enabledKeys!;

    final toggles = await getPlatformFeatureToggles();
    final enabled = <String>{};
    for (final t in toggles) {
      final key = t['feature_key'] ?? t['feature_name']?.toString().toLowerCase().replaceAll(' ', '_');
      if (key != null && key.isNotEmpty && (t['is_enabled'] == true)) {
        enabled.add(key.toString());
      }
    }
    _enabledKeys = enabled;
    _cacheTimestamp = DateTime.now().millisecondsSinceEpoch;
    return enabled;
  }

  /// Check if a feature is enabled by feature_key.
  Future<bool> isFeatureEnabled(String featureKey) async {
    if (featureKey.isEmpty) return false;
    final key = featureKey.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    final enabled = await getEnabledFeatureKeys();
    return enabled.contains(key);
  }

  /// Invalidate cache (e.g. after admin changes toggles).
  void invalidateCache() {
    _enabledKeys = null;
    _cacheTimestamp = 0;
  }
}
