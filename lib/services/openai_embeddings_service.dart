import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

/// Embeddings Service
/// Gemini-first semantic embeddings with OpenAI fallback.
///
/// Web has already moved embeddings behind an AI proxy that uses Gemini by
/// default; this mobile service mirrors that intent:
/// - If GEMINI_API_KEY is configured, use Gemini text-embedding endpoint.
/// - Otherwise, fall back to OpenAI text-embedding-3-small.
class OpenAIEmbeddingsService {
  static OpenAIEmbeddingsService? _instance;
  static OpenAIEmbeddingsService get instance =>
      _instance ??= OpenAIEmbeddingsService._();
  OpenAIEmbeddingsService._();

  final Dio _dio = Dio();
  final SupabaseClient _supabase = Supabase.instance.client;

  // Gemini config (primary)
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  // Using text-embedding-004 style endpoint; adjust if you adopt a newer model.
  static const String _geminiEmbeddingsEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent';

  // OpenAI config (fallback)
  static const String _openAIApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _openAIEmbeddingsEndpoint =
      'https://api.openai.com/v1/embeddings';
  static const String _openAIEmbeddingModel = 'text-embedding-3-small';
  static const int _embeddingDimensions = 1536;

  /// Generate embeddings for content (Gemini first, OpenAI fallback).
  Future<List<double>?> generateEmbedding(String text) async {
    // Prefer Gemini embeddings when configured.
    if (_geminiApiKey.isNotEmpty) {
      final geminiResult = await _generateGeminiEmbedding(text);
      if (geminiResult != null) {
        return geminiResult;
      }
    }

    // Fallback to OpenAI if Gemini is not configured or fails.
    return _generateOpenAIEmbedding(text);
  }

  Future<List<double>?> _generateGeminiEmbedding(String text) async {
    try {
      if (_geminiApiKey.isEmpty) {
        debugPrint('GEMINI_API_KEY not configured for embeddings');
        return null;
      }

      final response = await _dio.post(
        '$_geminiEmbeddingsEndpoint?key=$_geminiApiKey',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': 'text-embedding-004',
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      );

      if (response.statusCode == 200) {
        // Gemini embedding response: { embeddings: [ { values: [...] } ] }
        final embeddings = response.data['embeddings'] as List<dynamic>?;
        if (embeddings == null || embeddings.isEmpty) {
          return null;
        }
        final values =
            List<double>.from(embeddings.first['values'] as List<dynamic>);
        return values;
      }

      debugPrint(
          'Gemini embeddings HTTP error: ${response.statusCode} ${response.statusMessage}');
      return null;
    } catch (e) {
      debugPrint('Gemini generate embedding error: $e');
      return null;
    }
  }

  Future<List<double>?> _generateOpenAIEmbedding(String text) async {
    try {
      if (_openAIApiKey.isEmpty) {
        debugPrint('OPENAI_API_KEY not configured for embeddings');
        return null;
      }

      final response = await _dio.post(
        _openAIEmbeddingsEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_openAIApiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _openAIEmbeddingModel,
          'input': text,
          'dimensions': _embeddingDimensions,
        },
      );

      if (response.statusCode == 200) {
        final embedding = List<double>.from(
          response.data['data'][0]['embedding'],
        );
        return embedding;
      }

      debugPrint(
          'OpenAI embeddings HTTP error: ${response.statusCode} ${response.statusMessage}');
      return null;
    } catch (e) {
      debugPrint('OpenAI generate embedding error: $e');
      return null;
    }
  }

  /// Store content embedding in Supabase
  Future<void> storeContentEmbedding({
    required String contentId,
    required String contentType,
    required String textContent,
  }) async {
    try {
      final embedding = await generateEmbedding(textContent);
      if (embedding == null) return;

      await _supabase.from('content_embeddings').upsert({
        'content_id': contentId,
        'content_type': contentType,
        'embedding_vector': embedding,
        'text_content': textContent,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Store content embedding error: $e');
    }
  }

  /// Calculate semantic similarity between two embeddings (cosine similarity)
  double calculateSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 0.0;

    double dotProduct = 0.0;
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      magnitude1 += embedding1[i] * embedding1[i];
      magnitude2 += embedding2[i] * embedding2[i];
    }

    magnitude1 = sqrt(magnitude1);
    magnitude2 = sqrt(magnitude2);

    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;

    return dotProduct / (magnitude1 * magnitude2);
  }

  /// Get similar content based on embeddings
  Future<List<Map<String, dynamic>>> getSimilarContent({
    required String contentId,
    required String contentType,
    int limit = 10,
  }) async {
    try {
      final targetEmbedding = await _supabase
          .from('content_embeddings')
          .select('embedding_vector')
          .eq('content_id', contentId)
          .eq('content_type', contentType)
          .maybeSingle();

      if (targetEmbedding == null) return [];

      final targetVector = List<double>.from(
        targetEmbedding['embedding_vector'],
      );

      final allEmbeddings = await _supabase
          .from('content_embeddings')
          .select()
          .neq('content_id', contentId);

      final similarities = <Map<String, dynamic>>[];

      for (final item in allEmbeddings) {
        final embedding = List<double>.from(item['embedding_vector']);
        final similarity = calculateSimilarity(targetVector, embedding);

        similarities.add({...item, 'similarity_score': similarity});
      }

      similarities.sort(
        (a, b) => b['similarity_score'].compareTo(a['similarity_score']),
      );

      return similarities.take(limit).toList();
    } catch (e) {
      debugPrint('Get similar content error: $e');
      return [];
    }
  }

  /// Batch generate embeddings for multiple content items
  Future<void> batchGenerateEmbeddings(
    List<Map<String, dynamic>> contentItems,
  ) async {
    try {
      for (final item in contentItems) {
        await storeContentEmbedding(
          contentId: item['content_id'],
          contentType: item['content_type'],
          textContent: item['text_content'],
        );

        // Rate limiting: 3000 requests per minute for text-embedding-3-small
        await Future.delayed(const Duration(milliseconds: 20));
      }
    } catch (e) {
      debugPrint('Batch generate embeddings error: $e');
    }
  }
}
