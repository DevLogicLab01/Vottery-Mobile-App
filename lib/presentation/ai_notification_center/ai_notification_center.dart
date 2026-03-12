import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import './widgets/notification_card_widget.dart';

class AINotificationCenter extends StatefulWidget {
  const AINotificationCenter({super.key});

  @override
  State<AINotificationCenter> createState() => _AINotificationCenterState();
}

class _AINotificationCenterState extends State<AINotificationCenter> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _notificationSubscription;
  List<Map<String, dynamic>> _notifications = [];
  final Set<String> _activeFilters = {'security', 'recommendations', 'quests'};
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealTimeNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('ai_notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response);
        _unreadCount = _notifications
            .where((n) => n['is_read'] == false)
            .length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupRealTimeNotifications() {
    _notificationSubscription = _supabase
        .from('ai_notifications')
        .stream(primaryKey: ['id'])
        .listen((data) {
          setState(() {
            _notifications = List<Map<String, dynamic>>.from(data);
            _unreadCount = _notifications
                .where((n) => n['is_read'] == false)
                .length;
          });
        });
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabase
          .from('ai_notifications')
          .update({'is_read': true})
          .eq('is_read', false);
      setState(() => _unreadCount = 0);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('ai_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('ai_notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      // Handle error
    }
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
      screenName: 'AINotificationCenter',
      onRetry: _loadNotifications,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Row(
            children: [
              const Text('AI Notification Center'),
              if (_unreadCount > 0) ...[
                SizedBox(width: 2.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '$_unreadCount',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (_unreadCount > 0)
              IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: _markAllAsRead,
                tooltip: 'Mark all as read',
              ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // Open notification settings
              },
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 10)
            : _notifications.isEmpty
            ? NoDataEmptyState(
                title: 'No AI Notifications',
                description:
                    'AI-powered notifications and insights will appear here.',
                onRefresh: _loadNotifications,
              )
            : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView.builder(
                  padding: EdgeInsets.all(3.w),
                  itemCount: _filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _filteredNotifications[index];
                    return NotificationCardWidget(
                          notification: notification,
                          onTap: () => _markAsRead(notification['id']),
                          onDismiss: () =>
                              _deleteNotification(notification['id']),
                        )
                        as Widget;
                  },
                ),
              ),
      ),
    );
  }
}
