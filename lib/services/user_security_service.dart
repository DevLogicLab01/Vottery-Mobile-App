import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './notification_cost_optimizer_service.dart';

class UserSecurityService {
  static UserSecurityService? _instance;
  static UserSecurityService get instance =>
      _instance ??= UserSecurityService._();

  UserSecurityService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // =====================================================
  // FRAUD RISK SCORE
  // =====================================================

  Future<Map<String, dynamic>?> getFraudRiskScore() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('user_fraud_risk_scores')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get fraud risk score error: $e');
      return null;
    }
  }

  // =====================================================
  // SECURITY EVENTS
  // =====================================================

  Future<List<Map<String, dynamic>>> getSecurityEvents({
    String? eventType,
    String? threatLevel,
    int limit = 50,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client
          .from('user_security_events')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      if (eventType != null) {
        query = query.eq('event_type', eventType);
      }

      if (threatLevel != null) {
        query = query.eq('threat_level', threatLevel);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get security events error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getSecurityEventsSummary() async {
    try {
      if (!_auth.isAuthenticated) {
        return {
          'total': 0,
          'critical': 0,
          'high': 0,
          'medium': 0,
          'low': 0,
          'unresolved': 0,
        };
      }

      final response = await _client
          .from('user_security_events')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      final total = response.length;
      final critical = response
          .where((e) => e['threat_level'] == 'critical')
          .length;
      final high = response.where((e) => e['threat_level'] == 'high').length;
      final medium = response
          .where((e) => e['threat_level'] == 'medium')
          .length;
      final low = response.where((e) => e['threat_level'] == 'low').length;
      final unresolved = response
          .where((e) => e['is_resolved'] == false)
          .length;

      return {
        'total': total,
        'critical': critical,
        'high': high,
        'medium': medium,
        'low': low,
        'unresolved': unresolved,
      };
    } catch (e) {
      debugPrint('Get security events summary error: $e');
      return {
        'total': 0,
        'critical': 0,
        'high': 0,
        'medium': 0,
        'low': 0,
        'unresolved': 0,
      };
    }
  }

  Future<bool> resolveSecurityEvent(
    String eventId,
    String resolutionAction,
  ) async {
    try {
      await _client
          .from('user_security_events')
          .update({
            'is_resolved': true,
            'resolved_at': DateTime.now().toIso8601String(),
            'resolution_action': resolutionAction,
          })
          .eq('id', eventId);

      return true;
    } catch (e) {
      debugPrint('Resolve security event error: $e');
      return false;
    }
  }

  // =====================================================
  // TRUSTED DEVICES
  // =====================================================

  Future<List<Map<String, dynamic>>> getTrustedDevices() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('trusted_devices')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('last_used_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get trusted devices error: $e');
      return [];
    }
  }

  Future<bool> revokeDevice(String deviceId) async {
    try {
      await _client
          .from('trusted_devices')
          .update({
            'is_trusted': false,
            'revoked_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deviceId);

      return true;
    } catch (e) {
      debugPrint('Revoke device error: $e');
      return false;
    }
  }

  Future<bool> authorizeDevice(String deviceId) async {
    try {
      await _client
          .from('trusted_devices')
          .update({
            'is_trusted': true,
            'authorization_date': DateTime.now().toIso8601String(),
            'revoked_at': null,
          })
          .eq('id', deviceId);

      return true;
    } catch (e) {
      debugPrint('Authorize device error: $e');
      return false;
    }
  }

  // =====================================================
  // SECURITY SETTINGS
  // =====================================================

  Future<Map<String, dynamic>?> getSecuritySettings() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('user_security_settings')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get security settings error: $e');
      return null;
    }
  }

  Future<bool> updateSecuritySettings({
    bool? twoFactorEnabled,
    String? twoFactorMethod,
    String? twoFactorPhone,
    bool? biometricEnabled,
    String? biometricType,
    int? sessionTimeoutMinutes,
    bool? breachNotificationsEnabled,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final updates = <String, dynamic>{};

      if (twoFactorEnabled != null) {
        updates['two_factor_enabled'] = twoFactorEnabled;
      }
      if (twoFactorMethod != null) {
        updates['two_factor_method'] = twoFactorMethod;
      }
      if (twoFactorPhone != null) updates['two_factor_phone'] = twoFactorPhone;
      if (biometricEnabled != null) {
        updates['biometric_enabled'] = biometricEnabled;
      }
      if (biometricType != null) updates['biometric_type'] = biometricType;
      if (sessionTimeoutMinutes != null) {
        updates['session_timeout_minutes'] = sessionTimeoutMinutes;
      }
      if (breachNotificationsEnabled != null) {
        updates['breach_notifications_enabled'] = breachNotificationsEnabled;
      }

      if (updates.isEmpty) return false;

      updates['updated_at'] = DateTime.now().toIso8601String();

      // Check if settings exist
      final existing = await getSecuritySettings();

      if (existing == null) {
        // Create new settings
        updates['user_id'] = _auth.currentUser!.id;
        await _client.from('user_security_settings').insert(updates);
      } else {
        // Update existing settings
        await _client
            .from('user_security_settings')
            .update(updates)
            .eq('user_id', _auth.currentUser!.id);
      }

      return true;
    } catch (e) {
      debugPrint('Update security settings error: $e');
      return false;
    }
  }

  // =====================================================
  // TWO-FACTOR CHALLENGE FLOW (EMAIL / SMS)
  // =====================================================

  Future<bool> sendTwoFactorCode({
    required String method,
    required String recipient,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;
      final normalizedMethod = method.toLowerCase();
      if (recipient.trim().isEmpty) return false;

      if (normalizedMethod == 'email') {
        await _client.auth.signInWithOtp(
          email: recipient.trim(),
          shouldCreateUser: false,
        );
        return true;
      }

      if (normalizedMethod == 'sms') {
        final smsAllowed = NotificationCostOptimizerService.instance
            .isSmsAllowedUseCase('otp_fallback');
        if (!smsAllowed) return false;
        await _client.auth.signInWithOtp(
          phone: recipient.trim(),
          shouldCreateUser: false,
        );
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('sendTwoFactorCode error: $e');
      return false;
    }
  }

  Future<bool> verifyTwoFactorCode({
    required String method,
    required String recipient,
    required String code,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;
      final normalizedMethod = method.toLowerCase();
      if (recipient.trim().isEmpty || code.trim().isEmpty) return false;

      if (normalizedMethod == 'email') {
        final response = await _client.auth.verifyOTP(
          email: recipient.trim(),
          token: code.trim(),
          type: OtpType.email,
        );
        return response.user != null;
      }

      if (normalizedMethod == 'sms') {
        final smsAllowed = NotificationCostOptimizerService.instance
            .isSmsAllowedUseCase('otp_fallback');
        if (!smsAllowed) return false;
        final response = await _client.auth.verifyOTP(
          phone: recipient.trim(),
          token: code.trim(),
          type: OtpType.sms,
        );
        return response.user != null;
      }

      return false;
    } catch (e) {
      debugPrint('verifyTwoFactorCode error: $e');
      return false;
    }
  }

  Future<bool> verifyAuthenticatorCode({
    required String code,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;
      final token = code.trim();
      if (token.isEmpty) return false;

      final result = await _client.functions.invoke(
        'mfa-verify',
        body: {
          'userId': _auth.currentUser!.id,
          'token': token,
        },
      );

      if (result.status >= 400) return false;
      final data = result.data;
      if (data is Map<String, dynamic>) {
        return data['valid'] == true || data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('verifyAuthenticatorCode error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> setupAuthenticator() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final result = await _client.functions.invoke(
        'mfa-setup',
        body: {'userId': _auth.currentUser!.id},
      );

      if (result.status >= 400) return null;
      if (result.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(result.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('setupAuthenticator error: $e');
      return null;
    }
  }

  // =====================================================
  // ACTIVE SESSIONS
  // =====================================================

  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('user_active_sessions')
          .select('*, trusted_devices(*)')
          .eq('user_id', _auth.currentUser!.id)
          .order('last_activity_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active sessions error: $e');
      return [];
    }
  }

  Future<bool> terminateSession(String sessionId) async {
    try {
      await _client.from('user_active_sessions').delete().eq('id', sessionId);
      return true;
    } catch (e) {
      debugPrint('Terminate session error: $e');
      return false;
    }
  }

  // =====================================================
  // SECURITY AUDIT TRAIL
  // =====================================================

  Future<List<Map<String, dynamic>>> getSecurityAuditTrail({
    int limit = 100,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('security_audit_trail')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get security audit trail error: $e');
      return [];
    }
  }

  Future<String?> exportSecurityAuditTrail() async {
    try {
      final auditTrail = await getSecurityAuditTrail(limit: 1000);

      if (auditTrail.isEmpty) return null;

      // Generate CSV format
      final buffer = StringBuffer();
      buffer.writeln(
        'Timestamp,Action Type,Description,IP Address,Device Fingerprint',
      );

      for (final entry in auditTrail) {
        buffer.writeln(
          '${entry['created_at']},${entry['action_type']},"${entry['action_description']}",${entry['ip_address'] ?? 'N/A'},${entry['device_fingerprint'] ?? 'N/A'}',
        );
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('Export security audit trail error: $e');
      return null;
    }
  }

  // =====================================================
  // GDPR RIGHTS
  // =====================================================

  Future<bool> requestGdprExport({Map<String, dynamic>? details}) async {
    try {
      if (!_auth.isAuthenticated) return false;
      await _client.from('gdpr_requests').insert({
        'user_id': _auth.currentUser!.id,
        'request_type': 'export',
        'details': details ?? <String, dynamic>{},
      });
      return true;
    } catch (e) {
      debugPrint('requestGdprExport error: $e');
      return false;
    }
  }

  Future<bool> requestGdprDeletion({Map<String, dynamic>? details}) async {
    try {
      if (!_auth.isAuthenticated) return false;
      await _client.from('gdpr_requests').insert({
        'user_id': _auth.currentUser!.id,
        'request_type': 'deletion',
        'details': details ?? <String, dynamic>{},
      });
      return true;
    } catch (e) {
      debugPrint('requestGdprDeletion error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getConsentPreferences() async {
    try {
      if (!_auth.isAuthenticated) return null;
      final data = await _client
          .from('user_consent_preferences')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('getConsentPreferences error: $e');
      return null;
    }
  }

  Future<bool> updateConsentPreferences({
    bool? analyticsConsent,
    bool? marketingConsent,
    bool? personalizationConsent,
    bool? aiDecisioningConsent,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;
      final payload = <String, dynamic>{
        'user_id': _auth.currentUser!.id,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (analyticsConsent != null) payload['analytics_consent'] = analyticsConsent;
      if (marketingConsent != null) payload['marketing_consent'] = marketingConsent;
      if (personalizationConsent != null) payload['personalization_consent'] = personalizationConsent;
      if (aiDecisioningConsent != null) payload['ai_decisioning_consent'] = aiDecisioningConsent;
      await _client.from('user_consent_preferences').upsert(payload);
      return true;
    } catch (e) {
      debugPrint('updateConsentPreferences error: $e');
      return false;
    }
  }
}
