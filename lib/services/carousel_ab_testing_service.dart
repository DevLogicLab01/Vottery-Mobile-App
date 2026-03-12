import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import './supabase_service.dart';

/// Carousel A/B Testing Service
/// Manages experiment creation, variant assignment, and statistical analysis
class CarouselABTestingService {
  static CarouselABTestingService? _instance;
  static CarouselABTestingService get instance =>
      _instance ??= CarouselABTestingService._();

  CarouselABTestingService._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final Random _random = Random();

  // ============================================
  // EXPERIMENT MANAGEMENT
  // ============================================

  /// Create new A/B test experiment
  Future<Map<String, dynamic>> createExperiment({
    required String experimentName,
    required String experimentDescription,
    required String testType,
    required List<Map<String, dynamic>> variants,
    required List<String> successMetrics,
    required String primaryMetric,
    required int durationDays,
    int minimumSampleSize = 1000,
    double significanceThreshold = 0.95,
    bool autoPromote = false,
  }) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Validate traffic split totals 100%
      final totalTraffic = variants.fold<double>(
        0,
        (sum, v) => sum + (v['traffic_percentage'] as num).toDouble(),
      );
      if ((totalTraffic - 100.0).abs() > 0.01) {
        throw Exception('Traffic percentages must total 100%');
      }

      final response = await _supabaseService.client
          .from('carousel_experiments')
          .insert({
            'experiment_name': experimentName,
            'experiment_description': experimentDescription,
            'test_type': testType,
            'variants': variants,
            'success_metrics': successMetrics,
            'primary_metric': primaryMetric,
            'duration_days': durationDays,
            'minimum_sample_size': minimumSampleSize,
            'significance_threshold': significanceThreshold,
            'auto_promote': autoPromote,
            'status': 'draft',
            'created_by': userId,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Error creating experiment: $e');
      rethrow;
    }
  }

  /// Launch experiment
  Future<void> launchExperiment(String experimentId) async {
    try {
      await _supabaseService.client
          .from('carousel_experiments')
          .update({
            'status': 'running',
            'start_date': DateTime.now().toIso8601String(),
            'end_date': DateTime.now()
                .add(Duration(days: 30))
                .toIso8601String(), // Will be calculated from duration_days
          })
          .eq('experiment_id', experimentId);
    } catch (e) {
      debugPrint('Error launching experiment: $e');
      rethrow;
    }
  }

  /// Pause experiment
  Future<void> pauseExperiment(String experimentId) async {
    try {
      await _supabaseService.client
          .from('carousel_experiments')
          .update({'status': 'paused'})
          .eq('experiment_id', experimentId);
    } catch (e) {
      debugPrint('Error pausing experiment: $e');
      rethrow;
    }
  }

  /// Conclude experiment
  Future<void> concludeExperiment(
    String experimentId, {
    String? winningVariantId,
  }) async {
    try {
      await _supabaseService.client
          .from('carousel_experiments')
          .update({
            'status': 'concluded',
            'concluded_at': DateTime.now().toIso8601String(),
            if (winningVariantId != null)
              'winning_variant_id': winningVariantId,
          })
          .eq('experiment_id', experimentId);

      // If auto-promote enabled, apply winning configuration
      if (winningVariantId != null) {
        final experiment = await getExperiment(experimentId);
        if (experiment['auto_promote'] == true) {
          await _promoteWinner(experimentId, winningVariantId);
        }
      }
    } catch (e) {
      debugPrint('Error concluding experiment: $e');
      rethrow;
    }
  }

  /// Get experiment details
  Future<Map<String, dynamic>> getExperiment(String experimentId) async {
    try {
      final response = await _supabaseService.client
          .from('carousel_experiments')
          .select()
          .eq('experiment_id', experimentId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching experiment: $e');
      rethrow;
    }
  }

  /// Get all experiments
  Future<List<Map<String, dynamic>>> getExperiments({
    String? status,
    int limit = 50,
  }) async {
    try {
      var queryBuilder = _supabaseService.client
          .from('carousel_experiments')
          .select();

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status);
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching experiments: $e');
      return [];
    }
  }

