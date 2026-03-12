import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// A/B Testing Service
/// Multi-variant experiment management with statistical significance tracking
class ABTestingService {
  static ABTestingService? _instance;
  static ABTestingService get instance => _instance ??= ABTestingService._();

  ABTestingService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Create new A/B test experiment
  Future<Map<String, dynamic>?> createExperiment({
    required String name,
    required String description,
    required String experimentType,
    required List<Map<String, dynamic>> variants,
    required DateTime startDate,
    required DateTime endDate,
    String? targetAudience,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final experiment = await _client
          .from('ab_test_experiments')
          .insert({
            'name': name,
            'description': description,
            'experiment_type': experimentType,
            'variants': variants,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'target_audience': targetAudience,
            'status': 'draft',
            'created_by': _auth.currentUser!.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return experiment;
    } catch (e) {
      debugPrint('Create experiment error: $e');
      return null;
    }
  }

  /// Get all experiments
  Future<List<Map<String, dynamic>>> getExperiments({String? status}) async {
    try {
      var query = _client
          .from('ab_test_experiments')
          .select('*, ab_test_results(count)');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get experiments error: $e');
      return [];
    }
  }

  /// Get experiment details with results
  Future<Map<String, dynamic>?> getExperimentDetails(
    String experimentId,
  ) async {
    try {
      final details = await _client
          .from('ab_test_experiments')
          .select('*, ab_test_results(*)')
          .eq('id', experimentId)
          .single();

      return details;
    } catch (e) {
      debugPrint('Get experiment details error: $e');
      return null;
    }
  }

  /// Assign user to experiment variant
  Future<String?> assignUserToVariant(String experimentId) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Check if user already assigned
      final existing = await _client
          .from('ab_test_assignments')
          .select()
          .eq('experiment_id', experimentId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      if (existing != null) {
        return existing['variant_id'];
      }

      // Get experiment variants
      final experiment = await _client
          .from('ab_test_experiments')
          .select()
          .eq('id', experimentId)
          .single();

      final variants = List<Map<String, dynamic>>.from(experiment['variants']);

      // Randomly assign variant (equal distribution)
      final random = math.Random();
      final selectedVariant = variants[random.nextInt(variants.length)];

      // Store assignment
      await _client.from('ab_test_assignments').insert({
        'experiment_id': experimentId,
        'user_id': _auth.currentUser!.id,
        'variant_id': selectedVariant['id'],
        'assigned_at': DateTime.now().toIso8601String(),
      });

      return selectedVariant['id'];
    } catch (e) {
      debugPrint('Assign user to variant error: $e');
      return null;
    }
  }

  /// Track experiment result
  Future<bool> trackResult({
    required String experimentId,
    required String variantId,
    required String eventType,
    Map<String, dynamic>? eventData,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('ab_test_results').insert({
        'experiment_id': experimentId,
        'variant_id': variantId,
        'user_id': _auth.currentUser!.id,
        'event_type': eventType,
        'event_data': eventData,
        'recorded_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Track result error: $e');
      return false;
    }
  }

  /// Calculate statistical significance
  Future<Map<String, dynamic>?> calculateStatisticalSignificance(
    String experimentId,
  ) async {
    try {
      // Get experiment results
      final results = await _client
          .from('ab_test_results')
          .select('variant_id, event_type')
          .eq('experiment_id', experimentId);

      if (results.isEmpty) return null;

      // Group by variant
      final variantStats = <String, Map<String, int>>{};
      for (var result in results) {
        final variantId = result['variant_id'];
        if (!variantStats.containsKey(variantId)) {
          variantStats[variantId] = {'total': 0, 'conversions': 0};
        }
        variantStats[variantId]!['total'] =
            variantStats[variantId]!['total']! + 1;
        if (result['event_type'] == 'conversion') {
          variantStats[variantId]!['conversions'] =
              variantStats[variantId]!['conversions']! + 1;
        }
      }

      // Calculate conversion rates
      final conversionRates = <String, double>{};
      for (var entry in variantStats.entries) {
        final total = entry.value['total']!;
        final conversions = entry.value['conversions']!;
        conversionRates[entry.key] = total > 0 ? conversions / total : 0.0;
      }

      // Chi-square test for statistical significance
      final variantIds = variantStats.keys.toList();
      if (variantIds.length < 2) return null;

      final controlId = variantIds[0];
      final variantId = variantIds[1];

      final controlTotal = variantStats[controlId]!['total']!;
      final controlConversions = variantStats[controlId]!['conversions']!;
      final variantTotal = variantStats[variantId]!['total']!;
      final variantConversions = variantStats[variantId]!['conversions']!;

      // Calculate chi-square statistic
      final totalSamples = controlTotal + variantTotal;
      final totalConversions = controlConversions + variantConversions;
      final expectedControlConversions =
          (controlTotal * totalConversions) / totalSamples;
      final expectedVariantConversions =
          (variantTotal * totalConversions) / totalSamples;

      final chiSquare =
          math.pow(controlConversions - expectedControlConversions, 2) /
              expectedControlConversions +
          math.pow(variantConversions - expectedVariantConversions, 2) /
              expectedVariantConversions;

      // Calculate p-value (simplified - use chi-square distribution)
      // For 1 degree of freedom, critical value at 95% confidence is 3.841
      final pValue = chiSquare > 3.841 ? 0.05 : 0.10;
      final isSignificant = pValue < 0.05;

      // Determine winner
      final controlRate = conversionRates[controlId]!;
      final variantRate = conversionRates[variantId]!;
      final winnerId = variantRate > controlRate ? variantId : controlId;
      final improvement = ((variantRate - controlRate) / controlRate * 100)
          .abs();

      return {
        'experiment_id': experimentId,
        'variant_stats': variantStats,
        'conversion_rates': conversionRates,
        'chi_square': chiSquare,
        'p_value': pValue,
        'is_significant': isSignificant,
        'confidence_level': isSignificant ? 95 : 90,
        'winner_id': winnerId,
        'improvement_percentage': improvement,
        'sample_size': totalSamples,
      };
    } catch (e) {
      debugPrint('Calculate statistical significance error: $e');
      return null;
    }
  }

  /// Promote winning variant
  Future<bool> promoteWinner(String experimentId, String winnerId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Update experiment status
      await _client
          .from('ab_test_experiments')
          .update({
            'status': 'completed',
            'winner_variant_id': winnerId,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', experimentId);

      // Log promotion event
      await _client.from('ab_test_events').insert({
        'experiment_id': experimentId,
        'event_type': 'winner_promoted',
        'event_data': {'winner_id': winnerId},
        'created_by': _auth.currentUser!.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Promote winner error: $e');
      return false;
    }
  }

  /// Export experiment report
  Future<Map<String, dynamic>?> exportReport(
    String experimentId,
    String format,
  ) async {
    try {
      final experiment = await _client
          .from('ab_test_experiments')
          .select()
          .eq('id', experimentId)
          .single();

      final stats = await calculateStatisticalSignificance(experimentId);

      final report = {
        'experiment': experiment,
        'statistics': stats,
        'format': format,
        'generated_at': DateTime.now().toIso8601String(),
      };

      return report;
    } catch (e) {
      debugPrint('Export report error: $e');
      return null;
    }
  }

  /// Calculate sample size needed
  int calculateSampleSize({
    required double baselineConversionRate,
    required double minimumDetectableEffect,
    double confidenceLevel = 0.95,
    double power = 0.80,
  }) {
    // Simplified sample size calculation
    // In production, use proper statistical formulas
    final zAlpha = 1.96; // 95% confidence
    final zBeta = 0.84; // 80% power

    final p1 = baselineConversionRate;
    final p2 = p1 * (1 + minimumDetectableEffect);
    final pBar = (p1 + p2) / 2;

    final numerator = math.pow(zAlpha + zBeta, 2) * 2 * pBar * (1 - pBar);
    final denominator = math.pow(p2 - p1, 2);

    return (numerator / denominator).ceil();
  }
}
