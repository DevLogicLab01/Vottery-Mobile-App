class AIConsensusResult {
  final String analysisId;
  final String analysisType;
  final Map<String, dynamic> consensus;
  final List<AIProviderResponse> providerResponses;
  final double confidenceScore;
  final String finalRecommendation;
  final DateTime timestamp;

  AIConsensusResult({
    required this.analysisId,
    required this.analysisType,
    required this.consensus,
    required this.providerResponses,
    required this.confidenceScore,
    required this.finalRecommendation,
    required this.timestamp,
  });

  factory AIConsensusResult.fromJson(Map<String, dynamic> json) {
    return AIConsensusResult(
      analysisId: json['analysis_id'] as String? ?? '',
      analysisType: json['analysis_type'] as String? ?? '',
      consensus: json['consensus'] as Map<String, dynamic>? ?? {},
      providerResponses: (json['provider_responses'] as List<dynamic>? ?? [])
          .map((e) => AIProviderResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      finalRecommendation: json['final_recommendation'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'analysis_id': analysisId,
      'analysis_type': analysisType,
      'consensus': consensus,
      'provider_responses': providerResponses.map((e) => e.toJson()).toList(),
      'confidence_score': confidenceScore,
      'final_recommendation': finalRecommendation,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class AIProviderResponse {
  final String provider;
  final Map<String, dynamic> response;
  final double confidence;
  final int latencyMs;

  AIProviderResponse({
    required this.provider,
    required this.response,
    required this.confidence,
    required this.latencyMs,
  });

  factory AIProviderResponse.fromJson(Map<String, dynamic> json) {
    return AIProviderResponse(
      provider: json['provider'] as String? ?? '',
      response: json['response'] as Map<String, dynamic>? ?? {},
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      latencyMs: json['latency_ms'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'response': response,
      'confidence': confidence,
      'latency_ms': latencyMs,
    };
  }
}

class AIConsensusUpdate {
  final String analysisId;
  final String status;
  final int completedProviders;
  final int totalProviders;
  final Map<String, dynamic>? partialResults;
  final DateTime updatedAt;

  AIConsensusUpdate({
    required this.analysisId,
    required this.status,
    required this.completedProviders,
    required this.totalProviders,
    this.partialResults,
    required this.updatedAt,
  });

  factory AIConsensusUpdate.fromJson(Map<String, dynamic> json) {
    return AIConsensusUpdate(
      analysisId: json['analysis_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      completedProviders: json['completed_providers'] as int? ?? 0,
      totalProviders: json['total_providers'] as int? ?? 0,
      partialResults: json['partial_results'] as Map<String, dynamic>?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
}

class AIFailoverStatus {
  final String serviceId;
  final String status;
  final List<String> activeProviders;
  final List<String> failedProviders;
  final Map<String, double> providerLatencies;
  final DateTime lastChecked;

  AIFailoverStatus({
    required this.serviceId,
    required this.status,
    required this.activeProviders,
    required this.failedProviders,
    required this.providerLatencies,
    required this.lastChecked,
  });

  factory AIFailoverStatus.fromMetrics(List<Map<String, dynamic>> metrics) {
    final activeProviders = <String>[];
    final failedProviders = <String>[];
    final providerLatencies = <String, double>{};

    for (final metric in metrics) {
      final provider = metric['provider'] as String? ?? '';
      final status = metric['status'] as String? ?? '';
      final latency = (metric['avg_latency_ms'] as num?)?.toDouble() ?? 0.0;

      if (status == 'active') {
        activeProviders.add(provider);
      } else {
        failedProviders.add(provider);
      }

      providerLatencies[provider] = latency;
    }

    return AIFailoverStatus(
      serviceId: 'ai-orchestration',
      status: activeProviders.isNotEmpty ? 'operational' : 'degraded',
      activeProviders: activeProviders,
      failedProviders: failedProviders,
      providerLatencies: providerLatencies,
      lastChecked: DateTime.now(),
    );
  }
}
