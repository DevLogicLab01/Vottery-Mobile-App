import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import './widgets/gamification_notification_card_widget.dart';

class RealTimeGamificationNotificationCenter extends StatefulWidget {
  const RealTimeGamificationNotificationCenter({super.key});

  @override
  State<RealTimeGamificationNotificationCenter> createState() =>
      _RealTimeGamificationNotificationCenterState();
}

class _RealTimeGamificationNotificationCenterState
    extends State<RealTimeGamificationNotificationCenter> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _notificationSubscription;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadNotifications();
    _setupRealTimeNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: 'gamification_channel',
          channelName: 'Gamification Notifications',
          channelDescription:
              'Achievements, streaks, leaderboard, quests, VP opportunities',
          importance: NotificationImportance.High,
          defaultColor: const Color(0xFF6C63FF),
          ledColor: const Color(0xFF6C63FF),
          playSound: true,
          enableVibration: true,
        ),
      ]);

      await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
        if (!isAllowed) {
          AwesomeNotifications().requestPermissionToSendNotifications();
        }
      });

      // Listen to notification actions
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: _onActionReceived,
      );
    } catch (e) {
      debugPrint('Initialize notifications error: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceived(ReceivedAction receivedAction) async {
    // Handle notification action buttons
    final payload = receivedAction.payload;
    if (payload != null) {
      final action = payload['action'];
      final notificationId = payload['notification_id'];

      debugPrint('Notification action: $action for $notificationId');
      // Navigate or trigger actions based on payload
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('gamification_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _unreadCount = _notifications
            .where((n) => n['is_read'] == false)
            .length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load notifications error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealTimeNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _notificationSubscription = _supabase
        .from('gamification_notifications:user_id=eq.$userId')
        .stream(primaryKey: ['id'])
        .listen((data) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(data);
            _unreadCount = _notifications
                .where((n) => n['is_read'] == false)
                .length;
          });

          // Show push notification for new items
          if (data.isNotEmpty) {
            final latest = data.first;
            if (latest['is_read'] == false) {
              _showPushNotification(latest);
            }
          }
        });
  }

  Future<void> _showPushNotification(Map<String, dynamic> notification) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notification['id'].hashCode,
          channelKey: 'gamification_channel',
          title: notification['title'] ?? 'Gamification Update',
          body: notification['body'] ?? '',
          notificationLayout: NotificationLayout.BigText,
          payload: {
            'notification_id': notification['id'].toString(),
            'type': notification['notification_type'] ?? 'general',
          },
        ),
        actionButtons: _getActionButtons(notification),
      );
    } catch (e) {
      debugPrint('Show push notification error: $e');
    }
  }

  List<NotificationActionButton> _getActionButtons(
    Map<String, dynamic> notification,
  ) {
    final type = notification['notification_type'] as String? ?? 'general';

    switch (type) {
      case 'badge_unlocked':
        return [
          NotificationActionButton(
            key: 'view_badge',
            label: 'View Badge',
            actionType: ActionType.Default,
          ),
        ];
      case 'vp_opportunity':
        return [
          NotificationActionButton(
            key: 'join_now',
            label: 'Join Now',
            actionType: ActionType.Default,
          ),
        ];
      case 'quest_progress':
        return [
          NotificationActionButton(
            key: 'claim_reward',
            label: 'Claim Reward',
            actionType: ActionType.Default,
          ),
        ];
      default:
        return [];
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('gamification_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('gamification_notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      setState(() => _unreadCount = 0);
    } catch (e) {
      debugPrint('Mark all as read error: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('gamification_notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Delete notification error: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    if (_selectedFilter == 'all') return _notifications;
    return _notifications
        .where((n) => n['notification_type'] == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gamification Notifications',
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: Badge(
                label: Text(_unreadCount.toString()),
                child: const Icon(Icons.mark_email_read),
              ),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: ErrorBoundaryWrapper(
        screenName: 'RealTimeGamificationNotificationCenter',
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: Column(
            children: [
              _buildFilterChips(theme),
              Expanded(
                child: _isLoading
                    ? ShimmerSkeletonLoader(child: Container())
                    : _filteredNotifications.isEmpty
                    ? EnhancedEmptyStateWidget(
                        title: 'No notifications',
                        description: 'You\'ll see gamification updates here',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(4.w),
                        itemCount: _filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = _filteredNotifications[index];
                          return GamificationNotificationCardWidget(
                            notification: notification,
                            onTap: () => _markAsRead(notification['id']),
                            onDismiss: () =>
                                _deleteNotification(notification['id']),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': Icons.all_inclusive},
      {'key': 'badge_unlocked', 'label': 'Badges', 'icon': Icons.stars},
      {
        'key': 'streak_maintained',
        'label': 'Streaks',
        'icon': Icons.local_fire_department,
      },
      {
        'key': 'leaderboard_change',
        'label': 'Leaderboard',
        'icon': Icons.leaderboard,
      },
      {'key': 'quest_progress', 'label': 'Quests', 'icon': Icons.flag},
      {
        'key': 'vp_opportunity',
        'label': 'VP Opportunities',
        'icon': Icons.monetization_on,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['key'];
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16.sp,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.primary,
                    ),
                    SizedBox(width: 1.w),
                    Text(filter['label'] as String),
                  ],
                ),
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter['key'] as String);
                },
                backgroundColor: Colors.grey[200],
                selectedColor: theme.colorScheme.primary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
