import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import './supabase_service.dart';
import './auth_service.dart';
import './twilio_notification_service.dart';

/// Team Incident War Room Service
/// Manages collaborative incident response workspaces
class TeamIncidentWarRoomService {
  static TeamIncidentWarRoomService? _instance;
  static TeamIncidentWarRoomService get instance =>
      _instance ??= TeamIncidentWarRoomService._();

  TeamIncidentWarRoomService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  TwilioNotificationService get _twilio => TwilioNotificationService.instance;

  List<String> getChannelPolicyForSeverity(String? severity) {
    final normalized = _normalizeSeverity(severity);
    switch (normalized) {
      case 'critical':
        return const ['email', 'sms', 'push', 'slack'];
      case 'high':
        return const ['email', 'sms', 'push'];
      case 'medium':
        return const ['email', 'push'];
      case 'low':
      default:
        return const ['email'];
    }
  }

  String _normalizeSeverity(String? severity) {
    final raw = (severity ?? 'medium').toLowerCase();
    if (raw == 'p0' || raw == 'critical') return 'critical';
    if (raw == 'p1' || raw == 'high') return 'high';
    if (raw == 'p2' || raw == 'medium') return 'medium';
    if (raw == 'p3' || raw == 'low') return 'low';
    return 'medium';
  }

