import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './claude_service.dart';

/// Carousel ROI Analytics Service
/// Tracks revenue, sponsorship performance, creator payouts, and zone-specific analysis
class CarouselROIAnalyticsService {
  static CarouselROIAnalyticsService? _instance;
  static CarouselROIAnalyticsService get instance =>
      _instance ??= CarouselROIAnalyticsService._();

  CarouselROIAnalyticsService._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final ClaudeService _claudeService = ClaudeService.instance;

  // ============================================
  // REVENUE TRACKING
  // ============================================

  /// Get revenue by carousel type
  Future<Map<String, dynamic>> getRevenueByCarouselType({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('carousel_transactions')
          .select('carousel_type, transaction_type, amount')
          .gte('transaction_date', startDate.toIso8601String().split('T')[0]);

      if (response.isEmpty) {
        return _getDefaultRevenueData();
      }

      final data = response as List<dynamic>;
      final revenueByType = <String, Map<String, dynamic>>{};

      for (var transaction in data) {
        final carouselType = transaction['carousel_type'] as String;
        final transactionType = transaction['transaction_type'] as String;
        final amount = (transaction['amount'] as num).toDouble();

        if (!revenueByType.containsKey(carouselType)) {
          revenueByType[carouselType] = {
            'total_revenue': 0.0,
            'ad_revenue': 0.0,
            'sponsorship': 0.0,
            'creator_tips': 0.0,
            'premium_features': 0.0,
            'marketplace_commission': 0.0,
            'transaction_count': 0,
          };
        }

        revenueByType[carouselType]!['total_revenue'] =
            (revenueByType[carouselType]!['total_revenue'] as double) + amount;
        revenueByType[carouselType]![transactionType] =
            (revenueByType[carouselType]![transactionType] as double? ?? 0.0) +
            amount;
        revenueByType[carouselType]!['transaction_count'] =
            (revenueByType[carouselType]!['transaction_count'] as int) + 1;
      }

      return {
        'period_days': days,
        'total_revenue': data.fold<double>(
          0.0,
          (sum, t) => sum + (t['amount'] as num).toDouble(),
        ),
        'by_carousel_type': revenueByType,
      };
    } catch (e) {
      debugPrint('Error getting revenue by carousel type: $e');
      return _getDefaultRevenueData();
    }
  }

  Map<String, dynamic> _getDefaultRevenueData() {
    return {'period_days': 30, 'total_revenue': 0.0, 'by_carousel_type': {}};
  }

  /// Get revenue by content type
  Future<Map<String, dynamic>> getRevenueByContentType({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('carousel_transactions')
          .select('content_type, amount')
          .gte('transaction_date', startDate.toIso8601String().split('T')[0]);

      if (response.isEmpty) {
        return {'by_content_type': {}};
      }

      final data = response as List<dynamic>;
      final revenueByContent = <String, double>{};

      for (var transaction in data) {
        final contentType = transaction['content_type'] as String? ?? 'unknown';
        final amount = (transaction['amount'] as num).toDouble();
        revenueByContent[contentType] =
            (revenueByContent[contentType] ?? 0.0) + amount;
      }

      return {'by_content_type': revenueByContent};
    } catch (e) {
      debugPrint('Error getting revenue by content type: $e');
      return {'by_content_type': {}};
    }
  }

  // ============================================
  // SPONSORSHIP PERFORMANCE
  // ============================================

  /// Get sponsorship performance
  Future<List<Map<String, dynamic>>> getSponsorshipPerformance() async {
    try {
      final response = await _supabaseService.client
          .from('carousel_sponsorships')
          .select('*, user_profiles!sponsor_id(full_name)')
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      final data = response as List<dynamic>;
      final sponsorships = <Map<String, dynamic>>[];

      for (var sponsorship in data) {
        final investmentAmount = (sponsorship['investment_amount'] as num)
            .toDouble();
        final revenueGenerated = (sponsorship['revenue_generated'] as num)
            .toDouble();
        final roi = investmentAmount > 0
            ? ((revenueGenerated - investmentAmount) / investmentAmount * 100)
            : 0.0;

        sponsorships.add({
          'sponsorship_id': sponsorship['sponsorship_id'],
          'sponsor_name':
              sponsorship['user_profiles']?['full_name'] ?? 'Unknown',
          'carousel_type': sponsorship['carousel_type'],
          'investment_amount': investmentAmount,
          'impressions_delivered': sponsorship['impressions_delivered'] ?? 0,
          'clicks_generated': sponsorship['clicks_generated'] ?? 0,
          'conversions_achieved': sponsorship['conversions_achieved'] ?? 0,
          'revenue_generated': revenueGenerated,
          'roi': roi,
          'status': sponsorship['status'],
        });
      }

      return sponsorships;
    } catch (e) {
      debugPrint('Error getting sponsorship performance: $e');
      return [];
    }
  }

