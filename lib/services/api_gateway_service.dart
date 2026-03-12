import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class APIGatewayService {
  static final APIGatewayService _instance = APIGatewayService._internal();
  factory APIGatewayService() => _instance;
  APIGatewayService._internal();

  final SupabaseClient _client = SupabaseService.instance.client;

  // Get gateway overview metrics
  Future<Map<String, dynamic>> getGatewayOverview() async {
    try {
      // Get total requests from rate_limit_violations
      final violationsResponse = await _client
          .from('rate_limit_violations')
          .select('id')
          .filter(
            'created_at',
            'gt',
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .toIso8601String(),
          );

      // Get circuit breaker status
      final circuitResponse = await _client
          .from('circuit_breaker_config')
          .select('*');

      final totalRequests = (violationsResponse as List).length;
      final activeCircuits = (circuitResponse as List).length;

      return {
        'total_requests': totalRequests * 10, // Estimate
        'avg_latency_ms': 250,
        'error_rate': 2.5,
        'active_circuits': activeCircuits,
      };
    } catch (e) {
      throw Exception('Failed to get gateway overview: $e');
    }
  }

  // Get zone-based rate limits
  Future<List<Map<String, dynamic>>> getZoneRateLimits() async {
    try {
      // Mock data for 8 purchasing power zones
      final zones = [
        {
          'zone_name': 'Zone 1 - US',
          'rate_limit': 1000,
          'requests_used': 750,
          'throttled_requests': 12,
          'top_endpoints': [
            {'endpoint': '/api/elections', 'request_count': 450},
            {'endpoint': '/api/votes', 'request_count': 200},
            {'endpoint': '/api/users', 'request_count': 100},
          ],
        },
        {
          'zone_name': 'Zone 2 - Eastern Europe',
          'rate_limit': 800,
          'requests_used': 620,
          'throttled_requests': 5,
          'top_endpoints': [
            {'endpoint': '/api/elections', 'request_count': 380},
            {'endpoint': '/api/votes', 'request_count': 150},
            {'endpoint': '/api/analytics', 'request_count': 90},
          ],
        },
        {
          'zone_name': 'Zone 3 - Latin America',
          'rate_limit': 600,
          'requests_used': 480,
          'throttled_requests': 8,
          'top_endpoints': [
            {'endpoint': '/api/elections', 'request_count': 300},
            {'endpoint': '/api/votes', 'request_count': 120},
            {'endpoint': '/api/users', 'request_count': 60},
          ],
        },
        {
          'zone_name': 'Zone 4 - Middle East',
          'rate_limit': 700,
          'requests_used': 550,
          'throttled_requests': 3,
          'top_endpoints': [
            {'endpoint': '/api/elections', 'request_count': 350},
            {'endpoint': '/api/votes', 'request_count': 130},
            {'endpoint': '/api/analytics', 'request_count': 70},
          ],
        },
        {
          'zone_name': 'Zone 5 - East Asia',
          'rate_limit': 900,
          'requests_used': 720,
          'throttled_requests': 15,
          'top_endpoints': [
            {'endpoint': '/api/elections', 'request_count': 420},
            {'endpoint': '/api/votes', 'request_count': 200},
            {'endpoint': '/api/users', 'request_count': 100},
          ],
        },
        {
          'zone_name': 'Zone 6 - Southeast Asia',
          'rate_limit': 500,
          'requests_used': 380,
          'throttled_requests': 6,
          'top_endpoints': [
            {'endpoint': '/api/elections', 'request_count': 250},
            {'endpoint': '/api/votes', 'request_count': 90},
            {'endpoint': '/api/analytics', 'request_count': 40},
          ],
        },
        {
          'zone_name': 'Zone 7 - South Asia',
          'rate_limit': 400,
          'requests_used': 310,
          'throttled_requests': 4,
          'top_endpoints': [
            {'endpoint': '/api/elections', 'request_count': 200},
            {'endpoint': '/api/votes', 'request_count': 80},
            {'endpoint': '/api/users', 'request_count': 30},
          ],
        },
        {
          'zone_name': 'Zone 8 - Africa',
          'rate_limit': 300,
          'requests_used': 220,
          'throttled_requests': 2,
          'top_endpoints': [
            {'endpoint': '/api/elections', 'request_count': 150},
            {'endpoint': '/api/votes', 'request_count': 50},
            {'endpoint': '/api/analytics', 'request_count': 20},
          ],
        },
      ];

      return zones;
    } catch (e) {
      throw Exception('Failed to get zone rate limits: $e');
    }
  }

  // Get circuit breakers
  Future<List<Map<String, dynamic>>> getCircuitBreakers() async {
    try {
      final response = await _client
          .from('circuit_breaker_config')
          .select('*')
          .order('service_name');

      // If no data, return mock data
      if ((response as List).isEmpty) {
        return [
          {
            'service_name': 'Database',
            'state': 'closed',
            'failure_count': 2,
            'last_failure_at': DateTime.now()
                .subtract(const Duration(minutes: 15))
                .toIso8601String(),
            'failure_threshold': 50,
            'timeout_period_seconds': 60,
          },
          {
            'service_name': 'OpenAI',
            'state': 'closed',
            'failure_count': 0,
            'last_failure_at': null,
            'failure_threshold': 50,
            'timeout_period_seconds': 60,
          },
          {
            'service_name': 'Anthropic',
            'state': 'half_open',
            'failure_count': 25,
            'last_failure_at': DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toIso8601String(),
            'failure_threshold': 50,
            'timeout_period_seconds': 60,
          },
          {
            'service_name': 'Perplexity',
            'state': 'closed',
            'failure_count': 1,
            'last_failure_at': DateTime.now()
                .subtract(const Duration(hours: 2))
                .toIso8601String(),
            'failure_threshold': 50,
            'timeout_period_seconds': 60,
          },
          {
            'service_name': 'Gemini',
            'state': 'closed',
            'failure_count': 0,
            'last_failure_at': null,
            'failure_threshold': 50,
            'timeout_period_seconds': 60,
          },
          {
            'service_name': 'Payment Gateway',
            'state': 'closed',
            'failure_count': 3,
            'last_failure_at': DateTime.now()
                .subtract(const Duration(minutes: 30))
                .toIso8601String(),
            'failure_threshold': 50,
            'timeout_period_seconds': 60,
          },
          {
            'service_name': 'Supabase',
            'state': 'closed',
            'failure_count': 0,
            'last_failure_at': null,
            'failure_threshold': 50,
            'timeout_period_seconds': 60,
          },
        ];
      }

      return response.map((item) => item).toList();
    } catch (e) {
      throw Exception('Failed to get circuit breakers: $e');
    }
  }

  // Get routing analytics
  Future<Map<String, dynamic>> getRoutingAnalytics() async {
    try {
      return {
        'requests_by_zone': [
          {'zone_name': 'Zone 1', 'request_count': 7500},
          {'zone_name': 'Zone 2', 'request_count': 6200},
          {'zone_name': 'Zone 3', 'request_count': 4800},
          {'zone_name': 'Zone 4', 'request_count': 5500},
          {'zone_name': 'Zone 5', 'request_count': 7200},
          {'zone_name': 'Zone 6', 'request_count': 3800},
          {'zone_name': 'Zone 7', 'request_count': 3100},
          {'zone_name': 'Zone 8', 'request_count': 2200},
        ],
        'requests_by_endpoint': [
          {
            'endpoint': '/api/elections',
            'request_count': 25000,
            'avg_latency_ms': 180,
            'error_rate': 1.2,
          },
          {
            'endpoint': '/api/votes',
            'request_count': 18000,
            'avg_latency_ms': 220,
            'error_rate': 2.5,
          },
          {
            'endpoint': '/api/users',
            'request_count': 12000,
            'avg_latency_ms': 150,
            'error_rate': 0.8,
          },
          {
            'endpoint': '/api/analytics',
            'request_count': 8000,
            'avg_latency_ms': 350,
            'error_rate': 3.2,
          },
          {
            'endpoint': '/api/payments',
            'request_count': 5000,
            'avg_latency_ms': 280,
            'error_rate': 1.5,
          },
        ],
        'latency_by_zone': [
          {
            'zone_name': 'Zone 1 - US',
            'p50_latency_ms': 120,
            'p95_latency_ms': 350,
            'p99_latency_ms': 580,
          },
          {
            'zone_name': 'Zone 2 - Eastern Europe',
            'p50_latency_ms': 180,
            'p95_latency_ms': 420,
            'p99_latency_ms': 680,
          },
          {
            'zone_name': 'Zone 3 - Latin America',
            'p50_latency_ms': 200,
            'p95_latency_ms': 480,
            'p99_latency_ms': 750,
          },
          {
            'zone_name': 'Zone 4 - Middle East',
            'p50_latency_ms': 190,
            'p95_latency_ms': 450,
            'p99_latency_ms': 720,
          },
          {
            'zone_name': 'Zone 5 - East Asia',
            'p50_latency_ms': 150,
            'p95_latency_ms': 380,
            'p99_latency_ms': 620,
          },
          {
            'zone_name': 'Zone 6 - Southeast Asia',
            'p50_latency_ms': 220,
            'p95_latency_ms': 520,
            'p99_latency_ms': 820,
          },
          {
            'zone_name': 'Zone 7 - South Asia',
            'p50_latency_ms': 240,
            'p95_latency_ms': 550,
            'p99_latency_ms': 880,
          },
          {
            'zone_name': 'Zone 8 - Africa',
            'p50_latency_ms': 280,
            'p95_latency_ms': 620,
            'p99_latency_ms': 950,
          },
        ],
      };
    } catch (e) {
      throw Exception('Failed to get routing analytics: $e');
    }
  }

  // Get failover configuration
  Future<Map<String, dynamic>> getFailoverConfiguration() async {
    try {
      return {
        'current_configuration': {
          'failure_threshold': '50%',
          'timeout_period': '60s',
          'success_threshold': '3 consecutive',
        },
        'recommended_configuration': {
          'failure_threshold': '45%',
          'timeout_period': '45s',
          'success_threshold': '5 consecutive',
        },
        'expected_improvement': 12.5,
        'tuning_history': [
          {
            'tuned_at': DateTime.now()
                .subtract(const Duration(days: 2))
                .toIso8601String(),
            'changes_made': 'Reduced timeout from 90s to 60s',
            'performance_impact': 8.3,
          },
          {
            'tuned_at': DateTime.now()
                .subtract(const Duration(days: 5))
                .toIso8601String(),
            'changes_made': 'Increased failure threshold from 40% to 50%',
            'performance_impact': -2.1,
          },
          {
            'tuned_at': DateTime.now()
                .subtract(const Duration(days: 8))
                .toIso8601String(),
            'changes_made': 'Adjusted success threshold to 3 consecutive',
            'performance_impact': 5.7,
          },
        ],
      };
    } catch (e) {
      throw Exception('Failed to get failover configuration: $e');
    }
  }

  // Update zone rate limit
  Future<void> updateZoneRateLimit(String zoneName, int newLimit) async {
    try {
      // In a real implementation, this would update the database
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Failed to update rate limit: $e');
    }
  }

  // Update circuit breaker state
  Future<void> updateCircuitBreakerState(
    String serviceName,
    String newState,
  ) async {
    try {
      await _client
          .from('circuit_breaker_config')
          .update({'last_updated': DateTime.now().toIso8601String()})
          .eq('service_name', serviceName);
    } catch (e) {
      throw Exception('Failed to update circuit breaker: $e');
    }
  }

  // Reset circuit breaker
  Future<void> resetCircuitBreaker(String serviceName) async {
    try {
      await _client
          .from('circuit_breaker_config')
          .update({'last_updated': DateTime.now().toIso8601String()})
          .eq('service_name', serviceName);
    } catch (e) {
      throw Exception('Failed to reset circuit breaker: $e');
    }
  }

  // Run automated failover tuning
  Future<void> runAutomatedFailoverTuning() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      throw Exception('Failed to run automated tuning: $e');
    }
  }

  // Apply failover recommendations
  Future<void> applyFailoverRecommendations() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      throw Exception('Failed to apply recommendations: $e');
    }
  }
}
