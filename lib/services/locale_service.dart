import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// LocaleService – canonical supported locales backed by Supabase `supported_locales` table.
class LocaleService {
  LocaleService._();
  static LocaleService? _instance;
  static LocaleService get instance => _instance ??= LocaleService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getSupportedLocales() async {
    try {
      final response = await _client
          .from('supported_locales')
          .select(
              'locale_code, language_code, region_code, name, is_default, sort_order')
          .eq('enabled', true)
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('LocaleService.getSupportedLocales error: $e');
      return [];
    }
  }
}

