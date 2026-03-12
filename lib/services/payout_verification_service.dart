import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class PayoutVerificationService {
  static PayoutVerificationService? _instance;
  static PayoutVerificationService get instance =>
      _instance ??= PayoutVerificationService._();

  PayoutVerificationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get pending verifications for admin
  Future<List<Map<String, dynamic>>> getPendingVerifications() async {
    try {
      final response = await _client
          .from('settlement_records')
          .select('*, user_profiles!creator_user_id(full_name, email)')
          .eq('verification_status', 'pending_verification')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get pending verifications error: $e');
      return [];
    }
  }

  /// Get verification metrics
  Future<Map<String, dynamic>> getVerificationMetrics() async {
    try {
      final totalSettlements = await _client
          .from('settlement_records')
          .select('settlement_id')
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final verifiedSettlements = await _client
          .from('settlement_records')
          .select('settlement_id')
          .eq('verification_status', 'verified')
          .gte(
            'created_at',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final pendingVerifications = await _client
          .from('settlement_records')
          .select('settlement_id')
          .eq('verification_status', 'pending_verification');

      final discrepancies = await _client
          .from('verification_discrepancies')
          .select('discrepancy_id')
          .inFilter('status', ['open', 'investigating']);

      final total = (totalSettlements as List).length;
      final verified = (verifiedSettlements as List).length;

      return {
        'total_settlements_this_month': total,
        'verified_percentage': total > 0
            ? (verified / total * 100).toStringAsFixed(1)
            : '0',
        'pending_verification_count': (pendingVerifications as List).length,
        'discrepancies_found': (discrepancies as List).length,
        'average_verification_time_hours': 24.0, // Placeholder
      };
    } catch (e) {
      debugPrint('Get verification metrics error: $e');
      return {
        'total_settlements_this_month': 0,
        'verified_percentage': '0',
        'pending_verification_count': 0,
        'discrepancies_found': 0,
        'average_verification_time_hours': 0.0,
      };
    }
  }

  /// Get settlement detail for verification
  Future<Map<String, dynamic>?> getSettlementDetail(String settlementId) async {
    try {
      final settlement = await _client
          .from('settlement_records')
          .select('*, user_profiles!creator_user_id(full_name, email)')
          .eq('settlement_id', settlementId)
          .single();

      // Get transaction itemization (mock for now)
      final transactions = [
        {
          'date': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'source': 'election',
          'gross_amount': 150.0,
          'platform_fee': 45.0,
          'net_amount': 105.0,
        },
        {
          'date': DateTime.now()
              .subtract(const Duration(days: 3))
              .toIso8601String(),
          'source': 'marketplace',
          'gross_amount': 200.0,
          'platform_fee': 20.0,
          'net_amount': 180.0,
        },
      ];

      return {
        ...settlement,
        'transactions': transactions,
        'calculated_total': 350.0,
        'expected_payout': 285.0,
        'actual_stripe_transfer': settlement['net_amount'],
        'difference': (settlement['net_amount'] as double) - 285.0,
      };
    } catch (e) {
      debugPrint('Get settlement detail error: $e');
      return null;
    }
  }

  /// Verify settlement
  Future<bool> verifySettlement(String settlementId) async {
    try {
      await _client
          .from('settlement_records')
          .update({
            'verification_status': 'verified',
            'verified_at': DateTime.now().toIso8601String(),
          })
          .eq('settlement_id', settlementId);

      return true;
    } catch (e) {
      debugPrint('Verify settlement error: $e');
      return false;
    }
  }

  /// Flag discrepancy
  Future<String?> flagDiscrepancy({
    required String settlementId,
    required String discrepancyType,
    required double amount,
    required String description,
    List<String>? evidenceUrls,
  }) async {
    try {
      final response = await _client
          .from('verification_discrepancies')
          .insert({
            'settlement_id': settlementId,
            'discrepancy_type': discrepancyType,
            'discrepancy_amount': amount,
            'description': description,
            'evidence_urls': evidenceUrls ?? [],
            'status': 'open',
          })
          .select('discrepancy_id')
          .single();

      // Update settlement status
      await _client
          .from('settlement_records')
          .update({'verification_status': 'discrepancy'})
          .eq('settlement_id', settlementId);

      return response['discrepancy_id'] as String?;
    } catch (e) {
      debugPrint('Flag discrepancy error: $e');
      return null;
    }
  }

  /// Get discrepancy queue
  Future<List<Map<String, dynamic>>> getDiscrepancyQueue() async {
    try {
      final response = await _client
          .from('verification_discrepancies')
          .select(
            '*, settlement_records(creator_user_id, settlement_period_start, settlement_period_end, net_amount, user_profiles!creator_user_id(full_name, email))',
          )
          .inFilter('status', ['open', 'investigating'])
          .order('reported_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get discrepancy queue error: $e');
      return [];
    }
  }

  /// Process manual adjustment
  Future<bool> processManualAdjustment({
    required String creatorUserId,
    required String adjustmentType,
    required double adjustmentAmount,
    required String reason,
    List<String>? evidenceUrls,
  }) async {
    try {
      // Get current balance
      final account = await _client
          .from('creator_accounts')
          .select('pending_balance')
          .eq('user_id', creatorUserId)
          .single();

      final previousBalance = account['pending_balance'] as double;
      double newBalance = previousBalance;

      if (adjustmentType == 'increase_balance') {
        newBalance = previousBalance + adjustmentAmount;
      } else if (adjustmentType == 'decrease_balance') {
        newBalance = previousBalance - adjustmentAmount;
      }

      // Create adjustment record
      await _client.from('balance_adjustments').insert({
        'creator_user_id': creatorUserId,
        'adjustment_type': adjustmentType,
        'adjustment_amount': adjustmentAmount,
        'previous_balance': previousBalance,
        'new_balance': newBalance,
        'reason': reason,
        'evidence_urls': evidenceUrls ?? [],
        'approved_by': _auth.currentUser?.id,
      });

      // Update creator balance
      await _client
          .from('creator_accounts')
          .update({'pending_balance': newBalance})
          .eq('user_id', creatorUserId);

      return true;
    } catch (e) {
      debugPrint('Process manual adjustment error: $e');
      return false;
    }
  }

  /// Get reconciliation timeline data
  Future<List<Map<String, dynamic>>> getReconciliationTimeline() async {
    try {
      final last30Days = DateTime.now().subtract(const Duration(days: 30));

      final settlements = await _client
          .from('settlement_records')
          .select('created_at, verification_status')
          .gte('created_at', last30Days.toIso8601String())
          .order('created_at', ascending: true);

      final discrepancies = await _client
          .from('verification_discrepancies')
          .select('reported_at')
          .gte('reported_at', last30Days.toIso8601String())
          .order('reported_at', ascending: true);

      // Group by day
      final Map<String, Map<String, int>> dailyData = {};

      for (final settlement in settlements as List) {
        final date = DateTime.parse(
          settlement['created_at'] as String,
        ).toIso8601String().split('T')[0];
        dailyData[date] ??= {
          'settlements': 0,
          'verifications': 0,
          'discrepancies': 0,
        };
        dailyData[date]!['settlements'] =
            (dailyData[date]!['settlements'] ?? 0) + 1;
        if (settlement['verification_status'] == 'verified') {
          dailyData[date]!['verifications'] =
              (dailyData[date]!['verifications'] ?? 0) + 1;
        }
      }

      for (final discrepancy in discrepancies as List) {
        final date = DateTime.parse(
          discrepancy['reported_at'] as String,
        ).toIso8601String().split('T')[0];
        dailyData[date] ??= {
          'settlements': 0,
          'verifications': 0,
          'discrepancies': 0,
        };
        dailyData[date]!['discrepancies'] =
            (dailyData[date]!['discrepancies'] ?? 0) + 1;
      }

      return dailyData.entries.map((e) => {'date': e.key, ...e.value}).toList();
    } catch (e) {
      debugPrint('Get reconciliation timeline error: $e');
      return [];
    }
  }

  /// Export reconciliation report
  Future<String> exportReconciliationReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final settlements = await _client
          .from('settlement_records')
          .select('*, user_profiles!creator_user_id(full_name, email)')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .order('created_at', ascending: false);

      // Generate CSV content
      final csvLines = <String>[
        'Settlement ID,Creator Email,Period Start,Period End,Total Earnings,Platform Fees,Net Amount,Verification Status,Verified At',
      ];

      for (final settlement in settlements as List) {
        final creator = settlement['user_profiles'];
        csvLines.add(
          '${settlement['settlement_id']},'
          '${creator['email']},'
          '${settlement['settlement_period_start']},'
          '${settlement['settlement_period_end']},'
          '${settlement['total_earnings']},'
          '${settlement['platform_fees']},'
          '${settlement['net_amount']},'
          '${settlement['verification_status']},'
          '${settlement['verified_at'] ?? 'N/A'}',
        );
      }

      return csvLines.join('\n');
    } catch (e) {
      debugPrint('Export reconciliation report error: $e');
      return '';
    }
  }
}
