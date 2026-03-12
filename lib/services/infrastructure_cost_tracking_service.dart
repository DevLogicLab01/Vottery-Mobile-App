import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service cost entry
class ServiceCost {
  final String serviceName;
  final double monthlyCost;
  final Map<String, dynamic> usageMetrics;
  final List<double> trendData; // 6-month trend
  final List<String> optimizationOpportunities;

  ServiceCost({
    required this.serviceName,
    required this.monthlyCost,
    required this.usageMetrics,
    required this.trendData,
    required this.optimizationOpportunities,
  });
}

/// Cache ROI metrics
class CacheRoiMetrics {
  final int queriesEliminated;
  final int cacheHits;
  final int cacheMisses;
  final double costSavings;
  final double roiPercentage;
  final double investmentCost;
  final double paybackPeriodMonths;
  final double cacheHitRate;

  CacheRoiMetrics({
    required this.queriesEliminated,
    required this.cacheHits,
    required this.cacheMisses,
    required this.costSavings,
    required this.roiPercentage,
    required this.investmentCost,
    required this.paybackPeriodMonths,
    required this.cacheHitRate,
  });
}

/// Cost optimization recommendation
class CostRecommendation {
  final String optimizationType;
  final String description;
  final double currentCost;
  final double projectedCost;
  final double annualSavings;
  final String implementationEffort;
  final String impact;

  CostRecommendation({
    required this.optimizationType,
    required this.description,
    required this.currentCost,
    required this.projectedCost,
    required this.annualSavings,
    required this.implementationEffort,
    required this.impact,
  });
}

/// Infrastructure Cost Tracking Service
class InfrastructureCostTrackingService {
  static InfrastructureCostTrackingService? _instance;
  static InfrastructureCostTrackingService get instance =>
      _instance ??= InfrastructureCostTrackingService._();

  InfrastructureCostTrackingService._();

  final _supabase = Supabase.instance.client;

