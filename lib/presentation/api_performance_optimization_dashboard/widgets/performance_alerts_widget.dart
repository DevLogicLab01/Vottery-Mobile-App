import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PerformanceAlertsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;

  const PerformanceAlertsWidget({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
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
              'No active performance alerts',
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
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return _buildAlertCard(context, alert);
      },
    );
  }

  Widget _buildAlertCard(BuildContext context, Map<String, dynamic> alert) {
    final alertType = alert['alert_type'] ?? '';
    final endpoint = alert['endpoint'] ?? '';
    final metric = alert['metric'] ?? '';
    final threshold = alert['threshold'] ?? 0;
    final currentValue = alert['current_value'] ?? 0;
    final severity = alert['severity'] ?? 'low';
    final triggeredAt = alert['triggered_at'] as DateTime?;
    final escalationStatus = alert['escalation_status'] ?? 'pending';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getSeverityColor(severity).withAlpha(77),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _getSeverityColor(severity).withAlpha(26),
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
                      Icons.warning_amber_rounded,
                      size: 6.w,
                      color: _getSeverityColor(severity),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        _formatAlertType(alertType),
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
                _buildInfoRow(
                  icon: Icons.link,
                  label: 'Endpoint',
                  value: endpoint,
                ),
                SizedBox(height: 1.h),
                _buildInfoRow(
                  icon: Icons.analytics,
                  label: 'Metric',
                  value: _formatMetric(metric),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _buildThresholdCard(
                  label: 'Threshold',
                  value: _formatValue(metric, threshold),
                  color: Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildThresholdCard(
                  label: 'Current',
                  value: _formatValue(metric, currentValue),
                  color: _getSeverityColor(severity),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _getEscalationColor(escalationStatus).withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _getEscalationColor(escalationStatus).withAlpha(77),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getEscalationIcon(escalationStatus),
                      size: 4.w,
                      color: _getEscalationColor(escalationStatus),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Escalation: ${_formatEscalationStatus(escalationStatus)}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: _getEscalationColor(escalationStatus),
                      ),
                    ),
                  ],
                ),
                if (triggeredAt != null)
                  Text(
                    _formatTimestamp(triggeredAt),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _acknowledgeAlert(context, alert);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Acknowledge'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _resolveAlert(context, alert);
                  },
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Resolve'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildThresholdCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(77), width: 1.0),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _acknowledgeAlert(BuildContext context, Map<String, dynamic> alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert acknowledged: ${alert['endpoint']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _resolveAlert(BuildContext context, Map<String, dynamic> alert) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert resolved: ${alert['endpoint']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatAlertType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatMetric(String metric) {
    return metric
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatValue(String metric, dynamic value) {
    if (metric.contains('time')) {
      return '${value}ms';
    } else if (metric.contains('rate')) {
      return '$value%';
    }
    return value.toString();
  }

  String _formatEscalationStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }

  IconData _getEscalationIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'acknowledged':
        return Icons.check_circle_outline;
      case 'resolved':
        return Icons.done_all;
      default:
        return Icons.info_outline;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getEscalationColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'acknowledged':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
