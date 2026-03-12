import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Brand Directory Card Widget - Displays verified advertiser profiles with partnership criteria
class BrandDirectoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> brand;

  const BrandDirectoryCardWidget({super.key, required this.brand});

  @override
  Widget build(BuildContext context) {
    final brandProfile = brand['brand'] as Map<String, dynamic>?;
    final verification = brand;

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
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: CustomIconWidget(
                    iconName: 'business',
                    size: 8.w,
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
                              verification['company_name'] ?? 'Brand',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
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
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accentLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        brandProfile?['bio'] ?? 'No description',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                  child: _buildTrustIndicator(
                    icon: 'star',
                    label: 'Rating',
                    value:
                        '${(verification['average_rating'] ?? 0.0).toStringAsFixed(1)}',
                    color: AppTheme.warningLight,
                  ),
                ),
                Expanded(
                  child: _buildTrustIndicator(
                    icon: 'verified_user',
                    label: 'Trust Score',
                    value:
                        '${((verification['trust_score'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                    color: AppTheme.accentLight,
                  ),
                ),
                Expanded(
                  child: _buildTrustIndicator(
                    icon: 'handshake',
                    label: 'Partnerships',
                    value: '${verification['partnership_history_count'] ?? 0}',
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryLight),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'View Profile',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustIndicator({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        CustomIconWidget(iconName: icon, size: 5.w, color: color),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
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
