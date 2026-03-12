import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import './auth_service.dart';
import './supabase_service.dart';
import './enhanced_lottery_service.dart';
import './voting_service.dart';
import './blockchain_verification_service.dart';

/// RESTful API Service Layer for Lottery Operations
/// Provides structured HTTP endpoints with JWT authentication
class RestfulApiService {
  static RestfulApiService? _instance;
  static RestfulApiService get instance => _instance ??= RestfulApiService._();

  RestfulApiService._();

  final Dio _dio = Dio();
  final String _baseUrl = '${SupabaseService.supabaseUrl}/functions/v1';
  final AuthService _auth = AuthService.instance;
  final EnhancedLotteryService _lotteryService =
      EnhancedLotteryService.instance;
  final VotingService _votingService = VotingService.instance;
  final BlockchainVerificationService _blockchainService =
      BlockchainVerificationService.instance;
  final Uuid _uuid = const Uuid();

  /// Cast vote in lottery election (POST /api/v1/lottery/cast-vote)
  Future<Map<String, dynamic>?> castVote({
    required String electionId,
    required String selectedOptionId,
    Map<String, dynamic>? additionalData,
  }) async {
    final requestId = _uuid.v4();
    final startTime = DateTime.now();

    try {
      if (!_auth.isAuthenticated) {
        throw Exception('Authentication required');
      }

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      // Log request
      await _logApiRequest(
        endpoint: '/api/v1/lottery/cast-vote',
        method: 'POST',
        requestId: requestId,
        requestBody: {
          'election_id': electionId,
          'selected_option_id': selectedOptionId,
          ...?additionalData,
        },
      );

      // Execute vote casting
      final success = await _votingService.castVote(
        electionId: electionId,
        selectedOptionId: selectedOptionId,
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      final response = {
        'success': success,
        'election_id': electionId,
        'voter_id': _auth.currentUser!.id,
        'timestamp': DateTime.now().toIso8601String(),
        'request_id': requestId,
      };

      // Log response
      await _logApiResponse(
        endpoint: '/api/v1/lottery/cast-vote',
        requestId: requestId,
        statusCode: success ? 200 : 400,
        responseTime: responseTime,
        responseBody: response,
      );

      return response;
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      await _logApiResponse(
        endpoint: '/api/v1/lottery/cast-vote',
        requestId: requestId,
        statusCode: 500,
        responseTime: responseTime,
        errorMessage: e.toString(),
      );
      debugPrint('Cast vote API error: $e');
      return null;
    }
  }

  /// Verify lottery ticket (GET /api/v1/lottery/verify)
  Future<Map<String, dynamic>?> verifyLotteryTicket({
    required String ticketId,
  }) async {
    final requestId = _uuid.v4();
    final startTime = DateTime.now();

    try {
      if (!_auth.isAuthenticated) {
        throw Exception('Authentication required');
      }

      final session = SupabaseService.instance.client.auth.currentSession;
      if (session == null) throw Exception('No active session');

      await _logApiRequest(
        endpoint: '/api/v1/lottery/verify',
        method: 'GET',
        requestId: requestId,
        requestBody: {'ticket_id': ticketId},
      );

      // Verify ticket via blockchain service
      final verification = await _blockchainService.verifyVoteIntegrity(
        ticketId,
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      final response = {
        'ticket_id': ticketId,
        'is_valid': verification['is_valid'] ?? false,
        'blockchain_hash': verification['blockchain_hash'],
        'timestamp': DateTime.now().toIso8601String(),
        'request_id': requestId,
      };

      await _logApiResponse(
        endpoint: '/api/v1/lottery/verify',
        requestId: requestId,
        statusCode: 200,
        responseTime: responseTime,
        responseBody: response,
      );

      return response;
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      await _logApiResponse(
        endpoint: '/api/v1/lottery/verify',
        requestId: requestId,
        statusCode: 500,
        responseTime: responseTime,
        errorMessage: e.toString(),
      );
      debugPrint('Verify ticket API error: $e');
      return null;
    }
  }

  /// Get lottery results (GET /api/v1/lottery/results)
  Future<Map<String, dynamic>?> getLotteryResults({
    required String lotteryId,
  }) async {
    final requestId = _uuid.v4();
    final startTime = DateTime.now();

    try {
      await _logApiRequest(
        endpoint: '/api/v1/lottery/results',
        method: 'GET',
        requestId: requestId,
        requestBody: {'lottery_id': lotteryId},
      );

      final lotteryDraw = await _lotteryService.getLotteryDraw(lotteryId);
      final winners = await _lotteryService.getLotteryWinnersSequential(
        lotteryId,
      );

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      final response = {
        'lottery_id': lotteryId,
        'draw_date': lotteryDraw?['draw_date'],
        'total_participants': lotteryDraw?['total_participants'] ?? 0,
        'winners': winners,
        'timestamp': DateTime.now().toIso8601String(),
        'request_id': requestId,
      };

      await _logApiResponse(
        endpoint: '/api/v1/lottery/results',
        requestId: requestId,
        statusCode: 200,
        responseTime: responseTime,
        responseBody: response,
      );

      return response;
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      await _logApiResponse(
        endpoint: '/api/v1/lottery/results',
        requestId: requestId,
        statusCode: 500,
        responseTime: responseTime,
        errorMessage: e.toString(),
      );
      debugPrint('Get lottery results API error: $e');
      return null;
    }
  }

  /// Get audit logs (GET /api/v1/audit/logs)
  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? startDate,
    String? endDate,
    String? endpoint,
    int limit = 100,
  }) async {
    final requestId = _uuid.v4();
    final startTime = DateTime.now();

    try {
      if (!_auth.isAuthenticated) {
        throw Exception('Authentication required');
      }

      await _logApiRequest(
        endpoint: '/api/v1/audit/logs',
        method: 'GET',
        requestId: requestId,
        requestBody: {
          'start_date': startDate,
          'end_date': endDate,
          'endpoint': endpoint,
          'limit': limit,
        },
      );

      var query = SupabaseService.instance.client
          .from('api_request_logs')
          .select();

      if (startDate != null) {
        query = query.gte('timestamp', startDate);
      }
      if (endDate != null) {
        query = query.lte('timestamp', endDate);
      }
      if (endpoint != null) {
        query = query.eq('endpoint', endpoint);
      }

      final logs = await query
          .order('timestamp', ascending: false)
          .limit(limit);

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;

      await _logApiResponse(
        endpoint: '/api/v1/audit/logs',
        requestId: requestId,
        statusCode: 200,
        responseTime: responseTime,
        responseBody: {'count': logs.length},
      );

      return List<Map<String, dynamic>>.from(logs);
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      await _logApiResponse(
        endpoint: '/api/v1/audit/logs',
        requestId: requestId,
        statusCode: 500,
        responseTime: responseTime,
        errorMessage: e.toString(),
      );
      debugPrint('Get audit logs API error: $e');
      return [];
    }
  }

