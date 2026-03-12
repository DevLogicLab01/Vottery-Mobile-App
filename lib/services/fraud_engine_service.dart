import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import './supabase_service.dart';
import './auth_service.dart';
import './claude_service.dart';

class FraudEngineService {
  static FraudEngineService? _instance;
  static FraudEngineService get instance =>
      _instance ??= FraudEngineService._();

  FraudEngineService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  ClaudeService get _claude => ClaudeService.instance;

  /// Analyze user behavior for fraud with Claude
  Future<Map<String, dynamic>> analyzeBehaviorForFraud({
    required String userId,
    required Map<String, dynamic> behaviorData,
  }) async {
    try {
      final prompt =
          '''
Analyze this user behavior for fraud indicators. User ID: $userId.

Activity summary:
- Votes last hour: ${behaviorData['votes_last_hour'] ?? 0}
- Unique elections: ${behaviorData['unique_elections'] ?? 0}
- Vote velocity: ${behaviorData['vote_velocity'] ?? 0} votes/min
- Device changes: ${behaviorData['device_changes'] ?? 0}
- Location changes: ${behaviorData['location_changes'] ?? 0}
- Session patterns: ${behaviorData['session_patterns'] ?? {}}
- Account age: ${behaviorData['account_age_days'] ?? 0} days
- Earnings: \$${behaviorData['earnings'] ?? 0}
- Referrals: ${behaviorData['referrals'] ?? 0}

Detect:
1) Bot-like behavior
2) Vote manipulation
3) Multi-accounting
4) Coordinated attacks
5) Earnings fraud

For each detected pattern, provide:
- Fraud type
- Confidence (0-1)
- Evidence
- Risk level (minimal/low/medium/high/critical)

Return JSON format:
{
  "fraud_indicators": [
    {"type": "...", "confidence": 0.0, "evidence": "...", "risk_level": "..."}
  ],
  "overall_fraud_score": 0.0,
  "recommended_action": "flag|investigate|suspend|whitelist"
}
''';

      final claudeResponse = await _claude.callClaudeAPI(prompt);
      final analysis = _parseClaudeAnalysis(claudeResponse);

      // Log fraud detection event
      if (analysis['overall_fraud_score'] > 0.5) {
        await _logFraudEvent(userId: userId, analysis: analysis);
      }

      return analysis;
    } catch (e) {
      debugPrint('Analyze behavior for fraud error: $e');
      return _getDefaultAnalysis();
    }
  }

  /// Detect coordinated voting patterns
  Future<List<Map<String, dynamic>>> detectCoordinatedVoting({
    required String electionId,
  }) async {
    try {
      final response = await _client
          .from('votes')
          .select('user_id, voted_at, selected_option_id')
          .eq('election_id', electionId)
          .gte(
            'voted_at',
            DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
          )
          .order('voted_at', ascending: true);

      final votes = List<Map<String, dynamic>>.from(response);

      if (votes.length < 50) return [];

      // Analyze voting cluster
      final firstVote = DateTime.parse(votes.first['voted_at']);
      final lastVote = DateTime.parse(votes.last['voted_at']);
      final timespan = lastVote.difference(firstVote).inMinutes;

      if (timespan < 5) {
        // Potential coordinated attack
        final prompt =
            '''
Analyze this voting cluster for coordinated manipulation.

Election ID: $electionId
Voters: ${votes.length}
Timespan: $timespan minutes

Determine:
1) Is this coordinated manipulation? (Confidence 0-1)
2) Attack type (bot farm, click farm, organized group)
3) Recommended actions
4) Evidence summary

Return JSON:
{
  "coordination_detected": true/false,
  "confidence": 0.0,
  "attack_type": "...",
  "recommended_actions": ["..."],
  "evidence": "..."
}
''';

        final claudeResponse = await _claude.callClaudeAPI(prompt);
        final analysis = _parseCoordinationAnalysis(claudeResponse);

        if (analysis['coordination_detected'] == true) {
          return votes;
        }
      }

      return [];
    } catch (e) {
      debugPrint('Detect coordinated voting error: $e');
      return [];
    }
  }

  /// Suspend account with fraud reason
  Future<bool> suspendAccount({
    required String userId,
    required String reason,
    required String fraudEventId,
    int durationDays = 30,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final expiresAt = durationDays > 0
          ? DateTime.now().add(Duration(days: durationDays))
          : null;

      await _client.from('account_suspensions').insert({
        'user_id': userId,
        'suspension_reason': reason,
        'fraud_event_id': fraudEventId,
        'expires_at': expiresAt?.toIso8601String(),
        'status': durationDays > 0 ? 'active' : 'permanent',
        'suspended_by': _auth.currentUser!.id,
      });

      // Update user profile status
      await _client
          .from('user_profiles')
          .update({'account_status': 'suspended'})
          .eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('Suspend account error: $e');
      return false;
    }
  }

  /// Get fraud detection events
  Future<List<Map<String, dynamic>>> getFraudDetectionEvents({
    String? riskLevel,
    int limit = 50,
  }) async {
    try {
      PostgrestFilterBuilder query = _client
          .from('fraud_detection_events')
          .select('*, user_profiles(email, full_name)');

      if (riskLevel != null) {
        query = query.eq('risk_level', riskLevel);
      }

      final response = await query
          .order('detected_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get fraud detection events error: $e');
      return [];
    }
  }

