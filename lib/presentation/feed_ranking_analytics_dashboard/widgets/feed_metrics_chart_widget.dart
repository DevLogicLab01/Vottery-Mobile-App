import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FeedMetricsChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> metrics;

  const FeedMetricsChartWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
          Text(
            'Engagement Trends',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: metrics.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  )
                : LineChart(_buildChartData()),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final sortedMetrics = List<Map<String, dynamic>>.from(metrics)
      ..sort(
        (a, b) => (a['metric_date'] ?? '').compareTo(b['metric_date'] ?? ''),
      );

    final controlData = <FlSpot>[];
    final v1Data = <FlSpot>[];
    final v2Data = <FlSpot>[];

    for (int i = 0; i < sortedMetrics.length; i++) {
      final metric = sortedMetrics[i];
      final group = metric['test_group'] ?? '';
      final engagementRate = (metric['engagement_rate'] ?? 0.0) * 100;

      if (group == 'control') {
        controlData.add(FlSpot(i.toDouble(), engagementRate));
      } else if (group == 'algorithm_v1') {
        v1Data.add(FlSpot(i.toDouble(), engagementRate));
      } else if (group == 'algorithm_v2') {
        v2Data.add(FlSpot(i.toDouble(), engagementRate));
      }
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey[200]!, strokeWidth: 1.0),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              '${value.toInt()}%',
              style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= 0 && value.toInt() < sortedMetrics.length) {
                final date = sortedMetrics[value.toInt()]['metric_date'] ?? '';
                if (date.isNotEmpty) {
                  final parts = date.split('-');
                  if (parts.length >= 2) {
                    return Text(
                      '${parts[1]}/${parts[2]}',
                      style: TextStyle(fontSize: 9.sp, color: Colors.grey[600]),
                    );
                  }
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        if (controlData.isNotEmpty)
          LineChartBarData(
            spots: controlData,
            isCurved: true,
            color: Colors.grey,
            barWidth: 2.0,
            dotData: const FlDotData(show: false),
          ),
        if (v1Data.isNotEmpty)
          LineChartBarData(
            spots: v1Data,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2.0,
            dotData: const FlDotData(show: false),
          ),
        if (v2Data.isNotEmpty)
          LineChartBarData(
            spots: v2Data,
            isCurved: true,
            color: Colors.green,
            barWidth: 2.0,
            dotData: const FlDotData(show: false),
          ),
      ],
    );
  }
}
