import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class PayoutAutomationService {
  static PayoutAutomationService? _instance;
  static PayoutAutomationService get instance =>
      _instance ??= PayoutAutomationService._();

  PayoutAutomationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get payout schedule config for all tiers
  Future<List<Map<String, dynamic>>> getAllPayoutScheduleConfigs() async {
    try {
      final response = await _client
          .from('payout_schedule_config')
          .select()
          .order('tier_level', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all payout schedule configs error: $e');
      return [];
    }
  }

  /// Get payout schedule config for specific tier
  Future<Map<String, dynamic>?> getPayoutScheduleConfigForTier(
    String tierLevel,
  ) async {
    try {
      final response = await _client
          .from('payout_schedule_config')
          .select()
          .eq('tier_level', tierLevel)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get payout schedule config for tier error: $e');
      return null;
    }
  }

  /// Update payout schedule config for specific tier
  Future<bool> updatePayoutScheduleConfig({
    required String tierLevel,
    required String scheduleFrequency,
    required double minimumThreshold,
    required bool autoEnabled,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('payout_schedule_config')
          .update({
            'schedule_frequency': scheduleFrequency,
            'minimum_threshold': minimumThreshold,
            'auto_enabled': autoEnabled,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('tier_level', tierLevel);

      return true;
    } catch (e) {
      debugPrint('Update payout schedule config error: $e');
      return false;
    }
  }

  /// Get tax treaty rates
  Future<List<Map<String, dynamic>>> getTaxTreatyRates() async {
    try {
      final response = await _client
          .from('tax_treaty_rates')
          .select()
          .order('country_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get tax treaty rates error: $e');
      return [];
    }
  }

  /// Get tax withholding records for creator
  Future<List<Map<String, dynamic>>> getTaxWithholdingRecords() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('tax_withholding_records')
          .select('*, settlement_records(*)')
          .eq('creator_user_id', _auth.currentUser!.id)
          .order('withheld_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get tax withholding records error: $e');
      return [];
    }
  }

  /// Trigger manual payout processing (admin only)
  Future<Map<String, dynamic>> triggerManualPayoutProcessing() async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await _client.functions.invoke(
        'process-automated-payouts',
        body: {'manual_trigger': true},
      );

      if (response.data != null) {
        return {
          'success': true,
          'processed': response.data['processed'] ?? 0,
          'failed': response.data['failed'] ?? 0,
        };
      }

      return {'success': false, 'message': 'No response from function'};
    } catch (e) {
      debugPrint('Trigger manual payout processing error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Get payout statistics
  Future<Map<String, dynamic>> getPayoutStatistics() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultStatistics();

      final response = await _client
          .from('settlement_records')
          .select()
          .eq('creator_user_id', _auth.currentUser!.id);

      final settlements = List<Map<String, dynamic>>.from(response);

      final totalSettlements = settlements.length;
      final totalPaid = settlements.fold<double>(
        0.0,
        (sum, s) => sum + ((s['net_amount'] ?? 0.0) as num).toDouble(),
      );
      final totalWithheld = settlements.fold<double>(
        0.0,
        (sum, s) => sum + ((s['tax_withheld'] ?? 0.0) as num).toDouble(),
      );

      final pending = settlements.where((s) => s['status'] == 'pending').length;
      final completed = settlements
          .where((s) => s['status'] == 'completed')
          .length;
      final failed = settlements.where((s) => s['status'] == 'failed').length;

      return {
        'total_settlements': totalSettlements,
        'total_paid': totalPaid,
        'total_tax_withheld': totalWithheld,
        'pending_count': pending,
        'completed_count': completed,
        'failed_count': failed,
        'success_rate': totalSettlements > 0
            ? (completed / totalSettlements * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      debugPrint('Get payout statistics error: $e');
      return _getDefaultStatistics();
    }
  }

  Map<String, dynamic> _getDefaultStatistics() {
    return {
      'total_settlements': 0,
      'total_paid': 0.0,
      'total_tax_withheld': 0.0,
      'pending_count': 0,
      'completed_count': 0,
      'failed_count': 0,
      'success_rate': '0.0',
    };
  }
}
