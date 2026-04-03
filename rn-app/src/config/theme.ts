// src/config/theme.ts
// Ported from Flutter app_theme.dart — dark-first theme matching the original app

export const colors = {
  // Primary palette
  primary: '#6366F1',       // Indigo-500
  primaryLight: '#818CF8',  // Indigo-400
  primaryDark: '#4F46E5',   // Indigo-600

  // Backgrounds
  backgroundDark: '#0F172A',  // Slate-900
  surfaceDark: '#1E293B',     // Slate-800
  cardDark: '#1E293B',
  elevatedDark: '#334155',    // Slate-700

  // Text
  textPrimary: '#F8FAFC',     // Slate-50
  textSecondary: '#94A3B8',   // Slate-400
  textMuted: '#64748B',       // Slate-500

  // Status colors
  success: '#22C55E',   // Green-500
  error: '#EF4444',     // Red-500
  warning: '#EAB308',   // Yellow-500
  info: '#3B82F6',      // Blue-500

  // Borders
  border: '#334155',
  borderLight: '#475569',

  // Misc
  white: '#FFFFFF',
  black: '#000000',
  transparent: 'transparent',
  overlay: 'rgba(0, 0, 0, 0.5)',
} as const;

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
  xxxl: 32,
} as const;

export const borderRadius = {
  sm: 6,
  md: 8,
  lg: 12,
  xl: 16,
  full: 9999,
} as const;

export const typography = {
  h1: { fontSize: 28, fontWeight: '700' as const, lineHeight: 34 },
  h2: { fontSize: 22, fontWeight: '600' as const, lineHeight: 28 },
  h3: { fontSize: 18, fontWeight: '600' as const, lineHeight: 24 },
  body: { fontSize: 15, fontWeight: '400' as const, lineHeight: 22 },
  bodySmall: { fontSize: 13, fontWeight: '400' as const, lineHeight: 18 },
  caption: { fontSize: 11, fontWeight: '400' as const, lineHeight: 16 },
  button: { fontSize: 15, fontWeight: '600' as const, lineHeight: 20 },
  label: { fontSize: 13, fontWeight: '500' as const, lineHeight: 18 },
} as const;
