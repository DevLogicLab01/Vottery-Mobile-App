import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './auth_service.dart';

class SupportTicketService {
  static SupportTicketService? _instance;
  static SupportTicketService get instance =>
      _instance ??= SupportTicketService._();

  SupportTicketService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  final Map<String, RealtimeChannel> _ticketChannels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _ticketStreams = {};

  /// Create support ticket
  Future<Map<String, dynamic>?> createTicket({
    required String category,
    required String priority,
    required String subject,
    required String description,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('support_tickets')
          .insert({
            'user_id': _auth.currentUser!.id,
            'category': category,
            'priority': priority,
            'subject': subject,
            'description': description,
          })
          .select()
          .single();

      // Create initial system message
      await _client.from('ticket_messages').insert({
        'ticket_id': response['id'],
        'sender_id': _auth.currentUser!.id,
        'sender_type': 'system',
        'message':
            'Ticket created. Our support team will respond shortly based on your priority level.',
      });

      return response;
    } catch (e) {
      debugPrint('Create ticket error: $e');
      return null;
    }
  }

  /// Get user tickets
  Future<List<Map<String, dynamic>>> getUserTickets({
    String? status,
    String? category,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client
          .from('support_tickets')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get user tickets error: $e');
      return [];
    }
  }

  /// Get ticket details
  Future<Map<String, dynamic>?> getTicketDetails(String ticketId) async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('support_tickets')
          .select()
          .eq('id', ticketId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get ticket details error: $e');
      return null;
    }
  }

  /// Get ticket messages
  Future<List<Map<String, dynamic>>> getTicketMessages(String ticketId) async {
    try {
      final response = await _client
          .from('ticket_messages')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get ticket messages error: $e');
      return [];
    }
  }

  /// Send ticket message
  Future<bool> sendTicketMessage({
    required String ticketId,
    required String message,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('ticket_messages').insert({
        'ticket_id': ticketId,
        'sender_id': _auth.currentUser!.id,
        'sender_type': 'user',
        'message': message,
      });

      // Update ticket status to waiting_for_agent if it was waiting_for_user
      await _client
          .from('support_tickets')
          .update({'status': 'in_progress'})
          .eq('id', ticketId)
          .eq('status', 'waiting_for_user');

      return true;
    } catch (e) {
      debugPrint('Send ticket message error: $e');
      return false;
    }
  }

  /// Upload ticket attachment
  Future<String?> uploadAttachment({
    required String ticketId,
    required String fileName,
    required Uint8List fileBytes,
    required String fileType,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;

      // Check file size (max 10MB)
      if (fileBytes.length > 10 * 1024 * 1024) {
        throw Exception('File size exceeds 10MB limit');
      }

      // Upload to Supabase storage
      final filePath =
          'ticket_attachments/${_auth.currentUser!.id}/$ticketId/$fileName';
      await _client.storage
          .from('support-files')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: FileOptions(contentType: fileType),
          );

      final fileUrl = _client.storage
          .from('support-files')
          .getPublicUrl(filePath);

      // Save attachment record
      await _client.from('ticket_attachments').insert({
        'ticket_id': ticketId,
        'file_name': fileName,
        'file_url': fileUrl,
        'file_size_bytes': fileBytes.length,
        'file_type': fileType,
        'uploaded_by': _auth.currentUser!.id,
      });

      return fileUrl;
    } catch (e) {
      debugPrint('Upload attachment error: $e');
      return null;
    }
  }

  /// Get ticket attachments
  Future<List<Map<String, dynamic>>> getTicketAttachments(
    String ticketId,
  ) async {
    try {
      final response = await _client
          .from('ticket_attachments')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get ticket attachments error: $e');
      return [];
    }
  }

  /// Rate ticket resolution
  Future<bool> rateTicket({
    required String ticketId,
    required int rating,
    String? review,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('support_tickets')
          .update({'satisfaction_rating': rating, 'agent_review': review})
          .eq('id', ticketId);

      return true;
    } catch (e) {
      debugPrint('Rate ticket error: $e');
      return false;
    }
  }

  /// Get FAQ articles
  Future<List<Map<String, dynamic>>> getFAQArticles({
    String? category,
    String? searchQuery,
  }) async {
    try {
      var query = _client.from('faq_articles').select().eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'title.ilike.%$searchQuery%,content.ilike.%$searchQuery%,keywords.cs.{$searchQuery}',
        );
      }

      final response = await query.order('view_count', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get FAQ articles error: $e');
      return [];
    }
  }

  /// Get canned responses
  Future<List<Map<String, dynamic>>> getCannedResponses(String category) async {
    try {
      final response = await _client
          .from('canned_responses')
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('usage_count', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get canned responses error: $e');
      return [];
    }
  }

  /// Subscribe to ticket updates
  Stream<Map<String, dynamic>> subscribeToTicket(String ticketId) {
    if (_ticketStreams.containsKey(ticketId)) {
      return _ticketStreams[ticketId]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _ticketStreams[ticketId] = controller;

    final channel = _client
        .channel('ticket_$ticketId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'support_tickets',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: ticketId,
          ),
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        );

    channel.subscribe();
    _ticketChannels[ticketId] = channel;

    return controller.stream;
  }

  /// Unsubscribe from ticket updates
  void unsubscribeFromTicket(String ticketId) {
    _ticketChannels[ticketId]?.unsubscribe();
    _ticketChannels.remove(ticketId);
    _ticketStreams[ticketId]?.close();
    _ticketStreams.remove(ticketId);
  }

  /// Get ticket analytics
  Future<Map<String, dynamic>> getTicketAnalytics() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final tickets = await getUserTickets();

      final totalTickets = tickets.length;
      final openTickets = tickets.where((t) => t['status'] == 'open').length;
      final resolvedTickets = tickets
          .where((t) => t['status'] == 'resolved')
          .length;
      final avgSatisfaction =
          tickets.where((t) => t['satisfaction_rating'] != null).isEmpty
          ? 0.0
          : tickets
                    .where((t) => t['satisfaction_rating'] != null)
                    .map((t) => t['satisfaction_rating'] as int)
                    .reduce((a, b) => a + b) /
                tickets.where((t) => t['satisfaction_rating'] != null).length;

      return {
        'total_tickets': totalTickets,
        'open_tickets': openTickets,
        'resolved_tickets': resolvedTickets,
        'avg_satisfaction': avgSatisfaction,
      };
    } catch (e) {
      debugPrint('Get ticket analytics error: $e');
      return {};
    }
  }

  /// Dispose
  void dispose() {
    for (final channel in _ticketChannels.values) {
      channel.unsubscribe();
    }
    _ticketChannels.clear();

    for (final controller in _ticketStreams.values) {
      controller.close();
    }
    _ticketStreams.clear();
  }
}
