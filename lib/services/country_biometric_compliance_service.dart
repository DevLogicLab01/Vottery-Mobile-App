import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './auth_service.dart';

class CountryBiometricComplianceService {
  static CountryBiometricComplianceService? _instance;
  static CountryBiometricComplianceService get instance =>
      _instance ??= CountryBiometricComplianceService._();

  CountryBiometricComplianceService._();

  final _supabase = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  // GDPR EU country codes
  static const List<String> gdprCountries = [
    'AT',
    'BE',
    'BG',
    'HR',
    'CY',
    'CZ',
    'DK',
    'EE',
    'FI',
    'FR',
    'DE',
    'GR',
    'HU',
    'IE',
    'IT',
    'LV',
    'LT',
    'LU',
    'MT',
    'NL',
    'PL',
    'PT',
    'RO',
    'SK',
    'SI',
    'ES',
    'SE',
  ];

  /// Get all country biometric settings
  Future<List<Map<String, dynamic>>> getAllCountrySettings() async {
    try {
      final response = await _supabase
          .from('per_country_biometric_settings')
          .select()
          .order('country_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get country settings error: $e');
      return [];
    }
  }

  /// Get biometric status for specific country
  Future<BiometricStatus?> getCountryBiometricStatus(String countryCode) async {
    try {
      final response = await _supabase.rpc(
        'get_country_biometric_status',
        params: {'p_country_code': countryCode},
      );

      if (response == null || response.isEmpty) return null;

      final data = response[0] as Map<String, dynamic>;
      return BiometricStatus(
        enabled: data['enabled'] as bool,
        complianceReason: data['compliance_reason'] as String?,
        isGdpr: data['is_gdpr'] as bool,
      );
    } catch (e) {
      debugPrint('Get country biometric status error: $e');
      return null;
    }
  }

