import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PredictiveScalingWidget extends StatelessWidget {
  const PredictiveScalingWidget({super.key});

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
                Icons.trending_up,
                color: const Color(0xFF632CA6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Predictive Scaling Alerts',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildTrafficForecast(),
          SizedBox(height: 2.h),
          _buildScalingRecommendations(),
        ],
      ),
    );
  }

  Widget _buildTrafficForecast() {
    return Container(
      height: 25.h,
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Traffic Pattern Analysis',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 1.h),
          Expanded(
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
                          '${value.toInt()}K',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Now', '+1h', '+2h', '+3h', '+4h'];
                        if (value.toInt() >= 0 &&
                            value.toInt() < labels.length) {
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
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 12),
                      const FlSpot(1, 15),
                      const FlSpot(2, 22),
                      const FlSpot(3, 28),
                      const FlSpot(4, 32),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withAlpha(26),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 12),
                      const FlSpot(1, 14),
                      const FlSpot(2, 18),
                      const FlSpot(3, 35),
                      const FlSpot(4, 42),
                    ],
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 2,
                    dashArray: [5, 5],
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Current', Colors.blue),
              SizedBox(width: 3.w),
              _buildLegendItem('Forecast', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildScalingRecommendations() {
    final recommendations = [
      {
        'title': 'Scale Up Database Instances',
        'reason': 'Expected 150% traffic increase in 2 hours',
        'action': 'Add 2 read replicas',
        'urgency': 'high',
        'eta': '2h',
      },
      {
        'title': 'Increase Edge Function Concurrency',
        'reason': 'Payment processing load forecast spike',
        'action': 'Scale to 50 concurrent executions',
        'urgency': 'medium',
        'eta': '3h',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scaling Recommendations',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 1.h),
        ...recommendations.map((rec) => _buildRecommendationItem(rec)),
      ],
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    Color urgencyColor = recommendation['urgency'] == 'high'
        ? Colors.red
        : recommendation['urgency'] == 'medium'
        ? Colors.orange
        : Colors.blue;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: urgencyColor.withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: urgencyColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'ETA: ${recommendation['eta']}',
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
                  recommendation['title'],
                  style: TextStyle(
                    fontSize: 13.sp,
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
          Text(
            recommendation['reason'],
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 0.5.h),
          Row(
            children: [
              Icon(Icons.auto_fix_high, size: 14.sp, color: urgencyColor),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  recommendation['action'],
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: urgencyColor,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: urgencyColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Apply',
                  style: TextStyle(fontSize: 11.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
