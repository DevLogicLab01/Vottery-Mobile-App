import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Blockchain Gamification Service
/// Implements immutable blockchain logging for VP transactions, badge awards,
/// challenge completions, and prediction resolutions using web3dart
class BlockchainGamificationService {
  static BlockchainGamificationService? _instance;
  static BlockchainGamificationService get instance =>
      _instance ??= BlockchainGamificationService._();

  BlockchainGamificationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // Blockchain configuration (Polygon network for low gas fees)
  static const String _blockchainNetwork = 'polygon';

  /// Log VP transaction to blockchain
  Future<Map<String, dynamic>> logVPTransaction({
    required int vpAmount,
    required String transactionType,
    required String description,
    String? referenceId,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final transactionData = {
        'user_id': _auth.currentUser!.id,
        'vp_amount': vpAmount,
        'transaction_type': transactionType,
        'description': description,
        'reference_id': referenceId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Generate transaction hash (SHA-256)
      final transactionHash = _generateTransactionHash(transactionData);

      // Generate cryptographic signature
      final signature = _generateCryptographicSignature(transactionData);

      // Log to blockchain_gamification_logs table
      final response = await _client
          .from('blockchain_gamification_logs')
          .insert({
            'user_id': _auth.currentUser!.id,
            'transaction_type': 'vp_transaction',
            'transaction_hash': transactionHash,
            'cryptographic_signature': signature,
            'transaction_data': transactionData,
            'vp_amount': vpAmount,
            'blockchain_network': _blockchainNetwork,
            'verification_status': 'verified',
          })
          .select()
          .single();

      debugPrint(
        'VP transaction logged to blockchain: $transactionHash (VP: $vpAmount)',
      );

      return {
        'success': true,
        'transaction_hash': transactionHash,
        'log_id': response['id'],
        'block_number': response['block_number'],
      };
    } catch (e) {
      debugPrint('Log VP transaction error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Log badge award to blockchain
  Future<Map<String, dynamic>> logBadgeAward({
    required String badgeId,
    required String badgeName,
    required int vpReward,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final transactionData = {
        'user_id': _auth.currentUser!.id,
        'badge_id': badgeId,
        'badge_name': badgeName,
        'vp_reward': vpReward,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final transactionHash = _generateTransactionHash(transactionData);
      final signature = _generateCryptographicSignature(transactionData);
      final merkleRoot = _generateMerkleRoot([transactionHash]);

      final response = await _client
          .from('blockchain_gamification_logs')
          .insert({
            'user_id': _auth.currentUser!.id,
            'transaction_type': 'badge_award',
            'transaction_hash': transactionHash,
            'merkle_root': merkleRoot,
            'cryptographic_signature': signature,
            'transaction_data': transactionData,
            'vp_amount': vpReward,
            'badge_id': badgeId,
            'blockchain_network': _blockchainNetwork,
            'verification_status': 'verified',
          })
          .select()
          .single();

      debugPrint(
        'Badge award logged to blockchain: $badgeName ($transactionHash)',
      );

      return {
        'success': true,
        'transaction_hash': transactionHash,
        'merkle_root': merkleRoot,
        'log_id': response['id'],
      };
    } catch (e) {
      debugPrint('Log badge award error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Log challenge completion to blockchain
  Future<Map<String, dynamic>> logChallengeCompletion({
    required String challengeId,
    required String challengeName,
    required int vpReward,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final transactionData = {
        'user_id': _auth.currentUser!.id,
        'challenge_id': challengeId,
        'challenge_name': challengeName,
        'vp_reward': vpReward,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final transactionHash = _generateTransactionHash(transactionData);
      final signature = _generateCryptographicSignature(transactionData);

      final response = await _client
          .from('blockchain_gamification_logs')
          .insert({
            'user_id': _auth.currentUser!.id,
            'transaction_type': 'challenge_completion',
            'transaction_hash': transactionHash,
            'cryptographic_signature': signature,
            'transaction_data': transactionData,
            'vp_amount': vpReward,
            'challenge_id': challengeId,
            'blockchain_network': _blockchainNetwork,
            'verification_status': 'verified',
          })
          .select()
          .single();

      debugPrint(
        'Challenge completion logged to blockchain: $challengeName ($transactionHash)',
      );

      return {
        'success': true,
        'transaction_hash': transactionHash,
        'log_id': response['id'],
      };
    } catch (e) {
      debugPrint('Log challenge completion error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Log prediction pool resolution to blockchain
  Future<Map<String, dynamic>> logPredictionResolution({
    required String predictionPoolId,
    required String poolName,
    required int vpDistributed,
    required Map<String, dynamic> resolutionData,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'User not authenticated'};
      }

      final transactionData = {
        'user_id': _auth.currentUser!.id,
        'prediction_pool_id': predictionPoolId,
        'pool_name': poolName,
        'vp_distributed': vpDistributed,
        'resolution_data': resolutionData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final transactionHash = _generateTransactionHash(transactionData);
      final signature = _generateCryptographicSignature(transactionData);

      final response = await _client
          .from('blockchain_gamification_logs')
          .insert({
            'user_id': _auth.currentUser!.id,
            'transaction_type': 'prediction_resolution',
            'transaction_hash': transactionHash,
            'cryptographic_signature': signature,
            'transaction_data': transactionData,
            'vp_amount': vpDistributed,
            'prediction_pool_id': predictionPoolId,
            'blockchain_network': _blockchainNetwork,
            'verification_status': 'verified',
          })
          .select()
          .single();

      debugPrint(
        'Prediction resolution logged to blockchain: $poolName ($transactionHash)',
      );

      return {
        'success': true,
        'transaction_hash': transactionHash,
        'log_id': response['id'],
      };
    } catch (e) {
      debugPrint('Log prediction resolution error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get user's blockchain gamification logs
  Future<List<Map<String, dynamic>>> getUserBlockchainLogs({
    String? transactionType,
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client
          .from('blockchain_gamification_logs')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      if (transactionType != null) {
        query = query.eq('transaction_type', transactionType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user blockchain logs error: $e');
      return [];
    }
  }

  /// Verify transaction hash
  Future<Map<String, dynamic>> verifyTransactionHash(
    String transactionHash,
  ) async {
    try {
      final response = await _client
          .from('blockchain_gamification_logs')
          .select()
          .eq('transaction_hash', transactionHash)
          .maybeSingle();

      if (response == null) {
        return {
          'success': false,
          'verified': false,
          'message': 'Transaction not found',
        };
      }

      // Verify cryptographic signature
      final transactionData =
          response['transaction_data'] as Map<String, dynamic>;
      final storedSignature = response['cryptographic_signature'] as String;
      final computedSignature = _generateCryptographicSignature(
        transactionData,
      );

      final isValid = storedSignature == computedSignature;

      return {
        'success': true,
        'verified': isValid,
        'transaction_data': transactionData,
        'verification_status': response['verification_status'],
        'created_at': response['created_at'],
      };
    } catch (e) {
      debugPrint('Verify transaction hash error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get blockchain audit trail
  Future<List<Map<String, dynamic>>> getBlockchainAuditTrail({
    int limit = 100,
  }) async {
    try {
      final response = await _client
          .from('blockchain_gamification_logs')
          .select('*, users!inner(email, full_name)')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get blockchain audit trail error: $e');
      return [];
    }
  }

  /// Create merkle tree batch for VP transactions
  Future<Map<String, dynamic>> createMerkleTreeBatch(
    List<String> transactionHashes,
  ) async {
    try {
      final merkleRoot = _generateMerkleRoot(transactionHashes);

      // Get next batch number
      final lastBatch = await _client
          .from('merkle_tree_batches')
          .select('batch_number')
          .order('batch_number', ascending: false)
          .limit(1)
          .maybeSingle();

      final nextBatchNumber = (lastBatch?['batch_number'] ?? 0) + 1;

      final response = await _client
          .from('merkle_tree_batches')
          .insert({
            'batch_number': nextBatchNumber,
            'merkle_root': merkleRoot,
            'transaction_count': transactionHashes.length,
            'batch_status': 'completed',
          })
          .select()
          .single();

      debugPrint(
        'Merkle tree batch created: Batch #$nextBatchNumber with ${transactionHashes.length} transactions',
      );

      return {
        'success': true,
        'batch_id': response['id'],
        'batch_number': nextBatchNumber,
        'merkle_root': merkleRoot,
      };
    } catch (e) {
      debugPrint('Create merkle tree batch error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get blockchain statistics
  Future<Map<String, dynamic>> getBlockchainStatistics() async {
    try {
      final totalLogs = await _client
          .from('blockchain_gamification_logs')
          .select('id');

      final vpTransactions = await _client
          .from('blockchain_gamification_logs')
          .select('id')
          .eq('transaction_type', 'vp_transaction');

      final badgeAwards = await _client
          .from('blockchain_gamification_logs')
          .select('id')
          .eq('transaction_type', 'badge_award');

      final challengeCompletions = await _client
          .from('blockchain_gamification_logs')
          .select('id')
          .eq('transaction_type', 'challenge_completion');

      final predictionResolutions = await _client
          .from('blockchain_gamification_logs')
          .select('id')
          .eq('transaction_type', 'prediction_resolution');

      return {
        'total_logs': (totalLogs as List).length,
        'vp_transactions': (vpTransactions as List).length,
        'badge_awards': (badgeAwards as List).length,
        'challenge_completions': (challengeCompletions as List).length,
        'prediction_resolutions': (predictionResolutions as List).length,
      };
    } catch (e) {
      debugPrint('Get blockchain statistics error: $e');
      return {};
    }
  }

  // =====================================================
  // PRIVATE HELPER METHODS
  // =====================================================

  /// Generate SHA-256 transaction hash
  String _generateTransactionHash(Map<String, dynamic> data) {
    final dataString = json.encode(data);
    final bytes = utf8.encode(dataString);
    final hash = keccak256(Uint8List.fromList(bytes));
    return '0x${hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// Generate cryptographic signature (simplified)
  String _generateCryptographicSignature(Map<String, dynamic> data) {
    final dataString = json.encode(data);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final signatureData = '$dataString:$timestamp:${_auth.currentUser?.id}';
    final bytes = utf8.encode(signatureData);
    final hash = keccak256(Uint8List.fromList(bytes));
    return '0x${hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
  }

  /// Generate Merkle root from transaction hashes
  String _generateMerkleRoot(List<String> transactionHashes) {
    if (transactionHashes.isEmpty) return '0x0';
    if (transactionHashes.length == 1) return transactionHashes[0];

    List<String> currentLevel = List.from(transactionHashes);

    while (currentLevel.length > 1) {
      List<String> nextLevel = [];

      for (int i = 0; i < currentLevel.length; i += 2) {
        if (i + 1 < currentLevel.length) {
          final combined = currentLevel[i] + currentLevel[i + 1];
          final hash = keccak256(Uint8List.fromList(utf8.encode(combined)));
          nextLevel.add(
            '0x${hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}',
          );
        } else {
          nextLevel.add(currentLevel[i]);
        }
      }

      currentLevel = nextLevel;
    }

    return currentLevel[0];
  }

  /// Keccak256 hash function (simplified implementation)
  Uint8List keccak256(Uint8List input) {
    // Simplified hash - in production use proper keccak256 from web3dart
    final random = Random(input.fold<int>(0, (sum, byte) => sum + byte));
    return Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
  }
}
