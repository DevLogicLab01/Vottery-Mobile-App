import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './supabase_service.dart';
import './auth_service.dart';

class PagerDutyService {
  static PagerDutyService? _instance;
  static PagerDutyService get instance => _instance ??= PagerDutyService._();

  PagerDutyService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  static const String apiKey = String.fromEnvironment('PAGERDUTY_API_KEY');
  static const String serviceId = String.fromEnvironment(
    'PAGERDUTY_SERVICE_ID',
  );
  static const String apiUrl = 'https://api.pagerduty.com';

  /// Sync on-call schedules from PagerDuty
  Future<bool> syncOnCallSchedules() async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-pagerduty-api-key-here') {
        return false;
      }

      // Get schedules
      final schedulesResponse = await http.get(
        Uri.parse('$apiUrl/schedules'),
        headers: {
          'Authorization': 'Token token=$apiKey',
          'Accept': 'application/vnd.pagerduty+json;version=2',
        },
      );

      if (schedulesResponse.statusCode == 200) {
        final schedulesData = jsonDecode(schedulesResponse.body);
        final schedules = schedulesData['schedules'] as List<dynamic>? ?? [];

        for (final schedule in schedules) {
          final scheduleId = schedule['id'] as String;
          final scheduleName = schedule['name'] as String;

          // Get current on-call user
          final usersResponse = await http.get(
            Uri.parse('$apiUrl/schedules/$scheduleId/users'),
            headers: {
              'Authorization': 'Token token=$apiKey',
              'Accept': 'application/vnd.pagerduty+json;version=2',
            },
          );

          if (usersResponse.statusCode == 200) {
            final usersData = jsonDecode(usersResponse.body);
            final users = usersData['users'] as List<dynamic>? ?? [];

            if (users.isNotEmpty) {
              final currentUser = users.first;
              await _client.from('on_call_schedules').upsert({
                'schedule_id': scheduleId,
                'schedule_name': scheduleName,
                'current_on_call_user_id': currentUser['email'],
                'on_call_until': DateTime.now()
                    .add(const Duration(days: 7))
                    .toIso8601String(),
                'escalation_policy': schedule['escalation_policies'] ?? {},
                'last_synced_at': DateTime.now().toIso8601String(),
              });
            }
          }
        }

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Sync on-call schedules error: $e');
      return false;
    }
  }

  /// Create PagerDuty incident
  Future<String?> createPagerDutyIncident({
    required String incidentId,
    required String title,
    required String description,
    required String severity,
    required Map<String, dynamic> incidentData,
  }) async {
    try {
      if (apiKey.isEmpty || serviceId.isEmpty) {
        return null;
      }

      // Determine urgency based on severity
      final urgency = (severity == 'P0' || severity == 'critical')
          ? 'high'
          : 'low';

      // Calculate incident key for deduplication
      final incidentKey = _calculateIncidentKey(
        incidentData['incident_type'] ?? 'unknown',
        incidentData['affected_resource'] ?? 'unknown',
      );

      // Check for existing incident with same key
      final existingIncident = await _client
          .from('pagerduty_incidents')
          .select()
          .eq('incident_key', incidentKey)
          .inFilter('status', ['triggered', 'acknowledged'])
          .maybeSingle();

      if (existingIncident != null) {
        // Deduplicate - add note to existing incident
        await _addIncidentNote(
          existingIncident['pagerduty_incident_id'],
          'Similar incident detected at ${DateTime.now().toIso8601String()}',
        );
        return existingIncident['pagerduty_incident_id'];
      }

      // Create new incident
      final response = await http.post(
        Uri.parse('$apiUrl/incidents'),
        headers: {
          'Authorization': 'Token token=$apiKey',
          'Accept': 'application/vnd.pagerduty+json;version=2',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'incident': {
            'type': 'incident',
            'title': title,
            'service': {'id': serviceId, 'type': 'service_reference'},
            'urgency': urgency,
            'body': {'type': 'incident_body', 'details': description},
            'incident_key': incidentKey,
          },
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final pagerdutyIncidentId = data['incident']['id'] as String;

        // Store mapping
        await _client.from('pagerduty_incidents').insert({
          'vottery_incident_id': incidentId,
          'pagerduty_incident_id': pagerdutyIncidentId,
          'incident_key': incidentKey,
          'status': 'triggered',
        });

        return pagerdutyIncidentId;
      }

      return null;
    } catch (e) {
      debugPrint('Create PagerDuty incident error: $e');
      return null;
    }
  }

  /// Calculate incident key for deduplication
  String _calculateIncidentKey(String incidentType, String affectedResource) {
    final key = '$incidentType:$affectedResource';
    return key.replaceAll(RegExp(r'[^a-zA-Z0-9:_-]'), '_');
  }

  /// Add note to existing incident
  Future<void> _addIncidentNote(String incidentId, String note) async {
    try {
      await http.post(
        Uri.parse('$apiUrl/incidents/$incidentId/notes'),
        headers: {
          'Authorization': 'Token token=$apiKey',
          'Accept': 'application/vnd.pagerduty+json;version=2',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'note': {'content': note},
        }),
      );
    } catch (e) {
      debugPrint('Add incident note error: $e');
    }
  }

  /// Acknowledge incident in PagerDuty
  Future<bool> acknowledgeIncident(String pagerdutyIncidentId) async {
    try {
      if (apiKey.isEmpty) return false;

      final response = await http.put(
        Uri.parse('$apiUrl/incidents/$pagerdutyIncidentId'),
        headers: {
          'Authorization': 'Token token=$apiKey',
          'Accept': 'application/vnd.pagerduty+json;version=2',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'incident': {'type': 'incident_reference', 'status': 'acknowledged'},
        }),
      );

      if (response.statusCode == 200) {
        await _client
            .from('pagerduty_incidents')
            .update({
              'status': 'acknowledged',
              'acknowledged_at': DateTime.now().toIso8601String(),
            })
            .eq('pagerduty_incident_id', pagerdutyIncidentId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Acknowledge incident error: $e');
      return false;
    }
  }

  /// Resolve incident in PagerDuty
  Future<bool> resolveIncident(String pagerdutyIncidentId) async {
    try {
      if (apiKey.isEmpty) return false;

      final response = await http.put(
        Uri.parse('$apiUrl/incidents/$pagerdutyIncidentId'),
        headers: {
          'Authorization': 'Token token=$apiKey',
          'Accept': 'application/vnd.pagerduty+json;version=2',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'incident': {'type': 'incident_reference', 'status': 'resolved'},
        }),
      );

      if (response.statusCode == 200) {
        await _client
            .from('pagerduty_incidents')
            .update({
              'status': 'resolved',
              'resolved_at': DateTime.now().toIso8601String(),
            })
            .eq('pagerduty_incident_id', pagerdutyIncidentId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Resolve incident error: $e');
      return false;
    }
  }

  /// Handle PagerDuty webhook
  Future<void> handleWebhook(Map<String, dynamic> webhookData) async {
    try {
      final messages = webhookData['messages'] as List<dynamic>? ?? [];

      for (final message in messages) {
        final event = message['event'] as String?;
        final incident = message['incident'] as Map<String, dynamic>?;

        if (incident == null) continue;

        final pagerdutyIncidentId = incident['id'] as String;

        if (event == 'incident.acknowledged') {
          await _client
              .from('pagerduty_incidents')
              .update({
                'status': 'acknowledged',
                'acknowledged_by':
                    incident['last_status_change_by']?['summary'],
                'acknowledged_at': DateTime.now().toIso8601String(),
              })
              .eq('pagerduty_incident_id', pagerdutyIncidentId);
        } else if (event == 'incident.resolved') {
          await _client
              .from('pagerduty_incidents')
              .update({
                'status': 'resolved',
                'resolved_at': DateTime.now().toIso8601String(),
              })
              .eq('pagerduty_incident_id', pagerdutyIncidentId);
        }
      }
    } catch (e) {
      debugPrint('Handle webhook error: $e');
    }
  }

  /// Get on-call schedules
  Future<List<Map<String, dynamic>>> getOnCallSchedules() async {
    try {
      final response = await _client
          .from('on_call_schedules')
          .select()
          .order('schedule_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get on-call schedules error: $e');
      return [];
    }
  }

  /// Get PagerDuty incidents
  Future<List<Map<String, dynamic>>> getPagerDutyIncidents({
    String? status,
  }) async {
    try {
      var query = _client.from('pagerduty_incidents').select();

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get PagerDuty incidents error: $e');
      return [];
    }
  }
}
