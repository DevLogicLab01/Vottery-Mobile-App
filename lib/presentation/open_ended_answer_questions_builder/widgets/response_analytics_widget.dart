import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../theme/app_theme.dart';

class ResponseAnalyticsWidget extends StatelessWidget {
  final String? electionId;
  final Map<String, dynamic>? analytics;

  const ResponseAnalyticsWidget({super.key, this.electionId, this.analytics});

  @override
  Widget build(BuildContext context) {
    if (electionId == null || analytics == null) {
      return Center(
        child: Text(
          'No analytics data available',
          style: TextStyle(fontSize: 13.sp, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(),
          SizedBox(height: 2.h),
          _buildSentimentChart(),
          SizedBox(height: 2.h),
          _buildCommonThemes(),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    final totalResponses = analytics?['total_responses'] ?? 0;
    final avgCharCount = analytics?['average_character_count'] ?? 0.0;
    final moderationFlags = analytics?['moderation_flags'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Responses',
            totalResponses.toString(),
            Icons.chat_bubble_outline,
            AppTheme.accentLight,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatCard(
            'Avg. Length',
            '${avgCharCount.toStringAsFixed(0)} chars',
            Icons.text_fields,
            Colors.blue,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatCard(
            'Flagged',
            moderationFlags.toString(),
            Icons.flag,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentChart() {
    final sentimentDist = analytics?['sentiment_distribution'] ?? {};
    final positive = (sentimentDist['positive'] ?? 0).toDouble();
    final neutral = (sentimentDist['neutral'] ?? 0).toDouble();
    final negative = (sentimentDist['negative'] ?? 0).toDouble();

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sentiment Distribution',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: positive,
                    title: '${positive.toInt()}',
                    color: Colors.green,
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: neutral,
                    title: '${neutral.toInt()}',
                    color: Colors.grey,
                    radius: 50,
                  ),
                  PieChartSectionData(
                    value: negative,
                    title: '${negative.toInt()}',
                    color: Colors.red,
                    radius: 50,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Positive', Colors.green),
              _buildLegendItem('Neutral', Colors.grey),
              _buildLegendItem('Negative', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 3.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.w),
        Text(label, style: TextStyle(fontSize: 11.sp)),
      ],
    );
  }

  Widget _buildCommonThemes() {
    final themes = analytics?['common_themes'] ?? [];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common Themes',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          themes.isEmpty
              ? Text(
                  'No themes detected yet',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                )
              : Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: themes.map<Widget>((theme) {
                    return Chip(
                      label: Text(
                        theme.toString(),
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      backgroundColor: AppTheme.accentLight.withAlpha(51),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
