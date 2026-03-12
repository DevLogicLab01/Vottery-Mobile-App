import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AudienceInsightsCardWidget extends StatelessWidget {
  const AudienceInsightsCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audience Insights',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        _buildDemographicsCard(theme),
        SizedBox(height: 2.h),
        _buildGrowthTrajectoryCard(theme),
        SizedBox(height: 2.h),
        _buildEngagementPatternsCard(theme),
      ],
    );
  }

  Widget _buildDemographicsCard(ThemeData theme) {
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
            'Follower Demographics',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Age Distribution',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    SizedBox(
                      height: 20.h,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: 35,
                              title: '18-24',
                              color: Colors.blue,
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: 30,
                              title: '25-34',
                              color: Colors.green,
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: 20,
                              title: '35-44',
                              color: AppTheme.vibrantYellow,
                              radius: 50,
                            ),
                            PieChartSectionData(
                              value: 15,
                              title: '45+',
                              color: Colors.orange,
                              radius: 50,
                            ),
                          ],
                          sectionsSpace: 2,
                          centerSpaceRadius: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDemographicItem(theme, '18-24', '35%', Colors.blue),
                    SizedBox(height: 1.h),
                    _buildDemographicItem(theme, '25-34', '30%', Colors.green),
                    SizedBox(height: 1.h),
                    _buildDemographicItem(
                      theme,
                      '35-44',
                      '20%',
                      AppTheme.vibrantYellow,
                    ),
                    SizedBox(height: 1.h),
                    _buildDemographicItem(theme, '45+', '15%', Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicItem(
    ThemeData theme,
    String label,
    String percentage,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 4.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          percentage,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthTrajectoryCard(ThemeData theme) {
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
            'Growth Trajectory',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGrowthMetric(
                theme,
                'Followers',
                '12.5K',
                '+1.2K',
                Icons.people,
              ),
              _buildGrowthMetric(
                theme,
                'Retention',
                '89%',
                '+3%',
                Icons.trending_up,
              ),
              _buildGrowthMetric(
                theme,
                'Churn',
                '2.1%',
                '-0.5%',
                Icons.trending_down,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthMetric(
    ThemeData theme,
    String label,
    String value,
    String change,
    IconData icon,
  ) {
    final isPositive = change.startsWith('+') || change.startsWith('-');
    final isGrowth = change.startsWith('+');

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 6.w),
        SizedBox(height: 1.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (isPositive)
          Text(
            change,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: isGrowth ? Colors.green : Colors.red,
            ),
          ),
      ],
    );
  }

  Widget _buildEngagementPatternsCard(ThemeData theme) {
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
            'Engagement Patterns',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          _buildEngagementItem(
            theme,
            'Peak Activity',
            '6-9 PM',
            Icons.access_time,
          ),
          SizedBox(height: 1.h),
          _buildEngagementItem(theme, 'Avg. Session', '8.5 min', Icons.timer),
          SizedBox(height: 1.h),
          _buildEngagementItem(
            theme,
            'Top Location',
            'United States',
            Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(26),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 5.w),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          value,
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