  // ============================================
  // VARIANT ASSIGNMENT
  // ============================================

  /// Assign user to experiment variant
  Future<Map<String, dynamic>?> assignUserToVariant(
    String experimentId,
    String userId,
  ) async {
    try {
      // Check if user already assigned
      final existing = await _supabaseService.client
          .from('experiment_assignments')
          .select()
          .eq('experiment_id', experimentId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        return existing;
      }

      // Get experiment details
      final experiment = await getExperiment(experimentId);
      if (experiment['status'] != 'running') {
        return null;
      }

      // Select variant using weighted random
      final variants = List<Map<String, dynamic>>.from(experiment['variants']);
      final selectedVariant = _selectVariantWeighted(variants);

      // Create assignment
      final assignment = await _supabaseService.client
          .from('experiment_assignments')
          .insert({
            'experiment_id': experimentId,
            'user_id': userId,
            'variant_id': selectedVariant['variant_id'],
          })
          .select()
          .single();

      return assignment;
    } catch (e) {
      debugPrint('Error assigning user to variant: $e');
      return null;
    }
  }

  /// Get user's variant assignment
  Future<Map<String, dynamic>?> getUserVariant(
    String experimentId,
    String userId,
  ) async {
    try {
      final assignment = await _supabaseService.client
          .from('experiment_assignments')
          .select()
          .eq('experiment_id', experimentId)
          .eq('user_id', userId)
          .maybeSingle();

      return assignment;
    } catch (e) {
      debugPrint('Error fetching user variant: $e');
      return null;
    }
  }

  /// Select variant using weighted random distribution
  Map<String, dynamic> _selectVariantWeighted(
    List<Map<String, dynamic>> variants,
  ) {
    final randomValue = _random.nextDouble() * 100;
    double cumulativeWeight = 0;

    for (final variant in variants) {
      cumulativeWeight += (variant['traffic_percentage'] as num).toDouble();
      if (randomValue <= cumulativeWeight) {
        return variant;
      }
    }

    return variants.last;
  }

  // ============================================
  // METRICS COLLECTION
  // ============================================

  /// Get variant metrics
  Future<List<Map<String, dynamic>>> getVariantMetrics(
    String experimentId, {
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _supabaseService.client
          .from('experiment_variant_metrics')
          .select()
          .eq('experiment_id', experimentId)
          .gte('metric_date', startDate.toIso8601String())
          .order('metric_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching variant metrics: $e');
      return [];
    }
  }

  /// Calculate metrics for variant
  Future<void> calculateVariantMetrics(
    String experimentId,
    String variantId,
  ) async {
    try {
      final result = await _supabaseService.client.rpc(
        'calculate_experiment_metrics',
        params: {'exp_id': experimentId, 'var_id': variantId},
      );

      if (result != null && result.isNotEmpty) {
        final metrics = result[0];

        await _supabaseService.client
            .from('experiment_variant_metrics')
            .upsert({
              'experiment_id': experimentId,
              'variant_id': variantId,
              'metric_date': DateTime.now().toIso8601String().split('T')[0],
              'engagement_rate': metrics['engagement_rate'],
              'conversion_rate': metrics['conversion_rate'],
              'revenue_per_user': metrics['revenue_per_user'],
              'avg_session_duration': metrics['avg_session_duration'],
              'calculated_at': DateTime.now().toIso8601String(),
            });
      }
    } catch (e) {
      debugPrint('Error calculating variant metrics: $e');
    }
  }

  // ============================================
  // STATISTICAL ANALYSIS
  // ============================================

