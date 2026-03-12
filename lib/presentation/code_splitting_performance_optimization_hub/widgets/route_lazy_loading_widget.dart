import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class RouteLazyLoadingWidget extends StatelessWidget {
  const RouteLazyLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final lazyLoadedRoutes = [
      {
        'route': '/creator-analytics-dashboard',
        'status': 'Lazy Loaded',
        'size_reduction': '2.3 MB',
      },
      {
        'route': '/advanced-fraud-detection-center',
        'status': 'Lazy Loaded',
        'size_reduction': '1.8 MB',
      },
      {
        'route': '/ai-analytics-hub',
        'status': 'Lazy Loaded',
        'size_reduction': '2.1 MB',
      },
      {
        'route': '/blockchain-vote-verification-hub',
        'status': 'Eager Loaded',
        'size_reduction': '0 MB',
      },
    ];

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Route-Based Code Splitting',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Deferred imports reduce initial bundle size by loading screens only when needed',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        ...lazyLoadedRoutes.map((route) => _buildRouteCard(route)),
        SizedBox(height: 2.h),
        _buildStatsSummary(lazyLoadedRoutes),
      ],
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final isLazy = route['status'] == 'Lazy Loaded';
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isLazy
              ? AppTheme.accentLight.withAlpha(77)
              : AppTheme.borderLight,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLazy ? Icons.check_circle : Icons.warning_amber,
                color: isLazy ? AppTheme.accentLight : AppTheme.warningLight,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  route['route'],
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                route['status'],
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: isLazy ? AppTheme.accentLight : AppTheme.warningLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Saved: ${route['size_reduction']}',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(List<Map<String, dynamic>> routes) {
    final lazyCount = routes.where((r) => r['status'] == 'Lazy Loaded').length;
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            '$lazyCount of ${routes.length} routes lazy loaded',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Total bundle size reduction: 6.2 MB',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
