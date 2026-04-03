// src/types/auth.ts
// TypeScript types ported from Flutter auth_service.dart and Supabase user model

export interface UserProfile {
  id: string;
  email: string;
  full_name: string;
  username: string;
  avatar_url?: string;
  role: 'user' | 'creator' | 'admin' | 'super_admin';
  bio?: string;
  country?: string;
  created_at: string;
  updated_at?: string;
}

export interface AuthState {
  user: import('@supabase/supabase-js').User | null;
  session: import('@supabase/supabase-js').Session | null;
  profile: UserProfile | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  error: string | null;
}

export interface SignUpPayload {
  email: string;
  password: string;
  fullName: string;
  username?: string;
}

export interface SignInPayload {
  email: string;
  password: string;
}
