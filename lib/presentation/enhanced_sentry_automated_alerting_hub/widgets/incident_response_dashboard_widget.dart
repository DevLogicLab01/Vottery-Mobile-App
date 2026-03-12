import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class IncidentResponseDashboardWidget extends StatelessWidget {
  final List<Map<String, dynamic>> activeAlerts;
  final List<Map<String, dynamic>> recentIncidents;
  final Function(String, String) onAcknowledge;

  const IncidentResponseDashboardWidget({
    super.key,
    required this.activeAlerts,
    required this.recentIncidents,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emergency,
                  color: theme.colorScheme.primary,
                  size: 20.sp,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Incident Response Dashboard',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildResponseStats(theme),
            SizedBox(height: 2.h),
            Text(
              'Recent Incidents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            ...recentIncidents
                .take(5)
                .map((incident) => _buildIncidentTile(theme, incident)),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseStats(ThemeData theme) {
    final acknowledgedCount = activeAlerts
        .where((a) => a['status'] == 'acknowledged')
        .length;
    final investigatingCount = activeAlerts
        .where((a) => a['status'] == 'investigating')
        .length;
    final resolvedCount = activeAlerts
        .where((a) => a['status'] == 'resolved')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            'Acknowledged',
            '$acknowledgedCount',
            Icons.check_circle_outline,
            Colors.blue,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            theme,
            'Investigating',
            '$investigatingCount',
            Icons.search,
            Colors.orange,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            theme,
            'Resolved',
            '$resolvedCount',
            Icons.check_circle,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTile(ThemeData theme, Map<String, dynamic> incident) {
    final severity = incident['severity'] as String? ?? 'medium';
    final color = _getSeverityColor(severity);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Row(
        children: [
          Icon(_getSeverityIcon(severity), color: color, size: 18.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident['error_type'] as String? ?? 'Unknown Error',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  incident['error_message'] as String? ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: color.withAlpha(51),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              severity.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }
}
