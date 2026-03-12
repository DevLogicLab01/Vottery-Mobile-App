import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:faker/faker.dart';
import 'dart:math';
import './supabase_service.dart';

/// Synthetic Incident Generator Service
/// Creates realistic fake incidents for testing incident response systems
class SyntheticIncidentGenerator {
  static SyntheticIncidentGenerator? _instance;
  static SyntheticIncidentGenerator get instance =>
      _instance ??= SyntheticIncidentGenerator._();

  SyntheticIncidentGenerator._();

  SupabaseClient get _client => SupabaseService.instance.client;
  final _faker = Faker();
  final _random = Random();

  // Test user pool for synthetic incidents
  final List<String> _testUserPool = [
    'test_user_001',
    'test_user_002',
    'test_user_003',
    'test_user_004',
    'test_user_005',
  ];

  /// Generate fraud incident with fake fraud patterns
  Future<Map<String, dynamic>> generateFraudIncident({
    String? patternType,
    double? confidenceScore,
    int? userCount,
    int? evidenceCount,
  }) async {
    try {
      final userId = _testUserPool[_random.nextInt(_testUserPool.length)];
      final ipAddress = _generateFakeIP();
      final eventTypes = [
        'authentication',
        'payment',
        'voting',
        'account_creation',
      ];
      final eventType = eventTypes[_random.nextInt(eventTypes.length)];

      final patterns = [
        'multi_account_abuse',
        'credential_stuffing',
        'payment_fraud',
        'vote_manipulation',
        'account_takeover',
      ];
      final pattern = patternType ?? patterns[_random.nextInt(patterns.length)];

      final confidence = confidenceScore ?? (0.5 + _random.nextDouble() * 0.5);

      // Create synthetic log entry
      final logEntry = {
        'user_id': userId,
        'ip_address': ipAddress,
        'event_type': eventType,
        'severity': 'critical',
        'timestamp': DateTime.now()
            .subtract(Duration(minutes: _random.nextInt(60)))
            .toIso8601String(),
        'metadata': {
          'synthetic': true,
          'pattern': pattern,
          'confidence': confidence,
          'evidence_count': evidenceCount ?? _random.nextInt(10) + 1,
        },
      };

      // Insert into platform_logs_aggregated
      await _client.from('platform_logs_aggregated').insert(logEntry);

      // Store synthetic incident record
      final syntheticRecord = await _client
          .from('synthetic_incidents')
          .insert({
            'incident_type': 'fraud',
            'parameters': {
              'pattern_type': pattern,
              'confidence_score': confidence,
              'user_count': userCount ?? 1,
              'evidence_count': evidenceCount ?? _random.nextInt(10) + 1,
              'user_id': userId,
              'ip_address': ipAddress,
              'event_type': eventType,
            },
          })
          .select()
          .single();

      debugPrint(
        '✅ Generated fraud incident: ${syntheticRecord['synthetic_id']}',
      );

      return {
        'success': true,
        'synthetic_id': syntheticRecord['synthetic_id'],
        'pattern': pattern,
        'confidence': confidence,
        'log_entry': logEntry,
      };
    } catch (e) {
      debugPrint('❌ Generate fraud incident error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generate AI failover incident by simulating service failure
  Future<Map<String, dynamic>> generateFailoverIncident({
    String? serviceName,
    String? failureType,
    int? failureDurationSeconds,
  }) async {
    try {
      final services = ['openai', 'anthropic', 'perplexity', 'gemini'];
      final service = serviceName ?? services[_random.nextInt(services.length)];

      final failureTypes = [
        'timeout',
        'rate_limit',
        'server_error',
        'connection_error',
      ];
      final failure =
          failureType ?? failureTypes[_random.nextInt(failureTypes.length)];

      final duration = failureDurationSeconds ?? (_random.nextInt(298) + 2);

      // Insert failure record into ai_service_health_log
      await _client.from('ai_service_health_log').insert({
        'service_name': service,
        'status': 'down',
        'response_time_ms': 5000,
        'consecutive_failures': 3,
        'health_score': 0,
        'error_message': 'Synthetic failure: $failure',
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Store synthetic incident record
      final syntheticRecord = await _client
          .from('synthetic_incidents')
          .insert({
            'incident_type': 'ai_failover',
            'parameters': {
              'service_name': service,
              'failure_type': failure,
              'failure_duration_seconds': duration,
            },
          })
          .select()
          .single();

      debugPrint(
        '✅ Generated AI failover incident: ${syntheticRecord['synthetic_id']}',
      );

      return {
        'success': true,
        'synthetic_id': syntheticRecord['synthetic_id'],
        'service': service,
        'failure_type': failure,
        'duration': duration,
      };
    } catch (e) {
      debugPrint('❌ Generate failover incident error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generate security incident
  Future<Map<String, dynamic>> generateSecurityIncident({
    String? attackType,
    String? severity,
    List<String>? affectedResources,
  }) async {
    try {
      final attackTypes = [
        'SQL_injection',
        'XSS',
        'brute_force',
        'DDoS',
        'unauthorized_access',
      ];
      final attack =
          attackType ?? attackTypes[_random.nextInt(attackTypes.length)];

      final severities = ['critical', 'high', 'medium', 'low'];
      final sev = severity ?? severities[_random.nextInt(severities.length)];

      final resources =
          affectedResources ??
          [
            'api_endpoint_${_random.nextInt(100)}',
            'database_${_random.nextInt(10)}',
          ];

      // Insert into security_incidents table
      await _client.from('security_incidents').insert({
        'title': 'Synthetic $attack Attack',
        'description': 'Simulated security incident for testing',
        'severity': sev,
        'status': 'active',
        'affected_systems': resources,
        'detected_at': DateTime.now().toIso8601String(),
      });

      // Store synthetic incident record
      final syntheticRecord = await _client
          .from('synthetic_incidents')
          .insert({
            'incident_type': 'security',
            'parameters': {
              'attack_type': attack,
              'severity': sev,
              'affected_resources': resources,
            },
          })
          .select()
          .single();

      debugPrint(
        '✅ Generated security incident: ${syntheticRecord['synthetic_id']}',
      );

      return {
        'success': true,
        'synthetic_id': syntheticRecord['synthetic_id'],
        'attack_type': attack,
        'severity': sev,
        'resources': resources,
      };
    } catch (e) {
      debugPrint('❌ Generate security incident error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Batch generate multiple incidents
  Future<Map<String, dynamic>> batchGenerate({
    required int fraudCount,
    required int failoverCount,
    required int securityCount,
    String timing = 'immediate',
    int? distributionMinutes,
  }) async {
    try {
      final results = {
        'fraud': <Map<String, dynamic>>[],
        'failover': <Map<String, dynamic>>[],
        'security': <Map<String, dynamic>>[],
      };

      // Generate fraud incidents
      for (int i = 0; i < fraudCount; i++) {
        if (timing == 'distributed' && distributionMinutes != null) {
          await Future.delayed(
            Duration(milliseconds: (distributionMinutes * 60000) ~/ fraudCount),
          );
        }
        final result = await generateFraudIncident();
        if (result['success'] == true) {
          results['fraud']!.add(result);
        }
      }

      // Generate failover incidents
      for (int i = 0; i < failoverCount; i++) {
        if (timing == 'distributed' && distributionMinutes != null) {
          await Future.delayed(
            Duration(
              milliseconds: (distributionMinutes * 60000) ~/ failoverCount,
            ),
          );
        }
        final result = await generateFailoverIncident();
        if (result['success'] == true) {
          results['failover']!.add(result);
        }
      }

      // Generate security incidents
      for (int i = 0; i < securityCount; i++) {
        if (timing == 'distributed' && distributionMinutes != null) {
          await Future.delayed(
            Duration(
              milliseconds: (distributionMinutes * 60000) ~/ securityCount,
            ),
          );
        }
        final result = await generateSecurityIncident();
        if (result['success'] == true) {
          results['security']!.add(result);
        }
      }

      debugPrint(
        '✅ Batch generation complete: ${results['fraud']!.length} fraud, '
        '${results['failover']!.length} failover, ${results['security']!.length} security',
      );

      return {
        'success': true,
        'total_generated':
            results['fraud']!.length +
            results['failover']!.length +
            results['security']!.length,
        'results': results,
      };
    } catch (e) {
      debugPrint('❌ Batch generate error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  String _generateFakeIP() {
    return '${_random.nextInt(256)}.${_random.nextInt(256)}.'
        '${_random.nextInt(256)}.${_random.nextInt(256)}';
  }
}
