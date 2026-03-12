import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ErrorRateTrackingWidget extends StatelessWidget {
  const ErrorRateTrackingWidget({super.key});

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
              Icon(
                Icons.error_outline,
                color: const Color(0xFF632CA6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Error Rate Tracking',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildErrorRateChart(),
          SizedBox(height: 2.h),
          _buildAnomalyAlerts(),
        ],
      ),
    );
  }

  Widget _buildErrorRateChart() {
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
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['00:00', '06:00', '12:00', '18:00', '24:00'];
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
                const FlSpot(0, 0.5),
                const FlSpot(1, 0.8),
                const FlSpot(2, 2.1),
                const FlSpot(3, 1.2),
                const FlSpot(4, 0.6),
              ],
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withAlpha(26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyAlerts() {
    final anomalies = [
      {
        'endpoint': '/api/payment/process',
        'errorRate': '2.1%',
        'baseline': '0.5%',
        'spike': '+320%',
        'timestamp': '14:32',
        'severity': 'critical',
      },
      {
        'endpoint': '/api/vote/cast',
        'errorRate': '1.2%',
        'baseline': '0.3%',
        'spike': '+300%',
        'timestamp': '15:18',
        'severity': 'warning',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.red, size: 18.sp),
            SizedBox(width: 2.w),
            Text(
              'Anomaly Alerts',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ...anomalies.map((anomaly) => _buildAnomalyItem(anomaly)),
      ],
    );
  }

  Widget _buildAnomalyItem(Map<String, dynamic> anomaly) {
    Color severityColor = anomaly['severity'] == 'critical'
        ? Colors.red
        : anomaly['severity'] == 'warning'
        ? Colors.orange
        : Colors.yellow.shade700;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: severityColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: severityColor.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  anomaly['severity'].toUpperCase(),
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  anomaly['endpoint'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                anomaly['timestamp'],
                style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildAnomalyMetric('Error Rate', anomaly['errorRate']),
              SizedBox(width: 2.w),
              _buildAnomalyMetric('Baseline', anomaly['baseline']),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'Spike: ${anomaly['spike']}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyMetric(String label, String value) {
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
