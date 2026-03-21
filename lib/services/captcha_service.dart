import 'package:flutter/foundation.dart';

import './supabase_service.dart';

class CaptchaService {
  static CaptchaService? _instance;
  static CaptchaService get instance => _instance ??= CaptchaService._();

  CaptchaService._();

  /// Verifies hCaptcha token using Supabase Edge Function `validate-captcha`.
  Future<bool> validateToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return false;

    try {
      final response = await SupabaseService.instance.client.functions.invoke(
        'validate-captcha',
        body: {'token': normalized},
      );

      if (response.status != 200 || response.data == null) return false;
      final payload = Map<String, dynamic>.from(response.data as Map);
      return payload['success'] == true;
    } catch (e) {
      debugPrint('Captcha validation failed: $e');
      return false;
    }
  }
}
