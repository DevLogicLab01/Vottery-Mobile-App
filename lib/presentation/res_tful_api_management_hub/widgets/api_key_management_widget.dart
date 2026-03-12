import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ApiKeyManagementWidget extends StatelessWidget {
  const ApiKeyManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'API Key Management',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        ElevatedButton.icon(
          onPressed: () {},
          icon: Icon(Icons.add),
          label: Text('Generate New API Key'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
        ),
        SizedBox(height: 2.h),
        _buildApiKeyCard(
          'Production Key',
          'pk_live_***************',
          'Active',
          Colors.green,
        ),
        SizedBox(height: 1.h),
        _buildApiKeyCard(
          'Development Key',
          'pk_test_***************',
          'Active',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildApiKeyCard(
    String name,
    String key,
    String status,
    Color statusColor,
  ) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              key,
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'monospace',
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.copy, size: 14.sp),
                  label: Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.delete, size: 14.sp, color: Colors.red),
                  label: Text('Revoke', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
