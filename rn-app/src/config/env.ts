// src/config/env.ts
// Environment configuration - reads from process.env (Expo native support)

console.log('[ENV] Checking variables...');
console.log('[ENV] SUPABASE_URL:', process.env.EXPO_PUBLIC_SUPABASE_URL ? 'PRESENT' : 'MISSING');
console.log('[ENV] EXPO_OFFLINE Setting:', process.env.EXPO_OFFLINE);

export const ENV = {
  SUPABASE_URL: process.env.EXPO_PUBLIC_SUPABASE_URL || '',
  SUPABASE_ANON_KEY: process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY || '',
  STRIPE_PUBLISHABLE_KEY: process.env.EXPO_PUBLIC_STRIPE_PUBLISHABLE_KEY || '',
} as const;

// Dev-only check for critical configuration
if (__DEV__) {
  if (!ENV.SUPABASE_URL || !ENV.SUPABASE_ANON_KEY) {
    console.error(
      '[ENV ERROR] SUPABASE_URL or SUPABASE_ANON_KEY is missing! The app will hang on the splash screen.',
    );
  } else {
    console.log('[ENV OK] All critical variables are loaded.');
  }
}
