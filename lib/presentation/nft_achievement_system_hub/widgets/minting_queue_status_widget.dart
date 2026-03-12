import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MintingQueueStatusWidget extends StatelessWidget {
  final Map<String, dynamic> queueStatus;

  const MintingQueueStatusWidget({super.key, required this.queueStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = queueStatus['pending'] as int? ?? 0;
    final processing = queueStatus['processing'] as int? ?? 0;
    final completed = queueStatus['completed'] as int? ?? 0;
    final failed = queueStatus['failed'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minting Queue',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 2.h),

          Row(
            children: [
              _buildStatusCard(
                context,
                'Pending',
                pending,
                Icons.schedule,
                theme.colorScheme.primary,
              ),
              SizedBox(width: 2.w),
              _buildStatusCard(
                context,
                'Processing',
                processing,
                Icons.sync,
                Colors.orange,
              ),
            ],
          ),

          SizedBox(height: 2.h),

          Row(
            children: [
              _buildStatusCard(
                context,
                'Completed',
                completed,
                Icons.check_circle,
                theme.colorScheme.tertiary,
              ),
              SizedBox(width: 2.w),
              _buildStatusCard(
                context,
                'Failed',
                failed,
                Icons.error,
                theme.colorScheme.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String label,
    int count,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 1.h),
            Text(
              '$count',
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
