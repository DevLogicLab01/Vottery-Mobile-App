import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './vp_service.dart';

/// Service for prediction pools with Brier scoring system
class PredictionService {
  static PredictionService? _instance;
  static PredictionService get instance => _instance ??= PredictionService._();

  PredictionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  VPService get _vpService => VPService.instance;

  /// Get active prediction pools
  Future<List<Map<String, dynamic>>> getActivePools() async {
    try {
      final response = await _client
          .from('prediction_pools')
          .select('*, election:elections(*)')
          .eq('status', 'open')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active pools error: $e');
      return [];
    }
  }

  /// Enter prediction pool
  Future<bool> enterPredictionPool({
    required String poolId,
    required Map<String, dynamic> predictedOutcome,
    required double confidenceLevel,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get pool details
      final pool = await _client
          .from('prediction_pools')
          .select()
          .eq('id', poolId)
          .single();

      final entryFee = pool['entry_fee_vp'] as int;

      // Check VP balance
      final balance = await _vpService.getVPBalance();
      if (balance == null || balance['available_vp'] < entryFee) {
        throw Exception('Insufficient VP balance');
      }

      // Spend VP for entry
      await _vpService.spendVPPredictionEntry(poolId);

      // Create prediction
      await _client.from('predictions').insert({
        'pool_id': poolId,
        'user_id': _auth.currentUser!.id,
        'predicted_outcome': predictedOutcome,
        'confidence_level': confidenceLevel,
      });

      // Update pool stats
      await _client.rpc(
        'increment',
        params: {
          'table_name': 'prediction_pools',
          'row_id': poolId,
          'column_name': 'participant_count',
        },
      );

      await _client.rpc(
        'increment',
        params: {
          'table_name': 'prediction_pools',
          'row_id': poolId,
          'column_name': 'prize_pool_vp',
          'amount': entryFee,
        },
      );

      return true;
    } catch (e) {
      debugPrint('Enter prediction pool error: $e');
      return false;
    }
  }

  /// Calculate Brier Score
  double calculateBrierScore({
    required double predictedProbability,
    required int actualOutcome,
  }) {
    return pow(predictedProbability - actualOutcome, 2).toDouble();
  }

  /// Resolve prediction pool
  Future<bool> resolvePredictionPool({
    required String poolId,
    required Map<String, dynamic> actualOutcome,
  }) async {
    try {
      // Get all predictions for this pool
      final predictions = await _client
          .from('predictions')
          .select()
          .eq('pool_id', poolId);

      final pool = await _client
          .from('prediction_pools')
          .select()
          .eq('id', poolId)
          .single();

      final prizePool = pool['prize_pool_vp'] as int;

      // Calculate Brier scores and distribute rewards
      final List<Map<String, dynamic>> scoredPredictions = [];
      double totalInverseScore = 0;

      for (var prediction in predictions) {
        final predicted =
            prediction['predicted_outcome'] as Map<String, dynamic>;
        final confidence = prediction['confidence_level'] as double;

        // Simplified Brier score calculation
        final brierScore = calculateBrierScore(
          predictedProbability: confidence,
          actualOutcome: _compareOutcomes(predicted, actualOutcome) ? 1 : 0,
        );

        final inverseScore = 1 / (brierScore + 0.01);
        totalInverseScore += inverseScore;

        scoredPredictions.add({
          'prediction_id': prediction['id'],
          'user_id': prediction['user_id'],
          'brier_score': brierScore,
          'inverse_score': inverseScore,
        });

        // Update prediction with Brier score
        await _client
            .from('predictions')
            .update({'brier_score': brierScore})
            .eq('id', prediction['id']);
      }

      // Distribute rewards proportionally
      for (var scored in scoredPredictions) {
        final rewardShare = (scored['inverse_score'] / totalInverseScore);
        final vpReward = (prizePool * rewardShare).round();

        await _client
            .from('predictions')
            .update({'vp_reward': vpReward})
            .eq('id', scored['prediction_id']);

        // Award VP to user
        await _vpService.awardPredictionVP(vpReward, scored['prediction_id']);
      }

      // Update pool status
      await _client
          .from('prediction_pools')
          .update({
            'status': 'resolved',
            'actual_outcome': actualOutcome,
            'resolution_date': DateTime.now().toIso8601String(),
          })
          .eq('id', poolId);

      return true;
    } catch (e) {
      debugPrint('Resolve prediction pool error: $e');
      return false;
    }
  }

  /// Get user predictions
  Future<List<Map<String, dynamic>>> getUserPredictions() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('predictions')
          .select('*, pool:prediction_pools(*, election:elections(*))')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user predictions error: $e');
      return [];
    }
  }

  /// Get predictor rating
  Future<Map<String, dynamic>?> getPredictorRating() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('predictor_ratings')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get predictor rating error: $e');
      return null;
    }
  }

  bool _compareOutcomes(
    Map<String, dynamic> predicted,
    Map<String, dynamic> actual,
  ) {
    // Simplified outcome comparison
    return predicted.toString() == actual.toString();
  }
}
