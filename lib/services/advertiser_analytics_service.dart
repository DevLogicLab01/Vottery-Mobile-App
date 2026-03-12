import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class AdvertiserAnalyticsService {
  static AdvertiserAnalyticsService? _instance;
  static AdvertiserAnalyticsService get instance =>
      _instance ??= AdvertiserAnalyticsService._();

  AdvertiserAnalyticsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // ──────────────────────────────────────────────────────────────────────────
  // Vottery Ads Studio (unified) analytics (vottery_* tables + ad_events)
  // ──────────────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getVotteryAdsCampaigns({
    required String advertiserId,
  }) async {
    try {
      final resp = await _client
          .from('vottery_ad_campaigns')
          .select('id, name, objective, status, created_at')
          .eq('advertiser_id', advertiserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(resp);
    } catch (e) {
      debugPrint('getVotteryAdsCampaigns error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getVotteryAdsCampaignPerformance({
    required String advertiserId,
    String timeRange = '30d',
  }) async {
    try {
      final startDate = _startDateIso(timeRange);

      final campaigns = await _client
          .from('vottery_ad_campaigns')
          .select('id')
          .eq('advertiser_id', advertiserId);
      final campaignIds = (campaigns as List)
          .map((c) => (c as Map)['id'].toString())
          .toList();
      if (campaignIds.isEmpty) return _getDefaultAnalytics();

      final groups = await _client
          .from('vottery_ad_groups')
          .select('id,campaign_id')
          .in_('campaign_id', campaignIds);
      final groupIds = (groups as List)
          .map((g) => (g as Map)['id'].toString())
          .toList();
      if (groupIds.isEmpty) return _getDefaultAnalytics();

      final ads = await _client
          .from('vottery_ads')
          .select('id,bid_amount_cents')
          .in_('ad_group_id', groupIds);
      final adList = (ads as List).map((a) => Map<String, dynamic>.from(a)).toList();
      final adIds = adList.map((a) => a['id'].toString()).toList();
      if (adIds.isEmpty) return _getDefaultAnalytics();

      final events = await _client
          .from('ad_events')
          .select('ad_id,event_type,metadata,timestamp,user_id')
          .in_('ad_id', adIds)
          .gte('timestamp', startDate);

      int impressions = 0;
      int clicks = 0;
      int completes = 0;
      int hides = 0;
      int reports = 0;
      int spendCents = 0;

      final bidByAd = <String, int>{};
      for (final a in adList) {
        bidByAd[a['id'].toString()] =
            (a['bid_amount_cents'] as num?)?.toInt() ?? 0;
      }

      for (final row in (events as List)) {
        final map = Map<String, dynamic>.from(row as Map);
        final type = (map['event_type'] ?? '').toString();
        if (type == 'IMPRESSION') {
          impressions++;
          final meta = map['metadata'];
          final clearing = (meta is Map &&
                  meta['auction'] is Map &&
                  (meta['auction'] as Map)['clearing_price_cents'] != null)
              ? (meta['auction'] as Map)['clearing_price_cents']
              : null;
          final clearingInt = clearing is num ? clearing.toInt() : int.tryParse(clearing?.toString() ?? '');
          spendCents += clearingInt ?? (bidByAd[map['ad_id'].toString()] ?? 0);
        } else if (type == 'CLICK') {
          clicks++;
        } else if (type == 'COMPLETE') {
          completes++;
        } else if (type == 'HIDE') {
          hides++;
        } else if (type == 'REPORT') {
          reports++;
        }
      }

      final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0.0;
      final conversionRate = clicks > 0 ? (completes / clicks) * 100 : 0.0;
      final cpp = completes > 0 ? spendCents / completes : 0.0;

      return {
        'total_impressions': impressions,
        'total_clicks': clicks,
        'total_participants': completes,
        'cost_per_participant': cpp / 100.0,
        'conversion_rate': conversionRate,
        'engagement_rate': ctr,
        'roi_percentage': 0.0, // ROI needs revenue attribution inputs
        'total_revenue': 0.0,
        'total_spent': spendCents / 100.0,
      };
    } catch (e) {
      debugPrint('getVotteryAdsCampaignPerformance error: $e');
      return _getDefaultAnalytics();
    }
  }

  Future<Map<String, int>> getVotteryReachByZone({
    required String advertiserId,
    String timeRange = '30d',
  }) async {
    try {
      final startDate = _startDateIso(timeRange);
      // Get advertiser ad ids
      final campaigns = await _client
          .from('vottery_ad_campaigns')
          .select('id')
          .eq('advertiser_id', advertiserId);
      final campaignIds = (campaigns as List).map((c) => (c as Map)['id']).toList();
      if (campaignIds.isEmpty) return _getDefaultZoneReach();
      final groups = await _client.from('vottery_ad_groups').select('id').in_('campaign_id', campaignIds);
      final groupIds = (groups as List).map((g) => (g as Map)['id']).toList();
      if (groupIds.isEmpty) return _getDefaultZoneReach();
      final ads = await _client.from('vottery_ads').select('id').in_('ad_group_id', groupIds);
      final adIds = (ads as List).map((a) => (a as Map)['id']).toList();
      if (adIds.isEmpty) return _getDefaultZoneReach();

      final events = await _client
          .from('ad_events')
          .select('user_id,event_type,timestamp')
          .in_('ad_id', adIds)
          .eq('event_type', 'IMPRESSION')
          .gte('timestamp', startDate);
      final userIds = (events as List)
          .map((e) => (e as Map)['user_id']?.toString())
          .where((x) => x != null && x!.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      if (userIds.isEmpty) return _getDefaultZoneReach();

      final users = await _client
          .from('user_profiles')
          .select('id,purchasing_power_zone')
          .in_('id', userIds);
      final zoneByUser = <String, int>{};
      for (final u in (users as List)) {
        final m = Map<String, dynamic>.from(u as Map);
        zoneByUser[m['id'].toString()] =
            (m['purchasing_power_zone'] as num?)?.toInt() ?? 1;
      }

      final reach = <String, int>{};
      for (final e in (events as List)) {
        final m = Map<String, dynamic>.from(e as Map);
        final uid = m['user_id']?.toString();
        if (uid == null) continue;
        final z = zoneByUser[uid] ?? 1;
        final key = 'zone_$z';
        reach[key] = (reach[key] ?? 0) + 1;
      }

      return reach;
    } catch (e) {
      debugPrint('getVotteryReachByZone error: $e');
      return _getDefaultZoneReach();
    }
  }

  Future<Map<String, int>> getVotteryReachByCountry({
    required String advertiserId,
    String timeRange = '30d',
  }) async {
    try {
      final startDate = _startDateIso(timeRange);
      final campaigns = await _client
          .from('vottery_ad_campaigns')
          .select('id')
          .eq('advertiser_id', advertiserId);
      final campaignIds = (campaigns as List).map((c) => (c as Map)['id']).toList();
      if (campaignIds.isEmpty) return {};
      final groups = await _client.from('vottery_ad_groups').select('id').in_('campaign_id', campaignIds);
      final groupIds = (groups as List).map((g) => (g as Map)['id']).toList();
      if (groupIds.isEmpty) return {};
      final ads = await _client.from('vottery_ads').select('id').in_('ad_group_id', groupIds);
      final adIds = (ads as List).map((a) => (a as Map)['id']).toList();
      if (adIds.isEmpty) return {};

      final events = await _client
          .from('ad_events')
          .select('user_id,event_type,timestamp')
          .in_('ad_id', adIds)
          .eq('event_type', 'IMPRESSION')
          .gte('timestamp', startDate);
      final userIds = (events as List)
          .map((e) => (e as Map)['user_id']?.toString())
          .where((x) => x != null && x!.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      if (userIds.isEmpty) return {};

      final users = await _client
          .from('user_profiles')
          .select('id,country_iso,region_code,region_name')
          .in_('id', userIds);
      final uById = <String, Map<String, dynamic>>{};
      for (final u in (users as List)) {
        final m = Map<String, dynamic>.from(u as Map);
        uById[m['id'].toString()] = m;
      }

      final byCountry = <String, int>{};
      for (final e in (events as List)) {
        final m = Map<String, dynamic>.from(e as Map);
        final uid = m['user_id']?.toString();
        if (uid == null) continue;
        final u = uById[uid];
        final country = (u?['country_iso'] ?? 'UNKNOWN').toString();
        byCountry[country] = (byCountry[country] ?? 0) + 1;
      }
      return byCountry;
    } catch (e) {
      debugPrint('getVotteryReachByCountry error: $e');
      return {};
    }
  }

  String _startDateIso(String timeRange) {
    final now = DateTime.now();
    if (timeRange == '24h') {
      return now.subtract(const Duration(hours: 24)).toIso8601String();
    }
    if (timeRange == '7d') {
      return now.subtract(const Duration(days: 7)).toIso8601String();
    }
    return now.subtract(const Duration(days: 30)).toIso8601String();
  }

  /// Get comprehensive campaign analytics
  Future<Map<String, dynamic>> getCampaignAnalytics({
    required String campaignId,
  }) async {
    try {
      final response = await _client
          .from('campaign_analytics')
          .select()
          .eq('brand_partnership_id', campaignId)
          .order('date', ascending: false);

      if (response.isEmpty) return _getDefaultAnalytics();

      final analytics = List<Map<String, dynamic>>.from(response);
      final latest = analytics.first;

      // Calculate aggregated metrics
      int totalImpressions = 0;
      int totalClicks = 0;
      int totalParticipants = 0;
      double totalRevenue = 0.0;
      double totalSpent = 0.0;

      for (var record in analytics) {
        totalImpressions += (record['total_impressions'] ?? 0) as int;
        totalClicks += (record['total_clicks'] ?? 0) as int;
        totalParticipants += (record['total_participants'] ?? 0) as int;
        totalRevenue += ((record['revenue_generated'] ?? 0.0) as num)
            .toDouble();
      }

      // Get campaign budget
      final campaignResponse = await _client
          .from('brand_partnerships')
          .select('budget, spent')
          .eq('id', campaignId)
          .maybeSingle();

      totalSpent = ((campaignResponse?['spent'] ?? 0.0) as num).toDouble();

      final costPerParticipant = totalParticipants > 0
          ? totalSpent / totalParticipants
          : 0.0;
      final conversionRate = totalClicks > 0
          ? (totalParticipants / totalClicks) * 100
          : 0.0;
      final roi = totalSpent > 0
          ? ((totalRevenue - totalSpent) / totalSpent) * 100
          : 0.0;

      return {
        'total_impressions': totalImpressions,
        'total_clicks': totalClicks,
        'total_participants': totalParticipants,
        'cost_per_participant': costPerParticipant,
        'conversion_rate': conversionRate,
        'engagement_rate': (latest['engagement_rate'] ?? 0.0) as num,
        'roi_percentage': roi,
        'total_revenue': totalRevenue,
        'total_spent': totalSpent,
        'daily_analytics': analytics,
      };
    } catch (e) {
      debugPrint('Get campaign analytics error: $e');
      return _getDefaultAnalytics();
    }
  }

  /// Get reach by zone
  Future<Map<String, int>> getReachByZone({required String campaignId}) async {
    try {
      final response = await _client
          .from('campaign_analytics')
          .select()
          .eq('brand_partnership_id', campaignId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return _getDefaultZoneReach();

      return {
        'zone_1_us_canada': response['zone_1_reach'] ?? 0,
        'zone_2_western_europe': response['zone_2_reach'] ?? 0,
        'zone_3_eastern_europe_russia': response['zone_3_reach'] ?? 0,
        'zone_4_africa': response['zone_4_reach'] ?? 0,
        'zone_5_latin_america_caribbean': response['zone_5_reach'] ?? 0,
        'zone_6_middle_east_asia': response['zone_6_reach'] ?? 0,
        'zone_7_australasia_advanced_asia': response['zone_7_reach'] ?? 0,
        'zone_8_china_hong_kong_macau': response['zone_8_reach'] ?? 0,
      };
    } catch (e) {
      debugPrint('Get reach by zone error: $e');
      return _getDefaultZoneReach();
    }
  }

  /// Get conversion rates by zone
  Future<Map<String, dynamic>> getConversionsByZone({
    required String campaignId,
  }) async {
    try {
      final response = await _client
          .from('campaign_analytics')
          .select()
          .eq('brand_partnership_id', campaignId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return _getDefaultZoneConversions();

      return {
        'zone_1_us_canada': response['zone_1_conversions'] ?? 0,
        'zone_2_western_europe': response['zone_2_conversions'] ?? 0,
        'zone_3_eastern_europe_russia': response['zone_3_conversions'] ?? 0,
        'zone_4_africa': response['zone_4_conversions'] ?? 0,
        'zone_5_latin_america_caribbean': response['zone_5_conversions'] ?? 0,
        'zone_6_middle_east_asia': response['zone_6_conversions'] ?? 0,
        'zone_7_australasia_advanced_asia': response['zone_7_conversions'] ?? 0,
        'zone_8_china_hong_kong_macau': response['zone_8_conversions'] ?? 0,
      };
    } catch (e) {
      debugPrint('Get conversions by zone error: $e');
      return _getDefaultZoneConversions();
    }
  }

  /// Get ROI breakdown for multiple campaigns
  Future<List<Map<String, dynamic>>> getROIBreakdown({
    required String brandId,
  }) async {
    try {
      final campaigns = await _client
          .from('brand_partnerships')
          .select('id, campaign_name, budget, spent')
          .eq('brand_id', brandId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> roiBreakdown = [];

      for (var campaign in campaigns) {
        final campaignId = campaign['id'] as String;
        final analytics = await getCampaignAnalytics(campaignId: campaignId);

        roiBreakdown.add({
          'brand_partnership_id': campaignId,
          'campaign_name': campaign['campaign_name'],
          'budget': campaign['budget'],
          'spent': campaign['spent'],
          'revenue': analytics['total_revenue'],
          'roi_percentage': analytics['roi_percentage'],
          'cost_per_participant': analytics['cost_per_participant'],
          'conversion_rate': analytics['conversion_rate'],
          'total_participants': analytics['total_participants'],
        });
      }

      return roiBreakdown;
    } catch (e) {
      debugPrint('Get ROI breakdown error: $e');
      return [];
    }
  }

  /// Get performance trends over time
  Future<List<Map<String, dynamic>>> getPerformanceTrends({
    required String campaignId,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now()
          .subtract(Duration(days: days))
          .toIso8601String();

      final response = await _client
          .from('campaign_analytics')
          .select()
          .eq('brand_partnership_id', campaignId)
          .gte('date', startDate)
          .order('date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get performance trends error: $e');
      return [];
    }
  }

  /// Get advertiser dashboard summary
  Future<Map<String, dynamic>> getAdvertiserDashboardSummary({
    required String brandId,
  }) async {
    try {
      // Get all campaigns
      final campaigns = await _client
          .from('brand_partnerships')
          .select('id, status')
          .eq('brand_id', brandId);

      int activeCampaigns = 0;
      int totalCampaigns = campaigns.length;
      double totalSpent = 0.0;
      double totalRevenue = 0.0;
      int totalParticipants = 0;

      for (var campaign in campaigns) {
        if (campaign['status'] == 'open' ||
            campaign['status'] == 'in_progress') {
          activeCampaigns++;
        }

        final analytics = await getCampaignAnalytics(
          campaignId: campaign['id'] as String,
        );
        totalSpent += (analytics['total_spent'] ?? 0.0) as double;
        totalRevenue += (analytics['total_revenue'] ?? 0.0) as double;
        totalParticipants += (analytics['total_participants'] ?? 0) as int;
      }

      final avgCostPerParticipant = totalParticipants > 0
          ? totalSpent / totalParticipants
          : 0.0;
      final overallROI = totalSpent > 0
          ? ((totalRevenue - totalSpent) / totalSpent) * 100
          : 0.0;

      return {
        'active_campaigns': activeCampaigns,
        'total_campaigns': totalCampaigns,
        'total_spent': totalSpent,
        'total_revenue': totalRevenue,
        'total_participants': totalParticipants,
        'avg_cost_per_participant': avgCostPerParticipant,
        'overall_roi': overallROI,
      };
    } catch (e) {
      debugPrint('Get advertiser dashboard summary error: $e');
      return {
        'active_campaigns': 0,
        'total_campaigns': 0,
        'total_spent': 0.0,
        'total_revenue': 0.0,
        'total_participants': 0,
        'avg_cost_per_participant': 0.0,
        'overall_roi': 0.0,
      };
    }
  }

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'total_impressions': 0,
      'total_clicks': 0,
      'total_participants': 0,
      'cost_per_participant': 0.0,
      'conversion_rate': 0.0,
      'engagement_rate': 0.0,
      'roi_percentage': 0.0,
      'total_revenue': 0.0,
      'total_spent': 0.0,
      'daily_analytics': [],
    };
  }

  Map<String, int> _getDefaultZoneReach() {
    return {
      'zone_1_us_canada': 0,
      'zone_2_western_europe': 0,
      'zone_3_eastern_europe_russia': 0,
      'zone_4_africa': 0,
      'zone_5_latin_america_caribbean': 0,
      'zone_6_middle_east_asia': 0,
      'zone_7_australasia_advanced_asia': 0,
      'zone_8_china_hong_kong_macau': 0,
    };
  }

  Map<String, dynamic> _getDefaultZoneConversions() {
    return {
      'zone_1_us_canada': 0,
      'zone_2_western_europe': 0,
      'zone_3_eastern_europe_russia': 0,
      'zone_4_africa': 0,
      'zone_5_latin_america_caribbean': 0,
      'zone_6_middle_east_asia': 0,
      'zone_7_australasia_advanced_asia': 0,
      'zone_8_china_hong_kong_macau': 0,
    };
  }
}