  /// Perform chi-square test for categorical metrics
  Future<Map<String, dynamic>> performChiSquareTest(
    String experimentId,
    String variantAId,
    String variantBId,
    String metricName,
  ) async {
    try {
      // Get metrics for both variants
      final metricsA = await _getLatestMetrics(experimentId, variantAId);
      final metricsB = await _getLatestMetrics(experimentId, variantBId);

      if (metricsA == null || metricsB == null) {
        throw Exception('Metrics not available for comparison');
      }

      // Calculate chi-square statistic
      final observedA = (metricsA['engaged_users'] as num).toDouble();
      final observedB = (metricsB['engaged_users'] as num).toDouble();
      final totalA = (metricsA['users_assigned'] as num).toDouble();
      final totalB = (metricsB['users_assigned'] as num).toDouble();

      final expectedA = (observedA + observedB) * totalA / (totalA + totalB);
      final expectedB = (observedA + observedB) * totalB / (totalA + totalB);

      final chiSquare =
          pow((observedA - expectedA), 2) / expectedA +
          pow((observedB - expectedB), 2) / expectedB;

      // Calculate p-value (simplified - degrees of freedom = 1)
      final pValue = _calculatePValue(chiSquare.toDouble(), 1);
      final isSignificant = pValue < 0.05;

      // Store result
      await _supabaseService.client
          .from('experiment_statistical_results')
          .insert({
            'experiment_id': experimentId,
            'variant_a_id': variantAId,
            'variant_b_id': variantBId,
            'metric_name': metricName,
            'test_type': 'chi_square',
            'test_statistic': chiSquare,
            'p_value': pValue,
            'confidence_level': 0.95,
            'is_significant': isSignificant,
          });

      return {
        'test_statistic': chiSquare,
        'p_value': pValue,
        'is_significant': isSignificant,
        'confidence_level': 0.95,
      };
    } catch (e) {
      debugPrint('Error performing chi-square test: $e');
      rethrow;
    }
  }

  /// Perform t-test for continuous metrics
  Future<Map<String, dynamic>> performTTest(
    String experimentId,
    String variantAId,
    String variantBId,
    String metricName,
  ) async {
    try {
      final metricsA = await _getLatestMetrics(experimentId, variantAId);
      final metricsB = await _getLatestMetrics(experimentId, variantBId);

      if (metricsA == null || metricsB == null) {
        throw Exception('Metrics not available for comparison');
      }

      // Get metric values
      final valueA = (metricsA[metricName] as num?)?.toDouble() ?? 0.0;
      final valueB = (metricsB[metricName] as num?)?.toDouble() ?? 0.0;
      final nA = (metricsA['users_assigned'] as num).toDouble();
      final nB = (metricsB['users_assigned'] as num).toDouble();

      // Calculate t-statistic (simplified)
      final meanDiff = valueA - valueB;
      final pooledStdDev = sqrt(
        (pow(valueA, 2) / nA + pow(valueB, 2) / nB) / 2,
      );
      final tStatistic = meanDiff / (pooledStdDev * sqrt(1 / nA + 1 / nB));

      // Calculate p-value
      final degreesOfFreedom = (nA + nB - 2).toInt();
      final pValue = _calculatePValue(tStatistic.abs(), degreesOfFreedom);
      final isSignificant = pValue < 0.05;

      // Calculate confidence interval
      final marginOfError = 1.96 * pooledStdDev * sqrt(1 / nA + 1 / nB);
      final ciLower = meanDiff - marginOfError;
      final ciUpper = meanDiff + marginOfError;

      // Store result
      await _supabaseService.client
          .from('experiment_statistical_results')
          .insert({
            'experiment_id': experimentId,
            'variant_a_id': variantAId,
            'variant_b_id': variantBId,
            'metric_name': metricName,
            'test_type': 't_test',
            'test_statistic': tStatistic,
            'p_value': pValue,
            'confidence_level': 0.95,
            'effect_size': meanDiff,
            'confidence_interval_lower': ciLower,
            'confidence_interval_upper': ciUpper,
            'is_significant': isSignificant,
          });

      return {
        'test_statistic': tStatistic,
        'p_value': pValue,
        'is_significant': isSignificant,
        'confidence_level': 0.95,
        'effect_size': meanDiff,
        'confidence_interval': [ciLower, ciUpper],
      };
    } catch (e) {
      debugPrint('Error performing t-test: $e');
      rethrow;
    }
  }

