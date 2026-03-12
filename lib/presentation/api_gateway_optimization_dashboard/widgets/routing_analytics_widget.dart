import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

class RoutingAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;
  final VoidCallback onRefresh;

  const RoutingAnalyticsWidget({
    super.key,
    required this.analytics,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final requestsByZone =
        (analytics['requests_by_zone'] as List<dynamic>?) ?? [];
    final requestsByEndpoint =
        (analytics['requests_by_endpoint'] as List<dynamic>?) ?? [];
    final latencyByZone =
        (analytics['latency_by_zone'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildTrafficDistribution(requestsByZone),
          SizedBox(height: 3.h),
          _buildTopEndpoints(requestsByEndpoint),
          SizedBox(height: 3.h),
          _buildLatencyMetrics(latencyByZone),
        ],
      ),
    );
  }

  Widget _buildTrafficDistribution(List<dynamic> requestsByZone) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Traffic Distribution by Zone',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (requestsByZone.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.h),
                child: Text(
                  'No traffic data available',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 30.h,
              child: PieChart(
                PieChartData(
                  sections: requestsByZone.asMap().entries.map((entry) {
                    final index = entry.key;
                    final zone = entry.value;
                    final zoneName = zone['zone_name'] ?? 'Unknown';
                    final count = (zone['request_count'] ?? 0).toDouble();
                    final colors = [
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                      Colors.red,
                      Colors.teal,
                      Colors.pink,
                      Colors.amber,
                    ];
                    return PieChartSectionData(
                      value: count,
                      title: zoneName,
                      color: colors[index % colors.length],
                      radius: 12.h,
                      titleStyle: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopEndpoints(List<dynamic> requestsByEndpoint) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Endpoints',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (requestsByEndpoint.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.h),
                child: Text(
                  'No endpoint data available',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ...requestsByEndpoint.take(10).map((endpoint) {
              final path = endpoint['endpoint'] ?? 'Unknown';
              final count = endpoint['request_count'] ?? 0;
              final avgLatency = endpoint['avg_latency_ms'] ?? 0;
              final errorRate = endpoint['error_rate'] ?? 0.0;

              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            path,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$count requests',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(Icons.speed, size: 12.sp, color: Colors.blue),
                        SizedBox(width: 1.w),
                        Text(
                          '${avgLatency}ms',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.error_outline,
                          size: 12.sp,
                          color: errorRate > 5 ? Colors.red : Colors.green,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '${errorRate.toStringAsFixed(2)}% errors',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: errorRate > 5 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLatencyMetrics(List<dynamic> latencyByZone) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latency by Zone',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          if (latencyByZone.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(4.h),
                child: Text(
                  'No latency data available',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ...latencyByZone.map((zone) {
              final zoneName = zone['zone_name'] ?? 'Unknown';
              final p50 = zone['p50_latency_ms'] ?? 0;
              final p95 = zone['p95_latency_ms'] ?? 0;
              final p99 = zone['p99_latency_ms'] ?? 0;

              return Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zoneName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Expanded(child: _buildLatencyBadge('P50', p50)),
                        SizedBox(width: 2.w),
                        Expanded(child: _buildLatencyBadge('P95', p95)),
                        SizedBox(width: 2.w),
                        Expanded(child: _buildLatencyBadge('P99', p99)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLatencyBadge(String label, int value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
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
          Text(
            '${value}ms',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
