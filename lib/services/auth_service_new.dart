import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? username,
  }) async {
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

  Future<bool> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _client.auth.signInWithOAuth(OAuthProvider.google);
      } else {
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

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        final googleSignIn = GoogleSignIn.instance;
        await googleSignIn.signOut();
      }
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

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
}