  // ============================================
  // CREATOR PAYOUTS
  // ============================================

  /// Get creator payouts by carousel
  Future<Map<String, dynamic>> getCreatorPayoutsByCarousel({
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('carousel_transactions')
          .select('carousel_type, creator_user_id, amount')
          .not('creator_user_id', 'is', null)
          .gte('transaction_date', startDate.toIso8601String().split('T')[0]);

      if (response.isEmpty) {
        return {'by_carousel': {}};
      }

      final data = response as List<dynamic>;
      final payoutsByCarousel = <String, Map<String, dynamic>>{};

      for (var transaction in data) {
        final carouselType = transaction['carousel_type'] as String;
        final amount = (transaction['amount'] as num).toDouble();

        if (!payoutsByCarousel.containsKey(carouselType)) {
          payoutsByCarousel[carouselType] = {
            'total_payout': 0.0,
            'creator_count': <String>{},
          };
        }

        payoutsByCarousel[carouselType]!['total_payout'] =
            (payoutsByCarousel[carouselType]!['total_payout'] as double) +
            amount;
        (payoutsByCarousel[carouselType]!['creator_count'] as Set<String>).add(
          transaction['creator_user_id'] as String,
        );
      }

      final result = <String, Map<String, dynamic>>{};
      for (var entry in payoutsByCarousel.entries) {
        final creatorCount =
            (entry.value['creator_count'] as Set<String>).length;
        result[entry.key] = {
          'total_payout': entry.value['total_payout'],
          'creator_count': creatorCount,
          'avg_payout_per_creator': creatorCount > 0
              ? (entry.value['total_payout'] as double) / creatorCount
              : 0.0,
        };
      }

      return {'by_carousel': result};
    } catch (e) {
      debugPrint('Error getting creator payouts by carousel: $e');
      return {'by_carousel': {}};
    }
  }

  /// Get top earning creators
  Future<List<Map<String, dynamic>>> getTopEarningCreators({
    int limit = 10,
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('carousel_transactions')
          .select(
            'creator_user_id, amount, user_profiles!creator_user_id(full_name)',
          )
          .not('creator_user_id', 'is', null)
          .gte('transaction_date', startDate.toIso8601String().split('T')[0]);

      if (response.isEmpty) {
        return [];
      }

      final data = response as List<dynamic>;
      final creatorEarnings = <String, Map<String, dynamic>>{};

      for (var transaction in data) {
        final creatorId = transaction['creator_user_id'] as String;
        final amount = (transaction['amount'] as num).toDouble();
        final creatorName =
            transaction['user_profiles']?['full_name'] ?? 'Unknown';

        if (!creatorEarnings.containsKey(creatorId)) {
          creatorEarnings[creatorId] = {
            'creator_id': creatorId,
            'creator_name': creatorName,
            'total_earnings': 0.0,
          };
        }

        creatorEarnings[creatorId]!['total_earnings'] =
            (creatorEarnings[creatorId]!['total_earnings'] as double) + amount;
      }

      final sortedCreators = creatorEarnings.values.toList()
        ..sort(
          (a, b) => (b['total_earnings'] as double).compareTo(
            a['total_earnings'] as double,
          ),
        );

      return sortedCreators.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting top earning creators: $e');
      return [];
    }
  }

  // ============================================
  // ZONE-SPECIFIC ANALYSIS
  // ============================================

  /// Get revenue by purchasing power zone
  Future<Map<String, dynamic>> getRevenueByZone({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('carousel_transactions')
          .select('purchasing_power_zone, amount, user_id')
          .not('purchasing_power_zone', 'is', null)
          .gte('transaction_date', startDate.toIso8601String().split('T')[0]);

      if (response.isEmpty) {
        return {'by_zone': {}};
      }

      final data = response as List<dynamic>;
      final zoneData = <String, Map<String, dynamic>>{};

      for (var transaction in data) {
        final zone = transaction['purchasing_power_zone'] as String;
        final amount = (transaction['amount'] as num).toDouble();
        final userId = transaction['user_id'] as String?;

        if (!zoneData.containsKey(zone)) {
          zoneData[zone] = {
            'total_revenue': 0.0,
            'transaction_count': 0,
            'unique_users': <String>{},
          };
        }

        zoneData[zone]!['total_revenue'] =
            (zoneData[zone]!['total_revenue'] as double) + amount;
        zoneData[zone]!['transaction_count'] =
            (zoneData[zone]!['transaction_count'] as int) + 1;
        if (userId != null) {
          (zoneData[zone]!['unique_users'] as Set<String>).add(userId);
        }
      }

      final result = <String, Map<String, dynamic>>{};
      for (var entry in zoneData.entries) {
        final userCount = (entry.value['unique_users'] as Set<String>).length;
        result[entry.key] = {
          'total_revenue': entry.value['total_revenue'],
          'transaction_count': entry.value['transaction_count'],
          'user_count': userCount,
          'arpu': userCount > 0
              ? (entry.value['total_revenue'] as double) / userCount
              : 0.0,
        };
      }

      return {'by_zone': result};
    } catch (e) {
      debugPrint('Error getting revenue by zone: $e');
      return {'by_zone': {}};
    }
  }

