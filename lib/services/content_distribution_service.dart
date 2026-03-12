import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'supabase_service.dart';

/// Content distribution settings (election vs social vs ad ratios). Aligns with Web contentDistributionService.
class ContentDistributionService {
  static ContentDistributionService? _instance;
  static ContentDistributionService get instance =>
      _instance ??= ContentDistributionService._();

  ContentDistributionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get current distribution settings (single row, latest)
  Future<Map<String, dynamic>?> getDistributionSettings() async {
    try {
      final res = await _client
          .from('content_distribution_settings')
          .select()
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return res != null ? Map<String, dynamic>.from(res) : null;
    } catch (e) {
      debugPrint('Content distribution getSettings error: $e');
      return null;
    }
  }

  /// Update election/social percentages (must sum to 100)
  Future<bool> updateDistributionPercentages({
    required double electionPercentage,
    required double socialMediaPercentage,
  }) async {
    try {
      if ((electionPercentage + socialMediaPercentage).round() != 100) {
        debugPrint('Percentages must sum to 100');
        return false;
      }
      final settings = await getDistributionSettings();
      if (settings == null || settings['id'] == null) return false;
      final userId = _auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('content_distribution_settings').update({
        'election_content_percentage': electionPercentage.round(),
        'social_media_percentage': socialMediaPercentage.round(),
        'updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', settings['id']);

      return true;
    } catch (e) {
      debugPrint('Content distribution update error: $e');
      return false;
    }
  }

  /// Toggle distribution system on/off
  Future<bool> toggleDistributionSystem(bool isEnabled) async {
    try {
      final settings = await getDistributionSettings();
      if (settings == null || settings['id'] == null) return false;
      final userId = _auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('content_distribution_settings').update({
        'is_enabled': isEnabled,
        'updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', settings['id']);

      return true;
    } catch (e) {
      debugPrint('Content distribution toggle error: $e');
      return false;
    }
  }

  /// Toggle emergency freeze
  Future<bool> toggleEmergencyFreeze(bool isActive) async {
    try {
      final settings = await getDistributionSettings();
      if (settings == null || settings['id'] == null) return false;
      final userId = _auth.currentUser?.id;
      if (userId == null) return false;

      await _client.from('content_distribution_settings').update({
        'emergency_freeze': isActive,
        'updated_by': userId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', settings['id']);

      return true;
    } catch (e) {
      debugPrint('Content distribution emergency freeze error: $e');
      return false;
    }
  }

  /// Get distribution metrics for time range
  Future<List<Map<String, dynamic>>> getDistributionMetrics({
    String timeRange = '24h',
  }) async {
    try {
      final now = DateTime.now();
      DateTime start;
      switch (timeRange) {
        case '1h':
          start = now.subtract(const Duration(hours: 1));
          break;
        case '7d':
          start = now.subtract(const Duration(days: 7));
          break;
        case '30d':
          start = now.subtract(const Duration(days: 30));
          break;
        default:
          start = now.subtract(const Duration(hours: 24));
      }
      final res = await _client
          .from('content_distribution_metrics')
          .select()
          .gte('timestamp', start.toIso8601String())
          .order('timestamp', ascending: false)
          .limit(100);
      return List<Map<String, dynamic>>.from(res.map((e) => Map<String, dynamic>.from(e)));
    } catch (e) {
      debugPrint('Content distribution metrics error: $e');
      return [];
    }
  }
}
