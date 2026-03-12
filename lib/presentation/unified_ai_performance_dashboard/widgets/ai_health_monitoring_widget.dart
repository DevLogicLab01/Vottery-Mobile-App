import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AIHealthMonitoringWidget extends StatelessWidget {
  final Map<String, dynamic> healthData;

  const AIHealthMonitoringWidget({super.key, required this.healthData});

  @override
  Widget build(BuildContext context) {
    final claudeHealth = healthData['claude'] as Map<String, dynamic>? ?? {};
    final perplexityHealth =
        healthData['perplexity'] as Map<String, dynamic>? ?? {};
    final openaiHealth = healthData['openai'] as Map<String, dynamic>? ?? {};
    final overallHealth =
        (healthData['overall_health'] as num?)?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Model Health Monitoring',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildOverallHealthCard(overallHealth),
          SizedBox(height: 3.h),
          Text(
            'Individual Model Health',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildModelHealthCard(
            'Claude Sonnet 4.5',
            claudeHealth,
            Colors.purple,
            Icons.psychology,
          ),
          SizedBox(height: 2.h),
          _buildModelHealthCard(
            'Perplexity Sonar',
            perplexityHealth,
            Colors.blue,
            Icons.search,
          ),
          SizedBox(height: 2.h),
          _buildModelHealthCard(
            'OpenAI GPT-4o',
            openaiHealth,
            Colors.green,
            Icons.auto_awesome,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallHealthCard(double overallHealth) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getHealthColor(overallHealth),
            _getHealthColor(overallHealth).withAlpha(204),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: _getHealthColor(overallHealth).withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            overallHealth >= 0.8 ? Icons.check_circle : Icons.warning,
            color: Colors.white,
            size: 15.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Overall System Health',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '${(overallHealth * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 20.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            overallHealth >= 0.8
                ? 'All AI services operating normally'
                : 'Some AI services experiencing issues',
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white.withAlpha(230),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModelHealthCard(
    String modelName,
    Map<String, dynamic> health,
    Color color,
    IconData icon,
  ) {
    final healthScore = (health['health_score'] as num?)?.toDouble() ?? 0.0;
    final status = health['status'] ?? 'unknown';
    final responseTime =
        (health['avg_response_time'] as num?)?.toDouble() ?? 0.0;
    final errorRate = (health['error_rate'] as num?)?.toDouble() ?? 0.0;
    final uptime = (health['uptime'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 8.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modelName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: _getHealthColor(healthScore).withAlpha(51),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${(healthScore * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: _getHealthColor(healthScore),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Response Time',
                  '${responseTime.toStringAsFixed(0)}ms',
                  Icons.speed,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Error Rate',
                  '${(errorRate * 100).toStringAsFixed(2)}%',
                  Icons.error_outline,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  'Uptime',
                  '${(uptime * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textSecondaryLight, size: 5.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 8.sp, color: AppTheme.textSecondaryLight),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getHealthColor(double health) {
    if (health >= 0.8) return Colors.green;
    if (health >= 0.6) return Colors.lightGreen;
    if (health >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'operational':
        return Colors.green;
      case 'degraded':
        return Colors.orange;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
