import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../services/feature_management_service.dart';

class FeatureAuditLogWidget extends StatefulWidget {
  const FeatureAuditLogWidget({super.key});

  @override
  State<FeatureAuditLogWidget> createState() => _FeatureAuditLogWidgetState();
}

class _FeatureAuditLogWidgetState extends State<FeatureAuditLogWidget> {
  final FeatureManagementService _featureService =
      FeatureManagementService.instance;
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);

    final logs = await _featureService.getFeatureAuditLogs(limit: 100);

    if (mounted) {
      setState(() {
        _auditLogs = logs;
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, y').format(dt);
      }
    } catch (e) {
      return timestamp;
    }
  }

  IconData _getActionIcon(String action) {
    if (action.contains('enable')) return Icons.check_circle;
    if (action.contains('disable')) return Icons.cancel;
    if (action.contains('bulk')) return Icons.flash_on;
    return Icons.edit;
  }

  Color _getActionColor(String action) {
    if (action.contains('enable')) return Colors.green;
    if (action.contains('disable')) return Colors.red;
    if (action.contains('bulk')) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48.sp, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No audit logs yet',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAuditLogs,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _auditLogs.length,
        itemBuilder: (context, index) {
          final log = _auditLogs[index];
          final action = log['action'] as String;
          final timestamp = log['timestamp'] as String;
          final adminName =
              log['user_profiles']?['name'] as String? ?? 'Unknown';
          final adminEmail = log['user_profiles']?['email'] as String? ?? '';
          final reason = log['reason'] as String?;
          final newValue = log['new_value'] as Map<String, dynamic>?;

          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
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
                        color: _getActionColor(action).withAlpha(26),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        _getActionIcon(action),
                        color: _getActionColor(action),
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            'by $adminName',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                if (reason != null) ...[
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                if (newValue != null) ...[
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: newValue.entries.map((entry) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
