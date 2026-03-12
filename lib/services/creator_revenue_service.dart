import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Service for country-based revenue sharing operations
class CreatorRevenueService {
  static CreatorRevenueService? _instance;
  static CreatorRevenueService get instance =>
      _instance ??= CreatorRevenueService._();

  CreatorRevenueService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get creator's applicable revenue split (with grandfathering)
  Future<Map<String, dynamic>> getCreatorRevenueSplit() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultSplit();

      final response = await _client.rpc(
        'get_creator_revenue_split',
        params: {'p_creator_id': _auth.currentUser!.id},
      );

      if (response == null || (response as List).isEmpty) {
        return _getDefaultSplit();
      }

      final split = (response).first;
      return {
        'platform_percentage': split['platform_percentage'] ?? 30.0,
        'creator_percentage': split['creator_percentage'] ?? 70.0,
        'is_grandfathered': split['is_grandfathered'] ?? false,
        'grandfathered_until': split['grandfathered_until'],
      };
    } catch (e) {
      debugPrint('Get creator revenue split error: $e');
      return _getDefaultSplit();
    }
  }

  /// Calculate creator payout with country split
  Future<Map<String, dynamic>> calculateCreatorPayout({
    required double grossRevenueUsd,
  }) async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultPayout();

      final response = await _client.rpc(
        'calculate_creator_payout',
        params: {
          'p_creator_id': _auth.currentUser!.id,
          'p_gross_revenue_usd': grossRevenueUsd,
        },
      );

      if (response == null || (response as List).isEmpty) {
        return _getDefaultPayout();
      }

      final payout = (response).first;
      return {
        'creator_payout_usd': payout['creator_payout_usd'] ?? 0.0,
        'platform_share_usd': payout['platform_share_usd'] ?? 0.0,
        'split_percentage': payout['split_percentage'] ?? 70.0,
        'is_grandfathered': payout['is_grandfathered'] ?? false,
      };
    } catch (e) {
      debugPrint('Calculate creator payout error: $e');
      return _getDefaultPayout();
    }
  }

  /// Get revenue split history for creator's country
  Future<List<Map<String, dynamic>>> getRevenueSplitHistory() async {
    try {
      if (!_auth.isAuthenticated) return [];

      // Get creator's country
      final verification = await _client
          .from('creator_verification')
          .select('country')
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      if (verification == null) return [];

      final countryCode = verification['country'] ?? 'US';

      final response = await _client
          .from('revenue_split_history')
          .select()
          .eq('country_code', countryCode)
          .order('changed_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get revenue split history error: $e');
      return [];
    }
  }

  /// Get upcoming split changes (30-day notice period)
  Future<List<Map<String, dynamic>>> getUpcomingSplitChanges() async {
    try {
      if (!_auth.isAuthenticated) return [];

      // Get creator's country
      final verification = await _client
          .from('creator_verification')
          .select('country')
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      if (verification == null) return [];

      final countryCode = verification['country'] ?? 'US';

      final response = await _client
          .from('revenue_split_history')
          .select()
          .eq('country_code', countryCode)
          .gt('effective_date', DateTime.now().toIso8601String())
          .order('effective_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get upcoming split changes error: $e');
      return [];
    }
  }

  /// Submit custom split negotiation (for high-performing creators)
  Future<bool> submitSplitNegotiation({
    required double requestedCreatorPercentage,
    required String justification,
    required double monthlyRevenueUsd,
    Map<String, dynamic>? performanceMetrics,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Check if creator qualifies (>$10k monthly revenue)
      if (monthlyRevenueUsd < 10000) {
        debugPrint('Creator does not meet minimum revenue threshold (\$10k)');
        return false;
      }

      await _client.from('creator_split_negotiations').insert({
        'creator_id': _auth.currentUser!.id,
        'requested_creator_percentage': requestedCreatorPercentage,
        'justification': justification,
        'monthly_revenue_usd': monthlyRevenueUsd,
        'performance_metrics': performanceMetrics ?? {},
        'status': 'pending',
      });

      return true;
    } catch (e) {
      debugPrint('Submit split negotiation error: $e');
      return false;
    }
  }

  /// Get creator's split negotiations
  Future<List<Map<String, dynamic>>> getSplitNegotiations() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('creator_split_negotiations')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get split negotiations error: $e');
      return [];
    }
  }

  /// Opt into grandfathering (90-day protection for old split rates)
  Future<bool> optIntoGrandfathering({
    required double grandfatheredSplitPercentage,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final grandfatheredUntil = DateTime.now().add(const Duration(days: 90));

      await _client.from('creator_split_preferences').upsert({
        'creator_id': _auth.currentUser!.id,
        'grandfathered_split_percentage': grandfatheredSplitPercentage,
        'grandfathered_until': grandfatheredUntil.toIso8601String(),
        'opted_into_grandfathering': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Opt into grandfathering error: $e');
      return false;
    }
  }

  /// Get creator's split preferences
  Future<Map<String, dynamic>?> getSplitPreferences() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('creator_split_preferences')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get split preferences error: $e');
      return null;
    }
  }

  /// Update notification preferences for split changes
  Future<bool> updateNotificationPreferences({
    required bool notifyOnSplitChanges,
    String? notificationEmail,
    String? notificationSms,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('creator_split_preferences').upsert({
        'creator_id': _auth.currentUser!.id,
        'notify_on_split_changes': notifyOnSplitChanges,
        'notification_email': notificationEmail,
        'notification_sms': notificationSms,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update notification preferences error: $e');
      return false;
    }
  }

  /// Stream real-time split changes
  Stream<Map<String, dynamic>> streamRevenueSplit() {
    if (!_auth.isAuthenticated) {
      return Stream.value(_getDefaultSplit());
    }

    return _client
        .from('creator_revenue_splits')
        .stream(primaryKey: ['id'])
        .map((data) {
          if (data.isEmpty) return _getDefaultSplit();
          final split = data.first;
          return {
            'platform_percentage': split['platform_percentage'] ?? 30.0,
            'creator_percentage': split['creator_percentage'] ?? 70.0,
            'updated_at': split['updated_at'],
          };
        });
  }

  Map<String, dynamic> _getDefaultSplit() {
    return {
      'platform_percentage': 30.0,
      'creator_percentage': 70.0,
      'is_grandfathered': false,
      'grandfathered_until': null,
    };
  }

  Map<String, dynamic> _getDefaultPayout() {
    return {
      'creator_payout_usd': 0.0,
      'platform_share_usd': 0.0,
      'split_percentage': 70.0,
      'is_grandfathered': false,
    };
  }
}
