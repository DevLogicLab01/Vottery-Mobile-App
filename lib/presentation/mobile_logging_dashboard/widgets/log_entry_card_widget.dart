import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../models/platform_log.dart';

class LogEntryCardWidget extends StatelessWidget {
  final PlatformLog log;

  const LogEntryCardWidget({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 2.h),
      child: ExpansionTile(
        leading: _buildLogIcon(),
        title: Text(
          log.message,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
        ),
        subtitle: Text(_formatTimestamp(log.createdAt)),
        trailing: _buildLogLevelChip(),
        children: [
          if (log.metadata != null && log.metadata!.isNotEmpty)
            _buildMetadataSection(),
        ],
      ),
    );
  }

  Widget _buildLogIcon() {
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
      case 'ai_analysis':
        iconData = Icons.psychology;
        iconColor = Colors.purple;
        break;
      case 'performance':
        iconData = Icons.speed;
        iconColor = Colors.orange;
        break;
      case 'fraud_detection':
        iconData = Icons.warning;
        iconColor = Colors.red[700]!;
        break;
      case 'system':
        iconData = Icons.settings;
        iconColor = Colors.grey[700]!;
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

  Widget _buildLogLevelChip() {
    Color chipColor;
    switch (log.logLevel) {
      case 'critical':
        chipColor = Colors.red;
        break;
      case 'error':
        chipColor = Colors.orange;
        break;
      case 'warn':
        chipColor = Colors.yellow[700]!;
        break;
      case 'info':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        log.logLevel.toUpperCase(),
        style: TextStyle(color: Colors.white, fontSize: 10.sp),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildMetadataSection() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details:',
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
