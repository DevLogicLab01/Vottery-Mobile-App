import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

/// Adoption Trends Panel - Line chart showing 7-day and 30-day adoption rates
class AdoptionTrendsPanelWidget extends StatefulWidget {
  final Map<String, List<double>> adoptionTrends;

  const AdoptionTrendsPanelWidget({super.key, required this.adoptionTrends});

  @override
  State<AdoptionTrendsPanelWidget> createState() =>
      _AdoptionTrendsPanelWidgetState();
}

class _AdoptionTrendsPanelWidgetState extends State<AdoptionTrendsPanelWidget> {
  bool _show7Day = true;

  @override
  Widget build(BuildContext context) {
    final data = _show7Day
        ? (widget.adoptionTrends['7_day'] ?? [])
        : (widget.adoptionTrends['30_day'] ?? []);
    final maxY = data.isEmpty
        ? 100.0
        : data.reduce((a, b) => a > b ? a : b) * 1.2;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Adoption Trends',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              _buildToggle('7D', true),
              SizedBox(width: 2.w),
              _buildToggle('30D', false),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            _show7Day
                ? '7-day AI feature adoption rates'
                : '30-day AI feature adoption rates',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: AppTheme.primaryLight,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryLight.withAlpha(40),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 10.w,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _show7Day ? 1 : 5,
                      getTitlesWidget: (value, meta) => Text(
                        'D${value.toInt() + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
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
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.withAlpha(40), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          _buildTrendSummary(data),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, bool is7Day) {
    final isSelected = _show7Day == is7Day;
    return GestureDetector(
      onTap: () => setState(() => _show7Day = is7Day),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: AppTheme.primaryLight),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.primaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendSummary(List<double> data) {
    if (data.length < 2) return const SizedBox();
    final avg = data.reduce((a, b) => a + b) / data.length;
    final trend = data.last > data.first ? 'Increasing' : 'Decreasing';
    final trendColor = data.last > data.first ? Colors.green : Colors.red;
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: trendColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: trendColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(
            data.last > data.first ? Icons.trending_up : Icons.trending_down,
            color: trendColor,
            size: 5.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trend: $trend',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: trendColor,
                  ),
                ),
                Text(
                  'Average: ${avg.toStringAsFixed(0)} events/day',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
