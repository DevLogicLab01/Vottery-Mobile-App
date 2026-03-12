import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class CarouselPerformancePanelWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const CarouselPerformancePanelWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final carousels = [
      {
        'name': 'Kinetic Spindle',
        'key': 'kinetic_spindle',
        'color': Colors.blue,
      },
      {
        'name': 'Isometric Deck',
        'key': 'isometric_deck',
        'color': Colors.purple,
      },
      {'name': 'Liquid Horizon', 'key': 'liquid_horizon', 'color': Colors.teal},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Metrics',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...carousels.map(
            (carousel) => _buildCarouselCard(
              carousel['name'] as String,
              carousel['key'] as String,
              carousel['color'] as Color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Rendering Performance',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          _buildRenderingPerformanceChart(),
        ],
      ),
    );
  }

  Widget _buildCarouselCard(String name, String key, Color color) {
    final data = metrics[key] as Map<String, dynamic>? ?? {};
    final swipeRate = (data['swipe_rate'] ?? 0.0).toDouble();
    final tapRate = (data['tap_rate'] ?? 0.0).toDouble();
    final timeSpent = (data['time_spent_seconds'] ?? 0.0).toDouble();
    final fps = (data['fps'] ?? 60.0).toDouble();
    final frameDrops = (data['frame_drops'] ?? 0).toInt();
    final memoryMb = (data['memory_mb'] ?? 0.0).toDouble();

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3.w,
                height: 3.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              SizedBox(width: 2.w),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Swipe Rate',
                  '${swipeRate.toStringAsFixed(1)}%',
                  Icons.swipe,
                  color,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Tap Rate',
                  '${tapRate.toStringAsFixed(1)}%',
                  Icons.touch_app,
                  color,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Time Spent',
                  '${timeSpent.toStringAsFixed(0)}s',
                  Icons.timer,
                  color,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'FPS',
                  fps.toStringAsFixed(0),
                  Icons.speed,
                  fps >= 55 ? Colors.green : Colors.red,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Frame Drops',
                  frameDrops.toString(),
                  Icons.warning_amber,
                  frameDrops < 5 ? Colors.green : Colors.orange,
                ),
              ),
              Expanded(
                child: _buildMetricTile(
                  'Memory',
                  '${memoryMb.toStringAsFixed(0)}MB',
                  Icons.memory,
                  memoryMb < 100 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 4.w),
        SizedBox(height: 0.3.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildRenderingPerformanceChart() {
    final carouselNames = ['Kinetic', 'Isometric', 'Liquid'];
    final keys = ['kinetic_spindle', 'isometric_deck', 'liquid_horizon'];
    final colors = [Colors.blue, Colors.purple, Colors.teal];

    return SizedBox(
      height: 25.h,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 70,
          barGroups: List.generate(3, (i) {
            final data = metrics[keys[i]] as Map<String, dynamic>? ?? {};
            final fps = (data['fps'] ?? 60.0).toDouble();
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: fps,
                  color: colors[i],
                  width: 8.w,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  return Text(
                    idx < carouselNames.length ? carouselNames[idx] : '',
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
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 8.sp),
                ),
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
}
