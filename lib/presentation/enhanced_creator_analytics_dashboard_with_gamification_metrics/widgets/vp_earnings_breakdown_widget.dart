import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class VPEarningsBreakdownWidget extends StatefulWidget {
  final Map<String, dynamic> earningsData;

  const VPEarningsBreakdownWidget({super.key, required this.earningsData});

  @override
  State<VPEarningsBreakdownWidget> createState() =>
      _VPEarningsBreakdownWidgetState();
}

class _VPEarningsBreakdownWidgetState extends State<VPEarningsBreakdownWidget> {
  String _selectedPeriod = 'monthly';

  @override
  Widget build(BuildContext context) {
    final bySource =
        widget.earningsData['by_source'] as Map<String, int>? ?? {};
    final daily = widget.earningsData['daily'] as int? ?? 0;
    final weekly = widget.earningsData['weekly'] as int? ?? 0;
    final monthly = widget.earningsData['monthly'] as int? ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period selector
          Row(
            children: [
              _buildPeriodChip('Daily', 'daily', daily),
              SizedBox(width: 2.w),
              _buildPeriodChip('Weekly', 'weekly', weekly),
              SizedBox(width: 2.w),
              _buildPeriodChip('Monthly', 'monthly', monthly),
            ],
          ),
          SizedBox(height: 3.h),

          // VP by source pie chart
          Text(
            'VP Earnings by Source',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: bySource.isEmpty
                ? Center(
                    child: Text(
                      'No VP earnings yet',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(bySource),
                      centerSpaceRadius: 12.w,
                      sectionsSpace: 2,
                    ),
                  ),
          ),
          SizedBox(height: 3.h),

          // Source breakdown list
          _buildSourceCard(
            'Elections',
            bySource['elections'] ?? 0,
            '10 VP per vote',
            Icons.how_to_vote,
            AppTheme.primaryLight,
          ),
          SizedBox(height: 2.h),
          _buildSourceCard(
            'Ads',
            bySource['ads'] ?? 0,
            '5 VP per interaction',
            Icons.ads_click,
            Colors.orange,
          ),
          SizedBox(height: 2.h),
          _buildSourceCard(
            'Jolts',
            bySource['jolts'] ?? 0,
            '50 VP per creation',
            Icons.video_library,
            Colors.purple,
          ),
          SizedBox(height: 2.h),
          _buildSourceCard(
            'Predictions',
            bySource['predictions'] ?? 0,
            'Up to 1000 VP for accuracy',
            Icons.psychology,
            Colors.green,
          ),
          SizedBox(height: 2.h),
          _buildSourceCard(
            'Social',
            bySource['social'] ?? 0,
            '5 VP per like',
            Icons.favorite,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value, int vpAmount) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryLight : Colors.grey[200],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textSecondaryLight,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                '$vpAmount VP',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<String, int> bySource) {
    final total = bySource.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return [];

    final colors = {
      'elections': AppTheme.primaryLight,
      'ads': Colors.orange,
      'jolts': Colors.purple,
      'predictions': Colors.green,
      'social': Colors.red,
    };

    return bySource.entries.map((entry) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '$percentage%',
        color: colors[entry.key] ?? Colors.grey,
        radius: 15.w,
        titleStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildSourceCard(
    String title,
    int vpAmount,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: color, size: 6.w),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$vpAmount VP',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
