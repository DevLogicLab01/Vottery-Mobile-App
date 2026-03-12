import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content_moderation_result.dart';
import '../models/revenue_risk_analysis.dart';
import '../models/security_analysis_result.dart';
import './ai/ai_service_base.dart';

/// Anthropic Claude Security Service
/// Comprehensive security features using Claude for incident analysis,
/// content moderation, and revenue risk intelligence
class AnthropicService extends AIServiceBase {
  static AnthropicService? _instance;
  static AnthropicService get instance => _instance ??= AnthropicService._();

  AnthropicService._();

  static final SupabaseClient supabase = Supabase.instance.client;

  /// Security incident analysis with confidence scoring
  ///
  /// Analyzes security incidents using Claude's advanced reasoning
  /// Provides comprehensive threat assessment with confidence metrics
  ///
  /// [incidentId] - Unique identifier for the security incident
  /// [incidentData] - Detailed incident data for analysis
  ///
  /// Returns [SecurityAnalysisResult] with threat assessment and recommendations
  static Future<SecurityAnalysisResult> analyzeSecurityIncident({
    required String incidentId,
    required Map<String, dynamic> incidentData,
  }) async {
    try {
      final response =
          await AIServiceBase.invokeAIFunction('anthropic-security-reasoning', {
            'incident_id': incidentId,
            'incident_data': incidentData,
            'analysis_depth': 'comprehensive',
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, [
        'incident_id',
        'threat_level',
        'confidence_score',
      ]);

      return SecurityAnalysisResult.fromJson(response);
    } catch (e) {
      throw AIServiceException(
        'Failed to analyze security incident: ${e.toString()}',
        e,
      );
    }
  }

  /// Real-time content moderation
  ///
  /// Moderates user-generated content using Claude's safety features
  /// Detects policy violations, harmful content, and inappropriate material
  ///
  /// [contentId] - Unique identifier for the content
  /// [contentType] - Type of content (text, image, video, etc.)
  /// [content] - The actual content to moderate
  ///
  /// Returns [ContentModerationResult] with moderation decision and reasoning
  static Future<ContentModerationResult> moderateContent({
    required String contentId,
    required String contentType,
    required String content,
  }) async {
    try {
      final response =
          await AIServiceBase.invokeAIFunction('anthropic-content-moderation', {
            'content_id': contentId,
            'content_type': contentType,
            'content': content,
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, [
        'content_id',
        'decision',
        'confidence',
      ]);

      final result = ContentModerationResult.fromJson(response);

      // Log moderation action if content is flagged
      if (result.decision != 'approved') {
        await _logModerationAction(result);
      }

      return result;
    } catch (e) {
      throw AIServiceException(
        'Failed to moderate content: ${e.toString()}',
        e,
      );
    }
  }

  /// Revenue risk intelligence
  ///
  /// Analyzes revenue streams and identifies potential risks
  /// Provides strategic recommendations for revenue protection
  ///
  /// Returns [RevenueRiskAnalysis] with risk assessment and mitigation strategies
  static Future<RevenueRiskAnalysis> analyzeRevenueRisk() async {
    try {
      final response = await AIServiceBase.invokeAIFunction(
        'anthropic-revenue-risk-analysis',
        {
          'analysis_period': '90_days',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      AIServiceBase.validateResponse(response, [
        'analysis_id',
        'overall_risk_score',
        'risk_factors',
      ]);

      return RevenueRiskAnalysis.fromJson(response);
    } catch (e) {
      throw AIServiceException(
        'Failed to analyze revenue risk: ${e.toString()}',
        e,
      );
    }
  }

  /// Batch content moderation for multiple items
  ///
  /// Moderates multiple content items simultaneously for efficiency
  /// [contentItems] - List of content items to moderate
  ///
  /// Returns List of [ContentModerationResult]
  static Future<List<ContentModerationResult>> batchModerateContent(
    List<Map<String, dynamic>> contentItems,
  ) async {
    try {
      final results = await Future.wait(
        contentItems.map(
          (item) => moderateContent(
            contentId: item['content_id'] as String,
            contentType: item['content_type'] as String,
            content: item['content'] as String,
          ),
        ),
      );

      return results;
    } catch (e) {
      throw AIServiceException(
        'Batch content moderation failed: ${e.toString()}',
        e,
      );
    }
  }

  /// Get historical security incidents
  ///
  /// Retrieves past security incident analyses for review
  /// [limit] - Maximum number of incidents to return
  ///
  /// Returns List of historical [SecurityAnalysisResult]
  static Future<List<SecurityAnalysisResult>> getHistoricalIncidents({
    int limit = 50,
  }) async {
    try {
      final response = await supabase
          .from('security_incidents')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map(
            (e) => SecurityAnalysisResult.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw AIServiceException(
        'Failed to fetch historical incidents: ${e.toString()}',
        e,
      );
    }
  }

  /// Log moderation action for audit trail
  static Future<void> _logModerationAction(
    ContentModerationResult result,
  ) async {
    try {
      await supabase.from('content_moderation_logs').insert({
        'content_id': result.contentId,
        'decision': result.decision,
        'confidence': result.confidence,
        'violations': result.violations,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent fail - don't block moderation if logging fails
      print('Failed to log moderation action: $e');
    }
  }

  /// Stream real-time moderation events
  ///
  /// Monitors content moderation activity in real-time
  /// Returns Stream of [ContentModerationResult]
  static Stream<ContentModerationResult> getModerationStream() {
    try {
      return supabase
          .from('content_moderation_logs')
          .stream(primaryKey: ['id'])
          .map((data) {
            if (data.isEmpty) {
              throw AIServiceException('No moderation data available');
            }
            return ContentModerationResult.fromJson(data.first);
          })
          .handleError((error) {
            throw AIServiceException(
              'Moderation stream error: ${error.toString()}',
              error,
            );
          });
    } catch (e) {
      throw AIServiceException(
        'Failed to create moderation stream: ${e.toString()}',
        e,
      );
    }
  }

  /// Check security service health
  ///
  /// Verifies that Anthropic security services are operational
  /// Returns true if service is healthy
  static Future<bool> isSecurityServiceHealthy() async {
    try {
      final response = await AIServiceBase.invokeAIFunction('health-check', {
        'service': 'anthropic-security',
      });

      return response['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }
}
