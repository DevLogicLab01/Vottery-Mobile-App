import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class AssetOptimizationPanelWidget extends StatelessWidget {
  const AssetOptimizationPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Asset Optimization Pipeline',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        _buildOptimizationCard(
          'Image Compression',
          'WebP conversion with 85% quality',
          '12.4 MB saved',
          Icons.image,
          AppTheme.accentLight,
        ),
        _buildOptimizationCard(
          'Lazy Image Loading',
          'Viewport-based loading with placeholders',
          '40% faster initial load',
          Icons.visibility,
          AppTheme.secondaryLight,
        ),
        _buildOptimizationCard(
          'Cache Strategy',
          'CachedNetworkImage with 7-day expiration',
          '94.2% hit ratio',
          Icons.storage,
          AppTheme.primaryLight,
        ),
        _buildOptimizationCard(
          'Progressive Loading',
          'Low-quality placeholder → High-quality image',
          'Improved perceived performance',
          Icons.hourglass_bottom,
          AppTheme.warningLight,
        ),
        SizedBox(height: 2.h),
        _buildCacheStats(),
      ],
    );
  }

  Widget _buildOptimizationCard(
    String title,
    String description,
    String metric,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
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
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  metric,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheStats() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withAlpha(26),
            AppTheme.secondaryLight.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            'Cache Performance',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Hit Ratio', '94.2%'),
              _buildStatItem('Cached Items', '1,247'),
              _buildStatItem('Storage', '42.3 MB'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}
