// src/types/react-native-config.d.ts
// Type declarations for react-native-config environment variables
declare module 'react-native-config' {
  export interface NativeConfig {
    SUPABASE_URL?: string;
    SUPABASE_ANON_KEY?: string;
    STRIPE_PUBLISHABLE_KEY?: string;
    GOOGLE_WEB_CLIENT_ID?: string;
    SENTRY_DSN?: string;
  }

  export const Config: NativeConfig;
  export default Config;
}
