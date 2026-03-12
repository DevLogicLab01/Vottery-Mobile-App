import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class StatusPageService {
  static StatusPageService? _instance;
  static StatusPageService get instance => _instance ??= StatusPageService._();

  StatusPageService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Get overall system status
  Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      // Get overall status from RPC function
      final overallStatus = await _client.rpc('get_overall_system_status');

      // Get individual service statuses
      final services = await _client
          .from('system_services')
          .select()
          .order('service_name');

      return {
        'overall_status': overallStatus,
        'services': services,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Get system status error: $e');
      return {
        'overall_status': 'unknown',
        'services': [],
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get current active incidents
  Future<List<Map<String, dynamic>>> getCurrentIncidents() async {
    try {
      final incidents = await _client
          .from('service_incidents')
          .select('*, system_services(service_name)')
          .inFilter('status', ['investigating', 'identified', 'monitoring'])
          .order('started_at', ascending: false);

      return List<Map<String, dynamic>>.from(incidents);
    } catch (e) {
      debugPrint('Get current incidents error: $e');
      return [];
    }
  }

  /// Get scheduled maintenance
  Future<List<Map<String, dynamic>>> getScheduledMaintenance() async {
    try {
      final now = DateTime.now();

      final maintenance = await _client
          .from('scheduled_maintenance')
          .select()
          .gte('maintenance_end', now.toIso8601String())
          .eq('status', 'scheduled')
          .order('maintenance_start');

      return List<Map<String, dynamic>>.from(maintenance);
    } catch (e) {
      debugPrint('Get scheduled maintenance error: $e');
      return [];
    }
  }

  /// Get historical uptime (last 90 days)
  Future<List<Map<String, dynamic>>> getHistoricalUptime() async {
    try {
      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));

      final records = await _client
          .from('daily_uptime_records')
          .select()
          .gte('record_date', ninetyDaysAgo.toIso8601String().split('T')[0])
          .order('record_date', ascending: false);

      return List<Map<String, dynamic>>.from(records);
    } catch (e) {
      debugPrint('Get historical uptime error: $e');
      return [];
    }
  }

  /// Calculate uptime statistics
  Future<Map<String, dynamic>> getUptimeStatistics() async {
    try {
      final records = await getHistoricalUptime();

      if (records.isEmpty) {
        return {
          '90_day_uptime': 100.0,
          '30_day_uptime': 100.0,
          '7_day_uptime': 100.0,
        };
      }

      final ninetyDayRecords = records;
      final thirtyDayRecords = records.take(30).toList();
      final sevenDayRecords = records.take(7).toList();

      final ninetyDayUptime = _calculateAverageUptime(ninetyDayRecords);
      final thirtyDayUptime = _calculateAverageUptime(thirtyDayRecords);
      final sevenDayUptime = _calculateAverageUptime(sevenDayRecords);

      return {
        '90_day_uptime': ninetyDayUptime,
        '30_day_uptime': thirtyDayUptime,
        '7_day_uptime': sevenDayUptime,
      };
    } catch (e) {
      debugPrint('Get uptime statistics error: $e');
      return {'90_day_uptime': 0.0, '30_day_uptime': 0.0, '7_day_uptime': 0.0};
    }
  }

  double _calculateAverageUptime(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 100.0;

    final totalUptime = records.fold<double>(
      0.0,
      (sum, record) => sum + (record['uptime_percentage'] as num).toDouble(),
    );

    return totalUptime / records.length;
  }

  /// Subscribe to status updates
  Future<bool> subscribeToUpdates(String email) async {
    try {
      final unsubscribeToken = _generateUnsubscribeToken();

      await _client.from('status_page_subscribers').insert({
        'email': email,
        'subscribed_at': DateTime.now().toIso8601String(),
        'unsubscribe_token': unsubscribeToken,
        'verified': false,
      });

      return true;
    } catch (e) {
      debugPrint('Subscribe to updates error: $e');
      return false;
    }
  }

  /// Update service status (admin only)
  Future<bool> updateServiceStatus({
    required String serviceId,
    required String status,
    String? statusMessage,
    double? responseTimeMs,
  }) async {
    try {
      await _client
          .from('system_services')
          .update({
            'current_status': status,
            'status_message': statusMessage,
            'response_time_ms': responseTimeMs,
            'last_checked_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('service_id', serviceId);

      return true;
    } catch (e) {
      debugPrint('Update service status error: $e');
      return false;
    }
  }

  /// Create incident (admin only)
  Future<String?> createIncident({
    required String serviceId,
    required String title,
    required String description,
    required String severity,
    required List<String> affectedComponents,
  }) async {
    try {
      final incident = await _client
          .from('service_incidents')
          .insert({
            'service_id': serviceId,
            'title': title,
            'description': description,
            'severity': severity,
            'status': 'investigating',
            'started_at': DateTime.now().toIso8601String(),
            'affected_components': affectedComponents,
            'updates': [],
          })
          .select()
          .single();

      return incident['incident_id'] as String;
    } catch (e) {
      debugPrint('Create incident error: $e');
      return null;
    }
  }

  /// Add incident update (admin only)
  Future<bool> addIncidentUpdate({
    required String incidentId,
    required String updateText,
    String? newStatus,
  }) async {
    try {
      // Get current incident
      final incident = await _client
          .from('service_incidents')
          .select()
          .eq('incident_id', incidentId)
          .single();

      final updates = List<Map<String, dynamic>>.from(
        incident['updates'] ?? [],
      );

      updates.add({
        'timestamp': DateTime.now().toIso8601String(),
        'message': updateText,
        'status': newStatus ?? incident['status'],
      });

      await _client
          .from('service_incidents')
          .update({
            'updates': updates,
            'status': newStatus ?? incident['status'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('incident_id', incidentId);

      return true;
    } catch (e) {
      debugPrint('Add incident update error: $e');
      return false;
    }
  }

  /// Resolve incident (admin only)
  Future<bool> resolveIncident(String incidentId) async {
    try {
      await _client
          .from('service_incidents')
          .update({
            'status': 'resolved',
            'resolved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('incident_id', incidentId);

      return true;
    } catch (e) {
      debugPrint('Resolve incident error: $e');
      return false;
    }
  }

  String _generateUnsubscribeToken() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond % 10000}';
  }
}
