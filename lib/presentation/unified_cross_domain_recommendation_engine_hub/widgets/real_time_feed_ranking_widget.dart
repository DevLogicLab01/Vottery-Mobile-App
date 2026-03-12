import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class RealTimeFeedRankingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;

  const RealTimeFeedRankingWidget({super.key, required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 2.h),
          _buildLiveMetrics(),
          SizedBox(height: 2.h),
          Text(
            'Live Feed Rankings',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ...recommendations.map((rec) => _buildRankingCard(rec)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.accentLight),
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: AppTheme.accentLight, size: 6.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-Time Feed Optimization',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
                Text(
                  'Rankings update based on user behavior patterns',
                  style: TextStyle(
                    fontSize: 11.sp,
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

  Widget _buildLiveMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Click-Through Rate',
            '12.4%',
            Icons.touch_app,
            Colors.blue,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildMetricCard(
            'Engagement',
            '78.3%',
            Icons.favorite,
            Colors.red,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildMetricCard(
            'Correlation',
            '0.89',
            Icons.analytics,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> rec) {
    final type = rec['type'] ?? 'unknown';
    final title = rec['title'] ?? 'Untitled';
    final relevanceScore = rec['relevance_score'] ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _buildTypeIcon(type),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'Type: ${type.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${(relevanceScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentLight,
                ),
              ),
              Text(
                'Relevance',
                style: TextStyle(
                  fontSize: 9.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'election':
        icon = Icons.how_to_vote;
        color = AppTheme.primaryLight;
        break;
      case 'post':
        icon = Icons.article;
        color = AppTheme.accentLight;
        break;
      case 'ad':
        icon = Icons.campaign;
        color = Colors.orange;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(icon, color: color, size: 6.w),
    );
  }
}
