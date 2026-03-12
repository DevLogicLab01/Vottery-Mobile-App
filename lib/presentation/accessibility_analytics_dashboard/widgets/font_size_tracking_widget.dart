import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class FontSizeTrackingWidget extends StatelessWidget {
  final Map<String, dynamic> fontSizeData;

  const FontSizeTrackingWidget({super.key, required this.fontSizeData});

  @override
  Widget build(BuildContext context) {
    final small = fontSizeData['small'] ?? 0.0;
    final medium = fontSizeData['medium'] ?? 0.0;
    final large = fontSizeData['large'] ?? 0.0;
    final extraLarge = fontSizeData['extra_large'] ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Font Size Selection Tracking',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          Text(
            'GA4 custom events tracking font size adjustment frequency',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
          SizedBox(height: 3.h),
          _buildFontSizeCard('Small (0.8x)', small, Colors.blue),
          SizedBox(height: 2.h),
          _buildFontSizeCard('Medium (1.0x)', medium, Colors.green),
          SizedBox(height: 2.h),
          _buildFontSizeCard('Large (1.1x)', large, Colors.orange),
          SizedBox(height: 2.h),
          _buildFontSizeCard('Extra Large (1.2x)', extraLarge, Colors.red),
          SizedBox(height: 3.h),
          _buildDistributionChart(small, medium, large, extraLarge),
        ],
      ),
    );
  }

  Widget _buildFontSizeCard(String label, double percentage, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 1.h,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart(
    double small,
    double medium,
    double large,
    double extraLarge,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribution Chart',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              height: 25.h,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: small,
                      title: '${small.toStringAsFixed(1)}%',
                      color: Colors.blue,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: medium,
                      title: '${medium.toStringAsFixed(1)}%',
                      color: Colors.green,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: large,
                      title: '${large.toStringAsFixed(1)}%',
                      color: Colors.orange,
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: extraLarge,
                      title: '${extraLarge.toStringAsFixed(1)}%',
                      color: Colors.red,
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
