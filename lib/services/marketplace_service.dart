import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './revenue_share_service.dart';

/// Service for creator marketplace operations
class MarketplaceService {
  static MarketplaceService? _instance;
  static MarketplaceService get instance =>
      _instance ??= MarketplaceService._();

  MarketplaceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  RevenueShareService get _revenueShare => RevenueShareService.instance;

  /// Get all marketplace services
  Future<List<Map<String, dynamic>>> getMarketplaceServices({
    String? serviceType,
    String? category,
    String? searchQuery,
    bool activeOnly = true,
  }) async {
    try {
      var query = _client
          .from('marketplace_services')
          .select('*, user_profiles!creator_id(full_name, avatar_url)');

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      if (serviceType != null) {
        query = query.eq('service_type', serviceType);
      }

      if (category != null) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$searchQuery%,description.ilike.%$searchQuery%',
        );
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get marketplace services error: $e');
      return [];
    }
  }

  /// Get creator's own services
  Future<List<Map<String, dynamic>>> getMyServices() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('marketplace_services')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get my services error: $e');
      return [];
    }
  }

  /// Create marketplace service
  Future<String?> createService({
    required String serviceType,
    required String title,
    required String description,
    required List<Map<String, dynamic>> priceTiers,
    required int deliveryTimeDays,
    String? category,
    List<String>? tags,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('marketplace_services')
          .insert({
            'creator_id': _auth.currentUser!.id,
            'service_type': serviceType,
            'title': title,
            'description': description,
            'price_tiers': priceTiers,
            'delivery_time_days': deliveryTimeDays,
            'category': category,
            'tags': tags ?? [],
            'is_active': true,
          })
          .select('id')
          .single();

      return response['id'] as String?;
    } catch (e) {
      debugPrint('Create service error: $e');
      return null;
    }
  }

  /// Update marketplace service
  Future<bool> updateService({
    required String serviceId,
    String? title,
    String? description,
    List<Map<String, dynamic>>? priceTiers,
    int? deliveryTimeDays,
    bool? isActive,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (priceTiers != null) updates['price_tiers'] = priceTiers;
      if (deliveryTimeDays != null) {
        updates['delivery_time_days'] = deliveryTimeDays;
      }
      if (isActive != null) updates['is_active'] = isActive;

      await _client
          .from('marketplace_services')
          .update(updates)
          .eq('id', serviceId)
          .eq('creator_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Update service error: $e');
      return false;
    }
  }

  /// Purchase marketplace service
  Future<String?> purchaseService({
    required String serviceId,
    required String tierSelected,
    required double amountPaid,
    required String countryCode,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Get service details
      final service = await _client
          .from('marketplace_services')
          .select('creator_id')
          .eq('id', serviceId)
          .single();

      final sellerId = service['creator_id'] as String;

      // Calculate revenue split
      final split = await _client.rpc(
        'calculate_marketplace_revenue_split',
        params: {'p_amount': amountPaid, 'p_country_code': countryCode},
      );

      final platformFee = split[0]['platform_fee'] as double;
      final creatorEarnings = split[0]['creator_earnings'] as double;

      // Create transaction
      final response = await _client
          .from('marketplace_transactions')
          .insert({
            'buyer_id': _auth.currentUser!.id,
            'seller_id': sellerId,
            'service_id': serviceId,
            'tier_selected': tierSelected,
            'amount_paid': amountPaid,
            'platform_fee': platformFee,
            'creator_earnings': creatorEarnings,
            'transaction_status': 'pending',
          })
          .select('id')
          .single();

      return response['id'] as String?;
    } catch (e) {
      debugPrint('Purchase service error: $e');
      return null;
    }
  }

  /// Get marketplace transactions (buyer or seller)
  Future<List<Map<String, dynamic>>> getTransactions({
    bool asBuyer = true,
    String? statusFilter,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client
          .from('marketplace_transactions')
          .select(
            '*, marketplace_services(title), user_profiles!seller_id(full_name)',
          );

      if (asBuyer) {
        query = query.eq('buyer_id', _auth.currentUser!.id);
      } else {
        query = query.eq('seller_id', _auth.currentUser!.id);
      }

      if (statusFilter != null) {
        query = query.eq('transaction_status', statusFilter);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get transactions error: $e');
      return [];
    }
  }

  /// Update transaction status
  Future<bool> updateTransactionStatus({
    required String transactionId,
    required String status,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('marketplace_transactions')
          .update({
            'transaction_status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      return true;
    } catch (e) {
      debugPrint('Update transaction status error: $e');
      return false;
    }
  }

  /// Submit review
  Future<bool> submitReview({
    required String transactionId,
    required String serviceId,
    required String sellerId,
    required int rating,
    String? reviewText,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('marketplace_reviews').insert({
        'transaction_id': transactionId,
        'service_id': serviceId,
        'buyer_id': _auth.currentUser!.id,
        'seller_id': sellerId,
        'rating': rating,
        'review_text': reviewText,
      });

      return true;
    } catch (e) {
      debugPrint('Submit review error: $e');
      return false;
    }
  }

  /// Get service reviews
  Future<List<Map<String, dynamic>>> getServiceReviews(String serviceId) async {
    try {
      final response = await _client
          .from('marketplace_reviews')
          .select('*, user_profiles:buyer_id(full_name, avatar_url)')
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get service reviews error: $e');
      return [];
    }
  }

  /// Get marketplace analytics
  Future<Map<String, dynamic>> getMarketplaceAnalytics() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultAnalytics();

      final response = await _client
          .from('marketplace_analytics')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('analysis_date', ascending: false)
          .limit(30);

      final analytics = List<Map<String, dynamic>>.from(response);

      if (analytics.isEmpty) return _getDefaultAnalytics();

      final totalRevenue = analytics.fold<double>(
        0.0,
        (sum, a) => sum + (a['total_revenue_usd'] ?? 0.0),
      );

      final totalOrders = analytics.fold<int>(
        0,
        (sum, a) => sum + ((a['total_orders'] ?? 0) as int),
      );

      return {
        'total_revenue': totalRevenue,
        'total_orders': totalOrders,
        'average_order_value': totalOrders > 0
            ? totalRevenue / totalOrders
            : 0.0,
        'daily_breakdown': analytics,
      };
    } catch (e) {
      debugPrint('Get marketplace analytics error: $e');
      return _getDefaultAnalytics();
    }
  }

  /// Track service view
  Future<void> trackServiceView({
    required String serviceId,
    required String viewType, // listing, detail, click
    String? sessionId,
    String? referrer,
    String? deviceType,
  }) async {
    try {
      await _client.from('marketplace_service_views').insert({
        'service_id': serviceId,
        'viewer_id': _auth.isAuthenticated ? _auth.currentUser!.id : null,
        'view_type': viewType,
        'session_id': sessionId,
        'referrer': referrer,
        'device_type': deviceType,
      });
    } catch (e) {
      debugPrint('Track service view error: $e');
    }
  }

  /// Get enhanced marketplace analytics with conversion rates
  Future<Map<String, dynamic>> getEnhancedMarketplaceAnalytics() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final results = await Future.wait([
        _getConversionMetrics(),
        _getBuyerDemographics(),
        _getDemandForecasts(),
        _getOptimizationRecommendations(),
        _getCompetitiveAnalysis(),
        _getABTests(),
      ]);

      return {
        'conversion_metrics': results[0],
        'buyer_demographics': results[1],
        'demand_forecasts': results[2],
        'optimization_recommendations': results[3],
        'competitive_analysis': results[4],
        'ab_tests': results[5],
      };
    } catch (e) {
      debugPrint('Get enhanced marketplace analytics error: $e');
      return {};
    }
  }

  /// Get conversion metrics for all creator services
  Future<List<Map<String, dynamic>>> _getConversionMetrics() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('marketplace_conversion_metrics')
          .select('*, marketplace_services!service_id(title)')
          .eq('creator_id', _auth.currentUser!.id)
          .order('analysis_date', ascending: false)
          .limit(30);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get conversion metrics error: $e');
      return [];
    }
  }

  /// Get buyer demographics
  Future<Map<String, dynamic>> _getBuyerDemographics() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final response = await _client
          .from('marketplace_buyer_demographics')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('analysis_date', ascending: false)
          .limit(1)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      debugPrint('Get buyer demographics error: $e');
      return {};
    }
  }

  /// Get demand forecasts
  Future<List<Map<String, dynamic>>> _getDemandForecasts() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('marketplace_demand_forecasts')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .order('forecast_date', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get demand forecasts error: $e');
      return [];
    }
  }

  /// Get optimization recommendations
  Future<List<Map<String, dynamic>>> _getOptimizationRecommendations() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('marketplace_optimization_recommendations')
          .select('*, marketplace_services!service_id(title)')
          .eq('creator_id', _auth.currentUser!.id)
          .eq('status', 'pending')
          .order('priority', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get optimization recommendations error: $e');
      return [];
    }
  }

  /// Get competitive analysis
  Future<List<Map<String, dynamic>>> _getCompetitiveAnalysis() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('marketplace_competitive_analysis')
          .select('*, marketplace_services!service_id(title)')
          .eq('creator_id', _auth.currentUser!.id)
          .order('analysis_date', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get competitive analysis error: $e');
      return [];
    }
  }

  /// Get A/B tests
  Future<List<Map<String, dynamic>>> _getABTests() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('marketplace_ab_tests')
          .select('*, marketplace_services!service_id(title)')
          .eq('creator_id', _auth.currentUser!.id)
          .order('started_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get A/B tests error: $e');
      return [];
    }
  }

  /// Apply optimization recommendation
  Future<bool> applyOptimizationRecommendation(String recommendationId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('marketplace_optimization_recommendations')
          .update({
            'status': 'applied',
            'applied_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recommendationId)
          .eq('creator_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Apply optimization recommendation error: $e');
      return false;
    }
  }

  /// Dismiss optimization recommendation
  Future<bool> dismissOptimizationRecommendation(
    String recommendationId,
  ) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('marketplace_optimization_recommendations')
          .update({'status': 'dismissed'})
          .eq('id', recommendationId)
          .eq('creator_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Dismiss optimization recommendation error: $e');
      return false;
    }
  }

  /// Export monthly performance report
  Future<Map<String, dynamic>> generateMonthlyPerformanceReport({
    required int year,
    required int month,
  }) async {
    try {
      if (!_auth.isAuthenticated) return {};

      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final results = await Future.wait([
        _getMonthlyRevenue(startDate, endDate),
        _getMonthlyTransactions(startDate, endDate),
        _getMonthlyConversionMetrics(startDate, endDate),
        _getMonthlyTopServices(startDate, endDate),
      ]);

      return {
        'period': '$year-${month.toString().padLeft(2, '0')}',
        'revenue': results[0],
        'transactions': results[1],
        'conversion_metrics': results[2],
        'top_services': results[3],
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Generate monthly performance report error: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getMonthlyRevenue(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client
          .from('marketplace_transactions')
          .select('creator_earnings')
          .eq('seller_id', _auth.currentUser!.id)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final total = response.fold<double>(
        0.0,
        (sum, t) => sum + (t['creator_earnings'] as num).toDouble(),
      );

      return {'total': total, 'count': response.length};
    } catch (e) {
      debugPrint('Get monthly revenue error: $e');
      return {'total': 0.0, 'count': 0};
    }
  }

  Future<List<Map<String, dynamic>>> _getMonthlyTransactions(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client
          .from('marketplace_transactions')
          .select('*, marketplace_services!service_id(title)')
          .eq('seller_id', _auth.currentUser!.id)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get monthly transactions error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _getMonthlyConversionMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client
          .from('marketplace_conversion_metrics')
          .select()
          .eq('creator_id', _auth.currentUser!.id)
          .gte('analysis_date', startDate.toIso8601String().split('T')[0])
          .lte('analysis_date', endDate.toIso8601String().split('T')[0]);

      if (response.isEmpty) return {};

      final avgConversionRate =
          response.fold<double>(
            0.0,
            (sum, m) => sum + (m['conversion_rate'] as num).toDouble(),
          ) /
          response.length;

      return {
        'average_conversion_rate': avgConversionRate,
        'metrics_count': response.length,
      };
    } catch (e) {
      debugPrint('Get monthly conversion metrics error: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getMonthlyTopServices(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client.rpc(
        'get_top_services_by_revenue',
        params: {
          'p_creator_id': _auth.currentUser!.id,
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
          'p_limit': 5,
        },
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get monthly top services error: $e');
      return [];
    }
  }

  Map<String, dynamic> _getDefaultAnalytics() {
    return {
      'total_revenue': 0.0,
      'total_orders': 0,
      'average_order_value': 0.0,
      'daily_breakdown': [],
    };
  }
}
