import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'supabase_service.dart';

/// Vottery Ads Service (Mobile)
/// Uses unified Vottery Ads Studio tables:
/// - vottery_ad_campaigns
/// - vottery_ad_groups
/// - vottery_ad_targeting_geo
/// - vottery_ads
/// - spark_ad_references
class VotteryAdsService {
  VotteryAdsService._();

  static VotteryAdsService? _instance;
  static VotteryAdsService get instance =>
      _instance ??= VotteryAdsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  Future<Map<String, dynamic>> createCampaign({
    required String name,
    required String objective,
  }) async {
    if (!_auth.isAuthenticated) {
      throw Exception('User must be authenticated to create campaigns');
    }
    final userId = _auth.currentUser!.id;

    final response = await _client
        .from('vottery_ad_campaigns')
        .insert({
          'advertiser_id': userId,
          'name': name,
          'objective': objective,
          'status': 'active',
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> createAdGroup({
    required String campaignId,
    required String name,
    required List<int> targetZones,
    required List<String> targetCountries,
    required String placementMode,
    required List<String> placementSlots,
    int? dailyBudgetCents,
    int? lifetimeBudgetCents,
  }) async {
    final response = await _client
        .from('vottery_ad_groups')
        .insert({
          'campaign_id': campaignId,
          'name': name,
          'target_zones': targetZones,
          'target_countries': targetCountries,
          'placement_mode': placementMode,
          'placement_slots':
              placementSlots.isEmpty ? null : placementSlots,
          'daily_budget_cents': dailyBudgetCents,
          'lifetime_budget_cents': lifetimeBudgetCents,
          'status': 'active',
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> setTargetingGeo({
    required String adGroupId,
    required List<Map<String, String>> regions,
  }) async {
    await _client
        .from('vottery_ad_targeting_geo')
        .delete()
        .eq('ad_group_id', adGroupId);

    if (regions.isEmpty) return;

    await _client.from('vottery_ad_targeting_geo').insert(
      regions.map((r) {
        return {
          'ad_group_id': adGroupId,
          'country_iso': r['country_iso'],
          'region_code': r['region_code'],
          'region_name': r['region_name'],
        };
      }).toList(),
    );
  }

  Future<Map<String, dynamic>> createAd({
    required String adGroupId,
    required String name,
    required String adType,
    required Map<String, dynamic> creative,
    String? electionId,
    bool enableGamification = false,
    int? prizePoolCents,
    String? sourcePostId,
    required int bidAmountCents,
    required String pricingModel,
  }) async {
    final response = await _client
        .from('vottery_ads')
        .insert({
          'ad_group_id': adGroupId,
          'name': name,
          'ad_type': adType,
          'status': 'active',
          'creative': creative,
          'election_id': electionId,
          'enable_gamification': enableGamification,
          'prize_pool_cents': prizePoolCents,
          'source_post_id': sourcePostId,
          'bid_amount_cents': bidAmountCents,
          'pricing_model': pricingModel,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> upsertSparkReference({
    required String adId,
    required String sourcePostId,
    required String sourceType,
    String? ctaLabel,
    String? ctaDestinationUrl,
  }) async {
    await _client.from('spark_ad_references').upsert(
      {
        'ad_id': adId,
        'source_post_id': sourcePostId,
        'source_type': sourceType,
        'cta_label': ctaLabel,
        'cta_destination_url': ctaDestinationUrl,
      },
      onConflict: 'ad_id',
    );
  }

  Future<Map<String, dynamic>> getAdminConfig() async {
    final response = await _client
        .from('vottery_ads_admin_config')
        .select('key, value_json');

    final result = <String, dynamic>{};
    for (final row in response as List) {
      final map = Map<String, dynamic>.from(row as Map);
      result[map['key'] as String] = map['value_json'];
    }
    return result;
  }

  Future<void> updateAdminConfig({
    required String key,
    required dynamic value,
  }) async {
    await _client.from('vottery_ads_admin_config').upsert({
      'key': key,
      'value_json': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}