  /// Update country biometric setting
  Future<bool> updateCountryBiometricSetting({
    required String countryCode,
    required bool enabled,
    String? justification,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      // Get previous value
      final previous = await _supabase
          .from('per_country_biometric_settings')
          .select()
          .eq('country_code', countryCode)
          .maybeSingle();

      final previousValue = previous?['biometric_enabled'] as bool?;

      // Update setting
      await _supabase
          .from('per_country_biometric_settings')
          .update({
            'biometric_enabled': enabled,
            'last_modified_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('country_code', countryCode);

      // Log audit
      await _supabase.from('biometric_compliance_audit').insert({
        'country_code': countryCode,
        'action': enabled ? 'enabled' : 'disabled',
        'previous_value': previousValue,
        'new_value': enabled,
        'admin_id': userId,
        'justification': justification,
      });

      return true;
    } catch (e) {
      debugPrint('Update country biometric setting error: $e');
      return false;
    }
  }

  /// Override GDPR country (enable with liability waiver)
  Future<bool> overrideGDPRCountry({
    required String countryCode,
    required String justification,
    required bool acknowledged,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;
      if (!acknowledged) return false;

      // Verify it's a GDPR country
      if (!gdprCountries.contains(countryCode)) {
        return false;
      }

      final userId = _auth.currentUser!.id;

      // Update with override
      await _supabase
          .from('per_country_biometric_settings')
          .update({
            'biometric_enabled': true,
            'compliance_reason':
                'OVERRIDE: $justification (Liability acknowledged)',
            'last_modified_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('country_code', countryCode);

      // Log override audit
      await _supabase.from('biometric_compliance_audit').insert({
        'country_code': countryCode,
        'action': 'override_enabled',
        'previous_value': false,
        'new_value': true,
        'admin_id': userId,
        'justification': 'GDPR OVERRIDE: $justification',
      });

      return true;
    } catch (e) {
      debugPrint('Override GDPR country error: $e');
      return false;
    }
  }

  /// Bulk update region
  Future<bool> bulkUpdateRegion({
    required List<String> countryCodes,
    required bool enabled,
    String? justification,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;

      for (final countryCode in countryCodes) {
        await updateCountryBiometricSetting(
          countryCode: countryCode,
          enabled: enabled,
          justification: justification ?? 'Bulk region update',
        );
      }

      return true;
    } catch (e) {
      debugPrint('Bulk update region error: $e');
      return false;
    }
  }

  /// Get compliance statistics
  Future<Map<String, dynamic>> getComplianceStatistics() async {
    try {
      final allSettings = await getAllCountrySettings();

      final totalCountries = allSettings.length;
      final enabledCount = allSettings
          .where((s) => s['biometric_enabled'] == true)
          .length;
      final gdprCount = allSettings
          .where((s) => s['is_gdpr_country'] == true)
          .length;
      final gdprDisabledCount = allSettings
          .where(
            (s) =>
                s['is_gdpr_country'] == true && s['biometric_enabled'] == false,
          )
          .length;

      return {
        'total_countries': totalCountries,
        'enabled_count': enabledCount,
        'disabled_count': totalCountries - enabledCount,
        'gdpr_countries': gdprCount,
        'gdpr_compliant': gdprDisabledCount,
        'compliance_rate': gdprCount > 0
            ? (gdprDisabledCount / gdprCount * 100).toStringAsFixed(1)
            : '100.0',
      };
    } catch (e) {
      debugPrint('Get compliance statistics error: $e');
      return {
        'total_countries': 0,
        'enabled_count': 0,
        'disabled_count': 0,
        'gdpr_countries': 0,
        'gdpr_compliant': 0,
        'compliance_rate': '0.0',
      };
    }
  }

  /// Get biometric adoption by region
  Future<Map<String, dynamic>> getBiometricAdoptionByRegion() async {
    try {
      final allSettings = await getAllCountrySettings();

      final regions = {
        'Europe': [
          'AT',
          'BE',
          'BG',
          'HR',
          'CY',
          'CZ',
          'DK',
          'EE',
          'FI',
          'FR',
          'DE',
          'GR',
          'HU',
          'IE',
          'IT',
          'LV',
          'LT',
          'LU',
          'MT',
          'NL',
          'PL',
          'PT',
          'RO',
          'SK',
          'SI',
          'ES',
          'SE',
          'GB',
        ],
        'North America': ['US', 'CA', 'MX'],
        'Asia': ['JP', 'CN', 'IN', 'SG', 'KR'],
        'Oceania': ['AU', 'NZ'],
        'Middle East': ['AE', 'SA', 'IL'],
        'Africa': ['ZA', 'NG', 'KE', 'EG'],
        'South America': ['BR', 'AR', 'CL'],
      };

      final Map<String, dynamic> adoption = {};

      for (final region in regions.entries) {
        final regionCountries = allSettings
            .where((s) => region.value.contains(s['country_code']))
            .toList();

        final total = regionCountries.length;
        final enabled = regionCountries
            .where((s) => s['biometric_enabled'] == true)
            .length;

        adoption[region.key] = {
          'total': total,
          'enabled': enabled,
          'rate': total > 0
              ? (enabled / total * 100).toStringAsFixed(1)
              : '0.0',
        };
      }

      return adoption;
    } catch (e) {
      debugPrint('Get biometric adoption by region error: $e');
      return {};
    }
  }

  /// Get compliance audit log
  Future<List<Map<String, dynamic>>> getComplianceAuditLog({
    String? countryCode,
    int limit = 50,
  }) async {
    try {
      dynamic query = _supabase
          .from('biometric_compliance_audit')
          .select(
            '*, user_profiles!biometric_compliance_audit_admin_id_fkey(username, email)',
          );

      if (countryCode != null) {
        query = query.eq('country_code', countryCode);
      }

      query = query.order('created_at', ascending: false).limit(limit);

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get compliance audit log error: $e');
      return [];
    }
  }

  /// Validate election biometric requirement against country restrictions
  Future<ValidationResult> validateElectionBiometricRequirement({
    required List<String> targetCountries,
    required bool biometricRequired,
  }) async {
    try {
      if (!biometricRequired) {
        return ValidationResult(
          valid: true,
          message: 'No biometric requirement',
        );
      }

      final restrictedCountries = <String>[];

      for (final countryCode in targetCountries) {
        final status = await getCountryBiometricStatus(countryCode);
        if (status != null && !status.enabled) {
          restrictedCountries.add(countryCode);
        }
      }

      if (restrictedCountries.isNotEmpty) {
        return ValidationResult(
          valid: false,
          message:
              'Biometric voting not allowed in: ${restrictedCountries.join(", ")}',
          restrictedCountries: restrictedCountries,
        );
      }

      return ValidationResult(
        valid: true,
        message: 'Biometric requirement validated',
      );
    } catch (e) {
      debugPrint('Validate election biometric requirement error: $e');
      return ValidationResult(
        valid: false,
        message: 'Validation error: ${e.toString()}',
      );
    }
  }

  /// Get compliance badge for country
  String getComplianceBadge(Map<String, dynamic> countrySettings) {
    final isGdpr = countrySettings['is_gdpr_country'] as bool? ?? false;
    final enabled = countrySettings['biometric_enabled'] as bool? ?? false;

    if (isGdpr && !enabled) {
      return '🛡️ GDPR Protected';
    } else if (enabled) {
      return '✅ Enabled';
    } else {
      return '⚠️ Restricted by Law';
    }
  }
}

class BiometricStatus {
  final bool enabled;
  final String? complianceReason;
  final bool isGdpr;

  BiometricStatus({
    required this.enabled,
    this.complianceReason,
    required this.isGdpr,
  });
}

class ValidationResult {
  final bool valid;
  final String message;
  final List<String>? restrictedCountries;

  ValidationResult({
    required this.valid,
    required this.message,
    this.restrictedCountries,
  });
}
