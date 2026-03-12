import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/platform_log.dart';

extension PlatformLogExtensions on PlatformLog {
  String get severity => severity ?? 'info';
  String? get details => details;
  String get type => type ?? 'general';
  String? get platform => platform;
}

class CriticalAlertCardWidget extends StatelessWidget {
  final PlatformLog log;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const CriticalAlertCardWidget({
    super.key,
    required this.log,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(log.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDismiss();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 5.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(Icons.delete, color: Colors.white, size: 24.sp),
      ),
      child: Card(
        elevation: 3,
        margin: EdgeInsets.only(bottom: 2.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: _getSeverityColor(log.severity), width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildSeverityIcon(),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.message.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: _getSeverityColor(log.severity),
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _formatTimestamp(log.createdAt),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSeverityBadge(),
                  ],
                ),
                SizedBox(height: 1.5.h),
                Text(
                  log.details ?? '',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[800]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                Row(
                  children: [
                    _buildInfoChip(log.type, Icons.category),
                    SizedBox(width: 2.w),
                    if (log.platform != null)
                      _buildInfoChip(log.platform!, Icons.source),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityIcon() {
    IconData iconData;
    Color iconColor = _getSeverityColor(log.severity);

    switch (log.severity) {
      case 'critical':
        iconData = Icons.error;
        break;
      case 'error':
        iconData = Icons.warning;
        break;
      case 'warn':
        iconData = Icons.info;
        break;
      default:
        iconData = Icons.notifications;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 20.sp),
    );
  }

  Widget _buildSeverityBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: _getSeverityColor(log.severity),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        log.severity.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: Colors.grey[700]),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String level) {
    switch (level) {
      case 'critical':
        return Colors.red;
      case 'error':
        return Colors.orange;
      case 'warn':
        return Colors.yellow[700]!;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
