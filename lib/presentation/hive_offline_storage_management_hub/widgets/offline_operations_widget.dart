import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

class OfflineOperationsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> syncQueue;

  const OfflineOperationsWidget({super.key, required this.syncQueue});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline Operations',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            Text(
              'Queued actions with retry logic and priority management',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 2.h),
            if (syncQueue.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Text(
                    'No pending operations',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: syncQueue.length > 5 ? 5 : syncQueue.length,
                itemBuilder: (context, index) {
                  final item = syncQueue[index];
                  final type = item['type'] ?? 'unknown';
                  final queuedAt = DateTime.tryParse(item['queued_at'] ?? '');
                  final retryCount = item['sync_attempts'] ?? 0;

                  return ListTile(
                    leading: _buildTypeIcon(type),
                    title: Text(
                      _getTypeLabel(type),
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    subtitle: Text(
                      queuedAt != null
                          ? 'Queued ${timeago.format(queuedAt)}'
                          : 'Unknown',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    trailing: retryCount > 0
                        ? Chip(
                            label: Text(
                              'Retry $retryCount',
                              style: TextStyle(fontSize: 10.sp),
                            ),
                            backgroundColor: Colors.orange,
                          )
                        : null,
                  );
                },
              ),
            if (syncQueue.length > 5)
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text('View all ${syncQueue.length} items'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'vote':
        icon = Icons.how_to_vote;
        color = Colors.green;
        break;
      case 'election':
        icon = Icons.ballot;
        color = Colors.blue;
        break;
      case 'profile':
        icon = Icons.person;
        color = Colors.orange;
        break;
      default:
        icon = Icons.sync;
        color = Colors.grey;
    }

    return Icon(icon, color: color);
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'vote':
        return 'Vote Submission';
      case 'election':
        return 'Election Update';
      case 'profile':
        return 'Profile Update';
      default:
        return 'Unknown Operation';
    }
  }
}
