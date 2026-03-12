import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/offline_sync_service.dart';

/// Conflict Resolution Card Widget
/// Side-by-side comparison UI for three-way merge conflict resolution
class ConflictResolutionCardWidget extends StatelessWidget {
  final Map<String, dynamic> conflict;
  final VoidCallback onResolved;

  const ConflictResolutionCardWidget({
    super.key,
    required this.conflict,
    required this.onResolved,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localVersion =
        conflict['local_version'] as Map<String, dynamic>? ?? {};
    final serverVersion =
        conflict['server_version'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withAlpha(77), width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Sync Conflict',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                conflict['table_name'] ?? 'Unknown',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildVersionColumn(
                  'Local Version',
                  localVersion,
                  Colors.blue,
                  theme,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildVersionColumn(
                  'Server Version',
                  serverVersion,
                  Colors.green,
                  theme,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _resolveConflict(context, 'local_wins'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Use Local'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _resolveConflict(context, 'server_wins'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Use Server'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _resolveConflict(context, 'merged'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Merge'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVersionColumn(
    String title,
    Map<String, dynamic> version,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 1.h),
          ...version.entries
              .take(3)
              .map(
                (entry) => Padding(
                  padding: EdgeInsets.only(bottom: 0.5.h),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _resolveConflict(BuildContext context, String strategy) async {
    final syncService = OfflineSyncService.instance;

    try {
      await syncService.resolveConflict(
        conflictId: conflict['conflict_id'],
        strategy: strategy,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conflict resolved using $strategy'),
            backgroundColor: Colors.green,
          ),
        );
      }

      onResolved();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
