import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class BounceAnalysisWidget extends StatelessWidget {
  final List<Map<String, dynamic>> bounceData;

  const BounceAnalysisWidget({required this.bounceData, super.key});

  @override
  Widget build(BuildContext context) {
    if (bounceData.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green),
              SizedBox(height: 2.h),
              Text(
                'No bounced messages',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textPrimaryDark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bounceReasons = _calculateBounceReasons();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bounce Analysis',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        SizedBox(height: 2.h),
        _buildBounceReasonsPieChart(bounceReasons),
        SizedBox(height: 3.h),
        _buildTopBouncedNumbers(),
      ],
    );
  }

  Widget _buildBounceReasonsPieChart(Map<String, int> reasons) {
    final sections = <PieChartSectionData>[];
    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.purple];

    int colorIndex = 0;
    for (final entry in reasons.entries) {
      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          title: '${entry.value}',
          color: colors[colorIndex % colors.length],
          radius: 50,
          titleStyle: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            'Bounce Reasons Distribution',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 3.w,
            runSpacing: 1.h,
            children: reasons.entries
                .map(
                  (e) => _buildLegendItem(
                    e.key,
                    colors[reasons.keys.toList().indexOf(e.key) %
                        colors.length],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBouncedNumbers() {
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
            'Top Bounced Numbers',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryDark,
            ),
          ),
          SizedBox(height: 2.h),
          ...bounceData.take(10).map((bounce) {
            final phoneNumber = bounce['phone_number'] as String;
            final bounceCount = bounce['bounce_count'] as int;
            final bounceType = bounce['bounce_type'] as String;
            final bounceReason =
                bounce['bounce_reason'] as String? ?? 'Unknown';

            return Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: bounceType == 'hard_bounce'
                      ? Colors.red.withAlpha(77)
                      : Colors.orange.withAlpha(77),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phoneNumber,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryDark,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          bounceReason,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.textSecondaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: bounceType == 'hard_bounce'
                              ? Colors.red
                              : Colors.orange,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          bounceType.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '$bounceCount bounces',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Map<String, int> _calculateBounceReasons() {
    final reasons = <String, int>{};

    for (final bounce in bounceData) {
      final bounceType = bounce['bounce_type'] as String;
      reasons[bounceType] = (reasons[bounceType] ?? 0) + 1;
    }

    return reasons;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.w),
        Text(
          label.replaceAll('_', ' '),
          style: TextStyle(fontSize: 11.sp, color: AppTheme.textPrimaryDark),
        ),
      ],
    );
  }
}
