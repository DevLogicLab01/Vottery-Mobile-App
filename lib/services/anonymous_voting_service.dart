import 'dart:convert';

import 'package:crypto/crypto.dart';

import './supabase_service.dart';

class AnonymousVotingService {
  static final AnonymousVotingService _instance =
      AnonymousVotingService._internal();
  factory AnonymousVotingService() => _instance;
  AnonymousVotingService._internal();

  final _supabase = SupabaseService.instance.client;

  /// Generate hashed voter ID (SHA-256 of user_id + election_id + salt)
  String generateHashedVoterId(String userId, String electionId, String salt) {
    final input = '$userId$electionId$salt';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate anonymous voter code (ANON-{election_id}-{hash})
  String generateAnonymousVoterCode(String electionId, String hashedVoterId) {
    final electionPrefix = electionId.substring(0, 8);
    final hashPrefix = hashedVoterId.substring(0, 12);
    return 'ANON-$electionPrefix-$hashPrefix';
  }

  /// Check if election allows anonymous voting
  Future<bool> isAnonymousVotingAllowed(String electionId) async {
    try {
      final response = await _supabase
          .from('elections')
          .select('allow_anonymous_voting')
          .eq('id', electionId)
          .single();

      return response['allow_anonymous_voting'] ?? false;
    } catch (e) {
      print('Error checking anonymous voting: $e');
      return false;
    }
  }

  /// Check if user has already voted anonymously
  Future<bool> hasVotedAnonymously(
    String electionId,
    String hashedVoterId,
  ) async {
    try {
      final response = await _supabase
          .from('anonymous_voter_tracking')
          .select('id')
          .eq('election_id', electionId)
          .eq('hashed_voter_id', hashedVoterId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking anonymous vote status: $e');
      return false;
    }
  }

  /// Submit anonymous vote
  Future<Map<String, dynamic>?> submitAnonymousVote({
    required String electionId,
    required String userId,
    required String optionId,
    required Map<String, dynamic> voteData,
    String? blockchainHash,
  }) async {
    try {
      // Generate salt for this vote
      final salt = DateTime.now().millisecondsSinceEpoch.toString();

      // Generate hashed voter ID
      final hashedVoterId = generateHashedVoterId(userId, electionId, salt);

      // Generate anonymous voter code
      final anonymousCode = generateAnonymousVoterCode(
        electionId,
        hashedVoterId,
      );

      // Check if already voted
      final alreadyVoted = await hasVotedAnonymously(electionId, hashedVoterId);
      if (alreadyVoted) {
        throw Exception('You have already voted in this election');
      }

      // Insert anonymous vote
      final voteResponse = await _supabase
          .from('anonymous_votes')
          .insert({
            'election_id': electionId,
            'hashed_voter_id': hashedVoterId,
            'anonymous_voter_code': anonymousCode,
            'option_id': optionId,
            'vote_data': voteData,
            'blockchain_hash': blockchainHash,
          })
          .select()
          .single();

      // Track anonymous voter
      await _supabase.from('anonymous_voter_tracking').insert({
        'election_id': electionId,
        'hashed_voter_id': hashedVoterId,
        'anonymous_voter_code': anonymousCode,
        'has_voted': true,
      });

      return {
        'success': true,
        'anonymous_voter_code': anonymousCode,
        'vote_id': voteResponse['id'],
        'message': 'Anonymous vote submitted successfully',
      };
    } catch (e) {
      print('Error submitting anonymous vote: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify anonymous vote using voter code
  Future<Map<String, dynamic>?> verifyAnonymousVote(
    String anonymousVoterCode,
  ) async {
    try {
      final response = await _supabase
          .from('anonymous_votes')
          .select('id, election_id, voted_at, blockchain_hash')
          .eq('anonymous_voter_code', anonymousVoterCode)
          .single();

      return {
        'verified': true,
        'vote_id': response['id'],
        'election_id': response['election_id'],
        'voted_at': response['voted_at'],
        'blockchain_hash': response['blockchain_hash'],
      };
    } catch (e) {
      print('Error verifying anonymous vote: $e');
      return {'verified': false, 'error': 'Invalid anonymous voter code'};
    }
  }

  /// Get anonymous vote statistics for election creator
  Future<Map<String, dynamic>> getAnonymousVoteStats(String electionId) async {
    try {
      final votesResponse = await _supabase
          .from('anonymous_votes')
          .select('id')
          .eq('election_id', electionId);

      final totalVotes = votesResponse.length;

      return {
        'total_anonymous_votes': totalVotes,
        'anonymity_guaranteed': true,
        'voter_identities_protected': true,
      };
    } catch (e) {
      print('Error fetching anonymous vote stats: $e');
      return {'total_anonymous_votes': 0, 'error': e.toString()};
    }
  }

  /// Get anonymous vote aggregation (without voter identities)
  Future<List<Map<String, dynamic>>> getAnonymousVoteAggregation(
    String electionId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_anonymous_vote_aggregation',
        params: {'p_election_id': electionId},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      print('Error fetching anonymous vote aggregation: $e');
      return [];
    }
  }

  /// Check if anonymous voting is enabled for election
  Future<bool> checkAnonymityStatus(String electionId) async {
    try {
      final response = await _supabase
          .from('elections')
          .select('allow_anonymous_voting')
          .eq('id', electionId)
          .single();

      return response['allow_anonymous_voting'] ?? false;
    } catch (e) {
      print('Error checking anonymity status: $e');
      return false;
    }
  }
}
