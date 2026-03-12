import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './logging/platform_logging_service.dart';

/// Service for end-to-end encryption, blockchain audit logs, MCQ validation, and video tracking
class EncryptionService {
  static EncryptionService? _instance;
  static EncryptionService get instance => _instance ??= EncryptionService._();

  EncryptionService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Generate RSA key pair for user
  Future<Map<String, String>?> generateRSAKeyPair() async {
    try {
      final keyGen = RSAKeyGenerator();
      final secureRandom = FortunaRandom();

      // Seed the random number generator
      final seedSource = List<int>.generate(32, (i) => i);
      secureRandom.seed(KeyParameter(Uint8List.fromList(seedSource)));

      final params = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);

      keyGen.init(ParametersWithRandom(params, secureRandom));
      final keyPair = keyGen.generateKeyPair();

      final publicKey = keyPair.publicKey as RSAPublicKey;
      final privateKey = keyPair.privateKey as RSAPrivateKey;

      // Convert to PEM format (simplified)
      final publicKeyString = '${publicKey.modulus}:${publicKey.exponent}';
      final privateKeyString =
          '${privateKey.modulus}:${privateKey.exponent}:${privateKey.privateExponent}';

      return {'public_key': publicKeyString, 'private_key': privateKeyString};
    } catch (e) {
      debugPrint('Generate RSA key pair error: $e');
      return null;
    }
  }

  /// Store encryption keys
  Future<bool> storeEncryptionKeys({
    required String publicKey,
    required String encryptedPrivateKey,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final fingerprint = sha256.convert(utf8.encode(publicKey)).toString();

      await _client.from('vote_encryption_keys').insert({
        'user_id': _auth.currentUser!.id,
        'public_key': publicKey,
        'encrypted_private_key': encryptedPrivateKey,
        'algorithm': 'rsa_2048',
        'key_fingerprint': fingerprint,
        'is_active': true,
      });

      return true;
    } catch (e) {
      debugPrint('Store encryption keys error: $e');
      return false;
    }
  }

  /// Get user's active encryption key
  Future<Map<String, dynamic>?> getActiveEncryptionKey() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('vote_encryption_keys')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get active encryption key error: $e');
      return null;
    }
  }

  /// Create blockchain audit log
  Future<String?> createBlockchainAuditLog({
    required String transactionType,
    required Map<String, dynamic> transactionData,
  }) async {
    try {
      final response = await _client.rpc(
        'create_blockchain_audit_log',
        params: {
          'p_transaction_type': transactionType,
          'p_transaction_data': transactionData,
        },
      );

      await PlatformLoggingService.logEvent(
        eventType: 'blockchain_audit',
        message: 'Blockchain audit log created',
        logLevel: 'info',
        logCategory: 'security',
        metadata: {'transaction_type': transactionType, 'log_id': response},
      );

      return response as String?;
    } catch (e) {
      debugPrint('Create blockchain audit log error: $e');
      return null;
    }
  }

  /// Get blockchain audit logs
  Future<List<Map<String, dynamic>>> getBlockchainAuditLogs({
    String? transactionType,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('blockchain_audit_logs').select();

      if (transactionType != null) {
        query = query.eq('transaction_type', transactionType);
      }

      final response = await query
          .order('block_number', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get blockchain audit logs error: $e');
      return [];
    }
  }

  /// Get MCQ questions for election
  Future<List<Map<String, dynamic>>> getMCQQuestions(String electionId) async {
    try {
      final response = await _client
          .from('mcq_questions')
          .select()
          .eq('election_id', electionId)
          .order('display_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get MCQ questions error: $e');
      return [];
    }
  }

  /// Submit MCQ response
  Future<bool> submitMCQResponse({
    required String questionId,
    required String electionId,
    required String selectedAnswer,
    required String correctAnswer,
    required int timeTakenSeconds,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final isCorrect = selectedAnswer == correctAnswer;
      final pointsEarned = isCorrect ? 10 : 0;

      await _client.from('mcq_responses').insert({
        'question_id': questionId,
        'user_id': _auth.currentUser!.id,
        'election_id': electionId,
        'selected_answer': selectedAnswer,
        'is_correct': isCorrect,
        'time_taken_seconds': timeTakenSeconds,
        'points_earned': pointsEarned,
      });

      return true;
    } catch (e) {
      debugPrint('Submit MCQ response error: $e');
      return false;
    }
  }

  /// Verify MCQ completion
  Future<bool> verifyMCQCompletion(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final response = await _client.rpc(
        'verify_mcq_completion',
        params: {
          'p_user_id': _auth.currentUser!.id,
          'p_election_id': electionId,
        },
      );

      return response as bool;
    } catch (e) {
      debugPrint('Verify MCQ completion error: $e');
      return false;
    }
  }

  /// Get video watch requirement
  Future<Map<String, dynamic>?> getVideoWatchRequirement(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('video_watch_requirements')
          .select()
          .eq('election_id', electionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get video watch requirement error: $e');
      return null;
    }
  }

  /// Update video watch time
  Future<bool> updateVideoWatchTime({
    required String requirementId,
    required String electionId,
    required int watchTimeSeconds,
    required double watchPercentage,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get requirement to check minimum
      final requirement = await _client
          .from('video_watch_requirements')
          .select()
          .eq('id', requirementId)
          .single();

      final minWatchTime = requirement['minimum_watch_time_seconds'] as int;
      final minPercentage = (requirement['minimum_watch_percentage'] as num)
          .toDouble();

      final hasMet =
          watchTimeSeconds >= minWatchTime && watchPercentage >= minPercentage;

      await _client.from('user_video_watch_time').upsert({
        'requirement_id': requirementId,
        'user_id': _auth.currentUser!.id,
        'election_id': electionId,
        'total_watch_time_seconds': watchTimeSeconds,
        'watch_percentage': watchPercentage,
        'has_met_requirement': hasMet,
        'last_watched_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Update video watch time error: $e');
      return false;
    }
  }

  /// Verify video watch requirement
  Future<bool> verifyVideoWatchRequirement(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final response = await _client.rpc(
        'verify_video_watch_requirement',
        params: {
          'p_user_id': _auth.currentUser!.id,
          'p_election_id': electionId,
        },
      );

      return response as bool;
    } catch (e) {
      debugPrint('Verify video watch requirement error: $e');
      return false;
    }
  }
}
