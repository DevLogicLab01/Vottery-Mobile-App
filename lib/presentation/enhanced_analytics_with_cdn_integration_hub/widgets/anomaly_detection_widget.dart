import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AnomalyDetectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> anomalies;
  final VoidCallback onRefresh;

  const AnomalyDetectionWidget({
    super.key,
    required this.anomalies,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Anomaly Detection',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
          ],
        ),
        SizedBox(height: 2.h),

        if (anomalies.isEmpty)
          _buildEmptyState(theme)
        else
          ...anomalies.map((anomaly) => _buildAnomalyCard(theme, anomaly)),

        SizedBox(height: 2.h),

        // Automated Alerting
        _buildAlertingCard(theme),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'No anomalies detected',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            Text(
              'All metrics are within normal ranges',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(ThemeData theme, Map<String, dynamic> anomaly) {
    final severity = anomaly['severity'] ?? 'medium';
    final zScore = anomaly['z_score'] ?? 0.0;
    final value = anomaly['value'] ?? 0.0;
    final date = anomaly['date'] ?? '';

    Color severityColor;
    IconData severityIcon;
    switch (severity) {
      case 'high':
        severityColor = Colors.red;
        severityIcon = Icons.error;
        break;
      case 'medium':
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      default:
        severityColor = Colors.yellow;
        severityIcon = Icons.info;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(severityIcon, color: severityColor, size: 24),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${severity.toUpperCase()} Severity Anomaly',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: severityColor,
                      ),
                    ),
                    Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricBox(
                  theme,
                  'Value',
                  value.toStringAsFixed(2),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricBox(
                  theme,
                  'Z-Score',
                  zScore.toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(ThemeData theme, String label, String value) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertingCard(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Text(
                'Automated Alerting',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildAlertRow(theme, 'Real-time Detection', 'Enabled', Colors.green),
          _buildAlertRow(theme, 'Email Notifications', 'Enabled', Colors.green),
          _buildAlertRow(theme, 'Slack Integration', 'Enabled', Colors.green),
        ],
      ),
    );
  }

  Widget _buildAlertRow(
    ThemeData theme,
    String label,
    String status,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
