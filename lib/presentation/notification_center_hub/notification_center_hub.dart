import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/notification_category_filter_widget.dart';
import './widgets/unified_notification_card_widget.dart';

class NotificationCenterHub extends StatefulWidget {
  const NotificationCenterHub({super.key});

  @override
  State<NotificationCenterHub> createState() => _NotificationCenterHubState();
}

class _NotificationCenterHubState extends State<NotificationCenterHub> {
  final SupabaseClient _supabase = Supabase.instance.client;
  StreamSubscription? _notificationSubscription;
  List<Map<String, dynamic>> _notifications = [];
  Set<String> _activeFilters = {
    'votes',
    'messages',
    'achievements',
    'elections',
    'campaigns',
  };
  bool _isLoading = true;
  int _unreadCount = 0;
  bool _isSelectionMode = false;
  Set<String> _selectedNotifications = {};

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
          .from('unified_notifications')
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
      setState(() => _isLoading = false);
    }
  }

  void _setupRealTimeNotifications() {
    _notificationSubscription = _supabase
        .from('unified_notifications')
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
          .from('unified_notifications')
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
          .from('unified_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Mark as read error: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('unified_notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Delete notification error: $e');
    }
  }

  Future<void> _bulkMarkAsRead() async {
    if (_selectedNotifications.isEmpty) return;

    try {
      for (final id in _selectedNotifications) {
        await _supabase
            .from('unified_notifications')
            .update({'is_read': true})
            .eq('id', id);
      }

      setState(() {
        _selectedNotifications.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Selected notifications marked as read'),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      }
    } catch (e) {
      debugPrint('Bulk mark as read error: $e');
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedNotifications.isEmpty) return;

    try {
      for (final id in _selectedNotifications) {
        await _supabase.from('unified_notifications').delete().eq('id', id);
      }

      setState(() {
        _selectedNotifications.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Selected notifications deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Bulk delete error: $e');
    }
  }

  Future<void> _clearCategory(String category) async {
    try {
      await _supabase
          .from('unified_notifications')
          .delete()
          .eq('notification_type', category);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All $category notifications cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Clear category error: $e');
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNotifications.clear();
      }
    });
  }

  void _toggleNotificationSelection(String notificationId) {
    setState(() {
      if (_selectedNotifications.contains(notificationId)) {
        _selectedNotifications.remove(notificationId);
      } else {
        _selectedNotifications.add(notificationId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedNotifications = _filteredNotifications
          .map((n) => n['id'] as String)
          .toSet();
    });
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
      screenName: 'NotificationCenterHub',
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
          title: _isSelectionMode
              ? '${_selectedNotifications.length} selected'
              : 'Notifications',
          actions: [
            if (_isSelectionMode) ...[
              IconButton(
                icon: Icon(Icons.select_all, size: 6.w),
                onPressed: _selectAll,
                tooltip: 'Select all',
              ),
              IconButton(
                icon: Icon(Icons.done_all, size: 6.w),
                onPressed: _bulkMarkAsRead,
                tooltip: 'Mark as read',
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 6.w, color: Colors.red),
                onPressed: _bulkDelete,
                tooltip: 'Delete',
              ),
            ] else ...[
              if (_unreadCount > 0)
                IconButton(
                  icon: Icon(Icons.done_all, size: 6.w),
                  onPressed: _markAllAsRead,
                  tooltip: 'Mark all as read',
                ),
              IconButton(
                icon: Icon(Icons.checklist, size: 6.w),
                onPressed: _toggleSelectionMode,
                tooltip: 'Select',
              ),
              IconButton(
                icon: Icon(Icons.settings, size: 6.w),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.pushNotificationManagementCenter,
                  );
                },
              ),
            ],
          ],
        ),
        body: Column(
          children: [
            // Unread Badge
            if (_unreadCount > 0 && !_isSelectionMode)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 4.w),
                color: AppTheme.accentLight.withAlpha(26),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      size: 5.w,
                      color: AppTheme.accentLight,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentLight,
                      ),
                    ),
                  ],
                ),
              ),

            // Category Filter
            NotificationCategoryFilterWidget(
              activeFilters: _activeFilters,
              onFilterChanged: (filters) {
                setState(() => _activeFilters = filters);
              },
              onClearCategory: _clearCategory,
            ),

            // Notifications List
            Expanded(
              child: _isLoading
                  ? const SkeletonList(itemCount: 10)
                  : _filteredNotifications.isEmpty
                  ? NoDataEmptyState(
                      title: 'No Notifications',
                      description:
                          'You\'re all caught up! Notifications will appear here.',
                      onRefresh: _loadNotifications,
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: EdgeInsets.all(3.w),
                        itemCount: _filteredNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = _filteredNotifications[index];
                          final isSelected = _selectedNotifications.contains(
                            notification['id'],
                          );

                          return UnifiedNotificationCardWidget(
                            notification: notification,
                            isSelectionMode: _isSelectionMode,
                            isSelected: isSelected,
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleNotificationSelection(
                                  notification['id'],
                                );
                              } else {
                                _markAsRead(notification['id']);
                              }
                            },
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                _toggleSelectionMode();
                                _toggleNotificationSelection(
                                  notification['id'],
                                );
                              }
                            },
                            onDismiss: () =>
                                _deleteNotification(notification['id']),
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
}
