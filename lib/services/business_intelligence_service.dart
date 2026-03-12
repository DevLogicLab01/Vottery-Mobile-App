import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class BusinessIntelligenceService {
  static BusinessIntelligenceService? _instance;
  static BusinessIntelligenceService get instance =>
      _instance ??= BusinessIntelligenceService._();

  BusinessIntelligenceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get executive dashboard metrics
  Future<Map<String, dynamic>> getExecutiveDashboard() async {
    try {
      final response = await _client.rpc('get_executive_dashboard');
      return response ?? _getDefaultDashboard();
    } catch (e) {
      debugPrint('Get executive dashboard error: $e');
      return _getDefaultDashboard();
    }
  }

  /// Get revenue analytics
  Future<Map<String, dynamic>> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _client.rpc(
        'get_revenue_analytics',
        params: {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      );

      return response ?? _getDefaultRevenueAnalytics();
    } catch (e) {
      debugPrint('Get revenue analytics error: $e');
      return _getDefaultRevenueAnalytics();
    }
  }

  /// Get user intelligence metrics
  Future<Map<String, dynamic>> getUserIntelligence() async {
    try {
      final response = await _client.rpc('get_user_intelligence');
      return response ?? _getDefaultUserIntelligence();
    } catch (e) {
      debugPrint('Get user intelligence error: $e');
      return _getDefaultUserIntelligence();
    }
  }

  /// Get content performance metrics
  Future<Map<String, dynamic>> getContentPerformance() async {
    try {
      final response = await _client.rpc('get_content_performance_metrics');
      return response ?? _getDefaultContentPerformance();
    } catch (e) {
      debugPrint('Get content performance error: $e');
      return _getDefaultContentPerformance();
    }
  }

  /// Get predictive insights
  Future<Map<String, dynamic>> getPredictiveInsights() async {
    try {
      final response = await _client.rpc('get_predictive_insights');
      return response ?? _getDefaultPredictiveInsights();
    } catch (e) {
      debugPrint('Get predictive insights error: $e');
      return _getDefaultPredictiveInsights();
    }
  }

  /// Get growth forecasting
  Future<Map<String, dynamic>> getGrowthForecast({
    int forecastDays = 30,
  }) async {
    try {
      final response = await _client.rpc(
        'get_growth_forecast',
        params: {'forecast_days': forecastDays},
      );

      return response ?? _getDefaultGrowthForecast();
    } catch (e) {
      debugPrint('Get growth forecast error: $e');
      return _getDefaultGrowthForecast();
    }
  }

  /// Get market opportunity analysis
  Future<Map<String, dynamic>> getMarketOpportunities() async {
    try {
      final response = await _client.rpc('get_market_opportunities');
      return response ?? _getDefaultMarketOpportunities();
    } catch (e) {
      debugPrint('Get market opportunities error: $e');
      return _getDefaultMarketOpportunities();
    }
  }

  /// Get competitive intelligence
  Future<Map<String, dynamic>> getCompetitiveIntelligence() async {
    try {
      final response = await _client.rpc('get_competitive_intelligence');
      return response ?? _getDefaultCompetitiveIntelligence();
    } catch (e) {
      debugPrint('Get competitive intelligence error: $e');
      return _getDefaultCompetitiveIntelligence();
    }
  }

  /// Generate executive report
  Future<Map<String, dynamic>> generateExecutiveReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _client.rpc(
        'generate_executive_report',
        params: {
          'report_type': reportType,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      );

      return response ?? _getDefaultReport();
    } catch (e) {
      debugPrint('Generate executive report error: $e');
      return _getDefaultReport();
    }
  }

  /// Get KPI tracking
  Future<List<Map<String, dynamic>>> getKPITracking() async {
    try {
      final response = await _client
          .from('kpi_tracking')
          .select()
          .order('created_at', ascending: false)
          .limit(30);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get KPI tracking error: $e');
      return [];
    }
  }

  Map<String, dynamic> _getDefaultDashboard() {
    return {
      'total_revenue': 0.0,
      'monthly_revenue': 0.0,
      'revenue_growth': 0.0,
      'active_users': 0,
      'user_growth': 0.0,
      'engagement_rate': 0.0,
      'churn_rate': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultRevenueAnalytics() {
    return {
      'subscription_revenue': 0.0,
      'ad_revenue': 0.0,
      'creator_payouts': 0.0,
      'vp_purchases': 0.0,
      'revenue_by_tier': {},
    };
  }

  Map<String, dynamic> _getDefaultUserIntelligence() {
    return {
      'total_users': 0,
      'active_users': 0,
      'engagement_patterns': {},
      'churn_prediction': 0.0,
      'lifetime_value': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultContentPerformance() {
    return {
      'total_content': 0,
      'viral_content': 0,
      'voting_trends': {},
      'creator_success_metrics': {},
    };
  }

  Map<String, dynamic> _getDefaultPredictiveInsights() {
    return {
      'growth_forecast': 0.0,
      'churn_risk': 0.0,
      'revenue_forecast': 0.0,
      'market_opportunities': [],
    };
  }

  Map<String, dynamic> _getDefaultGrowthForecast() {
    return {
      'user_growth_forecast': [],
      'revenue_growth_forecast': [],
      'confidence_interval': 0.85,
    };
  }

  Map<String, dynamic> _getDefaultMarketOpportunities() {
    return {'opportunities': [], 'market_size': 0.0, 'addressable_market': 0.0};
  }

  Map<String, dynamic> _getDefaultCompetitiveIntelligence() {
    return {
      'market_position': 'unknown',
      'competitive_advantages': [],
      'threats': [],
    };
  }

  Map<String, dynamic> _getDefaultReport() {
    return {
      'report_type': 'executive_summary',
      'generated_at': DateTime.now().toIso8601String(),
      'summary': 'No data available',
      'metrics': {},
    };
  }
}