  /// Get API performance metrics
  Future<Map<String, dynamic>> getApiPerformanceMetrics() async {
    try {
      final response = await SupabaseService.instance.client
          .from('api_performance_metrics')
          .select()
          .order('last_updated', ascending: false)
          .limit(1)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      debugPrint('Get API performance metrics error: $e');
      return {};
    }
  }

  /// Get endpoint statistics
  Future<List<Map<String, dynamic>>> getEndpointStatistics() async {
    try {
      final response = await SupabaseService.instance.client.rpc(
        'get_api_endpoint_statistics',
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Get endpoint statistics error: $e');
      return [];
    }
  }

  /// Log API request
  Future<void> _logApiRequest({
    required String endpoint,
    required String method,
    required String requestId,
    Map<String, dynamic>? requestBody,
  }) async {
    try {
      await SupabaseService.instance.client.from('api_request_logs').insert({
        'request_id': requestId,
        'endpoint': endpoint,
        'method': method,
        'user_id': _auth.currentUser?.id,
        'request_body': requestBody,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log API request error: $e');
    }
  }

  /// Log API response
  Future<void> _logApiResponse({
    required String endpoint,
    required String requestId,
    required int statusCode,
    required int responseTime,
    Map<String, dynamic>? responseBody,
    String? errorMessage,
  }) async {
    try {
      await SupabaseService.instance.client.from('api_response_logs').insert({
        'request_id': requestId,
        'endpoint': endpoint,
        'status_code': statusCode,
        'response_time_ms': responseTime,
        'response_body': responseBody,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update performance metrics
      await _updatePerformanceMetrics(
        endpoint: endpoint,
        responseTime: responseTime,
        statusCode: statusCode,
      );
    } catch (e) {
      debugPrint('Log API response error: $e');
    }
  }

  /// Update performance metrics
  Future<void> _updatePerformanceMetrics({
    required String endpoint,
    required int responseTime,
    required int statusCode,
  }) async {
    try {
      await SupabaseService.instance.client.rpc(
        'update_api_performance_metrics',
        params: {
          'p_endpoint': endpoint,
          'p_response_time': responseTime,
          'p_status_code': statusCode,
        },
      );
    } catch (e) {
      debugPrint('Update performance metrics error: $e');
    }
  }
}
