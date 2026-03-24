import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../config/batch1_route_allowlist.dart';
import '../../routes/app_routes.dart';
import '../../services/unified_alert_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/alert_preferences_widget.dart';
import './widgets/alert_search_widget.dart';
import './widgets/unified_alert_card_widget.dart';

/// Unified Alert Management Center
/// Consolidates all notification types with comprehensive filtering,
/// bulk operations, and real-time updates
class UnifiedAlertManagementCenter extends StatefulWidget {
  const UnifiedAlertManagementCenter({super.key});

  @override
  State<UnifiedAlertManagementCenter> createState() =>
      _UnifiedAlertManagementCenterState();
}

class _UnifiedAlertManagementCenterState
    extends State<UnifiedAlertManagementCenter>
    with SingleTickerProviderStateMixin {
  final UnifiedAlertService _alertService = UnifiedAlertService.instance;
  late TabController _tabController;
  StreamSubscription? _notificationSubscription;

  List<Map<String, dynamic>> _notifications = [];
  Map<String, int> _unreadCounts = {};
  Set<String> _activeFilters = {
    'votes',
    'messages',
    'achievements',
    'elections',
    'campaigns',
    'security',
    'payments',
    'system',
  };
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedNotifications = {};
  String _searchQuery = '';
  DateTime? _searchStartDate;
  DateTime? _searchEndDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
    _loadUnreadCounts();
    _setupRealTimeUpdates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _alertService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load notifications error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final counts = await _alertService.getUnreadCountByCategory();
      setState(() => _unreadCounts = counts);
    } catch (e) {
      debugPrint('Load unread counts error: $e');
    }
  }

  void _setupRealTimeUpdates() {
    _notificationSubscription = _alertService.subscribeToNotifications((data) {
      setState(() => _notifications = data);
      _loadUnreadCounts();
    });
  }

  List<Map<String, dynamic>> get _filteredNotifications {
    return _notifications.where((n) {
      final type = n['notification_type'] as String?;
      return _activeFilters.contains(type);
    }).toList();
  }

  int get _totalUnreadCount {
    return _unreadCounts.values.fold(0, (sum, count) => sum + count);
  }

  void _onFilterChanged(Set<String> filters) {
    setState(() => _activeFilters = filters);
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

  void _selectByCategory(String category) {
    setState(() {
      _selectedNotifications = _notifications
          .where((n) => n['notification_type'] == category)
          .map((n) => n['id'] as String)
          .toSet();
    });
  }

  Future<void> _bulkMarkAsRead() async {
    if (_selectedNotifications.isEmpty) return;

    await _alertService.bulkMarkAsRead(_selectedNotifications.toList());
    setState(() {
      _selectedNotifications.clear();
      _isSelectionMode = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedNotifications.length} alerts marked as read',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedNotifications.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alerts'),
        content: Text(
          'Delete ${_selectedNotifications.length} selected alerts?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _alertService.bulkDeleteNotifications(
        _selectedNotifications.toList(),
      );
      setState(() {
        _selectedNotifications.clear();
        _isSelectionMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alerts deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    await _alertService.markAllAsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All alerts marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleDismiss(String notificationId) async {
    final notification = _notifications.firstWhere(
      (n) => n['id'] == notificationId,
    );
    await _alertService.deleteNotification(notificationId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alert dismissed'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Undo functionality would restore the notification
              debugPrint('Undo dismiss: $notificationId');
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleAlertTap(Map<String, dynamic> notification) async {
    if (_isSelectionMode) {
      _toggleNotificationSelection(notification['id']);
      return;
    }

    // Mark as read
    if (notification['is_read'] == false) {
      await _alertService.markAsRead(notification['id']);
    }

    // Deep link navigation based on notification type
    final type = notification['notification_type'] as String?;
    final metadata = notification['metadata'] as Map<String, dynamic>?;

    if (metadata != null && mounted) {
      switch (type) {
        case 'votes':
          if (metadata['election_id'] != null) {
            _navigateIfAllowed(
              context,
              route: AppRoutes.voteResults,
              arguments: metadata['election_id'],
            );
          }
          break;
        case 'messages':
          _navigateIfAllowed(context, route: AppRoutes.directMessagingScreen);
          break;
        case 'achievements':
          _navigateIfAllowed(context, route: AppRoutes.gamificationHub);
          break;
        case 'elections':
          _navigateIfAllowed(context, route: AppRoutes.voteDiscovery);
          break;
        case 'campaigns':
          _navigateIfAllowed(context, route: AppRoutes.campaignTemplateGallery);
          break;
        case 'security':
          _navigateIfAllowed(context, route: AppRoutes.userSecurityCenter);
          break;
        case 'payments':
          _navigateIfAllowed(
            context,
            route: AppRoutes.walletPrizeDistributionCenter,
          );
          break;
        default:
          break;
      }
    }
  }

  void _navigateIfAllowed(
    BuildContext context, {
    required String route,
    Object? arguments,
  }) {
    if (!Batch1RouteAllowlist.isAllowed(route)) return;
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  void _showPreferences() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AlertPreferencesWidget(),
    );
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AlertSearchWidget(
        onSearch: (query, startDate, endDate) async {
          setState(() {
            _searchQuery = query;
            _searchStartDate = startDate;
            _searchEndDate = endDate;
          });

          final results = await _alertService.searchAlertHistory(
            searchQuery: query,
            startDate: startDate,
            endDate: endDate,
            categories: _activeFilters.toList(),
          );

          setState(() => _notifications = results);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'UnifiedAlertManagementCenter',
      onRetry: _loadNotifications,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: _isSelectionMode
              ? '${_selectedNotifications.length} selected'
              : 'Alerts',
          variant: CustomAppBarVariant.withBack,
          actions: [
            if (_isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: _selectAll,
                tooltip: 'Select All',
              ),
              IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: _bulkMarkAsRead,
                tooltip: 'Mark as Read',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _bulkDelete,
                tooltip: 'Delete',
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
                tooltip: 'Cancel',
              ),
            ] else ...[
              if (_totalUnreadCount > 0)
                IconButton(
                  icon: const Icon(Icons.done_all),
                  onPressed: _markAllAsRead,
                  tooltip: 'Mark All Read',
                ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _showSearch,
                tooltip: 'Search',
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showPreferences,
                tooltip: 'Preferences',
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 8)
            : _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    SizedBox(height: 2.h),
                    Text('No Alerts', style: theme.textTheme.titleLarge),
                    SizedBox(height: 1.h),
                    Text(
                      'System alerts and notifications will appear here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 3.h),
                    TextButton.icon(
                      onPressed: _loadNotifications,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = _filteredNotifications[index];
                    final notificationId = notification['id'] as String;

                    return UnifiedAlertCardWidget(
                      notification: notification,
                      isSelectionMode: _isSelectionMode,
                      isSelected: _selectedNotifications.contains(
                        notificationId,
                      ),
                      onTap: () => _handleAlertTap(notification),
                      onLongPress: _toggleSelectionMode,
                      onDismiss: () => _handleDismiss(notificationId),
                    );
                  },
                ),
              ),
      ),
    );
  }
}