import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class BlockchainReceiptService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _polygonRpcUrl = String.fromEnvironment(
    'POLYGON_RPC_URL',
    defaultValue: 'https://polygon-rpc.com',
  );
  static const String _contractAddress = String.fromEnvironment(
    'VOTING_CONTRACT_ADDRESS',
  );

  late Web3Client _web3Client;

  BlockchainReceiptService() {
    _web3Client = Web3Client(_polygonRpcUrl, http.Client());
  }

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
    try {
      final receipt = jsonDecode(receiptJson) as Map<String, dynamic>;
      final voteHash = receipt['vote_hash'] as String;

      // Query blockchain/database for verification
      final stored = await _supabase
          .from('vote_receipts')
          .select()
          .eq('vote_hash', voteHash)
          .maybeSingle();

      if (stored == null) {
        return {'valid': false, 'reason': 'Receipt not found in blockchain'};
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
          'reason': 'Hash mismatch - receipt may be tampered',
        };
      }

      return {
        'valid': true,
        'receipt': stored,
        'verified_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) print('Error verifying receipt: $e');
      return {'valid': false, 'reason': 'Verification error: $e'};
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
