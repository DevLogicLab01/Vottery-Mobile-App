import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ConflictResolution3WayWidget extends StatelessWidget {
  final List<Map<String, dynamic>> conflicts;
  final Function(String conflictId, String resolution) onResolve;

  const ConflictResolution3WayWidget({
    super.key,
    required this.conflicts,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3-Way Merge Resolution',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            if (conflicts.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Text(
                    'No conflicts detected',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: conflicts.length,
                itemBuilder: (context, index) {
                  final conflict = conflicts[index];
                  return _buildConflictCard(context, conflict);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictCard(
    BuildContext context,
    Map<String, dynamic> conflict,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      color: Colors.orange[50],
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 20.sp),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Conflict: ${conflict['type']}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'ID: ${conflict['id']}',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onResolve(conflict['id'], 'use_local'),
                  child: const Text('Use Local'),
                ),
                SizedBox(width: 2.w),
                TextButton(
                  onPressed: () => onResolve(conflict['id'], 'use_server'),
                  child: const Text('Use Server'),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  onPressed: () => onResolve(conflict['id'], 'merge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Auto Merge'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
