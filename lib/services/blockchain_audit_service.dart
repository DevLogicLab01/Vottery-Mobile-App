import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlockchainAuditService {
  static final BlockchainAuditService _instance =
      BlockchainAuditService._internal();
  static BlockchainAuditService get instance => _instance;
  BlockchainAuditService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _genesisHash =
      '0x0000000000000000000000000000000000000000000000000000000000000000';

  String _generateHash(Map<String, dynamic> data) {
    final str = jsonEncode(data) + DateTime.now().microsecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(str)).toString();
  }

  Future<void> recordAuditLog(String action, {
    String? userId,
    String? electionId,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final hash = _generateHash({'action': action, ...metadata});

      String previousHash = _genesisHash;
      try {
        final last = await _supabase
            .from('blockchain_audit_logs')
            .select('hash')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (last != null && last['hash'] != null) {
          previousHash = last['hash'] as String;
        }
      } catch (_) {}

      await _supabase.from('blockchain_audit_logs').insert({
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': userId ?? _supabase.auth.currentUser?.id,
        'election_id': electionId,
        'hash': hash,
        'previous_hash': previousHash,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('BlockchainAuditService.recordAuditLog error: $e');
    }
  }

  Future<void> publishToBulletinBoard(String electionId, String voteHash) async {
    try {
      await _supabase.from('public_bulletin_board').insert({
        'election_id': electionId,
        'vote_hash': voteHash,
        'timestamp': DateTime.now().toIso8601String(),
        'verification_status': 'published',
      });
    } catch (e) {
      debugPrint('BlockchainAuditService.publishToBulletinBoard error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAuditChain(String electionId) async {
    try {
      final data = await _supabase
          .from('blockchain_audit_logs')
          .select('*')
          .eq('election_id', electionId)
          .order('created_at', ascending: true);
      return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('BlockchainAuditService.getAuditChain error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> verifyChainIntegrity(String electionId) async {
    try {
      final chain = await getAuditChain(electionId);
      if (chain.isEmpty) return {'valid': true, 'chainLength': 0, 'errors': []};

      final errors = <String>[];
      for (int i = 1; i < chain.length; i++) {
        if (chain[i]['previous_hash'] != chain[i - 1]['hash']) {
          errors.add('Chain break at index $i');
        }
      }
      return {
        'valid': errors.isEmpty,
        'chainLength': chain.length,
        'errors': errors,
      };
    } catch (e) {
      return {'valid': false, 'chainLength': 0, 'errors': ['$e']};
    }
  }

  Future<List<Map<String, dynamic>>> getPublicBulletinBoard(String electionId) async {
    try {
      final data = await _supabase
          .from('public_bulletin_board')
          .select('*')
          .eq('election_id', electionId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('BlockchainAuditService.getPublicBulletinBoard error: $e');
      return [];
    }
  }
}
