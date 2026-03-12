import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Service for settlement reconciliation operations
class ReconciliationService {
  static ReconciliationService? _instance;
  static ReconciliationService get instance =>
      _instance ??= ReconciliationService._();

  ReconciliationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get reconciliation summary
  Future<Map<String, dynamic>> getReconciliationSummary() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultSummary();

      final transactions = await getPayoutTransactions();

      int matched = 0;
      int pending = 0;
      int discrepancies = 0;

      for (var transaction in transactions) {
        final status = transaction['status'] ?? 'pending';
        switch (status) {
          case 'matched':
            matched++;
            break;
          case 'discrepancy':
            discrepancies++;
            break;
          default:
            pending++;
        }
      }

      return {
        'matched_transactions': matched,
        'pending_transactions': pending,
        'discrepancy_count': discrepancies,
        'total_transactions': transactions.length,
      };
    } catch (e) {
      debugPrint('Get reconciliation summary error: $e');
      return _getDefaultSummary();
    }
  }

  /// Get payout transactions with optional filters
  Future<List<Map<String, dynamic>>> getPayoutTransactions({
    String? status,
    String? paymentMethod,
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client
          .from('payout_transactions')
          .select()
          .eq('creator_id', _auth.currentUser!.id);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (paymentMethod != null) {
        query = query.eq('payment_method', paymentMethod);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get payout transactions error: $e');
      return [];
    }
  }

  /// Export transactions to CSV
  Future<bool> exportTransactionsToCSV({
    required List<Map<String, dynamic>> transactions,
  }) async {
    try {
      // In a real implementation, this would generate and download a CSV file
      // For now, we'll just return success
      debugPrint('Exporting ${transactions.length} transactions to CSV');
      return true;
    } catch (e) {
      debugPrint('Export transactions to CSV error: $e');
      return false;
    }
  }

  /// Match transaction with payment provider
  Future<bool> matchTransaction({
    required String transactionId,
    required String providerTransactionId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('payout_transactions')
          .update({
            'status': 'matched',
            'provider_transaction_id': providerTransactionId,
            'matched_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      return true;
    } catch (e) {
      debugPrint('Match transaction error: $e');
      return false;
    }
  }

  /// Report discrepancy
  Future<bool> reportDiscrepancy({
    required String transactionId,
    required String discrepancyReason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('payout_transactions')
          .update({
            'status': 'discrepancy',
            'discrepancy_reason': discrepancyReason,
            'discrepancy_reported_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      return true;
    } catch (e) {
      debugPrint('Report discrepancy error: $e');
      return false;
    }
  }

  Map<String, dynamic> _getDefaultSummary() {
    return {
      'matched_transactions': 0,
      'pending_transactions': 0,
      'discrepancy_count': 0,
      'total_transactions': 0,
    };
  }
}
