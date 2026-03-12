import 'package:flutter/foundation.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Payout settings – same table and contract as Web (payout_settings).
/// Use for preferred method, threshold, bank details so Mobile matches Web.
class PayoutSettingsService {
  static PayoutSettingsService? _instance;
  static PayoutSettingsService get instance =>
      _instance ??= PayoutSettingsService._();

  PayoutSettingsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get payout settings for current user (payout_settings table).
  Future<Map<String, dynamic>?> getPayoutSettings() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('payout_settings')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get payout settings error: $e');
      return null;
    }
  }

  /// Update payout settings. Pass map with keys matching DB (snake_case or camelCase).
  Future<bool> updatePayoutSettings(Map<String, dynamic> settings) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final data = _toSnakeCase(settings);
      data['user_id'] = _auth.currentUser!.id;
      data['updated_at'] = DateTime.now().toIso8601String();

      await _client.from('payout_settings').upsert(
            data,
            onConflict: 'user_id',
          );

      return true;
    } catch (e) {
      debugPrint('Update payout settings error: $e');
      return false;
    }
  }

  static Map<String, dynamic> _toSnakeCase(Map<String, dynamic> obj) {
    final result = <String, dynamic>{};
    for (final entry in obj.entries) {
      final key = entry.key
          .replaceAllMapped(
              RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
          .replaceFirst('_', '');
      result[key] = entry.value;
    }
    return result;
  }
}
