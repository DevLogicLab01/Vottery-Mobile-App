import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './auth_service.dart';
import './supabase_service.dart';

/// Bucket name for voice messages (must exist in Supabase Storage).
const String voiceMessagesBucket = 'voice_messages';

class MessagingService {
  static MessagingService? _instance;
  static MessagingService get instance => _instance ??= MessagingService._();

  MessagingService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  final Connectivity _connectivity = Connectivity();

  final Map<String, RealtimeChannel> _conversationChannels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _messageStreams =
      {};
  final Map<String, StreamController<List<String>>> _typingStreams = {};
  final Map<String, RealtimeChannel> _typingChannels = {};
  final Map<String, RealtimeChannel> _broadcastTypingChannels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _broadcastTypingStreams = {};

  static const String _offlineQueueKey = 'offline_message_queue';

  /// Get or create conversation
  Future<String?> getOrCreateConversation(List<String> participantIds) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Check if conversation exists
      final existing = await _client
          .from('conversations')
          .select()
          .contains('participant_ids', participantIds)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      // Create new conversation
      final response = await _client
          .from('conversations')
          .insert({'participant_ids': participantIds})
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Get or create conversation error: $e');
      return null;
    }
  }

  /// Send message (supports voice via mediaUrl + metadata.duration for Web parity).
  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        await _addToOfflineQueue(
          conversationId: conversationId,
          content: content,
          messageType: messageType,
          mediaUrl: mediaUrl,
        );
        return true;
      }

      final payload = <String, dynamic>{
        'conversation_id': conversationId,
        'sender_id': _auth.currentUser!.id,
        'message_type': messageType,
        'content': content,
        'media_url': mediaUrl,
      };
      if (metadata != null && metadata.isNotEmpty) {
        payload['metadata'] = metadata;
      }
      try {
        await _client.from('messages').insert(payload);
      } catch (e) {
        if (metadata != null && metadata.isNotEmpty) {
          payload.remove('metadata');
          await _client.from('messages').insert(payload);
        } else {
          rethrow;
        }
      }

      await _client
          .from('conversations')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);

      return true;
    } catch (e) {
      debugPrint('Send message error: $e');
      await _addToOfflineQueue(
        conversationId: conversationId,
        content: content,
        messageType: messageType,
        mediaUrl: mediaUrl,
      );
      return false;
    }
  }

  /// Add message to offline queue
  Future<void> _addToOfflineQueue({
    required String conversationId,
    required String content,
    String messageType = 'text',
    String? mediaUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_offlineQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(json.decode(queueJson));

      queue.add({
        'conversation_id': conversationId,
        'content': content,
        'message_type': messageType,
        'media_url': mediaUrl,
        'queued_at': DateTime.now().toIso8601String(),
        'retry_count': 0,
      });

      await prefs.setString(_offlineQueueKey, json.encode(queue));
      debugPrint('Message added to offline queue');
    } catch (e) {
      debugPrint('Add to offline queue error: $e');
    }
  }

  /// Sync offline messages
  Future<Map<String, dynamic>> syncOfflineMessages() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return {'success': false, 'message': 'No internet connection'};
      }

      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_offlineQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(json.decode(queueJson));

      if (queue.isEmpty) {
        return {'success': true, 'synced': 0, 'failed': 0};
      }

      int synced = 0;
      int failed = 0;
      final List<Map<String, dynamic>> failedMessages = [];

      for (var message in queue) {
        final success = await sendMessage(
          conversationId: message['conversation_id'],
          content: message['content'],
          messageType: message['message_type'] ?? 'text',
          mediaUrl: message['media_url'],
        );

        if (success) {
          synced++;
        } else {
          failed++;
          message['retry_count'] = (message['retry_count'] ?? 0) + 1;
          if (message['retry_count'] < 3) {
            failedMessages.add(message);
          }
        }
      }

      await prefs.setString(_offlineQueueKey, json.encode(failedMessages));
      return {'success': true, 'synced': synced, 'failed': failed};
    } catch (e) {
      debugPrint('Sync offline messages error: $e');
      return {'success': false, 'message': 'Sync error: $e'};
    }
  }

  /// Get pending offline messages count
  Future<int> getOfflineQueueCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_offlineQueueKey) ?? '[]';
      final queue = List<dynamic>.from(json.decode(queueJson));
      return queue.length;
    } catch (e) {
      debugPrint('Get offline queue count error: $e');
      return 0;
    }
  }

  /// Get conversation messages
  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await _client
          .from('messages')
          .select('*, sender:user_profiles!sender_id(*)')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get messages error: $e');
      return [];
    }
  }

  /// Subscribe to conversation
  Stream<Map<String, dynamic>>? subscribeToConversation(String conversationId) {
    try {
      if (_messageStreams.containsKey(conversationId)) {
        return _messageStreams[conversationId]!.stream;
      }

      final streamController =
          StreamController<Map<String, dynamic>>.broadcast();
      _messageStreams[conversationId] = streamController;

      final channel = _client.channel('conversation:$conversationId');

      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) {
              streamController.add(payload.newRecord);
            },
          )
          .subscribe();

      _conversationChannels[conversationId] = channel;

      return streamController.stream;
    } catch (e) {
      debugPrint('Subscribe to conversation error: $e');
      return null;
    }
  }

  /// Subscribe to typing indicators
  Stream<List<String>>? subscribeToTypingIndicators(String conversationId) {
    try {
      if (_typingStreams.containsKey(conversationId)) {
        return _typingStreams[conversationId]!.stream;
      }

      final streamController = StreamController<List<String>>.broadcast();
      _typingStreams[conversationId] = streamController;

      final channel = _client.channel('typing:$conversationId');

      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'typing_indicators',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'conversation_id',
              value: conversationId,
            ),
            callback: (payload) async {
              // Fetch current typing users
              final typingUsers = await _getTypingUsers(conversationId);
              streamController.add(typingUsers);
            },
          )
          .subscribe();

      _typingChannels[conversationId] = channel;

      return streamController.stream;
    } catch (e) {
      debugPrint('Subscribe to typing indicators error: $e');
      return null;
    }
  }

  /// Get typing users
  Future<List<String>> _getTypingUsers(String conversationId) async {
    try {
      final response = await _client
          .from('typing_indicators')
          .select('user_id, users:user_profiles!user_id(email)')
          .eq('conversation_id', conversationId)
          .eq('is_typing', true);

      return List<String>.from(
        response.map((e) => e['users']?['email']?.split('@')[0] ?? 'User'),
      );
    } catch (e) {
      debugPrint('Get typing users error: $e');
      return [];
    }
  }

  /// Set typing indicator
  Future<void> setTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.rpc(
        'set_typing_indicator',
        params: {
          'p_conversation_id': conversationId,
          'p_user_id': _auth.currentUser!.id,
          'p_is_typing': isTyping,
        },
      );
    } catch (e) {
      debugPrint('Set typing indicator error: $e');
    }
  }

  /// Send typing indicator via broadcast (same protocol as Web: dm-typing-{id}, event 'typing').
  Future<void> sendTypingIndicatorBroadcast({
    required String conversationId,
    required bool isTyping,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      RealtimeChannel? channel = _broadcastTypingChannels[conversationId];
      if (channel == null) {
        channel = _client.channel('dm-typing-$conversationId');
        channel.subscribe();
        _broadcastTypingChannels[conversationId] = channel;
      }

      await channel.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'threadId': conversationId,
          'userId': _auth.currentUser!.id,
          'isTyping': isTyping,
          'ts': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Send typing broadcast error: $e');
    }
  }

  /// Subscribe to typing broadcast (Web-compatible: dm-typing-{id}, event 'typing').
  Stream<Map<String, dynamic>>? subscribeToTypingBroadcast(
    String conversationId,
  ) {
    try {
      if (_broadcastTypingStreams.containsKey(conversationId)) {
        return _broadcastTypingStreams[conversationId]!.stream;
      }

      final streamController =
          StreamController<Map<String, dynamic>>.broadcast();
      _broadcastTypingStreams[conversationId] = streamController;

      final channel = _client.channel('dm-typing-$conversationId');
      channel.onBroadcast(
        event: 'typing',
        callback: (payload) {
          streamController.add(Map<String, dynamic>.from(payload));
        },
      ).subscribe();

      _broadcastTypingChannels[conversationId] = channel;

      return streamController.stream;
    } catch (e) {
      debugPrint('Subscribe to typing broadcast error: $e');
      return null;
    }
  }

  /// Upload voice file to Supabase Storage (bucket: voice_messages) and return public URL.
  Future<String?> uploadVoiceMessage({
    required String conversationId,
    required String filePath,
    String? fileName,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();

      final name = fileName ??
          'voice-$conversationId-${DateTime.now().millisecondsSinceEpoch}.m4a';
      final storagePath = '$conversationId/$name';
      await _client.storage.from(voiceMessagesBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: false,
            ),
          );

      final publicUrl =
          _client.storage.from(voiceMessagesBucket).getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload voice message error: $e');
      return null;
    }
  }

  /// Upload image/video attachment for a conversation and return public URL.
  Future<String?> uploadConversationMedia({
    required String conversationId,
    required String filePath,
    required String mediaType,
    String? fileName,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final file = File(filePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();

      final extension = file.path.split('.').last.toLowerCase();
      final safeType = mediaType == 'video' ? 'video' : 'image';
      final generatedName = fileName ??
          '$safeType-$conversationId-${DateTime.now().millisecondsSinceEpoch}.$extension';
      final storagePath = '$conversationId/$generatedName';
      final contentType = _inferContentType(extension, safeType);

      await _client.storage.from(voiceMessagesBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: false,
            ),
          );

      return _client.storage.from(voiceMessagesBucket).getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Upload conversation media error: $e');
      return null;
    }
  }

  String _inferContentType(String extension, String mediaType) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      default:
        return mediaType == 'video'
            ? 'application/octet-stream'
            : 'image/jpeg';
    }
  }

  /// Update user presence
  Future<void> updateUserPresence(String status) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.rpc(
        'update_user_presence',
        params: {'p_user_id': _auth.currentUser!.id, 'p_status': status},
      );
    } catch (e) {
      debugPrint('Update user presence error: $e');
    }
  }

  /// Get user presence
  Future<Map<String, dynamic>?> getUserPresence(String userId) async {
    try {
      final response = await _client
          .from('user_presence')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get user presence error: $e');
      return null;
    }
  }

  /// Unsubscribe from conversation
  Future<void> unsubscribeFromConversation(String conversationId) async {
    try {
      await _conversationChannels[conversationId]?.unsubscribe();
      _conversationChannels.remove(conversationId);
      await _messageStreams[conversationId]?.close();
      _messageStreams.remove(conversationId);

      await _typingChannels[conversationId]?.unsubscribe();
      _typingChannels.remove(conversationId);
      await _typingStreams[conversationId]?.close();
      _typingStreams.remove(conversationId);

      await _broadcastTypingChannels[conversationId]?.unsubscribe();
      _broadcastTypingChannels.remove(conversationId);
      await _broadcastTypingStreams[conversationId]?.close();
      _broadcastTypingStreams.remove(conversationId);
    } catch (e) {
      debugPrint('Unsubscribe from conversation error: $e');
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String conversationId) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.rpc(
        'mark_messages_read',
        params: {
          'conversation_id_param': conversationId,
          'user_id_param': _auth.currentUser!.id,
        },
      );
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  /// Get user conversations
  Future<List<Map<String, dynamic>>> getUserConversations() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('conversations')
          .select()
          .contains('participant_ids', [_auth.currentUser!.id])
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user conversations error: $e');
      return [];
    }
  }

  /// Get unread count for conversation
  Future<int> getUnreadCount(String conversationId) async {
    try {
      if (!_auth.isAuthenticated) return 0;

      final result = await _client.rpc(
        'get_unread_count',
        params: {
          'p_conversation_id': conversationId,
          'p_user_id': _auth.currentUser!.id,
        },
      );

      return result as int? ?? 0;
    } catch (e) {
      debugPrint('Get unread count error: $e');
      return 0;
    }
  }

  /// Add reaction to message (Web parity: reaction_emoji column).
  Future<bool> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': _auth.currentUser!.id,
        'reaction_emoji': emoji,
      });

      return true;
    } catch (e) {
      debugPrint('Add reaction error: $e');
      return false;
    }
  }

  /// Remove reaction (Web parity).
  Future<bool> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', _auth.currentUser!.id)
          .eq('reaction_emoji', emoji);

      return true;
    } catch (e) {
      debugPrint('Remove reaction error: $e');
      return false;
    }
  }

  /// Get reactions for a message (Web parity).
  Future<List<Map<String, dynamic>>> getMessageReactions(String messageId) async {
    try {
      final res = await _client
          .from('message_reactions')
          .select('*')
          .eq('message_id', messageId);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Get message reactions error: $e');
      return [];
    }
  }

  /// Get reactions for multiple messages (batch for UI).
  Future<Map<String, List<Map<String, dynamic>>>> getReactionsForMessageIds(
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return {};
    try {
      final res = await _client
          .from('message_reactions')
          .select('*')
          .inFilter('message_id', messageIds);
      final list = List<Map<String, dynamic>>.from(res);
      final map = <String, List<Map<String, dynamic>>>{};
      for (final r in list) {
        final id = r['message_id'] as String?;
        if (id != null) (map[id] ??= []).add(r);
      }
      return map;
    } catch (e) {
      debugPrint('Get reactions for messages error: $e');
      return {};
    }
  }

  /// Get thread media gallery (Web parity: message_media_gallery, thread_id = conversationId).
  Future<List<Map<String, dynamic>>> getThreadMedia(String conversationId) async {
    try {
      final res = await _client
          .from('message_media_gallery')
          .select('*')
          .eq('thread_id', conversationId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Get thread media error: $e');
      return [];
    }
  }

  /// Add media to gallery after sending (Web parity).
  Future<bool> addMediaToGallery({
    required String conversationId,
    required String messageId,
    required String mediaType,
    required String mediaUrl,
    String? mediaAlt,
    String? thumbnailUrl,
    int? fileSize,
    int? duration,
  }) async {
    try {
      await _client.from('message_media_gallery').insert({
        'thread_id': conversationId,
        'message_id': messageId,
        'media_type': mediaType,
        'media_url': mediaUrl,
        'media_alt': mediaAlt,
        'thumbnail_url': thumbnailUrl,
        'file_size': fileSize,
        'duration': duration,
      });
      return true;
    } catch (e) {
      debugPrint('Add media to gallery error: $e');
      return false;
    }
  }
}
