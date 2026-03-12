import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class CreatorEarningsService {
  static CreatorEarningsService? _instance;
  static CreatorEarningsService get instance =>
      _instance ??= CreatorEarningsService._();

  CreatorEarningsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // VP to USD conversion rate (100 VP = $1.00)
  static const double vpToUsdRate = 0.01;

  /// Get creator earnings summary
  Future<Map<String, dynamic>> getEarningsSummary() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultSummary();

      final response = await _client
          .from('creator_earnings_summary')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .maybeSingle();

      if (response == null) {
        return _getDefaultSummary();
      }

      return {
        'total_vp_earned': response['total_vp_earned'] ?? 0,
        'total_usd_earned': response['total_usd_earned'] ?? 0.0,
        'available_balance_vp': response['available_balance_vp'] ?? 0,
        'available_balance_usd': response['available_balance_usd'] ?? 0.0,
        'pending_balance_vp': response['pending_balance_vp'] ?? 0,
        'pending_balance_usd': response['pending_balance_usd'] ?? 0.0,
        'lifetime_payouts_usd': response['lifetime_payouts_usd'] ?? 0.0,
        'last_payout_date': response['last_payout_date'],
        'next_settlement_date': response['next_settlement_date'],
      };
    } catch (e) {
      debugPrint('Get earnings summary error: $e');
      return _getDefaultSummary();
    }
  }

  /// Stream real-time earnings summary updates
  Stream<Map<String, dynamic>> streamEarningsSummary() {
    if (!_auth.isAuthenticated) {
      return Stream.value(_getDefaultSummary());
    }

    return _client
        .from('creator_earnings_summary')
        .stream(primaryKey: ['id'])
        .eq('creator_id', _auth.currentUser!.id)
        .map((data) {
          if (data.isEmpty) return _getDefaultSummary();
          final record = data.first;
          return {
            'total_vp_earned': record['total_vp_earned'] ?? 0,
            'total_usd_earned': record['total_usd_earned'] ?? 0.0,
            'available_balance_vp': record['available_balance_vp'] ?? 0,
            'available_balance_usd': record['available_balance_usd'] ?? 0.0,
            'pending_balance_vp': record['pending_balance_vp'] ?? 0,
            'pending_balance_usd': record['pending_balance_usd'] ?? 0.0,
            'lifetime_payouts_usd': record['lifetime_payouts_usd'] ?? 0.0,
            'last_payout_date': record['last_payout_date'],
            'next_settlement_date': record['next_settlement_date'],
          };
        });
  }

  /// Get daily earnings breakdown (last N days)
  Future<List<Map<String, dynamic>>> getDailyEarnings({int days = 7}) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client.rpc(
        'get_creator_daily_earnings',
        params: {'p_creator_id': _auth.currentUser!.id, 'p_days': days},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get daily earnings error: $e');
      return [];
    }
  }

  /// Get weekly earnings breakdown
  Future<Map<String, dynamic>> getWeeklyEarnings() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultWeeklyEarnings();

      final dailyEarnings = await getDailyEarnings(days: 14);

      // Split into current week and previous week
      final currentWeek = dailyEarnings.take(7).toList();
      final previousWeek = dailyEarnings.skip(7).take(7).toList();

      final currentWeekTotal = currentWeek.fold<double>(
        0.0,
        (sum, day) => sum + (day['usd_earned'] ?? 0.0),
      );

      final previousWeekTotal = previousWeek.fold<double>(
        0.0,
        (sum, day) => sum + (day['usd_earned'] ?? 0.0),
      );

      final growthPercentage = previousWeekTotal > 0
          ? ((currentWeekTotal - previousWeekTotal) / previousWeekTotal) * 100
          : 0.0;

      return {
        'current_week_usd': currentWeekTotal,
        'previous_week_usd': previousWeekTotal,
        'growth_percentage': growthPercentage,
        'daily_breakdown': currentWeek,
      };
    } catch (e) {
      debugPrint('Get weekly earnings error: $e');
      return _getDefaultWeeklyEarnings();
    }
  }

  /// Get monthly earnings summary
  Future<Map<String, dynamic>> getMonthlyEarnings() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultMonthlyEarnings();

      final dailyEarnings = await getDailyEarnings(days: 30);

      final totalUsd = dailyEarnings.fold<double>(
        0.0,
        (sum, day) => sum + (day['usd_earned'] ?? 0.0),
      );

      final averagePerDay = dailyEarnings.isNotEmpty
          ? totalUsd / dailyEarnings.length
          : 0.0;

      return {
        'total_usd': totalUsd,
        'average_per_day': averagePerDay,
        'days_with_earnings': dailyEarnings.length,
        'daily_breakdown': dailyEarnings,
      };
    } catch (e) {
      debugPrint('Get monthly earnings error: $e');
      return _getDefaultMonthlyEarnings();
    }
  }

  /// Get settlement preview
  Future<Map<String, dynamic>> getSettlementPreview() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultSettlementPreview();

      final summary = await getEarningsSummary();
      final nextSettlementDate = await _calculateNextSettlementDate();

      return {
        'available_balance_vp': summary['available_balance_vp'],
        'available_balance_usd': summary['available_balance_usd'],
        'pending_balance_vp': summary['pending_balance_vp'],
        'pending_balance_usd': summary['pending_balance_usd'],
        'estimated_settlement_date': nextSettlementDate,
        'minimum_payout_threshold': 50.0,
        'can_withdraw': (summary['available_balance_usd'] ?? 0.0) >= 50.0,
      };
    } catch (e) {
      debugPrint('Get settlement preview error: $e');
      return _getDefaultSettlementPreview();
    }
  }

  /// Calculate next settlement date (weekly on Fridays)
  Future<String> _calculateNextSettlementDate() async {
    try {
      final response = await _client.rpc(
        'calculate_next_settlement_date',
        params: {'p_creator_id': _auth.currentUser!.id},
      );

      return response ??
          DateTime.now().add(Duration(days: 7)).toIso8601String();
    } catch (e) {
      debugPrint('Calculate next settlement date error: $e');
      return DateTime.now().add(Duration(days: 7)).toIso8601String();
    }
  }

  /// Get top performing elections by revenue
  Future<List<Map<String, dynamic>>> getTopElectionsByRevenue({
    int limit = 10,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client.rpc(
        'get_top_elections_by_revenue',
        params: {'p_creator_id': _auth.currentUser!.id, 'p_limit': limit},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get top elections by revenue error: $e');
      return [];
    }
  }

  /// Get VP transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    String? filterType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client
          .from('creator_earnings_transactions')
          .select('*, elections!source_election_id(title)')
          .eq('creator_id', _auth.currentUser!.id);

      if (filterType != null) {
        query = query.eq('transaction_type', filterType);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get transaction history error: $e');
      return [];
    }
  }

  /// Stream real-time transaction updates
  Stream<List<Map<String, dynamic>>> streamRecentTransactions({
    int limit = 10,
  }) {
    if (!_auth.isAuthenticated) {
      return Stream.value([]);
    }

    return _client
        .from('creator_earnings_transactions')
        .stream(primaryKey: ['id'])
        .eq('creator_id', _auth.currentUser!.id)
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Convert VP to USD
  double convertVpToUsd(int vpAmount) {
    return vpAmount * vpToUsdRate;
  }

  /// Convert USD to VP
  int convertUsdToVp(double usdAmount) {
    return (usdAmount / vpToUsdRate).round();
  }

  /// Get revenue breakdown by source
  Future<List<Map<String, dynamic>>> getRevenueBreakdown() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final summary = await getEarningsSummary();

      return [
        {
          'source': 'Election Fees',
          'amount': summary['election_fees'] ?? 0.0,
          'percentage': 0.0,
          'color': 'blue',
        },
        {
          'source': 'Marketplace',
          'amount': summary['marketplace_revenue'] ?? 0.0,
          'percentage': 0.0,
          'color': 'purple',
        },
        {
          'source': 'Partnerships',
          'amount': summary['partnership_revenue'] ?? 0.0,
          'percentage': 0.0,
          'color': 'orange',
        },
        {
          'source': 'Subscriptions',
          'amount': summary['subscription_revenue'] ?? 0.0,
          'percentage': 0.0,
          'color': 'green',
        },
      ];
    } catch (e) {
      debugPrint('Get revenue breakdown error: $e');
      return [];
    }
  }

  /// Get revenue forecast for next 30 days
  Future<Map<String, dynamic>> getRevenueForecast() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultForecast();

      final monthlyEarnings = await getMonthlyEarnings();
      final averagePerDay = monthlyEarnings['average_per_day'] ?? 0.0;

      final forecast30Days = averagePerDay * 30;
      final forecast60Days = averagePerDay * 60;
      final forecast90Days = averagePerDay * 90;

      return {
        '30_day_forecast': forecast30Days,
        '60_day_forecast': forecast60Days,
        '90_day_forecast': forecast90Days,
        'confidence_score': 0.75,
        'trend': 'growing',
      };
    } catch (e) {
      debugPrint('Get revenue forecast error: $e');
      return _getDefaultForecast();
    }
  }

  /// Enhanced revenue forecasting with seasonal modeling and churn probability
  Future<Map<String, dynamic>> getEnhancedRevenueForecasting() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultForecast();

      final historicalData = await getDailyEarnings(days: 90);
      final seasonalFactors = _calculateSeasonalFactors(historicalData);
      final churnProbability = await _calculateChurnProbability();

      final forecast30d = _forecastWithSeasonality(
        historicalData,
        30,
        seasonalFactors,
        churnProbability,
      );
      final forecast60d = _forecastWithSeasonality(
        historicalData,
        60,
        seasonalFactors,
        churnProbability,
      );
      final forecast90d = _forecastWithSeasonality(
        historicalData,
        90,
        seasonalFactors,
        churnProbability,
      );

      return {
        'forecast_30d': forecast30d,
        'forecast_60d': forecast60d,
        'forecast_90d': forecast90d,
        'seasonal_factors': seasonalFactors,
        'churn_probability': churnProbability,
        'confidence_level': _calculateConfidenceLevel(historicalData),
      };
    } catch (e) {
      debugPrint('Enhanced revenue forecasting error: $e');
      return _getDefaultForecast();
    }
  }

  /// Calculate seasonal factors from historical data
  Map<String, double> _calculateSeasonalFactors(
    List<Map<String, dynamic>> historicalData,
  ) {
    if (historicalData.isEmpty) return {'weekday': 1.0, 'weekend': 1.0};

    double weekdayAvg = 0.0;
    double weekendAvg = 0.0;
    int weekdayCount = 0;
    int weekendCount = 0;

    for (final day in historicalData) {
      final date = DateTime.parse(day['date']);
      final earnings = (day['usd_earned'] ?? 0.0) as double;

      if (date.weekday >= 6) {
        weekendAvg += earnings;
        weekendCount++;
      } else {
        weekdayAvg += earnings;
        weekdayCount++;
      }
    }

    weekdayAvg = weekdayCount > 0 ? weekdayAvg / weekdayCount : 0.0;
    weekendAvg = weekendCount > 0 ? weekendAvg / weekendCount : 0.0;

    final overallAvg = (weekdayAvg + weekendAvg) / 2;

    return {
      'weekday': overallAvg > 0 ? weekdayAvg / overallAvg : 1.0,
      'weekend': overallAvg > 0 ? weekendAvg / overallAvg : 1.0,
    };
  }

  /// Calculate churn probability based on engagement trends
  Future<double> _calculateChurnProbability() async {
    try {
      final recentEarnings = await getDailyEarnings(days: 30);
      if (recentEarnings.length < 7) return 0.0;

      final recentWeek = recentEarnings.take(7).toList();
      final previousWeek = recentEarnings.skip(7).take(7).toList();

      final recentAvg =
          recentWeek.fold<double>(
            0.0,
            (sum, day) => sum + (day['usd_earned'] ?? 0.0),
          ) /
          7;
      final previousAvg =
          previousWeek.fold<double>(
            0.0,
            (sum, day) => sum + (day['usd_earned'] ?? 0.0),
          ) /
          7;

      if (previousAvg == 0) return 0.0;

      final decline = (previousAvg - recentAvg) / previousAvg;
      final churnProbability = decline > 0
          ? (decline * 100).clamp(0.0, 100.0)
          : 0.0;

      return churnProbability;
    } catch (e) {
      debugPrint('Calculate churn probability error: $e');
      return 0.0;
    }
  }

  /// Forecast with seasonal modeling and churn adjustment
  Map<String, dynamic> _forecastWithSeasonality(
    List<Map<String, dynamic>> historicalData,
    int days,
    Map<String, double> seasonalFactors,
    double churnProbability,
  ) {
    if (historicalData.isEmpty) {
      return {
        'predicted_revenue': 0.0,
        'confidence_interval_low': 0.0,
        'confidence_interval_high': 0.0,
        'daily_breakdown': [],
      };
    }

    final recentData = historicalData.take(30).toList();
    final avgDailyEarnings =
        recentData.fold<double>(
          0.0,
          (sum, day) => sum + (day['usd_earned'] ?? 0.0),
        ) /
        recentData.length;

    // Apply churn adjustment
    final churnAdjustment = 1.0 - (churnProbability / 100);
    final adjustedAvg = avgDailyEarnings * churnAdjustment;

    double totalPredicted = 0.0;
    final dailyBreakdown = <Map<String, dynamic>>[];

    for (int i = 0; i < days; i++) {
      final futureDate = DateTime.now().add(Duration(days: i + 1));
      final isWeekend = futureDate.weekday >= 6;
      final seasonalFactor = isWeekend
          ? seasonalFactors['weekend']!
          : seasonalFactors['weekday']!;

      final dailyPrediction = adjustedAvg * seasonalFactor;
      totalPredicted += dailyPrediction;

      dailyBreakdown.add({
        'date': futureDate.toIso8601String().split('T')[0],
        'predicted_revenue': dailyPrediction,
        'seasonal_factor': seasonalFactor,
      });
    }

    // Calculate confidence intervals (±20% based on historical variance)
    final variance = _calculateVariance(recentData);
    final confidenceMargin = variance * 0.2;

    return {
      'predicted_revenue': totalPredicted,
      'confidence_interval_low': (totalPredicted - confidenceMargin).clamp(
        0.0,
        double.infinity,
      ),
      'confidence_interval_high': totalPredicted + confidenceMargin,
      'daily_breakdown': dailyBreakdown,
      'churn_adjusted': churnProbability > 0,
    };
  }

  /// Calculate variance for confidence intervals
  double _calculateVariance(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0.0;

    final mean =
        data.fold<double>(0.0, (sum, day) => sum + (day['usd_earned'] ?? 0.0)) /
        data.length;
    final variance =
        data.fold<double>(0.0, (sum, day) {
          final diff = (day['usd_earned'] ?? 0.0) - mean;
          return sum + (diff * diff);
        }) /
        data.length;

    return variance;
  }

  /// Calculate confidence level based on data quality
  double _calculateConfidenceLevel(List<Map<String, dynamic>> historicalData) {
    if (historicalData.isEmpty) return 0.0;
    if (historicalData.length < 30) return 0.5;
    if (historicalData.length < 60) return 0.75;
    return 0.9;
  }

  /// Export earnings report
  Future<void> exportEarningsReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.rpc(
        'export_earnings_report',
        params: {
          'p_creator_id': _auth.currentUser!.id,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Export earnings report error: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _getDefaultForecast() {
    return {
      'forecast_30d': {
        'predicted_revenue': 0.0,
        'confidence_interval_low': 0.0,
        'confidence_interval_high': 0.0,
        'daily_breakdown': [],
      },
      'forecast_60d': {
        'predicted_revenue': 0.0,
        'confidence_interval_low': 0.0,
        'confidence_interval_high': 0.0,
        'daily_breakdown': [],
      },
      'forecast_90d': {
        'predicted_revenue': 0.0,
        'confidence_interval_low': 0.0,
        'confidence_interval_high': 0.0,
        'daily_breakdown': [],
      },
      'seasonal_factors': {'weekday': 1.0, 'weekend': 1.0},
      'churn_probability': 0.0,
      'confidence_level': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultSummary() {
    return {
      'total_vp_earned': 0,
      'total_usd_earned': 0.0,
      'available_balance_vp': 0,
      'available_balance_usd': 0.0,
      'pending_balance_vp': 0,
      'pending_balance_usd': 0.0,
      'lifetime_payouts_usd': 0.0,
      'last_payout_date': null,
      'next_settlement_date': null,
    };
  }

  Map<String, dynamic> _getDefaultWeeklyEarnings() {
    return {
      'current_week_usd': 0.0,
      'previous_week_usd': 0.0,
      'growth_percentage': 0.0,
      'daily_breakdown': [],
    };
  }

  Map<String, dynamic> _getDefaultMonthlyEarnings() {
    return {
      'total_usd': 0.0,
      'average_per_day': 0.0,
      'days_with_earnings': 0,
      'daily_breakdown': [],
    };
  }

  Map<String, dynamic> _getDefaultSettlementPreview() {
    return {
      'available_balance_vp': 0,
      'available_balance_usd': 0.0,
      'pending_balance_vp': 0,
      'pending_balance_usd': 0.0,
      'estimated_settlement_date': DateTime.now()
          .add(Duration(days: 7))
          .toIso8601String(),
      'minimum_payout_threshold': 50.0,
      'can_withdraw': false,
    };
  }
}
