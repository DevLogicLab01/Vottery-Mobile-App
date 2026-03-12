import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_service.dart';

/// Loads translated strings from Supabase `translations` table
/// (language_code, namespace, translation_key, translation_value).
/// Caches per locale + namespace. Falls back to language-only code then to key.
class AppI18nService {
  static AppI18nService? _instance;
  static AppI18nService get instance => _instance ??= AppI18nService._();

  AppI18nService._();

  static const String _localeKey = 'app_selected_locale';
  final Map<String, Map<String, String>> _cache = {};

  /// Convert Flutter Locale to Supabase language_code (matches Web: en-US, zh-CN).
  static String localeToLanguageCode(Locale? locale) {
    if (locale == null) return 'en-US';
    final country = locale.countryCode;
    if (country != null && country.isNotEmpty) {
      return '${locale.languageCode}-${country.toUpperCase()}';
    }
    return locale.languageCode;
  }

  /// Persist user's selected locale (optional).
  Future<void> setSelectedLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, localeToLanguageCode(locale));
  }

  /// Get last selected locale code, if any.
  Future<String?> getSelectedLocaleCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  /// Load all keys for a namespace and locale. Tries language_code then language only.
  Future<Map<String, String>> loadNamespace({
    required Locale locale,
    required String namespace,
  }) async {
    final code = localeToLanguageCode(locale);
    final cacheKey = '${code}_$namespace';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final client = SupabaseService.instance.client;
    try {
      final List<Map<String, dynamic>> rows;
      try {
        rows = await client
            .from('translations')
            .select('translation_key, translation_value, language_code')
            .eq('namespace', namespace)
            .inFilter('language_code', [code, locale.languageCode]);
      } catch (_) {
        _cache[cacheKey] = {};
        return {};
      }

      // Prefer exact code (e.g. en-US) over language-only (en).
      rows.sort((a, b) {
        final aExact = (a['language_code'] as String?) == code ? 0 : 1;
        final bExact = (b['language_code'] as String?) == code ? 0 : 1;
        return aExact.compareTo(bExact);
      });

      final map = <String, String>{};
      for (final row in rows) {
        final key = row['translation_key'] as String?;
        final value = row['translation_value'] as String?;
        if (key != null && value != null && !map.containsKey(key)) {
          map[key] = value;
        }
      }
      _cache[cacheKey] = map;
      return map;
    } catch (e) {
      debugPrint('AppI18nService loadNamespace error: $e');
      _cache[cacheKey] = {};
      return {};
    }
  }

  /// Get one translated string. Loads namespace if not cached. Falls back to [fallback] or key.
  Future<String> t({
    required Locale locale,
    required String namespace,
    required String key,
    String? fallback,
  }) async {
    final cacheKey = '${localeToLanguageCode(locale)}_$namespace';
    if (!_cache.containsKey(cacheKey)) {
      await loadNamespace(locale: locale, namespace: namespace);
    }
    final map = _cache[cacheKey];
    if (map != null && map.containsKey(key)) {
      return map[key]!;
    }
    return fallback ?? key;
  }

  /// Synchronous lookup from cache only. Call [loadNamespace] first (e.g. in initState) to fill cache.
  String tSync({required Locale locale, required String namespace, required String key, String? fallback}) {
    final code = localeToLanguageCode(locale);
    final cacheKey = '${code}_$namespace';
    final map = _cache[cacheKey];
    if (map != null && map.containsKey(key)) return map[key]!;
    return fallback ?? key;
  }

  /// Clear in-memory cache (e.g. after admin updates translations).
  void clearCache() {
    _cache.clear();
  }
}

/// Extension to get translated string using context locale (sync from cache; load namespace first).
extension AppI18nContext on BuildContext {
  /// Returns translated string for [key] in [namespace] from cache, or [fallback]/key.
  String t(String namespace, String key, {String? fallback}) {
    final locale = Localizations.maybeLocaleOf(this) ?? const Locale('en', 'US');
    return AppI18nService.instance.tSync(
      locale: locale,
      namespace: namespace,
      key: key,
      fallback: fallback,
    );
  }
}
