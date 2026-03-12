import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'vottery_auction_service.dart';

/// Sealed class hierarchy for ad slot content
abstract class AdSlotContent {}

class InternalAdContent extends AdSlotContent {
  final String electionId;
  final String adId;
  final Map<String, dynamic> campaignData;

  InternalAdContent({
    required this.electionId,
    required this.adId,
    required this.campaignData,
  });
}

class InternalVotteryAdContent extends AdSlotContent {
  final String adId;
  final String adType; // display/video/participatory/spark
  final String? electionId;
  final String? sourcePostId;
  final Map<String, dynamic> creative;

  InternalVotteryAdContent({
    required this.adId,
    required this.adType,
    required this.creative,
    this.electionId,
    this.sourcePostId,
  });
}

class AdSenseAdContent extends AdSlotContent {
  final String adUnitId;

  AdSenseAdContent({required this.adUnitId});
}

/// Ad Slot Orchestration Service
/// Prioritizes internal sponsored election ads from Supabase,
/// falls back to Google AdSense for unfilled slots.
class AdSlotOrchestrationService {
  static final AdSlotOrchestrationService _instance =
      AdSlotOrchestrationService._internal();
  static AdSlotOrchestrationService get instance => _instance;
  AdSlotOrchestrationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const int _maxImpressionsPerDay = 3;

  String _mapSlotIdToPlacementKey(String slotId) {
    if (slotId.startsWith('home_feed_')) return 'feed_post';
    if (slotId == 'profile_top') return 'creators_marketplace';
    if (slotId == 'election_detail_bottom') return 'elections_voting_ui';
    return slotId;
  }

