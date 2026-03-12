import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../services/enhanced_offline_sync_service.dart';
import './widgets/cache_analytics_widget.dart';
import './widgets/conflict_resolution_widget.dart';
import './widgets/data_synchronization_widget.dart';
import './widgets/offline_operations_widget.dart';
import './widgets/storage_card_widget.dart';
import './widgets/storage_status_overview_widget.dart';

class HiveOfflineStorageManagementHub extends StatefulWidget {
  const HiveOfflineStorageManagementHub({super.key});

  @override
  State<HiveOfflineStorageManagementHub> createState() =>
      _HiveOfflineStorageManagementHubState();
}

class _HiveOfflineStorageManagementHubState
    extends State<HiveOfflineStorageManagementHub> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final EnhancedOfflineSyncService _enhancedSyncService =
      EnhancedOfflineSyncService.instance;
  final Connectivity _connectivity = Connectivity();

  bool _isLoading = true;
  bool _isOnline = true;
  bool _isSyncing = false;
  Map<String, dynamic> _storageStats = {};
  Map<String, dynamic> _syncMetrics = {};
  final List<Map<String, dynamic>> _syncQueue = [];
  final List<Map<String, dynamic>> _conflicts = [];

  // Hive boxes
  late Box<Map<dynamic, dynamic>> _electionsBox;
  late Box<Map<dynamic, dynamic>> _votesBox;
  late Box<Map<dynamic, dynamic>> _userProfilesBox;
  late Box<Map<dynamic, dynamic>> _aiResponsesBox;
  late Box<Map<dynamic, dynamic>> _syncQueueBox;

  @override
  void initState() {
    super.initState();
    _initializeEnhancedSync();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeEnhancedSync() async {
    try {
      setState(() => _isLoading = true);

      // Initialize enhanced offline sync service
      await _enhancedSyncService.initialize();

      await _loadStorageData();
      await _loadSyncMetrics();
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Initialize enhanced sync error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = !results.contains(ConnectivityResult.none);
    });

    if (_isOnline && _enhancedSyncService.getSyncQueueDepth() > 0) {
      _syncData();
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      setState(() {
        _isOnline = !results.contains(ConnectivityResult.none);
      });

      // Auto-sync when reconnected
      if (wasOffline &&
          _isOnline &&
          _enhancedSyncService.getSyncQueueDepth() > 0) {
        _syncData();
      }
    });
  }

  Future<void> _loadStorageData() async {
    try {
      // Get sync queue depth
      final syncQueueDepth = _enhancedSyncService.getSyncQueueDepth();

      setState(() {
        _storageStats = {
          'sync_queue_depth': syncQueueDepth,
          'is_syncing': _enhancedSyncService.isSyncing,
        };
      });
    } catch (e) {
      debugPrint('Load storage data error: $e');
    }
  }

  Future<void> _loadSyncMetrics() async {
    try {
      final metrics = await _enhancedSyncService.getSyncMetrics();
      setState(() {
        _syncMetrics = metrics;
      });
    } catch (e) {
      debugPrint('Load sync metrics error: $e');
    }
  }

  Future<void> _syncData() async {
    if (_isSyncing || !_isOnline) return;

    try {
      setState(() => _isSyncing = true);

      final result = await _enhancedSyncService.syncPendingData();

      await _loadStorageData();
      await _loadSyncMetrics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sync completed: ${result['synced']} succeeded, ${result['failed']} failed\nData reduction: ${result['data_reduction_percent']}%',
            ),
            backgroundColor: result['synced'] > 0
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Sync data error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _syncVote(Map<String, dynamic> voteData) async {
    await _supabaseService.client.from('votes').insert(voteData);
  }

  Future<void> _syncElection(Map<String, dynamic> electionData) async {
    await _supabaseService.client.from('elections').upsert(electionData);
  }

  Future<void> _syncProfile(Map<String, dynamic> profileData) async {
    await _supabaseService.client.from('user_profiles').upsert(profileData);
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will delete all locally stored data. Unsynchronized changes will be lost. Continue?',
        ),
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

    if (confirm != true) return;

    try {
      await _electionsBox.clear();
      await _votesBox.clear();
      await _userProfilesBox.clear();
      await _aiResponsesBox.clear();
      await _syncQueueBox.clear();

      await _loadStorageData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Clear cache error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offline Storage Hub',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isOnline)
            IconButton(
              icon: _isSyncing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.sync),
              onPressed: _isSyncing ? null : _syncData,
              tooltip: 'Sync Now',
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearCache,
            tooltip: 'Clear Cache',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStorageData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StorageStatusOverviewWidget(
                      stats: _storageStats,
                      isOnline: _isOnline,
                      isSyncing: _isSyncing,
                    ),
                    SizedBox(height: 3.h),
                    DataSynchronizationWidget(
                      syncQueue: _syncQueue,
                      isOnline: _isOnline,
                      isSyncing: _isSyncing,
                      onSyncPressed: _syncData,
                    ),
                    SizedBox(height: 3.h),
                    CacheAnalyticsWidget(stats: _storageStats),
                    SizedBox(height: 3.h),
                    OfflineOperationsWidget(syncQueue: _syncQueue),
                    SizedBox(height: 3.h),
                    if (_conflicts.isNotEmpty)
                      ConflictResolutionWidget(
                        conflicts: _conflicts,
                        onConflictResolved: _loadStorageData,
                      ),
                    SizedBox(height: 3.h),
                    Text(
                      'Storage Breakdown',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    StorageCardWidget(
                      title: 'Elections',
                      count: _storageStats['elections_count'] ?? 0,
                      icon: Icons.how_to_vote,
                      color: Colors.blue,
                    ),
                    SizedBox(height: 1.h),
                    StorageCardWidget(
                      title: 'Votes',
                      count: _storageStats['votes_count'] ?? 0,
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    SizedBox(height: 1.h),
                    StorageCardWidget(
                      title: 'User Profiles',
                      count: _storageStats['profiles_count'] ?? 0,
                      icon: Icons.person,
                      color: Colors.orange,
                    ),
                    SizedBox(height: 1.h),
                    StorageCardWidget(
                      title: 'AI Responses',
                      count: _storageStats['ai_responses_count'] ?? 0,
                      icon: Icons.psychology,
                      color: Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
