import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// Bulk management: elections, users, compliance. Same backend as Web (bulk_operations, bulk_operation_items, bulk_operation_logs).
class BulkManagementService {
  static BulkManagementService? _instance;
  static BulkManagementService get instance =>
      _instance ??= BulkManagementService._();

  BulkManagementService._();

  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  /// Create a bulk operation (same schema as Web).
  Future<Map<String, dynamic>?> createBulkOperation({
    required String operationName,
    required String operationType,
    required String targetEntityType,
    required List<String> targetEntityIds,
    int batchSize = 50,
    bool rollbackEnabled = true,
  }) async {
    try {
      if (!_auth.isAuthenticated) return null;
      final userId = _auth.currentUser!.id;
      final res = await _client.from('bulk_operations').insert({
        'operation_name': operationName,
        'operation_type': operationType,
        'target_entity_type': targetEntityType,
        'target_entity_ids': targetEntityIds,
        'total_items': targetEntityIds.length,
        'progress_percentage': 0,
        'batch_size': batchSize,
        'rollback_enabled': rollbackEnabled,
        'created_by': userId,
        'status': 'pending',
      }).select().single();
      return res;
    } catch (e) {
      debugPrint('createBulkOperation error: $e');
      return null;
    }
  }

  /// List bulk operations (same as Web getBulkOperations).
  Future<List<Map<String, dynamic>>> getBulkOperations({
    String? status,
    String? operationType,
    int limit = 50,
  }) async {
    try {
      final base = _client.from('bulk_operations').select('*');
      final shouldFilterStatus = status != null && status != 'all';
      final shouldFilterType = operationType != null && operationType != 'all';

      final filtered = shouldFilterStatus && shouldFilterType
          ? base.eq('status', status).eq('operation_type', operationType)
          : shouldFilterStatus
              ? base.eq('status', status)
              : shouldFilterType
                  ? base.eq('operation_type', operationType)
                  : base;

      final res = await filtered
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('getBulkOperations error: $e');
      return [];
    }
  }

  /// Get one operation with items and logs (same as Web getBulkOperationDetails).
  Future<Map<String, dynamic>?> getBulkOperationDetails(String operationId) async {
    try {
      final op = await _client
          .from('bulk_operations')
          .select('*')
          .eq('id', operationId)
          .maybeSingle();
      if (op == null) return null;
      final items = await _client
          .from('bulk_operation_items')
          .select('*')
          .eq('bulk_operation_id', operationId)
          .order('created_at', ascending: false);
      final logs = await _client
          .from('bulk_operation_logs')
          .select('*')
          .eq('bulk_operation_id', operationId)
          .order('created_at', ascending: false)
          .limit(100);
      return {
        'operation': op,
        'items': List<Map<String, dynamic>>.from(items),
        'logs': List<Map<String, dynamic>>.from(logs),
      };
    } catch (e) {
      debugPrint('getBulkOperationDetails error: $e');
      return null;
    }
  }

  /// Trigger execution (invoke Edge Function or mark for processing; Web runs client-side loop).
  /// Mobile: call Edge Function 'execute-bulk-operation' if you add one, or run batch in Dart.
  /// For parity we invoke the same Supabase RPC/table updates. Here we just set status to processing and let a backend cron or the Web run the actual work; alternatively implement the same loop in Dart.
  Future<bool> executeBulkOperation(String operationId) async {
    try {
      await _client.from('bulk_operations').update({
        'status': 'processing',
        'started_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', operationId);
      return true;
    } catch (e) {
      debugPrint('executeBulkOperation error: $e');
      return false;
    }
  }

  /// Rollback (same as Web: restore before_state on each item).
  Future<bool> rollbackBulkOperation(String operationId) async {
    try {
      final items = await _client
          .from('bulk_operation_items')
          .select('*')
          .eq('bulk_operation_id', operationId)
          .eq('status', 'completed');
      final list = List<Map<String, dynamic>>.from(items);
      if (list.isEmpty) return false;
      for (final item in list) {
        final entityType = item['entity_type'] as String?;
        final entityId = item['entity_id'];
        final before = item['before_state'] as Map<String, dynamic>?;
        if (entityType == null || entityId == null || before == null) continue;
        try {
          await _client.from(entityType).update(before).eq('id', entityId);
          await _client.from('bulk_operation_items').update({
            'status': 'rolled_back',
            'rollback_executed': true,
            'rollback_at': DateTime.now().toIso8601String(),
          }).eq('id', item['id']);
        } catch (_) {}
      }
      await _client.from('bulk_operations').update({
        'status': 'rolled_back',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', operationId);
      return true;
    } catch (e) {
      debugPrint('rollbackBulkOperation error: $e');
      return false;
    }
  }

  /// Statistics (optional, for dashboard).
  Future<Map<String, dynamic>> getBulkOperationStatistics(String timeRange) async {
    try {
      final days = timeRange == '7d' ? 7 : (timeRange == '30d' ? 30 : 1);
      final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final res = await _client
          .from('bulk_operations')
          .select('id, status, operation_type')
          .gte('created_at', since);
      final list = List<Map<String, dynamic>>.from(res);
      final completed = list.where((e) => e['status'] == 'completed').length;
      final failed = list.where((e) => e['status'] == 'failed').length;
      final processing = list.where((e) => e['status'] == 'processing').length;
      return {
        'total': list.length,
        'completed': completed,
        'failed': failed,
        'processing': processing,
      };
    } catch (e) {
      debugPrint('getBulkOperationStatistics error: $e');
      return {'total': 0, 'completed': 0, 'failed': 0, 'processing': 0};
    }
  }
}
