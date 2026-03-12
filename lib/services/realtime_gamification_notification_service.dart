import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


/// Retry configuration for exponential backoff
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    this.maxRetries = 5,
    this.initialDelay = const Duration(seconds: 2),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });
}

/// Pending notification for offline queue
class PendingNotification {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  PendingNotification({
    required this.type,
    required this.data,
    required this.timestamp,
  });
}

/// Offline notification queue
class OfflineNotificationQueue {
  final List<PendingNotification> _queue = [];

  List<PendingNotification> get pending => List.unmodifiable(_queue);
  int get length => _queue.length;

  Future<void> enqueue(PendingNotification notification) async {
    _queue.add(notification);
    debugPrint('📦 Queued offline notification: ${notification.type}');
  }

  Future<List<PendingNotification>> flushAll() async {
    final flushed = List<PendingNotification>.from(_queue);
    _queue.clear();
    return flushed;
  }

  void clear() => _queue.clear();
}

/// Connection state enum
enum ConnectionState { connected, disconnected, reconnecting }

/// Real-time Gamification Notification Service
/// Subscribes to Supabase real-time channels for gamification events
/// and shows in-app toast/snackbar alerts with retry logic and offline queueing.
class RealtimeGamificationNotificationService {
  static final RealtimeGamificationNotificationService _instance =
      RealtimeGamificationNotificationService._internal();
  static RealtimeGamificationNotificationService get instance => _instance;
  RealtimeGamificationNotificationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final List<RealtimeChannel> _channels = [];
  BuildContext? _context;
  String? _userId;

  // Retry configuration
  final RetryConfig _retryConfig = const RetryConfig();

  // Offline queue
  final OfflineNotificationQueue _offlineQueue = OfflineNotificationQueue();

  // Connection state
  ConnectionState _connectionState = ConnectionState.disconnected;
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  ConnectionState get connectionState => _connectionState;
  OfflineNotificationQueue get offlineQueue => _offlineQueue;

