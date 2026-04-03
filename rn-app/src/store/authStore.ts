// src/store/authStore.ts
// Zustand auth store — replaces Flutter Provider/Riverpod for auth state
import { create } from 'zustand';
import type { Session, User } from '@supabase/supabase-js';
import type { UserProfile } from '../types/auth';
import { authService } from '../services/auth';

interface AuthStore {
  user: User | null;
  session: Session | null;
  profile: UserProfile | null;
  isLoading: boolean;
  isInitialized: boolean;
  error: string | null;

  // Computed
  isAuthenticated: boolean;

  // Actions
  initialize: () => Promise<void>;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (
    email: string,
    password: string,
    fullName: string,
    username?: string,
  ) => Promise<void>;
  signOut: () => Promise<void>;
  loadProfile: () => Promise<void>;
  clearError: () => void;
  setSession: (session: Session | null) => void;
}

export const useAuthStore = create<AuthStore>((set, get) => ({
  user: null,
  session: null,
  profile: null,
  isLoading: false,
  isInitialized: false,
  isAuthenticated: false,
  error: null,

  initialize: async () => {
    let heartbeat: any;
    try {
      console.log('[AUTH] Starting initialization sequence...');
      set({ isLoading: true, error: null });
      
      // Heartbeat to confirm the loop is alive
      heartbeat = setInterval(() => {
        console.log('[AUTH] Still waiting for database response...');
      }, 2000);

      // Create a timeout so we don't hang if there's a network issue
      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Auth Network Timeout (5s)')), 5000)
      );

      console.log('[AUTH] Calling getSession()...');
      // Race the session check against our 5 second timeout
      const session = await Promise.race([
        authService.getSession(),
        timeoutPromise
      ]) as Session | null;
      
      clearInterval(heartbeat);
      console.log('[AUTH] Session result received:', session ? 'User exists' : 'No session');
      
      if (session) {
        set({
          user: session.user,
          session,
          isAuthenticated: true,
        });
        
        console.log('[AUTH] Loading profile for UID:', session.user.id);
        const profile = await authService.getUserProfile(session.user.id);
        set({ profile });
      } else {
        console.log('[AUTH] Proceeding as guest (No session)');
      }
    } catch (err: any) {
      console.warn('[AUTH] Initialization fallback (Database unreachable):', err.message);
    } finally {
      if (typeof heartbeat !== 'undefined') clearInterval(heartbeat);
      console.log('[AUTH] Initialization complete. Switching to main UI.');
      set({ isLoading: false, isInitialized: true });
    }
  },

  signIn: async (email: string, password: string) => {
    try {
      set({ isLoading: true, error: null });
      const { session, user } = await authService.signIn({ email, password });
      set({
        user: user ?? null,
        session: session ?? null,
        isAuthenticated: !!session,
        isLoading: false,
      });
      if (user) {
        const profile = await authService.getUserProfile(user.id);
        set({ profile });
      }
    } catch (err: any) {
      set({ isLoading: false, error: err.message ?? 'Sign in failed' });
      throw err;
    }
  },

  signUp: async (
    email: string,
    password: string,
    fullName: string,
    username?: string,
  ) => {
    try {
      set({ isLoading: true, error: null });
      const { session, user } = await authService.signUp({
        email,
        password,
        fullName,
        username,
      });
      console.log('[AUTH] Sign-up successful for:', email);
      set({
        user: user ?? null,
        session: session ?? null,
        isAuthenticated: !!session,
        isLoading: false,
      });
    } catch (err: any) {
      console.error('[AUTH_STORE] Sign-up FAILED:', err.message);
      console.error('[AUTH_STORE] Full Error Details:', JSON.stringify(err, null, 2));
      set({ isLoading: false, error: err.message ?? 'Sign up failed' });
      throw err;
    }
  },

  signOut: async () => {
    try {
      set({ isLoading: true, error: null });
      await authService.signOut();
      set({
        user: null,
        session: null,
        profile: null,
        isAuthenticated: false,
        isLoading: false,
      });
    } catch (err: any) {
      set({ isLoading: false, error: err.message ?? 'Sign out failed' });
    }
  },

  loadProfile: async () => {
    const user = get().user;
    if (!user) return;
    const profile = await authService.getUserProfile(user.id);
    set({ profile });
  },

  clearError: () => set({ error: null }),

  setSession: (session: Session | null) => {
    set({
      session,
      user: session?.user ?? null,
      isAuthenticated: !!session,
    });
  },
}));
