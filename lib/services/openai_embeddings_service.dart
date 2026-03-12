import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math'; // Add this import for sqrt function

/// OpenAI Embeddings Service
/// Generates 1536-dimensional semantic vectors for content using text-embedding-3-small model
class OpenAIEmbeddingsService {
  static OpenAIEmbeddingsService? _instance;
  static OpenAIEmbeddingsService get instance =>
      _instance ??= OpenAIEmbeddingsService._();
  OpenAIEmbeddingsService._();

  final Dio _dio = Dio();
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _embeddingsEndpoint =
      'https://api.openai.com/v1/embeddings';
  static const String _embeddingModel = 'text-embedding-3-small';
  static const int _embeddingDimensions = 1536;

  /// Generate embeddings for content
  Future<List<double>?> generateEmbedding(String text) async {
    try {
      if (_apiKey.isEmpty) {
        debugPrint('OpenAI API key not configured');
        return null;
      }

      final response = await _dio.post(
        _embeddingsEndpoint,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _embeddingModel,
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

      return null;
    } catch (e) {
      debugPrint('Generate embedding error: $e');
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
