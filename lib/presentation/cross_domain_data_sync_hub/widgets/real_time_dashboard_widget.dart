import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class RealTimeDashboardWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> contentSyncStatus;
  final Future<void> Function() onRefresh;

  const RealTimeDashboardWidget({
    super.key,
    required this.contentSyncStatus,
    required this.onRefresh,
  });

  Color _getHealthColor(String health) {
    switch (health) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getContentIcon(String contentType) {
    switch (contentType) {
      case 'elections':
        return Icons.how_to_vote;
      case 'posts':
        return Icons.article;
      case 'ads':
        return Icons.campaign;
      case 'users':
        return Icons.people;
      default:
        return Icons.data_usage;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: EdgeInsets.all(3.w),
        children: [
          Text(
            'Live Sync Status by Content Type',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...contentSyncStatus.entries.map((entry) {
            return _buildContentSyncCard(
              contentType: entry.key,
              syncData: entry.value,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContentSyncCard({
    required String contentType,
    required Map<String, dynamic> syncData,
  }) {
    final synced = syncData['synced'] ?? 0;
    final pending = syncData['pending'] ?? 0;
    final errors = syncData['errors'] ?? 0;
    final health = syncData['health'] ?? 'unknown';
    final lastSync = syncData['lastSync'] as DateTime?;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  _getContentIcon(contentType),
                  color: AppTheme.primaryLight,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contentType.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    if (lastSync != null)
                      Text(
                        'Last sync: ${_formatTimestamp(lastSync)}',
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
                  color: _getHealthColor(health).withAlpha(51),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _getHealthColor(health),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  health.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _getHealthColor(health),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricColumn(
                  label: 'Synced',
                  value: synced.toString(),
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildMetricColumn(
                  label: 'Pending',
                  value: pending.toString(),
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildMetricColumn(
                  label: 'Errors',
                  value: errors.toString(),
                  color: Colors.red,
                ),
              ),
            ],
          ),
          if (pending > 0 || errors > 0) ...[
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: synced / (synced + pending + errors),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                errors > 0 ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricColumn({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
