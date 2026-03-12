import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class SystemHealthTabWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const SystemHealthTabWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by parent
      },
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildSystemHealthOverview(),
          SizedBox(height: 2.h),
          _buildOfflineSyncMetrics(),
          SizedBox(height: 2.h),
          _buildVoiceInteractionMetrics(),
          SizedBox(height: 2.h),
          _buildIntegrationHealth(),
        ],
      ),
    );
  }

  Widget _buildSystemHealthOverview() {
    final systemHealth = data['system_health'] as Map<String, dynamic>? ?? {};
    final overallHealth = systemHealth['overall_health_score'] ?? 0.95;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health Overview',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            Center(
              child: SizedBox(
                height: 150,
                width: 150,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: overallHealth as double,
                      strokeWidth: 12,
                      backgroundColor: AppTheme.borderLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getHealthColor(overallHealth),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(overallHealth * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: _getHealthColor(overallHealth),
                            ),
                          ),
                          Text(
                            _getHealthStatus(overallHealth),
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
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHealthIndicator(
                  'API',
                  systemHealth['api_health'] ?? 0.98,
                  Icons.api,
                ),
                _buildHealthIndicator(
                  'Database',
                  systemHealth['database_health'] ?? 0.96,
                  Icons.storage,
                ),
                _buildHealthIndicator(
                  'Cache',
                  systemHealth['cache_health'] ?? 0.92,
                  Icons.memory,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String label, double health, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: _getHealthColor(health), size: 28),
        SizedBox(height: 0.5.h),
        Text(
          '${(health * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: _getHealthColor(health),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildOfflineSyncMetrics() {
    final syncSuccess = data['offline_sync_success'] ?? 0.94;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline Sync Performance',
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
                              value: syncSuccess as double,
                              strokeWidth: 8,
                              backgroundColor: AppTheme.borderLight,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getHealthColor(syncSuccess),
                              ),
                            ),
                            Center(
                              child: Text(
                                '${(syncSuccess * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 14.sp,
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
                        'Success Rate',
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
                      _buildSyncMetric(
                        'Pending Syncs',
                        '12',
                        Icons.sync,
                        AppTheme.warningLight,
                      ),
                      SizedBox(height: 1.h),
                      _buildSyncMetric(
                        'Failed Syncs',
                        '3',
                        Icons.sync_problem,
                        AppTheme.errorLight,
                      ),
                      SizedBox(height: 1.h),
                      _buildSyncMetric(
                        'Completed',
                        '487',
                        Icons.check_circle,
                        AppTheme.accentLight,
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

  Widget _buildSyncMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
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

  Widget _buildVoiceInteractionMetrics() {
    final voiceMetrics =
        data['voice_interaction_metrics'] as Map<String, dynamic>? ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice Interaction Performance',
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
                  child: _buildVoiceMetricCard(
                    'Total Interactions',
                    '${voiceMetrics['total_interactions'] ?? 0}',
                    Icons.mic,
                    AppTheme.primaryLight,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildVoiceMetricCard(
                    'Success Rate',
                    '${((voiceMetrics['success_rate'] ?? 0) * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    AppTheme.accentLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildVoiceMetricCard(
                    'Avg Response',
                    '${voiceMetrics['avg_response_time'] ?? 0}s',
                    Icons.timer,
                    AppTheme.secondaryLight,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildVoiceMetricCard(
                    'Recognition',
                    '${((voiceMetrics['recognition_accuracy'] ?? 0.91) * 100).toStringAsFixed(0)}%',
                    Icons.hearing,
                    AppTheme.accentLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMetricCard(
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
              fontSize: 14.sp,
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

  Widget _buildIntegrationHealth() {
    final integrations = data['integration_status'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Integration Health',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 2.h),
            ...integrations.map(
              (integration) => _buildIntegrationCard(integration),
            ),
            if (integrations.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Text(
                    'No integration data available',
                    style: TextStyle(
                      fontSize: 12.sp,
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

  Widget _buildIntegrationCard(Map<String, dynamic> integration) {
    final name = integration['integration_name'] as String? ?? 'Unknown';
    final status = integration['status'] as String? ?? 'unknown';
    final lastCheck = integration['last_check'] as String? ?? 'Never';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _getIntegrationStatusColor(status).withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: _getIntegrationStatusColor(status).withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getIntegrationIcon(name),
            color: _getIntegrationStatusColor(status),
            size: 28,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                Text(
                  'Last check: $lastCheck',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _getIntegrationStatusColor(status),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(double health) {
    if (health >= 0.9) return AppTheme.accentLight;
    if (health >= 0.7) return AppTheme.warningLight;
    return AppTheme.errorLight;
  }

  String _getHealthStatus(double health) {
    if (health >= 0.9) return 'Excellent';
    if (health >= 0.7) return 'Good';
    if (health >= 0.5) return 'Fair';
    return 'Poor';
  }

  Color _getIntegrationStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return AppTheme.accentLight;
      case 'degraded':
        return AppTheme.warningLight;
      case 'down':
        return AppTheme.errorLight;
      default:
        return AppTheme.textSecondaryLight;
    }
  }

  IconData _getIntegrationIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('openai')) return Icons.psychology;
    if (nameLower.contains('anthropic')) return Icons.smart_toy;
    if (nameLower.contains('gemini')) return Icons.auto_awesome;
    if (nameLower.contains('perplexity')) return Icons.search;
    if (nameLower.contains('supabase')) return Icons.storage;
    if (nameLower.contains('stripe')) return Icons.payment;
    return Icons.integration_instructions;
  }
}
