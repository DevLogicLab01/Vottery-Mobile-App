import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ErrorTrackingTabWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const ErrorTrackingTabWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by parent
      },
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildErrorSummary(),
          SizedBox(height: 2.h),
          _buildRecentErrors(),
          SizedBox(height: 2.h),
          _buildErrorTrends(),
          SizedBox(height: 2.h),
          _buildAlertConfiguration(),
        ],
      ),
    );
  }

  Widget _buildErrorSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error Overview',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Errors',
                    '${data['total_errors'] ?? 0}',
                    Icons.error_outline,
                    AppTheme.warningLight,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildSummaryCard(
                    'Critical',
                    '${data['critical_errors'] ?? 0}',
                    Icons.error,
                    AppTheme.errorLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Error Rate',
                    '${((data['error_rate'] ?? 0) * 100).toStringAsFixed(2)}%',
                    Icons.trending_up,
                    AppTheme.secondaryLight,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildSummaryCard(
                    'Crash-Free',
                    '${((data['crash_free_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    AppTheme.accentLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentErrors() {
    final errors = data['recent_errors'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Errors',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  '${data['affected_users'] ?? 0} users affected',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            ...errors.map((error) => _buildErrorCard(error)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(Map<String, dynamic> error) {
    final severity = error['severity'] as String;
    final timestamp = error['timestamp'] as DateTime;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _getSeverityColor(severity).withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: _getSeverityColor(severity).withAlpha(77),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  severity.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  error['message'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: AppTheme.textSecondaryLight,
              ),
              SizedBox(width: 1.w),
              Text(
                DateFormat('MMM dd, HH:mm').format(timestamp),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.repeat, size: 14, color: AppTheme.textSecondaryLight),
              SizedBox(width: 1.w),
              Text(
                '${error['count']} occurrences',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.people, size: 14, color: AppTheme.textSecondaryLight),
              SizedBox(width: 1.w),
              Text(
                '${error['affected_users']} users',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              error['stack_trace'] as String,
              style: TextStyle(
                fontSize: 9.sp,
                fontFamily: 'monospace',
                color: AppTheme.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTrends() {
    final trends = data['error_trends'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error Trends (Last 4 Days)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trends.map((trend) {
                  final count = trend['count'] as int;
                  final maxCount = trends
                      .map((t) => t['count'] as int)
                      .reduce((a, b) => a > b ? a : b);
                  final height = (count / maxCount) * 120;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Container(
                        width: 15.w,
                        height: height,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryLight,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        (trend['date'] as String).substring(8),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertConfiguration() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Configuration',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            _buildAlertSetting(
              'Critical Errors',
              'Immediate notification',
              true,
              AppTheme.errorLight,
            ),
            _buildAlertSetting(
              'AI Service Failures',
              'Alert after 3 consecutive failures',
              true,
              AppTheme.warningLight,
            ),
            _buildAlertSetting(
              'Performance Degradation',
              'Alert when latency > 2s',
              true,
              AppTheme.secondaryLight,
            ),
            _buildAlertSetting(
              'Error Rate Spike',
              'Alert when rate increases > 50%',
              false,
              AppTheme.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertSetting(
    String title,
    String description,
    bool enabled,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.notifications_active : Icons.notifications_off,
            color: color,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) {
              // Handle alert configuration
            },
            activeThumbColor: AppTheme.accentLight,
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppTheme.errorLight;
      case 'error':
        return AppTheme.warningLight;
      case 'warning':
        return AppTheme.vibrantYellow;
      default:
        return AppTheme.textSecondaryLight;
    }
  }
}
