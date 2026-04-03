// src/hooks/useAuth.ts
// Convenience hook wrapping the Zustand auth store
import { useAuthStore } from '../store/authStore';

export const useAuth = () => {
  const store = useAuthStore();
  return {
    user: store.user,
    session: store.session,
    profile: store.profile,
    isLoading: store.isLoading,
    isAuthenticated: store.isAuthenticated,
    isInitialized: store.isInitialized,
    error: store.error,
    signIn: store.signIn,
    signUp: store.signUp,
    signOut: store.signOut,
    loadProfile: store.loadProfile,
    clearError: store.clearError,
    initialize: store.initialize,
  };
};
