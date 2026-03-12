import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class VerificationRetryWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final int retryCount;

  const VerificationRetryWidget({
    super.key,
    required this.onRetry,
    required this.retryCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (retryCount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Retry Attempts: $retryCount',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
            ],
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay),
              label: Text(
                'Retry Verification',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Automatic retry with exponential backoff: 5s, 15s, 30s',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 9.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
