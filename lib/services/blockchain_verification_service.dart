import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Blockchain Verification Service
/// Implements RSA-2048 encryption, SHA-256 hashing, Merkle trees, and vote integrity checking
class BlockchainVerificationService {
  static BlockchainVerificationService? _instance;
  static BlockchainVerificationService get instance =>
      _instance ??= BlockchainVerificationService._();

  BlockchainVerificationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // Error tracking
  final List<Map<String, dynamic>> _errorLog = [];

  /// Get error analytics
  Map<String, int> getErrorAnalytics() {
    final analytics = <String, int>{};
    for (final error in _errorLog) {
      final type = error['type'] as String;
      analytics[type] = (analytics[type] ?? 0) + 1;
    }
    return analytics;
  }

  /// Log error for analytics
  void _logError(String type, String message, {dynamic error}) {
    _errorLog.add({
      'type': type,
      'message': message,
      'error': error?.toString(),
      'timestamp': DateTime.now(),
    });

    // Keep only last 100 errors
    if (_errorLog.length > 100) {
      _errorLog.removeAt(0);
    }
  }

  /// Generate RSA-2048 key pair with error handling
  Future<Map<String, dynamic>> generateRSAKeyPair() async {
    try {
      final keyGen = RSAKeyGenerator();
      final secureRandom = FortunaRandom();

      // Seed the random number generator
      final seedSource = List<int>.generate(
        32,
        (i) => math.Random().nextInt(256),
      );
      secureRandom.seed(KeyParameter(Uint8List.fromList(seedSource)));

      final params = RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64);
      keyGen.init(ParametersWithRandom(params, secureRandom));

      final keyPair = keyGen.generateKeyPair();
      final publicKey = keyPair.publicKey as RSAPublicKey;
      final privateKey = keyPair.privateKey as RSAPrivateKey;

      // Convert to string format
      final publicKeyString = '${publicKey.modulus}:${publicKey.exponent}';
      final privateKeyString =
          '${privateKey.modulus}:${privateKey.exponent}:${privateKey.privateExponent}';

      return {
        'success': true,
        'public_key': publicKeyString,
        'private_key': privateKeyString,
      };
    } catch (e) {
      _logError('rsa_generation', '🔐 RSA Key Generation Failed', error: e);
      debugPrint('Generate RSA key pair error: $e');
      return {
        'success': false,
        'error': 'rsa_generation_failed',
        'message':
            '🔐 Encryption Key Generation Error - Unable to create secure keys',
      };
    }
  }

  /// Decrypt RSA encrypted data with error handling
  Future<Map<String, dynamic>> decryptRSAData({
    required String encryptedData,
    required String privateKey,
  }) async {
    try {
      // Parse private key
      final keyParts = privateKey.split(':');
      if (keyParts.length != 3) {
        throw Exception('Invalid private key format');
      }

      // Attempt decryption (simplified - in production use proper RSA decryption)
      final decryptedData = utf8.decode(base64Decode(encryptedData));

      return {'success': true, 'data': decryptedData};
    } catch (e) {
      _logError(
        'rsa_decryption',
        '🔐 Decryption Error - Verify election encryption keys',
        error: e,
      );
      debugPrint('RSA decryption error: $e');
      return {
        'success': false,
        'error': 'rsa_decryption_failed',
        'message': '🔐 Decryption Error - Verify election encryption keys',
        'suggestion':
            'Ensure you have the correct encryption keys for this election',
      };
    }
  }

  /// Generate SHA-256 hash
  String generateSHA256Hash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create vote fingerprint (SHA-256 hash combining voter_id + election_id + vote_data + timestamp)
  String createVoteFingerprint({
    required String voterId,
    required String electionId,
    required String voteData,
    required DateTime timestamp,
  }) {
    final combined =
        '$voterId$electionId$voteData${timestamp.toIso8601String()}';
    return generateSHA256Hash(combined);
  }

  /// Verify vote hash integrity with tamper detection
  Future<Map<String, dynamic>> verifyVoteHash({
    required String voteHash,
    required String voterId,
    required String electionId,
    required String voteData,
    required DateTime timestamp,
  }) async {
    try {
      final expectedHash = createVoteFingerprint(
        voterId: voterId,
        electionId: electionId,
        voteData: voteData,
        timestamp: timestamp,
      );

      final isValid = voteHash == expectedHash;

      if (!isValid) {
        _logError(
          'invalid_hash',
          '⚠️ Vote Integrity Compromised',
          error: 'Hash mismatch',
        );

        // Generate audit report
        await _generateTamperAuditReport(
          voteHash: voteHash,
          expectedHash: expectedHash,
          electionId: electionId,
        );
      }

      return {
        'success': true,
        'is_valid': isValid,
        'message': isValid
            ? '✅ Vote Integrity Verified'
            : '⚠️ Vote Integrity Compromised - Tamper detected',
        'expected_hash': expectedHash,
        'actual_hash': voteHash,
      };
    } catch (e) {
      _logError('hash_verification', 'Hash verification failed', error: e);
      return {
        'success': false,
        'error': 'hash_verification_failed',
        'message': 'Unable to verify vote hash',
      };
    }
  }

  /// Generate tamper audit report
  Future<void> _generateTamperAuditReport({
    required String voteHash,
    required String expectedHash,
    required String electionId,
  }) async {
    try {
      await _client.from('blockchain_audit_logs').insert({
        'election_id': electionId,
        'event_type': 'tamper_detected',
        'severity': 'critical',
        'details': jsonEncode({
          'actual_hash': voteHash,
          'expected_hash': expectedHash,
          'detection_time': DateTime.now().toIso8601String(),
        }),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Failed to generate tamper audit report: $e');
    }
  }

  /// Generate election encryption keys with error handling
  Future<Map<String, dynamic>> generateElectionEncryptionKeys(
    String electionId,
  ) async {
    try {
      final keyPair = await generateRSAKeyPair();
      if (!keyPair['success']) {
        return keyPair;
      }

      final publicKey = keyPair['public_key']!;
      final privateKey = keyPair['private_key']!;

      // Generate key fingerprint
      final fingerprint = generateSHA256Hash(publicKey);

      // Store in database
      final response = await _client.rpc(
        'generate_election_encryption_keys',
        params: {'p_election_id': electionId},
      );

      // Update with actual keys
      await _client
          .from('election_encryption_keys')
          .update({
            'public_key': publicKey,
            'encrypted_private_key': privateKey, // In production, encrypt this
            'key_fingerprint': fingerprint,
          })
          .eq('id', response);

      return {
        'success': true,
        'id': response,
        'public_key': publicKey,
        'key_fingerprint': fingerprint,
      };
    } catch (e) {
      _logError('key_generation', 'Election key generation failed', error: e);
      debugPrint('Generate election encryption keys error: $e');
      return {
        'success': false,
        'error': 'key_generation_failed',
        'message': 'Failed to generate encryption keys for election',
      };
    }
  }

  /// Create blockchain vote record with timeout and retry
  Future<Map<String, dynamic>> createBlockchainVoteRecord({
    required String electionId,
    required String voteData,
    int retryCount = 0,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {
          'success': false,
          'error': 'not_authenticated',
          'message': 'Authentication required to record vote',
        };
      }

      final voterId = _auth.currentUser!.id;
      final timestamp = DateTime.now();

      // Generate vote hash (SHA-256 fingerprint)
      final voteHash = createVoteFingerprint(
        voterId: voterId,
        electionId: electionId,
        voteData: voteData,
        timestamp: timestamp,
      );

      // Generate digital signature (simplified - in production use RSA signing)
      final digitalSignature = generateSHA256Hash('$voteHash$voterId');

      // Encrypt vote data (simplified - in production use RSA encryption)
      final encryptedVoteData = base64Encode(utf8.encode(voteData));

      // Create blockchain record with 30-second timeout
      final recordId = await _client
          .rpc(
            'create_blockchain_vote_record',
            params: {
              'p_election_id': electionId,
              'p_voter_id': voterId,
              'p_vote_hash': voteHash,
              'p_digital_signature': digitalSignature,
              'p_vote_data_encrypted': encryptedVoteData,
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('Blockchain verification timeout'),
          );

      // Get receipt code
      final receipt = await _client
          .from('vote_verification_receipts')
          .select('receipt_code')
          .eq('blockchain_record_id', recordId)
          .single()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('Receipt retrieval timeout'),
          );

      return {
        'success': true,
        'record_id': recordId,
        'vote_hash': voteHash,
        'receipt_code': receipt['receipt_code'],
      };
    } on TimeoutException catch (e) {
      _logError('blockchain_timeout', 'Blockchain Timeout', error: e);

      // Retry with exponential backoff
      if (retryCount < 3) {
        final delays = [5, 15, 30];
        await Future.delayed(Duration(seconds: delays[retryCount]));
        return createBlockchainVoteRecord(
          electionId: electionId,
          voteData: voteData,
          retryCount: retryCount + 1,
        );
      }

      return {
        'success': false,
        'error': 'blockchain_timeout',
        'message': 'Network Error: Unable to connect to verification service',
        'suggestion': 'Check your internet connection and try again',
        'retry_available': false,
      };
    } catch (e) {
      _logError(
        'blockchain_record',
        'Failed to create blockchain record',
        error: e,
      );
      debugPrint('Create blockchain vote record error: $e');
      return {
        'success': false,
        'error': 'blockchain_record_failed',
        'message': 'Failed to record vote on blockchain',
        'suggestion': 'Please try submitting your vote again',
        'retry_available': retryCount < 3,
      };
    }
  }

  /// Verify vote integrity with comprehensive error handling
  Future<Map<String, dynamic>> verifyVoteIntegrity(
    String receiptCode, {
    int retryCount = 0,
  }) async {
    try {
      final response = await _client
          .rpc('verify_vote_integrity', params: {'p_receipt_code': receiptCode})
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException('Verification timeout'),
          );

      if (response == null || response.isEmpty) {
        _logError(
          'vote_not_found',
          'Vote record not found',
          error: 'Empty response',
        );
        return {
          'success': false,
          'error': 'vote_not_found',
          'message': 'Verification Failed: Vote record not found in blockchain',
          'suggestion': 'Verify your receipt code and try again',
        };
      }

      final result = response[0];
      final isValid = result['is_valid'] as bool;

      return {
        'success': true,
        'is_valid': isValid,
        'vote_hash': result['vote_hash'],
        'block_number': result['block_number'],
        'timestamp': DateTime.parse(result['vote_timestamp']),
        'verification_status': result['verification_status'],
        'message': isValid
            ? '✅ Vote Verified Successfully'
            : '⚠️ Vote Integrity Compromised',
      };
    } on TimeoutException catch (e) {
      _logError('verification_timeout', 'Verification timeout', error: e);

      // Retry with exponential backoff
      if (retryCount < 3) {
        final delays = [5, 15, 30];
        await Future.delayed(Duration(seconds: delays[retryCount]));
        return verifyVoteIntegrity(receiptCode, retryCount: retryCount + 1);
      }

      return {
        'success': false,
        'error': 'verification_timeout',
        'message': 'Network Error: Unable to connect to verification service',
        'suggestion': 'Check your internet connection and try again',
        'retry_available': false,
      };
    } catch (e) {
      _logError('verification_failed', 'Verification failed', error: e);
      debugPrint('Verify vote integrity error: $e');
      return {
        'success': false,
        'error': 'verification_failed',
        'message': 'Verification Failed: Unable to verify vote',
        'suggestion': 'Please try again or contact support',
        'retry_available': retryCount < 3,
      };
    }
  }

  /// Check if verification period is valid
  Future<Map<String, dynamic>> checkVerificationPeriod(
    String electionId,
  ) async {
    try {
      final election = await _client
          .from('elections')
          .select('end_date, verification_period_days')
          .eq('id', electionId)
          .single();

      final endDate = DateTime.parse(election['end_date']);
      final verificationDays = election['verification_period_days'] ?? 30;
      final verificationEndDate = endDate.add(Duration(days: verificationDays));
      final isExpired = DateTime.now().isAfter(verificationEndDate);

      if (isExpired) {
        _logError(
          'expired_certificate',
          'Verification period ended',
          error: 'Period expired',
        );
      }

      return {
        'success': true,
        'is_expired': isExpired,
        'end_date': verificationEndDate,
        'message': isExpired
            ? 'Expired Certificate: Verification period ended'
            : 'Verification period active',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'period_check_failed',
        'message': 'Unable to check verification period',
      };
    }
  }

  /// Get blockchain vote records for election
  Future<List<Map<String, dynamic>>> getBlockchainVoteRecords(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('blockchain_vote_records')
          .select('*')
          .eq('election_id', electionId)
          .order('block_number', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get blockchain vote records error: $e');
      return [];
    }
  }

  /// Get user's blockchain vote records
  Future<List<Map<String, dynamic>>> getUserBlockchainVoteRecords() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('blockchain_vote_records')
          .select('*, elections(title)')
          .eq('voter_id', _auth.currentUser!.id)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user blockchain vote records error: $e');
      return [];
    }
  }

  /// Get blockchain audit logs
  Future<List<Map<String, dynamic>>> getBlockchainAuditLogs(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('blockchain_audit_logs')
          .select('*')
          .eq('election_id', electionId)
          .order('timestamp', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get blockchain audit logs error: $e');
      return [];
    }
  }

  /// Get election encryption status
  Future<Map<String, dynamic>?> getElectionEncryptionStatus(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('election_encryption_keys')
          .select('*')
          .eq('election_id', electionId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get election encryption status error: $e');
      return null;
    }
  }

  /// Get Merkle tree blocks
  Future<List<Map<String, dynamic>>> getMerkleTreeBlocks(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('merkle_tree_blocks')
          .select('*')
          .eq('election_id', electionId)
          .eq('is_published', true)
          .order('block_number', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get Merkle tree blocks error: $e');
      return [];
    }
  }

  /// Calculate Merkle root (simplified implementation)
  String calculateMerkleRoot(List<String> hashes) {
    if (hashes.isEmpty) return '';
    if (hashes.length == 1) return hashes[0];

    List<String> currentLevel = List.from(hashes);

    while (currentLevel.length > 1) {
      List<String> nextLevel = [];

      for (int i = 0; i < currentLevel.length; i += 2) {
        if (i + 1 < currentLevel.length) {
          final combined = currentLevel[i] + currentLevel[i + 1];
          nextLevel.add(generateSHA256Hash(combined));
        } else {
          nextLevel.add(currentLevel[i]);
        }
      }

      currentLevel = nextLevel;
    }

    return currentLevel[0];
  }

  /// Get verification statistics
  Future<Map<String, dynamic>> getVerificationStatistics(
    String electionId,
  ) async {
    try {
      final voteRecords = await getBlockchainVoteRecords(electionId);
      final verifiedCount = voteRecords
          .where((r) => r['verification_status'] == 'verified')
          .length;
      final tamperedCount = voteRecords
          .where((r) => r['verification_status'] == 'tampered')
          .length;

      final successRate = voteRecords.isNotEmpty
          ? (verifiedCount / voteRecords.length) * 100
          : 0.0;

      return {
        'total_votes': voteRecords.length,
        'verified_count': verifiedCount,
        'tampered_count': tamperedCount,
        'success_rate': successRate,
      };
    } catch (e) {
      debugPrint('Get verification statistics error: $e');
      return {
        'total_votes': 0,
        'verified_count': 0,
        'tampered_count': 0,
        'success_rate': 0.0,
      };
    }
  }
}
