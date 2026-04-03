import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/supabase_service.dart';
import '../../../../services/auth_service.dart';
import '../constants/payout_constants.dart';

/// Payout API – same contract as Web: user_wallets + prize_redemptions.
/// All errors return user-facing messages from PayoutErrors.
class PayoutApi {
  static final PayoutApi _instance = PayoutApi._();
  static PayoutApi get instance => _instance;

  PayoutApi._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get wallet from user_wallets (not wallets).
  Future<Map<String, dynamic>?> getWallet() async {
    try {
      if (!_auth.isAuthenticated) return null;
      final res = await _client
          .from('user_wallets')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();
      return res as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('PayoutApi getWallet: $e');
      return null;
    }
  }

  /// Get payout_settings.
  Future<Map<String, dynamic>?> getPayoutSettings() async {
    try {
      if (!_auth.isAuthenticated) return null;
      final res = await _client
          .from('payout_settings')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();
      return res as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('PayoutApi getPayoutSettings: $e');
      return null;
    }
  }

  /// Get payout history from prize_redemptions.
  Future<List<Map<String, dynamic>>> getPayoutHistory({int limit = 50}) async {
    try {
      if (!_auth.isAuthenticated) return [];
      final res = await _client
          .from('prize_redemptions')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint('PayoutApi getPayoutHistory: $e');
      return [];
    }
  }

  /// Request payout. Validates threshold and balance; inserts into prize_redemptions.
  /// Returns (success, userFacingErrorMessage).
  Future<({bool success, String? error})> requestPayout({
    required double amount,
    double processingFee = 0,
    Map<String, dynamic>? paymentDetails,
    String method = 'bank_transfer',
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return (success: false, error: PayoutErrors.notAuthenticated);
      }
      if (amount <= 0 || !amount.isFinite) {
        return (success: false, error: PayoutErrors.invalidAmount);
      }
      if (amount < PayoutConstants.payoutThreshold) {
        return (success: false, error: PayoutErrors.belowThreshold);
      }

      final wallet = await getWallet();
      if (wallet == null) {
        return (success: false, error: PayoutErrors.requestFailed);
      }
      final available = (wallet['available_balance'] as num?)?.toDouble() ?? 0.0;
      if (amount > available) {
        return (success: false, error: PayoutErrors.insufficientBalance);
      }

      final walletId = wallet['id'] as String?;
      if (walletId == null) {
        return (success: false, error: PayoutErrors.requestFailed);
      }
      // Map UI methods to database redemption_type enum values
      String dbRedemptionType = 'cash';
      if (method == 'bank_transfer' || method == 'stripe') {
        dbRedemptionType = 'bank_transfer';
      } else if (method == 'gift_card') {
        dbRedemptionType = 'gift_card';
      } else if (method == 'crypto') {
        dbRedemptionType = 'crypto';
      }

      await _client.from('prize_redemptions').insert({
        'user_id': _auth.currentUser!.id,
        'wallet_id': walletId,
        'redemption_type': dbRedemptionType,
        'amount': amount,
        'conversion_rate': 1.0,
        'final_amount': amount - processingFee,
        'processing_fee': processingFee,
        'status': 'pending',
        'payment_details': paymentDetails ?? {'method': method},
        'notes': '',
      });

      return (success: true, error: null);
    } catch (e) {
      debugPrint('PayoutApi requestPayout: $e');
      return (success: false, error: PayoutErrors.requestFailed);
    }
  }

  String formatCurrency(double amount, [String currency = 'USD']) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Next payment date (YouTube-style: 21st–26th).
  String getNextPaymentDate() {
    final d = DateTime.now();
    int month = d.month;
    if (d.day > 26) {
      month += 1;
      if (month > 12) {
        month = 1;
      }
    }
    final next = DateTime(d.year, month > 12 ? 1 : month, 21);
    return '${_month(next.month)} ${next.day}, ${next.year}';
  }

  static String _month(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m - 1];
  }
}
