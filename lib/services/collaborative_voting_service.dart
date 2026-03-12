import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Service for collaborative voting room real-time communications
class CollaborativeVotingService {
  static CollaborativeVotingService? _instance;
  static CollaborativeVotingService get instance =>
      _instance ??= CollaborativeVotingService._();

  CollaborativeVotingService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  final Map<String, RealtimeChannel> _roomChannels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _messageStreams =
      {};
  final Map<String, StreamController<List<Map<String, dynamic>>>>
  _participantStreams = {};

  /// Join a collaborative voting room
  Future<bool> joinRoom(String roomId) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated to join rooms');
      }

      // Create realtime channel for this room
      final channel = _client.channel('room:$roomId');

      // Initialize stream controllers
      _messageStreams[roomId] =
          StreamController<Map<String, dynamic>>.broadcast();
      _participantStreams[roomId] =
          StreamController<List<Map<String, dynamic>>>.broadcast();

      // Subscribe to room messages
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'room_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (payload) {
              _messageStreams[roomId]?.add(payload.newRecord);
            },
          )
          .subscribe();

      _roomChannels[roomId] = channel;

      // Add user to participants
      await _client.from('room_participants').insert({
        'room_id': roomId,
        'user_id': _auth.currentUser!.id,
        'joined_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Join room error: $e');
      return false;
    }
  }

  /// Leave a collaborative voting room
  Future<bool> leaveRoom(String roomId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Remove from participants
      await _client
          .from('room_participants')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', _auth.currentUser!.id);

      // Unsubscribe from channel
      await _roomChannels[roomId]?.unsubscribe();
      _roomChannels.remove(roomId);

      // Close streams
      await _messageStreams[roomId]?.close();
      _messageStreams.remove(roomId);
      await _participantStreams[roomId]?.close();
      _participantStreams.remove(roomId);

      return true;
    } catch (e) {
      debugPrint('Leave room error: $e');
      return false;
    }
  }

  /// Send message to room
  Future<bool> sendMessage({
    required String roomId,
    required String message,
    String? replyToId,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('room_messages').insert({
        'room_id': roomId,
        'user_id': _auth.currentUser!.id,
        'message': message,
        'reply_to_id': replyToId,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Send message error: $e');
      return false;
    }
  }

  /// Add reaction to message
  Future<bool> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': _auth.currentUser!.id,
        'emoji': emoji,
      });

      return true;
    } catch (e) {
      debugPrint('Add reaction error: $e');
      return false;
    }
  }

  /// Get room messages
  Future<List<Map<String, dynamic>>> getRoomMessages(String roomId) async {
    try {
      final response = await _client
          .from('room_messages')
          .select('*, users(id, email)')
          .eq('room_id', roomId)
          .order('created_at', ascending: true)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get room messages error: $e');
      return [];
    }
  }

  /// Get room participants
  Future<List<Map<String, dynamic>>> getRoomParticipants(String roomId) async {
    try {
      final response = await _client
          .from('room_participants')
          .select('*, users(id, email)')
          .eq('room_id', roomId)
          .order('joined_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get room participants error: $e');
      return [];
    }
  }

  /// Stream of new messages for a room
  Stream<Map<String, dynamic>>? getMessageStream(String roomId) {
    return _messageStreams[roomId]?.stream;
  }

  /// Mute participant (moderator only)
  Future<bool> muteParticipant({
    required String roomId,
    required String userId,
  }) async {
    try {
      await _client
          .from('room_participants')
          .update({'is_muted': true})
          .eq('room_id', roomId)
          .eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Mute participant error: $e');
      return false;
    }
  }

  /// Update option suggestion
  Future<bool> suggestOptionModification({
    required String roomId,
    required String optionId,
    required String suggestion,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('option_suggestions').insert({
        'room_id': roomId,
        'option_id': optionId,
        'user_id': _auth.currentUser!.id,
        'suggestion': suggestion,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Suggest option modification error: $e');
      return false;
    }
  }

  /// Get option suggestions
  Future<List<Map<String, dynamic>>> getOptionSuggestions({
    required String roomId,
    required String optionId,
  }) async {
    try {
      final response = await _client
          .from('option_suggestions')
          .select('*, users(id, email)')
          .eq('room_id', roomId)
          .eq('option_id', optionId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get option suggestions error: $e');
      return [];
    }
  }
}
