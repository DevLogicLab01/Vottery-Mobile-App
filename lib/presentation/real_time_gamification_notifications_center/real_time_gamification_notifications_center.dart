import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/ga4_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/gamification_notification_card_widget.dart';
import './widgets/notification_preferences_panel_widget.dart';

/// Real-time Gamification Notifications Center
/// Comprehensive notification system using awesome_notifications for push notifications
/// with in-app notification center featuring badge counter and priority-based categorization
class RealTimeGamificationNotificationsCenter extends StatefulWidget {
  const RealTimeGamificationNotificationsCenter({super.key});

  @override
  State<RealTimeGamificationNotificationsCenter> createState() =>
      _RealTimeGamificationNotificationsCenterState();
}

class _RealTimeGamificationNotificationsCenterState
    extends State<RealTimeGamificationNotificationsCenter> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _notificationSubscription;
  List<Map<String, dynamic>> _notifications = [];
  final Set<String> _activeFilters = {
    'achievement',
    'streak',
    'leaderboard',
    'quest',
    'vp_opportunity',
  };
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealTimeNotifications();
    _trackScreenView();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _trackScreenView() async {
    await GA4AnalyticsService.instance.trackScreenView(
      screenName: 'real_time_gamification_notifications',
    );
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('gamification_notifications')
          .select()
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
    _notificationSubscription = _supabase
        .from('gamification_notifications')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (mounted) {
            setState(() {
              _notifications = List<Map<String, dynamic>>.from(data);
              _unreadCount = _notifications
                  .where((n) => n['is_read'] == false)
                  .length;
            });
          }
        });
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabase
          .from('gamification_notifications')
          .update({'is_read': true})
          .eq('is_read', false);

      setState(() => _unreadCount = 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications marked as read'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }
    } catch (e) {
      debugPrint('Mark all as read error: $e');
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

  void _handleNotificationAction(String action, Map<String, dynamic> data) {
    switch (action) {
      case 'view_badge':
        Navigator.pushNamed(context, AppRoutes.gamificationHub);
        break;
      case 'claim_reward':
        _claimReward(data);
        break;
      case 'join_prediction':
        Navigator.pushNamed(context, AppRoutes.socialHomeFeed);
        break;
      case 'view_leaderboard':
        Navigator.pushNamed(context, AppRoutes.gamificationHub);
        break;
      case 'view_quest':
        Navigator.pushNamed(context, AppRoutes.feedQuestDashboard);
        break;
      default:
        debugPrint('Unknown action: $action');
    }
  }

  Future<void> _claimReward(Map<String, dynamic> data) async {
    // Trigger VP credit with animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars, color: AppTheme.vibrantYellow, size: 15.w),
            SizedBox(height: 2.h),
            Text(
              'Reward Claimed!',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              '+${data['vp_amount'] ?? 0} VP',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.vibrantYellow,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Track analytics
    await GA4AnalyticsService.instance.trackVPEarned(
      source: 'claim_reward',
      amount: data['vp_amount'] ?? 0,
      transactionType: 'claim_reward',
    );
  }

  void _showPreferences() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationPreferencesPanelWidget(
        onSave: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification preferences saved'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    return _notifications.where((n) {
      final type = n['notification_type'] as String?;
      return _activeFilters.contains(type);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'RealTimeGamificationNotificationsCenter',
      onRetry: _loadNotifications,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Notifications',
          actions: [
            if (_unreadCount > 0)
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'done_all',
                  size: 6.w,
                  color: AppTheme.textPrimaryLight,
                ),
                onPressed: _markAllAsRead,
                tooltip: 'Mark all as read',
              ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'settings',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _showPreferences,
              tooltip: 'Notification preferences',
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 10)
            : _notifications.isEmpty
            ? NoDataEmptyState(
                title: 'No Notifications',
                description:
                    'Gamification notifications will appear here when you earn achievements, maintain streaks, or climb leaderboards.',
                onRefresh: _loadNotifications,
              )
            : Column(
                children: [
                  // Filter chips
                  _buildFilterChips(),
                  // Notifications list
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: EdgeInsets.all(3.w),
                        itemCount: _filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = _filteredNotifications[index];
                          return GamificationNotificationCardWidget(
                            notification: notification,
                            onTap: () {
                              _markAsRead(notification['id']);
                              if (notification['action'] != null) {
                                _handleNotificationAction(
                                  notification['action'],
                                  notification,
                                );
                              }
                            },
                            onDismiss: () =>
                                _deleteNotification(notification['id']),
                            onAction: (action) =>
                                _handleNotificationAction(action, notification),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {
        'key': 'achievement',
        'label': 'Achievements',
        'icon': Icons.emoji_events,
      },
      {
        'key': 'streak',
        'label': 'Streaks',
        'icon': Icons.local_fire_department,
      },
      {'key': 'leaderboard', 'label': 'Leaderboard', 'icon': Icons.leaderboard},
      {'key': 'quest', 'label': 'Quests', 'icon': Icons.flag},
      {
        'key': 'vp_opportunity',
        'label': 'VP Opportunities',
        'icon': Icons.stars,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isActive = _activeFilters.contains(filter['key']);
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 4.w,
                      color: isActive
                          ? Colors.white
                          : AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      filter['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                selected: isActive,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _activeFilters.add(filter['key'] as String);
                    } else {
                      _activeFilters.remove(filter['key']);
                    }
                  });
                },
                selectedColor: AppTheme.primaryLight,
                backgroundColor: Colors.grey[200],
                checkmarkColor: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
