import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './claude_service.dart';

class RevenueShareService {
  static RevenueShareService? _instance;
  static RevenueShareService get instance =>
      _instance ??= RevenueShareService._();

  RevenueShareService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  ClaudeService get _claude => ClaudeService.instance;

  /// Get all country revenue splits
  Future<List<Map<String, dynamic>>> getAllRevenueSplits() async {
    try {
      final response = await _client
          .from('creator_revenue_splits')
          .select()
          .order('country_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all revenue splits error: $e');
      return [];
    }
  }

  /// Update revenue split for country
  Future<bool> updateRevenueSplit({
    required String countryCode,
    required double platformPercentage,
    required double creatorPercentage,
    String? changeReason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Validate split totals 100%
      if ((platformPercentage + creatorPercentage) != 100.0) {
        throw Exception('Split percentages must total 100%');
      }

      await _client
          .from('creator_revenue_splits')
          .update({
            'platform_percentage': platformPercentage,
            'creator_percentage': creatorPercentage,
            'updated_by': _auth.currentUser!.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('country_code', countryCode);

      return true;
    } catch (e) {
      debugPrint('Update revenue split error: $e');
      return false;
    }
  }

  /// Bulk update revenue splits by region
  Future<bool> bulkUpdateByRegion({
    required List<String> countryCodes,
    required double platformPercentage,
    required double creatorPercentage,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      for (final countryCode in countryCodes) {
        await updateRevenueSplit(
          countryCode: countryCode,
          platformPercentage: platformPercentage,
          creatorPercentage: creatorPercentage,
          changeReason: 'Bulk regional update',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Bulk update by region error: $e');
      return false;
    }
  }

  /// Apply preset template
  Future<bool> applyPresetTemplate({
    required String templateName,
    required List<String> countryCodes,
  }) async {
    try {
      final Map<String, Map<String, double>> templates = {
        'Standard 70/30': {'platform': 30.0, 'creator': 70.0},
        'Premium Markets 60/40': {'platform': 40.0, 'creator': 60.0},
        'Emerging Markets 75/25': {'platform': 25.0, 'creator': 75.0},
        'High Growth 80/20': {'platform': 20.0, 'creator': 80.0},
      };

      final template = templates[templateName];
      if (template == null) return false;

      return await bulkUpdateByRegion(
        countryCodes: countryCodes,
        platformPercentage: template['platform']!,
        creatorPercentage: template['creator']!,
      );
    } catch (e) {
      debugPrint('Apply preset template error: $e');
      return false;
    }
  }

  /// Get revenue split history for country
  Future<List<Map<String, dynamic>>> getRevenueSplitHistory({
    required String countryCode,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('revenue_split_history')
          .select('*, user_profiles!updated_by(full_name)')
          .eq('country_code', countryCode)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get revenue split history error: $e');
      return [];
    }
  }

  /// Get regional revenue analytics
  Future<List<Map<String, dynamic>>> getRegionalRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final response = await _client.rpc(
        'get_regional_revenue_summary',
        params: {
          'p_start_date': start.toIso8601String().split('T')[0],
          'p_end_date': end.toIso8601String().split('T')[0],
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get regional revenue analytics error: $e');
      return [];
    }
  }

  /// Get split effectiveness metrics
  Future<Map<String, dynamic>> getSplitEffectivenessMetrics() async {
    try {
      final analytics = await getRegionalRevenueAnalytics();

      final totalCountries = analytics.length;
      final avgPlatformPercentage = analytics.isEmpty
          ? 0.0
          : analytics
                    .map((a) => a['platform_earnings'] as num? ?? 0)
                    .reduce((a, b) => a + b) /
                analytics
                    .map((a) => a['total_revenue'] as num? ?? 1)
                    .reduce((a, b) => a + b) *
                100;

      final pendingChanges = await _client
          .from('revenue_split_history')
          .select('id')
          .gte(
            'created_at',
            DateTime.now().subtract(Duration(hours: 24)).toIso8601String(),
          );

      return {
        'total_countries_configured': totalCountries,
        'average_platform_percentage': avgPlatformPercentage,
        'pending_split_changes': (pendingChanges as List).length,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Get split effectiveness metrics error: $e');
      return {
        'total_countries_configured': 0,
        'average_platform_percentage': 0.0,
        'pending_split_changes': 0,
      };
    }
  }

  /// Get Claude AI split recommendations
  Future<Map<String, dynamic>> getAISplitRecommendation({
    required String countryCode,
  }) async {
    try {
      // Check cache first
      final cached = await _client
          .from('split_recommendation_cache')
          .select()
          .eq('country_code', countryCode)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (cached != null) {
        return {
          'country_code': countryCode,
          'recommended_platform_percentage':
              cached['recommended_platform_percentage'],
          'recommended_creator_percentage':
              cached['recommended_creator_percentage'],
          'confidence_score': cached['confidence_score'],
          'reasoning': cached['reasoning'],
          'cached': true,
        };
      }

      // Get analytics data for country
      final analytics = await _client
          .from('regional_revenue_analytics')
          .select()
          .eq('country_code', countryCode)
          .order('analysis_date', ascending: false)
          .limit(30);

      // Call Claude for recommendation
      final prompt =
          '''
Analyze creator revenue split optimization for country: $countryCode

Historical Data:
${analytics.map((a) => 'Date: ${a['analysis_date']}, Revenue: \$${a['total_revenue_usd']}, Creators: ${a['total_creators']}, Satisfaction: ${a['creator_satisfaction_score']}').join('\n')}

Provide:
1. Recommended platform/creator split percentages (must total 100%)
2. Confidence score (0-100)
3. Brief reasoning (max 200 words)

Format response as JSON:
{
  "recommended_platform_percentage": 30.0,
  "recommended_creator_percentage": 70.0,
  "confidence_score": 85.0,
  "reasoning": "..."
}
''';

      final response = await _claude.analyzeRevenueRisk(
        revenueData: {'country_code': countryCode, 'analytics': analytics},
      );

      // Cache recommendation
      await _client.from('split_recommendation_cache').insert({
        'country_code': countryCode,
        'recommended_platform_percentage':
            response['recommended_platform_percentage'],
        'recommended_creator_percentage':
            response['recommended_creator_percentage'],
        'confidence_score': response['confidence_score'],
        'reasoning': response['reasoning'],
        'data_analyzed': {'analytics_count': analytics.length},
      });

      return {...response, 'cached': false};
    } catch (e) {
      debugPrint('Get AI split recommendation error: $e');
      return {
        'recommended_platform_percentage': 30.0,
        'recommended_creator_percentage': 70.0,
        'confidence_score': 0.0,
        'reasoning': 'Unable to generate recommendation',
      };
    }
  }

  /// Stream revenue splits for real-time updates
  Stream<List<Map<String, dynamic>>> streamRevenueSplits() {
    return _client
        .from('creator_revenue_splits')
        .stream(primaryKey: ['id'])
        .order('country_name', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
