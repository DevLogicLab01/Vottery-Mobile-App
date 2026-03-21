import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './claude_service.dart';

class ClaudeRevenueOptimizationService {
  static ClaudeRevenueOptimizationService? _instance;
  static ClaudeRevenueOptimizationService get instance =>
      _instance ??= ClaudeRevenueOptimizationService._();

  ClaudeRevenueOptimizationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  ClaudeService get _claude => ClaudeService.instance;

  /// Analyze earning patterns with Claude
  Future<Map<String, dynamic>> analyzeEarningPatterns() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final userId = _auth.currentUser!.id;

      // Collect creator data
      final creatorData = await _collectCreatorData(userId);

      // Build Claude prompt
      final prompt = _buildEarningAnalysisPrompt(creatorData);

      // Call Claude API
      final response = await _claude.callClaudeAPI(prompt);

      // Parse response
      final analysis = _parseEarningAnalysis(response);

      // Store coaching session
      await _storeCoachingSession(
        userId: userId,
        sessionType: 'weekly_checkin',
        analysisData: creatorData,
        recommendations: analysis['recommendations'] ?? [],
      );

      return analysis;
    } catch (e) {
      debugPrint('Analyze earning patterns error: $e');
      return _getDefaultAnalysis();
    }
  }

  /// Get optimization recommendations
  Future<List<Map<String, dynamic>>> getOptimizationRecommendations() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('claude_optimization_recommendations')
          .select()
          .eq('creator_user_id', userId)
          .inFilter('status', ['pending', 'accepted'])
          .order('priority', ascending: true)
          .order('recommended_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get optimization recommendations error: $e');
      return [];
    }
  }

  /// Generate pricing recommendations
  Future<Map<String, dynamic>> generatePricingRecommendations() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final userId = _auth.currentUser!.id;

      // Get marketplace services
      final services = await _client
          .from('marketplace_services')
          .select()
          .eq('creator_user_id', userId)
          .eq('is_active', true);

      if ((services as List).isEmpty) {
        return {'has_services': false, 'recommendations': []};
      }

      final prompt =
          '''
Analyze these marketplace services and provide pricing optimization:

Services: ${services.map((s) => '${s['title']}: \$${s['price']}').join(', ')}

Provide recommendations in JSON format:
{
  "services": [
    {
      "service_id": "...",
      "current_price": 0,
      "suggested_price": 0,
      "reasoning": "...",
      "expected_revenue_increase": 0,
      "confidence": 0.0-1.0
    }
  ],
  "overall_strategy": "..."
}
''';

      final response = await _claude.callClaudeAPI(prompt);
      final recommendations = _parsePricingRecommendations(response);

      return recommendations;
    } catch (e) {
      debugPrint('Generate pricing recommendations error: $e');
      return {};
    }
  }

  /// Predict revenue growth
  Future<Map<String, dynamic>> predictRevenueGrowth() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final userId = _auth.currentUser!.id;

      // Get historical data
      final snapshots = await _client
          .from('revenue_analytics_snapshots')
          .select()
          .eq('creator_user_id', userId)
          .gte(
            'snapshot_date',
            DateTime.now()
                .subtract(const Duration(days: 180))
                .toIso8601String()
                .split('T')[0],
          )
          .order('snapshot_date', ascending: true);

      if ((snapshots as List).isEmpty) {
        return _getDefaultGrowthPrediction();
      }

      // Calculate scenarios
      final currentStrategy = _calculateCurrentTrend(snapshots);
      final optimizedPricing = currentStrategy * 1.15; // 15% increase
      final contentFocus = currentStrategy * 1.25; // 25% increase
      final multiChannel = currentStrategy * 1.40; // 40% increase

      return {
        'current_strategy': {
          'month_3': currentStrategy,
          'month_6': currentStrategy * 1.05,
          'month_12': currentStrategy * 1.10,
        },
        'optimized_pricing': {
          'month_3': optimizedPricing,
          'month_6': optimizedPricing * 1.05,
          'month_12': optimizedPricing * 1.10,
        },
        'content_focus': {
          'month_3': contentFocus,
          'month_6': contentFocus * 1.08,
          'month_12': contentFocus * 1.15,
        },
        'multi_channel': {
          'month_3': multiChannel,
          'month_6': multiChannel * 1.10,
          'month_12': multiChannel * 1.20,
        },
      };
    } catch (e) {
      debugPrint('Predict revenue growth error: $e');
      return _getDefaultGrowthPrediction();
    }
  }

  /// Update recommendation status
  Future<bool> updateRecommendationStatus({
    required String recommendationId,
    required String status,
  }) async {
    try {
      await _client
          .from('claude_optimization_recommendations')
          .update({
            'status': status,
            if (status == 'implemented')
              'implemented_at': DateTime.now().toIso8601String(),
          })
          .eq('recommendation_id', recommendationId);

      return true;
    } catch (e) {
      debugPrint('Update recommendation status error: $e');
      return false;
    }
  }

  /// Ask Claude a coaching question
  Future<String> askCoachingQuestion(String question) async {
    try {
      if (!_auth.isAuthenticated) return 'Please sign in to use coaching.';

      final userId = _auth.currentUser!.id;
      final creatorData = await _collectCreatorData(userId);

      final prompt =
          '''
You are an expert creator economy coach. Answer this creator's question:

Creator Profile:
- Tier: ${creatorData['tier']}
- Total Earnings: \$${creatorData['total_earnings']}
- This Month: \$${creatorData['this_month_earnings']}

Question: $question

Provide a helpful, specific, actionable answer (2-3 paragraphs).
''';

      final response = await _claude.callClaudeAPI(prompt);
      return response.isNotEmpty
          ? response
          : 'Unable to generate response. Please try again.';
    } catch (e) {
      debugPrint('Ask coaching question error: $e');
      return 'Error processing your question. Please try again.';
    }
  }

  /// Get coaching session history
  Future<List<Map<String, dynamic>>> getCoachingHistory() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final userId = _auth.currentUser!.id;

      final response = await _client
          .from('revenue_coaching_sessions')
          .select()
          .eq('creator_user_id', userId)
          .order('session_date', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get coaching history error: $e');
      return [];
    }
  }

  /// Get revenue roadmap
  Future<List<Map<String, dynamic>>> getRevenueRoadmap() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final userId = _auth.currentUser!.id;

      // Get pending and accepted recommendations
      final recommendations = await _client
          .from('claude_optimization_recommendations')
          .select()
          .eq('creator_user_id', userId)
          .inFilter('status', ['pending', 'accepted', 'implemented'])
          .order('priority', ascending: true)
          .order('recommended_at', ascending: false)
          .limit(5);

      // Transform to roadmap steps
      final roadmapSteps = <Map<String, dynamic>>[];
      for (var i = 0; i < (recommendations as List).length; i++) {
        final rec = recommendations[i];
        roadmapSteps.add({
          'step_number': i + 1,
          'title': rec['title'],
          'description': rec['description'],
          'eta': _calculateETA(rec['timeframe']),
          'impact_amount': rec['estimated_impact_usd'],
          'status': rec['status'],
        });
      }

      return roadmapSteps;
    } catch (e) {
      debugPrint('Get revenue roadmap error: $e');
      return [];
    }
  }

  /// Get coaching data for chat interface
  Future<Map<String, dynamic>> getCoachingData() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final userId = _auth.currentUser!.id;

      // Get recent coaching sessions
      final sessions = await _client
          .from('revenue_coaching_sessions')
          .select()
          .eq('creator_user_id', userId)
          .order('session_date', ascending: false)
          .limit(10);

      // Build conversation history
      final conversationHistory = <Map<String, dynamic>>[];
      for (final session in sessions as List) {
        final recommendations = session['recommendations'] as List? ?? [];
        if (recommendations.isNotEmpty) {
          conversationHistory.add({
            'role': 'assistant',
            'content': recommendations.join('\n'),
            'timestamp': session['session_date'],
          });
        }
      }

      return {
        'conversation_history': conversationHistory,
        'total_sessions': sessions.length,
      };
    } catch (e) {
      debugPrint('Get coaching data error: $e');
      return {'conversation_history': []};
    }
  }

  /// Implement a recommendation
  Future<bool> implementRecommendation(String recommendationId) async {
    try {
      await _client
          .from('claude_optimization_recommendations')
          .update({
            'status': 'implemented',
            'implemented_at': DateTime.now().toIso8601String(),
          })
          .eq('recommendation_id', recommendationId);

      return true;
    } catch (e) {
      debugPrint('Implement recommendation error: $e');
      return false;
    }
  }

  /// Dismiss a recommendation
  Future<bool> dismissRecommendation(String recommendationId) async {
    try {
      await _client
          .from('claude_optimization_recommendations')
          .update({'status': 'dismissed'})
          .eq('recommendation_id', recommendationId);

      return true;
    } catch (e) {
      debugPrint('Dismiss recommendation error: $e');
      return false;
    }
  }

  /// Ask coach a question
  Future<bool> askCoach(String question) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final userId = _auth.currentUser!.id;
      final response = await askCoachingQuestion(question);

      // Store in coaching sessions
      await _client.from('revenue_coaching_sessions').insert({
        'creator_user_id': userId,
        'session_type': 'on_demand',
        'analysis_data': {'question': question},
        'recommendations': [response],
        'session_date': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Ask coach error: $e');
      return false;
    }
  }

  String _calculateETA(String? timeframe) {
    switch (timeframe?.toLowerCase()) {
      case 'immediate':
        return 'Now';
      case 'short':
        return '1 week';
      case 'medium':
        return '2 weeks';
      case 'long':
        return '1 month';
      default:
        return 'TBD';
    }
  }

  // Private helper methods

  Future<Map<String, dynamic>> _collectCreatorData(String userId) async {
    final account = await _client
        .from('creator_accounts')
        .select('total_earnings, tier_level')
        .eq('user_id', userId)
        .maybeSingle();

    final snapshots = await _client
        .from('revenue_analytics_snapshots')
        .select()
        .eq('creator_user_id', userId)
        .gte(
          'snapshot_date',
          DateTime.now()
              .subtract(const Duration(days: 30))
              .toIso8601String()
              .split('T')[0],
        );

    double thisMonthEarnings = 0;
    for (final snapshot in snapshots as List) {
      thisMonthEarnings += (snapshot['total_revenue'] as num).toDouble();
    }

    return {
      'tier': account?['tier_level'] ?? 'bronze',
      'total_earnings': account?['total_earnings'] ?? 0.0,
      'this_month_earnings': thisMonthEarnings,
      'snapshots': snapshots,
    };
  }

  String _buildEarningAnalysisPrompt(Map<String, dynamic> creatorData) {
    return '''
Analyze this creator's revenue patterns for optimization opportunities.

Creator Profile:
- Tier: ${creatorData['tier']}
- Total Earnings: \$${creatorData['total_earnings']}
- This Month: \$${creatorData['this_month_earnings']}

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
  "recommendations": ["..."],
  "insights": "..."
}
''';
  }

  Map<String, dynamic> _parseEarningAnalysis(String response) {
    try {
      final jsonObject = _extractJsonObject(response);
      if (jsonObject == null) return _getDefaultAnalysis();
      return {
        'opportunities': List<Map<String, dynamic>>.from(
          (jsonObject['opportunities'] as List? ?? []).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        ),
        'recommendations': List<dynamic>.from(
          jsonObject['recommendations'] as List? ?? [],
        ),
        'insights': jsonObject['insights']?.toString() ?? '',
      };
    } catch (e) {
      return _getDefaultAnalysis();
    }
  }

  Map<String, dynamic> _parsePricingRecommendations(String response) {
    final jsonObject = _extractJsonObject(response);
    if (jsonObject == null) {
      return {
        'has_services': true,
        'recommendations': <Map<String, dynamic>>[],
        'overall_strategy': '',
      };
    }
    return {
      'has_services': true,
      'recommendations': List<Map<String, dynamic>>.from(
        (jsonObject['services'] as List? ?? jsonObject['recommendations'] as List? ?? []).map(
          (item) => Map<String, dynamic>.from(item as Map),
        ),
      ),
      'overall_strategy': jsonObject['overall_strategy']?.toString() ?? '',
    };
  }

  Map<String, dynamic>? _extractJsonObject(String response) {
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(response);
    if (match == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(match.group(0)!) as Map);
    } catch (_) {
      return null;
    }
  }

  double _calculateCurrentTrend(List<dynamic> snapshots) {
    if (snapshots.isEmpty) return 1000.0;

    double total = 0;
    for (final snapshot in snapshots) {
      total += (snapshot['total_revenue'] as num).toDouble();
    }

    return total / snapshots.length * 30; // Monthly average
  }

  Future<void> _storeCoachingSession({
    required String userId,
    required String sessionType,
    required Map<String, dynamic> analysisData,
    required List<dynamic> recommendations,
  }) async {
    await _client.from('revenue_coaching_sessions').insert({
      'creator_user_id': userId,
      'session_type': sessionType,
      'analysis_data': analysisData,
      'recommendations': recommendations,
    });
  }

  Map<String, dynamic> _getDefaultAnalysis() {
    return {
      'opportunities': [],
      'recommendations': [],
      'insights': 'Insufficient data for analysis',
    };
  }

  Map<String, dynamic> _getDefaultGrowthPrediction() {
    return {
      'current_strategy': {'month_3': 0.0, 'month_6': 0.0, 'month_12': 0.0},
      'optimized_pricing': {'month_3': 0.0, 'month_6': 0.0, 'month_12': 0.0},
      'content_focus': {'month_3': 0.0, 'month_6': 0.0, 'month_12': 0.0},
      'multi_channel': {'month_3': 0.0, 'month_6': 0.0, 'month_12': 0.0},
    };
  }
}
