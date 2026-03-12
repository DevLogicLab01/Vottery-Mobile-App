import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DeferredImportsManagerWidget extends StatelessWidget {
  const DeferredImportsManagerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final deferredRoutes = [
      {
        'route': '/admin-dashboard',
        'status': 'deferred',
        'size': 2.1,
        'loadTime': 340,
      },
      {
        'route': '/creator-analytics',
        'status': 'deferred',
        'size': 1.8,
        'loadTime': 280,
      },
      {
        'route': '/ai-analytics-hub',
        'status': 'deferred',
        'size': 2.5,
        'loadTime': 420,
      },
      {
        'route': '/brand-partnership-hub',
        'status': 'deferred',
        'size': 1.4,
        'loadTime': 210,
      },
      {'route': '/marketplace', 'status': 'eager', 'size': 1.9, 'loadTime': 0},
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deferred Import Configuration',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Route-based code splitting reduces initial bundle load',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          _buildStatsRow(),
          SizedBox(height: 3.h),
          ...deferredRoutes.map((route) => _buildRouteCard(route)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Deferred Routes',
            '42',
            AppTheme.accentLight,
            Icons.route,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            'Avg Load Time',
            '320ms',
            AppTheme.secondaryLight,
            Icons.speed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 5.w, color: color),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    final isDeferred = route['status'] == 'deferred';
    final color = isDeferred
        ? AppTheme.accentLight
        : AppTheme.textSecondaryLight;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  isDeferred ? 'DEFERRED' : 'EAGER',
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${route['size']} MB',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            route['route'] as String,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          if (isDeferred) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 4.w,
                  color: AppTheme.textSecondaryLight,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Load time: ${route['loadTime']}ms',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
