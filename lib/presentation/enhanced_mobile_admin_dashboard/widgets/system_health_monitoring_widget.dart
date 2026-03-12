import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SystemHealthMonitoringWidget extends StatelessWidget {
  final Map<String, dynamic> systemHealth;
  final VoidCallback onRefresh;

  const SystemHealthMonitoringWidget({
    super.key,
    required this.systemHealth,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRefreshInfo(),
            SizedBox(height: 2.h),
            _buildHealthMetrics(),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshInfo() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Icon(Icons.refresh, color: Colors.blue, size: 20.sp),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Auto-refreshing every 15 seconds',
                style: TextStyle(fontSize: 12.sp, color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetrics() {
    final apiLatency = systemHealth['api_latency'] ?? 0;
    final dbLoad = systemHealth['database_load'] ?? 0;
    final activeUsers = systemHealth['active_users'] ?? 0;
    final errorRate = systemHealth['error_rate'] ?? 0;
    final memoryUsage = systemHealth['memory_usage'] ?? 0;
    final cpuUsage = systemHealth['cpu_usage'] ?? 0;

    return Column(
      children: [
        _buildMetricCard(
          'API Latency',
          '${apiLatency}ms',
          Icons.speed,
          _getHealthStatus(apiLatency, 200, 500),
          'Response time for API requests',
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          'Database Load',
          '$dbLoad%',
          Icons.storage,
          _getHealthStatus(dbLoad, 70, 90),
          'Current database utilization',
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          'Active Users',
          activeUsers.toString(),
          Icons.people,
          HealthStatus.healthy,
          'Currently active user sessions',
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          'Error Rate',
          '$errorRate%',
          Icons.error_outline,
          _getHealthStatus(errorRate, 1, 5),
          'Percentage of failed requests',
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          'Memory Usage',
          '$memoryUsage%',
          Icons.memory,
          _getHealthStatus(memoryUsage, 70, 85),
          'Server memory utilization',
        ),
        SizedBox(height: 2.h),
        _buildMetricCard(
          'CPU Usage',
          '$cpuUsage%',
          Icons.developer_board,
          _getHealthStatus(cpuUsage, 70, 85),
          'Server CPU utilization',
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    HealthStatus status,
    String description,
  ) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  HealthStatus _getHealthStatus(num value, num warning, num critical) {
    if (value < warning) return HealthStatus.healthy;
    if (value < critical) return HealthStatus.warning;
    return HealthStatus.critical;
  }

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.warning:
        return Colors.orange;
      case HealthStatus.critical:
        return Colors.red;
    }
  }

  String _getStatusText(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return 'HEALTHY';
      case HealthStatus.warning:
        return 'WARNING';
      case HealthStatus.critical:
        return 'CRITICAL';
    }
  }
}

enum HealthStatus { healthy, warning, critical }