  Future<void> recordVotteryAdEvent({
    required String adId,
    required String eventType,
    required String slotId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('ad_events').insert({
        'ad_id': adId,
        'user_id': userId,
        'event_type': eventType,
        'slot_id': slotId,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('recordVotteryAdEvent error: $e');
    }
  }

  /// Main method: returns best ad for a given slot
  Future<AdSlotContent?> getAdForSlot(String slotId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return AdSenseAdContent(adUnitId: _getAdSenseUnitId(slotId));
      }

      // Step 1: Get user purchasing power zone
      final currentUserZone = await _getUserPurchasingPowerZone(userId);
      final placementKey = _mapSlotIdToPlacementKey(slotId);

      // Step 2: Prefer unified Vottery Ads (vottery_ads) with auction scoring
      final votteryAdsResp = await _supabase
          .from('vottery_ads')
          .select(
            'id, ad_type, creative, election_id, source_post_id, bid_amount_cents, quality_score, '
            'ad_quality_metrics(quality_score, hook_rate, hold_rate, neg_score), '
            'vottery_ad_groups!inner(target_zones, placement_mode, placement_slots)',
          )
          .eq('status', 'active')
          .gte('bid_amount_cents', 0)
          .order('bid_amount_cents', ascending: false)
          .limit(30);

      final votteryAds = (votteryAdsResp as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (votteryAds.isNotEmpty) {
        // frequency cap via ad_events (last 24h)
        final since = DateTime.now()
            .subtract(const Duration(hours: 24))
            .toIso8601String();
        final eventsResp = await _supabase
            .from('ad_events')
            .select('ad_id')
            .eq('user_id', userId)
            .eq('event_type', 'IMPRESSION')
            .gte('timestamp', since);
        final counts = <String, int>{};
        for (final row in (eventsResp as List<dynamic>)) {
          final adId = (row as Map)['ad_id']?.toString();
          if (adId != null) counts[adId] = (counts[adId] ?? 0) + 1;
        }

        const maxImpressionsPerDay = 5;
        final eligible = <Map<String, dynamic>>[];
        for (final ad in votteryAds) {
          final ag = ad['vottery_ad_groups'];
          if (ag is! Map) continue;
          final zones = (ag['target_zones'] as List?)?.map((z) => (z as num).toInt()).toList() ?? [];
          if (zones.isNotEmpty && !zones.contains(currentUserZone)) continue;
          final placementSlots =
              (ag['placement_slots'] as List?)?.map((s) => s.toString()).toList();
          if (placementSlots != null && placementSlots.isNotEmpty) {
            if (!placementSlots.contains(placementKey)) continue;
          }
          final id = ad['id']?.toString();
          if (id != null && (counts[id] ?? 0) >= maxImpressionsPerDay) continue;
          eligible.add(ad);
        }

        if (eligible.isNotEmpty) {
          final candidates = eligible.map((ad) {
            final id = ad['id'].toString();
            final bid = (ad['bid_amount_cents'] as num?)?.toInt() ?? 0;
            final aqm = ad['ad_quality_metrics'];
            final qs = (aqm is Map && aqm['quality_score'] != null)
                ? (aqm['quality_score'] as num).toDouble()
                : (ad['quality_score'] as num?)?.toDouble() ?? 100.0;
            return VotteryAdCandidate(
              adId: id,
              bidCents: bid,
              qualityScore: qs,
              raw: ad,
            );
          }).toList();

          final result = VotteryAuctionService.runSecondPriceAuction(candidates);
          if (result != null) {
            final winner = result.winner.raw;
            final winnerId = winner['id'].toString();
            await _supabase.from('ad_events').insert({
              'ad_id': winnerId,
              'user_id': userId,
              'event_type': 'IMPRESSION',
              'slot_id': slotId,
              'metadata': {
                'auction': {
                  'clearing_price_cents': result.clearingPriceCents,
                  'winner_tvs': result.winnerTvs,
                  'runner_up_tvs': result.runnerUpTvs,
                },
                'placement': placementKey,
                'user_zone': currentUserZone,
              },
            });

            return InternalVotteryAdContent(
              adId: winnerId,
              adType: winner['ad_type']?.toString() ?? 'display',
              creative: Map<String, dynamic>.from(
                (winner['creative'] as Map?) ?? <String, dynamic>{},
              ),
              electionId: winner['election_id']?.toString(),
              sourcePostId: winner['source_post_id']?.toString(),
            );
          }
        }
      }

      // Step 3: Legacy internal sponsored election ads (fallback)
      final response = await _supabase
          .from('sponsored_elections')
          .select(
            'id, campaign_name, description, image_url, ad_format_type, engagement_metrics, bid_amount, election_id',
          )
          .eq('status', 'active')
          .contains('target_zones', [currentUserZone])
          .order('bid_amount', ascending: false)
          .limit(5);

      final ads = response as List<dynamic>;

      // Step 4: Find first ad that passes frequency cap
      for (final ad in ads) {
        final adId = ad['id'] as String;
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final impressionCount = await _getAdImpressionCount(
          userId,
          adId,
          today,
        );

        if (impressionCount >= _maxImpressionsPerDay) continue;

        // Step 5: Record impression
        await _recordImpression(userId, adId, slotId);

        return InternalAdContent(
          electionId: ad['election_id'] as String? ?? adId,
          adId: adId,
          campaignData: Map<String, dynamic>.from(ad as Map),
        );
      }

      // Step 6: Fallback to AdSense
      return AdSenseAdContent(adUnitId: _getAdSenseUnitId(slotId));
    } catch (e) {
      debugPrint('AdSlotOrchestrationService.getAdForSlot error: $e');
      return AdSenseAdContent(adUnitId: _getAdSenseUnitId(slotId));
    }
  }

  /// Record ad click
  Future<void> recordAdClick(String adId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      await _supabase.from('ad_clicks').insert({
        'user_id': userId,
        'ad_id': adId,
        'clicked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('recordAdClick error: $e');
    }
  }

  /// Maps slot IDs to AdSense unit IDs
  String _getAdSenseUnitId(String slotId) {
    switch (slotId) {
      case 'home_feed_1':
        return 'ca-app-pub-xxx/home_feed_1';
      case 'home_feed_2':
        return 'ca-app-pub-xxx/home_feed_2';
      case 'profile_top':
        return 'ca-app-pub-xxx/profile_top';
      case 'election_detail_bottom':
        return 'ca-app-pub-xxx/election_detail_bottom';
      default:
        return 'ca-app-pub-xxx/default';
    }
  }

  /// Get user purchasing power zone (1-8)
  Future<int> _getUserPurchasingPowerZone(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('purchasing_power_zone')
          .eq('id', userId)
          .maybeSingle();
      if (response != null && response['purchasing_power_zone'] != null) {
        return (response['purchasing_power_zone'] as num).toInt();
      }
    } catch (e) {
      debugPrint('_getUserPurchasingPowerZone error: $e');
    }
    return 1; // Default zone
  }

  /// Count impressions for a specific ad today
  Future<int> _getAdImpressionCount(
    String userId,
    String adId,
    String date,
  ) async {
    try {
      final response = await _supabase
          .from('ad_impressions')
          .select('impression_id')
          .eq('user_id', userId)
          .eq('ad_id', adId)
          .gte('impression_timestamp', '${date}T00:00:00')
          .lt('impression_timestamp', '${date}T23:59:59');
      return (response as List).length;
    } catch (e) {
      debugPrint('_getAdImpressionCount error: $e');
      return 0;
    }
  }

  /// Record an ad impression
  Future<void> _recordImpression(
    String userId,
    String adId,
    String slotId,
  ) async {
    try {
      await _supabase.from('ad_impressions').insert({
        'user_id': userId,
        'ad_id': adId,
        'slot_id': slotId,
        'impression_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('_recordImpression error: $e');
    }
  }
}
