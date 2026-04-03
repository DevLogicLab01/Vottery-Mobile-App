// src/lib/supabase.ts
// Supabase client — ported from Flutter supabase_service.dart
import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';
import { ENV } from '../config/env';

console.log('[SUPABASE] Initializing client with persistence...');
export const supabase = createClient(ENV.SUPABASE_URL, ENV.SUPABASE_ANON_KEY, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
console.log('[SUPABASE] Client ready.');
