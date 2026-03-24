class NotificationCostOptimizerService {
  NotificationCostOptimizerService._();
  static final NotificationCostOptimizerService instance =
      NotificationCostOptimizerService._();

  static const int smsMaxChars = 160;
  static const int pushAckWaitHours = 24;
  static final RegExp _urlRegex = RegExp(r'https?:\/\/[^\s]+', caseSensitive: false);
  static const Set<String> _smsAllowedUseCases = {
    'otp',
    'otp_fallback',
    'critical_security',
    'admin_message',
    'time_sensitive_admin',
  };

  bool isSmsAllowedUseCase(String? useCase) {
    return _smsAllowedUseCases.contains((useCase ?? '').trim().toLowerCase());
  }

  String _compactUrlsForSms(String input) {
    return input.replaceAllMapped(_urlRegex, (match) {
      final raw = match.group(0) ?? '';
      final parsed = Uri.tryParse(raw);
      if (parsed == null || parsed.host.isEmpty) {
        return raw.replaceFirst(RegExp(r'^https?:\/\/', caseSensitive: false), '');
      }
      final path = parsed.path == '/' ? '' : parsed.path;
      return '${parsed.host}$path';
    });
  }

  String optimizeSmsMessage(String input) {
    final compactInput = _compactUrlsForSms(input);
    final compact = compactInput.replaceAll(RegExp(r'\s+'), ' ').trim();
    final gsm7 = compact.replaceAll(RegExp(r'[^\x0A\x0D\x20-\x7E]'), '');
    if (gsm7.length <= smsMaxChars) return gsm7;
    return '${gsm7.substring(0, smsMaxChars - 1)}…';
  }

  List<Map<String, dynamic>> buildChannelPlan({
    required String severity,
    String? useCase,
    required bool hasPushToken,
    required bool hasWhatsApp,
    required bool hasPhone,
  }) {
    final s = severity.toLowerCase();
    final urgent = s == 'critical' || s == 'high';
    final smsAllowed = isSmsAllowedUseCase(useCase);
    final plan = <Map<String, dynamic>>[];

    if (hasPushToken) {
      plan.add({'channel': 'push', 'immediate': true});
    }

    if (urgent) {
      if (hasWhatsApp) plan.add({'channel': 'whatsapp', 'immediate': true});
      if (hasPhone && smsAllowed) {
        plan.add({'channel': 'sms', 'immediate': true});
      }
      return plan;
    }

    plan.add({'channel': 'email', 'immediate': true});
    if (hasWhatsApp) {
      plan.add({
        'channel': 'whatsapp',
        'immediate': false,
        'waitHours': pushAckWaitHours,
        'requiresUnackedPush': true,
      });
    }
    if (hasPhone && smsAllowed) {
      plan.add({
        'channel': 'sms',
        'immediate': false,
        'waitHours': pushAckWaitHours,
        'requiresUnackedPush': true,
      });
    }
    return plan;
  }
}
