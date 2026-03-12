import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class UserAssignmentWidget extends StatelessWidget {
  final Map<String, dynamic> assignment;

  const UserAssignmentWidget({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final testGroup = assignment['test_group'] ?? 'unknown';
    final groupColor = _getGroupColor(testGroup);
    final groupLabel = _getGroupLabel(testGroup);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: groupColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(Icons.science_outlined, color: groupColor, size: 20.sp),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A/B Test Group',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  groupLabel,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: groupColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: groupColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              testGroup.toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGroupColor(String group) {
    switch (group) {
      case 'control':
        return Colors.grey;
      case 'algorithm_v1':
        return Colors.blue;
      case 'algorithm_v2':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getGroupLabel(String group) {
    switch (group) {
      case 'control':
        return 'Control Group (Chronological)';
      case 'algorithm_v1':
        return 'Algorithm V1 (Collaborative Filtering)';
      case 'algorithm_v2':
        return 'Algorithm V2 (Semantic + Collaborative)';
      default:
        return 'Unknown Group';
    }
  }
}
