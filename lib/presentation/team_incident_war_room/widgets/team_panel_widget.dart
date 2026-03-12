import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class TeamPanelWidget extends StatelessWidget {
  final String roomId;
  final List<Map<String, dynamic>> teamMembers;

  const TeamPanelWidget({
    super.key,
    required this.roomId,
    required this.teamMembers,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: teamMembers.length,
      itemBuilder: (context, index) {
        final member = teamMembers[index];
        final userProfile = member['user_profiles'] as Map<String, dynamic>?;
        final status = member['status'] as String? ?? 'offline';
        final role = member['role'] as String? ?? 'Team Member';

        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 25.sp,
                  backgroundColor: AppTheme.primaryLight,
                  child: Icon(Icons.person, size: 25.sp, color: Colors.white),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(status),
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              userProfile?['full_name'] ?? 'Team Member',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.primaryLight,
                  ),
                ),
                if (member['current_task'] != null)
                  Text(
                    'Working on: ${member['current_task']}',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    // TODO: Open direct message
                  },
                  tooltip: 'Message',
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () {
                    // TODO: Initiate call
                  },
                  tooltip: 'Call',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'offline':
      default:
        return Colors.grey;
    }
  }
}
