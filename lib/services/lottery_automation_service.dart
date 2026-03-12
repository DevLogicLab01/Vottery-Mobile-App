import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './messaging_service.dart';

class LotteryAutomationService {
  static LotteryAutomationService? _instance;
  static LotteryAutomationService get instance =>
      _instance ??= LotteryAutomationService._();

  LotteryAutomationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  MessagingService get _messaging => MessagingService.instance;

  /// Generate voter ID for user after vote submission
  Future<String?> generateVoterID(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final result = await _client.rpc(
        'generate_voter_id',
        params: {
          'p_election_id': electionId,
          'p_user_id': _auth.currentUser!.id,
        },
      );

      return result as String?;
    } catch (e) {
      debugPrint('Generate voter ID error: $e');
      return null;
    }
  }

  /// Get voter ID for user in election
  Future<Map<String, dynamic>?> getVoterID(String electionId) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('voter_ids')
          .select()
          .eq('election_id', electionId)
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get voter ID error: $e');
      return null;
    }
  }

  /// Get slot machine state for election
  Future<Map<String, dynamic>?> getSlotMachineState(String electionId) async {
    try {
      final response = await _client
          .from('slot_machine_state')
          .select()
          .eq('election_id', electionId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get slot machine state error: $e');
      return null;
    }
  }

  /// Get all voter IDs for election (for slot machine display)
  Future<List<String>> getAllVoterIDsForElection(String electionId) async {
    try {
      final response = await _client
          .from('voter_ids')
          .select('voter_id_number')
          .eq('election_id', electionId)
          .order('sequential_number', ascending: true);

      return List<String>.from(
        response.map((item) => item['voter_id_number'] as String),
      );
    } catch (e) {
      debugPrint('Get all voter IDs error: $e');
      return [];
    }
  }

  /// Get lottery winners for election
  Future<List<Map<String, dynamic>>> getLotteryWinners(
    String electionId,
  ) async {
    try {
      final lotteryDraw = await _client
          .from('lottery_draws')
          .select()
          .eq('election_id', electionId)
          .maybeSingle();

      if (lotteryDraw == null) return [];

      final response = await _client
          .from('lottery_winners')
          .select('*, user_profiles(*)')
          .eq('lottery_id', lotteryDraw['id'])
          .order('winning_position', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get lottery winners error: $e');
      return [];
    }
  }

  /// Send winner notification to personal message box
  Future<bool> sendWinnerNotification({
    required String winnerId,
    required String electionTitle,
    required double prizeAmount,
    required int winningPosition,
  }) async {
    try {
      // Create conversation with winner
      final conversationId = await _messaging.getOrCreateConversation([
        winnerId,
      ]);

      if (conversationId == null) return false;

      // Send congratulations message
      final message =
          '🎉 Congratulations! You won ${_getPositionSuffix(winningPosition)} place in "$electionTitle"!\n\n💰 Prize: \$${prizeAmount.toStringAsFixed(2)}\n\nYour prize will be processed shortly. Check your wallet for updates.';

      final success = await _messaging.sendMessage(
        conversationId: conversationId,
        content: message,
        messageType: 'winner_notification',
      );

      return success;
    } catch (e) {
      debugPrint('Send winner notification error: $e');
      return false;
    }
  }

  String _getPositionSuffix(int position) {
    if (position == 1) return '1st';
    if (position == 2) return '2nd';
    if (position == 3) return '3rd';
    return '${position}th';
  }

  /// Check if creator is blacklisted
  Future<bool> isCreatorBlacklisted(String creatorId) async {
    try {
      final response = await _client
          .from('creator_blacklist')
          .select()
          .eq('creator_id', creatorId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Check creator blacklist error: $e');
      return false;
    }
  }

  /// Blacklist creator for not distributing prizes
  Future<bool> blacklistCreator({
    required String creatorId,
    required String reason,
    String? electionId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('creator_blacklist').insert({
        'creator_id': creatorId,
        'reason': reason,
        'election_id': electionId,
        'blacklisted_by': _auth.currentUser!.id,
      });

      return true;
    } catch (e) {
      debugPrint('Blacklist creator error: $e');
      return false;
    }
  }
}
