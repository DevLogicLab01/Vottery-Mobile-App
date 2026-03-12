import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

/// Service for multi-currency settlement operations across 8 purchasing power zones
class MultiCurrencySettlementService {
  static MultiCurrencySettlementService? _instance;
  static MultiCurrencySettlementService get instance =>
      _instance ??= MultiCurrencySettlementService._();

  MultiCurrencySettlementService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // 8 Purchasing Power Zones
  static const List<String> zones = [
    'US_Canada',
    'Western_Europe',
    'Eastern_Europe',
    'Africa',
    'Latin_America',
    'Middle_East_Asia',
    'Australasia',
    'China_Hong_Kong',
  ];

  // Payment method timelines (in days)
  static const Map<String, String> settlementTimelines = {
    'bank_transfer': '3-5 days',
    'PayPal': 'instant',
    'Stripe': '2-7 days',
    'crypto': '1-24 hours',
  };

  /// Get pending payouts summary
  Future<Map<String, dynamic>> getPendingPayoutsSummary() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultSummary();

      final response = await _client
          .from('payout_requests')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .eq('status', 'pending');

      final payouts = List<Map<String, dynamic>>.from(response);

      double totalPending = 0.0;
      Set<String> activeZones = {};

      for (var payout in payouts) {
        totalPending += ((payout['amount'] ?? 0.0) as num).toDouble();
        if (payout['zone'] != null) {
          activeZones.add(payout['zone'] as String);
        }
      }

      return {
        'total_pending': totalPending,
        'active_zones': activeZones.length,
        'next_settlement_date': _calculateNextSettlementDate(),
        'pending_count': payouts.length,
      };
    } catch (e) {
      debugPrint('Get pending payouts summary error: $e');
      return _getDefaultSummary();
    }
  }

  /// Get zone-specific payout status
  Future<Map<String, Map<String, dynamic>>> getZonePayoutStatus() async {
    try {
      if (!_auth.isAuthenticated) return {};

      Map<String, Map<String, dynamic>> zoneStatus = {};

      for (var zone in zones) {
        final response = await _client
            .from('payout_requests')
            .select()
            .eq('creator_id', _auth.currentUser!.id)
            .eq('zone', zone)
            .order('created_at', ascending: false)
            .limit(1);

        if (response.isNotEmpty) {
          final latest = response.first;
          zoneStatus[zone] = {
            'status': latest['status'] ?? 'none',
            'amount': latest['amount'] ?? 0.0,
            'last_payout': latest['created_at'],
          };
        } else {
          zoneStatus[zone] = {
            'status': 'none',
            'amount': 0.0,
            'last_payout': null,
          };
        }
      }

      return zoneStatus;
    } catch (e) {
      debugPrint('Get zone payout status error: $e');
      return {};
    }
  }

  /// Submit withdrawal request
  Future<bool> submitWithdrawalRequest({
    required double amount,
    required String zone,
    required String paymentMethod,
    required Map<String, dynamic> beneficiaryDetails,
    String? taxDocumentUrl,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('payout_requests').insert({
        'creator_id': _auth.currentUser!.id,
        'amount': amount,
        'zone': zone,
        'payout_method': paymentMethod,
        'payout_details': beneficiaryDetails,
        'tax_document_url': taxDocumentUrl,
        'status': 'pending',
        'estimated_completion': _calculateEstimatedCompletion(paymentMethod),
      });

      return true;
    } catch (e) {
      debugPrint('Submit withdrawal request error: $e');
      return false;
    }
  }

  /// Get payout history with filters
  Future<List<Map<String, dynamic>>> getPayoutHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? zone,
    double? minAmount,
    double? maxAmount,
    String? status,
    String? paymentMethod,
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client
          .from('payout_requests')
          .select()
          .eq('creator_id', _auth.currentUser!.id);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }
      if (zone != null) {
        query = query.eq('zone', zone);
      }
      if (status != null) {
        query = query.eq('status', status);
      }
      if (paymentMethod != null) {
        query = query.eq('payout_method', paymentMethod);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      var results = List<Map<String, dynamic>>.from(response);

      // Apply amount filters in memory
      if (minAmount != null) {
        results = results
            .where((p) => ((p['amount'] ?? 0.0) as num).toDouble() >= minAmount)
            .toList();
      }
      if (maxAmount != null) {
        results = results
            .where((p) => ((p['amount'] ?? 0.0) as num).toDouble() <= maxAmount)
            .toList();
      }

      return results;
    } catch (e) {
      debugPrint('Get payout history error: $e');
      return [];
    }
  }

  /// Get compliance status for zones
  Future<Map<String, String>> getComplianceStatus() async {
    try {
      if (!_auth.isAuthenticated) return {};

      // Mock compliance status - in production, this would check regulatory approvals
      return {
        'US_Canada': 'approved',
        'Western_Europe': 'approved',
        'Eastern_Europe': 'approved',
        'Africa': 'pending',
        'Latin_America': 'approved',
        'Middle_East_Asia': 'approved',
        'Australasia': 'approved',
        'China_Hong_Kong': 'pending',
      };
    } catch (e) {
      debugPrint('Get compliance status error: $e');
      return {};
    }
  }

  /// Get multi-currency wallet balances
  Future<Map<String, double>> getMultiCurrencyBalances() async {
    try {
      if (!_auth.isAuthenticated) return {};

      // Mock balances - in production, fetch from wallet service
      return {
        'USD': 1250.50,
        'EUR': 980.30,
        'GBP': 750.00,
        'CNY': 5420.00,
        'JPY': 125000.00,
      };
    } catch (e) {
      debugPrint('Get multi-currency balances error: $e');
      return {};
    }
  }

  /// Calculate estimated completion date
  DateTime _calculateEstimatedCompletion(String paymentMethod) {
    final now = DateTime.now();
    switch (paymentMethod) {
      case 'PayPal':
        return now; // Instant
      case 'bank_transfer':
        return now.add(const Duration(days: 4)); // 3-5 days average
      case 'Stripe':
        return now.add(const Duration(days: 4)); // 2-7 days average
      case 'crypto':
        return now.add(const Duration(hours: 12)); // 1-24 hours average
      default:
        return now.add(const Duration(days: 3));
    }
  }

  /// Calculate next settlement date
  DateTime _calculateNextSettlementDate() {
    final now = DateTime.now();
    // Next Friday
    int daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
    if (daysUntilFriday == 0) daysUntilFriday = 7;
    return now.add(Duration(days: daysUntilFriday));
  }

  Map<String, dynamic> _getDefaultSummary() {
    return {
      'total_pending': 0.0,
      'active_zones': 0,
      'next_settlement_date': _calculateNextSettlementDate(),
      'pending_count': 0,
    };
  }
}
