import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/platform_log.dart';

class UserActivityCardWidget extends StatelessWidget {
  final PlatformLog log;

  const UserActivityCardWidget({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 2.h),
      child: ExpansionTile(
        leading: _buildActivityIcon(),
        title: Text(
          log.message,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatTimestamp(log.createdAt)),
            SizedBox(height: 0.5.h),
            Text(
              log.eventType.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        children: [
          if (log.metadata != null && log.metadata!.isNotEmpty)
            _buildMetadataSection(),
        ],
      ),
    );
  }

  Widget _buildActivityIcon() {
    IconData iconData;
    Color iconColor;

    switch (log.logCategory) {
      case 'voting':
        iconData = Icons.how_to_vote;
        iconColor = Colors.blue;
        break;
      case 'payment':
        iconData = Icons.payment;
        iconColor = Colors.green;
        break;
      case 'security':
        iconData = Icons.security;
        iconColor = Colors.red;
        break;
      case 'user_activity':
        iconData = Icons.person_outline;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.info;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withAlpha(26),
      child: Icon(iconData, color: iconColor, size: 20.sp),
    );
  }

  Widget _buildMetadataSection() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Details:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp),
          ),
          SizedBox(height: 1.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _formatMetadata(log.metadata!),
              style: TextStyle(fontFamily: 'monospace', fontSize: 10.sp),
            ),
          ),
        ],
      ),
    );
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
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatMetadata(Map<String, dynamic> metadata) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(metadata);
  }
}
