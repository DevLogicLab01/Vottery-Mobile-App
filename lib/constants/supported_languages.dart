/// Single source of supported languages for Mobile; same list as Web (src/constants/supportedLanguages.js).
/// Use for i18n, voting UI, and gamification multi-language features.

class SupportedLanguage {
  const SupportedLanguage({required this.code, required this.name});
  final String code;
  final String name;
}

const List<SupportedLanguage> supportedLanguages = [
  SupportedLanguage(code: 'af', name: 'Afrikaans'),
  SupportedLanguage(code: 'sq', name: 'Albanian'),
  SupportedLanguage(code: 'am', name: 'Amharic'),
  SupportedLanguage(code: 'ar', name: 'Arabic'),
  SupportedLanguage(code: 'hy', name: 'Armenian'),
  SupportedLanguage(code: 'az', name: 'Azerbaijani'),
  SupportedLanguage(code: 'eu', name: 'Basque'),
  SupportedLanguage(code: 'be', name: 'Belarusian'),
  SupportedLanguage(code: 'bn', name: 'Bengali'),
  SupportedLanguage(code: 'bs', name: 'Bosnian'),
  SupportedLanguage(code: 'bg', name: 'Bulgarian'),
  SupportedLanguage(code: 'ca', name: 'Catalan'),
  SupportedLanguage(code: 'zh', name: 'Chinese (Simplified)'),
  SupportedLanguage(code: 'zh-TW', name: 'Chinese (Traditional)'),
  SupportedLanguage(code: 'hr', name: 'Croatian'),
  SupportedLanguage(code: 'cs', name: 'Czech'),
  SupportedLanguage(code: 'da', name: 'Danish'),
  SupportedLanguage(code: 'nl', name: 'Dutch'),
  SupportedLanguage(code: 'en', name: 'English'),
  SupportedLanguage(code: 'et', name: 'Estonian'),
  SupportedLanguage(code: 'fil', name: 'Filipino'),
  SupportedLanguage(code: 'fi', name: 'Finnish'),
  SupportedLanguage(code: 'fr', name: 'French'),
  SupportedLanguage(code: 'gl', name: 'Galician'),
  SupportedLanguage(code: 'ka', name: 'Georgian'),
  SupportedLanguage(code: 'de', name: 'German'),
  SupportedLanguage(code: 'el', name: 'Greek'),
  SupportedLanguage(code: 'gn', name: 'Guaraní'),
  SupportedLanguage(code: 'gu', name: 'Gujarati'),
  SupportedLanguage(code: 'he', name: 'Hebrew'),
  SupportedLanguage(code: 'hi', name: 'Hindi'),
  SupportedLanguage(code: 'hu', name: 'Hungarian'),
  SupportedLanguage(code: 'is', name: 'Icelandic'),
  SupportedLanguage(code: 'id', name: 'Indonesian'),
  SupportedLanguage(code: 'ga', name: 'Irish'),
  SupportedLanguage(code: 'it', name: 'Italian'),
  SupportedLanguage(code: 'ja', name: 'Japanese'),
  SupportedLanguage(code: 'kn', name: 'Kannada'),
  SupportedLanguage(code: 'kk', name: 'Kazakh'),
  SupportedLanguage(code: 'km', name: 'Khmer'),
  SupportedLanguage(code: 'ko', name: 'Korean'),
  SupportedLanguage(code: 'ky', name: 'Kyrgyz'),
  SupportedLanguage(code: 'lo', name: 'Lao'),
  SupportedLanguage(code: 'lv', name: 'Latvian'),
  SupportedLanguage(code: 'lt', name: 'Lithuanian'),
  SupportedLanguage(code: 'mk', name: 'Macedonian'),
  SupportedLanguage(code: 'ms', name: 'Malay'),
  SupportedLanguage(code: 'ml', name: 'Malayalam'),
  SupportedLanguage(code: 'mt', name: 'Maltese'),
  SupportedLanguage(code: 'mr', name: 'Marathi'),
  SupportedLanguage(code: 'mn', name: 'Mongolian'),
  SupportedLanguage(code: 'ne', name: 'Nepali'),
  SupportedLanguage(code: 'no', name: 'Norwegian'),
  SupportedLanguage(code: 'fa', name: 'Persian'),
  SupportedLanguage(code: 'pl', name: 'Polish'),
  SupportedLanguage(code: 'pt', name: 'Portuguese'),
  SupportedLanguage(code: 'pt-BR', name: 'Portuguese (Brazil)'),
  SupportedLanguage(code: 'pa', name: 'Punjabi'),
  SupportedLanguage(code: 'ro', name: 'Romanian'),
  SupportedLanguage(code: 'ru', name: 'Russian'),
  SupportedLanguage(code: 'sr', name: 'Serbian'),
  SupportedLanguage(code: 'si', name: 'Sinhala'),
  SupportedLanguage(code: 'sk', name: 'Slovak'),
  SupportedLanguage(code: 'sl', name: 'Slovenian'),
  SupportedLanguage(code: 'es', name: 'Spanish'),
  SupportedLanguage(code: 'sw', name: 'Swahili'),
  SupportedLanguage(code: 'sv', name: 'Swedish'),
  SupportedLanguage(code: 'tl', name: 'Tagalog'),
  SupportedLanguage(code: 'tg', name: 'Tajik'),
  SupportedLanguage(code: 'ta', name: 'Tamil'),
  SupportedLanguage(code: 'te', name: 'Telugu'),
  SupportedLanguage(code: 'th', name: 'Thai'),
  SupportedLanguage(code: 'tr', name: 'Turkish'),
  SupportedLanguage(code: 'uk', name: 'Ukrainian'),
  SupportedLanguage(code: 'ur', name: 'Urdu'),
  SupportedLanguage(code: 'uz', name: 'Uzbek'),
  SupportedLanguage(code: 'vi', name: 'Vietnamese'),
  SupportedLanguage(code: 'cy', name: 'Welsh'),
  SupportedLanguage(code: 'xh', name: 'Xhosa'),
  SupportedLanguage(code: 'zu', name: 'Zulu'),
];

SupportedLanguage? getLanguageByCode(String code) {
  try {
    return supportedLanguages.firstWhere((l) => l.code == code);
  } catch (_) {
    return null;
  }
}

List<String> getLanguageCodes() =>
    supportedLanguages.map((l) => l.code).toList();
