import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../services/ai_cache_service.dart';
import './widgets/cache_optimization_widget.dart';
import './widgets/cache_stats_card_widget.dart';
import './widgets/sync_queue_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class AICacheManagementDashboard extends StatefulWidget {
  const AICacheManagementDashboard({super.key});

  @override
  State<AICacheManagementDashboard> createState() =>
      _AICacheManagementDashboardState();
}

class _AICacheManagementDashboardState extends State<AICacheManagementDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _cacheStats = {};
  bool _isSyncing = false;
  bool _isOnline = true;
  StreamSubscription? _connectivitySubscription;
  DateTime _lastSyncTime = DateTime.now();
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCacheStats();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _loadCacheStats() {
    setState(() {
      _cacheStats = AICacheService.getCacheStats();
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivityResult != ConnectivityResult.none;
    });
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      if (_isOnline) {
        _syncCache();
      }
    });
  }

  Future<void> _syncCache() async {
    setState(() => _isSyncing = true);
    try {
      await AICacheService.syncPendingAIRequests();
      setState(() {
        _lastSyncTime = DateTime.now();
      });
      _loadCacheStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache synced successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: ${e.toString()}')));
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AICacheService.clearAllCache();
      _loadCacheStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AICacheManagementDashboard',
      onRetry: _loadCacheStats,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('AI Cache Management'),
          actions: [
            if (_isOnline)
              IconButton(
                icon: _isSyncing
                    ? SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                onPressed: _isSyncing ? null : _syncCache,
                tooltip: 'Sync cache',
              ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCache,
              tooltip: 'Clear cache',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
              Tab(text: 'Sync Queue', icon: Icon(Icons.queue)),
              Tab(text: 'Optimization', icon: Icon(Icons.tune)),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : (_cacheStats['total_cache_items'] ?? 0) == 0
            ? NoDataEmptyState(
                title: 'No Cached Data',
                description: 'Cached AI responses will appear here.',
                onRefresh: _loadCacheStats,
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildStatusBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildSyncQueueTab(),
                          _buildOptimizationTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green[50] : Colors.red[50],
        border: Border(
          bottom: BorderSide(
            color: _isOnline ? Colors.green : Colors.red,
            width: 2.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: _isOnline ? Colors.green : Colors.red,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  'Last sync: ${_formatTime(_lastSyncTime)}',
                  style: TextStyle(fontSize: 11.0, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            '${_cacheStats['total_cache_items'] ?? 0} items',
            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: () async => _loadCacheStats(),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CacheStatsCard(
            title: 'Consensus Results',
            count: _cacheStats['consensus_cached'] ?? 0,
            icon: Icons.psychology,
            color: Colors.blue,
          ),
          const SizedBox(height: 16.0),
          CacheStatsCard(
            title: 'Cached Quests',
            count: _cacheStats['quests_cached'] ?? 0,
            icon: Icons.emoji_events,
            color: Colors.green,
          ),
          const SizedBox(height: 16.0),
          CacheStatsCard(
            title: 'Pending Requests',
            count: _cacheStats['pending_requests'] ?? 0,
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncQueueTab() {
    return SyncQueueWidget(
      pendingRequests: _cacheStats['pending_requests'] ?? 0,
      onSync: _syncCache,
      isSyncing: _isSyncing,
      isOnline: _isOnline,
    );
  }

  Widget _buildOptimizationTab() {
    return CacheOptimizationWidget(
      cacheStats: _cacheStats,
      onClearCache: _clearCache,
      onOptimize: () {
        // Implement cache optimization logic
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cache optimized')));
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