  /// Get active suspensions
  Future<List<Map<String, dynamic>>> getActiveSuspensions() async {
    try {
      final response = await _client
          .from('account_suspensions')
          .select('*, user_profiles(email, full_name)')
          .eq('status', 'active')
          .order('suspended_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get active suspensions error: $e');
      return [];
    }
  }

  /// Get fraud appeals
  Future<List<Map<String, dynamic>>> getFraudAppeals({String? status}) async {
    try {
      PostgrestFilterBuilder query = _client
          .from('fraud_appeals')
          .select('*, account_suspensions(*), user_profiles(email, full_name)');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get fraud appeals error: $e');
      return [];
    }
  }

  /// Submit fraud appeal
  Future<bool> submitFraudAppeal({
    required String suspensionId,
    required String appealReason,
    List<String>? evidenceUrls,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('fraud_appeals').insert({
        'suspension_id': suspensionId,
        'appellant_user_id': _auth.currentUser!.id,
        'appeal_reason': appealReason,
        'evidence_urls': evidenceUrls ?? [],
        'status': 'pending',
      });

      // Update suspension status
      await _client
          .from('account_suspensions')
          .update({'status': 'appealed'})
          .eq('suspension_id', suspensionId);

      return true;
    } catch (e) {
      debugPrint('Submit fraud appeal error: $e');
      return false;
    }
  }

  /// Review fraud appeal (admin only)
  Future<bool> reviewFraudAppeal({
    required String appealId,
    required String decision,
    String? resolutionNotes,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('fraud_appeals')
          .update({
            'status': decision,
            'reviewed_by': _auth.currentUser!.id,
            'reviewed_at': DateTime.now().toIso8601String(),
            'resolution_notes': resolutionNotes,
          })
          .eq('appeal_id', appealId);

      // If approved, lift suspension
      if (decision == 'approved') {
        final appeal = await _client
            .from('fraud_appeals')
            .select('suspension_id')
            .eq('appeal_id', appealId)
            .single();

        await _client
            .from('account_suspensions')
            .update({
              'status': 'lifted',
              'lifted_at': DateTime.now().toIso8601String(),
              'lifted_by': _auth.currentUser!.id,
            })
            .eq('suspension_id', appeal['suspension_id']);

        // Update user profile
        final suspension = await _client
            .from('account_suspensions')
            .select('user_id')
            .eq('suspension_id', appeal['suspension_id'])
            .single();

        await _client
            .from('user_profiles')
            .update({'account_status': 'active'})
            .eq('id', suspension['user_id']);
      }

      return true;
    } catch (e) {
      debugPrint('Review fraud appeal error: $e');
      return false;
    }
  }

  Future<void> _logFraudEvent({
    required String userId,
    required Map<String, dynamic> analysis,
  }) async {
    try {
      final indicators = analysis['fraud_indicators'] as List? ?? [];
      final primaryIndicator = indicators.isNotEmpty ? indicators.first : {};

      await _client.from('fraud_detection_events').insert({
        'user_id': userId,
        'event_type': _mapFraudType(
          primaryIndicator['type'] ?? 'behavioral_anomaly',
        ),
        'fraud_score': analysis['overall_fraud_score'] ?? 0.0,
        'confidence': primaryIndicator['confidence'] ?? 0.0,
        'fraud_indicators': analysis,
        'risk_level': primaryIndicator['risk_level'] ?? 'low',
        'action_taken': analysis['recommended_action'] ?? 'flagged',
      });
    } catch (e) {
      debugPrint('Log fraud event error: $e');
    }
  }

  String _mapFraudType(String type) {
    final typeMap = {
      'bot': 'behavioral_anomaly',
      'manipulation': 'coordinated_voting',
      'multi_account': 'multi_accounting',
      'earnings': 'earnings_fraud',
    };

    for (var key in typeMap.keys) {
      if (type.toLowerCase().contains(key)) {
        return typeMap[key]!;
      }
    }

    return 'behavioral_anomaly';
  }

  Map<String, dynamic> _parseClaudeAnalysis(String response) {
    try {
      // Try to extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return Map<String, dynamic>.from(jsonDecode(jsonStr));
      }
    } catch (e) {
      debugPrint('Parse Claude analysis error: $e');
    }

    return _getDefaultAnalysis();
  }

  Map<String, dynamic> _parseCoordinationAnalysis(String response) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd);
        return Map<String, dynamic>.from(jsonDecode(jsonStr));
      }
    } catch (e) {
      debugPrint('Parse coordination analysis error: $e');
    }

    return {
      'coordination_detected': false,
      'confidence': 0.0,
      'attack_type': 'unknown',
      'recommended_actions': [],
      'evidence': '',
    };
  }

  Map<String, dynamic> _getDefaultAnalysis() {
    return {
      'fraud_indicators': [],
      'overall_fraud_score': 0.0,
      'recommended_action': 'whitelist',
    };
  }

  /// Get recent fraud alerts for dashboard display
  Future<List<Map<String, dynamic>>> getRecentFraudAlerts({
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from('fraud_alerts')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get recent fraud alerts error: $e');
      return [];
    }
  }

  /// Get automated responses triggered by fraud detection
  Future<List<Map<String, dynamic>>> getAutomatedResponses({
    int limit = 5,
  }) async {
    try {
      final response = await _client
          .from('automated_fraud_responses')
          .select()
          .order('triggered_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get automated responses error: $e');
      return [];
    }
  }
}
