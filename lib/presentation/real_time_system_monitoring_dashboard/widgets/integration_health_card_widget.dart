import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class IntegrationHealthCardWidget extends StatelessWidget {
  final Map<String, dynamic> integration;
  final VoidCallback onTap;

  const IntegrationHealthCardWidget({
    super.key,
    required this.integration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = integration['status'] ?? 'unknown';
    final integrationName = integration['integration_name'] ?? 'Unknown';
    final integrationType = integration['integration_type'] ?? 'Unknown';
    final responseTime = integration['response_time_ms'] ?? 0;
    final uptime = integration['uptime_percentage'] ?? 0.0;
    final errorRate = integration['error_rate'] ?? 0.0;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'healthy':
        statusColor = AppTheme.accentLight;
        statusIcon = Icons.check_circle;
        statusText = 'Healthy';
        break;
      case 'degraded':
        statusColor = AppTheme.warningLight;
        statusIcon = Icons.warning;
        statusText = 'Degraded';
        break;
      case 'down':
        statusColor = AppTheme.errorLight;
        statusIcon = Icons.error;
        statusText = 'Down';
        break;
      case 'maintenance':
        statusColor = Colors.blue;
        statusIcon = Icons.build;
        statusText = 'Maintenance';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Unknown';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          integrationName,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryLight,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          integrationType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 4.w),
                        SizedBox(width: 1.w),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    'Response Time',
                    '${responseTime}ms',
                    Icons.speed,
                    responseTime > 1000
                        ? AppTheme.warningLight
                        : AppTheme.accentLight,
                  ),
                  _buildMetric(
                    'Uptime',
                    '${uptime.toStringAsFixed(2)}%',
                    Icons.trending_up,
                    uptime >= 99.0 ? AppTheme.accentLight : AppTheme.errorLight,
                  ),
                  _buildMetric(
                    'Error Rate',
                    '${errorRate.toStringAsFixed(2)}%',
                    Icons.error_outline,
                    errorRate > 5.0
                        ? AppTheme.errorLight
                        : AppTheme.accentLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 5.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }
}
