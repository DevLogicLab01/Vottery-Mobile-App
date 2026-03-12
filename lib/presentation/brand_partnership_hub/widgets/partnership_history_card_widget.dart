import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Partnership History Card Widget - Displays completed collaborations with earnings
class PartnershipHistoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> partnership;

  const PartnershipHistoryCardWidget({super.key, required this.partnership});

  @override
  Widget build(BuildContext context) {
    final campaign = partnership['campaign'] as Map<String, dynamic>?;
    final brand = partnership['brand'] as Map<String, dynamic>?;

    return Card(
      margin: EdgeInsets.only(bottom: 3.w),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: CustomIconWidget(
                    iconName: 'business',
                    size: 6.w,
                    color: AppTheme.primaryLight,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign?['campaign_name'] ?? 'Campaign',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        brand?['full_name'] ?? 'Brand',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '\$${(partnership['total_earnings'] ?? 0.0).toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentLight,
                        ),
                      ),
                      Text(
                        'Earned',
                        style: GoogleFonts.inter(
                          fontSize: 8.sp,
                          color: AppTheme.accentLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    icon: 'visibility',
                    label: 'Reach',
                    value: _formatNumber(partnership['total_reach'] ?? 0),
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    icon: 'favorite',
                    label: 'Engagement',
                    value:
                        '${(partnership['engagement_rate'] ?? 0.0).toStringAsFixed(1)}%',
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    icon: 'check_circle',
                    label: 'Content',
                    value:
                        '${partnership['content_approved'] ?? 0}/${partnership['content_delivered'] ?? 0}',
                  ),
                ),
                Expanded(
                  child: _buildMetric(
                    icon: 'star',
                    label: 'Rating',
                    value:
                        '${(partnership['performance_rating'] ?? 0.0).toStringAsFixed(1)}',
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'calendar_today',
                  size: 3.w,
                  color: AppTheme.textSecondaryLight,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Completed ${_formatDate(partnership['completed_at'])}',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          size: 4.w,
          color: AppTheme.primaryLight,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime).inDays;

      if (difference < 7) return '$difference days ago';
      if (difference < 30) return '${(difference / 7).floor()} weeks ago';
      if (difference < 365) return '${(difference / 30).floor()} months ago';
      return '${(difference / 365).floor()} years ago';
    } catch (e) {
      return 'N/A';
    }
  }
}
