import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Carousel Real-Time Bidding Service
/// Dynamic sponsorship auction system with auto-bidding, zone-based pricing, and CPE optimization
class CarouselRTBService {
  static CarouselRTBService? _instance;
  static CarouselRTBService get instance =>
      _instance ??= CarouselRTBService._();

  CarouselRTBService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================
  // AUCTION MECHANICS
  // ============================================

  /// Create new auction for ad slot
  Future<String?> createAuction({
    required String slotId,
    required double reservePrice,
    int durationSeconds = 60,
  }) async {
    try {
      final auctionEnd = DateTime.now().add(Duration(seconds: durationSeconds));

      final response = await _supabase
          .from('carousel_auctions')
          .insert({
            'slot_id': slotId,
            'auction_start': DateTime.now().toIso8601String(),
            'auction_end': auctionEnd.toIso8601String(),
            'reserve_price': reservePrice,
            'status': 'active',
          })
          .select()
          .single();

      final auctionId = response['auction_id'] as String;

      // Schedule auction closure
      Timer(Duration(seconds: durationSeconds), () => _closeAuction(auctionId));

      return auctionId;
    } catch (e) {
      debugPrint('Create auction error: $e');
      return null;
    }
  }

  /// Submit bid to auction
  Future<bool> submitBid({
    required String auctionId,
    required String slotId,
    required double bidAmount,
    Map<String, dynamic>? targetingParams,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Validate auction is active
      final auctionResponse = await _supabase
          .from('carousel_auctions')
          .select()
          .eq('auction_id', auctionId)
          .maybeSingle();

      if (auctionResponse == null || auctionResponse['status'] != 'active') {
        return false;
      }

      final reservePrice = (auctionResponse['reserve_price'] ?? 0.0) as num;
      if (bidAmount < reservePrice) {
        debugPrint('Bid amount below reserve price');
        return false;
      }

      // Check advertiser budget
      final campaignResponse = await _supabase
          .from('advertiser_campaigns')
          .select()
          .eq('advertiser_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (campaignResponse == null) {
        debugPrint('No active campaign found');
        return false;
      }

      final budgetRemaining =
          ((campaignResponse['total_budget'] ?? 0.0) as num).toDouble() -
          ((campaignResponse['budget_spent'] ?? 0.0) as num).toDouble();

      if (bidAmount > budgetRemaining) {
        debugPrint('Insufficient budget');
        return false;
      }

      // Submit bid
      await _supabase.from('carousel_bids').insert({
        'auction_id': auctionId,
        'advertiser_id': userId,
        'slot_id': slotId,
        'bid_amount': bidAmount,
        'targeting_params': jsonEncode(targetingParams ?? {}),
        'bid_status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Submit bid error: $e');
      return false;
    }
  }

  /// Close auction and determine winner
  Future<void> _closeAuction(String auctionId) async {
    try {
      // Get all bids for auction
      final bidsResponse = await _supabase
          .from('carousel_bids')
          .select()
          .eq('auction_id', auctionId)
          .eq('bid_status', 'pending')
          .order('bid_amount', ascending: false);

      if (bidsResponse.isEmpty) {
        // No bids, cancel auction
        await _supabase
            .from('carousel_auctions')
            .update({'status': 'cancelled'})
            .eq('auction_id', auctionId);
        return;
      }

      // Get highest bid (winner)
      final winningBid = bidsResponse.first;
      final winningBidId = winningBid['bid_id'] as String;
      final highestBidAmount = (winningBid['bid_amount'] ?? 0.0) as num;

      // Second-price auction: winner pays second-highest bid + 0.01
      double winnerPrice = highestBidAmount.toDouble();
      if (bidsResponse.length > 1) {
        final secondHighestBid = bidsResponse[1];
        final secondHighestAmount =
            (secondHighestBid['bid_amount'] ?? 0.0) as num;
        winnerPrice = secondHighestAmount.toDouble() + 0.01;
      }

      // Update auction with winner
      await _supabase
          .from('carousel_auctions')
          .update({
            'winning_bid_id': winningBidId,
            'winner_price': winnerPrice,
            'status': 'closed',
          })
          .eq('auction_id', auctionId);

      // Update bid statuses
      await _supabase
          .from('carousel_bids')
          .update({'bid_status': 'won'})
          .eq('bid_id', winningBidId);

      await _supabase
          .from('carousel_bids')
          .update({'bid_status': 'lost'})
          .eq('auction_id', auctionId)
          .neq('bid_id', winningBidId);

      // Charge advertiser
      final advertiserId = winningBid['advertiser_id'] as String;
      await _chargeAdvertiser(advertiserId, winnerPrice);
    } catch (e) {
      debugPrint('Close auction error: $e');
    }
  }

  Future<void> _chargeAdvertiser(String advertiserId, double amount) async {
    try {
      final campaignResponse = await _supabase
          .from('advertiser_campaigns')
          .select()
          .eq('advertiser_id', advertiserId)
          .eq('status', 'active')
          .maybeSingle();

      if (campaignResponse == null) return;

      final currentSpent = ((campaignResponse['budget_spent'] ?? 0.0) as num)
          .toDouble();
      final newSpent = currentSpent + amount;

      await _supabase
          .from('advertiser_campaigns')
          .update({'budget_spent': newSpent})
          .eq('campaign_id', campaignResponse['campaign_id']);
    } catch (e) {
      debugPrint('Charge advertiser error: $e');
    }
  }

  // ============================================
  // ZONE-BASED PRICING
  // ============================================

  /// Calculate zone-adjusted price
  Future<double> calculateZoneAdjustedPrice({
    required double basePrice,
    required int zoneNumber,
  }) async {
    try {
      final zoneResponse = await _supabase
          .from('zone_pricing_multipliers')
          .select()
          .eq('zone_number', zoneNumber)
          .maybeSingle();

      if (zoneResponse == null) return basePrice;

      final multiplier = (zoneResponse['base_multiplier'] ?? 1.0) as num;
      return basePrice * multiplier.toDouble();
    } catch (e) {
      debugPrint('Calculate zone adjusted price error: $e');
      return basePrice;
    }
  }

  // ============================================
  // AUTO-BIDDING STRATEGIES
  // ============================================

  /// Calculate optimal bid using Maximum CPE strategy
  Future<double> calculateMaxCPEBid({
    required String slotId,
    required double maxCPE,
  }) async {
    try {
      // Get slot engagement rate
      final slotResponse = await _supabase
          .from('carousel_ad_inventory')
          .select()
          .eq('inventory_id', slotId)
          .maybeSingle();

      if (slotResponse == null) return 0.0;

      final estimatedImpressions =
          (slotResponse['estimated_daily_impressions'] ?? 0) as int;
      final engagementRate =
          ((slotResponse['avg_engagement_rate'] ?? 0.0) as num).toDouble() /
          100;

      final estimatedEngagements = estimatedImpressions * engagementRate;
      final optimalBid = maxCPE * estimatedEngagements;

      return optimalBid;
    } catch (e) {
      debugPrint('Calculate max CPE bid error: $e');
      return 0.0;
    }
  }

  /// Calculate optimal bid using Target ROAS strategy
  Future<double> calculateTargetROASBid({
    required String slotId,
    required double targetROAS,
    required double expectedConversionValue,
  }) async {
    try {
      // Get slot engagement rate
      final slotResponse = await _supabase
          .from('carousel_ad_inventory')
          .select()
          .eq('inventory_id', slotId)
          .maybeSingle();

      if (slotResponse == null) return 0.0;

      final estimatedImpressions =
          (slotResponse['estimated_daily_impressions'] ?? 0) as int;
      final engagementRate =
          ((slotResponse['avg_engagement_rate'] ?? 0.0) as num).toDouble() /
          100;

      // Assume 5% conversion rate from engagement
      final estimatedConversions = estimatedImpressions * engagementRate * 0.05;

      if (estimatedConversions == 0) return 0.0;

      final optimalBid =
          (expectedConversionValue * targetROAS) / estimatedConversions;

      return optimalBid;
    } catch (e) {
      debugPrint('Calculate target ROAS bid error: $e');
      return 0.0;
    }
  }

  /// Calculate bid with daily budget pacing
  Future<double> calculatePacedBid({
    required String campaignId,
    required double baseBid,
  }) async {
    try {
      final campaignResponse = await _supabase
          .from('advertiser_campaigns')
          .select()
          .eq('campaign_id', campaignId)
          .maybeSingle();

      if (campaignResponse == null) return baseBid;

      final dailyBudget = ((campaignResponse['daily_budget'] ?? 0.0) as num)
          .toDouble();
      final budgetSpent = ((campaignResponse['budget_spent'] ?? 0.0) as num)
          .toDouble();

      if (dailyBudget == 0) return baseBid;

      // Calculate spend rate
      final currentHour = DateTime.now().hour;
      final expectedSpendByNow = (dailyBudget / 24) * currentHour;

      double adjustedBid = baseBid;

      if (budgetSpent < expectedSpendByNow * 0.8) {
        // Under-pacing, increase bid by 10%
        adjustedBid = baseBid * 1.1;
      } else if (budgetSpent > expectedSpendByNow * 1.2) {
        // Over-pacing, decrease bid by 10%
        adjustedBid = baseBid * 0.9;
      }

      return adjustedBid;
    } catch (e) {
      debugPrint('Calculate paced bid error: $e');
      return baseBid;
    }
  }

  // ============================================
  // CPE OPTIMIZATION
  // ============================================

  /// Track engagement from sponsored content
  Future<void> trackSponsoredEngagement({
    required String bidId,
    required String engagementType,
  }) async {
    try {
      // This would be called when user interacts with sponsored content
      // For now, we'll just log it
      debugPrint('Sponsored engagement tracked: $bidId - $engagementType');
    } catch (e) {
      debugPrint('Track sponsored engagement error: $e');
    }
  }

  /// Calculate actual CPE for campaign
  Future<double> calculateActualCPE({required String campaignId}) async {
    try {
      final campaignResponse = await _supabase
          .from('advertiser_campaigns')
          .select()
          .eq('campaign_id', campaignId)
          .maybeSingle();

      if (campaignResponse == null) return 0.0;

      final budgetSpent = ((campaignResponse['budget_spent'] ?? 0.0) as num)
          .toDouble();

      // Get total engagements (would come from tracking)
      // For now, estimate based on impressions and engagement rate
      final bidsResponse = await _supabase
          .from('carousel_bids')
          .select('slot_id')
          .eq('bid_status', 'won')
          .eq('advertiser_id', campaignResponse['advertiser_id']);

      int totalEngagements = 0;
      for (final bid in bidsResponse) {
        final slotResponse = await _supabase
            .from('carousel_ad_inventory')
            .select()
            .eq('inventory_id', bid['slot_id'])
            .maybeSingle();

        if (slotResponse != null) {
          final impressions =
              (slotResponse['estimated_daily_impressions'] ?? 0) as int;
          final engagementRate =
              ((slotResponse['avg_engagement_rate'] ?? 0.0) as num).toDouble() /
              100;
          totalEngagements += (impressions * engagementRate).toInt();
        }
      }

      if (totalEngagements == 0) return 0.0;

      return budgetSpent / totalEngagements;
    } catch (e) {
      debugPrint('Calculate actual CPE error: $e');
      return 0.0;
    }
  }

  // ============================================
  // CAMPAIGN MANAGEMENT
  // ============================================

  /// Create advertiser campaign
  Future<String?> createCampaign({
    required String campaignName,
    required double totalBudget,
    double? dailyBudget,
    double? targetCPE,
    double? targetROAS,
    String? autoBiddingStrategy,
    List<String>? carouselTargets,
    List<int>? zoneTargets,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('advertiser_campaigns')
          .insert({
            'advertiser_id': userId,
            'campaign_name': campaignName,
            'total_budget': totalBudget,
            'daily_budget': dailyBudget,
            'target_cpe': targetCPE,
            'target_roas': targetROAS,
            'auto_bidding_strategy': autoBiddingStrategy,
            'carousel_targets': jsonEncode(carouselTargets ?? []),
            'zone_targets': jsonEncode(zoneTargets ?? []),
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response['campaign_id'] as String;
    } catch (e) {
      debugPrint('Create campaign error: $e');
      return null;
    }
  }

  /// Get campaign analytics
  Future<Map<String, dynamic>> getCampaignAnalytics({
    required String campaignId,
  }) async {
    try {
      final campaignResponse = await _supabase
          .from('advertiser_campaigns')
          .select()
          .eq('campaign_id', campaignId)
          .maybeSingle();

      if (campaignResponse == null) return {};

      final bidsResponse = await _supabase
          .from('carousel_bids')
          .select()
          .eq('advertiser_id', campaignResponse['advertiser_id']);

      final wonBids = bidsResponse
          .where((b) => b['bid_status'] == 'won')
          .length;
      final totalBids = bidsResponse.length;
      final winRate = totalBids > 0 ? (wonBids / totalBids) * 100 : 0.0;

      final budgetSpent = ((campaignResponse['budget_spent'] ?? 0.0) as num)
          .toDouble();
      final totalBudget = ((campaignResponse['total_budget'] ?? 0.0) as num)
          .toDouble();
      final budgetRemaining = totalBudget - budgetSpent;

      final actualCPE = await calculateActualCPE(campaignId: campaignId);

      return {
        'campaign_name': campaignResponse['campaign_name'],
        'status': campaignResponse['status'],
        'total_budget': totalBudget,
        'budget_spent': budgetSpent,
        'budget_remaining': budgetRemaining,
        'total_bids': totalBids,
        'won_bids': wonBids,
        'win_rate': winRate,
        'actual_cpe': actualCPE,
        'target_cpe': campaignResponse['target_cpe'],
      };
    } catch (e) {
      debugPrint('Get campaign analytics error: $e');
      return {};
    }
  }

  /// Get available ad slots
  Future<List<Map<String, dynamic>>> getAvailableSlots() async {
    try {
      final response = await _supabase
          .from('carousel_ad_inventory')
          .select()
          .eq('status', 'available')
          .order('avg_engagement_rate', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get available slots error: $e');
      return [];
    }
  }

  /// Get active auctions
  Future<List<Map<String, dynamic>>> getActiveAuctions() async {
    try {
      final response = await _supabase
          .from('carousel_auctions')
          .select('*, carousel_ad_inventory(*)')
          .eq('status', 'active')
          .gte('auction_end', DateTime.now().toIso8601String())
          .order('auction_end', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active auctions error: $e');
      return [];
    }
  }
}
