import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class IncidentCardWidget extends StatelessWidget {
  final Map<String, dynamic> incident;
  final VoidCallback onResolve;

  const IncidentCardWidget({
    super.key,
    required this.incident,
    required this.onResolve,
  });

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = incident['severity'] as String? ?? 'unknown';
    final alertType = incident['alert_type'] as String? ?? 'Unknown Alert';
    final affectedComponent =
        incident['affected_component'] as String? ?? 'Unknown';
    final message = incident['message'] as String? ?? '';
    final timestampStr = incident['timestamp'] as String?;
    final isResolved = incident['resolved'] as bool? ?? false;
    final correlatedFeatures = incident['correlated_features'] as List? ?? [];

    DateTime? timestamp;
    if (timestampStr != null) {
      timestamp = DateTime.tryParse(timestampStr);
    }

    final timeAgo = timestamp != null
        ? _formatTimeAgo(timestamp)
        : 'Unknown time';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isResolved
              ? Colors.green.withValues(alpha: 0.3)
              : _severityColor(severity).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          _severityIcon(severity),
          color: isResolved ? Colors.green : _severityColor(severity),
          size: 28,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                alertType,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isResolved)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'RESOLVED',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              affectedComponent,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              timeAgo,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.isNotEmpty) ...[
                  Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 2.h),
                ],
                // Correlated Features
                if (correlatedFeatures.isNotEmpty) ...[
                  Text(
                    'Correlated Feature Deployments',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ...correlatedFeatures.take(3).map((feature) {
                    final featureMap = feature as Map<String, dynamic>;
                    final featureName =
                        featureMap['feature_name'] as String? ?? 'Unknown';
                    final correlationScore =
                        (featureMap['correlation_score'] as double? ?? 0.0);
                    final possibleCause =
                        featureMap['possible_cause'] as String? ?? '';
                    return Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    featureName,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: correlationScore,
                                        backgroundColor: Colors.grey.shade300,
                                        color: correlationScore > 0.7
                                            ? Colors.red
                                            : correlationScore > 0.4
                                            ? Colors.orange
                                            : Colors.green,
                                        strokeWidth: 4,
                                      ),
                                      Text(
                                        '${(correlationScore * 100).toInt()}%',
                                        style: TextStyle(fontSize: 8.sp),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (possibleCause.isNotEmpty) ...[
                              SizedBox(height: 0.5.h),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    size: 14,
                                    color: Colors.amber,
                                  ),
                                  SizedBox(width: 1.w),
                                  Expanded(
                                    child: Text(
                                      possibleCause,
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 1.h),
                ],
                // Action Buttons
                Row(
                  children: [
                    if (!isResolved)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onResolve,
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(
                            'Resolve',
                            style: TextStyle(fontSize: 11.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    if (!isResolved) SizedBox(width: 2.w),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.search, size: 16),
                        label: Text(
                          'Investigate',
                          style: TextStyle(fontSize: 11.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
