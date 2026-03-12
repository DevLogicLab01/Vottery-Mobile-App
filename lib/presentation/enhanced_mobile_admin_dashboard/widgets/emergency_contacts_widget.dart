import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class EmergencyContactsWidget extends StatelessWidget {
  const EmergencyContactsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone, color: Colors.red, size: 24.sp),
              SizedBox(width: 2.w),
              Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildContactCard(
            'On-Call Engineer',
            'John Smith',
            '+1 (555) 123-4567',
            Icons.engineering,
            Colors.blue,
          ),
          SizedBox(height: 1.h),
          _buildContactCard(
            'Security Lead',
            'Sarah Johnson',
            '+1 (555) 234-5678',
            Icons.security,
            Colors.red,
          ),
          SizedBox(height: 1.h),
          _buildContactCard(
            'DevOps Manager',
            'Mike Chen',
            '+1 (555) 345-6789',
            Icons.cloud,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    String role,
    String name,
    String phone,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(26),
          child: Icon(icon, color: color),
        ),
        title: Text(
          name,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
            Text(phone, style: TextStyle(fontSize: 12.sp)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Colors.green),
          onPressed: () {
            // One-tap call functionality would go here
          },
        ),
      ),
    );
  }
}
