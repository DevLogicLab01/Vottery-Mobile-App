import 'dart:async';
import 'package:flutter/foundation.dart';
import './supabase_service.dart';
import './claude_service.dart';

/// Extended Outage Handler Service
/// Manages Telnyx outages lasting >24 hours with AI-powered decisions
class ExtendedOutageHandlerService {
  static ExtendedOutageHandlerService? _instance;
  static ExtendedOutageHandlerService get instance =>
      _instance ??= ExtendedOutageHandlerService._();

  ExtendedOutageHandlerService._();

  final _supabase = SupabaseService.instance.client;
  final _claudeService = ClaudeService.instance;

  Timer? _outageCheckTimer;
  DateTime? _outageStartTime;
  bool _gamificationSmsEnabled = false;
  int _queuedCriticalMessages = 0;
  int _queuedGamificationMessages = 0;

  static const Duration _extendedOutageThreshold = Duration(hours: 24);
  static const Duration _escalationInterval = Duration(hours: 6);

  /// Start monitoring for extended outages
  void startMonitoring() {
    _outageCheckTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _checkExtendedOutage(),
    );
    debugPrint('✅ ExtendedOutageHandler monitoring started');
  }

  /// Record outage start
  void recordOutageStart() {
    _outageStartTime ??= DateTime.now();
    debugPrint('⚠️ Telnyx outage started at $_outageStartTime');
  }

  /// Record outage end (Telnyx restored)
  void recordOutageEnd() {
    _outageStartTime = null;
    _gamificationSmsEnabled = false;
    debugPrint('✅ Telnyx outage ended - gamification SMS re-blocked on Twilio');
  }

  /// Check if outage exceeds 24 hours
  Future<void> _checkExtendedOutage() async {
    if (_outageStartTime == null) return;

    final duration = DateTime.now().difference(_outageStartTime!);
    if (duration < _extendedOutageThreshold) return;

    debugPrint('🚨 Extended Telnyx outage: ${duration.inHours}h');

    // Load queued message counts
    await _loadQueuedMessageCounts();

    // AI analysis for gamification SMS decision
    if (!_gamificationSmsEnabled && _queuedGamificationMessages > 0) {
      await _analyzeGamificationSmsDecision(duration);
    }

    // Log the extended outage
    await _logExtendedOutage(duration);

    // Escalate every 6 hours
    if (duration.inMinutes % _escalationInterval.inMinutes < 30) {
      await _sendEscalationAlert(duration);
    }
  }

  Future<void> _loadQueuedMessageCounts() async {
    try {
      final critical = await _supabase
          .from('sms_queue')
          .select('id')
          .inFilter('message_type', ['security_alert', 'account_notification'])
          .eq('status', 'queued');

      final gamification = await _supabase
          .from('sms_queue')
          .select('id')
          .inFilter('message_type', [
            'lottery_winner',
            'prize_notification',
            'gamification',
          ])
          .eq('status', 'queued');

      _queuedCriticalMessages = (critical as List).length;
      _queuedGamificationMessages = (gamification as List).length;
    } catch (e) {
      debugPrint('Queue count error: $e');
    }
  }

  Future<void> _analyzeGamificationSmsDecision(Duration outageDuration) async {
    try {
      final analysis = await _claudeService.callClaudeAPI(
        'Telnyx SMS outage has lasted ${outageDuration.inHours} hours. '
        'We have $_queuedCriticalMessages critical messages and $_queuedGamificationMessages gamification SMS queued. '
        'Should we enable Twilio delivery for gamification SMS? '
        'Consider: user impact, business risk, compliance. '
        'Respond with: APPROVE or DENY and brief reason.',
      );

      final shouldApprove = analysis.toUpperCase().contains('APPROVE');
      debugPrint(
        'AI gamification SMS decision: ${shouldApprove ? "APPROVE" : "DENY"}',
      );

      // Store decision for admin review
      await _supabase.from('extended_outage_log').insert({
        'provider': 'telnyx',
        'outage_start': _outageStartTime!.toIso8601String(),
        'outage_duration_hours': outageDuration.inHours,
        'decision': shouldApprove
            ? 'ai_recommend_approve'
            : 'ai_recommend_deny',
        'notes': analysis,
      });
    } catch (e) {
      debugPrint('AI analysis error: $e');
    }
  }

  Future<void> _logExtendedOutage(Duration duration) async {
    try {
      await _supabase.from('extended_outage_log').upsert({
        'provider': 'telnyx',
        'outage_start': _outageStartTime!.toIso8601String(),
        'outage_duration_hours': duration.inHours,
        'decision': _gamificationSmsEnabled
            ? 'gamification_enabled'
            : 'gamification_blocked',
      });
    } catch (e) {
      debugPrint('Outage log error: $e');
    }
  }

  Future<void> _sendEscalationAlert(Duration duration) async {
    debugPrint(
      '📧 Escalation: Telnyx still down after ${duration.inHours}h. '
      'Critical: $_queuedCriticalMessages, Gamification: $_queuedGamificationMessages',
    );
    // In production: send Slack webhook + Resend email
  }

  /// Admin approval to enable gamification SMS on Twilio
  Future<void> approveGamificationSms(String adminId) async {
    _gamificationSmsEnabled = true;
    try {
      await _supabase.from('extended_outage_log').insert({
        'provider': 'telnyx',
        'outage_start':
            _outageStartTime?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'outage_duration_hours': _outageStartTime != null
            ? DateTime.now().difference(_outageStartTime!).inHours
            : 0,
        'decision': 'admin_approved_gamification',
        'admin_approval_id': adminId,
        'approval_timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Approval log error: $e');
    }
    debugPrint('✅ Admin approved gamification SMS on Twilio');
  }

  bool get isGamificationSmsEnabled => _gamificationSmsEnabled;
  int get queuedCriticalMessages => _queuedCriticalMessages;
  int get queuedGamificationMessages => _queuedGamificationMessages;
  Duration get outageDuration => _outageStartTime != null
      ? DateTime.now().difference(_outageStartTime!)
      : Duration.zero;

  void dispose() {
    _outageCheckTimer?.cancel();
  }
}
