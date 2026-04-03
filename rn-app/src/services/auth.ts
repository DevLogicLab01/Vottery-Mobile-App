// src/services/auth.ts
// Auth service — ported from Flutter auth_service.dart
// Covers: sign up, sign in, sign out, session restore, profile fetch
import { supabase } from '../lib/supabase';
import type { SignUpPayload, SignInPayload, UserProfile } from '../types/auth';

class AuthService {
  /** Sign up with email + password (mirrors Flutter signUpWithEmail) */
  async signUp({ email, password, fullName, username }: SignUpPayload) {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          full_name: fullName,
          username: username ?? email.split('@')[0],
        },
      },
    });
    if (error) throw error;
    return data;
  }

  /** Sign in with email + password (mirrors Flutter signInWithEmail) */
  async signIn({ email, password }: SignInPayload) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });
    if (error) throw error;
    return data;
  }

  /** Sign out (mirrors Flutter signOut) */
  async signOut() {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
  }

  /** Get current session (Robust version) */
  async getSession() {
    try {
      console.log('[AUTH_SERVICE] Requesting session from Supabase...');
      const { data, error } = await supabase.auth.getSession();
      if (error) {
        console.warn('[AUTH_SERVICE] Supabase returned session error:', error.message);
        return null;
      }
      return data.session;
    } catch (err: any) {
      console.error('[AUTH_SERVICE] CRASH in getSession:', err.message);
      return null; // Return null to proceed to login instead of crashing
    }
  }

  /** Reset password (mirrors Flutter resetPassword) */
  async resetPassword(email: string) {
    const { error } = await supabase.auth.resetPasswordForEmail(email);
    if (error) throw error;
  }

  /** Fetch user profile from user_profiles table (mirrors Flutter getUserProfile) */
  async getUserProfile(userId: string): Promise<UserProfile | null> {
    try {
      console.log('[AUTH_SERVICE] Fetching profile for:', userId);
      const { data, error } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();
      if (error) {
        console.warn('[AUTH_SERVICE] getUserProfile error:', error.message);
        return null;
      }
      return data as UserProfile | null;
    } catch (err: any) {
      console.error('[AUTH_SERVICE] CRASH in getUserProfile:', err.message);
      return null;
    }
  }

  /** Update user profile (mirrors Flutter updateUserProfile) */
  async updateUserProfile(userId: string, updates: Partial<UserProfile>) {
    const { error } = await supabase
      .from('user_profiles')
      .update(updates)
      .eq('id', userId);
    if (error) throw error;
  }

  /** Listen to auth state changes */
  onAuthStateChange(
    callback: (
      event: string,
      session: import('@supabase/supabase-js').Session | null,
    ) => void,
  ) {
    return supabase.auth.onAuthStateChange(callback);
  }
}

export const authService = new AuthService();
