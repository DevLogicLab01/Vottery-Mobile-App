import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/offline_sync_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/sync_status_header_widget.dart';
import './widgets/conflict_resolution_card_widget.dart';
import './widgets/sync_queue_widget.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/adaptive_strategy_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Enhanced Mobile Offline Sync Hub
/// Comprehensive offline operation management with intelligent conflict
/// resolution and adaptive sync strategies
class EnhancedMobileOfflineSyncHub extends StatefulWidget {
  const EnhancedMobileOfflineSyncHub({super.key});

  @override
  State<EnhancedMobileOfflineSyncHub> createState() =>
      _EnhancedMobileOfflineSyncHubState();
}

class _EnhancedMobileOfflineSyncHubState
    extends State<EnhancedMobileOfflineSyncHub>
    with SingleTickerProviderStateMixin {
  final OfflineSyncService _syncService = OfflineSyncService.instance;
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isOnline = false;

  List<Map<String, dynamic>> _syncQueue = [];
  List<Map<String, dynamic>> _conflicts = [];
  List<Map<String, dynamic>> _performanceMetrics = [];
  DateTime? _lastSyncTime;
  String _networkQuality = 'offline';
  String _syncStrategy = 'manual';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSyncData();
    _listenToConnectivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _listenToConnectivity() {
    _syncService.connectivityStream.listen((online) {
      setState(() => _isOnline = online);
      if (online && !_isSyncing) {
        _syncPendingChanges();
      }
    });
  }

  Future<void> _loadSyncData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _syncService.getSyncQueue(),
        _syncService.getSyncConflicts(),
        _syncService.getSyncPerformanceMetrics(limit: 20),
        _syncService.getLastSyncTime(),
        _syncService.isOnline(),
      ]);

      final networkQuality = await _syncService.getNetworkQuality();
      final syncStrategy = _syncService.getAdaptiveSyncStrategy(networkQuality);

      setState(() {
        _syncQueue = results[0] as List<Map<String, dynamic>>;
        _conflicts = results[1] as List<Map<String, dynamic>>;
        _performanceMetrics = results[2] as List<Map<String, dynamic>>;
        _lastSyncTime = results[3] as DateTime?;
        _isOnline = results[4] as bool;
        _networkQuality = networkQuality;
        _syncStrategy = syncStrategy;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load sync data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncPendingChanges() async {
    setState(() => _isSyncing = true);

    final startTime = DateTime.now();

    try {
      final result = await _syncService.syncPendingVotes();

      final duration = DateTime.now().difference(startTime).inMilliseconds;

      await _syncService.recordSyncMetrics(
        durationMs: duration,
        dataVolumeBytes: 0,
        recordsSynced: result['synced'] ?? 0,
        conflictsDetected: 0,
      );

      await _loadSyncData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${result['synced']} items. ${result['failed']} failed.',
            ),
            backgroundColor: result['failed'] > 0
                ? Colors.orange
                : Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Sync pending changes error: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _clearQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Sync Queue'),
        content: const Text(
          'Are you sure you want to clear all pending sync items? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _syncService.clearSyncQueue();
      if (success) {
        await _loadSyncData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync queue cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedMobileOfflineSyncHub',
      onRetry: _loadSyncData,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Offline Sync Hub',
          variant: CustomAppBarVariant.withBack,
          actions: [
            if (_isSyncing)
              Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: Center(
                  child: SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              )
            else ...[
              IconButton(
                icon: Icon(Icons.sync, size: 6.w),
                onPressed: _isOnline ? _syncPendingChanges : null,
                tooltip: 'Manual Sync',
              ),
              IconButton(
                icon: Icon(Icons.delete_sweep, size: 6.w),
                onPressed: _syncQueue.isNotEmpty ? _clearQueue : null,
                tooltip: 'Clear Queue',
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  SyncStatusHeaderWidget(
                    queueLength: _syncQueue.length,
                    lastSyncTime: _lastSyncTime,
                    isOnline: _isOnline,
                    networkQuality: _networkQuality,
                    syncStrategy: _syncStrategy,
                  ),
                  _buildTabBar(theme),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildQueueTab(),
                        _buildConflictsTab(),
                        _buildPerformanceTab(),
                        _buildStrategyTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(153),
        indicatorColor: theme.colorScheme.primary,
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13.sp),
        tabs: [
          Tab(text: 'Queue (${_syncQueue.length})'),
          Tab(text: 'Conflicts (${_conflicts.length})'),
          const Tab(text: 'Performance'),
          const Tab(text: 'Strategy'),
        ],
      ),
    );
  }

  Widget _buildQueueTab() {
    return SyncQueueWidget(syncQueue: _syncQueue, onRefresh: _loadSyncData);
  }

  Widget _buildConflictsTab() {
    if (_conflicts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 15.w,
              color: Colors.green.withAlpha(77),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Sync Conflicts',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _conflicts.length,
      itemBuilder: (context, index) {
        return ConflictResolutionCardWidget(
          conflict: _conflicts[index],
          onResolved: _loadSyncData,
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    return PerformanceMetricsWidget(metrics: _performanceMetrics);
  }

  Widget _buildStrategyTab() {
    return AdaptiveStrategyWidget(
      networkQuality: _networkQuality,
      syncStrategy: _syncStrategy,
      isOnline: _isOnline,
    );
  }
}
