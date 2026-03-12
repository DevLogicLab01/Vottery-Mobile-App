import 'ai_service_base.dart';

/// Calls the shared ai-proxy Supabase Edge with provider: gemini.
/// Use for SMS optimization and any chat flow that should match Web (Gemini).
class GeminiChatService {
  static GeminiChatService? _instance;
  static GeminiChatService get instance => _instance ??= GeminiChatService._();

  GeminiChatService._();

  /// Send messages to Gemini via ai-proxy. Returns assistant text.
  /// [messages] e.g. [{'role': 'user', 'content': '...'}] or [{'role': 'system', 'content': '...'}, {'role': 'user', 'content': '...'}]
  static Future<String> sendChat(
    List<Map<String, String>> messages, {
    int maxTokens = 1024,
    double temperature = 0.7,
  }) async {
    final response = await AIServiceBase.invokeAIFunction('ai-proxy', {
      'provider': 'gemini',
      'method': 'chat',
      'payload': {
        'messages': messages,
        'model': 'gemini-1.5-flash',
        'max_tokens': maxTokens,
        'temperature': temperature,
      },
    });

    // ai-proxy returns OpenAI-shaped: { choices: [ { message: { content } } ], usage }
    final choices = response['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return '';
    final first = choices.first as Map<String, dynamic>?;
    final message = first?['message'] as Map<String, dynamic>?;
    final text = message?['content'] as String?;
    return text?.trim() ?? '';
  }
}
