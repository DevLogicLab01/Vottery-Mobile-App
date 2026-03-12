import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ProgressiveImageLoaderWidget extends StatelessWidget {
  const ProgressiveImageLoaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progressive Image Loading',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Low-quality placeholders → High-quality images',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          _buildStrategyCard(),
          SizedBox(height: 3.h),
          _buildPerformanceCard(),
          SizedBox(height: 3.h),
          _buildExampleCard(),
        ],
      ),
    );
  }

  Widget _buildStrategyCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Loading Strategy',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildStrategyStep(
            '1',
            'Placeholder',
            'Show low-quality blur (5KB)',
            AppTheme.textSecondaryLight,
          ),
          _buildStrategyStep(
            '2',
            'Progressive Load',
            'Stream high-quality image',
            AppTheme.secondaryLight,
          ),
          _buildStrategyStep(
            '3',
            'Cache',
            'Store for offline access',
            AppTheme.accentLight,
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyStep(
    String number,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentLight, Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Impact',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  'Initial Load',
                  '85% faster',
                  Icons.speed,
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  'Bandwidth',
                  '60% saved',
                  Icons.data_usage,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  'User Experience',
                  '95% improved',
                  Icons.sentiment_very_satisfied,
                ),
              ),
              Expanded(
                child: _buildPerformanceMetric(
                  'Cache Hit',
                  '94.2%',
                  Icons.cached,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 5.w, color: Colors.white.withAlpha(204)),
        SizedBox(height: 1.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: Colors.white.withAlpha(204)),
        ),
      ],
    );
  }

  Widget _buildExampleCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Implementation Example',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              'CachedNetworkImage(\n  imageUrl: url,\n  placeholder: (context, url) =>\n    BlurHash(hash: blurHash),\n  fadeInDuration: Duration(\n    milliseconds: 300,\n  ),\n  memCacheWidth: 800,\n)',
              style: TextStyle(
                fontSize: 10.sp,
                fontFamily: 'monospace',
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
