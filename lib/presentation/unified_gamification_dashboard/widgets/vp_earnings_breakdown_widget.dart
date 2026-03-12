import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

/// VP Earnings Breakdown Widget
/// Displays daily/weekly/monthly VP earnings by source with interactive charts
class VPEarningsBreakdownWidget extends StatefulWidget {
  final List<Map<String, dynamic>> earningsData;

  const VPEarningsBreakdownWidget({super.key, required this.earningsData});

  @override
  State<VPEarningsBreakdownWidget> createState() =>
      _VPEarningsBreakdownWidgetState();
}

class _VPEarningsBreakdownWidgetState extends State<VPEarningsBreakdownWidget> {
  String _selectedPeriod = 'weekly';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredData = _filterDataByPeriod();
    final sourceBreakdown = _calculateSourceBreakdown(filteredData);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Earnings by Source',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              _buildPeriodSelector(theme),
            ],
          ),
          SizedBox(height: 2.h),

          // Pie Chart
          SizedBox(
            height: 25.h,
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(sourceBreakdown, theme),
                centerSpaceRadius: 8.h,
                sectionsSpace: 2,
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Legend
          _buildLegend(sourceBreakdown, theme),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return Row(
      children: ['daily', 'weekly', 'monthly'].map((period) {
        final isSelected = _selectedPeriod == period;
        return GestureDetector(
          onTap: () => setState(() => _selectedPeriod = period),
          child: Container(
            margin: EdgeInsets.only(left: 1.w),
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
              ),
            ),
            child: Text(
              period[0].toUpperCase() + period.substring(1),
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _filterDataByPeriod() {
    final now = DateTime.now();
    final cutoffDate = _selectedPeriod == 'daily'
        ? now.subtract(const Duration(days: 1))
        : _selectedPeriod == 'weekly'
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    return widget.earningsData.where((item) {
      final createdAt = DateTime.parse(item['created_at'] as String);
      return createdAt.isAfter(cutoffDate);
    }).toList();
  }

  Map<String, int> _calculateSourceBreakdown(List<Map<String, dynamic>> data) {
    final breakdown = <String, int>{
      'Voting': 0,
      'Ads': 0,
      'Predictions': 0,
      'Challenges': 0,
      'Social': 0,
    };

    for (var item in data) {
      final source = item['reference_type'] as String?;
      final amount = item['amount'] as int? ?? 0;

      if (source == 'election' || source == 'voting') {
        breakdown['Voting'] = (breakdown['Voting'] ?? 0) + amount;
      } else if (source == 'ad_interaction') {
        breakdown['Ads'] = (breakdown['Ads'] ?? 0) + amount;
      } else if (source == 'prediction') {
        breakdown['Predictions'] = (breakdown['Predictions'] ?? 0) + amount;
      } else if (source == 'challenge') {
        breakdown['Challenges'] = (breakdown['Challenges'] ?? 0) + amount;
      } else if (source?.contains('social') ?? false) {
        breakdown['Social'] = (breakdown['Social'] ?? 0) + amount;
      }
    }

    return breakdown;
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, int> breakdown,
    ThemeData theme,
  ) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];

    final total = breakdown.values.fold<int>(0, (sum, val) => sum + val);
    if (total == 0) return [];

    int colorIndex = 0;
    return breakdown.entries.map((entry) {
      final percentage = (entry.value / total * 100).toStringAsFixed(1);
      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '$percentage%',
        color: color,
        radius: 8.h,
        titleStyle: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, int> breakdown, ThemeData theme) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];

    int colorIndex = 0;
    return Wrap(
      spacing: 2.w,
      runSpacing: 1.h,
      children: breakdown.entries.map((entry) {
        final color = colors[colorIndex % colors.length];
        colorIndex++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3.w,
              height: 3.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 1.w),
            Text(
              '${entry.key}: ${entry.value} VP',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
