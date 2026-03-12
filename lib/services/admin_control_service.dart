import '../services/supabase_service.dart';

class AdminControlService {
  static AdminControlService? _instance;
  static AdminControlService get instance =>
      _instance ??= AdminControlService._();

  AdminControlService._();

  final _supabase = SupabaseService.instance.client;

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================

  /// Get all feature flags
  Future<List<Map<String, dynamic>>> getAllFeatureFlags() async {
    try {
      final response = await _supabase
          .from('feature_flags')
          .select()
          .order('flag_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching feature flags: $e');
      return [];
    }
  }

  /// Update feature flag status
  Future<bool> updateFeatureFlag({
    required String flagKey,
    required bool isActive,
    String? changeReason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Get previous value for audit
      final previous = await _supabase
          .from('feature_flags')
          .select()
          .eq('flag_key', flagKey)
          .maybeSingle();

      // Update flag
      await _supabase
          .from('feature_flags')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('flag_key', flagKey);

      // Log audit
      await _supabase.from('feature_flag_audit_log').insert({
        'flag_key': flagKey,
        'action': isActive ? 'enabled' : 'disabled',
        'previous_value': previous,
        'new_value': {'is_active': isActive},
        'changed_by': userId,
        'change_reason': changeReason,
      });

      return true;
    } catch (e) {
      print('Error updating feature flag: $e');
      return false;
    }
  }

