import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueBreakdownChartWidget extends StatefulWidget {
  final Map<String, double> revenueBreakdown;
  final Function(String)? onSegmentTap;

  const RevenueBreakdownChartWidget({
    super.key,
    required this.revenueBreakdown,
    this.onSegmentTap,
  });

  @override
  State<RevenueBreakdownChartWidget> createState() =>
      _RevenueBreakdownChartWidgetState();
}

class _RevenueBreakdownChartWidgetState
    extends State<RevenueBreakdownChartWidget> {
  int _touchedIndex = -1;

  static const Map<String, Color> _segmentColors = {
    'SMS Ads': Color(0xFF89B4FA),
    'Elections': Color(0xFFA6E3A1),
    'Marketplace': Color(0xFFCBA6F7),
    'Creator Tiers': Color(0xFFFAB387),
    'Templates': Color(0xFFF5C2E7),
    'Sponsorships': Color(0xFFF9E2AF),
  };

  @override
  Widget build(BuildContext context) {
    final total = widget.revenueBreakdown.values.fold<double>(
      0,
      (sum, v) => sum + v,
    );

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Breakdown',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              SizedBox(
                height: 20.h,
                width: 40.w,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                          final keys = widget.revenueBreakdown.keys.toList();
                          if (_touchedIndex >= 0 &&
                              _touchedIndex < keys.length) {
                            widget.onSegmentTap?.call(keys[_touchedIndex]);
                          }
                        });
                      },
                    ),
                    sections: _buildSections(total),
                    centerSpaceRadius: 35,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.revenueBreakdown.entries
                      .map(
                        (entry) =>
                            _buildLegendItem(entry.key, entry.value, total),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    final keys = widget.revenueBreakdown.keys.toList();
    return List.generate(keys.length, (i) {
      final key = keys[i];
      final value = widget.revenueBreakdown[key] ?? 0;
      final isTouched = i == _touchedIndex;
      final color = _segmentColors[key] ?? Colors.grey;

      return PieChartSectionData(
        color: color,
        value: value,
        title: total > 0
            ? '${(value / total * 100).toStringAsFixed(0)}%'
            : '0%',
        radius: isTouched ? 55 : 45,
        titleStyle: GoogleFonts.inter(
          fontSize: isTouched ? 11.sp : 9.sp,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    });
  }

  Widget _buildLegendItem(String label, double value, double total) {
    final color = _segmentColors[label] ?? Colors.grey;
    final percentage = total > 0 ? (value / total * 100) : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 0.8.h),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          SizedBox(width: 1.5.w),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
