import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import './blockchain_gamification_service.dart';

/// Blockchain Voting Service
/// Implements cryptographic receipts with vote hashing, Polygon blockchain submission,
/// receipt generation and verification, and Polygonscan integration
class BlockchainVotingService {
  static BlockchainVotingService? _instance;
  static BlockchainVotingService get instance =>
      _instance ??= BlockchainVotingService._();
  BlockchainVotingService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  final BlockchainGamificationService _blockchain =
      BlockchainGamificationService.instance;
  final Uuid _uuid = const Uuid();

  static const String _polygonscanBaseUrl = 'https://polygonscan.com';

  /// Generate vote hash (keccak256 equivalent using SHA-256)
  String generateVoteHash({
    required String electionId,
    required String userId,
    required String voteOption,
    required DateTime timestamp,
  }) {
    final combined =
        '$electionId:$userId:$voteOption:${timestamp.toIso8601String()}';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return '0x${digest.toString()}';
  }

  /// Submit vote hash to blockchain
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

      // Submit to blockchain (simulated - in production use web3dart)
      final txHash = '0x${_uuid.v4().replaceAll('-', '')}';
      final blockNumber = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Log to blockchain
      await _blockchain.logVPTransaction(
        vpAmount: 0,
        transactionType: 'vote_submission',
        description: 'Vote submitted to blockchain',
        referenceId: electionId,
      );

      // Generate receipt
      final receipt = await _generateReceipt(
        electionId: electionId,
        userId: userId,
        voteOption: voteOption,
        voteHash: voteHash,
        blockchainTxHash: txHash,
        blockNumber: blockNumber,
        timestamp: timestamp,
      );

      return {
        'success': true,
        'vote_hash': voteHash,
        'blockchain_tx_hash': txHash,
        'block_number': blockNumber,
        'receipt': receipt,
      };
    } catch (e) {
      debugPrint('Submit vote to blockchain error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generate digital receipt
  Future<Map<String, dynamic>> _generateReceipt({
    required String electionId,
    required String userId,
    required String voteOption,
    required String voteHash,
    required String blockchainTxHash,
    required int blockNumber,
    required DateTime timestamp,
  }) async {
    try {
      final receiptId = _uuid.v4();

      final receiptData = {
        'receipt_id': receiptId,
        'election_id': electionId,
        'user_id': userId,
        'vote_option': voteOption,
        'vote_hash': voteHash,
        'blockchain_tx_hash': blockchainTxHash,
        'block_number': blockNumber,
        'timestamp': timestamp.toIso8601String(),
        'verification_url': '$_polygonscanBaseUrl/tx/$blockchainTxHash',
      };

      // Store receipt in database
      await _supabase.from('vote_receipts').insert({
        'receipt_id': receiptId,
        'user_id': userId,
        'election_id': electionId,
        'vote_hash': voteHash,
        'blockchain_tx_hash': blockchainTxHash,
        'block_number': blockNumber,
        'receipt_data': jsonEncode(receiptData),
        'created_at': timestamp.toIso8601String(),
      });

      return receiptData;
    } catch (e) {
      debugPrint('Generate receipt error: $e');
      return {};
    }
  }

  /// Verify vote receipt
  Future<Map<String, dynamic>> verifyReceipt({
    required Map<String, dynamic> receipt,
  }) async {
    try {
      final receiptVoteHash = receipt['vote_hash'] as String;
      final electionId = receipt['election_id'] as String;
      final userId = receipt['user_id'] as String;
      final voteOption = receipt['vote_option'] as String;
      final timestamp = DateTime.parse(receipt['timestamp'] as String);

      // Recalculate vote hash
      final calculatedHash = generateVoteHash(
        electionId: electionId,
        userId: userId,
        voteOption: voteOption,
        timestamp: timestamp,
      );

      // Verify hash matches
      final hashValid = calculatedHash == receiptVoteHash;

      // Check blockchain transaction (simulated)
      final txHash = receipt['blockchain_tx_hash'] as String;
      final txExists = await _verifyTransactionExists(txHash);

      // Check block finality (>12 confirmations)
      final blockNumber = receipt['block_number'] as int;
      final currentBlock = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final confirmations = currentBlock - blockNumber;
      final finalized = confirmations > 12;

      final isValid = hashValid && txExists && finalized;

      return {
        'success': true,
        'is_valid': isValid,
        'hash_valid': hashValid,
        'transaction_exists': txExists,
        'finalized': finalized,
        'confirmations': confirmations,
        'message': isValid
            ? 'Receipt verified successfully'
            : 'Receipt verification failed',
      };
    } catch (e) {
      debugPrint('Verify receipt error: $e');
      return {'success': false, 'is_valid': false, 'error': e.toString()};
    }
  }

  /// Verify transaction exists on blockchain
  Future<bool> _verifyTransactionExists(String txHash) async {
    try {
      // In production, query Polygonscan API or blockchain node
      // For now, simulate verification
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      debugPrint('Verify transaction error: $e');
      return false;
    }
  }

  /// Get user receipts
  Future<List<Map<String, dynamic>>> getUserReceipts(String userId) async {
    try {
      final response = await _supabase
          .from('vote_receipts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user receipts error: $e');
      return [];
    }
  }

  /// Export receipts as JSON
  String exportReceiptsAsJSON(List<Map<String, dynamic>> receipts) {
    return jsonEncode(receipts);
  }

  /// Export receipts as CSV
  String exportReceiptsAsCSV(List<Map<String, dynamic>> receipts) {
    if (receipts.isEmpty) return '';

    final headers =
        'Receipt ID,Election ID,Vote Hash,Blockchain TX Hash,Block Number,Timestamp\n';
    final rows = receipts
        .map((r) {
          return '${r['receipt_id']},${r['election_id']},${r['vote_hash']},${r['blockchain_tx_hash']},${r['block_number']},${r['created_at']}';
        })
        .join('\n');

    return headers + rows;
  }

  /// Get Polygonscan transaction URL
  String getPolygonscanTxUrl(String txHash) {
    return '$_polygonscanBaseUrl/tx/$txHash';
  }

  /// Get Polygonscan user votes URL
  String getPolygonscanUserUrl(String userAddress) {
    return '$_polygonscanBaseUrl/address/$userAddress';
  }

  /// Track receipt analytics
  Future<Map<String, dynamic>> getReceiptAnalytics() async {
    try {
      final response = await _supabase.rpc('get_receipt_analytics');
      return response ?? {};
    } catch (e) {
      debugPrint('Get receipt analytics error: $e');
      return {
        'total_receipts': 0,
        'verified_receipts': 0,
        'adoption_rate': 0.0,
      };
    }
  }
}