  /// Get feature flag audit logs
  Future<List<Map<String, dynamic>>> getFeatureFlagAuditLogs({
    String? flagKey,
    int limit = 50,
  }) async {
    try {
      dynamic query = _supabase
          .from('feature_flag_audit_log')
          .select(
            '*, user_profiles!feature_flag_audit_log_changed_by_fkey(username, email)',
          );

      if (flagKey != null) {
        query = query.eq('flag_key', flagKey);
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }

  // ============================================================================
  // COUNTRY RESTRICTIONS
  // ============================================================================

  /// Get all country restrictions
  Future<List<Map<String, dynamic>>> getAllCountryRestrictions() async {
    try {
      final response = await _supabase
          .from('country_restrictions')
          .select()
          .order('country_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching country restrictions: $e');
      return [];
    }
  }

  /// Update country restriction
  Future<bool> updateCountryRestriction({
    required String countryCode,
    bool? isAllowed,
    bool? biometricAllowed,
    int? feeZone,
    String? complianceLevel,
    String? changeReason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // Get previous value
      final previous = await _supabase
          .from('country_restrictions')
          .select()
          .eq('country_code', countryCode)
          .maybeSingle();

      // Build update map
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        'last_modified_by': userId,
      };

      if (isAllowed != null) updates['is_allowed'] = isAllowed;
      if (biometricAllowed != null) {
        updates['biometric_allowed'] = biometricAllowed;
      }
      if (feeZone != null) updates['fee_zone'] = feeZone;
      if (complianceLevel != null) {
        updates['compliance_level'] = complianceLevel;
      }
      if (changeReason != null) updates['restriction_reason'] = changeReason;

      // Update restriction
      await _supabase
          .from('country_restrictions')
          .update(updates)
          .eq('country_code', countryCode);

      // Log audit
      await _supabase.from('country_restriction_audit_log').insert({
        'country_code': countryCode,
        'action': 'updated',
        'previous_value': previous,
        'new_value': updates,
        'changed_by': userId,
        'change_reason': changeReason,
      });

      return true;
    } catch (e) {
      print('Error updating country restriction: $e');
      return false;
    }
  }

  /// Bulk update countries by region
  Future<bool> bulkUpdateCountries({
    required List<String> countryCodes,
    required bool isAllowed,
    String? changeReason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      for (final code in countryCodes) {
        await updateCountryRestriction(
          countryCode: code,
          isAllowed: isAllowed,
          changeReason: changeReason ?? 'Bulk region update',
        );
      }

      return true;
    } catch (e) {
      print('Error bulk updating countries: $e');
      return false;
    }
  }

  /// Get country restriction audit logs
  Future<List<Map<String, dynamic>>> getCountryAuditLogs({
    String? countryCode,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('country_restriction_audit_log')
          .select(
            '*, user_profiles!country_restriction_audit_log_changed_by_fkey(username, email)',
          );

      if (countryCode != null) {
        query = query.eq('country_code', countryCode);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching country audit logs: $e');
      return [];
    }
  }

  /// Get restriction violation logs
  Future<List<Map<String, dynamic>>> getViolationLogs({int limit = 100}) async {
    try {
      final response = await _supabase
          .from('restriction_violation_logs')
          .select('*, user_profiles(username, email)')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching violation logs: $e');
      return [];
    }
  }

  // ============================================================================
  // INTEGRATION SETTINGS
  // ============================================================================

  /// Get all integration settings
  Future<List<Map<String, dynamic>>> getAllIntegrationSettings() async {
    try {
      final response = await _supabase
          .from('integration_settings')
          .select()
          .order('integration_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching integration settings: $e');
      return [];
    }
  }

  /// Update integration status
  Future<bool> updateIntegrationStatus({
    required String integrationType,
    required bool isEnabled,
  }) async {
    try {
      await _supabase
          .from('integration_settings')
          .update({
            'is_enabled': isEnabled,
            'status': isEnabled ? 'active' : 'inactive',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('integration_type', integrationType);

      return true;
    } catch (e) {
      print('Error updating integration status: $e');
      return false;
    }
  }

  /// Update integration budget caps
  Future<bool> updateIntegrationBudget({
    required String integrationType,
    double? weeklyBudgetCap,
    double? monthlyBudgetCap,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (weeklyBudgetCap != null) {
        updates['weekly_budget_cap'] = weeklyBudgetCap;
      }
      if (monthlyBudgetCap != null) {
        updates['monthly_budget_cap'] = monthlyBudgetCap;
      }

      await _supabase
          .from('integration_settings')
          .update(updates)
          .eq('integration_type', integrationType);

      return true;
    } catch (e) {
      print('Error updating integration budget: $e');
      return false;
    }
  }

  /// Get integration usage logs
  Future<List<Map<String, dynamic>>> getIntegrationUsageLogs({
    String? integrationType,
    int limit = 100,
  }) async {
    try {
      var query = _supabase.from('integration_usage_logs').select();

      if (integrationType != null) {
        query = query.eq('integration_type', integrationType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching usage logs: $e');
      return [];
    }
  }

  /// Get integration usage analytics
  Future<Map<String, dynamic>> getIntegrationAnalytics(
    String integrationType,
  ) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: 7));
      final monthStart = now.subtract(Duration(days: 30));

      final weeklyLogs = await _supabase
          .from('integration_usage_logs')
          .select()
          .eq('integration_type', integrationType)
          .gte('created_at', weekStart.toIso8601String());

      final monthlyLogs = await _supabase
          .from('integration_usage_logs')
          .select()
          .eq('integration_type', integrationType)
          .gte('created_at', monthStart.toIso8601String());

      final weeklySpend = weeklyLogs.fold<double>(
        0,
        (sum, log) => sum + (log['cost_amount'] as num? ?? 0).toDouble(),
      );

      final monthlySpend = monthlyLogs.fold<double>(
        0,
        (sum, log) => sum + (log['cost_amount'] as num? ?? 0).toDouble(),
      );

      return {
        'weekly_calls': weeklyLogs.length,
        'monthly_calls': monthlyLogs.length,
        'weekly_spend': weeklySpend,
        'monthly_spend': monthlySpend,
        'weekly_success_rate': weeklyLogs.isEmpty
            ? 0.0
            : weeklyLogs.where((l) => l['success'] == true).length /
                  weeklyLogs.length *
                  100,
        'monthly_success_rate': monthlyLogs.isEmpty
            ? 0.0
            : monthlyLogs.where((l) => l['success'] == true).length /
                  monthlyLogs.length *
                  100,
      };
    } catch (e) {
      print('Error fetching integration analytics: $e');
      return {};
    }
  }

  // ============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to feature flag changes
  Stream<List<Map<String, dynamic>>> subscribeToFeatureFlags() {
    return _supabase
        .from('feature_flags')
        .stream(primaryKey: ['id'])
        .order('flag_name');
  }

  /// Subscribe to country restrictions changes
  Stream<List<Map<String, dynamic>>> subscribeToCountryRestrictions() {
    return _supabase
        .from('country_restrictions')
        .stream(primaryKey: ['id'])
        .order('country_name');
  }

  /// Subscribe to integration settings changes
  Stream<List<Map<String, dynamic>>> subscribeToIntegrationSettings() {
    return _supabase
        .from('integration_settings')
        .stream(primaryKey: ['id'])
        .order('integration_name');
  }
}