  void _updateConnectionState(ConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  /// Initialize and set up all subscriptions
  Future<void> initialize({BuildContext? context}) async {
    _context = context;
    _userId = _supabase.auth.currentUser?.id;
    if (_userId == null) return;

    _updateConnectionState(ConnectionState.reconnecting);
    await _subscribeToVPTransactions();
    await _subscribeToQuests();
    await _subscribeToAchievements();
    await _subscribeToStreaks();
    await _subscribeToLeaderboards();
    _updateConnectionState(ConnectionState.connected);

    // Flush any pending offline notifications
    await _flushOfflineQueue();
  }

  /// Update context (call from widget tree when context is available)
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Retry a subscription with exponential backoff
  Future<void> _retrySubscription(
    Future<void> Function() subscriptionFn,
    int maxAttempts,
  ) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await subscriptionFn();
        return; // success
      } catch (e) {
        if (attempt < maxAttempts) {
          final rawDelay =
              _retryConfig.initialDelay.inMilliseconds *
              pow(_retryConfig.backoffMultiplier, attempt - 1);
          final clampedMs = rawDelay.clamp(
            0,
            _retryConfig.maxDelay.inMilliseconds.toDouble(),
          );
          final delay = Duration(milliseconds: clampedMs.toInt());
          debugPrint(
            '⚠️ Subscription attempt $attempt failed, retrying in ${delay.inSeconds}s: $e',
          );
          await Future.delayed(delay);
        } else {
          debugPrint('❌ Final subscription attempt $attempt failed: $e');
          rethrow;
        }
      }
    }
  }

  /// Reconnect all subscriptions
  Future<void> reconnectAllSubscriptions() async {
    debugPrint('🔄 Reconnecting all gamification subscriptions...');
    _updateConnectionState(ConnectionState.reconnecting);

    // Cancel all existing subscriptions
    for (final channel in _channels) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        debugPrint('Error unsubscribing channel: $e');
      }
    }
    _channels.clear();

    // Wait for cleanup
    await Future.delayed(const Duration(seconds: 2));

    // Reinitialize subscriptions
    try {
      await _subscribeToVPTransactions();
      await _subscribeToQuests();
      await _subscribeToAchievements();
      await _subscribeToStreaks();
      await _subscribeToLeaderboards();
      _updateConnectionState(ConnectionState.connected);
      debugPrint('✅ All subscriptions reconnected successfully');

      // Flush offline queue on reconnect
      await _flushOfflineQueue();
    } catch (e) {
      _updateConnectionState(ConnectionState.disconnected);
      debugPrint('❌ Reconnection failed: $e');
    }
  }

  /// Flush offline notification queue
  Future<void> _flushOfflineQueue() async {
    if (_offlineQueue.length == 0) return;
    final pending = await _offlineQueue.flushAll();
    debugPrint('📤 Flushing ${pending.length} offline notifications');
    for (final notification in pending) {
      _deliverQueuedNotification(notification);
    }
  }

  void _deliverQueuedNotification(PendingNotification notification) {
    switch (notification.type) {
      case 'vp_earned':
        _showVPEarnedNotification(
          notification.data['amount'] as int? ?? 0,
          notification.data['source'] as String? ?? 'activity',
        );
        break;
      case 'quest_completed':
        _showQuestCompletedNotification(
          notification.data['quest_name'] as String? ?? 'Quest',
        );
        break;
      case 'achievement_unlocked':
        _showAchievementUnlockedNotification(
          notification.data['badge_name'] as String? ?? 'Achievement',
          notification.data['badge_icon'] as String? ?? '🏆',
        );
        break;
    }
  }

  // ─── Subscription 1: VP Transactions ────────────────────────────────────────
  Future<void> _subscribeToVPTransactions() async {
    try {
      await _retrySubscription(() async {
        final channel = _supabase
            .channel('vp_transactions_$_userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'user_vp_transactions',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: _userId!,
              ),
              callback: (payload) {
                final amount = payload.newRecord['amount'];
                final source =
                    payload.newRecord['source'] as String? ?? 'activity';
                try {
                  _showVPEarnedNotification(
                    amount is int ? amount : (amount as num?)?.toInt() ?? 0,
                    source,
                  );
                } catch (e) {
                  _offlineQueue.enqueue(
                    PendingNotification(
                      type: 'vp_earned',
                      data: {'amount': amount, 'source': source},
                      timestamp: DateTime.now(),
                    ),
                  );
                }
              },
            )
            .subscribe();
        _channels.add(channel);
      }, _retryConfig.maxRetries);
    } catch (e) {
      debugPrint('VP transactions subscription failed after all retries: $e');
    }
  }

  // ─── Subscription 2: Quests ──────────────────────────────────────────────────
  Future<void> _subscribeToQuests() async {
    try {
      await _retrySubscription(() async {
        final channel = _supabase
            .channel('user_quests_$_userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'user_quests',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: _userId!,
              ),
              callback: (payload) {
                final completed =
                    payload.newRecord['completed'] as bool? ?? false;
                final questName =
                    payload.newRecord['quest_name'] as String? ?? 'Quest';
                if (completed) {
                  try {
                    _showQuestCompletedNotification(questName);
                  } catch (e) {
                    _offlineQueue.enqueue(
                      PendingNotification(
                        type: 'quest_completed',
                        data: {'quest_name': questName},
                        timestamp: DateTime.now(),
                      ),
                    );
                  }
                }
              },
            )
            .subscribe();
        _channels.add(channel);
      }, _retryConfig.maxRetries);
    } catch (e) {
      debugPrint('Quests subscription failed after all retries: $e');
    }
  }

  // ─── Subscription 3: Achievements ───────────────────────────────────────────
  Future<void> _subscribeToAchievements() async {
    try {
      await _retrySubscription(() async {
        final channel = _supabase
            .channel('user_achievements_$_userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'user_achievements',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: _userId!,
              ),
              callback: (payload) {
                final badgeName =
                    payload.newRecord['badge_name'] as String? ?? 'Achievement';
                final badgeIcon =
                    payload.newRecord['badge_icon'] as String? ?? '🏆';
                try {
                  _showAchievementUnlockedNotification(badgeName, badgeIcon);
                } catch (e) {
                  _offlineQueue.enqueue(
                    PendingNotification(
                      type: 'achievement_unlocked',
                      data: {'badge_name': badgeName, 'badge_icon': badgeIcon},
                      timestamp: DateTime.now(),
                    ),
                  );
                }
              },
            )
            .subscribe();
        _channels.add(channel);
      }, _retryConfig.maxRetries);
    } catch (e) {
      debugPrint('Achievements subscription failed after all retries: $e');
    }
  }

  // ─── Subscription 4: Streaks ─────────────────────────────────────────────────
  Future<void> _subscribeToStreaks() async {
    try {
      await _retrySubscription(() async {
        final channel = _supabase
            .channel('user_streaks_$_userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'user_streaks',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: _userId!,
              ),
              callback: (payload) {
                final currentStreak =
                    (payload.newRecord['current_streak'] as num?)?.toInt() ?? 0;
                final oldStreak =
                    (payload.oldRecord['current_streak'] as num?)?.toInt() ?? 0;
                if (currentStreak > oldStreak) {
                  _showStreakMaintainedNotification(currentStreak);
                } else if (currentStreak == 0 && oldStreak > 0) {
                  _showStreakBrokenNotification();
                }
              },
            )
            .subscribe();
        _channels.add(channel);
      }, _retryConfig.maxRetries);
    } catch (e) {
      debugPrint('Streaks subscription failed after all retries: $e');
    }
  }

  // ─── Subscription 5: Leaderboards ───────────────────────────────────────────
  Future<void> _subscribeToLeaderboards() async {
    try {
      await _retrySubscription(() async {
        final channel = _supabase
            .channel('leaderboard_positions_$_userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'leaderboard_positions',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: _userId!,
              ),
              callback: (payload) {
                final newRank =
                    (payload.newRecord['rank'] as num?)?.toInt() ?? 0;
                final oldRank =
                    (payload.oldRecord['rank'] as num?)?.toInt() ?? 0;
                final leaderboardName =
                    payload.newRecord['leaderboard_name'] as String? ??
                    'Leaderboard';
                if (newRank > 0 && newRank < oldRank) {
                  _showRankUpNotification(newRank, leaderboardName);
                }
              },
            )
            .subscribe();
        _channels.add(channel);
      }, _retryConfig.maxRetries);
    } catch (e) {
      debugPrint('Leaderboards subscription failed after all retries: $e');
    }
  }

  // ─── Notification Methods ────────────────────────────────────────────────────

  void _showVPEarnedNotification(int amount, String source) {
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return;
    try {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '+$amount VP earned!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'from $source',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } catch (e) {
      _offlineQueue.enqueue(
        PendingNotification(
          type: 'vp_earned',
          data: {'amount': amount, 'source': source},
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _showQuestCompletedNotification(String questName) {
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return;
    try {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '✅ Quest completed: $questName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue[700],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } catch (e) {
      _offlineQueue.enqueue(
        PendingNotification(
          type: 'quest_completed',
          data: {'quest_name': questName},
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _showAchievementUnlockedNotification(String name, String icon) {
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return;
    try {
      showDialog(
        context: ctx,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              const Text('Achievement Unlocked!'),
            ],
          ),
          content: Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Awesome!'),
            ),
          ],
        ),
      );
    } catch (e) {
      _offlineQueue.enqueue(
        PendingNotification(
          type: 'achievement_unlocked',
          data: {'badge_name': name, 'badge_icon': icon},
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void _showStreakMaintainedNotification(int streak) {
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return;
    try {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '$streak day streak maintained!',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing streak notification: $e');
    }
  }

  void _showStreakBrokenNotification() {
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return;
    try {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Text('💔', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Streak broken. Start a new one today!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing streak broken notification: $e');
    }
  }

  void _showRankUpNotification(int rank, String leaderboard) {
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return;
    try {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🏆 Rank #$rank on $leaderboard!',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.purple[700],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error showing rank notification: $e');
    }
  }

  /// Dispose all subscriptions
  Future<void> dispose() async {
    for (final channel in _channels) {
      try {
        await channel.unsubscribe();
      } catch (e) {
        debugPrint('Error unsubscribing: $e');
      }
    }
    _channels.clear();
    _connectionStateController.close();
  }
}
