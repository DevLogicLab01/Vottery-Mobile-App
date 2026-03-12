import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SentryAlertCardWidget extends StatelessWidget {
  final Map<String, dynamic> alert;
  final Function(String) onAcknowledge;

  const SentryAlertCardWidget({
    super.key,
    required this.alert,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = alert['severity'] as String? ?? 'medium';
    final status = alert['status'] as String? ?? 'open';
    final color = _getSeverityColor(severity);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withAlpha(77), width: 2),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      _getSeverityIcon(severity),
                      color: color,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['rule_name'] as String? ?? 'Alert',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          alert['message'] as String? ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
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
              SizedBox(height: 2.h),
              _buildMetadataRow(theme, alert),
              SizedBox(height: 2.h),
              _buildActionButtons(theme, status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(ThemeData theme, Map<String, dynamic> alert) {
    final metadata = alert['metadata'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetadataItem(
            theme,
            'Error Type',
            metadata['error_type'] as String? ?? 'Unknown',
          ),
          if (metadata['total_incidents'] != null)
            _buildMetadataItem(
              theme,
              'Total Incidents',
              '${metadata['total_incidents']}',
            ),
          if (metadata['affected_services'] != null)
            _buildMetadataItem(
              theme,
              'Affected Services',
              metadata['affected_services'] as String,
            ),
          _buildMetadataItem(
            theme,
            'Timestamp',
            metadata['timestamp'] as String? ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataItem(ThemeData theme, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, String status) {
    return Row(
      children: [
        if (status == 'open')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onAcknowledge('acknowledged'),
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Acknowledge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        if (status == 'open') SizedBox(width: 2.w),
        if (status == 'acknowledged')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onAcknowledge('investigating'),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Investigating'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        if (status == 'acknowledged') SizedBox(width: 2.w),
        if (status != 'resolved')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => onAcknowledge('resolved'),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Resolve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
      ],
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
