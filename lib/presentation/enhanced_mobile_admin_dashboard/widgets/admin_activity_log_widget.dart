import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/admin_management_service.dart';

class AdminActivityLogWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const AdminActivityLogWidget({super.key, required this.onRefresh});

  @override
  State<AdminActivityLogWidget> createState() => _AdminActivityLogWidgetState();
}

class _AdminActivityLogWidgetState extends State<AdminActivityLogWidget> {
  final AdminManagementService _adminService = AdminManagementService.instance;
  List<Map<String, dynamic>> _activityLog = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivityLog();
  }

  Future<void> _loadActivityLog() async {
    setState(() => _isLoading = true);

    try {
      // Mock activity log data
      _activityLog = [
        {
          'action': 'pause_campaign',
          'admin': 'admin@vottery.com',
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 5))
              .toIso8601String(),
          'ip_address': '192.168.1.100',
          'biometric_verified': true,
        },
        {
          'action': 'freeze_account',
          'admin': 'security@vottery.com',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
          'ip_address': '192.168.1.101',
          'biometric_verified': true,
        },
        {
          'action': 'bulk_suspend',
          'admin': 'admin@vottery.com',
          'timestamp': DateTime.now()
              .subtract(const Duration(hours: 3))
              .toIso8601String(),
          'ip_address': '192.168.1.100',
          'biometric_verified': true,
        },
      ];

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Load activity log error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadActivityLog();
        widget.onRefresh();
      },
      child: _activityLog.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(3.w),
              itemCount: _activityLog.length,
              itemBuilder: (context, index) {
                return _buildActivityCard(_activityLog[index]);
              },
            ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final action = activity['action'] ?? 'unknown';
    final admin = activity['admin'] ?? 'Unknown';
    final timestamp = activity['timestamp'] ?? DateTime.now().toIso8601String();
    final ipAddress = activity['ip_address'] ?? 'N/A';
    final biometricVerified = activity['biometric_verified'] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getActionIcon(action),
                  color: const Color(0xFFFFC629),
                  size: 20.sp,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _formatAction(action),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (biometricVerified)
                  Icon(Icons.verified_user, color: Colors.green, size: 16.sp),
              ],
            ),
            SizedBox(height: 1.h),
            _buildInfoRow('Admin', admin),
            _buildInfoRow('Time', _formatTimestamp(timestamp)),
            _buildInfoRow('IP Address', ipAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 0.5.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No activity logs',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'pause_campaign':
        return Icons.pause_circle;
      case 'resume_campaign':
        return Icons.play_circle;
      case 'freeze_account':
        return Icons.block;
      case 'block_transaction':
        return Icons.money_off;
      case 'escalate_security':
        return Icons.security;
      case 'disable_feature':
        return Icons.toggle_off;
      case 'bulk_suspend':
        return Icons.people_outline;
      default:
        return Icons.admin_panel_settings;
    }
  }

  String _formatAction(String action) {
    return action
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (e) {
      return 'Just now';
    }
  }
}
