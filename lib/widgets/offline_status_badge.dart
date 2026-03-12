import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../services/offline_sync_service.dart';
import '../services/hive_offline_service.dart';

/// Small reusable badge showing online/offline state and pending sync count.
/// Can be dropped into any screen (e.g. app bars, footers).
class OfflineStatusBadge extends StatefulWidget {
  const OfflineStatusBadge({super.key});

  @override
  State<OfflineStatusBadge> createState() => _OfflineStatusBadgeState();
}

class _OfflineStatusBadgeState extends State<OfflineStatusBadge> {
  final OfflineSyncService _offlineSync = OfflineSyncService.instance;
  final HiveOfflineService _hiveOffline = HiveOfflineService.instance;

  bool _isOnline = true;
  int _pendingVotes = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _listenToConnectivity();
  }

  Future<void> _loadInitialState() async {
    final online = await _offlineSync.isOnline();
    final pending = await _offlineSync.getPendingVotesCount();
    if (!mounted) return;
    setState(() {
      _isOnline = online;
      _pendingVotes = pending;
    });
  }

  void _listenToConnectivity() {
    _offlineSync.connectivityStream.listen((isOnline) {
      if (!mounted) return;
      setState(() => _isOnline = isOnline);
      if (isOnline) {
        _refreshPendingCount();
      }
    });
  }

  Future<void> _refreshPendingCount() async {
    final pending = await _offlineSync.getPendingVotesCount();
    if (!mounted) return;
    setState(() => _pendingVotes = pending);
  }

  Future<void> _runFullSync() async {
    if (_isSyncing || !_isOnline) return;
    setState(() => _isSyncing = true);
    try {
      await _hiveOffline.syncAllData();
      await _offlineSync.syncPendingVotes();
      await _refreshPendingCount();
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget _buildDiagnosticsHint() {
      return InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.offlineSyncDiagnostics,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.2.w),
          child: Icon(
            Icons.more_vert,
            size: 14,
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
        ),
      );
    }

    if (!_isOnline) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: Colors.red.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withAlpha(102)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 16, color: Colors.red),
            SizedBox(width: 1.5.w),
            Text(
              _pendingVotes > 0
                  ? 'Offline – $_pendingVotes pending'
                  : 'Offline',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 0.5.w),
            _buildDiagnosticsHint(),
          ],
        ),
      );
    }

    // Online
    if (_pendingVotes == 0 && !_isSyncing) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_done, size: 16, color: Colors.green),
            SizedBox(width: 1.5.w),
            Text(
              'Online',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 0.5.w),
            _buildDiagnosticsHint(),
          ],
        ),
      );
    }

    // Online with pending votes or currently syncing
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(26),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withAlpha(140)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _isSyncing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                )
              : const Icon(Icons.sync, size: 16, color: Colors.orange),
          SizedBox(width: 1.5.w),
          Text(
            _isSyncing
                ? 'Syncing...'
                : '$_pendingVotes pending',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 2.w),
          TextButton(
            onPressed: _isSyncing ? null : _runFullSync,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              minimumSize: Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sync now',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 0.5.w),
          _buildDiagnosticsHint(),
        ],
      ),
    );
  }
}

