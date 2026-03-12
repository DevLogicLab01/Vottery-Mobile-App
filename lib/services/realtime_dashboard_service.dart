import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

enum DashboardType {
  analytics,
  security,
  performance,
  fraud,
  operations,
  compliance,
}

class UpdateIntervalConfig {
  final Map<DashboardType, Duration> defaultIntervals = {
    DashboardType.analytics: const Duration(seconds: 60),
    DashboardType.security: const Duration(seconds: 30),
    DashboardType.performance: const Duration(seconds: 10),
    DashboardType.fraud: const Duration(seconds: 5),
    DashboardType.operations: const Duration(seconds: 15),
    DashboardType.compliance: const Duration(seconds: 300),
  };

  Map<DashboardType, Duration> customIntervals = {};
  Map<DashboardType, Duration> adminIntervals = {};

  Duration getInterval(DashboardType type, {bool isAdmin = false}) {
    if (isAdmin && adminIntervals.containsKey(type)) {
      return adminIntervals[type]!;
    }
    return customIntervals[type] ?? defaultIntervals[type]!;
  }
}

class RealtimeDashboardService {
  static final RealtimeDashboardService _instance =
      RealtimeDashboardService._internal();
  factory RealtimeDashboardService() => _instance;
  RealtimeDashboardService._internal();

  final Map<DashboardType, RealtimeChannel> _channels = {};
  final Map<DashboardType, StreamController<Map<String, dynamic>>>
  _controllers = {};
  final UpdateIntervalConfig config = UpdateIntervalConfig();

  bool _isConnected = false;
  DateTime? _lastUpdated;
  final Map<DashboardType, bool> _autoRefreshEnabled = {};
  final Map<DashboardType, int> _activeViewers = {};

  bool get isConnected => _isConnected;
  DateTime? get lastUpdated => _lastUpdated;

  Future<void> connect() async {
    try {
      _isConnected = true;
      _lastUpdated = DateTime.now();
    } catch (e) {
      _isConnected = false;
      await _reconnect();
    }
  }

  Future<void> _reconnect() async {
    int retryCount = 0;
    const maxRetries = 5;

    while (retryCount < maxRetries && !_isConnected) {
      await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
      try {
        await connect();
        break;
      } catch (e) {
        retryCount++;
      }
    }
  }

  Future<void> configureDashboardRefresh({
    required DashboardType dashboardType,
    required Duration updateInterval,
  }) async {
    config.customIntervals[dashboardType] = updateInterval;

    if (_channels.containsKey(dashboardType)) {
      await disconnect(dashboardType);
    }

    await _setupSubscription(dashboardType);
  }

  Future<void> _setupSubscription(DashboardType dashboardType) async {
    final tableName = _getTableName(dashboardType);
    final channel = SupabaseService.instance.client.channel(
      'dashboard_${dashboardType.name}',
    );

    if (!_controllers.containsKey(dashboardType)) {
      _controllers[dashboardType] =
          StreamController<Map<String, dynamic>>.broadcast();
    }

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            _lastUpdated = DateTime.now();
            if (_autoRefreshEnabled[dashboardType] ?? true) {
              _controllers[dashboardType]?.add({
                'type': payload.eventType.name,
                'data': payload.newRecord,
                'old_data': payload.oldRecord,
                'timestamp': DateTime.now().toIso8601String(),
              });
            }
          },
        )
        .subscribe();

    _channels[dashboardType] = channel;
    _autoRefreshEnabled[dashboardType] = true;
  }

  String _getTableName(DashboardType type) {
    switch (type) {
      case DashboardType.analytics:
        return 'metrics_updates';
      case DashboardType.security:
        return 'incident_updates';
      case DashboardType.performance:
        return 'performance_metrics';
      case DashboardType.fraud:
        return 'fraud_alerts';
      case DashboardType.operations:
        return 'system_health';
      case DashboardType.compliance:
        return 'compliance_audits';
    }
  }

  Stream<Map<String, dynamic>>? getStream(DashboardType type) {
    return _controllers[type]?.stream;
  }

  Future<void> disconnect(DashboardType dashboardType) async {
    await _channels[dashboardType]?.unsubscribe();
    _channels.remove(dashboardType);
    await _controllers[dashboardType]?.close();
    _controllers.remove(dashboardType);
  }

  Future<void> disconnectAll() async {
    for (final type in DashboardType.values) {
      await disconnect(type);
    }
    _isConnected = false;
  }

  void toggleAutoRefresh(DashboardType type, bool enabled) {
    _autoRefreshEnabled[type] = enabled;
  }

  bool isAutoRefreshEnabled(DashboardType type) {
    return _autoRefreshEnabled[type] ?? true;
  }

  Future<void> joinPresence(
    DashboardType type,
    String userId,
    String username,
  ) async {
    final channel = _channels[type];
    if (channel != null) {
      await channel.track({'user_id': userId, 'username': username});
      _activeViewers[type] = (_activeViewers[type] ?? 0) + 1;
    }
  }

  Future<void> leavePresence(DashboardType type) async {
    final channel = _channels[type];
    if (channel != null) {
      await channel.untrack();
      _activeViewers[type] = ((_activeViewers[type] ?? 1) - 1).clamp(0, 999);
    }
  }

  int getActiveViewers(DashboardType type) {
    return _activeViewers[type] ?? 0;
  }

  Map<String, dynamic> getConnectionStatus() {
    return {
      'connected': _isConnected,
      'last_updated': _lastUpdated?.toIso8601String(),
      'active_channels': _channels.length,
      'total_viewers': _activeViewers.values.fold(0, (a, b) => a + b),
    };
  }
}
