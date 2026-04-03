import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './logging/platform_logging_service.dart';
import '../features/payouts/api/payout_api.dart';

/// Service for wallet management, prize distribution, and lottery automation
class WalletService {
  static WalletService? _instance;
  static WalletService get instance => _instance ??= WalletService._();

  WalletService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get user's wallet (using user_wallets for Web/Mobile parity)
  Future<Map<String, dynamic>?> getWallet() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('user_wallets')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Get wallet error: $e');
      return null;
    }
  }

  /// Initialize wallet for new user
  Future<bool> initializeWallet(String zone) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('wallets').insert({
        'user_id': _auth.currentUser!.id,
        'balance_usd': 0.00,
        'purchasing_power_zone': zone,
      });

      return true;
    } catch (e) {
      debugPrint('Initialize wallet error: $e');
      return false;
    }
  }

  /// Get wallet transactions (aligned with prize_redemptions for payouts)
  Future<List<Map<String, dynamic>>> getTransactions({int limit = 50}) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('prize_redemptions')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Get transactions error: $e');
      return [];
    }
  }

  /// Get regional pricing for zone
  Future<List<Map<String, dynamic>>> getRegionalPricing(String zone) async {
    try {
      final response = await _client
          .from('regional_pricing')
          .select()
          .eq('zone', zone)
          .eq('is_active', true)
          .order('vp_amount', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get regional pricing error: $e');
      return [];
    }
  }

  /// Get prize for election
  Future<Map<String, dynamic>?> getPrizeForElection(String electionId) async {
    try {
      final response = await _client
          .from('prizes')
          .select()
          .eq('election_id', electionId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get prize error: $e');
      return null;
    }
  }

  /// Get user's prize distributions
  Future<List<Map<String, dynamic>>> getUserPrizes() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('prize_distributions')
          .select('*, prizes(*), elections(*)')
          .eq('winner_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user prizes error: $e');
      return [];
    }
  }

  /// Get lottery draw for election
  Future<Map<String, dynamic>?> getLotteryDraw(String electionId) async {
    try {
      final response = await _client
          .from('lottery_draws')
          .select()
          .eq('election_id', electionId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get lottery draw error: $e');
      return null;
    }
  }

  /// Check if user has lottery entry
  Future<bool> hasLotteryEntry(String lotteryDrawId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final response = await _client
          .from('lottery_entries')
          .select('id')
          .eq('lottery_draw_id', lotteryDrawId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check lottery entry error: $e');
      return false;
    }
  }

  /// Get lottery winners
  Future<List<Map<String, dynamic>>> getLotteryWinners(
    String lotteryDrawId,
  ) async {
    try {
      final response = await _client
          .from('lottery_entries')
          .select('*, user_profiles(*)')
          .eq('lottery_draw_id', lotteryDrawId)
          .eq('is_winner', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get lottery winners error: $e');
      return [];
    }
  }

  /// Get wallet balance summary for the current user
  Future<Map<String, dynamic>?> getWalletBalance() async {
    return getWallet();
  }

  /// Get pending/unclaimed winnings for the current user
  Future<List<Map<String, dynamic>>> getPendingWinnings() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('prize_distributions')
          .select('*, prizes(*), elections(*)')
          .eq('winner_id', _auth.currentUser!.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get pending winnings error: $e');
      return [];
    }
  }

  /// Get payout history for the current user (using prize_redemptions via PayoutApi)
  Future<List<Map<String, dynamic>>> getPayoutHistory() async {
    return PayoutApi.instance.getPayoutHistory();
  }

  /// Get all active lottery draws
  Future<List<Map<String, dynamic>>> getLotteryDraws() async {
    try {
      final response = await _client
          .from('lottery_draws')
          .select('*, elections(*)')
          .eq('status', 'active')
          .order('draw_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get lottery draws error: $e');
      return [];
    }
  }

  /// Get zone fee structure for regional pricing
  Future<List<Map<String, dynamic>>> getZoneFeeStructure() async {
    try {
      final response = await _client
          .from('regional_pricing')
          .select()
          .eq('is_active', true)
          .order('zone', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get zone fee structure error: $e');
      return [];
    }
  }

  /// Request a payout from wallet balance.
  /// Delegates to PayoutApi (user_wallets + prize_redemptions) to match Web behavior.
  /// Returns (success, errorMessage) so callers can show user-facing errors.
  Future<({bool success, String? errorMessage})> requestPayout({
    required double amount,
    required String method,
  }) async {
    final result = await PayoutApi.instance.requestPayout(
      amount: amount,
      method: method,
      paymentDetails: null,
    );
    if (result.success) {
      await PlatformLoggingService.logEvent(
        eventType: 'payout_request',
        message: 'Payout requested: \$$amount via $method',
        logLevel: 'info',
        logCategory: 'payment',
        metadata: {
          'amount': amount,
          'method': method,
          'user_id': _auth.currentUser?.id,
        },
      );
    }
    return (success: result.success, errorMessage: result.error);
  }

  /// Distribute prizes (called after lottery draw)
  Future<Map<String, dynamic>> distributePrizes(String electionId) async {
    try {
      final response = await _client.rpc(
        'distribute_prizes',
        params: {'p_election_id': electionId},
      );

      await PlatformLoggingService.logEvent(
        eventType: 'prize_distribution',
        message: 'Prize distribution initiated for election',
        logLevel: 'info',
        logCategory: 'payment',
        metadata: {'election_id': electionId, 'result': response},
      );

      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Distribute prizes error: $e');

      await PlatformLoggingService.logEvent(
        eventType: 'prize_distribution_error',
        message: 'Prize distribution failed: ${e.toString()}',
        logLevel: 'error',
        logCategory: 'payment',
        metadata: {'election_id': electionId, 'error': e.toString()},
      );

      return {'success': false, 'message': 'Distribution failed: $e'};
    }
  }

  /// Get earnings breakdown by category for the current user (lottery, predictions, quests)
  Future<Map<String, double>> getEarningsBreakdown() async {
    try {
      if (!_auth.isAuthenticated) {
        return {
          'lottery': 0.0,
          'predictions': 0.0,
          'quests': 0.0,
        };
      }

      final userId = _auth.currentUser!.id;

      // 1. Get Lottery Prizes
      // Sum up prize_amount from lottery_winners table (using migration schema)
      final lotteryResponse = await _client
          .from('lottery_winners')
          .select('prize_amount')
          .eq('user_id', userId);
      
      double lotteryTotal = 0.0;
      if (lotteryResponse != null) {
        for (var row in (lotteryResponse as List)) {
          lotteryTotal += (row['prize_amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // 2. Get Prediction Pool Rewards
      // Although predictions primarily award VP, we'll check prize_distributions for USD
      final prizeDistResponse = await _client
          .from('prize_distributions')
          .select('amount, prizes(distribution_method)')
          .eq('winner_id', userId)
          .eq('status', 'completed');
      
      double predictionTotal = 0.0;
      double questTotal = 0.0;
      
      if (prizeDistResponse != null) {
        for (var row in (prizeDistResponse as List)) {
          final amount = (row['amount'] as num?)?.toDouble() ?? 0.0;
          final prizes = row['prizes'] as Map<String, dynamic>?;
          final method = prizes?['distribution_method']?.toString().toLowerCase() ?? '';
          
          if (method.contains('prediction')) {
            predictionTotal += amount;
          } else if (method.contains('quest') || method.contains('bonus')) {
            questTotal += amount;
          } else if (lotteryTotal == 0 && (method.contains('lottery') || method.contains('draw'))) {
            lotteryTotal += amount;
          } else {
            // Default to predictions to show something on the dashboard if categorized elsewhere
            predictionTotal += amount;
          }
        }
      }

      return {
        'lottery': lotteryTotal,
        'predictions': predictionTotal,
        'quests': questTotal,
      };
    } catch (e) {
      debugPrint('Get earnings breakdown error: $e');
      return {
        'lottery': 0.0,
        'predictions': 0.0,
        'quests': 0.0,
      };
    }
  }
}
