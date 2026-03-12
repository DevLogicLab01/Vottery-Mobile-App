import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import './widgets/channel_configuration_widget.dart';
import './widgets/delivery_scheduling_widget.dart';
import './widgets/notification_card_widget.dart';
import './widgets/notification_status_overview_widget.dart';
import './widgets/real_time_analytics_widget.dart';
import './widgets/user_preferences_widget.dart';

class PushNotificationManagementCenter extends StatefulWidget {
  const PushNotificationManagementCenter({super.key});

  @override
  State<PushNotificationManagementCenter> createState() =>
      _PushNotificationManagementCenterState();
}

class _PushNotificationManagementCenterState
    extends State<PushNotificationManagementCenter>
    with WidgetsBindingObserver {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final NotificationService _notificationService = createNotificationService();

  bool _isLoading = true;
  Map<String, dynamic> _notificationStats = {};
  List<Map<String, dynamic>> _recentNotifications = [];
  List<dynamic> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications();
    _loadNotificationData();
    _setupRealtimeSubscriptions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var subscription in _subscriptions) {
      subscription.unsubscribe();
    }
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();

      // Initialize awesome_notifications channels
      await AwesomeNotifications().initialize(null, [
        NotificationChannel(
          channelKey: 'quest_completions',
          channelName: 'Quest Completions',
          channelDescription:
              'Notifications for completed quests and challenges',
          defaultColor: const Color(0xFF9C27B0),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'security_alerts',
          channelName: 'Security Alerts',
          channelDescription: 'Critical security notifications',
          defaultColor: const Color(0xFFF44336),
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          playSound: true,
          enableVibration: true,
          criticalAlerts: true,
        ),
        NotificationChannel(
          channelKey: 'vp_rewards',
          channelName: 'VP Rewards',
          channelDescription: 'Vottery Points earnings notifications',
          defaultColor: const Color(0xFF4CAF50),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: true,
          enableVibration: true,
        ),
        NotificationChannel(
          channelKey: 'social_interactions',
          channelName: 'Social Interactions',
          channelDescription: 'Likes, comments, and social activity',
          defaultColor: const Color(0xFF2196F3),
          ledColor: Colors.white,
          importance: NotificationImportance.Default,
          playSound: true,
          enableVibration: false,
        ),
      ]);

      // Request notification permissions
      await AwesomeNotifications().requestPermissionToSendNotifications();
    } catch (e) {
      debugPrint('Initialize notifications error: $e');
    }
  }

  Future<void> _loadNotificationData() async {
    try {
      setState(() => _isLoading = true);

      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      // Load notification statistics
      final statsResponse = await _supabaseService.client
          .from('notification_analytics')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Load recent notifications
      final notificationsResponse = await _supabaseService.client
          .from('push_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _notificationStats = statsResponse ?? {};
        _recentNotifications = List<Map<String, dynamic>>.from(
          notificationsResponse ?? [],
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load notification data error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscriptions() {
    final userId = _supabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    // Subscribe to quest completions
    final questSub = _supabaseService.client
        .from('user_feed_quest_progress')
        .stream(primaryKey: ['id'])
        .listen((data) {
          final filteredData = data
              .where(
                (item) =>
                    item['user_id'] == userId && item['status'] == 'completed',
              )
              .toList();
          if (filteredData.isNotEmpty) {
            _sendQuestCompletionNotification(filteredData.last);
          }
        });

    // Subscribe to security alerts
    final securitySub = _supabaseService.client
        .from('security_events')
        .stream(primaryKey: ['id'])
        .listen((data) {
          final filteredData = data
              .where(
                (item) =>
                    item['user_id'] == userId && item['severity'] == 'critical',
              )
              .toList();
          if (filteredData.isNotEmpty) {
            _sendSecurityAlertNotification(filteredData.last);
          }
        });

    // Subscribe to VP rewards
    final vpSub = _supabaseService.client
        .from('vp_transactions')
        .stream(primaryKey: ['id'])
        .listen((data) {
          final filteredData = data
              .where(
                (item) =>
                    item['user_id'] == userId &&
                    (item['amount'] as num? ?? 0) >= 50,
              )
              .toList();
          if (filteredData.isNotEmpty) {
            _sendVPRewardNotification(filteredData.last);
          }
        });

    // Subscribe to social interactions
    final socialSub = _supabaseService.client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .listen((data) {
          final filteredData = data
              .where(
                (item) =>
                    item['user_id'] == userId &&
                    [
                      'like',
                      'comment',
                      'follow',
                      'mention',
                    ].contains(item['type']),
              )
              .toList();
          if (filteredData.isNotEmpty) {
            _sendSocialInteractionNotification(filteredData.last);
          }
        });

    _subscriptions = [questSub, securitySub, vpSub, socialSub];
  }

  Future<void> _sendQuestCompletionNotification(
    Map<String, dynamic> quest,
  ) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'quest_completions',
        title: '🎉 Quest Completed!',
        body:
            'You earned ${quest['vp_reward'] ?? 0} VP for completing "${quest['quest_title'] ?? 'a quest'}"',
        notificationLayout: NotificationLayout.BigText,
        payload: {'quest_id': quest['quest_id']?.toString() ?? ''},
      ),
    );
  }

  Future<void> _sendSecurityAlertNotification(
    Map<String, dynamic> alert,
  ) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'security_alerts',
        title: '🚨 Security Alert',
        body:
            alert['message'] ?? 'Suspicious activity detected on your account',
        notificationLayout: NotificationLayout.BigText,
        criticalAlert: true,
        payload: {'alert_id': alert['id']?.toString() ?? ''},
      ),
    );
  }

  Future<void> _sendVPRewardNotification(
    Map<String, dynamic> transaction,
  ) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'vp_rewards',
        title: '💰 VP Earned!',
        body:
            'You earned ${transaction['amount'] ?? 0} VP from ${transaction['source'] ?? 'activity'}',
        notificationLayout: NotificationLayout.BigText,
        payload: {'transaction_id': transaction['id']?.toString() ?? ''},
      ),
    );
  }

  Future<void> _sendSocialInteractionNotification(
    Map<String, dynamic> notification,
  ) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'social_interactions',
        title: notification['title'] ?? 'New Activity',
        body: notification['message'] ?? 'Someone interacted with your content',
        notificationLayout: NotificationLayout.Default,
        payload: {'notification_id': notification['id']?.toString() ?? ''},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Push Notification Center',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotificationData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotificationData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NotificationStatusOverviewWidget(stats: _notificationStats),
                    SizedBox(height: 3.h),
                    ChannelConfigurationWidget(
                      onChannelUpdated: _loadNotificationData,
                    ),
                    SizedBox(height: 3.h),
                    DeliverySchedulingWidget(
                      onScheduleUpdated: _loadNotificationData,
                      userId: _supabaseService.client.auth.currentUser?.id,
                    ),
                    SizedBox(height: 3.h),
                    UserPreferencesWidget(
                      onPreferencesUpdated: _loadNotificationData,
                    ),
                    SizedBox(height: 3.h),
                    RealTimeAnalyticsWidget(stats: _notificationStats),
                    SizedBox(height: 3.h),
                    Text(
                      'Recent Notifications',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    if (_recentNotifications.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentNotifications.length,
                        itemBuilder: (context, index) {
                          return NotificationCardWidget(
                            notification: _recentNotifications[index],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
