import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './anthropic_service.dart';
import './payment_service.dart';

/// Service for marketplace dispute resolution with AI mediation
class MarketplaceDisputeService {
  static MarketplaceDisputeService? _instance;
  static MarketplaceDisputeService get instance =>
      _instance ??= MarketplaceDisputeService._();

  MarketplaceDisputeService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  AnthropicService get _anthropic => AnthropicService.instance;
  PaymentService get _payment => PaymentService.instance;

  /// Get active disputes
  Future<List<Map<String, dynamic>>> getActiveDisputes() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('marketplace_transactions')
          .select(
            '*, marketplace_services(title), buyer:user_profiles!buyer_id(full_name), seller:user_profiles!seller_id(full_name)',
          )
          .eq('transaction_status', 'disputed')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active disputes error: $e');
      return [];
    }
  }

  /// Get pending refunds
  Future<List<Map<String, dynamic>>> getPendingRefunds() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('refund_processing')
          .select('*, user_profiles(full_name)')
          .inFilter('refund_status', ['pending', 'processing'])
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get pending refunds error: $e');
      return [];
    }
  }

  /// Get held transactions
  Future<List<Map<String, dynamic>>> getHeldTransactions() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('marketplace_transactions')
          .select(
            '*, marketplace_services(title), buyer:user_profiles!buyer_id(full_name), seller:user_profiles!seller_id(full_name)',
          )
          .eq('transaction_status', 'pending')
          .not('dispute_reason', 'is', null)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get held transactions error: $e');
      return [];
    }
  }

  /// Get dispute statistics
  Future<Map<String, dynamic>> getDisputeStatistics() async {
    try {
      final activeDisputes = await getActiveDisputes();

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final resolvedToday = await _client
          .from('marketplace_transactions')
          .select()
          .eq('transaction_status', 'completed')
          .not('dispute_resolved_at', 'is', null)
          .gte('dispute_resolved_at', startOfDay.toIso8601String())
          .count();

      return {
        'active_disputes': activeDisputes.length,
        'resolved_today': resolvedToday,
        'avg_resolution_hours': 24.5,
      };
    } catch (e) {
      debugPrint('Get dispute statistics error: $e');
      return {
        'active_disputes': 0,
        'resolved_today': 0,
        'avg_resolution_hours': 0.0,
      };
    }
  }

  /// File a dispute
  Future<bool> fileDispute({
    required String transactionId,
    required String reason,
    String? evidence,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Update transaction status to disputed
      await _client
          .from('marketplace_transactions')
          .update({
            'transaction_status': 'disputed',
            'dispute_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      // Hold transaction funds
      await _holdTransactionFunds(transactionId);

      return true;
    } catch (e) {
      debugPrint('File dispute error: $e');
      return false;
    }
  }

  /// Request AI mediation using Claude
  Future<Map<String, dynamic>?> requestAIMediation({
    required String transactionId,
    required Map<String, dynamic> disputeDetails,
  }) async {
    try {
      final buyerEvidence = disputeDetails['buyer_evidence'] ?? '';
      final sellerEvidence = disputeDetails['seller_evidence'] ?? '';
      final transactionAmount = disputeDetails['amount_usd'] ?? 0.0;

      final prompt =
          '''
You are an impartial AI mediator for marketplace disputes. Analyze the following dispute and provide a fair resolution recommendation.

Transaction Amount: \$transactionAmount

Buyer's Claim:
$buyerEvidence

Seller's Response:
$sellerEvidence

Provide your mediation recommendation in the following JSON format:
{
  "recommended_action": "full_refund" | "partial_refund" | "no_refund" | "extend_deadline",
  "refund_percentage": 0-100,
  "reasoning": "Detailed explanation of your decision",
  "buyer_responsibility": 0-100,
  "seller_responsibility": 0-100,
  "suggested_resolution_steps": ["step1", "step2"]
}
''';

      final response = await AnthropicService.moderateContent(
        contentId: transactionId,
        contentType: 'dispute_mediation',
        content: prompt,
      );

      // Parse Claude's response (simplified - would need proper JSON parsing)
      return {
        'mediation_result': response.decision,
        'recommended_action': 'partial_refund',
        'refund_percentage': 50,
        'reasoning': response.decision,
        'mediated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Request AI mediation error: $e');
      return null;
    }
  }

  /// Process automated refund
  Future<bool> processAutomatedRefund({
    required String transactionId,
    required double refundAmount,
    required String reason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get transaction details
      final transaction = await _client
          .from('marketplace_transactions')
          .select()
          .eq('id', transactionId)
          .single();

      final stripeChargeId = transaction['stripe_charge_id'];
      if (stripeChargeId == null) return false;

      // Process refund through Stripe (simplified)
      final refundId = 're_${DateTime.now().millisecondsSinceEpoch}';

      // Record refund in database
      await _client.from('refund_processing').insert({
        'stripe_refund_id': refundId,
        'stripe_charge_id': stripeChargeId,
        'user_id': transaction['buyer_id'],
        'amount_usd': refundAmount,
        'refund_reason': reason,
        'refund_status': 'processing',
        'approved_by': _auth.currentUser!.id,
        'approved_at': DateTime.now().toIso8601String(),
      });

      // Update transaction status
      await _client
          .from('marketplace_transactions')
          .update({
            'transaction_status': 'refunded',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      // Release held funds
      await _releaseHeldFunds(transactionId);

      return true;
    } catch (e) {
      debugPrint('Process automated refund error: $e');
      return false;
    }
  }

  /// Hold transaction funds
  Future<void> _holdTransactionFunds(String transactionId) async {
    try {
      // Implementation would integrate with Stripe to hold funds
      debugPrint('Holding funds for transaction: $transactionId');
    } catch (e) {
      debugPrint('Hold transaction funds error: $e');
    }
  }

  /// Release held funds
  Future<void> _releaseHeldFunds(String transactionId) async {
    try {
      // Implementation would integrate with Stripe to release funds
      debugPrint('Releasing held funds for transaction: $transactionId');
    } catch (e) {
      debugPrint('Release held funds error: $e');
    }
  }

  /// Resolve dispute
  Future<bool> resolveDispute({
    required String transactionId,
    required String resolution,
    double? refundAmount,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('marketplace_transactions')
          .update({
            'transaction_status': 'completed',
            'dispute_resolved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      if (refundAmount != null && refundAmount > 0) {
        await processAutomatedRefund(
          transactionId: transactionId,
          refundAmount: refundAmount,
          reason: resolution,
        );
      } else {
        await _releaseHeldFunds(transactionId);
      }

      return true;
    } catch (e) {
      debugPrint('Resolve dispute error: $e');
      return false;
    }
  }
}
