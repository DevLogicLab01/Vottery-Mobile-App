import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class UserAnalyticsTabWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const UserAnalyticsTabWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by parent
      },
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildMetricsSummary(),
          SizedBox(height: 2.h),
          _buildEngagementFunnel(),
          SizedBox(height: 2.h),
          _buildTopScreens(),
          SizedBox(height: 2.h),
          _buildCustomEvents(),
          SizedBox(height: 2.h),
          _buildFeatureAdoption(),
        ],
      ),
    );
  }

  Widget _buildMetricsSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Analytics',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Sessions',
                    '${data['total_sessions'] ?? 0}',
                    Icons.analytics,
                    AppTheme.primaryLight,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Active Users',
                    '${data['active_users'] ?? 0}',
                    Icons.people,
                    AppTheme.accentLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Avg Duration',
                    '${data['avg_session_duration'] ?? 0}s',
                    Icons.timer,
                    AppTheme.secondaryLight,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricCard(
                    'Bounce Rate',
                    '${((data['bounce_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
                    Icons.exit_to_app,
                    AppTheme.warningLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            style: TextStyle(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementFunnel() {
    final funnel = data['engagement_funnel'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Journey Funnel',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            ...funnel.map(
              (stage) => _buildFunnelStage(
                stage['stage'] as String,
                stage['users'] as int,
                stage['conversion'] as double,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFunnelStage(String stage, int users, double conversion) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stage,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                '$users users (${(conversion * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: conversion,
            backgroundColor: AppTheme.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              conversion > 0.5 ? AppTheme.accentLight : AppTheme.warningLight,
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTopScreens() {
    final screens = data['top_screens'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Screens',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            ...screens.map(
              (screen) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryLight.withAlpha(26),
                  child: Icon(
                    Icons.screen_search_desktop,
                    color: AppTheme.primaryLight,
                    size: 20,
                  ),
                ),
                title: Text(
                  screen['name'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  '${screen['views']} views • Avg ${screen['avg_time']}s',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomEvents() {
    final events = data['custom_events'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Events',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            ...events.map((event) {
              final trend = event['trend'] as double;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _getEventIcon(event['name'] as String),
                  color: AppTheme.secondaryLight,
                ),
                title: Text(
                  event['name'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                subtitle: Text(
                  '${event['count']} events',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trend >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: trend >= 0
                          ? AppTheme.accentLight
                          : AppTheme.errorLight,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${(trend * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: trend >= 0
                            ? AppTheme.accentLight
                            : AppTheme.errorLight,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureAdoption() {
    final aiAdoption = data['ai_feature_adoption'] ?? 0.0;
    final consensusUsage = data['consensus_analysis_usage'] ?? 0;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Feature Adoption',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: Stack(
                          children: [
                            CircularProgressIndicator(
                              value: aiAdoption as double,
                              strokeWidth: 8,
                              backgroundColor: AppTheme.borderLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.accentLight,
                              ),
                            ),
                            Center(
                              child: Text(
                                '${(aiAdoption * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Overall Adoption',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAdoptionMetric(
                        'Consensus Analysis',
                        '$consensusUsage uses',
                        Icons.psychology,
                      ),
                      SizedBox(height: 1.h),
                      _buildAdoptionMetric(
                        'Quest Completion',
                        '${data['quest_completion_events'] ?? 0}',
                        Icons.emoji_events,
                      ),
                      SizedBox(height: 1.h),
                      _buildAdoptionMetric(
                        'VP Earning',
                        '${data['vp_earning_events'] ?? 0}',
                        Icons.monetization_on,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdoptionMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondaryLight, size: 20),
        SizedBox(width: 2.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getEventIcon(String eventName) {
    switch (eventName) {
      case 'vote_submission':
        return Icons.how_to_vote;
      case 'quest_completion':
        return Icons.emoji_events;
      case 'vp_purchase':
        return Icons.shopping_cart;
      case 'fraud_alert':
        return Icons.warning;
      default:
        return Icons.event;
    }
  }
}
