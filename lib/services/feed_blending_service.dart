import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedBlendingService {
  static final FeedBlendingService _instance = FeedBlendingService._internal();
  static FeedBlendingService get instance => _instance;
  FeedBlendingService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  static const int adInterval = 7;

  Future<List<Map<String, dynamic>>> getSponsoredElections({
    int limit = 5,
    String? userZone,
  }) async {
    try {
      var query = _supabase
          .from('sponsored_elections')
          .select('*')
          .eq('status', 'active')
          .order('bid_amount', ascending: false)
          .limit(limit);

      final response = await query;
      return (response as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        m['_sponsoredTag'] = true;
        m['_adType'] = 'sponsored_election';
        return m;
      }).toList();
    } catch (e) {
      debugPrint('FeedBlendingService.getSponsoredElections error: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> blendAdsIntoFeed(
    List<Map<String, dynamic>> organicItems,
    List<Map<String, dynamic>> sponsoredItems,
  ) {
    if (sponsoredItems.isEmpty) return organicItems;

    final blended = <Map<String, dynamic>>[];
    int adIndex = 0;

    for (int i = 0; i < organicItems.length; i++) {
      blended.add(organicItems[i]);
      if ((i + 1) % adInterval == 0 && adIndex < sponsoredItems.length) {
        blended.add(sponsoredItems[adIndex]);
        adIndex++;
      }
    }
    return blended;
  }

  bool isSponsoredItem(Map<String, dynamic> item) {
    return item['_sponsoredTag'] == true;
  }
}
