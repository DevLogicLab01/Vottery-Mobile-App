import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/ai_consensus_result.dart';
import './ai/ai_service_base.dart';

/// AI Orchestration Service for Multi-AI Consensus Analysis
/// Coordinates multiple AI providers (Claude, Gemini)
class AIOrchestratorService extends AIServiceBase {
  static AIOrchestratorService? _instance;
  static AIOrchestratorService get instance =>
      _instance ??= AIOrchestratorService._();

  AIOrchestratorService._();

  static final SupabaseClient supabase = Supabase.instance.client;

  /// Multi-AI consensus analysis with cross-provider validation
  ///
  /// Analyzes context using multiple AI providers and generates consensus
  /// [context] - The content/data to analyze
  /// [analysisType] - Type of analysis (fraud_detection, content_moderation, etc.)
  /// [providers] - List of AI providers to use for consensus
  ///
  /// Returns [AIConsensusResult] with aggregated analysis from all providers
  static Future<AIConsensusResult> analyzeWithConsensus({
    required String context,
    required String analysisType,
    List<String> providers = const [
      'anthropic',
      'gemini',
    ],
  }) async {
    try {
      final response =
          await AIServiceBase.invokeAIFunction('ai-consensus-orchestration', {
            'context': context,
            'analysis_type': analysisType,
            'providers': providers,
            'confidence_threshold': 0.8,
            'timestamp': DateTime.now().toIso8601String(),
          });

      AIServiceBase.validateResponse(response, [
        'analysis_id',
        'consensus',
        'provider_responses',
      ]);
      // Apply shared auto-approval policy from Supabase so Web & Mobile behave consistently.
      try {
        final policyQuery = await supabase
            .from('ai_auto_approval_policies')
            .select()
            .eq('analysis_type', analysisType)
            .eq('enabled', true)
            .maybeSingle();

        if (policyQuery != null) {
          final minConfidence =
              (policyQuery['min_confidence'] as num?)?.toDouble() ?? 0.0;
          final consensus = (response['consensus'] as Map<String, dynamic>? ??
              <String, dynamic>{});
          final confidence =
              (response['confidence_score'] as num?)?.toDouble() ??
                  (consensus['average_confidence'] as num?)?.toDouble() ??
                  0.0;

          final hasConsensus = consensus['has_consensus'] == true ||
              consensus['hasConsensus'] == true;
          final autoApproved = hasConsensus && confidence >= minConfidence;

          consensus['auto_approved'] = autoApproved;
          consensus['policy'] = {
            'analysis_type': analysisType,
            'min_confidence': minConfidence,
            'enabled': policyQuery['enabled'] == true,
          };

          response['consensus'] = consensus;
        }
      } catch (_) {
        // If policy lookup fails, fall back to requiring manual approval.
      }

      return AIConsensusResult.fromJson(response);
    } catch (e) {
      throw AIServiceException(
        'Failed to perform consensus analysis: ${e.toString()}',
        e,
      );
    }
  }

  /// Real-time consensus monitoring stream
  ///
  /// Monitors ongoing consensus analysis and provides live updates
  /// [analysisId] - ID of the analysis to monitor
  ///
  /// Returns Stream of [AIConsensusUpdate] with real-time progress
  static Stream<AIConsensusUpdate> getConsensusUpdates(String analysisId) {
    try {
      return supabase
          .from('ai_consensus_results')
          .stream(primaryKey: ['id'])
          .eq('analysis_id', analysisId)
          .map((data) {
            if (data.isEmpty) {
              throw AIServiceException(
                'No consensus data found for analysis: $analysisId',
              );
            }
            return AIConsensusUpdate.fromJson(data.first);
          })
          .handleError((error) {
            throw AIServiceException(
              'Consensus stream error: ${error.toString()}',
              error,
            );
          });
    } catch (e) {
      throw AIServiceException(
        'Failed to create consensus stream: ${e.toString()}',
        e,
      );
    }
  }

  /// Automatic failover status monitoring
  ///
  /// Monitors AI service performance metrics and failover status
  /// Provides real-time health status of all AI providers
  ///
  /// Returns Stream of [AIFailoverStatus] with provider health metrics
  static Stream<AIFailoverStatus> getFailoverStatus() {
    try {
      return supabase
          .from('ai_service_performance_metrics')
          .stream(primaryKey: ['id'])
          .map((data) {
            if (data.isEmpty) {
              return AIFailoverStatus(
                serviceId: 'ai-orchestration',
                status: 'unknown',
                activeProviders: [],
                failedProviders: [],
                providerLatencies: {},
                lastChecked: DateTime.now(),
              );
            }
            return AIFailoverStatus.fromMetrics(data);
          })
          .handleError((error) {
            throw AIServiceException(
              'Failover status stream error: ${error.toString()}',
              error,
            );
          });
    } catch (e) {
      throw AIServiceException(
        'Failed to create failover status stream: ${e.toString()}',
        e,
      );
    }
  }

  /// Batch consensus analysis for multiple contexts
  ///
  /// Analyzes multiple contexts in parallel using consensus
  /// [contexts] - Map of context IDs to context data
  /// [analysisType] - Type of analysis to perform
  ///
  /// Returns Map of context IDs to their consensus results
  static Future<Map<String, AIConsensusResult>> batchAnalyzeWithConsensus({
    required Map<String, String> contexts,
    required String analysisType,
    List<String> providers = const [
      'anthropic',
      'gemini',
    ],
  }) async {
    try {
      final results = <String, AIConsensusResult>{};

      await Future.wait(
        contexts.entries.map((entry) async {
          final result = await analyzeWithConsensus(
            context: entry.value,
            analysisType: analysisType,
            providers: providers,
          );
          results[entry.key] = result;
        }),
      );

      return results;
    } catch (e) {
      throw AIServiceException(
        'Batch consensus analysis failed: ${e.toString()}',
        e,
      );
    }
  }

  /// Get historical consensus results
  ///
  /// Retrieves past consensus analysis results for review
  /// [analysisType] - Optional filter by analysis type
  /// [limit] - Maximum number of results to return
  ///
  /// Returns List of historical [AIConsensusResult]
  static Future<List<AIConsensusResult>> getHistoricalConsensus({
    String? analysisType,
    int limit = 50,
  }) async {
    try {
      var query = supabase.from('ai_consensus_results').select();

      if (analysisType != null) {
        query = query.eq('analysis_type', analysisType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((e) => AIConsensusResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw AIServiceException(
        'Failed to fetch historical consensus: ${e.toString()}',
        e,
      );
    }
  }

  /// Check consensus service health
  ///
  /// Verifies that consensus orchestration is operational
  /// Returns true if service is healthy
  static Future<bool> isConsensusServiceHealthy() async {
    try {
      final response = await AIServiceBase.invokeAIFunction('health-check', {
        'service': 'consensus-orchestration',
      });

      return response['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }
}
