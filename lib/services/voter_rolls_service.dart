import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoterRollsService {
  static final VoterRollsService _instance = VoterRollsService._internal();
  static VoterRollsService get instance => _instance;
  VoterRollsService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getVoterRoll(String electionId) async {
    try {
      final data = await _supabase
          .from('election_voter_rolls')
          .select('*')
          .eq('election_id', electionId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('VoterRollsService.getVoterRoll error: $e');
      return [];
    }
  }

  Future<bool> importVoterRoll(
    String electionId,
    List<Map<String, String>> voters,
  ) async {
    try {
      final rows = voters
          .map((v) => {
            return {
              'election_id': electionId,
              'email': (v['email'] ?? '').trim().toLowerCase(),
              'name': (v['name'] ?? '').trim(),
              'verified': false,
            };
          })
          .where((r) => (r['email'] as String).isNotEmpty)
          .toList();

      await _supabase
          .from('election_voter_rolls')
          .upsert(rows, onConflict: 'election_id,email');
      return true;
    } catch (e) {
      debugPrint('VoterRollsService.importVoterRoll error: $e');
      return false;
    }
  }

  Future<bool> verifyVoter(String electionId, String email) async {
    try {
      final data = await _supabase
          .from('election_voter_rolls')
          .select('id, email, verified')
          .eq('election_id', electionId)
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      return data != null;
    } catch (e) {
      debugPrint('VoterRollsService.verifyVoter error: $e');
      return false;
    }
  }

  Future<bool> removeVoter(String rollEntryId) async {
    try {
      await _supabase
          .from('election_voter_rolls')
          .delete()
          .eq('id', rollEntryId);
      return true;
    } catch (e) {
      debugPrint('VoterRollsService.removeVoter error: $e');
      return false;
    }
  }

  List<Map<String, String>> parseCSV(String csvText) {
    final lines = csvText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return [];

    final header = lines[0].toLowerCase();
    final hasHeader = header.contains('email') || header.contains('name');
    final dataLines = hasHeader ? lines.sublist(1) : lines;

    return dataLines.map((line) {
      final parts = line.split(',').map((p) => p.trim().replaceAll('"', '')).toList();
      return {'email': parts.isNotEmpty ? parts[0] : '', 'name': parts.length > 1 ? parts[1] : ''};
    }).where((v) => v['email']!.isNotEmpty).toList();
  }
}
