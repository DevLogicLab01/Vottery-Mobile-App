import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

class GatewayAnalyticsWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const GatewayAnalyticsWidget({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final requestVolume =
        (analytics['request_volume_trends'] as List<dynamic>?) ?? [];
    final anomalies = (analytics['anomalies'] as List<dynamic>?) ?? [];
    final cacheHitRate = analytics['cache_hit_rate'] ?? 0.0;

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
            'Gateway Analytics',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildCacheMetrics(cacheHitRate),
          SizedBox(height: 3.h),
          if (anomalies.isNotEmpty) _buildAnomalies(anomalies),
          if (anomalies.isNotEmpty) SizedBox(height: 3.h),
          if (requestVolume.isNotEmpty) _buildRequestVolumeChart(requestVolume),
        ],
      ),
    );
  }

  Widget _buildCacheMetrics(double hitRate) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(Icons.cached, color: Colors.blue, size: 20.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache Hit Rate',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                Text(
                  '${hitRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalies(List<dynamic> anomalies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 16.sp),
            SizedBox(width: 2.w),
            Text(
              'Detected Anomalies',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ...anomalies.take(3).map((anomaly) {
          final description = anomaly['description'] ?? 'Unknown anomaly';
          final severity = anomaly['severity'] ?? 'medium';
          final severityColor = severity == 'high'
              ? Colors.red
              : severity == 'medium'
              ? Colors.orange
              : Colors.yellow;

          return Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Row(
              children: [
                Container(width: 1.w, height: 5.h, color: severityColor),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRequestVolumeChart(List<dynamic> requestVolume) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request Volume (Last 7 Days)',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 25.h,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: requestVolume.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = (entry.value['request_count'] ?? 0)
                        .toDouble();
                    return FlSpot(index.toDouble(), value);
                  }).toList(),
                  isCurved: true,
                  color: AppTheme.primaryLight,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryLight.withAlpha(51),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
