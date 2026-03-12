import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecurityMonitoringService {
  static SecurityMonitoringService? _instance;
  static SecurityMonitoringService get instance =>
      _instance ??= SecurityMonitoringService._();

  SecurityMonitoringService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get security metrics for today
  Future<Map<String, int>> getTodaySecurityMetrics() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _supabase
          .from('security_incidents')
          .select('incident_type')
          .gte('created_at', startOfDay.toIso8601String());

      final incidents = List<Map<String, dynamic>>.from(response);

      return {
        'cors_violations': incidents
            .where((i) => i['incident_type'] == 'cors_violation')
            .length,
        'rate_limit_breaches': incidents
            .where((i) => i['incident_type'] == 'rate_limit_breach')
            .length,
        'webhook_replay_attacks': incidents
            .where((i) => i['incident_type'] == 'webhook_replay_attack')
            .length,
        'sql_injection_attempts': incidents
            .where((i) => i['incident_type'] == 'sql_injection_attempt')
            .length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch security metrics: $e');
      }
      return {
        'cors_violations': 0,
        'rate_limit_breaches': 0,
        'webhook_replay_attacks': 0,
        'sql_injection_attempts': 0,
      };
    }
  }

  /// Get 24-hour activity timeline data
  Future<Map<String, List<Map<String, dynamic>>>> get24HourTimeline() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final response = await _supabase
          .from('security_incidents')
          .select('incident_type, created_at')
          .gte('created_at', yesterday.toIso8601String())
          .order('created_at', ascending: true);

      final incidents = List<Map<String, dynamic>>.from(response);

      // Group by hour and incident type
      final Map<String, List<Map<String, dynamic>>> timelineData = {
        'cors_violations': [],
        'rate_limit_breaches': [],
        'webhook_replay_attacks': [],
        'sql_injection_attempts': [],
      };

      for (int hour = 0; hour < 24; hour++) {
        final hourStart = yesterday.add(Duration(hours: hour));
        final hourEnd = hourStart.add(const Duration(hours: 1));

        for (var type in timelineData.keys) {
          final count = incidents.where((incident) {
            final createdAt = DateTime.parse(incident['created_at']);
            return incident['incident_type'] == type &&
                createdAt.isAfter(hourStart) &&
                createdAt.isBefore(hourEnd);
          }).length;

          timelineData[type]!.add({
            'hour': hour,
            'count': count,
            'timestamp': hourStart.toIso8601String(),
          });
        }
      }

      return timelineData;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch 24-hour timeline: $e');
      }
      return {};
    }
  }

  /// Get real-time incident stream
  Stream<List<Map<String, dynamic>>> getIncidentStream() {
    return _supabase
        .from('security_incidents')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Get incident details
  Future<Map<String, dynamic>?> getIncidentDetails(String incidentId) async {
    try {
      final response = await _supabase
          .from('security_incidents')
          .select('*, user_profiles(email, username)')
          .eq('id', incidentId)
          .maybeSingle();

      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch incident details: $e');
      }
      return null;
    }
  }

  /// Create security incident
  Future<bool> createSecurityIncident({
    required String incidentType,
    required String severity,
    required String description,
    String? sourceIp,
    String? userId,
    Map<String, dynamic>? requestDetails,
    String? detectionMethod,
    String? actionTaken,
  }) async {
    try {
      await _supabase.from('security_incidents').insert({
        'incident_type': incidentType,
        'severity': severity,
        'description': description,
        'source_ip': sourceIp,
        'user_id': userId,
        'request_details': requestDetails,
        'detection_method': detectionMethod,
        'action_taken': actionTaken,
        'status': 'detected',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create security incident: $e');
      }
      return false;
    }
  }

  /// Resolve incident
  Future<bool> resolveIncident({
    required String incidentId,
    required String resolutionNotes,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _supabase
          .from('security_incidents')
          .update({
            'status': 'resolved',
            'resolution_notes': resolutionNotes,
            'resolved_by': userId,
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', incidentId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to resolve incident: $e');
      }
      return false;
    }
  }

  /// Export incidents to CSV
  Future<String> exportIncidentsToCSV({
    DateTime? startDate,
    DateTime? endDate,
    String? incidentType,
    String? severity,
  }) async {
    try {
      var query = _supabase.from('security_incidents').select();

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      if (incidentType != null) {
        query = query.eq('incident_type', incidentType);
      }

      if (severity != null) {
        query = query.eq('severity', severity);
      }

      final response = await query.order('created_at', ascending: false);
      final incidents = List<Map<String, dynamic>>.from(response);

      // Build CSV
      final csvLines = <String>[
        'Incident ID,Type,Severity,Description,Source IP,User ID,Detection Method,Action Taken,Status,Created At',
      ];

      for (var incident in incidents) {
        csvLines.add(
          '${incident['id']},'
          '${incident['incident_type']},'
          '${incident['severity']},'
          '"${incident['description']}",'
          '${incident['source_ip'] ?? 'N/A'},'
          '${incident['user_id'] ?? 'N/A'},'
          '${incident['detection_method'] ?? 'N/A'},'
          '${incident['action_taken'] ?? 'N/A'},'
          '${incident['status']},'
          '${incident['created_at']}',
        );
      }

      return csvLines.join('\n');
    } catch (e) {
      if (kDebugMode) {
        print('Failed to export incidents: $e');
      }
      return '';
    }
  }

  /// Get related incidents (by IP or user)
  Future<List<Map<String, dynamic>>> getRelatedIncidents({
    String? sourceIp,
    String? userId,
    int limit = 10,
  }) async {
    try {
      var query = _supabase.from('security_incidents').select();

      if (sourceIp != null) {
        query = query.eq('source_ip', sourceIp);
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch related incidents: $e');
      }
      return [];
    }
  }
}
