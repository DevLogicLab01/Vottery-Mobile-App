import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import './auth_service.dart';
import './blockchain_audit_service.dart';
import './gamification_service.dart';
import './supabase_service.dart';
import './vp_service.dart';
import './logging/platform_logging_service.dart';

class VotingService {
  static VotingService? _instance;
  static VotingService get instance => _instance ??= VotingService._();

  VotingService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  VPService get _vpService => VPService.instance;
  GamificationService get _gamificationService => GamificationService.instance;

  Future<List<Map<String, dynamic>>> getElections({
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('elections').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get elections error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getElectionById(String electionId) async {
    try {
      final response = await _client
          .from('elections')
          .select()
          .eq('id', electionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get election error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getElectionOptions(
    String electionId,
  ) async {
    try {
      final response = await _client
          .from('election_options')
          .select()
          .eq('election_id', electionId)
          .order('display_order', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get election options error: $e');
      return [];
    }
  }

  /// Cast a vote and return a detailed receipt, mirroring the Web contract.
  /// Returns (success, errorMessage, receipt) where receipt includes hashes and proof metadata.
  Future<({bool success, String? errorMessage, Map<String, dynamic>? receipt})>
      castVoteWithReceipt({
    required String electionId,
    String? selectedOptionId,
    List<String>? rankedChoices,
    List<String>? selectedOptions,
    Map<String, dynamic>? voteScores,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated to vote');
      }

      // Generate blockchain-style hashes for vote verification
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final userId = _auth.currentUser!.id;

      // Generate vote hash (hash of vote data)
      final voteContent = '$userId:$electionId:$selectedOptionId:$timestamp';
      final voteHashBytes = sha256.convert(utf8.encode(voteContent));
      final voteHash = voteHashBytes.toString();

      // Generate blockchain hash (simulated chain linking)
      final blockchainContent =
          '$voteHash:$timestamp:${DateTime.now().microsecondsSinceEpoch}';
      final blockchainHashBytes = sha256.convert(
        utf8.encode(blockchainContent),
      );
      final blockchainHash = blockchainHashBytes.toString();

      final voteData = {
        'election_id': electionId,
        'user_id': userId,
        'selected_option_id': selectedOptionId,
        'ranked_choices': rankedChoices ?? [],
        'selected_options': selectedOptions ?? [],
        'vote_scores': voteScores ?? {},
        'vote_hash': voteHash,
        'blockchain_hash': blockchainHash,
      };

      final inserted = await _client
          .from('votes')
          .insert(voteData)
          .select()
          .single() as Map<String, dynamic>;

      final voteId = inserted['id'];

      // Store a lightweight zero-knowledge proof record to mirror Web analytics.
      await _client.from('zero_knowledge_proofs').insert({
        'vote_id': voteId,
        'election_id': electionId,
        'commitment': voteHash,
        'challenge': blockchainHash,
        'response': voteHash,
        'public_key': 'mobile-lite',
        'verified': false,
      });

      // Award VP for voting
      final vpResult = await _vpService.awardVotingVP(electionId);

      // Add XP for gamification
      await _gamificationService.addXP(10, 'voting');

      // Update streak
      await _gamificationService.updateStreak();

      // Record on blockchain audit chain and publish to bulletin board
      await BlockchainAuditService.instance.recordAuditLog(
        'vote_cast',
        userId: userId,
        electionId: electionId,
        metadata: {'previousHash': blockchainHash},
      );
      await BlockchainAuditService.instance.publishToBulletinBoard(
        electionId,
        voteHash,
      );

      // Log successful vote
      await PlatformLoggingService.logVoteAction(
        electionId: electionId,
        optionId: selectedOptionId ?? 'multiple',
        vpEarned: vpResult ? 1 : 0,
      );

      final receipt = <String, dynamic>{
        'voteId': voteId,
        'electionId': electionId,
        'voteHash': voteHash,
        'blockchainHash': blockchainHash,
        'zkProof': {
          'commitment': voteHash.substring(0, 20),
          'verified': false,
        },
        'cryptographicProofs': {
          'hashChain': 'Mobile SHA-256 hash chain',
        },
      };

      return (success: true, errorMessage: null, receipt: receipt);
    } catch (e) {
      debugPrint('Cast vote error: $e');

      // Log voting errors
      await PlatformLoggingService.logEvent(
        eventType: 'vote_error',
        message: 'Failed to cast vote: ${e.toString()}',
        logLevel: 'error',
        logCategory: 'voting',
        metadata: {'election_id': electionId, 'error': e.toString()},
      );

      return (success: false, errorMessage: e.toString(), receipt: null);
    }
  }

  /// Backwards-compatible wrapper used by existing callers.
  /// Returns only a boolean, but internally records hashes and ZK metadata.
  Future<bool> castVote({
    required String electionId,
    String? selectedOptionId,
    List<String>? rankedChoices,
    List<String>? selectedOptions,
    Map<String, dynamic>? voteScores,
  }) async {
    final result = await castVoteWithReceipt(
      electionId: electionId,
      selectedOptionId: selectedOptionId,
      rankedChoices: rankedChoices,
      selectedOptions: selectedOptions,
      voteScores: voteScores,
    );
    return result.success;
  }

  Future<bool> hasUserVoted(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final response = await _client
          .from('votes')
          .select('id')
          .eq('election_id', electionId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check vote error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getUserVoteHistory({
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('votes')
          .select('*, elections(*)')
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get vote history error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getElectionResults(String electionId) async {
    try {
      final votes = await _client
          .from('votes')
          .select('selected_option_id')
          .eq('election_id', electionId);

      final options = await getElectionOptions(electionId);

      final Map<String, int> voteCounts = {};
      for (var vote in votes) {
        final optionId = vote['selected_option_id'] as String?;
        if (optionId != null) {
          voteCounts[optionId] = (voteCounts[optionId] ?? 0) + 1;
        }
      }

      final totalVotes = votes.length;
      final results = options.map((option) {
        final optionId = option['id'] as String;
        final voteCount = voteCounts[optionId] ?? 0;
        final percentage = totalVotes > 0
            ? (voteCount / totalVotes * 100)
            : 0.0;

        return {...option, 'vote_count': voteCount, 'percentage': percentage};
      }).toList();

      results.sort(
        (a, b) => (b['vote_count'] as int).compareTo(a['vote_count'] as int),
      );

      return {'total_votes': totalVotes, 'results': results};
    } catch (e) {
      debugPrint('Get election results error: $e');
      return {'total_votes': 0, 'results': []};
    }
  }

  Future<String?> createElection(Map<String, dynamic> electionData) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated to create elections');
      }

      final response = await _client
          .from('elections')
          .insert(electionData)
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Create election error: $e');
      return null;
    }
  }

  /// Clone/Copy an election – creates a new draft with same config and options.
  /// Votes and winners are not copied.
  Future<String?> cloneElection(String electionId) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated to clone elections');
      }

      final userId = _auth.currentUser!.id;

      final source = await _client
          .from('elections')
          .select('*, election_options(*)')
          .eq('id', electionId)
          .single();

      if (source == null) throw Exception('Election not found');
      if (source['created_by'] != userId) {
        throw Exception('Only the creator can clone this election');
      }

      final options = source['election_options'] as List<dynamic>? ?? [];
      final uniqueId =
          'ELEC-${DateTime.now().year}-${DateTime.now().millisecond.toString().padLeft(6, '0')}';
      final electionUrl = 'https://vottery.com/vote/$uniqueId';

      final src = Map<String, dynamic>.from(source);
      src.remove('election_options');
      src.remove('id');
      src.remove('created_at');
      src.remove('updated_at');
      final newElection = {
        ...src,
        'vote_count': 0,
        'status': 'draft',
        'unique_election_id': uniqueId,
        'election_url': electionUrl,
        'qr_code_data': electionUrl,
        'title': '${source['title'] ?? 'Election'} (Copy)',
        'winner_notifications': null,
        'winners_announced': false,
      };

      final created = await _client
          .from('elections')
          .insert(newElection)
          .select()
          .single() as Map<String, dynamic>;

      final newElectionId = created['id'] as String;

      if (options.isNotEmpty) {
        final newOptions = options.map((o) {
          final m = Map<String, dynamic>.from(o as Map);
          m.remove('id');
          m.remove('election_id');
          m['election_id'] = newElectionId;
          return m;
        }).toList();
        await _client.from('election_options').insert(newOptions);
      }

      return newElectionId;
    } catch (e) {
      debugPrint('Clone election error: $e');
      return null;
    }
  }

  /// Clone election as run-off with only the given option IDs (creator only). Parity with Web.
  Future<String?> cloneRunoff(String electionId, List<String> optionIds) async {
    try {
      if (!_auth.isAuthenticated) return null;
      final userId = _auth.currentUser!.id;

      final source = await _client
          .from('elections')
          .select('*, election_options(*)')
          .eq('id', electionId)
          .single() as Map<String, dynamic>?;

      if (source == null) return null;
      final creatorId = source['creator_id'] ?? source['created_by'];
      if (creatorId != userId) return null;

      final allOptions = List<Map<String, dynamic>>.from(
          (source['election_options'] as List<dynamic>?) ?? []);
      final idsSet = optionIds.toSet();
      final optionsToClone = idsSet.isEmpty
          ? allOptions
          : allOptions.where((o) => idsSet.contains(o['id']?.toString())).toList();
      if (optionsToClone.isEmpty) return null;

      final uniqueId =
          'ELEC-${DateTime.now().year}-${DateTime.now().millisecond.toString().padLeft(6, '0')}';
      final electionUrl = 'https://vottery.com/vote/$uniqueId';
      final src = Map<String, dynamic>.from(source);
      src.remove('election_options');
      src.remove('id');
      src.remove('created_at');
      src.remove('updated_at');
      final newElection = {
        ...src,
        'vote_count': 0,
        'status': 'draft',
        'unique_election_id': uniqueId,
        'election_url': electionUrl,
        'qr_code_data': electionUrl,
        'title': 'Run-off: ${source['title'] ?? 'Election'}',
        'winner_notifications': null,
        'winners_announced': false,
      };

      final created = await _client
          .from('elections')
          .insert(newElection)
          .select()
          .single() as Map<String, dynamic>;
      final newElectionId = created['id'] as String;

      final newOptions = optionsToClone.map((o) {
        final m = Map<String, dynamic>.from(o);
        m.remove('id');
        m.remove('election_id');
        m['election_id'] = newElectionId;
        m['vote_count'] = 0;
        return m;
      }).toList();
      if (newOptions.isNotEmpty) {
        await _client.from('election_options').insert(newOptions);
      }
      return newElectionId;
    } catch (e) {
      debugPrint('Clone runoff error: $e');
      return null;
    }
  }

  /// Trigger participation fee refunds for an election by calling the
  /// refund-election-participation-fees Edge Function.
  /// Intended to be used when an election is canceled or fails.
  Future<bool> refundParticipationFeesForElection(
    String electionId, {
    String reason = 'canceled',
  }) async {
    try {
      if (electionId.isEmpty) {
        throw Exception('electionId is required');
      }

      final response = await _client.functions.invoke(
        'refund-election-participation-fees',
        body: {
          'electionId': electionId,
          'reason': reason,
        },
      );

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      return true;
    } catch (e) {
      debugPrint('Refund participation fees error: $e');
      return false;
    }
  }

  Future<bool> addElectionOption({
    required String electionId,
    required String optionText,
    String? description,
    String? imageUrl,
    int? displayOrder,
  }) async {
    try {
      final optionData = {
        'election_id': electionId,
        'option_text': optionText,
        'description': description,
        'image_url': imageUrl,
        'display_order': displayOrder ?? 0,
      };

      await _client.from('election_options').insert(optionData);
      return true;
    } catch (e) {
      debugPrint('Add election option error: $e');
      return false;
    }
  }
}
