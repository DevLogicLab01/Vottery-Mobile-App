import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PerformanceMetricsWidget extends StatelessWidget {
  const PerformanceMetricsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: const Color(0xFF632CA6), size: 20.sp),
              SizedBox(width: 2.w),
              Text(
                'Performance Metrics',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildLatencyMetrics(),
          SizedBox(height: 2.h),
          _buildLatencyChart(),
          SizedBox(height: 2.h),
          _buildEndpointPerformance(),
        ],
      ),
    );
  }

  Widget _buildLatencyMetrics() {
    final metrics = [
      {'label': 'P50', 'value': '125ms', 'status': 'healthy'},
      {'label': 'P95', 'value': '450ms', 'status': 'healthy'},
      {'label': 'P99', 'value': '890ms', 'status': 'warning'},
      {'label': 'P999', 'value': '1.2s', 'status': 'critical'},
    ];

    return Row(
      children: metrics
          .map(
            (metric) => Expanded(
              child: _buildMetricCard(
                metric['label']!,
                metric['value']!,
                metric['status']!,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildMetricCard(String label, String value, String status) {
    Color statusColor;
    switch (status) {
      case 'healthy':
        statusColor = Colors.green;
        break;
      case 'warning':
        statusColor = Colors.orange;
        break;
      case 'critical':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 1.w),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: statusColor.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatencyChart() {
    return Container(
      height: 25.h,
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}ms',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['12h', '18h', '00h', '06h', '12h'];
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                const FlSpot(0, 120),
                const FlSpot(1, 150),
                const FlSpot(2, 180),
                const FlSpot(3, 140),
                const FlSpot(4, 125),
              ],
              isCurved: true,
              color: const Color(0xFF632CA6),
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF632CA6).withAlpha(26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointPerformance() {
    final endpoints = [
      {
        'path': '/api/vote/cast',
        'p95': '245ms',
        'requests': '1.2K',
        'errors': '0.1%',
        'status': 'healthy',
      },
      {
        'path': '/api/elections/list',
        'p95': '89ms',
        'requests': '3.5K',
        'errors': '0.0%',
        'status': 'healthy',
      },
      {
        'path': '/api/payment/process',
        'p95': '1.2s',
        'requests': '450',
        'errors': '2.1%',
        'status': 'warning',
      },
      {
        'path': '/api/ai/claude/analyze',
        'p95': '890ms',
        'requests': '680',
        'errors': '0.5%',
        'status': 'healthy',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Endpoints',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 1.h),
        ...endpoints.map((endpoint) => _buildEndpointItem(endpoint)),
      ],
    );
  }

  Widget _buildEndpointItem(Map<String, dynamic> endpoint) {
    Color statusColor = endpoint['status'] == 'healthy'
        ? Colors.green
        : endpoint['status'] == 'warning'
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  endpoint['path'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              _buildEndpointMetric('P95', endpoint['p95']),
              SizedBox(width: 2.w),
              _buildEndpointMetric('Requests', endpoint['requests']),
              SizedBox(width: 2.w),
              _buildEndpointMetric('Errors', endpoint['errors']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointMetric(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
