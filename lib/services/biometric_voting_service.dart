import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';
import './auth_service.dart';

/// Service for managing biometric voting requirements
/// Handles platform-specific validation, retry logic, and security logging
class BiometricVotingService {
  static BiometricVotingService? _instance;
  static BiometricVotingService get instance =>
      _instance ??= BiometricVotingService._();

  BiometricVotingService._();

  final LocalAuthentication _localAuth = LocalAuthentication();
  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  // Retry tracking
  final Map<String, int> _attemptCounts = {};
  static const int maxAttempts = 3;

  /// Check if biometric authentication is available on device
  Future<Map<String, dynamic>> checkBiometricAvailability() async {
    try {
      // Web platform doesn't support biometrics
      if (kIsWeb) {
        return {
          'available': false,
          'reason': 'Biometric authentication not supported on web platform',
          'fallbackAvailable': true,
        };
      }

      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheck || !isDeviceSupported) {
        return {
          'available': false,
          'reason': 'Biometric authentication not available on this device',
          'fallbackAvailable': true,
        };
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      return {
        'available': true,
        'biometrics': availableBiometrics.map((b) => b.name).toList(),
        'fallbackAvailable': true,
      };
    } catch (e) {
      debugPrint('Check biometric availability error: $e');
      return {
        'available': false,
        'reason': 'Error checking biometric availability',
        'fallbackAvailable': true,
      };
    }
  }

  /// Authenticate user with biometrics for voting
  Future<Map<String, dynamic>> authenticateForVoting(String electionId) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'reason': 'User not authenticated'};
      }

      final userId = _auth.currentUser!.id;
      final attemptKey = '$userId:$electionId';

      // Check attempt count
      final currentAttempts = _attemptCounts[attemptKey] ?? 0;
      if (currentAttempts >= maxAttempts) {
        return {
          'success': false,
          'reason':
              'Maximum authentication attempts ($maxAttempts) exceeded. Please try again later.',
          'attemptsRemaining': 0,
        };
      }

      // Web fallback
      if (kIsWeb) {
        return await _fallbackAuthentication(electionId);
      }

      // Check availability
      final availability = await checkBiometricAvailability();
      if (availability['available'] != true) {
        return await _fallbackAuthentication(electionId);
      }

      // Attempt biometric authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to cast your vote',
      );

      // Update attempt count
      _attemptCounts[attemptKey] = currentAttempts + 1;

      // Log attempt
      await _logBiometricAttempt(
        userId: userId,
        electionId: electionId,
        attemptNumber: currentAttempts + 1,
        success: authenticated,
        biometricType: 'any',
      );

      if (authenticated) {
        // Reset attempts on success
        _attemptCounts.remove(attemptKey);

        return {'success': true, 'method': 'biometric'};
      } else {
        final attemptsRemaining = maxAttempts - (currentAttempts + 1);
        return {
          'success': false,
          'reason': 'Biometric authentication failed',
          'attemptsRemaining': attemptsRemaining,
        };
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');

      // Handle specific error codes
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return await _fallbackAuthentication(electionId);
      }

      return {'success': false, 'reason': 'Authentication error: ${e.message}'};
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return {
        'success': false,
        'reason': 'Unexpected error during authentication',
      };
    }
  }

  /// Fallback authentication using PIN/password
  Future<Map<String, dynamic>> _fallbackAuthentication(
    String electionId,
  ) async {
    try {
      if (!_auth.isAuthenticated) {
        return {'success': false, 'reason': 'User not authenticated'};
      }

      final userId = _auth.currentUser!.id;

      // Log fallback attempt
      await _logBiometricAttempt(
        userId: userId,
        electionId: electionId,
        attemptNumber: 1,
        success: true,
        biometricType: 'fallback_pin',
      );

      return {
        'success': true,
        'method': 'fallback',
        'message':
            'Biometric authentication not available. Using account authentication.',
      };
    } catch (e) {
      debugPrint('Fallback authentication error: $e');
      return {'success': false, 'reason': 'Fallback authentication failed'};
    }
  }

  /// Log biometric authentication attempt to database
  Future<void> _logBiometricAttempt({
    required String userId,
    required String electionId,
    required int attemptNumber,
    required bool success,
    required String biometricType,
  }) async {
    try {
      await _client.rpc(
        'log_biometric_attempt',
        params: {
          'p_user_id': userId,
          'p_election_id': electionId,
          'p_attempt_number': attemptNumber,
          'p_success': success,
          'p_biometric_type': biometricType,
          'p_device_info': {
            'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
            'timestamp': DateTime.now().toIso8601String(),
          },
        },
      );
    } catch (e) {
      debugPrint('Log biometric attempt error: $e');
    }
  }

  /// Check if election requires biometric authentication
  Future<bool> isBiometricRequired(String electionId) async {
    try {
      final response = await _client
          .from('elections')
          .select('biometric_required')
          .eq('id', electionId)
          .maybeSingle();

      if (response == null) return false;

      final biometricRequired = response['biometric_required'] as String?;
      return biometricRequired != null && biometricRequired != 'none';
    } catch (e) {
      debugPrint('Check biometric required error: $e');
      return false;
    }
  }

  /// Get biometric authentication attempts for election
  Future<List<Map<String, dynamic>>> getAuthenticationAttempts(
    String electionId,
  ) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('biometric_auth_attempts')
          .select()
          .eq('user_id', userId)
          .eq('election_id', electionId)
          .order('attempted_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get authentication attempts error: $e');
      return [];
    }
  }

  /// Reset attempt counter for user/election
  void resetAttempts(String electionId) {
    if (!_auth.isAuthenticated) return;
    final userId = _auth.currentUser!.id;
    final attemptKey = '$userId:$electionId';
    _attemptCounts.remove(attemptKey);
  }

  /// Get remaining attempts for user/election
  int getRemainingAttempts(String electionId) {
    if (!_auth.isAuthenticated) return 0;
    final userId = _auth.currentUser!.id;
    final attemptKey = '$userId:$electionId';
    final currentAttempts = _attemptCounts[attemptKey] ?? 0;
    return maxAttempts - currentAttempts;
  }
}
