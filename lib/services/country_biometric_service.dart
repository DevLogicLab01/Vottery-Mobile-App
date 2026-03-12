import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './auth_service.dart';

class CountryBiometricService {
  static CountryBiometricService? _instance;
  static CountryBiometricService get instance =>
      _instance ??= CountryBiometricService._();

  CountryBiometricService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get all country biometric settings
  Future<List<Map<String, dynamic>>> getAllCountrySettings() async {
    try {
      final response = await _client
          .from('per_country_biometric_settings')
          .select()
          .order('country_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get all country settings error: $e');
      return [];
    }
  }

  /// Get biometric setting for specific country
  Future<Map<String, dynamic>?> getCountrySetting(String countryCode) async {
    try {
      final response = await _client
          .from('per_country_biometric_settings')
          .select()
          .eq('country_code', countryCode)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get country setting error: $e');
      return null;
    }
  }

  /// Check if biometrics enabled for country
  Future<bool> isBiometricEnabledForCountry(String countryCode) async {
    try {
      final setting = await getCountrySetting(countryCode);
      return setting?['biometric_enabled'] ?? true;
    } catch (e) {
      debugPrint('Check biometric enabled error: $e');
      return true;
    }
  }

  /// Update country biometric setting (Admin only)
  Future<bool> updateCountryBiometricSetting({
    required String countryCode,
    required bool biometricEnabled,
    String? complianceReason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('per_country_biometric_settings')
          .update({
            'biometric_enabled': biometricEnabled,
            'compliance_reason': complianceReason,
            'last_modified_by': _auth.currentUser!.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('country_code', countryCode);

      return true;
    } catch (e) {
      debugPrint('Update country biometric setting error: $e');
      return false;
    }
  }

  /// Apply GDPR biometric restrictions to all EU countries
  Future<bool> applyGDPRRestrictions() async {
    try {
      await _client.rpc('apply_gdpr_biometric_restrictions');
      return true;
    } catch (e) {
      debugPrint('Apply GDPR restrictions error: $e');
      return false;
    }
  }

  /// Get GDPR protected countries
  Future<List<Map<String, dynamic>>> getGDPRProtectedCountries() async {
    try {
      final response = await _client
          .from('per_country_biometric_settings')
          .select()
          .eq('gdpr_protected', true)
          .order('country_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get GDPR protected countries error: $e');
      return [];
    }
  }

  /// Get EU countries
  Future<List<Map<String, dynamic>>> getEUCountries() async {
    try {
      final response = await _client
          .from('per_country_biometric_settings')
          .select()
          .eq('is_eu_country', true)
          .order('country_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get EU countries error: $e');
      return [];
    }
  }

  /// Bulk update biometric settings for multiple countries
  Future<bool> bulkUpdateBiometricSettings({
    required List<String> countryCodes,
    required bool biometricEnabled,
    String? complianceReason,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      for (final countryCode in countryCodes) {
        await updateCountryBiometricSetting(
          countryCode: countryCode,
          biometricEnabled: biometricEnabled,
          complianceReason: complianceReason,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Bulk update biometric settings error: $e');
      return false;
    }
  }

  /// Get biometric adoption analytics by region
  Future<Map<String, dynamic>> getBiometricAdoptionAnalytics() async {
    try {
      final allSettings = await getAllCountrySettings();

      final total = allSettings.length;
      final enabled = allSettings
          .where((s) => s['biometric_enabled'] == true)
          .length;
      final disabled = total - enabled;
      final gdprProtected = allSettings
          .where((s) => s['gdpr_protected'] == true)
          .length;

      return {
        'total': total,
        'enabled': enabled,
        'disabled': disabled,
        'gdprProtected': gdprProtected,
        'enabledPercentage': total > 0
            ? (enabled / total * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      debugPrint('Get biometric adoption analytics error: $e');
      return {};
    }
  }

  /// Subscribe to real-time country biometric changes
  RealtimeChannel subscribeToCountryBiometricChanges({
    required Function(Map<String, dynamic>) onUpdate,
  }) {
    return _client
        .channel('country_biometric_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'per_country_biometric_settings',
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Validate election biometric requirement against country restrictions
  Future<Map<String, dynamic>> validateElectionBiometricRequirement({
    required List<String> targetCountries,
    required bool biometricRequired,
  }) async {
    try {
      if (!biometricRequired) {
        return {'valid': true, 'message': 'Biometric not required'};
      }

      final restrictedCountries = <String>[];

      for (final countryCode in targetCountries) {
        final setting = await getCountrySetting(countryCode);
        if (setting != null && setting['biometric_enabled'] == false) {
          restrictedCountries.add(setting['country_name']);
        }
      }

      if (restrictedCountries.isNotEmpty) {
        return {
          'valid': false,
          'message':
              'Biometric voting restricted in: ${restrictedCountries.join(", ")}',
          'restrictedCountries': restrictedCountries,
        };
      }

      return {'valid': true, 'message': 'Biometric requirement valid'};
    } catch (e) {
      debugPrint('Validate election biometric requirement error: $e');
      return {'valid': false, 'message': 'Validation failed'};
    }
  }
}
