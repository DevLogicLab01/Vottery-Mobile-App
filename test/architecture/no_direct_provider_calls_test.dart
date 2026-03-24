import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no direct privileged provider calls from mobile client services', () async {
    final libDir = Directory('lib/services');
    expect(await libDir.exists(), isTrue);

    final disallowed = <RegExp>[
      RegExp(r'https:\/\/api\.openai\.com\/v1'),
      RegExp(r'https:\/\/api\.anthropic\.com\/v1'),
      RegExp(r'https:\/\/api\.perplexity\.ai\/'),
      RegExp(r"String\.fromEnvironment\('OPENAI_API_KEY'"),
      RegExp(r"String\.fromEnvironment\('ANTHROPIC_API_KEY'"),
      RegExp(r"String\.fromEnvironment\('PERPLEXITY_API_KEY'"),
    ];

    final allowedFiles = <String>{
      // Transitional compatibility: these will be migrated to ai-proxy in follow-up slices.
      'lib/services/claude_service.dart',
      'lib/services/perplexity_service.dart',
      'lib/services/claude_faq_service.dart',
      'lib/services/enhanced_analytics_cdn_service.dart',
      'lib/services/image_generation_service.dart',
      'lib/services/openai_carousel_ranking_service.dart',
      'lib/services/openai_embeddings_service.dart',
      'lib/services/openai_fraud_detection_service.dart',
      'lib/services/openai_fraud_service.dart',
      'lib/services/voter_sentiment_service.dart',
    };

    final violations = <String>[];

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalizedPath = entity.path.replaceAll('\\', '/');
      if (allowedFiles.contains(normalizedPath)) continue;

      final content = await entity.readAsString();
      for (final pattern in disallowed) {
        if (pattern.hasMatch(content)) {
          violations.add('$normalizedPath matched ${pattern.pattern}');
        }
      }
    }

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
