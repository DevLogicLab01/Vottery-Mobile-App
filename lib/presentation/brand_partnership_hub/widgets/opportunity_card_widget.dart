import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Opportunity Card Widget - Displays available brand campaigns matching creator profile
class OpportunityCardWidget extends StatelessWidget {
  final Map<String, dynamic> opportunity;
  final VoidCallback onApply;

  const OpportunityCardWidget({
    super.key,
    required this.opportunity,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final brand = opportunity['brand'] as Map<String, dynamic>?;
    final verification =
        opportunity['brand_verification'] as Map<String, dynamic>?;
    final isVerified = verification?['verification_status'] == 'verified';

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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              brand?['full_name'] ?? 'Brand',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.5.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentLight.withAlpha(26),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'verified',
                                    size: 3.w,
                                    color: AppTheme.accentLight,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Verified',
                                    style: GoogleFonts.inter(
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accentLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (verification != null)
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'star',
                              size: 3.w,
                              color: AppTheme.warningLight,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${(verification['average_rating'] ?? 0.0).toStringAsFixed(1)} rating',
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
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              opportunity['campaign_name'] ?? 'Campaign',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              opportunity['campaign_description'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildDetail(
                    icon: 'attach_money',
                    label: 'Revenue',
                    value:
                        '\$${(opportunity['revenue_potential'] ?? 0.0).toStringAsFixed(0)}',
                  ),
                ),
                Expanded(
                  child: _buildDetail(
                    icon: 'calendar_today',
                    label: 'Deadline',
                    value: _formatDeadline(opportunity['application_deadline']),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Apply Now',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: icon,
          size: 4.w,
          color: AppTheme.primaryLight,
        ),
        SizedBox(width: 2.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDeadline(dynamic deadline) {
    if (deadline == null) return 'N/A';
    try {
      final date = DateTime.parse(deadline.toString());
      final now = DateTime.now();
      final difference = date.difference(now).inDays;

      if (difference < 0) return 'Expired';
      if (difference == 0) return 'Today';
      if (difference == 1) return 'Tomorrow';
      return '$difference days';
    } catch (e) {
      return 'N/A';
    }
  }
}
