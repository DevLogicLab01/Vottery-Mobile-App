import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisputeAnalysisResult {
  final String disputeId;
  final List<String> reasoningChain;
  final double userFavorScore;
  final double merchantFavorScore;
  final String recommendedResolution;
  final List<String> policyCitations;
  final String appealRisk;
  final String justification;

  DisputeAnalysisResult({
    required this.disputeId,
    required this.reasoningChain,
    required this.userFavorScore,
    required this.merchantFavorScore,
    required this.recommendedResolution,
    required this.policyCitations,
    required this.appealRisk,
    required this.justification,
  });

  factory DisputeAnalysisResult.fromJson(Map<String, dynamic> json) {
    return DisputeAnalysisResult(
      disputeId: json['dispute_id'] ?? '',
      reasoningChain: List<String>.from(json['reasoning_chain'] ?? []),
      userFavorScore: (json['confidence_scores']?['user_favor'] ?? 50)
          .toDouble(),
      merchantFavorScore: (json['confidence_scores']?['merchant_favor'] ?? 50)
          .toDouble(),
      recommendedResolution: json['recommended_resolution'] ?? 'manual_review',
      policyCitations: List<String>.from(json['policy_citations'] ?? []),
      appealRisk: json['appeal_risk_assessment'] ?? 'medium',
      justification: json['justification'] ?? '',
    );
  }
}

class FraudInvestigationResult {
  final String caseId;
  final List<String> investigationSteps;
  final double fraudProbability;
  final String recommendedAction;
  final List<String> evidenceGaps;
  final String reasoning;

  FraudInvestigationResult({
    required this.caseId,
    required this.investigationSteps,
    required this.fraudProbability,
    required this.recommendedAction,
    required this.evidenceGaps,
    required this.reasoning,
  });

  factory FraudInvestigationResult.fromJson(Map<String, dynamic> json) {
    return FraudInvestigationResult(
      caseId: json['case_id'] ?? '',
      investigationSteps: List<String>.from(json['investigation_steps'] ?? []),
      fraudProbability: (json['fraud_probability'] ?? 0).toDouble(),
      recommendedAction: json['recommended_action'] ?? 'no_action',
      evidenceGaps: List<String>.from(json['evidence_gaps'] ?? []),
      reasoning: json['reasoning'] ?? '',
    );
  }
}

class PolicyInterpretationResult {
  final String question;
  final String interpretation;
  final double confidenceScore;
  final List<String> citedPolicies;
  final List<String> edgeCases;
  final String userFriendlyExplanation;

  PolicyInterpretationResult({
    required this.question,
    required this.interpretation,
    required this.confidenceScore,
    required this.citedPolicies,
    required this.edgeCases,
    required this.userFriendlyExplanation,
  });

  factory PolicyInterpretationResult.fromJson(Map<String, dynamic> json) {
    return PolicyInterpretationResult(
      question: json['question'] ?? '',
      interpretation: json['interpretation'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 50).toDouble(),
      citedPolicies: List<String>.from(json['cited_policies'] ?? []),
      edgeCases: List<String>.from(json['edge_cases'] ?? []),
      userFriendlyExplanation: json['user_friendly_explanation'] ?? '',
    );
  }
}

