import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class FeatureManagementService {
  static FeatureManagementService? _instance;
  static FeatureManagementService get instance =>
      _instance ??= FeatureManagementService._();

  FeatureManagementService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get all feature flags
  Future<List<Map<String, dynamic>>> getAllFeatureFlags() async {
    try {
      final response = await _client
          .from('feature_flags')
          .select()
          .order('category')
          .order('feature_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all feature flags error: $e');
      return [];
    }
  }

  /// Get feature flags by category
  Future<List<Map<String, dynamic>>> getFeatureFlagsByCategory(
    String category,
  ) async {
    try {
      final response = await _client
          .from('feature_flags')
          .select()
          .eq('category', category)
          .order('feature_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get feature flags by category error: $e');
      return [];
    }
  }

  /// Update feature flag status
  Future<bool> updateFeatureFlag({
    required String featureId,
    required bool isEnabled,
    String? reason,
  }) async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) return false;

      // Get old value for audit
      final oldData = await _client
          .from('feature_flags')
          .select()
          .eq('id', featureId)
          .maybeSingle();

      // Update feature flag
      await _client
          .from('feature_flags')
          .update({
            'is_enabled': isEnabled,
            'last_modified_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', featureId);

      // Log audit
      await _logAudit(
        action: 'update_feature_flag',
        targetType: 'feature_flag',
        targetId: featureId,
        reason: reason,
        oldValue: oldData,
        newValue: {'is_enabled': isEnabled},
      );

      return true;
    } catch (e) {
      debugPrint('Update feature flag error: $e');
      return false;
    }
  }

  /// Update feature rollout percentage
  Future<bool> updateFeatureRollout({
    required String featureId,
    required int rolloutPercentage,
  }) async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('feature_flags')
          .update({
            'rollout_percentage': rolloutPercentage,
            'last_modified_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', featureId);

      return true;
    } catch (e) {
      debugPrint('Update feature rollout error: $e');
      return false;
    }
  }

  /// Check feature dependencies
  Future<List<String>> checkFeatureDependencies(String featureId) async {
    try {
      final feature = await _client
          .from('feature_flags')
          .select()
          .eq('id', featureId)
          .maybeSingle();

      if (feature == null) return [];

      final dependencies = List<String>.from(feature['dependencies'] ?? []);
      final disabledDependencies = <String>[];

      for (final depName in dependencies) {
        final dep = await _client
            .from('feature_flags')
            .select()
            .eq('feature_name', depName)
            .maybeSingle();

        if (dep != null && dep['is_enabled'] == false) {
          disabledDependencies.add(depName);
        }
      }

      return disabledDependencies;
    } catch (e) {
      debugPrint('Check feature dependencies error: $e');
      return [];
    }
  }

  /// Bulk update features by category
  Future<bool> bulkUpdateByCategory({
    required String category,
    required bool isEnabled,
  }) async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('feature_flags')
          .update({
            'is_enabled': isEnabled,
            'last_modified_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('category', category);

      await _logAudit(
        action: 'bulk_update_features',
        targetType: 'feature_flag',
        targetId: category,
        reason: 'Bulk ${isEnabled ? "enable" : "disable"} for $category',
        oldValue: null,
        newValue: {'category': category, 'is_enabled': isEnabled},
      );

      return true;
    } catch (e) {
      debugPrint('Bulk update by category error: $e');
      return false;
    }
  }

  /// Get feature usage analytics
  Future<Map<String, dynamic>> getFeatureUsageAnalytics(
    String featureId,
  ) async {
    try {
      final response = await _client
          .from('feature_usage_analytics')
          .select()
          .eq('feature_id', featureId)
          .order('date', ascending: false)
          .limit(30);

      final analytics = List<Map<String, dynamic>>.from(response);

      if (analytics.isEmpty) {
        return {
          'adoption_rate': 0.0,
          'active_users': 0,
          'total_interactions': 0,
          'trend': [],
        };
      }

      return {
        'adoption_rate': analytics.first['adoption_rate'] ?? 0.0,
        'active_users': analytics.first['active_users'] ?? 0,
        'total_interactions': analytics.first['total_interactions'] ?? 0,
        'trend': analytics,
      };
    } catch (e) {
      debugPrint('Get feature usage analytics error: $e');
      return {
        'adoption_rate': 0.0,
        'active_users': 0,
        'total_interactions': 0,
        'trend': [],
      };
    }
  }

  /// Stream feature flag changes (real-time)
  Stream<List<Map<String, dynamic>>> streamFeatureFlags() {
    return _client
        .from('feature_flags')
        .stream(primaryKey: ['id'])
        .order('category')
        .order('feature_name')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Get audit logs for features
  Future<List<Map<String, dynamic>>> getFeatureAuditLogs({
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('admin_audit_logs')
          .select(
            '*, user_profiles!admin_audit_logs_admin_id_fkey(name, email)',
          )
          .eq('target_type', 'feature_flag')
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get feature audit logs error: $e');
      return [];
    }
  }

  Future<void> _logAudit({
    required String action,
    required String targetType,
    required String targetId,
    String? reason,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
  }) async {
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('admin_audit_logs').insert({
        'admin_id': userId,
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        'old_value': oldValue,
        'new_value': newValue,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log audit error: $e');
    }
  }
}
