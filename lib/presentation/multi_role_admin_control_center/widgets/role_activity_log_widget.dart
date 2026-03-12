import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/multi_role_admin_service.dart';
import './role_badge_widget.dart';

class RoleActivityLogWidget extends StatefulWidget {
  const RoleActivityLogWidget({super.key});

  @override
  State<RoleActivityLogWidget> createState() => _RoleActivityLogWidgetState();
}

class _RoleActivityLogWidgetState extends State<RoleActivityLogWidget> {
  final _adminService = MultiRoleAdminService();

  List<Map<String, dynamic>> _activityLogs = [];
  bool _isLoading = false;
  String? _filterRole;

  @override
  void initState() {
    super.initState();
    _loadActivityLogs();
  }

  Future<void> _loadActivityLogs() async {
    setState(() => _isLoading = true);

    try {
      final logs = await _adminService.getRoleActivityLogs(
        role: _filterRole,
        limit: 50,
      );
      setState(() {
        _activityLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activity logs: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        SizedBox(height: 2.h),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _activityLogs.isEmpty
              ? _buildEmptyState()
              : _buildActivityLogsList(),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: _filterRole,
              decoration: InputDecoration(
                labelText: 'Filter by Role',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                prefixIcon: const Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Roles')),
                ...[
                  'manager',
                  'admin',
                  'moderator',
                  'auditor',
                  'editor',
                  'advertiser',
                  'analyst',
                ].map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase()),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _filterRole = value);
                _loadActivityLogs();
              },
            ),
          ),
          SizedBox(width: 2.w),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivityLogs,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLogsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      itemCount: _activityLogs.length,
      itemBuilder: (context, index) {
        final log = _activityLogs[index];
        return _buildActivityLogCard(log);
      },
    );
  }

  Widget _buildActivityLogCard(Map<String, dynamic> log) {
    final actorRole = log['actor_role'] ?? '';
    final actionType = log['action_type'] ?? '';
    final targetResource = log['target_resource'] ?? '';
    final performedAt = DateTime.parse(log['performed_at']);
    final actor = log['actor'] as Map<String, dynamic>?;
    final actorName = actor?['full_name'] ?? 'Unknown';
    final actorAvatar = actor?['avatar_url'];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: actorAvatar != null
              ? NetworkImage(actorAvatar)
              : null,
          child: actorAvatar == null ? Text(actorName[0].toUpperCase()) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                actorName,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
            RoleBadgeWidget(
              role: actorRole,
              colorCode: _getRoleColorCode(actorRole),
              size: 'small',
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            Text(
              _formatActionType(actionType),
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            ),
            if (targetResource.isNotEmpty)
              Text(
                'Target: $targetResource',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            Text(
              _formatTimestamp(performedAt),
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: Icon(
          _getActionIcon(actionType),
          color: _getActionColor(actionType),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48.sp, color: Colors.grey),
          SizedBox(height: 2.h),
          Text(
            'No activity logs found',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatActionType(String actionType) {
    return actionType
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  IconData _getActionIcon(String actionType) {
    if (actionType.contains('create')) return Icons.add_circle;
    if (actionType.contains('update')) return Icons.edit;
    if (actionType.contains('delete')) return Icons.delete;
    if (actionType.contains('assign')) return Icons.person_add;
    return Icons.info;
  }

  Color _getActionColor(String actionType) {
    if (actionType.contains('create')) return Colors.green;
    if (actionType.contains('update')) return Colors.blue;
    if (actionType.contains('delete')) return Colors.red;
    if (actionType.contains('assign')) return Colors.purple;
    return Colors.grey;
  }

  String _getRoleColorCode(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return 'purple';
      case 'admin':
        return 'red';
      case 'moderator':
        return 'blue';
      case 'auditor':
        return 'green';
      case 'editor':
        return 'orange';
      case 'advertiser':
        return 'yellow';
      case 'analyst':
        return 'teal';
      default:
        return 'gray';
    }
  }
}
