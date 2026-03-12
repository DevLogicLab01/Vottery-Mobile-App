import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Active Campaign Card Widget - Displays current brand partnerships with performance metrics
class ActiveCampaignCardWidget extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback onTap;

  const ActiveCampaignCardWidget({
    super.key,
    required this.campaign,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final campaignData = campaign['campaign'] as Map<String, dynamic>?;
    final status = campaign['application_status'] ?? 'pending';

    return Card(
      margin: EdgeInsets.only(bottom: 3.w),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
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
                          campaignData?['campaign_name'] ?? 'Campaign',
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        _buildStatusChip(status),
                      ],
                    ),
                  ),
                  CustomIconWidget(
                    iconName: 'chevron_right',
                    size: 6.w,
                    color: AppTheme.textSecondaryLight,
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
                      value: '${campaign['expected_reach'] ?? 0}',
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      icon: 'favorite',
                      label: 'Engagement',
                      value:
                          '${(campaign['expected_engagement_rate'] ?? 0.0).toStringAsFixed(1)}%',
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      icon: 'attach_money',
                      label: 'Revenue',
                      value:
                          '\$${(campaignData?['revenue_potential'] ?? 0.0).toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'accepted':
        bgColor = AppTheme.accentLight.withAlpha(26);
        textColor = AppTheme.accentLight;
        displayText = 'Active';
        break;
      case 'pending':
        bgColor = AppTheme.warningLight.withAlpha(26);
        textColor = AppTheme.warningLight;
        displayText = 'Pending';
        break;
      case 'under_review':
        bgColor = AppTheme.secondaryLight.withAlpha(26);
        textColor = AppTheme.secondaryLight;
        displayText = 'Under Review';
        break;
      default:
        bgColor = AppTheme.surfaceLight;
        textColor = AppTheme.textSecondaryLight;
        displayText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(
          fontSize: 9.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
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
          size: 5.w,
          color: AppTheme.primaryLight,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
