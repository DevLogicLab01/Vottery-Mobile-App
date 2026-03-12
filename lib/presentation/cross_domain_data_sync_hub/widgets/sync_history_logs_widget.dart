import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/enhanced_empty_state_widget.dart';

class SyncHistoryLogsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> syncHistory;
  final Future<void> Function() onRefresh;

  const SyncHistoryLogsWidget({
    super.key,
    required this.syncHistory,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (syncHistory.isEmpty) {
      return EnhancedEmptyStateWidget(
        title: 'No Sync History',
        description: 'Sync operations will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.all(3.w),
        itemCount: syncHistory.length,
        itemBuilder: (context, index) {
          final log = syncHistory[index];
          return _buildHistoryLogCard(log);
        },
      ),
    );
  }

  Widget _buildHistoryLogCard(Map<String, dynamic> log) {
    final syncId = log['sync_id'] ?? '';
    final timestamp = log['timestamp'] as DateTime? ?? DateTime.now();
    final durationMs = log['duration_ms'] ?? 0;
    final recordsSynced = log['records_synced'] ?? 0;
    final conflictsDetected = log['conflicts_detected'] ?? 0;
    final dataVolumeBytes = log['data_volume_bytes'] ?? 0;
    final success = log['success'] ?? true;
    final errorMessage = log['error_message'];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: success
              ? Colors.green.withAlpha(77)
              : Colors.red.withAlpha(77),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      success ? 'Sync Successful' : 'Sync Failed',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      _formatFullTimestamp(timestamp),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${durationMs}ms',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Records Synced',
                  value: recordsSynced.toString(),
                  icon: Icons.sync_alt,
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Conflicts',
                  value: conflictsDetected.toString(),
                  icon: Icons.warning_amber,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  label: 'Data Volume',
                  value: _formatBytes(dataVolumeBytes),
                  icon: Icons.data_usage,
                  color: Colors.purple,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  label: 'Sync ID',
                  value: syncId.substring(0, 8),
                  icon: Icons.fingerprint,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (!success && errorMessage != null) ...[
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(13),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.red.withAlpha(77)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16.sp),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}
