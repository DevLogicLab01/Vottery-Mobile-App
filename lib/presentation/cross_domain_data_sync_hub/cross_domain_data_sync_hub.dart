import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/offline_sync_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../theme/app_theme.dart';
import './widgets/sync_status_overview_widget.dart';
import './widgets/real_time_dashboard_widget.dart';
import './widgets/conflict_resolution_ui_widget.dart';
import './widgets/offline_queue_monitor_widget.dart';
import './widgets/sync_history_logs_widget.dart';
import './widgets/network_health_widget.dart';

/// Cross-Domain Data Sync Hub
/// Comprehensive real-time synchronization monitoring across all platform
/// content types with unified conflict resolution and queue management
class CrossDomainDataSyncHub extends StatefulWidget {
  const CrossDomainDataSyncHub({super.key});

  @override
  State<CrossDomainDataSyncHub> createState() => _CrossDomainDataSyncHubState();
}

class _CrossDomainDataSyncHubState extends State<CrossDomainDataSyncHub>
    with SingleTickerProviderStateMixin {
  final OfflineSyncService _syncService = OfflineSyncService.instance;
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isOnline = false;

  // Sync status data
  int _activeOperations = 0;
  int _queueLength = 0;
  String _networkHealth = 'excellent';
  final List<Map<String, dynamic>> _syncOperations = [];
  List<Map<String, dynamic>> _conflicts = [];
  List<Map<String, dynamic>> _queueItems = [];
  List<Map<String, dynamic>> _syncHistory = [];
  Map<String, dynamic> _networkMetrics = {};

  // Content type sync status
  Map<String, Map<String, dynamic>> _contentSyncStatus = {
    'elections': {'synced': 0, 'pending': 0, 'errors': 0, 'health': 'good'},
    'posts': {'synced': 0, 'pending': 0, 'errors': 0, 'health': 'good'},
    'ads': {'synced': 0, 'pending': 0, 'errors': 0, 'health': 'good'},
    'users': {'synced': 0, 'pending': 0, 'errors': 0, 'health': 'good'},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        _triggerAutoSync();
      }
    });
  }

  Future<void> _loadSyncData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _syncService.getSyncQueue(),
        _syncService.getSyncConflicts(),
        _syncService.getSyncPerformanceMetrics(limit: 50),
        _syncService.isOnline(),
        _getContentSyncStatus(),
        _getNetworkHealthMetrics(),
      ]);

      final networkQuality = await _syncService.getNetworkQuality();

      setState(() {
        _queueItems = results[0] as List<Map<String, dynamic>>;
        _conflicts = results[1] as List<Map<String, dynamic>>;
        _syncHistory = results[2] as List<Map<String, dynamic>>;
        _isOnline = results[3] as bool;
        _contentSyncStatus = results[4] as Map<String, Map<String, dynamic>>;
        _networkMetrics = results[5] as Map<String, dynamic>;
        _networkHealth = networkQuality;
        _queueLength = _queueItems.length;
        _activeOperations = _queueItems
            .where((item) => item['status'] == 'syncing')
            .length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load sync data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getContentSyncStatus() async {
    try {
      final supabase = SupabaseService.instance.client;

      // Get sync status for each content type
      final electionsStatus = await _getTableSyncStatus('elections');
      final postsStatus = await _getTableSyncStatus('social_posts');
      final adsStatus = await _getTableSyncStatus('sponsored_elections');
      final usersStatus = await _getTableSyncStatus('user_profiles');

      return {
        'elections': electionsStatus,
        'posts': postsStatus,
        'ads': adsStatus,
        'users': usersStatus,
      };
    } catch (e) {
      debugPrint('Get content sync status error: $e');
      return _contentSyncStatus;
    }
  }

  Future<Map<String, dynamic>> _getTableSyncStatus(String tableName) async {
    try {
      // Simulate sync status calculation
      // In production, this would query actual sync metadata
      return {
        'synced': 150,
        'pending': 5,
        'errors': 0,
        'health': 'good',
        'lastSync': DateTime.now().subtract(const Duration(minutes: 2)),
      };
    } catch (e) {
      return {'synced': 0, 'pending': 0, 'errors': 0, 'health': 'unknown'};
    }
  }

  Future<Map<String, dynamic>> _getNetworkHealthMetrics() async {
    try {
      return {
        'latency': 45, // ms
        'bandwidth': 'high',
        'connectionQuality': 'excellent',
        'activeSubscriptions': 4,
        'webSocketStatus': 'connected',
        'dataFlowRate': 1250, // KB/s
      };
    } catch (e) {
      return {};
    }
  }

  Future<void> _triggerAutoSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final result = await _syncService.syncPendingVotes();

      await _loadSyncData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Auto-sync completed: ${result['synced']} items synced',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Auto-sync error: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);

    try {
      final result = await _syncService.syncPendingVotes();

      await _loadSyncData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Manual sync: ${result['synced']} synced, ${result['failed']} failed',
            ),
            backgroundColor: result['failed'] > 0
                ? Colors.orange
                : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _resolveConflict(String conflictId, String strategy) async {
    try {
      // Implement conflict resolution logic
      await _syncService.resolveConflict(
        conflictId: conflictId,
        strategy: strategy,
      );
      await _loadSyncData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conflict resolved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conflict resolution failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Cross-Domain Data Sync Hub',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Cross-Domain Data Sync Hub',
          actions: [
            IconButton(
              icon: Icon(
                _isSyncing ? Icons.sync : Icons.sync_outlined,
                color: _isSyncing ? AppTheme.primaryLight : Colors.white,
              ),
              onPressed: _isSyncing ? null : _manualSync,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadSyncData,
            ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : Column(
                children: [
                  _buildSyncStatusHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRealTimeDashboard(),
                        _buildConflictResolution(),
                        _buildOfflineQueueMonitor(),
                        _buildSyncHistoryLogs(),
                        _buildNetworkHealth(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: ShimmerSkeletonLoader(
          child: Container(
            height: 15.h,
            width: double.infinity,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusHeader() {
    return SyncStatusOverviewWidget(
      activeOperations: _activeOperations,
      queueLength: _queueLength,
      networkHealth: _networkHealth,
      isOnline: _isOnline,
      isSyncing: _isSyncing,
      onManualSync: _manualSync,
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Real-Time Dashboard'),
          Tab(text: 'Conflict Resolution'),
          Tab(text: 'Offline Queue'),
          Tab(text: 'Sync History'),
          Tab(text: 'Network Health'),
        ],
      ),
    );
  }

  Widget _buildRealTimeDashboard() {
    return RealTimeDashboardWidget(
      contentSyncStatus: _contentSyncStatus,
      onRefresh: _loadSyncData,
    );
  }

  Widget _buildConflictResolution() {
    return ConflictResolutionUiWidget(
      conflicts: _conflicts,
      onResolve: _resolveConflict,
      onRefresh: _loadSyncData,
    );
  }

  Widget _buildOfflineQueueMonitor() {
    return OfflineQueueMonitorWidget(
      queueItems: _queueItems,
      onRetry: (itemId) async {
        // Retry logic would be implemented here
        await _loadSyncData();
      },
      onClear: () async {
        await _syncService.clearSyncQueue();
        await _loadSyncData();
      },
      onRefresh: _loadSyncData,
    );
  }

  Widget _buildSyncHistoryLogs() {
    return SyncHistoryLogsWidget(
      syncHistory: _syncHistory,
      onRefresh: _loadSyncData,
    );
  }

  Widget _buildNetworkHealth() {
    return NetworkHealthWidget(
      networkMetrics: _networkMetrics,
      networkHealth: _networkHealth,
      isOnline: _isOnline,
      onRefresh: _loadSyncData,
    );
  }
}
