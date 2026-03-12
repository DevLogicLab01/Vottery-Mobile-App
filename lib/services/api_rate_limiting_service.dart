import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ApiRateLimitingService {
  static ApiRateLimitingService? _instance;
  static ApiRateLimitingService get instance =>
      _instance ??= ApiRateLimitingService._();

  ApiRateLimitingService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  Future<Map<String, dynamic>?> getMetrics() async {
    try {
      final limits = await getAllRateLimits();
      final violations = await getViolations('24h');
      final quota = await getQuotaMonitoring('1h');

      final totalEndpoints = limits?.length ?? 0;
      final throttled = limits?.where((r) => r['throttle_enabled'] == true).length ?? 0;
      final totalViolations = violations?.length ?? 0;
      final blocked = violations?.where((v) => v['blocked'] == true).length ?? 0;
      final avgUtilization = quota?.isNotEmpty == true
          ? quota.map((q) => q['quota_utilization_percent'] ?? 0).reduce((a, b) => a + b) / quota.length
          : 0.0;
      final abuseDetected = violations?.any((v) => v['severity'] == 'high') ?? false;

      return {
        'totalEndpoints': totalEndpoints,
        'throttledEndpoints': throttled,
        'totalViolations': totalViolations,
        'blockedRequests': blocked,
        'avgQuotaUtilization': avgUtilization.toStringAsFixed(2),
        'abuseDetected': abuseDetected,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllRateLimits() async {
    try {
      final response = await _client
          .from('api_rate_limits')
          .select()
          .order('endpoint');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getViolations(String timeRange) async {
    try {
      final now = DateTime.now();
      DateTime start;
      switch (timeRange) {
        case '1h':
          start = now.subtract(const Duration(hours: 1));
          break;
        case '24h':
          start = now.subtract(const Duration(hours: 24));
          break;
        case '7d':
          start = now.subtract(const Duration(days: 7));
          break;
        default:
          start = now.subtract(const Duration(hours: 24));
      }

      final response = await _client
          .from('api_rate_limit_violations')
          .select()
          .gte('created_at', start.toIso8601String())
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getQuotaMonitoring(String timeRange) async {
    try {
      final now = DateTime.now();
      DateTime start;
      switch (timeRange) {
        case '1h':
          start = now.subtract(const Duration(hours: 1));
          break;
        case '6h':
          start = now.subtract(const Duration(hours: 6));
          break;
        case '24h':
          start = now.subtract(const Duration(hours: 24));
          break;
        default:
          start = now.subtract(const Duration(hours: 1));
      }

      final response = await _client
          .from('api_quota_monitoring')
          .select()
          .gte('timestamp', start.toIso8601String())
          .order('timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<bool> toggleThrottling(String id, bool enabled) async {
    try {
      await _client
          .from('api_rate_limits')
          .update({'throttle_enabled': enabled, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
