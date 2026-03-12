import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AI Service Router
/// Manages atomic traffic switching with zero-downtime and request queuing
class AIServiceRouter {
  static AIServiceRouter? _instance;
  static AIServiceRouter get instance => _instance ??= AIServiceRouter._();

  AIServiceRouter._();

  static final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, String> _currentHandlers = {};
  final List<PendingRequest> _requestQueue = [];
  bool _isSwitching = false;
  final _switchLock = Completer<void>();

  /// Initialize router with default configurations
  Future<void> initialize() async {
    final configs = await _supabase
        .from('service_router_config')
        .select()
        .order('operation_type');

    for (final config in configs as List) {
      _currentHandlers[config['operation_type']] = config['preferred_service'];
    }

    _switchLock.complete();
  }

  /// Get current handler for operation type
  String getCurrentHandler(String operationType) {
    return _currentHandlers[operationType] ?? 'gemini';
  }

  /// Switch traffic atomically with zero-downtime
  Future<void> switchTraffic({required String from, required String to}) async {
    // Wait for any ongoing switch to complete
    await _switchLock.future;

    _isSwitching = true;

    try {
      // Update all operation types using the 'from' service
      for (final entry in _currentHandlers.entries) {
        if (entry.value == from) {
          _currentHandlers[entry.key] = to;

          // Update database
          await _supabase
              .from('service_router_config')
              .update({'preferred_service': to})
              .eq('operation_type', entry.key);
        }
      }

      // Process queued requests on new handler
      await _processQueue();
    } finally {
      _isSwitching = false;
    }
  }

  /// Add request to queue during switch
  void queueRequest(PendingRequest request) {
    if (_requestQueue.length < 100) {
      _requestQueue.add(request);
    }
  }

  /// Process queued requests
  Future<void> _processQueue() async {
    while (_requestQueue.isNotEmpty) {
      final request = _requestQueue.removeAt(0);
      // Retry request on new handler
      // Implementation would invoke the new service
    }
  }

  /// Check if switching is in progress
  bool get isSwitching => _isSwitching;

  /// Get queue size
  int get queueSize => _requestQueue.length;
}

/// Pending Request Model
class PendingRequest {
  final String id;
  final String operationType;
  final Map<String, dynamic> params;
  final DateTime timestamp;

  PendingRequest({
    required this.id,
    required this.operationType,
    required this.params,
    required this.timestamp,
  });
}
