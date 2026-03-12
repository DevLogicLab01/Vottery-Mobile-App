import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ApiHealthScoreWidget extends StatelessWidget {
  final Map<String, dynamic> healthScore;

  const ApiHealthScoreWidget({super.key, required this.healthScore});

  @override
  Widget build(BuildContext context) {
    final overallScore = healthScore['overall_score'] ?? 0.0;
    final avgResponseTime = healthScore['avg_response_time'] ?? 0;
    final errorRate = healthScore['error_rate'] ?? 0.0;
    final opportunities = healthScore['optimization_opportunities'] ?? 0;
    final uptime = healthScore['uptime_percentage'] ?? 0.0;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getScoreColor(overallScore).withAlpha(26),
            _getScoreColor(overallScore).withAlpha(13),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getScoreColor(overallScore).withAlpha(77),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'API Health Score',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: _getScoreColor(overallScore),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  '${overallScore.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.speed,
                  label: 'Avg Response',
                  value: '${avgResponseTime}ms',
                  color: avgResponseTime < 300 ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.error_outline,
                  label: 'Error Rate',
                  value: '${errorRate.toStringAsFixed(1)}%',
                  color: errorRate < 1.0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.lightbulb_outline,
                  label: 'Opportunities',
                  value: opportunities.toString(),
                  color: AppTheme.accentLight,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.cloud_done,
                  label: 'Uptime',
                  value: '${uptime.toStringAsFixed(1)}%',
                  color: uptime > 99.5 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 4.w, color: color),
              SizedBox(width: 1.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.orange;
    return Colors.red;
  }
}
