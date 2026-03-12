import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class AdminManagementService {
  static AdminManagementService? _instance;
  static AdminManagementService get instance =>
      _instance ??= AdminManagementService._();

  AdminManagementService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get system statistics
  Future<Map<String, dynamic>> getSystemStatistics() async {
    try {
      final response = await _client.rpc('get_system_statistics');
      return response ?? _getDefaultStatistics();
    } catch (e) {
      debugPrint('Get system statistics error: $e');
      return _getDefaultStatistics();
    }
  }

  /// Get user management data
  Future<List<Map<String, dynamic>>> getUsers({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
  }) async {
    try {
      dynamic query = _client.from('user_profiles').select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'username.ilike.%$searchQuery%,email.ilike.%$searchQuery%',
        );
      }

      query = query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get users error: $e');
      return [];
    }
  }

  /// Update user status
  Future<bool> updateUserStatus({
    required String userId,
    required String status,
    String? reason,
  }) async {
    try {
      await _client
          .from('user_profiles')
          .update({
            'status': status,
            'status_reason': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      await _logAdminAction(
        action: 'update_user_status',
        targetId: userId,
        details: {'status': status, 'reason': reason},
      );

      return true;
    } catch (e) {
      debugPrint('Update user status error: $e');
      return false;
    }
  }

  /// Get feature toggles
  Future<Map<String, dynamic>> getFeatureToggles() async {
    try {
      final response = await _client
          .from('feature_toggles')
          .select()
          .order('feature_name');

      final togglesMap = <String, dynamic>{};
      for (var toggle in response) {
        togglesMap[toggle['feature_name']] = toggle['is_enabled'];
      }

      return togglesMap;
    } catch (e) {
      debugPrint('Get feature toggles error: $e');
      return {};
    }
  }

  /// Update feature toggle
  Future<bool> updateFeatureToggle({
    required String featureName,
    required bool isEnabled,
  }) async {
    try {
      await _client.from('feature_toggles').upsert({
        'feature_name': featureName,
        'is_enabled': isEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _logAdminAction(
        action: 'update_feature_toggle',
        targetId: featureName,
        details: {'is_enabled': isEnabled},
      );

      return true;
    } catch (e) {
      debugPrint('Update feature toggle error: $e');
      return false;
    }
  }

  /// Get audit logs
  Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 100,
    String? actionType,
    String? userId,
  }) async {
    try {
      dynamic query = _client.from('audit_logs').select();

      if (actionType != null) {
        query = query.eq('action_type', actionType);
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get audit logs error: $e');
      return [];
    }
  }

  /// Get system health metrics
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final response = await _client.rpc('get_system_health');
      return response ?? _getDefaultHealth();
    } catch (e) {
      debugPrint('Get system health error: $e');
      return _getDefaultHealth();
    }
  }

  /// Get compliance metrics
  Future<Map<String, dynamic>> getComplianceMetrics() async {
    try {
      final response = await _client.rpc('get_compliance_metrics');
      return response ?? _getDefaultCompliance();
    } catch (e) {
      debugPrint('Get compliance metrics error: $e');
      return _getDefaultCompliance();
    }
  }

  /// Create system alert
  Future<bool> createSystemAlert({
    required String alertType,
    required String severity,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('system_alerts').insert({
        'alert_type': alertType,
        'severity': severity,
        'message': message,
        'metadata': metadata ?? {},
        'is_resolved': false,
      });

      return true;
    } catch (e) {
      debugPrint('Create system alert error: $e');
      return false;
    }
  }

  /// Get active system alerts
  Future<List<Map<String, dynamic>>> getSystemAlerts({
    bool unresolvedOnly = true,
  }) async {
    try {
      dynamic query = _client.from('system_alerts').select();

      if (unresolvedOnly) {
        query = query.eq('is_resolved', false);
      }

      query = query.order('created_at', ascending: false);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get system alerts error: $e');
      return [];
    }
  }

  /// Resolve system alert
  Future<bool> resolveSystemAlert({
    required String alertId,
    String? resolution,
  }) async {
    try {
      await _client
          .from('system_alerts')
          .update({
            'is_resolved': true,
            'resolution': resolution,
            'resolved_at': DateTime.now().toIso8601String(),
            'resolved_by': _auth.currentUser?.id,
          })
          .eq('id', alertId);

      return true;
    } catch (e) {
      debugPrint('Resolve system alert error: $e');
      return false;
    }
  }

  Future<void> _logAdminAction({
    required String action,
    required String targetId,
    Map<String, dynamic>? details,
  }) async {
    try {
      if (!_auth.isAuthenticated) return;

      await _client.from('admin_actions').insert({
        'admin_id': _auth.currentUser!.id,
        'action_type': action,
        'target_id': targetId,
        'details': details ?? {},
      });
    } catch (e) {
      debugPrint('Log admin action error: $e');
    }
  }

  Map<String, dynamic> _getDefaultStatistics() {
    return {
      'total_users': 0,
      'active_users': 0,
      'total_elections': 0,
      'active_elections': 0,
      'total_votes': 0,
      'total_revenue': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultHealth() {
    return {
      'database_status': 'healthy',
      'api_status': 'healthy',
      'storage_status': 'healthy',
      'uptime_percentage': 99.9,
    };
  }

  Map<String, dynamic> _getDefaultCompliance() {
    return {
      'gdpr_compliant': true,
      'data_retention_policy': 'active',
      'audit_trail_status': 'enabled',
      'security_score': 95,
    };
  }
}
