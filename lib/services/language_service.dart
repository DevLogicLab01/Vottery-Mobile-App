import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class LanguageService {
  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();

  LanguageService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Get user's language preference
  Future<Map<String, dynamic>?> getUserLanguagePreference() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('user_language_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching language preference: $e');
      return null;
    }
  }

  // Save user's language preference
  Future<bool> saveLanguagePreference({
    required String languageCode,
    bool? autoDetect,
    bool? rtlEnabled,
    String? dateFormat,
    String? timeFormat,
    String? numberFormat,
    String? currencyFormat,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final data = {
        'user_id': userId,
        'language_code': languageCode,
        if (autoDetect != null) 'auto_detect': autoDetect,
        if (rtlEnabled != null) 'rtl_enabled': rtlEnabled,
        if (dateFormat != null) 'date_format': dateFormat,
        if (timeFormat != null) 'time_format': timeFormat,
        if (numberFormat != null) 'number_format': numberFormat,
        if (currencyFormat != null) 'currency_format': currencyFormat,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('user_language_preferences').upsert(data);

      return true;
    } catch (e) {
      debugPrint('Error saving language preference: $e');
      return false;
    }
  }

  // Get supported languages with metadata
  List<Map<String, dynamic>> getSupportedLanguages() {
    return [
      {
        'code': 'af',
        'name': 'Afrikaans',
        'nativeName': 'Afrikaans',
        'rtl': false,
        'flag': '🇿🇦',
      },
      {
        'code': 'sq',
        'name': 'Albanian',
        'nativeName': 'Shqip',
        'rtl': false,
        'flag': '🇦🇱',
      },
      {
        'code': 'ar',
        'name': 'Arabic',
        'nativeName': 'العربية',
        'rtl': true,
        'flag': '🇸🇦',
      },
      {
        'code': 'hy',
        'name': 'Armenian',
        'nativeName': 'Հայերեն',
        'rtl': false,
        'flag': '🇦🇲',
      },
      {
        'code': 'ay',
        'name': 'Aymara',
        'nativeName': 'Aymar aru',
        'rtl': false,
        'flag': '🇧🇴',
      },
      {
        'code': 'az',
        'name': 'Azeri',
        'nativeName': 'Azərbaycan',
        'rtl': false,
        'flag': '🇦🇿',
      },
      {
        'code': 'eu',
        'name': 'Basque',
        'nativeName': 'Euskara',
        'rtl': false,
        'flag': '🇪🇸',
      },
      {
        'code': 'be',
        'name': 'Belarusian',
        'nativeName': 'Беларуская',
        'rtl': false,
        'flag': '🇧🇾',
      },
      {
        'code': 'bn',
        'name': 'Bengali',
        'nativeName': 'বাংলা',
        'rtl': false,
        'flag': '🇧🇩',
      },
      {
        'code': 'bs',
        'name': 'Bosnian',
        'nativeName': 'Bosanski',
        'rtl': false,
        'flag': '🇧🇦',
      },
      {
        'code': 'bg',
        'name': 'Bulgarian',
        'nativeName': 'Български',
        'rtl': false,
        'flag': '🇧🇬',
      },
      {
        'code': 'ca',
        'name': 'Catalan',
        'nativeName': 'Català',
        'rtl': false,
        'flag': '🇪🇸',
      },
      {
        'code': 'chr',
        'name': 'Cherokee',
        'nativeName': 'ᏣᎳᎩ',
        'rtl': false,
        'flag': '🇺🇸',
      },
      {
        'code': 'zh-CN',
        'name': 'Chinese (Simplified)',
        'nativeName': '简体中文',
        'rtl': false,
        'flag': '🇨🇳',
      },
      {
        'code': 'zh-TW',
        'name': 'Chinese (Traditional Taiwan)',
        'nativeName': '繁體中文',
        'rtl': false,
        'flag': '🇹🇼',
      },
      {
        'code': 'zh-HK',
        'name': 'Chinese (Traditional Hong Kong)',
        'nativeName': '繁體中文',
        'rtl': false,
        'flag': '🇭🇰',
      },
      {
        'code': 'hr',
        'name': 'Croatian',
        'nativeName': 'Hrvatski',
        'rtl': false,
        'flag': '🇭🇷',
      },
      {
        'code': 'cs',
        'name': 'Czech',
        'nativeName': 'Čeština',
        'rtl': false,
        'flag': '🇨🇿',
      },
      {
        'code': 'da',
        'name': 'Danish',
        'nativeName': 'Dansk',
        'rtl': false,
        'flag': '🇩🇰',
      },
      {
        'code': 'nl',
        'name': 'Dutch',
        'nativeName': 'Nederlands',
        'rtl': false,
        'flag': '🇳🇱',
      },
      {
        'code': 'nl-BE',
        'name': 'Dutch (België)',
        'nativeName': 'Nederlands (België)',
        'rtl': false,
        'flag': '🇧🇪',
      },
      {
        'code': 'en',
        'name': 'English (US)',
        'nativeName': 'English (US)',
        'rtl': false,
        'flag': '🇺🇸',
      },
      {
        'code': 'en-GB',
        'name': 'English (UK)',
        'nativeName': 'English (UK)',
        'rtl': false,
        'flag': '🇬🇧',
      },
      {
        'code': 'en-IN',
        'name': 'English (India)',
        'nativeName': 'English (India)',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'eo',
        'name': 'Esperanto',
        'nativeName': 'Esperanto',
        'rtl': false,
        'flag': '🌍',
      },
      {
        'code': 'et',
        'name': 'Estonian',
        'nativeName': 'Eesti',
        'rtl': false,
        'flag': '🇪🇪',
      },
      {
        'code': 'fo',
        'name': 'Faroese',
        'nativeName': 'Føroyskt',
        'rtl': false,
        'flag': '🇫🇴',
      },
      {
        'code': 'tl',
        'name': 'Filipino',
        'nativeName': 'Filipino',
        'rtl': false,
        'flag': '🇵🇭',
      },
      {
        'code': 'fi',
        'name': 'Finnish',
        'nativeName': 'Suomi',
        'rtl': false,
        'flag': '🇫🇮',
      },
      {
        'code': 'fr',
        'name': 'French (France)',
        'nativeName': 'Français',
        'rtl': false,
        'flag': '🇫🇷',
      },
      {
        'code': 'fr-CA',
        'name': 'French (Canada)',
        'nativeName': 'Français (Canada)',
        'rtl': false,
        'flag': '🇨🇦',
      },
      {
        'code': 'fy',
        'name': 'Frisian',
        'nativeName': 'Frysk',
        'rtl': false,
        'flag': '🇳🇱',
      },
      {
        'code': 'gl',
        'name': 'Galician',
        'nativeName': 'Galego',
        'rtl': false,
        'flag': '🇪🇸',
      },
      {
        'code': 'ka',
        'name': 'Georgian',
        'nativeName': 'ქართული',
        'rtl': false,
        'flag': '🇬🇪',
      },
      {
        'code': 'de',
        'name': 'German',
        'nativeName': 'Deutsch',
        'rtl': false,
        'flag': '🇩🇪',
      },
      {
        'code': 'el',
        'name': 'Greek (Modern)',
        'nativeName': 'Ελληνικά',
        'rtl': false,
        'flag': '🇬🇷',
      },
      {
        'code': 'grc',
        'name': 'Greek (Classical)',
        'nativeName': 'Ἑλληνική',
        'rtl': false,
        'flag': '🇬🇷',
      },
      {
        'code': 'gn',
        'name': 'Guaraní',
        'nativeName': 'Avañe\'ẽ',
        'rtl': false,
        'flag': '🇵🇾',
      },
      {
        'code': 'gu',
        'name': 'Gujarati',
        'nativeName': 'ગુજરાતી',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'he',
        'name': 'Hebrew',
        'nativeName': 'עברית',
        'rtl': true,
        'flag': '🇮🇱',
      },
      {
        'code': 'hi',
        'name': 'Hindi',
        'nativeName': 'हिन्दी',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'hu',
        'name': 'Hungarian',
        'nativeName': 'Magyar',
        'rtl': false,
        'flag': '🇭🇺',
      },
      {
        'code': 'is',
        'name': 'Icelandic',
        'nativeName': 'Íslenska',
        'rtl': false,
        'flag': '🇮🇸',
      },
      {
        'code': 'id',
        'name': 'Indonesian',
        'nativeName': 'Bahasa Indonesia',
        'rtl': false,
        'flag': '🇮🇩',
      },
      {
        'code': 'ga',
        'name': 'Irish',
        'nativeName': 'Gaeilge',
        'rtl': false,
        'flag': '🇮🇪',
      },
      {
        'code': 'it',
        'name': 'Italian',
        'nativeName': 'Italiano',
        'rtl': false,
        'flag': '🇮🇹',
      },
      {
        'code': 'ja',
        'name': 'Japanese',
        'nativeName': '日本語',
        'rtl': false,
        'flag': '🇯🇵',
      },
      {
        'code': 'jv',
        'name': 'Javanese',
        'nativeName': 'Basa Jawa',
        'rtl': false,
        'flag': '🇮🇩',
      },
      {
        'code': 'kn',
        'name': 'Kannada',
        'nativeName': 'ಕನ್ನಡ',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'kk',
        'name': 'Kazakh',
        'nativeName': 'Қазақша',
        'rtl': false,
        'flag': '🇰🇿',
      },
      {
        'code': 'km',
        'name': 'Khmer',
        'nativeName': 'ភាសាខ្មែរ',
        'rtl': false,
        'flag': '🇰🇭',
      },
      {
        'code': 'ko',
        'name': 'Korean',
        'nativeName': '한국어',
        'rtl': false,
        'flag': '🇰🇷',
      },
      {
        'code': 'ku',
        'name': 'Kurdish',
        'nativeName': 'Kurdî',
        'rtl': false,
        'flag': '🇮🇶',
      },
      {
        'code': 'la',
        'name': 'Latin',
        'nativeName': 'Latina',
        'rtl': false,
        'flag': '🇻🇦',
      },
      {
        'code': 'lv',
        'name': 'Latvian',
        'nativeName': 'Latviešu',
        'rtl': false,
        'flag': '🇱🇻',
      },
      {
        'code': 'li',
        'name': 'Limburgish',
        'nativeName': 'Limburgs',
        'rtl': false,
        'flag': '🇳🇱',
      },
      {
        'code': 'lt',
        'name': 'Lithuanian',
        'nativeName': 'Lietuvių',
        'rtl': false,
        'flag': '🇱🇹',
      },
      {
        'code': 'mk',
        'name': 'Macedonian',
        'nativeName': 'Македонски',
        'rtl': false,
        'flag': '🇲🇰',
      },
      {
        'code': 'mg',
        'name': 'Malagasy',
        'nativeName': 'Malagasy',
        'rtl': false,
        'flag': '🇲🇬',
      },
      {
        'code': 'ms',
        'name': 'Malay',
        'nativeName': 'Bahasa Melayu',
        'rtl': false,
        'flag': '🇲🇾',
      },
      {
        'code': 'ml',
        'name': 'Malayalam',
        'nativeName': 'മലയാളം',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'mt',
        'name': 'Maltese',
        'nativeName': 'Malti',
        'rtl': false,
        'flag': '🇲🇹',
      },
      {
        'code': 'mr',
        'name': 'Marathi',
        'nativeName': 'मराठी',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'mn',
        'name': 'Mongolian',
        'nativeName': 'Монгол',
        'rtl': false,
        'flag': '🇲🇳',
      },
      {
        'code': 'ne',
        'name': 'Nepali',
        'nativeName': 'नेपाली',
        'rtl': false,
        'flag': '🇳🇵',
      },
      {
        'code': 'se',
        'name': 'Northern Sámi',
        'nativeName': 'Davvisámegiella',
        'rtl': false,
        'flag': '🇳🇴',
      },
      {
        'code': 'nb',
        'name': 'Norwegian (Bokmål)',
        'nativeName': 'Norsk bokmål',
        'rtl': false,
        'flag': '🇳🇴',
      },
      {
        'code': 'nn',
        'name': 'Norwegian (Nynorsk)',
        'nativeName': 'Norsk nynorsk',
        'rtl': false,
        'flag': '🇳🇴',
      },
      {
        'code': 'ps',
        'name': 'Pashto',
        'nativeName': 'پښتو',
        'rtl': true,
        'flag': '🇦🇫',
      },
      {
        'code': 'fa',
        'name': 'Persian',
        'nativeName': 'فارسی',
        'rtl': true,
        'flag': '🇮🇷',
      },
      {
        'code': 'pl',
        'name': 'Polish',
        'nativeName': 'Polski',
        'rtl': false,
        'flag': '🇵🇱',
      },
      {
        'code': 'pt-BR',
        'name': 'Portuguese (Brazil)',
        'nativeName': 'Português (Brasil)',
        'rtl': false,
        'flag': '🇧🇷',
      },
      {
        'code': 'pt-PT',
        'name': 'Portuguese (Portugal)',
        'nativeName': 'Português (Portugal)',
        'rtl': false,
        'flag': '🇵🇹',
      },
      {
        'code': 'pa',
        'name': 'Punjabi',
        'nativeName': 'ਪੰਜਾਬੀ',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'qu',
        'name': 'Quechua',
        'nativeName': 'Runa Simi',
        'rtl': false,
        'flag': '🇵🇪',
      },
      {
        'code': 'ro',
        'name': 'Romanian',
        'nativeName': 'Română',
        'rtl': false,
        'flag': '🇷🇴',
      },
      {
        'code': 'rm',
        'name': 'Romansh',
        'nativeName': 'Rumantsch',
        'rtl': false,
        'flag': '🇨🇭',
      },
      {
        'code': 'ru',
        'name': 'Russian',
        'nativeName': 'Русский',
        'rtl': false,
        'flag': '🇷🇺',
      },
      {
        'code': 'sa',
        'name': 'Sanskrit',
        'nativeName': 'संस्कृतम्',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'sr',
        'name': 'Serbian',
        'nativeName': 'Српски',
        'rtl': false,
        'flag': '🇷🇸',
      },
      {
        'code': 'sk',
        'name': 'Slovak',
        'nativeName': 'Slovenčina',
        'rtl': false,
        'flag': '🇸🇰',
      },
      {
        'code': 'sl',
        'name': 'Slovenian',
        'nativeName': 'Slovenščina',
        'rtl': false,
        'flag': '🇸🇮',
      },
      {
        'code': 'so',
        'name': 'Somali',
        'nativeName': 'Soomaali',
        'rtl': false,
        'flag': '🇸🇴',
      },
      {
        'code': 'es',
        'name': 'Spanish (Spain)',
        'nativeName': 'Español',
        'rtl': false,
        'flag': '🇪🇸',
      },
      {
        'code': 'es-CL',
        'name': 'Spanish (Chile)',
        'nativeName': 'Español (Chile)',
        'rtl': false,
        'flag': '🇨🇱',
      },
      {
        'code': 'es-CO',
        'name': 'Spanish (Colombia)',
        'nativeName': 'Español (Colombia)',
        'rtl': false,
        'flag': '🇨🇴',
      },
      {
        'code': 'es-MX',
        'name': 'Spanish (Mexico)',
        'nativeName': 'Español (México)',
        'rtl': false,
        'flag': '🇲🇽',
      },
      {
        'code': 'es-VE',
        'name': 'Spanish (Venezuela)',
        'nativeName': 'Español (Venezuela)',
        'rtl': false,
        'flag': '🇻🇪',
      },
      {
        'code': 'sw',
        'name': 'Swahili',
        'nativeName': 'Kiswahili',
        'rtl': false,
        'flag': '🇰🇪',
      },
      {
        'code': 'sv',
        'name': 'Swedish',
        'nativeName': 'Svenska',
        'rtl': false,
        'flag': '🇸🇪',
      },
      {
        'code': 'syc',
        'name': 'Syriac',
        'nativeName': 'ܣܘܪܝܝܐ',
        'rtl': true,
        'flag': '🇸🇾',
      },
      {
        'code': 'tg',
        'name': 'Tajik',
        'nativeName': 'Тоҷикӣ',
        'rtl': false,
        'flag': '🇹🇯',
      },
      {
        'code': 'ta',
        'name': 'Tamil',
        'nativeName': 'தமிழ்',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'tt',
        'name': 'Tatar',
        'nativeName': 'Татарча',
        'rtl': false,
        'flag': '🇷🇺',
      },
      {
        'code': 'te',
        'name': 'Telugu',
        'nativeName': 'తెలుగు',
        'rtl': false,
        'flag': '🇮🇳',
      },
      {
        'code': 'th',
        'name': 'Thai',
        'nativeName': 'ไทย',
        'rtl': false,
        'flag': '🇹🇭',
      },
      {
        'code': 'tr',
        'name': 'Turkish',
        'nativeName': 'Türkçe',
        'rtl': false,
        'flag': '🇹🇷',
      },
      {
        'code': 'uk',
        'name': 'Ukrainian',
        'nativeName': 'Українська',
        'rtl': false,
        'flag': '🇺🇦',
      },
      {
        'code': 'ur',
        'name': 'Urdu',
        'nativeName': 'اردو',
        'rtl': true,
        'flag': '🇵🇰',
      },
      {
        'code': 'uz',
        'name': 'Uzbek',
        'nativeName': 'Oʻzbekcha',
        'rtl': false,
        'flag': '🇺🇿',
      },
      {
        'code': 'vi',
        'name': 'Vietnamese',
        'nativeName': 'Tiếng Việt',
        'rtl': false,
        'flag': '🇻🇳',
      },
      {
        'code': 'cy',
        'name': 'Welsh',
        'nativeName': 'Cymraeg',
        'rtl': false,
        'flag': '🏴󠁧󠁢󠁷󠁬󠁳󠁿',
      },
      {
        'code': 'xh',
        'name': 'Xhosa',
        'nativeName': 'isiXhosa',
        'rtl': false,
        'flag': '🇿🇦',
      },
      {
        'code': 'yi',
        'name': 'Yiddish',
        'nativeName': 'ייִדיש',
        'rtl': true,
        'flag': '🇮🇱',
      },
      {
        'code': 'zu',
        'name': 'Zulu',
        'nativeName': 'isiZulu',
        'rtl': false,
        'flag': '🇿🇦',
      },
    ];
  }

  // Check if language is RTL
  bool isRTL(String languageCode) {
    final rtlLanguages = ['ar', 'he', 'fa', 'ur', 'ps', 'syc', 'yi'];
    return rtlLanguages.contains(languageCode);
  }

  // Get text direction for language
  TextDirection getTextDirection(String languageCode) {
    return isRTL(languageCode) ? TextDirection.rtl : TextDirection.ltr;
  }
}
