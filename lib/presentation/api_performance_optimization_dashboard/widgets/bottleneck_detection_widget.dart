import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class BottleneckDetectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> bottlenecks;

  const BottleneckDetectionWidget({super.key, required this.bottlenecks});

  @override
  Widget build(BuildContext context) {
    if (bottlenecks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 15.w,
              color: Colors.green.withAlpha(128),
            ),
            SizedBox(height: 2.h),
            Text(
              'No bottlenecks detected',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: bottlenecks.length,
      itemBuilder: (context, index) {
        final bottleneck = bottlenecks[index];
        return _buildBottleneckCard(bottleneck);
      },
    );
  }

  Widget _buildBottleneckCard(Map<String, dynamic> bottleneck) {
    final type = bottleneck['type'] ?? '';
    final endpoint = bottleneck['endpoint'] ?? '';
    final query = bottleneck['query'] ?? '';
    final avgExecutionTime = bottleneck['avg_execution_time'] ?? 0;
    final frequency = bottleneck['frequency'] ?? 0;
    final rootCause = bottleneck['root_cause'] ?? '';
    final recommendation = bottleneck['recommendation'] ?? '';
    final severity = bottleneck['severity'] ?? 'low';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getSeverityColor(severity).withAlpha(77),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _getTypeIcon(type),
                      size: 5.w,
                      color: _getSeverityColor(severity),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _formatType(type),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _buildInfoRow(icon: Icons.link, label: 'Endpoint', value: endpoint),
          SizedBox(height: 1.h),
          _buildInfoRow(
            icon: Icons.timer,
            label: 'Avg Execution Time',
            value: '${avgExecutionTime}ms',
          ),
          SizedBox(height: 1.h),
          _buildInfoRow(
            icon: Icons.repeat,
            label: 'Frequency',
            value: '$frequency requests/min',
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.code,
                      size: 4.w,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Query',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  query,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontFamily: 'monospace',
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.red.withAlpha(51), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, size: 4.w, color: Colors.red),
                    SizedBox(width: 1.w),
                    Text(
                      'Root Cause',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  rootCause,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(13),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.green.withAlpha(51), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 4.w,
                      color: Colors.green,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Recommendation',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Text(
                  recommendation,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 4.w, color: AppTheme.textSecondaryLight),
        SizedBox(width: 2.w),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'slow_query':
        return Icons.hourglass_empty;
      case 'n_plus_one':
        return Icons.loop;
      case 'large_payload':
        return Icons.cloud_download;
      default:
        return Icons.error_outline;
    }
  }

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'medium':
      case 'warning':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
