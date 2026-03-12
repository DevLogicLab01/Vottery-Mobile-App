import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/revenue_split_admin_service.dart';

class SplitAuditLogWidget extends StatefulWidget {
  const SplitAuditLogWidget({super.key});

  @override
  State<SplitAuditLogWidget> createState() => _SplitAuditLogWidgetState();
}

class _SplitAuditLogWidgetState extends State<SplitAuditLogWidget> {
  final RevenueSplitAdminService _service = RevenueSplitAdminService.instance;
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    final logs = await _service.getAuditLog(limit: 100);
    if (mounted) {
      setState(() {
        _auditLogs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_auditLogs.isEmpty) {
      return Center(
        child: Text(
          'No audit logs yet',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        return _buildAuditLogCard(log);
      },
    );
  }

  Widget _buildAuditLogCard(Map<String, dynamic> log) {
    final actionType = log['action_type'] as String;
    final icon = _getActionIcon(actionType);
    final color = _getActionColor(actionType);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatActionType(actionType),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'By: ${log['user_profiles']?['full_name'] ?? 'System'}',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _formatTimestamp(log['timestamp']),
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                  ),
                  if (log['affected_creators_count'] != null &&
                      log['affected_creators_count'] > 0) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      'Affected ${log['affected_creators_count']} creators',
                      style: TextStyle(fontSize: 10.sp, color: Colors.orange),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(String actionType) {
    switch (actionType) {
      case 'config_change':
        return Icons.settings;
      case 'campaign_create':
        return Icons.add_circle;
      case 'campaign_modify':
        return Icons.edit;
      case 'campaign_end':
        return Icons.stop_circle;
      case 'campaign_pause':
        return Icons.pause_circle;
      case 'campaign_resume':
        return Icons.play_circle;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'config_change':
        return Colors.blue;
      case 'campaign_create':
        return Colors.green;
      case 'campaign_modify':
        return Colors.orange;
      case 'campaign_end':
        return Colors.red;
      case 'campaign_pause':
        return Colors.grey;
      case 'campaign_resume':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatActionType(String actionType) {
    return actionType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      final date = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
