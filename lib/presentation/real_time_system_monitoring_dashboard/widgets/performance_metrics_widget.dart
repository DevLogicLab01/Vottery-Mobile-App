import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PerformanceMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> latencyStats;
  final Map<String, dynamic> databasePerformance;

  const PerformanceMetricsWidget({
    super.key,
    required this.latencyStats,
    required this.databasePerformance,
  });

  @override
  Widget build(BuildContext context) {
    final avgLatency = latencyStats['average_ms'] ?? 0;
    final p95Latency = latencyStats['p95_ms'] ?? 0;
    final totalRequests = latencyStats['total_requests'] ?? 0;
    final errorCount = latencyStats['error_count'] ?? 0;

    final avgDbTime = databasePerformance['avg_execution_time_ms'] ?? 0;
    final avgConnections = databasePerformance['avg_active_connections'] ?? 0;
    final totalQueries = databasePerformance['total_queries'] ?? 0;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Performance',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn(
                      'Avg Latency',
                      '${avgLatency}ms',
                      avgLatency > 500
                          ? AppTheme.warningLight
                          : AppTheme.accentLight,
                    ),
                    _buildMetricColumn(
                      'P95 Latency',
                      '${p95Latency}ms',
                      p95Latency > 1000
                          ? AppTheme.errorLight
                          : AppTheme.accentLight,
                    ),
                    _buildMetricColumn(
                      'Requests',
                      totalRequests.toString(),
                      AppTheme.primaryLight,
                    ),
                    _buildMetricColumn(
                      'Errors',
                      errorCount.toString(),
                      errorCount > 0
                          ? AppTheme.errorLight
                          : AppTheme.accentLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Database Performance',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn(
                      'Avg Query Time',
                      '${avgDbTime}ms',
                      avgDbTime > 100
                          ? AppTheme.warningLight
                          : AppTheme.accentLight,
                    ),
                    _buildMetricColumn(
                      'Active Connections',
                      avgConnections.toString(),
                      AppTheme.primaryLight,
                    ),
                    _buildMetricColumn(
                      'Total Queries',
                      totalQueries.toString(),
                      AppTheme.primaryLight,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
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
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }
}
