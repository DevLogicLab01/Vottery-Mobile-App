import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/offline_sync_service.dart';

class OfflineSyncStatusWidget extends StatefulWidget {
  final bool isOnline;
  final int pendingCount;
  final VoidCallback onRefresh;

  const OfflineSyncStatusWidget({
    super.key,
    required this.isOnline,
    required this.pendingCount,
    required this.onRefresh,
  });

  @override
  State<OfflineSyncStatusWidget> createState() =>
      _OfflineSyncStatusWidgetState();
}

class _OfflineSyncStatusWidgetState extends State<OfflineSyncStatusWidget> {
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final lastSync = await OfflineSyncService.instance.getLastSyncTime();
    if (mounted) {
      setState(() => _lastSyncTime = lastSync);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: widget.isOnline ? Colors.green : Colors.orange,
                  size: 18.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  widget.isOnline ? 'Online' : 'Offline Mode',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Sync status indicators
            _buildStatusRow(
              'Connection Status',
              widget.isOnline ? 'Connected' : 'Disconnected',
              widget.isOnline ? Colors.green : Colors.orange,
            ),
            _buildStatusRow(
              'Pending Items',
              '${widget.pendingCount}',
              widget.pendingCount > 0 ? Colors.orange : Colors.green,
            ),
            if (_lastSyncTime != null)
              _buildStatusRow(
                'Last Sync',
                _formatLastSync(_lastSyncTime!),
                Colors.grey,
              ),
            SizedBox(height: 2.h),

            // Sync progress
            if (_isSyncing) ...[
              LinearProgressIndicator(),
              SizedBox(height: 1.h),
              Center(
                child: Text(
                  'Syncing...',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: 1.h),
            ],

            // Manual sync button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.isOnline && !_isSyncing ? _manualSync : null,
                icon: Icon(_isSyncing ? Icons.sync : Icons.sync, size: 14.sp),
                label: Text(
                  _isSyncing ? 'Syncing...' : 'Manual Sync',
                  style: TextStyle(fontSize: 11.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            if (!widget.isOnline) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14.sp, color: Colors.orange),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        'Votes will sync automatically when connection is restored',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

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

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);

    try {
      final result = await OfflineSyncService.instance.syncPendingVotes();

      if (mounted) {
        setState(() => _isSyncing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success']
                  ? 'Synced ${result['synced']} votes successfully'
                  : 'Sync failed: ${result['message']}',
            ),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );

        widget.onRefresh();
        _loadLastSyncTime();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