  /// Determine experiment winner
  Future<Map<String, dynamic>?> determineWinner(String experimentId) async {
    try {
      final experiment = await getExperiment(experimentId);
      final variants = List<Map<String, dynamic>>.from(experiment['variants']);
      final primaryMetric = experiment['primary_metric'] as String;

      // Get metrics for all variants
      final variantMetrics = <String, Map<String, dynamic>>{};
      for (final variant in variants) {
        final metrics = await _getLatestMetrics(
          experimentId,
          variant['variant_id'],
        );
        if (metrics != null) {
          variantMetrics[variant['variant_id']] = metrics;
        }
      }

      if (variantMetrics.isEmpty) return null;

      // Find best performing variant
      String? bestVariantId;
      double bestValue = -1;

      for (final entry in variantMetrics.entries) {
        final value = (entry.value[primaryMetric] as num?)?.toDouble() ?? 0.0;
        if (value > bestValue) {
          bestValue = value;
          bestVariantId = entry.key;
        }
      }

      if (bestVariantId == null) return null;

      // Check statistical significance against control (first variant)
      final controlVariantId = variants.first['variant_id'] as String;
      if (bestVariantId != controlVariantId) {
        final testResult = await performChiSquareTest(
          experimentId,
          controlVariantId,
          bestVariantId,
          primaryMetric,
        );

        if (testResult['is_significant'] != true) {
          return null; // No significant winner
        }
      }

      // Calculate lift
      final controlValue =
          (variantMetrics[controlVariantId]?[primaryMetric] as num?)
              ?.toDouble() ??
          0.0;
      final lift = controlValue > 0
          ? ((bestValue - controlValue) / controlValue * 100)
          : 0.0;

      return {
        'winning_variant_id': bestVariantId,
        'lift_percentage': lift,
        'primary_metric_value': bestValue,
        'is_significant': true,
      };
    } catch (e) {
      debugPrint('Error determining winner: $e');
      return null;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  Future<Map<String, dynamic>?> _getLatestMetrics(
    String experimentId,
    String variantId,
  ) async {
    try {
      final response = await _supabaseService.client
          .from('experiment_variant_metrics')
          .select()
          .eq('experiment_id', experimentId)
          .eq('variant_id', variantId)
          .order('metric_date', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching latest metrics: $e');
      return null;
    }
  }

  double _calculatePValue(double testStatistic, int degreesOfFreedom) {
    // Simplified p-value calculation
    // In production, use a proper statistical library
    final absT = testStatistic.abs();
    if (absT > 3.0) return 0.001;
    if (absT > 2.5) return 0.01;
    if (absT > 2.0) return 0.05;
    if (absT > 1.5) return 0.10;
    return 0.20;
  }

  Future<void> _promoteWinner(
    String experimentId,
    String winningVariantId,
  ) async {
    try {
      final experiment = await getExperiment(experimentId);
      final variants = List<Map<String, dynamic>>.from(experiment['variants']);
      final winningVariant = variants.firstWhere(
        (v) => v['variant_id'] == winningVariantId,
      );

      // Apply winning configuration to feed orchestration
      // This would integrate with FeedOrchestrationService
      debugPrint('Promoting winner: $winningVariantId');
      debugPrint('Configuration: ${winningVariant['configuration_json']}');

      // TODO: Apply configuration to production feed
    } catch (e) {
      debugPrint('Error promoting winner: $e');
    }
  }
}
