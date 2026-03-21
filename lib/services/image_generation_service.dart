import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';

/// Cross-platform image generation parity:
/// - Primary: OpenAI DALL-E (`dall-e-3`)
/// - Fallback: Supabase Edge `gemini-image-generation`
class ImageGenerationService {
  ImageGenerationService._();
  static final ImageGenerationService instance = ImageGenerationService._();

  static const String _defaultProvider = 'OPEN_AI';
  static const String _defaultModel = 'dall-e-3';
  static const String _openAiApiUrl = 'https://api.openai.com/v1/images/generations';
  static const String _openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');

  final _supabase = SupabaseService.instance.client;

  Future<Map<String, dynamic>> generateImage({
    required String prompt,
    String provider = _defaultProvider,
    String model = _defaultModel,
    Map<String, dynamic> options = const {},
  }) async {
    if (provider == 'OPEN_AI' && _openAiApiKey.isNotEmpty) {
      try {
        return await _generateWithOpenAI(prompt: prompt, model: model, options: options);
      } catch (e) {
        debugPrint('OpenAI image generation failed, falling back to Gemini: $e');
      }
    }

    return _generateWithGeminiFallback(prompt: prompt, options: options);
  }

  Future<Map<String, dynamic>> _generateWithOpenAI({
    required String prompt,
    required String model,
    required Map<String, dynamic> options,
  }) async {
    final dio = Dio(
      BaseOptions(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiApiKey',
        },
      ),
    );

    final response = await dio.post(
      _openAiApiUrl,
      data: {
        'model': model,
        'prompt': prompt,
        'size': options['size'] ?? '1024x1024',
        'quality': options['quality'] ?? 'standard',
        'n': 1,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return {
      'provider': 'OPEN_AI',
      'model': model,
      'data': data['data'],
      'created': data['created'],
    };
  }

  Future<Map<String, dynamic>> _generateWithGeminiFallback({
    required String prompt,
    required Map<String, dynamic> options,
  }) async {
    final response = await _supabase.functions.invoke(
      'gemini-image-generation',
      body: {
        'prompt': prompt,
        ...options,
      },
    );

    if (response.status != 200) {
      throw Exception('Gemini fallback failed: ${response.status}');
    }

    return {
      'provider': 'GEMINI',
      'model': 'imagen-3.0-generate-002',
      'data': response.data,
    };
  }
}