  /// Get zone optimization recommendations from Claude
  Future<Map<String, dynamic>> getZoneOptimizationRecommendations({
    required Map<String, dynamic> zoneData,
  }) async {
    try {
      final prompt =
          '''
Analyze these purchasing power zone metrics and provide optimization recommendations:

${zoneData.entries.map((e) => '${e.key}: Revenue \$${e.value['total_revenue']}, ARPU \$${e.value['arpu']}, Users ${e.value['user_count']}').join('\n')}

Provide recommendations in JSON format:
{
  "high_potential_zones": ["zone1", "zone2"],
  "recommendations": [
    {
      "zone": "zone_name",
      "strategy": "strategy_description",
      "expected_impact": "high|medium|low"
    }
  ]
}
''';

      final response = await _claudeService.callClaudeAPI(prompt);
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error getting zone optimization recommendations: $e');
      return {'high_potential_zones': [], 'recommendations': []};
    }
  }

  // ============================================
  // REVENUE FORECASTING
  // ============================================

  /// Generate revenue forecast using OpenAI
  Future<Map<String, dynamic>> generateRevenueForecast({
    required String carouselType,
    required String forecastPeriod,
    int historicalDays = 90,
  }) async {
    try {
      final historicalData = await getRevenueByCarouselType(
        days: historicalDays,
      );
      final carouselRevenue =
          (historicalData['by_carousel_type']
              as Map<String, dynamic>)[carouselType];

      if (carouselRevenue == null) {
        return _getDefaultForecast();
      }

      // Mock forecast for now (OpenAI integration would go here)
      final totalRevenue = (carouselRevenue['total_revenue'] as double);
      final dailyAvg = totalRevenue / historicalDays;
      final forecastDays = forecastPeriod == '30_days'
          ? 30
          : (forecastPeriod == '90_days' ? 90 : 365);
      final predictedRevenue = dailyAvg * forecastDays;

      final forecastData = {
        'carousel_type': carouselType,
        'forecast_period': forecastPeriod,
        'predicted_revenue': predictedRevenue,
        'confidence_interval_lower': predictedRevenue * 0.85,
        'confidence_interval_upper': predictedRevenue * 1.15,
        'confidence_level': 0.85,
        'forecasting_model': 'linear_trend',
      };

      await _supabaseService.client
          .from('carousel_revenue_forecasts')
          .insert(forecastData);

      return forecastData;
    } catch (e) {
      debugPrint('Error generating revenue forecast: $e');
      return _getDefaultForecast();
    }
  }

  Map<String, dynamic> _getDefaultForecast() {
    return {
      'carousel_type': 'unknown',
      'forecast_period': '30_days',
      'predicted_revenue': 0.0,
      'confidence_interval_lower': 0.0,
      'confidence_interval_upper': 0.0,
      'confidence_level': 0.0,
      'forecasting_model': 'none',
    };
  }

  /// Get profitability analysis
  Future<Map<String, dynamic>> getProfitabilityAnalysis({int days = 30}) async {
    try {
      final revenueData = await getRevenueByCarouselType(days: days);
      final totalRevenue = revenueData['total_revenue'] as double;

      // Mock cost data (would come from infrastructure metrics in real implementation)
      final estimatedCosts = totalRevenue * 0.35; // 35% cost estimate
      final profit = totalRevenue - estimatedCosts;
      final profitMargin = totalRevenue > 0
          ? (profit / totalRevenue * 100)
          : 0.0;

      return {
        'period_days': days,
        'total_revenue': totalRevenue,
        'estimated_costs': estimatedCosts,
        'profit': profit,
        'profit_margin': profitMargin,
      };
    } catch (e) {
      debugPrint('Error getting profitability analysis: $e');
      return {
        'period_days': days,
        'total_revenue': 0.0,
        'estimated_costs': 0.0,
        'profit': 0.0,
        'profit_margin': 0.0,
      };
    }
  }
}