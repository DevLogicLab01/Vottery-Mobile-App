import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class BlockchainReceiptService {
  static const String stateVerified = 'verified';
  static const String stateFailed = 'failed';
  static const String stateUnavailable = 'unavailable';
  static const String stateUnsupported = 'unsupported';
  static const String statePendingBackend = 'pending_backend';

  final SupabaseClient _supabase = Supabase.instance.client;

  BlockchainReceiptService();

  // Generate cryptographic vote hash
  String generateVoteHash({
    required String electionId,
    required String userId,
    required String voteOption,
    required DateTime timestamp,
  }) {
    final data = '$electionId$userId$voteOption${timestamp.toIso8601String()}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Submit vote hash to blockchain
  Future<Map<String, dynamic>> submitVoteToBlockchain({
    required String electionId,
    required String userId,
    required String voteOption,
  }) async {
    try {
      final timestamp = DateTime.now();
      final voteHash = generateVoteHash(
        electionId: electionId,
        userId: userId,
        voteOption: voteOption,
        timestamp: timestamp,
      );

      // In production, this would submit to Polygon smart contract
      // For now, store locally with simulated blockchain data
      final receipt = {
        'vote_id': const Uuid().v4(),
        'election_id': electionId,
        'user_id': userId,
        'vote_option': voteOption,
        'vote_hash': voteHash,
        'blockchain_tx_hash': 'sim_${voteHash.substring(0, 16)}',
        'block_number': DateTime.now().millisecondsSinceEpoch,
        'timestamp': timestamp.toIso8601String(),
        'receipt_data': {
          'election_id': electionId,
          'vote_hash': voteHash,
          'timestamp': timestamp.toIso8601String(),
        },
      };

      await _supabase.from('vote_receipts').insert(receipt);

      return receipt;
    } catch (e) {
      if (kDebugMode) print('Error submitting vote to blockchain: $e');
      rethrow;
    }
  }

  // Verify vote receipt
  Future<Map<String, dynamic>> verifyReceipt(String receiptJson) async {
    final trimmedReceipt = receiptJson.trim();
    if (trimmedReceipt.isEmpty) {
      return {
        'valid': false,
        'state': stateFailed,
        'reason': 'Receipt payload is empty',
      };
    }

    try {
      final receipt = jsonDecode(trimmedReceipt) as Map<String, dynamic>;
      final voteHash = receipt['vote_hash'] as String;
      if (voteHash.trim().isEmpty) {
        return {
          'valid': false,
          'state': stateFailed,
          'reason': 'Receipt is missing vote_hash',
        };
      }

      // Query blockchain/database for verification
      final stored = await _supabase
          .from('vote_receipts')
          .select()
          .eq('vote_hash', voteHash)
          .maybeSingle();

      if (stored == null) {
        return {
          'valid': false,
          'state': statePendingBackend,
          'reason': 'Receipt not found in blockchain verification records',
        };
      }

      // Verify hash matches
      final regeneratedHash = generateVoteHash(
        electionId: stored['election_id'],
        userId: stored['user_id'],
        voteOption: stored['vote_option'],
        timestamp: DateTime.parse(stored['timestamp']),
      );

      if (regeneratedHash != voteHash) {
        return {
          'valid': false,
          'state': stateFailed,
          'reason': 'Hash mismatch - receipt may be tampered',
        };
      }

      return {
        'valid': true,
        'state': stateVerified,
        'receipt': stored,
        'verified_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) print('Error verifying receipt: $e');
      return {
        'valid': false,
        'state': stateUnavailable,
        'reason': 'Verification error: $e',
      };
    }
  }

  // Get user receipts
  Future<List<Map<String, dynamic>>> getUserReceipts(String userId) async {
    try {
      final receipts = await _supabase
          .from('vote_receipts')
          .select('*, elections!inner(title)')
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(receipts);
    } catch (e) {
      if (kDebugMode) print('Error getting receipts: $e');
      return [];
    }
  }

  // Generate receipt PDF data
  Map<String, dynamic> generateReceiptData(Map<String, dynamic> receipt) {
    return {
      'vote_id': receipt['vote_id'],
      'election_title': receipt['elections']?['title'] ?? 'Unknown Election',
      'vote_option': receipt['vote_option'],
      'vote_hash': receipt['vote_hash'],
      'blockchain_tx': receipt['blockchain_tx_hash'],
      'block_number': receipt['block_number'],
      'timestamp': receipt['timestamp'],
      'polygonscan_url':
          'https://polygonscan.com/tx/${receipt['blockchain_tx_hash']}',
    };
  }
}
