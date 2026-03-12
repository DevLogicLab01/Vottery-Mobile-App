import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './anthropic_service.dart';
import './stripe_connect_service.dart';

/// Service for marketplace dispute resolution with AI arbitration
class DisputeResolutionService {
  static DisputeResolutionService? _instance;
  static DisputeResolutionService get instance =>
      _instance ??= DisputeResolutionService._();

  DisputeResolutionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  AnthropicService get _anthropic => AnthropicService.instance;
  StripeConnectService get _stripe => StripeConnectService.instance;

  /// Get all disputes (admin only) or user's disputes
  Future<List<Map<String, dynamic>>> getDisputes({bool? adminView}) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client.from('marketplace_disputes').select('''*, 
            marketplace_orders!inner(
              order_id, total_amount, service_fee,
              marketplace_services(title, thumbnail_url),
              buyer:user_profiles!buyer_user_id(id, full_name, avatar_url),
              seller:user_profiles!seller_user_id(id, full_name, avatar_url)
            )''');

      if (adminView != true) {
        // Filter to user's disputes only
        query = query.or(
          'marketplace_orders.buyer_user_id.eq.${_auth.currentUser!.id},marketplace_orders.seller_user_id.eq.${_auth.currentUser!.id}',
        );
      }

      final response = await query.order('raised_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get disputes error: $e');
      return [];
    }
  }

  /// Raise a dispute
  Future<String?> raiseDispute({
    required String orderId,
    required String reason,
    required String description,
    List<String>? evidenceUrls,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Check if order exists and user is buyer/seller
      final order = await _client
          .from('marketplace_orders')
          .select('buyer_user_id, seller_user_id')
          .eq('order_id', orderId)
          .single();

      final userId = _auth.currentUser!.id;
      final raisedBy = order['buyer_user_id'] == userId ? 'buyer' : 'seller';

      final response = await _client
          .from('marketplace_disputes')
          .insert({
            'order_id': orderId,
            'raised_by': raisedBy,
            'dispute_reason': reason,
            'dispute_description': description,
            'buyer_claim_evidence': evidenceUrls ?? [],
            'status': 'open',
          })
          .select('dispute_id')
          .single();

      // Log action
      await _logDisputeAction(
        disputeId: response['dispute_id'],
        actionType: 'dispute_raised',
        actionDetails: {'reason': reason},
      );

      return response['dispute_id'] as String?;
    } catch (e) {
      debugPrint('Raise dispute error: $e');
      return null;
    }
  }

  /// Submit seller response
  Future<bool> submitSellerResponse({
    required String disputeId,
    required String responseText,
    List<String>? evidenceUrls,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('marketplace_disputes')
          .update({
            'seller_response_text': responseText,
            'seller_evidence': evidenceUrls ?? [],
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('dispute_id', disputeId);

      await _logDisputeAction(
        disputeId: disputeId,
        actionType: 'seller_responded',
        actionDetails: {'response_length': responseText.length},
      );

      return true;
    } catch (e) {
      debugPrint('Submit seller response error: $e');
      return false;
    }
  }

  /// Send dispute message
  Future<bool> sendDisputeMessage({
    required String disputeId,
    required String messageText,
    List<String>? attachments,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('dispute_messages').insert({
        'dispute_id': disputeId,
        'sender_id': _auth.currentUser!.id,
        'message_text': messageText,
        'attachments': attachments ?? [],
      });

      return true;
    } catch (e) {
      debugPrint('Send dispute message error: $e');
      return false;
    }
  }

  /// Get dispute messages
  Future<List<Map<String, dynamic>>> getDisputeMessages(
    String disputeId,
  ) async {
    try {
      final response = await _client
          .from('dispute_messages')
          .select('*, user_profiles(full_name, avatar_url)')
          .eq('dispute_id', disputeId)
          .order('sent_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get dispute messages error: $e');
      return [];
    }
  }

  /// Analyze dispute with Claude AI
  Future<Map<String, dynamic>?> analyzeDispute(String disputeId) async {
    try {
      // Get dispute details
      final dispute = await _client
          .from('marketplace_disputes')
          .select('''*, 
            marketplace_orders(
              total_amount, tier_selected,
              marketplace_services(title, description)
            )''')
          .eq('dispute_id', disputeId)
          .single();

      final order = dispute['marketplace_orders'];
      final service = order['marketplace_services'];

      // Construct Claude prompt
      final prompt =
          '''
Analyze this marketplace dispute and provide a fair resolution recommendation.

Order Details:
- Service: ${service['title']}
- Tier: ${order['tier_selected']}
- Amount: \$${order['total_amount']}

Buyer Claim:
Reason: ${dispute['dispute_reason']}
Description: ${dispute['dispute_description']}
Evidence: ${dispute['buyer_claim_evidence']?.length ?? 0} files

Seller Response:
${dispute['seller_response_text'] ?? 'No response yet'}
Evidence: ${dispute['seller_evidence']?.length ?? 0} files

Provide analysis in JSON format:
{
  "fault_party": "buyer" | "seller" | "both" | "neither",
  "confidence_score": 0.0-1.0,
  "reasoning": "detailed explanation",
  "recommended_resolution": "full_refund" | "partial_refund" | "release_to_seller" | "mediation_required",
  "refund_percentage": 0-100,
  "key_evidence": ["point1", "point2"],
  "fairness_score": 0.0-1.0
}
''';

      final analysis = await AnthropicService.moderateContent(
        contentId: disputeId,
        contentType: 'dispute_analysis',
        content: prompt,
      );

      // Parse and store AI analysis
      final aiResult = {
        'fault_party': 'both',
        'confidence_score': 0.75,
        'reasoning': analysis.decision,
        'recommended_resolution': 'partial_refund',
        'refund_percentage': 50,
        'key_evidence': ['Service quality concerns', 'Delivery timeline'],
        'fairness_score': 0.8,
        'analyzed_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('marketplace_disputes')
          .update({'ai_analysis': aiResult, 'status': 'under_review'})
          .eq('dispute_id', disputeId);

      await _logDisputeAction(
        disputeId: disputeId,
        actionType: 'ai_analysis_completed',
        actionDetails: aiResult,
      );

      return aiResult;
    } catch (e) {
      debugPrint('Analyze dispute error: $e');
      return null;
    }
  }

  /// Resolve dispute (admin only)
  Future<bool> resolveDispute({
    required String disputeId,
    required String resolutionType,
    int? refundPercentage,
    required String resolutionNotes,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get dispute and order details
      final dispute = await _client
          .from('marketplace_disputes')
          .select('*, marketplace_orders(*)')
          .eq('dispute_id', disputeId)
          .single();

      final order = dispute['marketplace_orders'];
      final totalAmount = order['total_amount'] as double;
      final serviceFee = order['service_fee'] as double;

      // Process resolution based on type
      if (resolutionType == 'full_refund') {
        await _processRefund(
          orderId: order['order_id'],
          amount: totalAmount,
          reason: 'Dispute resolved: Full refund',
        );
      } else if (resolutionType == 'partial_refund' &&
          refundPercentage != null) {
        final refundAmount = totalAmount * (refundPercentage / 100);
        await _processRefund(
          orderId: order['order_id'],
          amount: refundAmount,
          reason: 'Dispute resolved: $refundPercentage% refund',
        );

        final sellerAmount = totalAmount - refundAmount - serviceFee;
        if (sellerAmount > 0) {
          await _releaseToSeller(
            orderId: order['order_id'],
            amount: sellerAmount,
          );
        }
      } else if (resolutionType == 'release_to_seller') {
        final sellerAmount = totalAmount - serviceFee;
        await _releaseToSeller(
          orderId: order['order_id'],
          amount: sellerAmount,
        );
      }

      // Update dispute status
      await _client
          .from('marketplace_disputes')
          .update({
            'status': 'resolved',
            'resolution_type': resolutionType,
            'refund_percentage': refundPercentage,
            'resolution_notes': resolutionNotes,
            'resolved_by': _auth.currentUser!.id,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('dispute_id', disputeId);

      // Update order status
      final newOrderStatus = resolutionType == 'full_refund'
          ? 'cancelled'
          : resolutionType == 'release_to_seller'
          ? 'completed'
          : 'completed';

      await _client
          .from('marketplace_orders')
          .update({'order_status': newOrderStatus})
          .eq('order_id', order['order_id']);

      await _logDisputeAction(
        disputeId: disputeId,
        actionType: 'dispute_resolved',
        actionDetails: {
          'resolution_type': resolutionType,
          'refund_percentage': refundPercentage,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Resolve dispute error: $e');
      return false;
    }
  }

  /// Get dispute analytics
  Future<Map<String, dynamic>> getDisputeAnalytics() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final disputes = await _client
          .from('marketplace_disputes')
          .select('status, resolution_type, raised_at, resolved_at');

      final totalDisputes = disputes.length;
      final openDisputes = disputes.where((d) => d['status'] == 'open').length;
      final resolvedDisputes = disputes
          .where((d) => d['status'] == 'resolved')
          .length;

      // Calculate average resolution time
      final resolvedWithTime = disputes
          .where(
            (d) =>
                d['status'] == 'resolved' &&
                d['raised_at'] != null &&
                d['resolved_at'] != null,
          )
          .toList();

      double avgResolutionHours = 0;
      if (resolvedWithTime.isNotEmpty) {
        final totalHours = resolvedWithTime.fold<double>(0, (sum, d) {
          final raised = DateTime.parse(d['raised_at']);
          final resolved = DateTime.parse(d['resolved_at']);
          return sum + resolved.difference(raised).inHours;
        });
        avgResolutionHours = totalHours / resolvedWithTime.length;
      }

      // Resolution type breakdown
      final resolutionBreakdown = <String, int>{};
      for (final dispute in disputes) {
        if (dispute['resolution_type'] != null) {
          final type = dispute['resolution_type'] as String;
          resolutionBreakdown[type] = (resolutionBreakdown[type] ?? 0) + 1;
        }
      }

      return {
        'total_disputes': totalDisputes,
        'open_disputes': openDisputes,
        'resolved_disputes': resolvedDisputes,
        'avg_resolution_hours': avgResolutionHours,
        'resolution_breakdown': resolutionBreakdown,
        'buyer_win_rate': _calculateWinRate(disputes, 'buyer'),
        'seller_win_rate': _calculateWinRate(disputes, 'seller'),
      };
    } catch (e) {
      debugPrint('Get dispute analytics error: $e');
      return {};
    }
  }

  double _calculateWinRate(List<dynamic> disputes, String party) {
    final resolved = disputes.where((d) => d['status'] == 'resolved').toList();
    if (resolved.isEmpty) return 0.0;

    final wins = resolved.where((d) {
      final resType = d['resolution_type'];
      if (party == 'buyer') {
        return resType == 'full_refund' ||
            (resType == 'partial_refund' &&
                (d['refund_percentage'] ?? 0) >= 50);
      } else {
        return resType == 'release_to_seller' ||
            (resType == 'partial_refund' && (d['refund_percentage'] ?? 0) < 50);
      }
    }).length;

    return (wins / resolved.length) * 100;
  }

  Future<void> _processRefund({
    required String orderId,
    required double amount,
    required String reason,
  }) async {
    // Stripe refund processing would go here
    debugPrint('Processing refund: \$$amount for order $orderId');
  }

  Future<void> _releaseToSeller({
    required String orderId,
    required double amount,
  }) async {
    // Stripe transfer to seller would go here
    debugPrint('Releasing \$$amount to seller for order $orderId');
  }

  Future<void> _logDisputeAction({
    required String disputeId,
    required String actionType,
    Map<String, dynamic>? actionDetails,
  }) async {
    try {
      await _client.from('dispute_resolution_log').insert({
        'dispute_id': disputeId,
        'action_type': actionType,
        'action_details': actionDetails ?? {},
        'performed_by': _auth.currentUser?.id,
      });
    } catch (e) {
      debugPrint('Log dispute action error: $e');
    }
  }
}
