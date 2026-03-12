import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import './supabase_service.dart';
import './auth_service.dart';

class AuditLogService {
  static AuditLogService? _instance;
  static AuditLogService get instance => _instance ??= AuditLogService._();

  AuditLogService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Log audit event with cryptographic hash
  Future<bool> logAuditEvent({
    required String eventType,
    required String actionType,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Get previous hash
      final previousHash = await _getLastAuditLogHash();

      // Construct entry data
      final entryData = {
        'event_type': eventType,
        'actor_id': _auth.currentUser!.id,
        'actor_username': _auth.currentUser!.email ?? 'unknown',
        'action_type': actionType,
        'entity_type': entityType,
        'entity_id': entityId,
        'old_value': oldValue,
        'new_value': newValue,
        'reason': reason,
        'metadata': metadata,
        'previous_hash': previousHash,
      };

      // Calculate cryptographic hash
      final currentHash = _calculateHash(entryData);

      // Insert audit log entry
      await _client.from('immutable_audit_log').insert({
        ...entryData,
        'cryptographic_hash': currentHash,
      });

      return true;
    } catch (e) {
      debugPrint('Log audit event error: $e');
      return false;
    }
  }

  /// Get last audit log hash
  Future<String> _getLastAuditLogHash() async {
    try {
      final response = await _client
          .from('immutable_audit_log')
          .select('cryptographic_hash')
          .order('event_timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      return response?['cryptographic_hash'] ?? 'genesis';
    } catch (e) {
      debugPrint('Get last audit log hash error: $e');
      return 'genesis';
    }
  }

  /// Calculate SHA-256 hash
  String _calculateHash(Map<String, dynamic> data) {
    final dataString = json.encode(data);
    final bytes = utf8.encode(dataString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Get audit logs with filtering
  Future<List<Map<String, dynamic>>> getAuditLogs({
    List<String>? eventTypes,
    List<String>? actionTypes,
    List<String>? entityTypes,
    String? actorId,
    DateTime? startDate,
    DateTime? endDate,
    bool? tamperDetected,
    int limit = 100,
  }) async {
    try {
      var query = _client.from('immutable_audit_log').select();

      if (eventTypes != null && eventTypes.isNotEmpty) {
        query = query.inFilter('event_type', eventTypes);
      }

      if (actionTypes != null && actionTypes.isNotEmpty) {
        query = query.inFilter('action_type', actionTypes);
      }

      if (entityTypes != null && entityTypes.isNotEmpty) {
        query = query.inFilter('entity_type', entityTypes);
      }

      if (actorId != null) {
        query = query.eq('actor_id', actorId);
      }

      if (startDate != null) {
        query = query.gte('event_timestamp', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('event_timestamp', endDate.toIso8601String());
      }

      if (tamperDetected != null) {
        query = query.eq('tamper_detected', tamperDetected);
      }

      final response = await query
          .order('event_timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get audit logs error: $e');
      return [];
    }
  }

  /// Verify audit log integrity
  Future<Map<String, dynamic>> verifyAuditLogIntegrity() async {
    try {
      final logs = await _client
          .from('immutable_audit_log')
          .select()
          .order('event_timestamp', ascending: true);

      final auditLogs = List<Map<String, dynamic>>.from(logs);

      int entriesVerified = 0;
      int tamperedEntries = 0;
      final tamperedEntryIds = <String>[];

      for (int i = 0; i < auditLogs.length; i++) {
        final entry = auditLogs[i];
        final storedHash = entry['cryptographic_hash'] as String;

        // Reconstruct entry data for hash calculation
        final entryData = {
          'event_type': entry['event_type'],
          'actor_id': entry['actor_id'],
          'actor_username': entry['actor_username'],
          'action_type': entry['action_type'],
          'entity_type': entry['entity_type'],
          'entity_id': entry['entity_id'],
          'old_value': entry['old_value'],
          'new_value': entry['new_value'],
          'reason': entry['reason'],
          'metadata': entry['metadata'],
          'previous_hash': entry['previous_hash'],
        };

        final calculatedHash = _calculateHash(entryData);

        if (calculatedHash != storedHash) {
          tamperedEntries++;
          tamperedEntryIds.add(entry['audit_log_id']);

          // Mark as tampered
          await _client
              .from('immutable_audit_log')
              .update({'tamper_detected': true})
              .eq('audit_log_id', entry['audit_log_id']);
        }

        entriesVerified++;
      }

      // Log verification result
      await _client.from('audit_verification_log').insert({
        'entries_verified': entriesVerified,
        'tampering_detected': tamperedEntries > 0,
        'tampered_entry_ids': tamperedEntryIds,
      });

      return {
        'success': true,
        'entries_verified': entriesVerified,
        'tampered_entries': tamperedEntries,
        'tampered_entry_ids': tamperedEntryIds,
        'hash_chain_status': tamperedEntries == 0 ? 'intact' : 'broken',
      };
    } catch (e) {
      debugPrint('Verify audit log integrity error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get verification history
  Future<List<Map<String, dynamic>>> getVerificationHistory({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('audit_verification_log')
          .select()
          .order('verification_timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get verification history error: $e');
      return [];
    }
  }

  /// Export audit logs to CSV
  Future<String> exportAuditLogsToCsv({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? eventTypes,
    bool includeHashValues = false,
  }) async {
    try {
      final logs = await getAuditLogs(
        startDate: startDate,
        endDate: endDate,
        eventTypes: eventTypes,
        limit: 10000,
      );

      final csv = StringBuffer();

      if (includeHashValues) {
        csv.writeln(
          'Timestamp,Event Type,Actor,Action,Entity Type,Entity ID,Reason,Hash,Previous Hash,Tamper Detected',
        );
      } else {
        csv.writeln(
          'Timestamp,Event Type,Actor,Action,Entity Type,Entity ID,Reason,Tamper Detected',
        );
      }

      for (final log in logs) {
        if (includeHashValues) {
          csv.writeln(
            '${log['event_timestamp']},${log['event_type']},${log['actor_username']},'
            '${log['action_type']},${log['entity_type']},${log['entity_id'] ?? "N/A"},'
            '"${log['reason'] ?? ""}",${log['cryptographic_hash']},'
            '${log['previous_hash']},${log['tamper_detected'] ?? false}',
          );
        } else {
          csv.writeln(
            '${log['event_timestamp']},${log['event_type']},${log['actor_username']},'
            '${log['action_type']},${log['entity_type']},${log['entity_id'] ?? "N/A"},'
            '"${log['reason'] ?? ""}",${log['tamper_detected'] ?? false}',
          );
        }
      }

      return csv.toString();
    } catch (e) {
      debugPrint('Export audit logs to CSV error: $e');
      return '';
    }
  }

  /// Get audit log statistics
  Future<Map<String, dynamic>> getAuditLogStatistics() async {
    try {
      final logs = await _client.from('immutable_audit_log').select();

      final auditLogs = List<Map<String, dynamic>>.from(logs);

      final totalEntries = auditLogs.length;
      final entriesToday = auditLogs.where((log) {
        final timestamp = DateTime.parse(log['event_timestamp']);
        final now = DateTime.now();
        return timestamp.year == now.year &&
            timestamp.month == now.month &&
            timestamp.day == now.day;
      }).length;

      final tamperedEntries = auditLogs
          .where((log) => log['tamper_detected'] == true)
          .length;

      // Get most active users
      final actorCounts = <String, int>{};
      for (final log in auditLogs) {
        final actor = log['actor_username'] as String;
        actorCounts[actor] = (actorCounts[actor] ?? 0) + 1;
      }

      final mostActiveUsers = actorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Get most common actions
      final actionCounts = <String, int>{};
      for (final log in auditLogs) {
        final action = log['action_type'] as String;
        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
      }

      return {
        'total_entries': totalEntries,
        'entries_today': entriesToday,
        'tampered_entries': tamperedEntries,
        'most_active_users': mostActiveUsers.take(10).toList(),
        'action_counts': actionCounts,
      };
    } catch (e) {
      debugPrint('Get audit log statistics error: $e');
      return {};
    }
  }
}
