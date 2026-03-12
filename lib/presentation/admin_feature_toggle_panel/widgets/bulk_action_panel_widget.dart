import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class BulkActionPanelWidget extends StatelessWidget {
  final String category;
  final Function(String category, bool enable) onBulkAction;

  const BulkActionPanelWidget({
    super.key,
    required this.category,
    required this.onBulkAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(color: Colors.grey.shade50),
      child: Row(
        children: [
          Icon(Icons.flash_on, size: 16.sp, color: Colors.grey[700]),
          SizedBox(width: 2.w),
          Text(
            'Bulk Actions:',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onBulkAction(category, true),
                    icon: Icon(Icons.check_circle, size: 14.sp),
                    label: Text(
                      'Enable All',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onBulkAction(category, false),
                    icon: Icon(Icons.cancel, size: 14.sp),
                    label: Text(
                      'Disable All',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: 1.h),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
