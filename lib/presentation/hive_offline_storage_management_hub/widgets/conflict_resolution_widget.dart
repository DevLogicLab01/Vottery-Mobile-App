import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ConflictResolutionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> conflicts;
  final VoidCallback onConflictResolved;

  const ConflictResolutionWidget({
    super.key,
    required this.conflicts,
    required this.onConflictResolved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 24),
                SizedBox(width: 2.w),
                Text(
                  'Conflict Resolution',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[900],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              '${conflicts.length} conflicts require manual resolution',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: () {
                // Show conflict resolution dialog
                _showConflictResolutionDialog(context);
              },
              icon: const Icon(Icons.build, size: 18),
              label: Text(
                'Resolve Conflicts',
                style: TextStyle(fontSize: 12.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConflictResolutionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Conflicts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Manual resolution interface for complex data conflicts with side-by-side comparison',
              style: TextStyle(fontSize: 12.sp),
            ),
            SizedBox(height: 2.h),
            Text(
              '${conflicts.length} conflicts detected',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConflictResolved();
            },
            child: const Text('Resolve All'),
          ),
        ],
      ),
    );
  }
}
