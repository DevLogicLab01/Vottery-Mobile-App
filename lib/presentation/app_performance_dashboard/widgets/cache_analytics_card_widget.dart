import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CacheAnalyticsCardWidget extends StatelessWidget {
  final Map<String, dynamic> analytics;

  const CacheAnalyticsCardWidget({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hitRate = analytics['hit_rate'] ?? 0.0;
    final missRate = analytics['miss_rate'] ?? 0.0;
    final totalRequests = analytics['total_requests'] ?? 0;
    final cacheSize = analytics['cache_size_mb'] ?? 0.0;
    final evictionCount = analytics['eviction_count'] ?? 0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cache Performance',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: hitRate > 80
                      ? AppTheme.accentLight.withAlpha(26)
                      : AppTheme.warningLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${hitRate.toStringAsFixed(1)}% Hit Rate',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: hitRate > 80
                        ? AppTheme.accentLight
                        : AppTheme.warningLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildMetricRow(
            'Total Requests',
            totalRequests.toString(),
            Icons.analytics,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(
            'Cache Size',
            '${cacheSize.toStringAsFixed(1)} MB',
            Icons.storage,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(
            'Miss Rate',
            '${missRate.toStringAsFixed(1)}%',
            Icons.error_outline,
            theme,
          ),
          SizedBox(height: 1.h),
          _buildMetricRow(
            'Evictions',
            evictionCount.toString(),
            Icons.delete_outline,
            theme,
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: hitRate / 100,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              hitRate > 80 ? AppTheme.accentLight : AppTheme.warningLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 5.w, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
