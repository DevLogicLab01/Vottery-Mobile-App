import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class CodeSplittingAnalyzerWidget extends StatelessWidget {
  const CodeSplittingAnalyzerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final heavyImports = [
      {
        'file': 'lib/presentation/creator_marketplace/creator_marketplace.dart',
        'size_kb': 245.3,
        'recommendation':
            'Defer marketplace initialization until user navigates',
      },
      {
        'file': 'lib/services/openai_service.dart',
        'size_kb': 189.7,
        'recommendation': 'Lazy load AI services on first use',
      },
      {
        'file': 'lib/presentation/jolts_video_feed/jolts_video_feed.dart',
        'size_kb': 167.2,
        'recommendation': 'Implement route-based lazy loading for video player',
      },
    ];

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Automated Code Splitting Analysis',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        _buildPerformanceBudgetCard(),
        SizedBox(height: 2.h),
        Text(
          'Heavy Imports Detected',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        ...heavyImports.map((import) => _buildHeavyImportCard(import)),
        SizedBox(height: 2.h),
        _buildOptimizationSummary(),
      ],
    );
  }

  Widget _buildPerformanceBudgetCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.shade200, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 8.w),
              SizedBox(width: 2.w),
              Text(
                'Performance Budget Alert',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            '3 screens exceed 2-second load threshold',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBudgetStat('Target', '<2000ms', Colors.green),
              _buildBudgetStat('Average', '2145ms', Colors.orange),
              _buildBudgetStat('Worst', '2847ms', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color,
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

  Widget _buildHeavyImportCard(Map<String, dynamic> import) {
    final file = import['file'] ?? '';
    final sizeKb = import['size_kb'] ?? 0.0;
    final recommendation = import['recommendation'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_present, color: Colors.red, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  file.split('/').last,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  '${sizeKb.toStringAsFixed(1)} KB',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orange, size: 5.w),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  recommendation,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationSummary() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Optimization Recommendations',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          _buildRecommendationItem(
            'Implement route-based lazy loading for 12 screens',
          ),
          _buildRecommendationItem('Enable tree-shaking for unused exports'),
          _buildRecommendationItem(
            'Defer AI service initialization until first use',
          ),
          _buildRecommendationItem('Split video player into separate bundle'),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.blue, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
