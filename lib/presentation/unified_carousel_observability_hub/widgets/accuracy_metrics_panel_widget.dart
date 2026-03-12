import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class AccuracyMetricsPanelWidget extends StatelessWidget {
  final double overallAccuracy;
  final Map<String, double> accuracyByCarousel;
  final List<Map<String, dynamic>> accuracyTrend7d;
  final List<Map<String, dynamic>> accuracyTrend30d;

  const AccuracyMetricsPanelWidget({
    super.key,
    required this.overallAccuracy,
    required this.accuracyByCarousel,
    required this.accuracyTrend7d,
    required this.accuracyTrend30d,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall accuracy
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withAlpha(30),
                  Colors.purple.withAlpha(30),
                ],
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.blue.withAlpha(60)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Accuracy',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '${overallAccuracy.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          color: overallAccuracy >= 70
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      Text(
                        'Engaged / Recommended',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: overallAccuracy / 100,
                        backgroundColor: Colors.grey.withAlpha(50),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          overallAccuracy >= 70 ? Colors.green : Colors.orange,
                        ),
                        strokeWidth: 8,
                      ),
                      Text(
                        '${overallAccuracy.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            'Accuracy by Carousel Type',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          _buildAccuracyBarChart(),
          SizedBox(height: 3.h),
          Text(
            '7-Day Accuracy Trend',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          _buildTrendChart(accuracyTrend7d, Colors.blue),
          SizedBox(height: 2.h),
          Text(
            '30-Day Accuracy Trend',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          _buildTrendChart(accuracyTrend30d, Colors.purple),
          SizedBox(height: 2.h),
          _buildOptimizationInsights(),
        ],
      ),
    );
  }

  Widget _buildAccuracyBarChart() {
    final carousels = [
      MapEntry(
        'Kinetic Spindle',
        accuracyByCarousel['kinetic_spindle'] ?? 72.0,
      ),
      MapEntry('Isometric Deck', accuracyByCarousel['isometric_deck'] ?? 68.0),
      MapEntry('Liquid Horizon', accuracyByCarousel['liquid_horizon'] ?? 75.0),
    ];
    final colors = [Colors.blue, Colors.purple, Colors.teal];

    return SizedBox(
      height: 22.h,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: carousels.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: colors[entry.key],
                  width: 8.w,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  final labels = ['Kinetic', 'Isometric', 'Liquid'];
                  return Text(
                    idx < labels.length ? labels[idx] : '',
                    style: TextStyle(fontSize: 9.sp),
                  );
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) =>
                    Text('${value.toInt()}%', style: TextStyle(fontSize: 8.sp)),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<Map<String, dynamic>> trend, Color color) {
    final spots = trend.isEmpty
        ? List.generate(7, (i) => FlSpot(i.toDouble(), 65.0 + i * 1.5))
        : trend.asMap().entries.map((e) {
            final acc = (e.value['accuracy'] ?? 70.0).toDouble();
            return FlSpot(e.key.toDouble(), acc);
          }).toList();

    return SizedBox(
      height: 15.h,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: color.withAlpha(30)),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) =>
                    Text('${value.toInt()}%', style: TextStyle(fontSize: 8.sp)),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }

  Widget _buildOptimizationInsights() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.amber.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 4.w),
              SizedBox(width: 2.w),
              Text(
                'Optimization Insights',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          _buildInsightRow(
            'Liquid Horizon shows highest accuracy — prioritize for new users',
          ),
          _buildInsightRow(
            'Isometric Deck accuracy below 70% — review content matching algorithm',
          ),
          _buildInsightRow(
            'Increase recommendation diversity to improve engagement signals',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.amber[800]),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