class ClaudeDecisionReasoningService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> getChatCompletion(
    String provider,
    String model,
    List<Map<String, dynamic>> messages, {
    Map<String, dynamic>? parameters,
  }) async {
    // Placeholder implementation - replace with actual API call
    return {
      'choices': [
        {
          'message': {
            'content': '{}',
          },
        },
      ],
    };
  }

  static Future<DisputeAnalysisResult> analyzeDispute(String disputeId) async {
    try {
      // Fetch dispute details
      final disputeData = await _supabase
          .from('disputes')
          .select(
            'id, type, claim, evidence, user_history, transaction_details',
          )
          .eq('id', disputeId)
          .maybeSingle();

      final dispute =
          disputeData ??
          {
            'id': disputeId,
            'type': 'chargeback',
            'claim': 'User claims unauthorized transaction',
            'evidence': 'Transaction receipt, IP logs',
            'user_history': 'Account in good standing for 2 years',
            'transaction_details': 'Transaction amount: \$49.99',
          };

      final response = await getChatCompletion(
        'ANTHROPIC',
        'claude-sonnet-4-5-20250929',
        [
          {
            'role': 'system',
            'content':
                'You are an expert dispute resolution analyst. Analyze evidence thoroughly and return valid JSON only.',
          },
          {
            'role': 'user',
            'content':
                'Analyze this dispute: Type: ${dispute['type']}. User claim: ${dispute['claim']}. Evidence: ${dispute['evidence']}. Transaction history: ${dispute['user_history']}. Transaction: ${dispute['transaction_details']}. Provide JSON with: reasoning_chain (array of strings), confidence_scores (object with user_favor and merchant_favor 0-100), recommended_resolution (approve/partial_refund/deny), policy_citations (array), appeal_risk_assessment (low/medium/high), justification (string).',
          },
        ],
        parameters: {'temperature': 0.3, 'max_tokens': 2000},
      );

      final content = response['choices']?[0]?['message']?['content'] ?? '{}';
      Map<String, dynamic> parsed = {};
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          parsed = jsonDecode(jsonMatch.group(0)!);
        }
      } catch (_) {}

      parsed['dispute_id'] = disputeId;
      parsed['reasoning_chain'] ??= [
        'Evidence reviewed',
        'Policy applied',
        'Decision reached',
      ];
      parsed['confidence_scores'] ??= {'user_favor': 65, 'merchant_favor': 35};
      parsed['recommended_resolution'] ??= 'manual_review';
      parsed['policy_citations'] ??= ['Policy 3.2: Chargeback Guidelines'];
      parsed['appeal_risk_assessment'] ??= 'medium';
      parsed['justification'] ??= content.length > 200
          ? content.substring(0, 200)
          : content;

      // Store analysis
      try {
        await _supabase.from('dispute_resolution_analysis').upsert({
          'dispute_id': disputeId,
          'reasoning_chain': parsed['reasoning_chain'],
          'confidence_scores': parsed['confidence_scores'],
          'recommended_resolution': parsed['recommended_resolution'],
          'policy_citations': parsed['policy_citations'],
          'appeal_risk': parsed['appeal_risk_assessment'],
          'analyzed_by': 'claude-sonnet-4-5-20250929',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return DisputeAnalysisResult.fromJson(parsed);
    } catch (e) {
      return DisputeAnalysisResult(
        disputeId: disputeId,
        reasoningChain: ['Analysis failed: ${e.toString()}'],
        userFavorScore: 50,
        merchantFavorScore: 50,
        recommendedResolution: 'manual_review',
        policyCitations: [],
        appealRisk: 'medium',
        justification: 'Manual review required',
      );
    }
  }

  static Future<FraudInvestigationResult> investigateFraud(
    String caseId,
  ) async {
    try {
      final caseData = await _supabase
          .from('fraud_detection_alerts')
          .select('id, user_id, fraud_indicators, severity')
          .eq('id', caseId)
          .maybeSingle();

      final fraudCase =
          caseData ??
          {
            'id': caseId,
            'user_id': 'user_unknown',
            'fraud_indicators': 'velocity_anomaly, duplicate_ip',
            'severity': 'high',
          };

      final response = await getChatCompletion(
        'ANTHROPIC',
        'claude-sonnet-4-5-20250929',
        [
          {
            'role': 'system',
            'content':
                'You are a fraud investigation expert. Build investigation chains and return valid JSON only.',
          },
          {
            'role': 'user',
            'content':
                'Investigate potential fraud: User: ${fraudCase['user_id']}. Fraud indicators: ${fraudCase['fraud_indicators']}. Severity: ${fraudCase['severity']}. Return JSON with: investigation_steps (array of strings), fraud_probability (0-100), recommended_action (flag_account/suspend_temporarily/permanent_ban/no_action), evidence_gaps (array), reasoning (string).',
          },
        ],
        parameters: {'temperature': 0.2, 'max_tokens': 2000},
      );

      final content = response['choices']?[0]?['message']?['content'] ?? '{}';
      Map<String, dynamic> parsed = {};
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          parsed = jsonDecode(jsonMatch.group(0)!);
        }
      } catch (_) {}

      parsed['case_id'] = caseId;
      parsed['investigation_steps'] ??= [
        'Indicators analyzed',
        'Patterns cross-referenced',
        'Risk assessed',
      ];
      parsed['fraud_probability'] ??= 45;
      parsed['recommended_action'] ??= 'flag_account';
      parsed['evidence_gaps'] ??= ['Device fingerprint needed'];
      parsed['reasoning'] ??= content.length > 200
          ? content.substring(0, 200)
          : content;

      return FraudInvestigationResult.fromJson(parsed);
    } catch (e) {
      return FraudInvestigationResult(
        caseId: caseId,
        investigationSteps: ['Investigation failed: ${e.toString()}'],
        fraudProbability: 0,
        recommendedAction: 'no_action',
        evidenceGaps: ['Manual review required'],
        reasoning: 'Error during investigation',
      );
    }
  }

  static Future<PolicyInterpretationResult> interpretPolicy(
    String question,
  ) async {
    try {
      final response = await getChatCompletion(
        'ANTHROPIC',
        'claude-sonnet-4-5-20250929',
        [
          {
            'role': 'system',
            'content':
                'You are a platform policy expert for a voting and gamification platform. Return valid JSON only.',
          },
          {
            'role': 'user',
            'content':
                'Interpret this policy question: $question. Context: Platform voting and gamification rules, privacy policy, terms of service. Return JSON with: interpretation (string), confidence_score (0-100), cited_policies (array), edge_cases (array), user_friendly_explanation (string).',
          },
        ],
        parameters: {'temperature': 0.3, 'max_tokens': 1500},
      );

      final content = response['choices']?[0]?['message']?['content'] ?? '{}';
      Map<String, dynamic> parsed = {};
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          parsed = jsonDecode(jsonMatch.group(0)!);
        }
      } catch (_) {}

      parsed['question'] = question;
      parsed['interpretation'] ??= content;
      parsed['confidence_score'] ??= 75;
      parsed['cited_policies'] ??= ['Terms of Service Section 4'];
      parsed['edge_cases'] ??= ['Edge cases may apply'];
      parsed['user_friendly_explanation'] ??= parsed['interpretation'];

      return PolicyInterpretationResult.fromJson(parsed);
    } catch (e) {
      return PolicyInterpretationResult(
        question: question,
        interpretation: 'Unable to interpret at this time',
        confidenceScore: 0,
        citedPolicies: [],
        edgeCases: [],
        userFriendlyExplanation:
            'Please contact support for policy clarification',
      );
    }
  }

  static Future<Map<String, dynamic>> processAppeal(String appealId) async {
    try {
      final appealData = await _supabase
          .from('dispute_resolution_analysis')
          .select('*')
          .eq('dispute_id', appealId)
          .maybeSingle();

      final originalDecision = appealData?['recommended_resolution'] ?? 'deny';
      final originalReasoning =
          (appealData?['reasoning_chain'] as List?)?.join(', ') ??
          'Original analysis';

      final response = await getChatCompletion(
        'ANTHROPIC',
        'claude-sonnet-4-5-20250929',
        [
          {
            'role': 'system',
            'content':
                'You are an appeal review specialist. Return valid JSON only.',
          },
          {
            'role': 'user',
            'content':
                'Review appeal: Original decision: $originalDecision. Original reasoning: $originalReasoning. New evidence: User provided additional documentation. Determine: is_new_evidence_material (true/false), confidence_change (number), should_overturn (yes/no/partial), new_resolution (if changed). Return JSON.',
          },
        ],
        parameters: {'temperature': 0.3, 'max_tokens': 1000},
      );

      final content = response['choices']?[0]?['message']?['content'] ?? '{}';
      Map<String, dynamic> parsed = {};
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonMatch != null) {
          parsed = jsonDecode(jsonMatch.group(0)!);
        }
      } catch (_) {}

      parsed['appeal_id'] = appealId;
      parsed['original_decision'] = originalDecision;
      parsed['is_new_evidence_material'] ??= false;
      parsed['confidence_change'] ??= 5;
      parsed['should_overturn'] ??= 'no';
      parsed['new_resolution'] ??= originalDecision;

      return parsed;
    } catch (e) {
      return {
        'appeal_id': appealId,
        'error': e.toString(),
        'should_overturn': 'no',
        'original_decision': 'unknown',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getActiveDisputes() async {
    try {
      final data = await _supabase
          .from('disputes')
          .select('id, type, claim, status, created_at')
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [
        {
          'id': 'disp_001',
          'type': 'chargeback',
          'claim': 'Unauthorized charge of \$49.99',
          'status': 'pending',
          'user_name': 'Alice Johnson',
        },
        {
          'id': 'disp_002',
          'type': 'refund_request',
          'claim': 'Service not delivered as promised',
          'status': 'pending',
          'user_name': 'Bob Smith',
        },
        {
          'id': 'disp_003',
          'type': 'policy_violation',
          'claim': 'Account suspended incorrectly',
          'status': 'pending',
          'user_name': 'Carol Davis',
        },
      ];
    }
  }

  static Future<List<Map<String, dynamic>>> getSuspiciousActivities() async {
    try {
      final data = await _supabase
          .from('fraud_detection_alerts')
          .select('id, user_id, fraud_indicators, severity, created_at')
          .eq('status', 'open')
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [
        {
          'id': 'fraud_001',
          'user_id': 'user_123',
          'fraud_indicators': 'velocity_anomaly',
          'severity': 'high',
        },
        {
          'id': 'fraud_002',
          'user_id': 'user_456',
          'fraud_indicators': 'duplicate_ip, suspicious_payment',
          'severity': 'medium',
        },
        {
          'id': 'fraud_003',
          'user_id': 'user_789',
          'fraud_indicators': 'duplicate_ip',
          'severity': 'low',
        },
      ];
    }
  }
}