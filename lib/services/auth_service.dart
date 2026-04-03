import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/password_validator.dart';
import './secure_storage_service.dart';
import './supabase_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Map current session to election allowed_auth_methods value (parity with Web).
  /// Returns: email_password, passkey, magic_link, oauth, or null if not logged in.
  Future<String?> getCurrentAuthMethod() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;
      final user = session.user;
      final provider =
          (user.appMetadata['provider'] as String? ?? 'email').toLowerCase();
      final amr = user.appMetadata['amr'] as List? ?? [];
      final hasPasskey = amr.any((m) => m != null && m.toString().toUpperCase() == 'PASSKEY');
      if (hasPasskey) return 'passkey';
      if (provider == 'magiclink' || provider == 'magic_link') return 'magic_link';
      if (['google', 'github', 'apple', 'azure', 'facebook'].contains(provider)) return 'oauth';
      return 'email_password';
    } catch (e) {
      debugPrint('getCurrentAuthMethod: $e');
      return null;
    }
  }

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? username,
  }) async {
    final passwordResult = PasswordValidator.validate(password);
    if (!(passwordResult['isValid'] as bool)) {
      throw AuthException(
        (passwordResult['errors'] as List<String>).join('. '),
      );
    }
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'username': username ?? email.split('@')[0],
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signInPasskeyFirst({
    required String email,
    required String password,
    bool allowPasswordFallback = true,
  }) async {
    final passkeyAttempt = await signInWithPasskey(email: email);
    if (passkeyAttempt['success'] == true) {
      return passkeyAttempt;
    }
    if (!allowPasswordFallback) {
      return {
        'success': false,
        'error': passkeyAttempt['error'] ?? 'Passkey sign-in required',
      };
    }
    try {
      final response = await signInWithEmail(email: email, password: password);
      return {'success': response.user != null, 'user': response.user};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signInWithPasskey({required String email}) async {
    try {
      final optionsResponse = await _client.functions.invoke(
        'passkey-auth-options',
        body: {'email': email},
      );
      if (optionsResponse.status >= 400) {
        return {'success': false, 'error': 'Passkey auth options unavailable'};
      }
      final verifyResponse = await _client.functions.invoke(
        'passkey-verify',
        body: {'email': email, 'platform': kIsWeb ? 'web' : 'mobile'},
      );
      if (verifyResponse.status >= 400) {
        return {'success': false, 'error': 'Passkey verification failed'};
      }
      return {'success': true, 'data': verifyResponse.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web OAuth flow
        return await _client.auth.signInWithOAuth(OAuthProvider.google);
      } else {
        // Native flow
        const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.initialize(
          serverClientId: webClientId.isNotEmpty ? webClientId : null,
        );

        GoogleSignInAccount? user = await googleSignIn.attemptLightweightAuthentication();
        user ??= await googleSignIn.authenticate();

        if (user == null) return false;

        final googleAuth = await user.authentication;
        final idToken = googleAuth.idToken;

        if (idToken == null) throw AuthException('No ID Token found');

        final response = await _client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
        );

        return response.user != null;
      }
    } catch (e) {
      debugPrint('Google sign in error: $e');
      return false;
    }
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    return signInWithOAuthProvider(OAuthProvider.apple);
  }

  // Sign in with Facebook
  Future<bool> signInWithFacebook() async {
    return signInWithOAuthProvider(OAuthProvider.facebook);
  }

  // Generic OAuth entrypoint
  Future<bool> signInWithOAuthProvider(OAuthProvider provider) async {
    try {
      final result = await _client.auth.signInWithOAuth(provider);
      return result;
    } catch (e) {
      debugPrint('OAuth sign in error ($provider): $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.signOut();
        
        // Clear secure credential storage on logout
        await SecureStorageService.instance.deleteAll();
      }
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile from database
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (!isAuthenticated) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      if (!isAuthenticated) throw Exception('User not authenticated');

      await _client
          .from('user_profiles')
          .update(updates)
          .eq('id', currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Enhanced onboarding with guided tutorials
  Future<void> startGuidedTutorial(String tutorialType) async {
    try {
      await _client.from('onboarding_progress').upsert({
        'user_id': currentUser!.id,
        'tutorial_type': tutorialType,
        'status': 'in_progress',
        'started_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Start guided tutorial error: $e');
    }
  }

  /// Track tutorial step completion
  Future<void> trackTutorialStep({
    required String tutorialType,
    required int stepNumber,
    required String stepName,
  }) async {
    try {
      await _client.from('tutorial_steps_completed').insert({
        'user_id': currentUser!.id,
        'tutorial_type': tutorialType,
        'step_number': stepNumber,
        'step_name': stepName,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Track tutorial step error: $e');
    }
  }

  /// Complete tutorial and award achievement
  Future<void> completeTutorial(String tutorialType) async {
    try {
      await _client
          .from('onboarding_progress')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUser!.id)
          .eq('tutorial_type', tutorialType);

      // Award achievement
      await _client.from('user_achievements').insert({
        'user_id': currentUser!.id,
        'achievement_type': 'tutorial_completed',
        'achievement_name': '$tutorialType Tutorial Master',
        'reward_vp': 50,
      });
    } catch (e) {
      debugPrint('Complete tutorial error: $e');
    }
  }
}
