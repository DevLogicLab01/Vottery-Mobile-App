import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FraudDetectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> fraudAlerts;
  final VoidCallback onRefresh;

  const FraudDetectionWidget({
    super.key,
    required this.fraudAlerts,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'security',
                color: theme.colorScheme.error,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Fraud Detection Dashboard',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Anomaly Alerts for Suspicious VP Accumulation Patterns',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          fraudAlerts.isEmpty
              ? _buildNoAlertsState(theme)
              : Column(
                  children: fraudAlerts.map((alert) {
                    return _buildAlertCard(theme, alert);
                  }).toList(),
                ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Alerts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showFreezeDialog,
                  icon: const Icon(Icons.block),
                  label: const Text('Emergency Freeze'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoAlertsState(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'No fraud alerts detected. VP economy is healthy.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(ThemeData theme, Map<String, dynamic> alert) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: theme.colorScheme.error, size: 20.sp),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  alert['title'] ?? 'Suspicious Activity Detected',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            alert['description'] ?? 'Unusual VP accumulation pattern detected',
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User ID: ${alert['user_id'] ?? "Unknown"}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton(
                onPressed: () => _investigateAlert(alert),
                child: const Text('Investigate'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _investigateAlert(Map<String, dynamic> alert) {
    // TODO: Implement investigation workflow
    debugPrint('Investigating alert: $alert');
  }

  void _showFreezeDialog() {
    // TODO: Implement emergency VP freeze dialog
    debugPrint('Emergency VP freeze initiated');
  }
}
