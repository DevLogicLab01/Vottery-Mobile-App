import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AI Service Cost Tracker
/// Tracks every API call with token usage and cost calculation
class AIServiceCostTracker {
  static AIServiceCostTracker? _instance;
  static AIServiceCostTracker get instance =>
      _instance ??= AIServiceCostTracker._();

  AIServiceCostTracker._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  // Pricing tables (cost per 1k tokens)
  static const Map<String, Map<String, Map<String, double>>> pricingTables = {
    'openai': {
      'gpt-4': {'input': 0.03, 'output': 0.06},
      'gpt-3.5-turbo': {'input': 0.001, 'output': 0.002},
    },
    'anthropic': {
      'claude-3-opus': {'input': 0.015, 'output': 0.075},
      'claude-3-sonnet': {'input': 0.003, 'output': 0.015},
    },
    'perplexity': {
      'sonar-pro': {'input': 0.001, 'output': 0.001},
    },
    'gemini': {
      'gemini-pro': {'input': 0.0005, 'output': 0.0015},
    },
  };

  /// Calculate cost for API call
  double calculateCost({
    required String serviceName,
    required String modelName,
    required int inputTokens,
    required int outputTokens,
  }) {
    final servicePrice = pricingTables[serviceName];
    if (servicePrice == null) return 0.0;

    final modelPrice = servicePrice[modelName];
    if (modelPrice == null) return 0.0;

    final inputCost = (inputTokens / 1000) * (modelPrice['input'] ?? 0.0);
    final outputCost = (outputTokens / 1000) * (modelPrice['output'] ?? 0.0);

    return inputCost + outputCost;
  }

  /// Log API call cost
  Future<void> logCost({
    required String serviceName,
    required String operationType,
    required String modelName,
    required int inputTokens,
    required int outputTokens,
    String? userId,
    String? requestId,
  }) async {
    final cost = calculateCost(
      serviceName: serviceName,
      modelName: modelName,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
    );

    await _supabase.from('ai_service_costs').insert({
      'service_name': serviceName,
      'operation_type': operationType,
      'model_name': modelName,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'cost_usd': cost,
      'user_id': userId,
      'request_id': requestId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get daily cost summary
  Future<Map<String, dynamic>> getDailyCostSummary({
    DateTime? targetDate,
  }) async {
    final date = targetDate ?? DateTime.now();

    final response = await _supabase.rpc(
      'get_daily_cost_summary',
      params: {'target_date': date.toIso8601String().split('T')[0]},
    );

    return {'date': date, 'services': response as List};
  }

  /// Get cost per operation type
  Future<List<Map<String, dynamic>>> getCostByOperation({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 30));
    final end = endDate ?? DateTime.now();

    final response = await _supabase
        .from('ai_service_costs')
        .select('operation_type, cost_usd')
        .gte('timestamp', start.toIso8601String())
        .lte('timestamp', end.toIso8601String());

    final grouped = <String, double>{};
    for (final row in response as List) {
      final opType = row['operation_type'] as String;
      final cost = (row['cost_usd'] as num).toDouble();
      grouped[opType] = (grouped[opType] ?? 0.0) + cost;
    }

    return grouped.entries
        .map((e) => {'operation_type': e.key, 'total_cost': e.value})
        .toList();
  }

  /// Get monthly cost trends
  Future<List<Map<String, dynamic>>> getMonthlyCostTrends({
    int months = 3,
  }) async {
    final endDate = DateTime.now();
    final startDate = DateTime(
      endDate.year,
      endDate.month - months,
      endDate.day,
    );

    final response = await _supabase
        .from('ai_service_costs')
        .select('service_name, cost_usd, timestamp')
        .gte('timestamp', startDate.toIso8601String())
        .lte('timestamp', endDate.toIso8601String())
        .order('timestamp');

    return response;
  }

  /// Check budget threshold
  Future<bool> checkBudgetThreshold({
    required String serviceName,
    required double dailyBudget,
  }) async {
    final summary = await getDailyCostSummary();
    final services = summary['services'] as List;

    final serviceCost = services.firstWhere(
      (s) => s['service_name'] == serviceName,
      orElse: () => {'total_cost': 0.0},
    );

    final totalCost = (serviceCost['total_cost'] as num).toDouble();

    return totalCost > dailyBudget;
  }
}
