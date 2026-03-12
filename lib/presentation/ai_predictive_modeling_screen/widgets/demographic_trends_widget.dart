import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Demographic Trends Widget
/// Displays demographic shift analysis with trend indicators
class DemographicTrendsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;

  const DemographicTrendsWidget({super.key, required this.shifts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_flat,
              size: 15.w,
              color: Colors.grey.withAlpha(77),
            ),
            SizedBox(height: 2.h),
            Text(
              'No Demographic Shifts Detected',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Demographic Shift Analysis',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Comparing current to historical baseline',
          style: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        SizedBox(height: 2.h),
        ...shifts.map((shift) => _buildShiftCard(shift, theme)),
      ],
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift, ThemeData theme) {
    final category = shift['demographic_category'] ?? 'Unknown';
    final baseline = shift['baseline_percentage'] ?? 0.0;
    final current = shift['current_percentage'] ?? 0.0;
    final shiftPercentage = shift['shift_percentage'] ?? 0.0;
    final direction = shift['shift_direction'] ?? 'stable';

    final isIncrease = direction == 'increase';
    final isDecrease = direction == 'decrease';
    final color = isIncrease
        ? Colors.green
        : isDecrease
        ? Colors.red
        : Colors.grey;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: theme.colorScheme.outline.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatCategory(category),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      isIncrease
                          ? Icons.trending_up
                          : isDecrease
                          ? Icons.trending_down
                          : Icons.trending_flat,
                      color: color,
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${shiftPercentage >= 0 ? '+' : ''}${shiftPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildPercentageBar(
                  'Baseline',
                  baseline,
                  Colors.grey,
                  theme,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildPercentageBar('Current', current, color, theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageBar(
    String label,
    double percentage,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        SizedBox(height: 0.5.h),
        Stack(
          children: [
            Container(
              height: 1.h,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 1.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _formatCategory(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
