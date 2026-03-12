import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CodeSplittingAnalyzerWidget extends StatelessWidget {
  const CodeSplittingAnalyzerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Code Splitting Analysis',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Performance insights and optimization recommendations',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          _buildScoreCard(),
          SizedBox(height: 3.h),
          _buildRecommendationsCard(),
          SizedBox(height: 3.h),
          _buildImpactCard(),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
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
        children: [
          Text(
            'Optimization Score',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2.h),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 30.w,
                height: 30.w,
                child: CircularProgressIndicator(
                  value: 0.87,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withAlpha(51),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    '87',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Excellent',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreMetric('Bundle', '92'),
              _buildScoreMetric('Loading', '85'),
              _buildScoreMetric('Caching', '84'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMetric(String label, String score) {
    return Column(
      children: [
        Text(
          score,
          style: TextStyle(
            fontSize: 18.sp,
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

  Widget _buildRecommendationsCard() {
    final recommendations = [
      {
        'title': 'Defer Admin Dashboard',
        'description': 'Move admin routes to deferred loading',
        'impact': 'High',
        'savings': '2.1 MB',
        'color': AppTheme.accentLight,
      },
      {
        'title': 'Optimize Font Loading',
        'description': 'Use font subsetting for google_fonts',
        'impact': 'Medium',
        'savings': '0.8 MB',
        'color': AppTheme.warningLight,
      },
      {
        'title': 'Compress Video Assets',
        'description': 'Apply H.265 encoding to election videos',
        'impact': 'High',
        'savings': '15.2 MB',
        'color': AppTheme.accentLight,
      },
    ];

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
            'Optimization Recommendations',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...recommendations.map((rec) => _buildRecommendationCard(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: (rec['color'] as Color).withAlpha(13),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: (rec['color'] as Color).withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rec['title'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: rec['color'] as Color,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  rec['impact'] as String,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            rec['description'] as String,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.savings, size: 4.w, color: rec['color'] as Color),
              SizedBox(width: 2.w),
              Text(
                'Potential savings: ${rec['savings']}',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: rec['color'] as Color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard() {
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
            'Performance Impact',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildImpactRow(
            'Initial Load Time',
            '2.1s → 0.8s',
            '62% faster',
            AppTheme.accentLight,
          ),
          _buildImpactRow(
            'Time to Interactive',
            '3.5s → 1.4s',
            '60% faster',
            AppTheme.accentLight,
          ),
          _buildImpactRow(
            'First Contentful Paint',
            '1.8s → 0.6s',
            '67% faster',
            AppTheme.accentLight,
          ),
          _buildImpactRow(
            'Bundle Size',
            '85MB → 35MB',
            '58.6% smaller',
            AppTheme.primaryLight,
          ),
        ],
      ),
    );
  }

  Widget _buildImpactRow(
    String metric,
    String change,
    String improvement,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              metric,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              change,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              improvement,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
