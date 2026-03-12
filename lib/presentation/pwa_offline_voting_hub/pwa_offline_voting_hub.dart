import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/enhanced_notification_service.dart';
import '../../services/offline_sync_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/background_sync_monitor_widget.dart';
import './widgets/cached_elections_widget.dart';
import './widgets/offline_status_indicator_widget.dart';
import './widgets/offline_vote_queue_widget.dart';
import './widgets/pwa_installation_widget.dart';

class PWAOfflineVotingHub extends StatefulWidget {
  const PWAOfflineVotingHub({super.key});

  @override
  State<PWAOfflineVotingHub> createState() => _PWAOfflineVotingHubState();
}

class _PWAOfflineVotingHubState extends State<PWAOfflineVotingHub> {
  final OfflineSyncService _offlineSync = OfflineSyncService.instance;
  final EnhancedNotificationService _notificationService =
      EnhancedNotificationService.instance;

  bool _isLoading = true;
  bool _isOnline = false;
  int _cachedVotesCount = 0;
  int _pendingVotesCount = 0;
  DateTime? _lastSyncTime;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineData();
    _listenToConnectivity();
  }

  Future<void> _loadOfflineData() async {
    setState(() => _isLoading = true);

    try {
      final isOnline = await _offlineSync.isOnline();
      final pendingCount = await _offlineSync.getPendingVotesCount();
      final lastSync = await _offlineSync.getLastSyncTime();

      setState(() {
        _isOnline = isOnline;
        _pendingVotesCount = pendingCount;
        _lastSyncTime = lastSync;
        _cachedVotesCount = 0; // Will be populated from cached elections
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load offline data error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _listenToConnectivity() {
    _offlineSync.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
        if (isOnline && _pendingVotesCount > 0) {
          _syncPendingVotes();
        }
      }
    });
  }

  Future<void> _syncPendingVotes() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      final result = await _offlineSync.syncPendingVotes();

      if (result['success']) {
        await _notificationService.sendNotification(
          userId: 'current_user',
          category: 'system',
          priority: 'normal',
          title: 'Sync Complete',
          body: 'Synced ${result['synced']} votes. ${result['failed']} failed.',
        );
      }

      await _loadOfflineData();
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'PWAOfflineVotingHub',
      onRetry: _loadOfflineData,
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
          title: 'Offline Voting Hub',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadOfflineData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _loadOfflineData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      OfflineStatusIndicatorWidget(
                        isOnline: _isOnline,
                        cachedVotesCount: _cachedVotesCount,
                        pendingVotesCount: _pendingVotesCount,
                        lastSyncTime: _lastSyncTime,
                      ),
                      SizedBox(height: 2.h),
                      CachedElectionsWidget(onVoteOffline: _handleOfflineVote),
                      SizedBox(height: 2.h),
                      OfflineVoteQueueWidget(
                        pendingVotesCount: _pendingVotesCount,
                        onSync: _syncPendingVotes,
                        isSyncing: _isSyncing,
                      ),
                      SizedBox(height: 2.h),
                      BackgroundSyncMonitorWidget(
                        isOnline: _isOnline,
                        lastSyncTime: _lastSyncTime,
                        syncProgress: _isSyncing ? 0.5 : 1.0,
                      ),
                      SizedBox(height: 2.h),
                      const PWAInstallationWidget(),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _handleOfflineVote({
    required String electionId,
    required String electionTitle,
    String? selectedOptionId,
  }) async {
    final success = await _offlineSync.storeOfflineVote(
      electionId: electionId,
      electionTitle: electionTitle,
      selectedOptionId: selectedOptionId,
    );

    if (success) {
      await _notificationService.sendNotification(
        userId: 'current_user',
        category: 'new_vote',
        priority: 'normal',
        title: 'Vote Saved Offline',
        body: 'Your vote for "$electionTitle" will sync when online.',
      );

      await _loadOfflineData();
    }
  }
}

class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          ShimmerSkeletonLoader(
            child: Container(
              height: 15.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: Container(
              height: 20.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ShimmerSkeletonLoader(
            child: Container(
              height: 15.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
