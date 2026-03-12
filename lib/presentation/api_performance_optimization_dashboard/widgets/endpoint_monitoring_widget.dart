import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EndpointMonitoringWidget extends StatelessWidget {
  final List<Map<String, dynamic>> endpoints;

  const EndpointMonitoringWidget({super.key, required this.endpoints});

  @override
  Widget build(BuildContext context) {
    if (endpoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.api,
              size: 15.w,
              color: AppTheme.textSecondaryLight.withAlpha(128),
            ),
            SizedBox(height: 2.h),
            Text(
              'No endpoint data available',
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
      itemCount: endpoints.length,
      itemBuilder: (context, index) {
        final endpoint = endpoints[index];
        return _buildEndpointCard(endpoint);
      },
    );
  }

  Widget _buildEndpointCard(Map<String, dynamic> endpoint) {
    final endpointPath = endpoint['endpoint'] ?? '';
    final avgResponseTime = endpoint['avg_response_time'] ?? 0;
    final p50 = endpoint['p50'] ?? 0;
    final p95 = endpoint['p95'] ?? 0;
    final p99 = endpoint['p99'] ?? 0;
    final requestsPerMin = endpoint['requests_per_min'] ?? 0;
    final errorRate = endpoint['error_rate'] ?? 0.0;
    final status = endpoint['status'] ?? 'unknown';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getStatusColor(status).withAlpha(77),
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
                child: Text(
                  endpointPath,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  status.toUpperCase(),
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
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  label: 'Avg Response',
                  value: '${avgResponseTime}ms',
                  icon: Icons.timer,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  label: 'Requests/min',
                  value: requestsPerMin.toString(),
                  icon: Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildMetric(
                  label: 'Error Rate',
                  value: '${errorRate.toStringAsFixed(1)}%',
                  icon: Icons.error_outline,
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
                Text(
                  'Percentile Analysis',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPercentile('P50', p50),
                    _buildPercentile('P95', p95),
                    _buildPercentile('P99', p99),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 3.w, color: AppTheme.textSecondaryLight),
            SizedBox(width: 1.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentile(String label, int value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          '${value}ms',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryLight,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
