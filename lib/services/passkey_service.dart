import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

import './supabase_service.dart';

class PasskeyService {
  static PasskeyService? _instance;
  static PasskeyService get instance => _instance ??= PasskeyService._();

  PasskeyService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Check if passkeys are supported on this device
  Future<bool> isPasskeySupported() async {
    try {
      return false;
    } catch (e) {
      debugPrint('Error checking passkey support: $e');
      return false;
    }
  }

  // Register a new passkey
  Future<Map<String, dynamic>?> registerPasskey({
    required String userId,
    required String deviceName,
  }) async {
    try {
      debugPrint('Passkey registration not available');
      return null;
    } catch (e) {
      debugPrint('Error registering passkey: $e');
      return null;
    }
  }

  // Authenticate with passkey
  Future<bool> authenticateWithPasskey() async {
    try {
      debugPrint('Passkey authentication not available');
      return false;
    } catch (e) {
      debugPrint('Error authenticating with passkey: $e');
      await _logAuthenticationAttempt(authMethod: 'passkey', success: false);
      return false;
    }
  }

  // Get user's registered passkeys
  Future<List<Map<String, dynamic>>> getUserPasskeys() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('passkey_devices')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching user passkeys: $e');
      return [];
    }
  }

  // Revoke a passkey
  Future<bool> revokePasskey(String passkeyId) async {
    try {
      await _client
          .from('passkey_devices')
          .update({
            'is_active': false,
            'revoked_at': DateTime.now().toIso8601String(),
          })
          .eq('id', passkeyId);

      return true;
    } catch (e) {
      debugPrint('Error revoking passkey: $e');
      return false;
    }
  }

  // Update passkey last used timestamp
  Future<void> _updatePasskeyLastUsed(String credentialId) async {
    try {
      await _client.rpc(
        'update_passkey_last_used',
        params: {'p_credential_id': credentialId},
      );
    } catch (e) {
      debugPrint('Error updating passkey last used: $e');
    }
  }

  // Log authentication attempt
  Future<void> _logAuthenticationAttempt({
    required String authMethod,
    required bool success,
    String? electionId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;

      await _client.from('authentication_audit_log').insert({
        'user_id': userId,
        'election_id': electionId,
        'auth_method': authMethod,
        'success': success,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging authentication attempt: $e');
    }
  }

  // Generate random challenge for WebAuthn
  String _generateChallenge() {
    final random = List<int>.generate(
      32,
      (i) => DateTime.now().millisecondsSinceEpoch % 256,
    );
    return base64Encode(random);
  }

  // Get authentication audit logs
  Future<List<Map<String, dynamic>>> getAuthenticationAuditLogs({
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('authentication_audit_log')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching authentication audit logs: $e');
      return [];
    }
  }
}
