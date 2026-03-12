import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/platform_log.dart';

class LogStreamService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's own logs (non-sensitive)
  static Stream<List<PlatformLog>> getUserActivityStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('platform_logs')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data.map((e) => PlatformLog.fromJson(e)).toList());
  }

  /// Admin: Get all logs (requires admin role)
  static Stream<List<PlatformLog>> getAdminLogStream({
    String? logLevel,
    String? logCategory,
    String? searchQuery,
  }) {
    var query = _supabase
        .from('platform_logs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100);

    // Note: Filtering is done client-side after stream
    return query.map((data) {
      var logs = data.map((e) => PlatformLog.fromJson(e)).toList();

      if (logLevel != null) {
        logs = logs.where((log) => log.logLevel == logLevel).toList();
      }

      if (logCategory != null) {
        logs = logs.where((log) => log.logCategory == logCategory).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        logs = logs
            .where(
              (log) =>
                  log.message.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  log.eventType.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }

      return logs;
    });
  }

  /// Critical security alerts stream
  static Stream<List<PlatformLog>> getCriticalAlertsStream() {
    return _supabase
        .from('platform_logs')
        .stream(primaryKey: ['id'])
        .eq('log_level', 'critical')
        .order('created_at', ascending: false)
        .limit(10)
        .map((data) => data.map((e) => PlatformLog.fromJson(e)).toList());
  }
}