  Future<Map<String, dynamic>> sendStakeholderIncidentCommunication({
    required String incidentId,
    required String severity,
    required String title,
    required String message,
    required List<Map<String, dynamic>> recipients,
  }) async {
    try {
      final channels = getChannelPolicyForSeverity(severity);
      final nowIso = DateTime.now().toIso8601String();
      final sent = <Map<String, dynamic>>[];

      for (final recipient in recipients) {
        final recipientId = recipient['user_id']?.toString();
        if (recipientId == null || recipientId.isEmpty) {
          continue;
        }

        await _client.from('incident_communications').insert({
          'incident_id': incidentId,
          'recipient_type': recipient['role'] ?? 'stakeholder',
          'communication_type': channels.join(','),
          'message_subject': title,
          'message_content': message,
          'recipients': [recipient],
          'delivery_status': 'sent',
          'sent_at': nowIso,
          'metadata': {
            'severity': _normalizeSeverity(severity),
            'channels': channels,
          },
        });

        if (channels.contains('sms')) {
          final phone = recipient['phone']?.toString();
          if (phone != null && phone.isNotEmpty) {
            await _twilio.sendUserActivityNotification(
              phoneNumber: phone,
              activityType: 'Incident ${_normalizeSeverity(severity).toUpperCase()}',
              details: message,
            );
          }
        }

        sent.add({'recipient_id': recipientId, 'channels': channels});
      }

      return {'success': true, 'sent': sent, 'channel_policy': channels};
    } catch (e) {
      debugPrint('❌ Send stakeholder incident communication error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Create war room for incident
  Future<Map<String, dynamic>> createWarRoom({
    required String incidentId,
    required String incidentType,
    List<String>? affectedSystems,
  }) async {
    try {
      debugPrint('🚨 Creating war room for incident: $incidentId');

      // Create war room
      final warRoom = await _client
          .from('war_rooms')
          .insert({
            'incident_id': incidentId,
            'room_name': 'Incident Response: ${incidentType.toUpperCase()}',
            'status': 'active',
          })
          .select()
          .single();

      final roomId = warRoom['room_id'];

      // Assemble team based on incident type
      final teamMembers = await _assembleTeam(incidentType, affectedSystems);

      // Add team members
      for (final member in teamMembers) {
        await _client.from('war_room_members').insert({
          'room_id': roomId,
          'user_id': member['user_id'],
          'role': member['role'],
          'status': 'online',
        });

        // Send invitation notification
        await _sendInvitation(member['user_id'], roomId, incidentType);
      }

      // Log activity
      await _logActivity(
        roomId: roomId,
        activityType: 'war_room_created',
        description: 'War room created for $incidentType incident',
      );

      debugPrint(
        '✅ War room created: $roomId with ${teamMembers.length} members',
      );

      return {
        'success': true,
        'room_id': roomId,
        'team_size': teamMembers.length,
      };
    } catch (e) {
      debugPrint('❌ Create war room error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Send message to war room
  Future<bool> sendMessage({
    required String roomId,
    required String messageText,
    List<String>? attachments,
    List<String>? mentions,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('war_room_messages').insert({
        'room_id': roomId,
        'sender_id': _auth.currentUser!.id,
        'message_text': messageText,
        'attachments': attachments,
        'mentions': mentions,
      });

      // Send notifications to mentioned users
      if (mentions != null && mentions.isNotEmpty) {
        for (final userId in mentions) {
          await _notifyMention(userId, roomId, messageText);
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Send message error: $e');
      return false;
    }
  }

  /// Create task in war room
  Future<Map<String, dynamic>> createTask({
    required String roomId,
    required String title,
    String? description,
    String? assignedTo,
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final task = await _client
          .from('war_room_tasks')
          .insert({
            'room_id': roomId,
            'title': title,
            'description': description,
            'assigned_to': assignedTo,
            'priority': priority,
            'status': 'todo',
            'due_date': dueDate?.toIso8601String(),
            'created_by': _auth.currentUser!.id,
          })
          .select()
          .single();

      // Log activity
      await _logActivity(
        roomId: roomId,
        activityType: 'task_created',
        description: 'Task created: $title',
        metadata: {'task_id': task['task_id']},
      );

      // Notify assigned user
      if (assignedTo != null) {
        await _notifyTaskAssignment(assignedTo, roomId, title);
      }

      return {'success': true, 'task': task};
    } catch (e) {
      debugPrint('❌ Create task error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Update task status
  Future<bool> updateTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      await _client
          .from('war_room_tasks')
          .update({
            'status': status,
            if (status == 'done')
              'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('task_id', taskId);

      return true;
    } catch (e) {
      debugPrint('❌ Update task status error: $e');
      return false;
    }
  }

  /// Record decision
  Future<bool> recordDecision({
    required String roomId,
    required String decisionText,
    String? rationale,
    bool requiresApproval = false,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('war_room_decisions').insert({
        'room_id': roomId,
        'decision_text': decisionText,
        'made_by': _auth.currentUser!.id,
        'rationale': rationale,
        'approval_status': requiresApproval ? 'pending' : 'approved',
      });

      // Log activity
      await _logActivity(
        roomId: roomId,
        activityType: 'decision_made',
        description: 'Decision recorded: $decisionText',
      );

      return true;
    } catch (e) {
      debugPrint('❌ Record decision error: $e');
      return false;
    }
  }

  /// Upload evidence
  Future<Map<String, dynamic>> uploadEvidence({
    required String roomId,
    required String fileName,
    required String fileUrl,
    String? fileType,
    List<String>? tags,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'error': 'Not authenticated'};
      }

      final evidence = await _client
          .from('war_room_evidence')
          .insert({
            'room_id': roomId,
            'file_name': fileName,
            'file_url': fileUrl,
            'file_type': fileType,
            'uploaded_by': _auth.currentUser!.id,
            'tags': tags,
          })
          .select()
          .single();

      // Log activity
      await _logActivity(
        roomId: roomId,
        activityType: 'evidence_added',
        description: 'Evidence uploaded: $fileName',
      );

      return {'success': true, 'evidence': evidence};
    } catch (e) {
      debugPrint('❌ Upload evidence error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check for escalation conditions
  Future<void> checkEscalationConditions(String roomId) async {
    try {
      // Get war room details
      final warRoom = await _client
          .from('war_rooms')
          .select()
          .eq('room_id', roomId)
          .single();

      final createdAt = DateTime.parse(warRoom['created_at']);
      final elapsedMinutes = DateTime.now().difference(createdAt).inMinutes;

      // Check for no progress after 30 minutes
      if (elapsedMinutes >= 30) {
        final tasks = await _client
            .from('war_room_tasks')
            .select()
            .eq('room_id', roomId);

        final completedTasks = tasks.where((t) => t['status'] == 'done').length;
        final completionRate = tasks.isNotEmpty
            ? completedTasks / tasks.length
            : 0.0;

        if (completionRate < 0.3) {
          await _escalate(
            roomId: roomId,
            escalationType: 'no_progress',
            reason: 'Task completion rate below 30% after 30 minutes',
          );
        }
      }

      // Check for stalled investigation (no chat activity for 15 minutes)
      final recentMessages = await _client
          .from('war_room_messages')
          .select()
          .eq('room_id', roomId)
          .gte(
            'created_at',
            DateTime.now()
                .subtract(const Duration(minutes: 15))
                .toIso8601String(),
          );

      if (recentMessages.isEmpty && elapsedMinutes >= 15) {
        await _escalate(
          roomId: roomId,
          escalationType: 'stalled_investigation',
          reason: 'No chat activity for 15 minutes',
        );
      }
    } catch (e) {
      debugPrint('❌ Check escalation conditions error: $e');
    }
  }

  /// Close war room
  Future<bool> closeWarRoom({
    required String roomId,
    required String resolutionSummary,
    String? lessonsLearned,
    DateTime? postMortemScheduledAt,
  }) async {
    try {
      await _client
          .from('war_rooms')
          .update({
            'status': 'resolved',
            'closed_at': DateTime.now().toIso8601String(),
            'resolution_summary': resolutionSummary,
            'lessons_learned': lessonsLearned,
            'post_mortem_scheduled_at': postMortemScheduledAt
                ?.toIso8601String(),
          })
          .eq('room_id', roomId);

      // Log activity
      await _logActivity(
        roomId: roomId,
        activityType: 'war_room_closed',
        description: 'War room closed with resolution',
      );

      return true;
    } catch (e) {
      debugPrint('❌ Close war room error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _assembleTeam(
    String incidentType,
    List<String>? affectedSystems,
  ) async {
    // Simplified team assembly - in production, query team_assignment_rules
    final teamMembers = <Map<String, dynamic>>[];

    // Get security team members
    final securityTeam = await _client
        .from('user_profiles')
        .select()
        .eq('role', 'security_admin')
        .limit(3);

    for (final member in securityTeam) {
      teamMembers.add({'user_id': member['id'], 'role': 'Security Analyst'});
    }

    return teamMembers;
  }

  Future<void> _sendInvitation(
    String userId,
    String roomId,
    String incidentType,
  ) async {
    // Send push notification or SMS invitation
    debugPrint('📧 Sending invitation to user: $userId');
  }

  Future<void> _notifyMention(
    String userId,
    String roomId,
    String messageText,
  ) async {
    debugPrint('🔔 Notifying mention to user: $userId');
  }

  Future<void> _notifyTaskAssignment(
    String userId,
    String roomId,
    String taskTitle,
  ) async {
    debugPrint('📝 Notifying task assignment to user: $userId');
  }

  Future<void> _escalate({
    required String roomId,
    required String escalationType,
    required String reason,
  }) async {
    try {
      // Get senior staff to escalate to
      final seniorStaff = await _client
          .from('user_profiles')
          .select()
          .eq('role', 'admin')
          .limit(2);

      final escalatedTo = seniorStaff.map((s) => s['id'] as String).toList();

      await _client.from('war_room_escalations').insert({
        'room_id': roomId,
        'escalation_type': escalationType,
        'reason': reason,
        'escalated_to': escalatedTo,
      });

      // Send SMS notifications
      for (final userId in escalatedTo) {
        debugPrint('🚨 Escalating to user: $userId');
      }

      // Log activity
      await _logActivity(
        roomId: roomId,
        activityType: 'escalation',
        description: 'Incident escalated: $reason',
      );
    } catch (e) {
      debugPrint('❌ Escalate error: $e');
    }
  }

  Future<void> _logActivity({
    required String roomId,
    required String activityType,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('war_room_activity').insert({
        'room_id': roomId,
        'activity_type': activityType,
        'user_id': _auth.currentUser?.id,
        'description': description,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('❌ Log activity error: $e');
    }
  }

  /// Get war room messages stream
  Stream<List<Map<String, dynamic>>> getMessagesStream(String roomId) {
    return _client
        .from('war_room_messages')
        .stream(primaryKey: ['message_id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Get war room tasks stream
  Stream<List<Map<String, dynamic>>> getTasksStream(String roomId) {
    return _client
        .from('war_room_tasks')
        .stream(primaryKey: ['task_id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