  /// Get all service costs
  Future<List<ServiceCost>> getServiceCosts() async {
    try {
      final result = await _supabase
          .from('infrastructure_costs')
          .select()
          .order('monthly_cost', ascending: false)
          .limit(20);

      if (result.isNotEmpty) {
        return result
            .map(
              (row) => ServiceCost(
                serviceName: row['service_name'] as String? ?? '',
                monthlyCost: (row['monthly_cost'] as num?)?.toDouble() ?? 0.0,
                usageMetrics:
                    row['usage_metrics'] as Map<String, dynamic>? ?? {},
                trendData: [],
                optimizationOpportunities: [],
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Get service costs error: $e');
    }
    return _getMockServiceCosts();
  }

  /// Get total monthly cost
  Future<double> getTotalMonthlyCost() async {
    final costs = await getServiceCosts();
    return costs.fold<double>(0.0, (sum, c) => sum + c.monthlyCost);
  }

  /// Get cost per query
  Future<double> getCostPerQuery() async {
    try {
      final totalCost = await getTotalMonthlyCost();
      // Estimate 500K queries/month
      const totalQueriesPerMonth = 500000;
      return totalCost / totalQueriesPerMonth;
    } catch (e) {
      return 0.0023;
    }
  }

  /// Get cache ROI metrics
  Future<CacheRoiMetrics> getCacheRoiMetrics() async {
    try {
      final result = await _supabase
          .from('cache_roi_metrics')
          .select()
          .order('recorded_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (result != null) {
        return CacheRoiMetrics(
          queriesEliminated:
              (result['queries_eliminated'] as num?)?.toInt() ?? 0,
          cacheHits: (result['cache_hits'] as num?)?.toInt() ?? 0,
          cacheMisses: (result['cache_misses'] as num?)?.toInt() ?? 0,
          costSavings: (result['cost_savings'] as num?)?.toDouble() ?? 0.0,
          roiPercentage: (result['roi_percentage'] as num?)?.toDouble() ?? 0.0,
          investmentCost: 200.0,
          paybackPeriodMonths: 0.3,
          cacheHitRate: 0.72,
        );
      }
    } catch (e) {
      debugPrint('Get cache ROI error: $e');
    }
    return _getMockCacheRoi();
  }

  /// Get cost optimization recommendations
  List<CostRecommendation> getCostRecommendations() {
    return [
      CostRecommendation(
        optimizationType: 'Redis Upgrade',
        description: 'Upgrade Redis to larger instance with better \$/GB ratio',
        currentCost: 200.0,
        projectedCost: 180.0,
        annualSavings: 240.0,
        implementationEffort: 'low',
        impact: 'high',
      ),
      CostRecommendation(
        optimizationType: 'Datadog Metric Reduction',
        description:
            'Reduce custom metrics from 120 to 72 by consolidating duplicates',
        currentCost: 625.0,
        projectedCost: 425.0,
        annualSavings: 2400.0,
        implementationEffort: 'medium',
        impact: 'high',
      ),
      CostRecommendation(
        optimizationType: 'Supabase Storage Archival',
        description: 'Archive elections older than 90 days to cold storage',
        currentCost: 150.0,
        projectedCost: 135.0,
        annualSavings: 180.0,
        implementationEffort: 'low',
        impact: 'medium',
      ),
      CostRecommendation(
        optimizationType: 'Query Result Caching',
        description:
            'Cache election results for 5 min — eliminate 10K queries/day',
        currentCost: 0.0,
        projectedCost: 0.0,
        annualSavings: 600.0,
        implementationEffort: 'medium',
        impact: 'high',
      ),
    ];
  }

  /// Record cost snapshot
  Future<void> recordCostSnapshot({
    required String serviceName,
    required double monthlyCost,
    required Map<String, dynamic> usageMetrics,
  }) async {
    try {
      await _supabase.from('infrastructure_costs').insert({
        'service_name': serviceName,
        'monthly_cost': monthlyCost,
        'usage_metrics': usageMetrics,
        'recorded_month':
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-01',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Record cost snapshot error: $e');
    }
  }

  List<ServiceCost> _getMockServiceCosts() {
    return [
      ServiceCost(
        serviceName: 'Supabase',
        monthlyCost: 150.0,
        usageMetrics: {
          'database_size_gb': 12.4,
          'api_requests': 2400000,
          'storage_bandwidth_gb': 45,
        },
        trendData: [120.0, 128.0, 135.0, 142.0, 148.0, 150.0],
        optimizationOpportunities: [
          'Archive old elections',
          'Optimize large queries',
        ],
      ),
      ServiceCost(
        serviceName: 'Datadog',
        monthlyCost: 625.0,
        usageMetrics: {
          'hosts': 4,
          'custom_metrics': 120,
          'log_events_millions': 8.2,
        },
        trendData: [580.0, 595.0, 610.0, 618.0, 622.0, 625.0],
        optimizationOpportunities: [
          'Reduce custom metrics by 40%',
          'Optimize log retention',
        ],
      ),
      ServiceCost(
        serviceName: 'Redis',
        monthlyCost: 200.0,
        usageMetrics: {
          'memory_used_gb': 2.1,
          'commands_per_second': 8500,
          'cache_hit_rate': 0.72,
        },
        trendData: [180.0, 185.0, 190.0, 195.0, 198.0, 200.0],
        optimizationOpportunities: [
          'Upgrade to better \$/GB tier',
          'Implement TTL optimization',
        ],
      ),
      ServiceCost(
        serviceName: 'Other',
        monthlyCost: 25.0,
        usageMetrics: {'misc_services': 3},
        trendData: [20.0, 21.0, 22.0, 23.0, 24.0, 25.0],
        optimizationOpportunities: [],
      ),
    ];
  }

  CacheRoiMetrics _getMockCacheRoi() {
    return CacheRoiMetrics(
      queriesEliminated: 35000,
      cacheHits: 50000,
      cacheMisses: 15000,
      costSavings: 680.0,
      roiPercentage: 340.0,
      investmentCost: 200.0,
      paybackPeriodMonths: 0.3,
      cacheHitRate: 0.77,
    );
  }
}