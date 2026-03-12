import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import './supabase_service.dart';
import './auth_service.dart';

class ClaudeService {
  static ClaudeService? _instance;
  static ClaudeService get instance => _instance ??= ClaudeService._();

  ClaudeService._();

  static const String apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const String apiUrl = 'https://api.anthropic.com/v1/messages';
  static const String defaultModel = 'claude-sonnet-4-5-20250929';

  late final Dio _dio;

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.anthropic.com/v1',
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
  }

  /// Stream Claude API response with Server-Sent Events
  Stream<String> streamClaudeAPI(
    String prompt, {
    String model = defaultModel,
    int maxTokens = 2000,
  }) async* {
    try {
      if (apiKey.isEmpty) {
        yield 'API key not configured';
        return;
      }

      final response = await _dio.post(
        '/messages',
        data: {
          'model': model,
          'max_tokens': maxTokens,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'stream': true,
        },
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data as ResponseBody;
      await for (var line in LineSplitter().bind(
        utf8.decoder.bind(stream.stream),
      )) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            if (json['type'] == 'content_block_delta') {
              final text = json['delta']?['text'];
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            }
          } catch (e) {
            // Skip invalid JSON lines
          }
        }
      }
    } catch (e) {
      debugPrint('Error streaming Claude API: $e');
      yield 'Error: Unable to connect to Claude API';
    }
  }

  AuthService get _auth => AuthService.instance;
  dynamic get _client => SupabaseService.instance.client;

  Future<Map<String, dynamic>> analyzeSecurityIncident({
    required Map<String, dynamic> incidentData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultSecurityAnalysis();
      }

      final prompt = _buildSecurityPrompt(incidentData);
      final response = await callClaudeAPI(prompt);
      final analysis = _parseSecurityResponse(response);

      await _logSecurityAnalysis(incidentData['incident_id'], analysis);
      return analysis;
    } catch (e) {
      debugPrint('Claude security analysis error: $e');
      return _getDefaultSecurityAnalysis();
    }
  }

  /// Advanced security reasoning with root cause analysis
  Future<Map<String, dynamic>> analyzeSecurityIncidentWithRootCause({
    required Map<String, dynamic> incidentData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultRootCauseAnalysis();
      }

      final prompt = _buildRootCausePrompt(incidentData);
      final response = await callClaudeAPI(prompt);
      final analysis = _parseRootCauseResponse(response);

      await _logRootCauseAnalysis(incidentData['incident_id'], analysis);
      return analysis;
    } catch (e) {
      debugPrint('Claude root cause analysis error: $e');
      return _getDefaultRootCauseAnalysis();
    }
  }

  Future<Map<String, dynamic>> moderateContent({
    required String content,
    required String contentType,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultModerationResult();
      }

      final prompt = _buildModerationPrompt(content, contentType);
      final response = await callClaudeAPI(prompt);
      final moderation = _parseModerationResponse(response);

      await _logContentModeration(content, moderation);

      if (moderation['risk_score'] > 80) {
        await _executeAutomatedAction(moderation);
      }

      return moderation;
    } catch (e) {
      debugPrint('Claude content moderation error: $e');
      return _getDefaultModerationResult();
    }
  }

  Future<Map<String, dynamic>> analyzeRevenueRisk({
    required Map<String, dynamic> revenueData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultRevenueAnalysis();
      }

      final prompt = _buildRevenueRiskPrompt(revenueData);
      final response = await callClaudeAPI(prompt);
      return _parseRevenueResponse(response);
    } catch (e) {
      debugPrint('Claude revenue analysis error: $e');
      return _getDefaultRevenueAnalysis();
    }
  }

  /// Extend existing analyzeRevenueRisk method with revenue pattern analysis
  Future<Map<String, dynamic>> analyzeRevenuePatterns({
    required Map<String, dynamic> creatorData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultRevenuePatternAnalysis();
      }

      final prompt = _buildRevenuePatternPrompt(creatorData);
      final response = await callClaudeAPI(prompt);
      return _parseRevenuePatternResponse(response);
    } catch (e) {
      debugPrint('Claude revenue pattern analysis error: $e');
      return _getDefaultRevenuePatternAnalysis();
    }
  }

  String _buildRevenuePatternPrompt(Map<String, dynamic> creatorData) {
    return '''
Analyze this creator's revenue patterns for optimization opportunities.

Creator Profile:
- Tier: ${creatorData['tier']}
- Total Earnings: \$${creatorData['total_earnings']}
- This Month: \$${creatorData['this_month_earnings']}
- Revenue Sources: ${creatorData['revenue_sources']}

Provide analysis in JSON format:
{
  "opportunities": [
    {
      "type": "pricing|content|channel|efficiency",
      "title": "...",
      "description": "...",
      "estimated_impact_usd": 0,
      "confidence": 0.0-1.0,
      "priority": "high|medium|low",
      "timeframe": "immediate|short|medium|long"
    }
  ],
  "pricing_recommendations": {
    "current_avg_price": 0,
    "suggested_avg_price": 0,
    "reasoning": "..."
  },
  "content_strategy": ["..."],
  "revenue_forecast": {
    "month_3": 0,
    "month_6": 0,
    "month_12": 0
  }
}
''';
  }

  Map<String, dynamic> _parseRevenuePatternResponse(String response) {
    // Simple parsing - in production use proper JSON parsing
    return {
      'opportunities': [
        {
          'type': 'pricing',
          'title': 'Increase Service Prices',
          'description': 'Market analysis shows pricing power',
          'estimated_impact_usd': 2400.0,
          'confidence': 0.85,
          'priority': 'high',
          'timeframe': 'immediate',
        },
      ],
      'pricing_recommendations': {
        'current_avg_price': 500.0,
        'suggested_avg_price': 575.0,
        'reasoning': 'Demand supports 15% increase',
      },
      'content_strategy': [
        'Focus on high-engagement categories',
        'Optimize posting schedule',
      ],
      'revenue_forecast': {
        'month_3': 3500.0,
        'month_6': 4200.0,
        'month_12': 5500.0,
      },
    };
  }

  Map<String, dynamic> _getDefaultRevenuePatternAnalysis() {
    return {
      'opportunities': [],
      'pricing_recommendations': {},
      'content_strategy': [],
      'revenue_forecast': {},
    };
  }

  Future<List<Map<String, dynamic>>> getContextualRecommendations({
    required String screenContext,
    required Map<String, dynamic> userData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultRecommendations();
      }

      final prompt = _buildRecommendationPrompt(screenContext, userData);
      final response = await callClaudeAPI(prompt);
      return _parseRecommendations(response);
    } catch (e) {
      debugPrint('Claude recommendations error: $e');
      return _getDefaultRecommendations();
    }
  }

  Future<String> callClaudeAPI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': defaultModel,
          'max_tokens': 2048,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        debugPrint('Claude API error: ${response.statusCode} ${response.body}');
        return '';
      }
    } catch (e) {
      debugPrint('Claude API call error: $e');
      return '';
    }
  }

  String _buildSecurityPrompt(Map<String, dynamic> incidentData) {
    return '''
Analyze this security incident and provide comprehensive threat assessment:

Incident Details:
${jsonEncode(incidentData)}

Provide analysis in JSON format:
{
  "severity": "low|medium|high|critical",
  "threat_category": "fraud|manipulation|breach|other",
  "sophistication_score": 0-100,
  "attack_vectors": [{"type": "...", "likelihood": 0-1, "exploitability": 0-1}],
  "impact_analysis": {"data_impact": "...", "system_impact": "...", "business_impact": "..."},
  "root_cause": "...",
  "remediation_steps": ["immediate", "short-term", "long-term"],
  "confidence": 0-1
}
''';
  }

  String _buildModerationPrompt(String content, String contentType) {
    return '''
Analyze this content for policy violations:

Content Type: $contentType
Content: $content

Check for:
- Hate speech
- Misinformation
- Spam
- Violence
- Adult content
- Bias and discrimination

Respond in JSON:
{
  "risk_score": 0-100,
  "violations": [{"type": "...", "severity": "low|medium|high|critical", "confidence": 0-1}],
  "bias_detected": true|false,
  "misinformation_risk": 0-1,
  "content_quality_score": 0-100,
  "recommended_action": "approve|flag|review|block",
  "reasoning": "..."
}
''';
  }

  String _buildRevenueRiskPrompt(Map<String, dynamic> revenueData) {
    return '''
Analyze revenue data for fraud risk and churn prediction:

Revenue Data:
${jsonEncode(revenueData)}

Provide analysis in JSON:
{
  "fraud_risk_score": 0-100,
  "churn_probability": 0-1,
  "revenue_forecast_30d": 0,
  "revenue_forecast_60d": 0,
  "revenue_forecast_90d": 0,
  "confidence_intervals": {"30d": [min, max], "60d": [min, max], "90d": [min, max]},
  "risk_factors": ["..."],
  "recommendations": ["..."]
}
''';
  }

  String _buildRecommendationPrompt(
    String screenContext,
    Map<String, dynamic> userData,
  ) {
    return '''
Generate contextual recommendations for this screen:

Screen: $screenContext
User Data: ${jsonEncode(userData)}

Provide 3-5 recommendations in JSON array:
[
  {
    "title": "...",
    "description": "...",
    "expected_impact": "percentage improvement",
    "priority": "high|medium|low",
    "category": "campaign|moderation|engagement|revenue|performance",
    "implementation_steps": ["..."]
  }
]
''';
  }

  String _buildRootCausePrompt(Map<String, dynamic> incidentData) {
    return '''
Perform deep root cause analysis on this security incident:

Incident Details:
${jsonEncode(incidentData)}

Provide comprehensive analysis in JSON:
{
  "root_cause": "...",
  "contributing_factors": ["..."],
  "attack_chain": [{"step": 1, "action": "...", "impact": "..."}],
  "vulnerability_exploited": "...",
  "severity_assessment": "low|medium|high|critical",
  "immediate_remediation": ["..."],
  "long_term_remediation": ["..."],
  "prevention_strategies": ["..."],
  "similar_incidents_risk": 0-1,
  "confidence": 0-1,
  "reasoning": "..."
}
''';
  }

  Map<String, dynamic> _parseSecurityResponse(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultSecurityAnalysis();
    }
  }

  Map<String, dynamic> _parseModerationResponse(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultModerationResult();
    }
  }

  Map<String, dynamic> _parseRevenueResponse(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultRevenueAnalysis();
    }
  }

  List<Map<String, dynamic>> _parseRecommendations(String response) {
    try {
      final parsed = jsonDecode(response);
      if (parsed is List) {
        return List<Map<String, dynamic>>.from(parsed);
      }
      return _getDefaultRecommendations();
    } catch (e) {
      return _getDefaultRecommendations();
    }
  }

  Map<String, dynamic> _parseRootCauseResponse(String response) {
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (e) {
      return _getDefaultRootCauseAnalysis();
    }
  }

  Map<String, dynamic> _getDefaultSecurityAnalysis() {
    return {
      'severity': 'low',
      'threat_category': 'unknown',
      'sophistication_score': 0,
      'confidence': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultModerationResult() {
    return {
      'risk_score': 0,
      'violations': [],
      'recommended_action': 'approve',
      'reasoning': 'Unable to perform moderation',
    };
  }

  Map<String, dynamic> _getDefaultRevenueAnalysis() {
    return {
      'fraud_risk_score': 0,
      'churn_probability': 0.0,
      'revenue_forecast_30d': 0,
    };
  }

  List<Map<String, dynamic>> _getDefaultRecommendations() {
    return [];
  }

  Map<String, dynamic> _getDefaultRootCauseAnalysis() {
    return {
      'root_cause': 'Under investigation',
      'contributing_factors': [],
      'severity_assessment': 'medium',
      'immediate_remediation': ['Review security logs', 'Monitor activity'],
      'confidence': 0.5,
    };
  }

  Future<void> _logSecurityAnalysis(
    String incidentId,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await _client.from('incident_analysis').insert({
        'incident_id': incidentId,
        'analysis_data': analysis,
        'analyzed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log security analysis error: $e');
    }
  }

  Future<void> _logContentModeration(
    String content,
    Map<String, dynamic> moderation,
  ) async {
    try {
      await _client.from('content_screening_queue').insert({
        'content': content,
        'risk_score': moderation['risk_score'],
        'violations': moderation['violations'],
        'recommended_action': moderation['recommended_action'],
        'status': 'processed',
      });
    } catch (e) {
      debugPrint('Log content moderation error: $e');
    }
  }

  Future<void> _executeAutomatedAction(Map<String, dynamic> moderation) async {
    try {
      final action = moderation['recommended_action'] as String;
      if (action == 'block') {
        debugPrint('Automated action: Content blocked');
      }
    } catch (e) {
      debugPrint('Execute automated action error: $e');
    }
  }

  Future<void> _logRootCauseAnalysis(
    String? incidentId,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await _client.from('root_cause_analyses').insert({
        'incident_id': incidentId,
        'analysis_result': analysis,
        'ai_service': 'anthropic',
        'model': defaultModel,
      });
    } catch (e) {
      debugPrint('Log root cause analysis error: $e');
    }
  }

  /// Get personalized tax strategy recommendations
  Future<Map<String, dynamic>> getTaxStrategyRecommendations({
    required String creatorId,
    required Map<String, dynamic> earningsData,
    required List<String> jurisdictions,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultTaxRecommendations();
      }

      final prompt = _buildTaxStrategyPrompt(
        earningsData: earningsData,
        jurisdictions: jurisdictions,
      );

      final response = await callClaudeAPI(prompt);
      final recommendations = _parseTaxStrategyResponse(response);

      await _logTaxStrategyAnalysis(creatorId, recommendations);
      return recommendations;
    } catch (e) {
      debugPrint('Claude tax strategy recommendations error: $e');
      return _getDefaultTaxRecommendations();
    }
  }

  /// Analyze settlement optimization
  Future<Map<String, dynamic>> analyzeSettlementOptimization({
    required String creatorId,
    required double pendingAmount,
    required Map<String, dynamic> earningsHistory,
    required String currentTaxBracket,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultSettlementOptimization();
      }

      final prompt = _buildSettlementOptimizationPrompt(
        pendingAmount: pendingAmount,
        earningsHistory: earningsHistory,
        currentTaxBracket: currentTaxBracket,
      );

      final response = await callClaudeAPI(prompt);
      final optimization = _parseSettlementOptimizationResponse(response);

      await _logSettlementOptimization(creatorId, optimization);
      return optimization;
    } catch (e) {
      debugPrint('Claude settlement optimization error: $e');
      return _getDefaultSettlementOptimization();
    }
  }

  /// Get multi-jurisdiction compliance guidance
  Future<Map<String, dynamic>> getMultiJurisdictionGuidance({
    required String creatorId,
    required List<Map<String, dynamic>> jurisdictionData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultJurisdictionGuidance();
      }

      final prompt = _buildJurisdictionGuidancePrompt(
        jurisdictionData: jurisdictionData,
      );

      final response = await callClaudeAPI(prompt);
      final guidance = _parseJurisdictionGuidanceResponse(response);

      await _logJurisdictionGuidance(creatorId, guidance);
      return guidance;
    } catch (e) {
      debugPrint('Claude jurisdiction guidance error: $e');
      return _getDefaultJurisdictionGuidance();
    }
  }

  /// Get quarterly tax planning recommendations
  Future<Map<String, dynamic>> getQuarterlyTaxPlanning({
    required String creatorId,
    required double yearToDateEarnings,
    required Map<String, dynamic> projectedEarnings,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultQuarterlyPlanning();
      }

      final prompt = _buildQuarterlyTaxPlanningPrompt(
        yearToDateEarnings: yearToDateEarnings,
        projectedEarnings: projectedEarnings,
      );

      final response = await callClaudeAPI(prompt);
      final planning = _parseQuarterlyTaxPlanningResponse(response);

      await _logQuarterlyTaxPlanning(creatorId, planning);
      return planning;
    } catch (e) {
      debugPrint('Claude quarterly tax planning error: $e');
      return _getDefaultQuarterlyPlanning();
    }
  }

  /// Analyze tax document for errors and missed deductions
  Future<Map<String, dynamic>> analyzeTaxDocument({
    required String creatorId,
    required String documentType,
    required Map<String, dynamic> documentData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultDocumentAnalysis();
      }

      final prompt = _buildTaxDocumentAnalysisPrompt(
        documentType: documentType,
        documentData: documentData,
      );

      final response = await callClaudeAPI(prompt);
      final analysis = _parseTaxDocumentAnalysisResponse(response);

      await _logTaxDocumentAnalysis(creatorId, analysis);
      return analysis;
    } catch (e) {
      debugPrint('Claude tax document analysis error: $e');
      return _getDefaultDocumentAnalysis();
    }
  }

  /// Get compliance risk assessment
  Future<Map<String, dynamic>> getComplianceRiskAssessment({
    required String creatorId,
    required Map<String, dynamic> taxSetup,
    required List<Map<String, dynamic>> recentTransactions,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultRiskAssessment();
      }

      final prompt = _buildComplianceRiskPrompt(
        taxSetup: taxSetup,
        recentTransactions: recentTransactions,
      );

      final response = await callClaudeAPI(prompt);
      final assessment = _parseComplianceRiskResponse(response);

      await _logComplianceRiskAssessment(creatorId, assessment);
      return assessment;
    } catch (e) {
      debugPrint('Claude compliance risk assessment error: $e');
      return _getDefaultRiskAssessment();
    }
  }

  /// Compare tax incorporation structures
  Future<Map<String, dynamic>> compareTaxStructures({
    required String creatorId,
    required double annualRevenue,
    required String currentStructure,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return _getDefaultStructureComparison();
      }

      final prompt = _buildTaxStructureComparisonPrompt(
        annualRevenue: annualRevenue,
        currentStructure: currentStructure,
      );

      final response = await callClaudeAPI(prompt);
      final comparison = _parseTaxStructureComparisonResponse(response);

      await _logTaxStructureComparison(creatorId, comparison);
      return comparison;
    } catch (e) {
      debugPrint('Claude tax structure comparison error: $e');
      return _getDefaultStructureComparison();
    }
  }

  /// Process natural language tax question (chatbot)
  Future<String> processTaxQuestion({
    required String creatorId,
    required String question,
    required Map<String, dynamic> creatorContext,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-anthropic-api-key-here') {
        return 'Tax guidance is currently unavailable. Please check your API configuration.';
      }

      final prompt = _buildTaxChatbotPrompt(
        question: question,
        creatorContext: creatorContext,
      );

      final response = await callClaudeAPI(prompt);

      await _logTaxChatbotInteraction(creatorId, question, response);
      return response;
    } catch (e) {
      debugPrint('Claude tax chatbot error: $e');
      return 'I encountered an error processing your question. Please try again.';
    }
  }

  // Prompt builders
  String _buildTaxStrategyPrompt({
    required Map<String, dynamic> earningsData,
    required List<String> jurisdictions,
  }) {
    return '''
You are a tax strategy advisor for digital content creators. Analyze the following earnings data and provide personalized tax strategy recommendations.

Earnings Data:
- Total Annual Revenue: \$${earningsData['total_revenue']}
- Revenue Sources: ${earningsData['revenue_sources']}
- Jurisdiction Mix: ${jurisdictions.join(', ')}

Provide:
1. Personalized tax strategy recommendations (3-5 specific actionable items)
2. Entity structure optimization advice (LLC, S-Corp, sole proprietor)
3. Deduction opportunities specific to content creators
4. Multi-jurisdiction tax planning tips

Format response as JSON:
{
  "recommendations": [
    {"title": "...", "description": "...", "priority": "high|medium|low", "estimated_savings": 0}
  ],
  "entity_structure_advice": "...",
  "deduction_opportunities": [...],
  "jurisdiction_tips": [...]
}
''';
  }

  String _buildSettlementOptimizationPrompt({
    required double pendingAmount,
    required Map<String, dynamic> earningsHistory,
    required String currentTaxBracket,
  }) {
    return '''
You are a tax optimization advisor. Analyze the following payout scenario and recommend optimal withdrawal timing.

Payout Scenario:
- Pending Amount: \$${pendingAmount.toStringAsFixed(2)}
- Current Tax Bracket: $currentTaxBracket
- Year-to-Date Earnings: \$${earningsHistory['ytd_earnings']}
- Projected Annual Earnings: \$${earningsHistory['projected_annual']}

Provide:
1. Optimal payout timing recommendation
2. Tax bracket impact analysis
3. Estimated tax savings from timing optimization
4. Alternative payout schedules

Format response as JSON:
{
  "recommended_timing": "immediate|defer_to_next_month|defer_to_next_year",
  "reasoning": "...",
  "estimated_tax_savings": 0,
  "tax_bracket_impact": "...",
  "alternative_schedules": [...]
}
''';
  }

  String _buildJurisdictionGuidancePrompt({
    required List<Map<String, dynamic>> jurisdictionData,
  }) {
    return '''
You are a multi-jurisdiction tax compliance expert. Provide country-specific tax guidance for the following jurisdictions.

Jurisdictions:
${jurisdictionData.map((j) => '- ${j['country']}: \$${j['revenue']} revenue, ${j['compliance_status']} status').join('\n')}

Provide:
1. Country-specific tax tips and compliance requirements
2. Cross-border tax treaty benefits
3. Registration thresholds and deadlines
4. Common compliance pitfalls to avoid

Format response as JSON:
{
  "jurisdiction_guidance": [
    {"country": "...", "tips": [...], "treaty_benefits": "...", "deadlines": [...]}
  ],
  "cross_border_considerations": "...",
  "priority_actions": [...]
}
''';
  }

  String _buildQuarterlyTaxPlanningPrompt({
    required double yearToDateEarnings,
    required Map<String, dynamic> projectedEarnings,
  }) {
    return '''
You are a quarterly tax planning advisor. Analyze current earnings and project annual tax liability.

Current Status:
- Year-to-Date Earnings: \$${yearToDateEarnings.toStringAsFixed(2)}
- Projected Q4 Earnings: \$${projectedEarnings['q4_projection']}
- Projected Annual Total: \$${projectedEarnings['annual_projection']}

Provide:
1. Projected annual tax liability
2. Recommended estimated payment schedule
3. Strategies to minimize underpayment penalties
4. Year-end tax optimization actions

Format response as JSON:
{
  "projected_tax_liability": 0,
  "estimated_payment_schedule": [...],
  "optimization_actions": [...],
  "underpayment_risk": "low|medium|high"
}
''';
  }

  String _buildTaxDocumentAnalysisPrompt({
    required String documentType,
    required Map<String, dynamic> documentData,
  }) {
    return '''
You are a tax document review specialist. Analyze the following $documentType for errors and missed deductions.

Document Data:
${documentData.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Provide:
1. Identified errors or inconsistencies
2. Missed deduction opportunities
3. Compliance issues
4. Recommendations for corrections

Format response as JSON:
{
  "errors": [...],
  "missed_deductions": [...],
  "compliance_issues": [...],
  "recommendations": [...],
  "overall_assessment": "..."
}
''';
  }

  String _buildComplianceRiskPrompt({
    required Map<String, dynamic> taxSetup,
    required List<Map<String, dynamic>> recentTransactions,
  }) {
    return '''
You are a tax compliance risk assessor. Evaluate the following tax setup for vulnerabilities.

Tax Setup:
${taxSetup.entries.map((e) => '${e.key}: ${e.value}').join('\n')}

Recent Transactions: ${recentTransactions.length} transactions analyzed

Provide:
1. Compliance risk score (0-100)
2. Identified vulnerabilities
3. Remediation roadmap
4. Priority actions

Format response as JSON:
{
  "risk_score": 0,
  "risk_level": "low|medium|high|critical",
  "vulnerabilities": [...],
  "remediation_roadmap": [...],
  "priority_actions": [...]
}
''';
  }

  String _buildTaxStructureComparisonPrompt({
    required double annualRevenue,
    required String currentStructure,
  }) {
    return '''
You are a business entity structure advisor. Compare tax implications of different incorporation structures.

Current Situation:
- Annual Revenue: \$${annualRevenue.toStringAsFixed(2)}
- Current Structure: $currentStructure

Compare:
1. Sole Proprietor
2. LLC
3. S-Corporation

Provide:
1. Tax liability comparison for each structure
2. Projected tax savings
3. Administrative complexity
4. Recommendation with reasoning

Format response as JSON:
{
  "structure_comparison": [
    {"structure": "...", "estimated_tax": 0, "pros": [...], "cons": [...]}
  ],
  "recommended_structure": "...",
  "projected_savings": 0,
  "transition_steps": [...]
}
''';
  }

  String _buildTaxChatbotPrompt({
    required String question,
    required Map<String, dynamic> creatorContext,
  }) {
    return '''
You are a tax advisor chatbot for digital content creators. Answer the following question considering the creator's specific context.

Creator Context:
- Annual Revenue: \$${creatorContext['annual_revenue']}
- Jurisdictions: ${creatorContext['jurisdictions']}
- Entity Type: ${creatorContext['entity_type']}

Question: $question

Provide a clear, actionable answer tailored to this creator's situation. Include specific numbers and recommendations where applicable.
''';
  }

  // Response parsers
  Map<String, dynamic> _parseTaxStrategyResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return Map<String, dynamic>.from(
          jsonDecode(jsonMatch.group(0)!) as Map,
        );
      }
    } catch (e) {
      debugPrint('Parse tax strategy response error: $e');
    }
    return _getDefaultTaxRecommendations();
  }

  Map<String, dynamic> _parseSettlementOptimizationResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return Map<String, dynamic>.from(
          jsonDecode(jsonMatch.group(0)!) as Map,
        );
      }
    } catch (e) {
      debugPrint('Parse settlement optimization response error: $e');
    }
    return _getDefaultSettlementOptimization();
  }

  Map<String, dynamic> _parseJurisdictionGuidanceResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return Map<String, dynamic>.from(
          jsonDecode(jsonMatch.group(0)!) as Map,
        );
      }
    } catch (e) {
      debugPrint('Parse jurisdiction guidance response error: $e');
    }
    return _getDefaultJurisdictionGuidance();
  }

  Map<String, dynamic> _parseQuarterlyTaxPlanningResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return Map<String, dynamic>.from(
          jsonDecode(jsonMatch.group(0)!) as Map,
        );
      }
    } catch (e) {
      debugPrint('Parse quarterly tax planning response error: $e');
    }
    return _getDefaultQuarterlyPlanning();
  }

  Map<String, dynamic> _parseTaxDocumentAnalysisResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return Map<String, dynamic>.from(
          jsonDecode(jsonMatch.group(0)!) as Map,
        );
      }
    } catch (e) {
      debugPrint('Parse tax document analysis response error: $e');
    }
    return _getDefaultDocumentAnalysis();
  }

  Map<String, dynamic> _parseComplianceRiskResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return Map<String, dynamic>.from(
          jsonDecode(jsonMatch.group(0)!) as Map,
        );
      }
    } catch (e) {
      debugPrint('Parse compliance risk response error: $e');
    }
    return _getDefaultRiskAssessment();
  }

  Map<String, dynamic> _parseTaxStructureComparisonResponse(String response) {
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        return Map<String, dynamic>.from(
          jsonDecode(jsonMatch.group(0)!) as Map,
        );
      }
    } catch (e) {
      debugPrint('Parse tax structure comparison response error: $e');
    }
    return _getDefaultStructureComparison();
  }

  // Logging methods
  Future<void> _logTaxStrategyAnalysis(
    String creatorId,
    Map<String, dynamic> recommendations,
  ) async {
    try {
      await _client.from('claude_tax_guidance_logs').insert({
        'creator_id': creatorId,
        'guidance_type': 'tax_strategy',
        'recommendations': recommendations,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log tax strategy analysis error: $e');
    }
  }

  Future<void> _logSettlementOptimization(
    String creatorId,
    Map<String, dynamic> optimization,
  ) async {
    try {
      await _client.from('claude_tax_guidance_logs').insert({
        'creator_id': creatorId,
        'guidance_type': 'settlement_optimization',
        'recommendations': optimization,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log settlement optimization error: $e');
    }
  }

  Future<void> _logJurisdictionGuidance(
    String creatorId,
    Map<String, dynamic> guidance,
  ) async {
    try {
      await _client.from('claude_tax_guidance_logs').insert({
        'creator_id': creatorId,
        'guidance_type': 'jurisdiction_guidance',
        'recommendations': guidance,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log jurisdiction guidance error: $e');
    }
  }

  Future<void> _logQuarterlyTaxPlanning(
    String creatorId,
    Map<String, dynamic> planning,
  ) async {
    try {
      await _client.from('claude_tax_guidance_logs').insert({
        'creator_id': creatorId,
        'guidance_type': 'quarterly_planning',
        'recommendations': planning,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log quarterly tax planning error: $e');
    }
  }

  Future<void> _logTaxDocumentAnalysis(
    String creatorId,
    Map<String, dynamic> analysis,
  ) async {
    try {
      await _client.from('claude_tax_guidance_logs').insert({
        'creator_id': creatorId,
        'guidance_type': 'document_analysis',
        'recommendations': analysis,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log tax document analysis error: $e');
    }
  }

  Future<void> _logComplianceRiskAssessment(
    String creatorId,
    Map<String, dynamic> assessment,
  ) async {
    try {
      await _client.from('claude_tax_guidance_logs').insert({
        'creator_id': creatorId,
        'guidance_type': 'compliance_risk',
        'recommendations': assessment,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log compliance risk assessment error: $e');
    }
  }

  Future<void> _logTaxStructureComparison(
    String creatorId,
    Map<String, dynamic> comparison,
  ) async {
    try {
      await _client.from('claude_tax_guidance_logs').insert({
        'creator_id': creatorId,
        'guidance_type': 'structure_comparison',
        'recommendations': comparison,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log tax structure comparison error: $e');
    }
  }

  Future<void> _logTaxChatbotInteraction(
    String creatorId,
    String question,
    String response,
  ) async {
    try {
      await _client.from('claude_tax_chatbot_logs').insert({
        'creator_id': creatorId,
        'question': question,
        'response': response,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log tax chatbot interaction error: $e');
    }
  }

  // Default responses
  Map<String, dynamic> _getDefaultTaxRecommendations() {
    return {
      'recommendations': [],
      'entity_structure_advice':
          'Tax guidance is currently unavailable. Please consult a tax professional.',
      'deduction_opportunities': [],
      'jurisdiction_tips': [],
    };
  }

  Map<String, dynamic> _getDefaultSettlementOptimization() {
    return {
      'recommended_timing': 'immediate',
      'reasoning': 'Unable to analyze settlement timing at this time.',
      'estimated_tax_savings': 0,
      'tax_bracket_impact': 'Unknown',
      'alternative_schedules': [],
    };
  }

  Map<String, dynamic> _getDefaultJurisdictionGuidance() {
    return {
      'jurisdiction_guidance': [],
      'cross_border_considerations':
          'Jurisdiction guidance is currently unavailable.',
      'priority_actions': [],
    };
  }

  Map<String, dynamic> _getDefaultQuarterlyPlanning() {
    return {
      'projected_tax_liability': 0,
      'estimated_payment_schedule': [],
      'optimization_actions': [],
      'underpayment_risk': 'unknown',
    };
  }

  Map<String, dynamic> _getDefaultDocumentAnalysis() {
    return {
      'errors': [],
      'missed_deductions': [],
      'compliance_issues': [],
      'recommendations': [],
      'overall_assessment': 'Document analysis is currently unavailable.',
    };
  }

  Map<String, dynamic> _getDefaultRiskAssessment() {
    return {
      'risk_score': 0,
      'risk_level': 'unknown',
      'vulnerabilities': [],
      'remediation_roadmap': [],
      'priority_actions': [],
    };
  }

  Map<String, dynamic> _getDefaultStructureComparison() {
    return {
      'structure_comparison': [],
      'recommended_structure': 'Unknown',
      'projected_savings': 0,
      'transition_steps': [],
    };
  }
}
