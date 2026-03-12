import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './stripe_connect_service.dart';

/// Service for creator settlement and reconciliation
class SettlementService {
  static SettlementService? _instance;
  static SettlementService get instance => _instance ??= SettlementService._();

  SettlementService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  StripeConnectService get _stripe => StripeConnectService.instance;

  /// Get creator settlement summary
  Future<Map<String, dynamic>> getSettlementSummary() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultSummary();

      final userId = _auth.currentUser!.id;

      // Get pending balance
      final pendingBalance = await _calculatePendingBalance(userId);

      // Get next settlement date
      final schedule = await _client
          .from('settlement_schedule')
          .select()
          .eq('creator_user_id', userId)
          .maybeSingle();

      // Get recent settlements
      final recentSettlements = await _client
          .from('settlement_records')
          .select()
          .eq('creator_user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      return {
        'total_lifetime_earnings': await _calculateLifetimeEarnings(userId),
        'pending_settlement': pendingBalance,
        'available_for_withdrawal': pendingBalance,
        'next_payout_date': schedule?['next_settlement_date'],
        'settlement_frequency': schedule?['frequency'] ?? 'weekly',
        'minimum_threshold': schedule?['minimum_payout_threshold'] ?? 10.0,
        'recent_settlements': recentSettlements,
      };
    } catch (e) {
      debugPrint('Get settlement summary error: $e');
      return _getDefaultSummary();
    }
  }

  /// Get revenue breakdown by source
  Future<Map<String, dynamic>> getRevenueBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (!_auth.isAuthenticated) return {};

      final userId = _auth.currentUser!.id;
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      // Marketplace earnings
      final marketplaceResult = await _client
          .from('marketplace_orders')
          .select('total_amount, service_fee')
          .eq('seller_user_id', userId)
          .eq('order_status', 'completed')
          .gte('delivered_at', start.toIso8601String())
          .lte('delivered_at', end.toIso8601String());

      final marketplaceEarnings = marketplaceResult.fold<double>(
        0,
        (sum, order) =>
            sum +
            (order['total_amount'] as double) -
            (order['service_fee'] as double),
      );

      return {
        'marketplace': marketplaceEarnings,
        'elections': 0.0, // Placeholder
        'ads': 0.0, // Placeholder
        'referrals': 0.0, // Placeholder
        'total': marketplaceEarnings,
      };
    } catch (e) {
      debugPrint('Get revenue breakdown error: $e');
      return {};
    }
  }

  /// Process settlement
  Future<String?> processSettlement({
    required DateTime periodStart,
    required DateTime periodEnd,
    String? currency,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final userId = _auth.currentUser!.id;

      // Calculate settlement amounts
      final calculation = await _client.rpc(
        'calculate_settlement_amount',
        params: {
          'p_creator_id': userId,
          'p_start_date': periodStart.toIso8601String().split('T')[0],
          'p_end_date': periodEnd.toIso8601String().split('T')[0],
        },
      );

      final marketplaceEarnings = calculation['marketplace_earnings'] ?? 0.0;
      final electionEarnings = calculation['election_earnings'] ?? 0.0;
      final adEarnings = calculation['ad_earnings'] ?? 0.0;
      final totalEarnings = calculation['total_earnings'] ?? 0.0;
      final platformFees = calculation['platform_fees'] ?? 0.0;
      final netAmount = calculation['net_amount'] ?? 0.0;

      // Get exchange rate if needed
      double? exchangeRate;
      if (currency != null && currency != 'USD') {
        exchangeRate = await _getExchangeRate('USD', currency);
      }

      // Create settlement record
      final response = await _client
          .from('settlement_records')
          .insert({
            'creator_user_id': userId,
            'settlement_period_start': periodStart.toIso8601String().split(
              'T',
            )[0],
            'settlement_period_end': periodEnd.toIso8601String().split('T')[0],
            'marketplace_earnings': marketplaceEarnings,
            'election_earnings': electionEarnings,
            'ad_earnings': adEarnings,
            'total_earnings': totalEarnings,
            'platform_fees': platformFees,
            'net_amount': netAmount,
            'currency': currency ?? 'USD',
            'exchange_rate': exchangeRate,
            'status': 'pending',
          })
          .select('settlement_id')
          .single();

      // Process Stripe transfer
      final stripeTransferId = await _processStripeTransfer(
        userId: userId,
        amount: netAmount,
        currency: currency ?? 'USD',
      );

      if (stripeTransferId != null) {
        await _client
            .from('settlement_records')
            .update({
              'stripe_transfer_id': stripeTransferId,
              'status': 'processing',
              'settled_at': DateTime.now().toIso8601String(),
            })
            .eq('settlement_id', response['settlement_id']);
      }

      return response['settlement_id'] as String?;
    } catch (e) {
      debugPrint('Process settlement error: $e');
      return null;
    }
  }

  /// Get settlement history
  Future<List<Map<String, dynamic>>> getSettlementHistory({
    int? limit,
    String? status,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      PostgrestFilterBuilder query = _client
          .from('settlement_records')
          .select()
          .eq('creator_user_id', _auth.currentUser!.id);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit ?? 100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get settlement history error: $e');
      return [];
    }
  }

  /// Get reconciliation discrepancies
  Future<List<Map<String, dynamic>>> getReconciliationDiscrepancies() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('reconciliation_discrepancies')
          .select('*, settlement_records(creator_user_id)')
          .eq('settlement_records.creator_user_id', _auth.currentUser!.id)
          .eq('status', 'investigating')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get reconciliation discrepancies error: $e');
      return [];
    }
  }

  /// Generate tax document
  Future<String?> generateTaxDocument({
    required int taxYear,
    required String documentType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final userId = _auth.currentUser!.id;

      // Get earnings for tax year
      final startDate = DateTime(taxYear, 1, 1);
      final endDate = DateTime(taxYear, 12, 31);

      final settlements = await _client
          .from('settlement_records')
          .select()
          .eq('creator_user_id', userId)
          .gte(
            'settlement_period_start',
            startDate.toIso8601String().split('T')[0],
          )
          .lte(
            'settlement_period_end',
            endDate.toIso8601String().split('T')[0],
          );

      final totalEarnings = settlements.fold<double>(
        0,
        (sum, s) => sum + (s['total_earnings'] as double? ?? 0),
      );

      final breakdown = {
        'marketplace': settlements.fold<double>(
          0,
          (sum, s) => sum + (s['marketplace_earnings'] as double? ?? 0),
        ),
        'elections': settlements.fold<double>(
          0,
          (sum, s) => sum + (s['election_earnings'] as double? ?? 0),
        ),
        'ads': settlements.fold<double>(
          0,
          (sum, s) => sum + (s['ad_earnings'] as double? ?? 0),
        ),
      };

      // Generate document (placeholder - would use PDF generation)
      final documentUrl =
          'https://example.com/tax-docs/$userId-$taxYear-$documentType.pdf';

      final response = await _client
          .from('tax_documents')
          .insert({
            'creator_user_id': userId,
            'document_type': documentType,
            'tax_year': taxYear,
            'document_url': documentUrl,
            'total_earnings': totalEarnings,
            'breakdown': breakdown,
          })
          .select('document_id')
          .single();

      return response['document_id'] as String?;
    } catch (e) {
      debugPrint('Generate tax document error: $e');
      return null;
    }
  }

  /// Get tax documents
  Future<List<Map<String, dynamic>>> getTaxDocuments() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('tax_documents')
          .select()
          .eq('creator_user_id', _auth.currentUser!.id)
          .order('tax_year', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get tax documents error: $e');
      return [];
    }
  }

  /// Update settlement schedule
  Future<bool> updateSettlementSchedule({
    required String frequency,
    required double minimumThreshold,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      // Calculate next settlement date
      final nextDate = _calculateNextSettlementDate(frequency);

      await _client.from('settlement_schedule').upsert({
        'creator_user_id': userId,
        'frequency': frequency,
        'minimum_payout_threshold': minimumThreshold,
        'next_settlement_date': nextDate.toIso8601String().split('T')[0],
      });

      return true;
    } catch (e) {
      debugPrint('Update settlement schedule error: $e');
      return false;
    }
  }

  Future<double> _calculatePendingBalance(String userId) async {
    try {
      final result = await _client
          .from('marketplace_orders')
          .select('total_amount, service_fee')
          .eq('seller_user_id', userId)
          .eq('order_status', 'completed')
          .gte(
            'delivered_at',
            DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
          );

      return result.fold<double>(
        0,
        (sum, order) =>
            sum +
            (order['total_amount'] as double) -
            (order['service_fee'] as double),
      );
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _calculateLifetimeEarnings(String userId) async {
    try {
      final result = await _client
          .from('settlement_records')
          .select('net_amount')
          .eq('creator_user_id', userId)
          .eq('status', 'completed');

      return result.fold<double>(
        0,
        (sum, s) => sum + (s['net_amount'] as double? ?? 0),
      );
    } catch (e) {
      return 0.0;
    }
  }

  Future<double?> _getExchangeRate(String from, String to) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];

      final result = await _client
          .from('exchange_rates')
          .select('rate')
          .eq('from_currency', from)
          .eq('to_currency', to)
          .eq('effective_date', today)
          .maybeSingle();

      return result?['rate'] as double?;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _processStripeTransfer({
    required String userId,
    required double amount,
    required String currency,
  }) async {
    // Stripe transfer processing would go here
    debugPrint(
      'Processing Stripe transfer: \$$amount $currency to user $userId',
    );
    return 'tr_${DateTime.now().millisecondsSinceEpoch}';
  }

  DateTime _calculateNextSettlementDate(String frequency) {
    final now = DateTime.now();
    switch (frequency) {
      case 'daily':
        return now.add(const Duration(days: 1));
      case 'weekly':
        return now.add(const Duration(days: 7));
      case 'bi-weekly':
        return now.add(const Duration(days: 14));
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day);
      default:
        return now.add(const Duration(days: 7));
    }
  }

  Map<String, dynamic> _getDefaultSummary() {
    return {
      'total_lifetime_earnings': 0.0,
      'pending_settlement': 0.0,
      'available_for_withdrawal': 0.0,
      'next_payout_date': null,
      'settlement_frequency': 'weekly',
      'minimum_threshold': 10.0,
      'recent_settlements': [],
    };
  }
}
