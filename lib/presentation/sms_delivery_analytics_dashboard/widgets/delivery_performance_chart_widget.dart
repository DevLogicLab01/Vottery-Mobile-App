import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';

class DeliveryPerformanceChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> performanceData;

  const DeliveryPerformanceChartWidget({
    required this.performanceData,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (performanceData.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'No delivery data available',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryDark,
            ),
          ),
        ),
      );
    }

    final chartData = _processChartData();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Performance Over Time',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withAlpha(51),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.textSecondaryDark,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= chartData['labels'].length) {
                          return const SizedBox();
                        }
                        return Text(
                          chartData['labels'][value.toInt()],
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: AppTheme.textSecondaryDark,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData['telnyx_spots'],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withAlpha(26),
                    ),
                  ),
                  LineChartBarData(
                    spots: chartData['twilio_spots'],
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.purple.withAlpha(26),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Telnyx', Colors.blue),
              SizedBox(width: 4.w),
              _buildLegendItem('Twilio', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _processChartData() {
    final hourlyData = <String, Map<String, Map<String, int>>>{};

    for (final log in performanceData) {
      final sentAt = DateTime.parse(log['sent_at'] as String);
      final hourKey = DateFormat('HH:mm').format(sentAt);
      final provider = log['provider_used'] as String;
      final status = log['delivery_status'] as String;

      hourlyData.putIfAbsent(hourKey, () => {'telnyx': {}, 'twilio': {}});
      hourlyData[hourKey]![provider]!.putIfAbsent(status, () => 0);
      hourlyData[hourKey]![provider]![status] =
          hourlyData[hourKey]![provider]![status]! + 1;
    }

    final labels = <String>[];
    final telnyxSpots = <FlSpot>[];
    final twilioSpots = <FlSpot>[];

    int index = 0;
    for (final entry in hourlyData.entries) {
      labels.add(entry.key);

      final telnyxData = entry.value['telnyx']!;
      final twilioData = entry.value['twilio']!;

      final telnyxTotal = telnyxData.values.fold(
        0,
        (sum, count) => sum + count,
      );
      final telnyxDelivered = telnyxData['delivered'] ?? 0;
      final telnyxRate = telnyxTotal > 0
          ? (telnyxDelivered / telnyxTotal * 100)
          : 0.0;

      final twilioTotal = twilioData.values.fold(
        0,
        (sum, count) => sum + count,
      );
      final twilioDelivered = twilioData['delivered'] ?? 0;
      final twilioRate = twilioTotal > 0
          ? (twilioDelivered / twilioTotal * 100)
          : 0.0;

      telnyxSpots.add(FlSpot(index.toDouble(), telnyxRate));
      twilioSpots.add(FlSpot(index.toDouble(), twilioRate));

      index++;
    }

    return {
      'labels': labels,
      'telnyx_spots': telnyxSpots,
      'twilio_spots': twilioSpots,
    };
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppTheme.textPrimaryDark),
        ),
      ],
    );
  }
}
