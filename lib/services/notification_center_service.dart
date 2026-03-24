import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'supabase_service.dart';

/// Same source of truth as Web `notificationService.js`: table `activity_feed`.
class NotificationCenterService {
  NotificationCenterService._();
  static final NotificationCenterService instance = NotificationCenterService._();

  static const String tableName = 'activity_feed';

  /// Mirrors Web `categoryMap` in `notificationService.getNotifications`.
  static const Map<String, List<String>> categoryToActivityTypes = {
    'votes': ['vote'],
    'messages': ['message_received'],
    'achievements': ['achievement_unlocked'],
    'elections': ['election_created', 'election_completed'],
    'campaigns': ['post_liked', 'post_commented', 'post_shared'],
    'payments': [
      'settlement_processing',
      'payout_delayed',
      'payment_method_failed',
      'payout_completed',
    ],
  };

  SupabaseClient get _client => SupabaseService.instance.client;

  String notificationCategoryForActivityType(String? activityType) {
    if (activityType == null || activityType.isEmpty) return 'campaigns';
    for (final e in categoryToActivityTypes.entries) {
      if (e.value.contains(activityType)) return e.key;
    }
    return 'campaigns';
  }

  Map<String, dynamic> normalizeRow(Map<String, dynamic> row) {
    final activityType = row['activity_type'] as String?;
    final category = notificationCategoryForActivityType(activityType);
    final desc = row['description'] as String? ?? '';
    return {
      ...row,
      'notification_type': category,
      'body': desc,
    };
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({int limit = 100}) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return [];

    final data = await _client
        .from(tableName)
        .select(
          'id, user_id, activity_type, title, description, is_read, created_at',
        )
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    final list = List<Map<String, dynamic>>.from(data as List);
    return list
        .map((r) => normalizeRow(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Realtime parity with Web `subscribeToNotifications` (`activity_feed`).
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _client
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((raw) {
          final rows = List<Map<String, dynamic>>.from(
            (raw as List<dynamic>)
                .map((e) => Map<String, dynamic>.from(e as Map)),
          );
          rows.sort((a, b) {
            final da = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final db = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });
          if (rows.length > 100) {
            rows.removeRange(100, rows.length);
          }
          return rows.map(normalizeRow).toList();
        });
  }

  Future<void> markAsRead(String id) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    await _client
        .from(tableName)
        .update({'is_read': true})
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> markManyAsRead(Iterable<String> ids) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final list = ids.toList();
    if (list.isEmpty) return;
    await _client
        .from(tableName)
        .update({'is_read': true})
        .inFilter('id', list)
        .eq('user_id', user.id);
  }

  Future<void> markAllAsRead() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    await _client
        .from(tableName)
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);
  }

  Future<void> deleteById(String id) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    await _client.from(tableName).delete().eq('id', id).eq('user_id', user.id);
  }

  Future<void> deleteMany(Iterable<String> ids) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final list = ids.toList();
    if (list.isEmpty) return;
    await _client
        .from(tableName)
        .delete()
        .inFilter('id', list)
        .eq('user_id', user.id);
  }

  Future<void> deleteByCategory(String category) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;
    final types = categoryToActivityTypes[category];
    if (types == null || types.isEmpty) return;
    await _client
        .from(tableName)
        .delete()
        .eq('user_id', user.id)
        .inFilter('activity_type', types);
  }
}
