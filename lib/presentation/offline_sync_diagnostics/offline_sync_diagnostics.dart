import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/offline_sync_service.dart';
import '../../services/hive_offline_service.dart';
import '../../services/messaging_service.dart';
import '../../services/logging/platform_logging_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Offline Sync Diagnostics Screen
/// Shows offline status, pending queues, and provides manual sync controls.
class OfflineSyncDiagnostics extends StatefulWidget {
  const OfflineSyncDiagnostics({super.key});

  @override
  State<OfflineSyncDiagnostics> createState() => _OfflineSyncDiagnosticsState();
}

class _OfflineSyncDiagnosticsState extends State<OfflineSyncDiagnostics> {
  final OfflineSyncService _offlineSync = OfflineSyncService.instance;
  final HiveOfflineService _hiveOffline = HiveOfflineService.instance;
  final MessagingService _messagingService = MessagingService.instance;

  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingVotes = 0;
  int _pendingMessages = 0;
  int _offlineLogCount = 0;
  int _cachedElectionsCount = 0;
  int _syncedLastRun = 0;
  int _failedLastRun = 0;
  int _conflictsLastRun = 0;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final online = await _offlineSync.isOnline();
    final pending = await _offlineSync.getPendingVotesCount();
    final lastSync = await _offlineSync.getLastSyncTime();
    final pendingMessages = await _messagingService.getOfflineQueueCount();
    final offlineLogs = await PlatformLoggingService.getOfflineLogCount();
    final cachedElections = _hiveOffline.cachedElectionsCount;
    if (!mounted) return;
    setState(() {
      _isOnline = online;
      _pendingVotes = pending;
      _pendingMessages = pendingMessages;
      _offlineLogCount = offlineLogs;
      _cachedElectionsCount = cachedElections;
      _lastSyncTime = lastSync;
    });
  }

  Future<void> _runHiveSync() async {
    if (_isSyncing || !_isOnline) return;
    setState(() {
      _isSyncing = true;
      _syncedLastRun = 0;
      _failedLastRun = 0;
      _conflictsLastRun = 0;
    });
    try {
      final result = await _hiveOffline.syncAllData();
      if (!mounted) return;
      setState(() {
        _syncedLastRun = (result['synced'] as int?) ?? 0;
        _failedLastRun = (result['failed'] as int?) ?? 0;
        _conflictsLastRun = (result['conflicts'] as int?) ?? 0;
        _lastSyncTime = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _loadState();
      }
    }
  }

  Future<void> _runPendingVoteSync() async {
    if (_isSyncing || !_isOnline) return;
    setState(() => _isSyncing = true);
    try {
      final result = await _offlineSync.syncPendingVotes();
      if (!mounted) return;
      setState(() {
        _syncedLastRun = (result['synced'] as int?) ?? 0;
        _failedLastRun = (result['failed'] as int?) ?? 0;
        _conflictsLastRun = 0;
        _lastSyncTime = DateTime.now();
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _loadState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'OfflineSyncDiagnostics',
      onRetry: _loadState,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Offline Sync Diagnostics',
          variant: CustomAppBarVariant.withBack,
        ),
        body: RefreshIndicator(
          onRefresh: _loadState,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(theme),
                SizedBox(height: 2.h),
                _buildQueuesCard(theme),
                SizedBox(height: 2.h),
                _buildActionsCard(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3.w,
                  height: 3.w,
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: _isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (_lastSyncTime != null)
                  Text(
                    'Last sync: ${_lastSyncTime!.toLocal().toString().split(".").first}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Text(
              'Diagnostics for offline votes and cached entities.\nUse this screen to verify sync status and force a manual sync when needed.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueuesCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Queues',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.5.h),
            Wrap(
              spacing: 3.w,
              runSpacing: 1.5.h,
              children: [
                _buildStatChip(
                  theme,
                  icon: Icons.how_to_vote,
                  label: 'Pending Votes',
                  value: _pendingVotes.toString(),
                  color: Colors.orange,
                ),
                _buildStatChip(
                  theme,
                  icon: Icons.chat_outlined,
                  label: 'Pending Messages',
                  value: _pendingMessages.toString(),
                  color: Colors.purple,
                ),
                _buildStatChip(
                  theme,
                  icon: Icons.receipt_long,
                  label: 'Offline Logs',
                  value: _offlineLogCount.toString(),
                  color: Colors.redAccent,
                ),
                _buildStatChip(
                  theme,
                  icon: Icons.how_to_vote_outlined,
                  label: 'Cached Elections',
                  value: _cachedElectionsCount.toString(),
                  color: Colors.teal,
                ),
                _buildStatChip(
                  theme,
                  icon: Icons.cloud_sync,
                  label: 'Last Sync Result',
                  value:
                      '${_syncedLastRun} ok / ${_failedLastRun} failed / ${_conflictsLastRun} conflicts',
                  color: Colors.blue,
                  expanded: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.5.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                ElevatedButton.icon(
                  onPressed: !_isOnline || _isSyncing ? null : _runHiveSync,
                  icon: const Icon(Icons.storage),
                  label: const Text('Sync cached entities'),
                ),
                ElevatedButton.icon(
                  onPressed: !_isOnline || _isSyncing ? null : _runPendingVoteSync,
                  icon: const Icon(Icons.how_to_vote),
                  label: const Text('Sync pending votes'),
                ),
                OutlinedButton.icon(
                  onPressed: _isSyncing ? null : _loadState,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh state'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool expanded = false,
  }) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        SizedBox(width: 1.5.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 0.3.h),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );

    return expanded
        ? Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(24),
              ),
              child: child,
            ),
          )
        : Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: child,
          );
  }
}

