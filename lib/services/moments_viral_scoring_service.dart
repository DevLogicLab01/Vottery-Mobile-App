import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'ai/ai_service_base.dart';
import 'auth_service.dart';

/// Claude viral potential for Moments — uses shared `ai-proxy` (Anthropic), same stack as Web.
class MomentsViralScoringService {
  MomentsViralScoringService._();

  static MomentsViralScoringService? _instance;
  static MomentsViralScoringService get instance =>
      _instance ??= MomentsViralScoringService._();

  static String _extractAssistantText(dynamic response) {
    try {
      final content = response is Map ? response['content'] : null;
      if (content is List && content.isNotEmpty) {
        final first = content.first;
        if (first is Map && first['text'] is String) {
          return first['text'] as String;
        }
      }
    } catch (_) {}
    return response?.toString() ?? '';
  }

  static Map<String, dynamic>? _parseJsonObject(String text) {
    if (text.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (match == null) return null;
    try {
      final decoded = jsonDecode(match.group(0)!);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  static double _num(dynamic v, [double d = 0]) {
    if (v is num) return v.toDouble();
    final n = double.tryParse(v?.toString() ?? '');
    return n ?? d;
  }

  static String _str(dynamic v, [String d = '']) {
    if (v == null) return d;
    return v.toString();
  }

  /// Returns sanitized viral payload or keys `error` / `auth_required`.
  Future<Map<String, dynamic>> analyzeMomentComposition({
    required int mediaCount,
    required int filterCount,
    required int textStickerCount,
    required int interactiveElementCount,
    String caption = '',
  }) async {
    if (!AuthService.instance.isAuthenticated) {
      return {
        'auth_required': true,
        'error': 'Sign in required for Claude viral scoring.',
      };
    }

    final prompt = '''
You are a viral content analyst for short-form social "Moments" (ephemeral stories).

Moment composition:
- Media count: $mediaCount
- Applied filters: $filterCount
- Text stickers / overlays: $textStickerCount
- Interactive elements (polls, questions, etc.): $interactiveElementCount
- Caption (may be empty): ${caption.isEmpty ? '(none)' : caption}

Return ONLY valid JSON (no markdown) with exactly these keys:
{
  "overallScore": number 0-100,
  "confidence": number 0-100,
  "engagementPrediction": {
    "views": string,
    "interactions": string,
    "shares": string,
    "completionRate": number 0-100
  },
  "audienceTargeting": {
    "accuracy": number 0-100,
    "primaryDemographic": string,
    "secondaryDemographic": string,
    "interests": string[]
  },
  "optimalTiming": {
    "bestDay": string,
    "bestTime": string,
    "timezone": string,
    "reasoning": string
  },
  "viralFactors": [ { "factor": string, "impact": number 0-100, "description": string } ],
  "improvementSuggestions": string[],
  "competitorAnalysis": {
    "averageScore": number,
    "yourAdvantage": number,
    "ranking": string
  }
}
''';

    try {
      final response = await AIServiceBase.invokeWithRetry('ai-proxy', {
        'provider': 'anthropic',
        'method': 'messages',
        'payload': {
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 2000,
          'temperature': 0.35,
        },
      });

      final rawText = _extractAssistantText(response);
      final parsed = _parseJsonObject(rawText);
      if (parsed == null) {
        return {'error': 'Unable to parse viral score response.'};
      }

      return _sanitize(parsed);
    } catch (e, st) {
      debugPrint('MomentsViralScoringService error: $e\n$st');
      return {'error': 'Unable to analyze viral potential right now.'};
    }
  }

  Map<String, dynamic> _sanitize(Map<String, dynamic> raw) {
    final ep = raw['engagementPrediction'];
    final at = raw['audienceTargeting'];
    final ot = raw['optimalTiming'];
    final ca = raw['competitorAnalysis'];

    Map<String, dynamic> epMap;
    if (ep is Map) {
      epMap = {
        'views': _str(ep['views'], '—'),
        'interactions': _str(ep['interactions'], '—'),
        'shares': _str(ep['shares'], '—'),
        'completionRate': _num(ep['completionRate']).clamp(0, 100),
      };
    } else {
      epMap = {
        'views': '—',
        'interactions': '—',
        'shares': '—',
        'completionRate': 0.0,
      };
    }

    Map<String, dynamic> atMap;
    if (at is Map) {
      final interests = at['interests'];
      atMap = {
        'accuracy': _num(at['accuracy']).clamp(0, 100),
        'primaryDemographic': _str(at['primaryDemographic'], '—'),
        'secondaryDemographic': _str(at['secondaryDemographic'], '—'),
        'interests': interests is List
            ? interests.map((e) => _str(e)).where((s) => s.isNotEmpty).toList()
            : <String>[],
      };
    } else {
      atMap = {
        'accuracy': 0.0,
        'primaryDemographic': '—',
        'secondaryDemographic': '—',
        'interests': <String>[],
      };
    }

    Map<String, dynamic> otMap;
    if (ot is Map) {
      otMap = {
        'bestDay': _str(ot['bestDay'], '—'),
        'bestTime': _str(ot['bestTime'], '—'),
        'timezone': _str(ot['timezone'], 'Local'),
        'reasoning': _str(ot['reasoning'], ''),
      };
    } else {
      otMap = {
        'bestDay': '—',
        'bestTime': '—',
        'timezone': 'Local',
        'reasoning': '',
      };
    }

    final factors = <Map<String, dynamic>>[];
    final vf = raw['viralFactors'];
    if (vf is List) {
      for (final item in vf) {
        if (item is! Map) continue;
        factors.add({
          'factor': _str(item['factor'], 'Factor'),
          'impact': _num(item['impact']).clamp(0, 100),
          'description': _str(item['description'], ''),
        });
      }
    }

    final suggestions = <String>[];
    final imp = raw['improvementSuggestions'];
    if (imp is List) {
      for (final s in imp) {
        final t = _str(s);
        if (t.isNotEmpty) suggestions.add(t);
      }
    }

    Map<String, dynamic> caMap;
    if (ca is Map) {
      caMap = {
        'averageScore': _num(ca['averageScore']),
        'yourAdvantage': _num(ca['yourAdvantage']),
        'ranking': _str(ca['ranking'], '—'),
      };
    } else {
      caMap = {
        'averageScore': 0.0,
        'yourAdvantage': 0.0,
        'ranking': '—',
      };
    }

    return {
      'overallScore': _num(raw['overallScore']).clamp(0, 100),
      'confidence': _num(raw['confidence']).clamp(0, 100),
      'engagementPrediction': epMap,
      'audienceTargeting': atMap,
      'optimalTiming': otMap,
      'viralFactors': factors,
      'improvementSuggestions': suggestions,
      'competitorAnalysis': caMap,
    };
  }
}
