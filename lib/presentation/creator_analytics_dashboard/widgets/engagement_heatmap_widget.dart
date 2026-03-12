import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class EngagementHeatmapWidget extends StatelessWidget {
  const EngagementHeatmapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engagement Heatmap',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        _buildInteractionTimingCard(theme),
        SizedBox(height: 2.h),
        _buildContentPreferencesCard(theme),
        SizedBox(height: 2.h),
        _buildGeographicDistributionCard(theme),
      ],
    );
  }

  Widget _buildInteractionTimingCard(ThemeData theme) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hours = ['12AM', '6AM', '12PM', '6PM'];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interaction Timing',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              SizedBox(width: 12.w),
              ...hours.map(
                (hour) => Expanded(
                  child: Center(
                    child: Text(
                      hour,
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          ...days.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 12.w,
                    child: Text(
                      entry.value,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ...List.generate(4, (index) {
                    final intensity = (entry.key + index) % 4;
                    return Expanded(
                      child: Container(
                        height: 4.h,
                        margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                        decoration: BoxDecoration(
                          color: _getHeatmapColor(intensity),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(theme, 'Low', _getHeatmapColor(0)),
              SizedBox(width: 2.w),
              _buildLegendItem(theme, 'Medium', _getHeatmapColor(1)),
              SizedBox(width: 2.w),
              _buildLegendItem(theme, 'High', _getHeatmapColor(2)),
              SizedBox(width: 2.w),
              _buildLegendItem(theme, 'Peak', _getHeatmapColor(3)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHeatmapColor(int intensity) {
    switch (intensity) {
      case 0:
        return Colors.green.shade100;
      case 1:
        return Colors.green.shade300;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return Colors.red.shade600;
      default:
        return Colors.grey.shade200;
    }
  }

  Widget _buildLegendItem(ThemeData theme, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildContentPreferencesCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content Type Preferences',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildPreferenceBar(theme, 'Jolts (Videos)', 45, Colors.purple),
          SizedBox(height: 1.h),
          _buildPreferenceBar(theme, 'Elections', 30, Colors.blue),
          SizedBox(height: 1.h),
          _buildPreferenceBar(theme, 'Posts', 15, Colors.green),
          SizedBox(height: 1.h),
          _buildPreferenceBar(theme, 'Moments', 10, AppTheme.vibrantYellow),
        ],
      ),
    );
  }

  Widget _buildPreferenceBar(
    ThemeData theme,
    String label,
    int percentage,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 1.h,
          ),
        ),
      ],
    );
  }

  Widget _buildGeographicDistributionCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Geographic Distribution',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildLocationItem(theme, 'United States', 42, Icons.flag, 1),
          SizedBox(height: 1.h),
          _buildLocationItem(theme, 'United Kingdom', 18, Icons.flag, 2),
          SizedBox(height: 1.h),
          _buildLocationItem(theme, 'Canada', 12, Icons.flag, 3),
          SizedBox(height: 1.h),
          _buildLocationItem(theme, 'Australia', 10, Icons.flag, 4),
          SizedBox(height: 1.h),
          _buildLocationItem(theme, 'Others', 18, Icons.public, 5),
        ],
      ),
    );
  }

  Widget _buildLocationItem(
    ThemeData theme,
    String location,
    int percentage,
    IconData icon,
    int rank,
  ) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$rank',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Icon(icon, color: theme.colorScheme.onSurfaceVariant, size: 5.w),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            location,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          '$percentage%',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
