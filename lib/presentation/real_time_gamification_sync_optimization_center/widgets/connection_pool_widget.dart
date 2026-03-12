import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ConnectionPoolWidget extends StatelessWidget {
  final int activeConnections;
  final int maxConnections;

  const ConnectionPoolWidget({
    super.key,
    required this.activeConnections,
    required this.maxConnections,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'WebSocket Connection Pool',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Connections',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: activeConnections / maxConnections,
                  backgroundColor: Colors.grey.shade200,
                ),
                SizedBox(height: 1.h),
                Text(
                  '$activeConnections / $maxConnections connections',
                  style: TextStyle(fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        _buildConnectionCard('VP Transactions', 'Active', Colors.green),
        _buildConnectionCard('Leaderboards', 'Active', Colors.green),
        _buildConnectionCard('Achievements', 'Active', Colors.green),
        _buildConnectionCard('Feed Quests', 'Active', Colors.green),
        _buildConnectionCard('Blockchain Logs', 'Active', Colors.green),
      ],
    );
  }

  Widget _buildConnectionCard(String name, String status, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: Icon(Icons.cable, color: color),
        title: Text(name),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            status,
            style: TextStyle(color: color, fontSize: 10.sp),
          ),
        ),
      ),
    );
  }
}
