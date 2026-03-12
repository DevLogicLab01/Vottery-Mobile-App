import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NetworkQuality { wifi, cellular, offline }

class SubscriptionConfig {
  final String table;
  final String? filter;
  final void Function(PostgresChangePayload) callback;

  const SubscriptionConfig({
    required this.table,
    required this.callback,
    this.filter,
  });
}

class GlobalSubscriptionManager {
  static GlobalSubscriptionManager? _instance;
  static GlobalSubscriptionManager get instance =>
      _instance ??= GlobalSubscriptionManager._();

  GlobalSubscriptionManager._() {
    _initNetworkMonitoring();
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, RealtimeChannel> _activeChannels = {};
  final Map<String, Timer> _pollingTimers = {};
  NetworkQuality _networkQuality = NetworkQuality.wifi;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Batching
  final List<SubscriptionConfig> _pendingSubscriptions = [];
  Timer? _batchTimer;

  NetworkQuality get networkQuality => _networkQuality;

  void _initNetworkMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      final previous = _networkQuality;
      if (result == ConnectivityResult.wifi) {
        _networkQuality = NetworkQuality.wifi;
      } else if (result == ConnectivityResult.mobile) {
        _networkQuality = NetworkQuality.cellular;
      } else {
        _networkQuality = NetworkQuality.offline;
      }

      if (previous != _networkQuality) {
        _onNetworkQualityChanged();
      }
    });
  }

  void _onNetworkQualityChanged() {
    if (_networkQuality == NetworkQuality.cellular) {
      // Switch to polling on cellular
      _convertToPolling();
    } else if (_networkQuality == NetworkQuality.wifi) {
      // Switch back to real-time on WiFi
      _convertToRealtime();
    }
  }

  void _convertToPolling() {
    // Cancel real-time channels and use polling
    for (final entry in _activeChannels.entries) {
      _supabase.removeChannel(entry.value);
    }
    _activeChannels.clear();
  }

  void _convertToRealtime() {
    // Cancel polling timers
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
  }

  /// Add subscription to batch queue (batched within 200ms window)
  void addSubscription(SubscriptionConfig config) {
    _pendingSubscriptions.add(config);
    _batchTimer?.cancel();
    _batchTimer = Timer(const Duration(milliseconds: 200), _flushBatch);
  }

  void _flushBatch() {
    if (_pendingSubscriptions.isEmpty) return;

    if (_networkQuality == NetworkQuality.cellular) {
      // Use polling on cellular
      for (final config in _pendingSubscriptions) {
        _setupPolling(config);
      }
    } else if (_networkQuality != NetworkQuality.offline) {
      // Batch into unified channel
      _createBatchedChannel(List.from(_pendingSubscriptions));
    }

    _pendingSubscriptions.clear();
  }

  void _createBatchedChannel(List<SubscriptionConfig> configs) {
    final channelName = 'mobile_batch_${DateTime.now().millisecondsSinceEpoch}';

    // Prevent duplicate channels for same tables
    final tables = configs.map((c) => c.table).toSet();
    final existingKey = _activeChannels.keys.firstWhere(
      (k) => k.contains('mobile_batch'),
      orElse: () => '',
    );

    if (existingKey.isNotEmpty) {
      _supabase.removeChannel(_activeChannels[existingKey]!);
      _activeChannels.remove(existingKey);
    }

    var channel = _supabase.channel(channelName);

    for (final config in configs) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: config.table,
        callback: config.callback,
      );
    }

    channel.subscribe();
    _activeChannels[channelName] = channel;
  }

  void _setupPolling(
    SubscriptionConfig config, {
    Duration interval = const Duration(seconds: 5),
  }) {
    final key = '${config.table}_polling';
    _pollingTimers[key]?.cancel();
    _pollingTimers[key] = Timer.periodic(interval, (_) {
      // Polling callback - just notify that data may have changed
      config.callback(
        PostgresChangePayload(
          schema: 'public',
          table: config.table,
          commitTimestamp: DateTime.now(),
          eventType: PostgresChangeEvent.update,
          newRecord: {},
          oldRecord: {},
          errors: null,
        ),
      );
    });
  }

  /// Subscribe to a specific channel with deduplication
  RealtimeChannel subscribeToChannel({
    required String channelName,
    required String table,
    required void Function(PostgresChangePayload) callback,
    String? filter,
  }) {
    // Remove existing channel if duplicate
    if (_activeChannels.containsKey(channelName)) {
      _supabase.removeChannel(_activeChannels[channelName]!);
    }

    final channel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: callback,
        )
        .subscribe();

    _activeChannels[channelName] = channel;
    return channel;
  }

  /// Dispose a specific subscription
  void disposeSubscription(String channelName) {
    if (_activeChannels.containsKey(channelName)) {
      _supabase.removeChannel(_activeChannels[channelName]!);
      _activeChannels.remove(channelName);
    }
    _pollingTimers[channelName]?.cancel();
    _pollingTimers.remove(channelName);
  }

  /// Dispose all subscriptions (call on app lifecycle pause)
  void disposeAll() {
    for (final channel in _activeChannels.values) {
      _supabase.removeChannel(channel);
    }
    _activeChannels.clear();
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
    _batchTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  int get activeSubscriptionCount => _activeChannels.length;
}