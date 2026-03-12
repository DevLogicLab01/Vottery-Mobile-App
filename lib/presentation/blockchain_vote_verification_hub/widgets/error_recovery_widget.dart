import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ErrorRecoveryWidget extends StatelessWidget {
  final Map<String, dynamic> error;
  final VoidCallback onRetry;
  final VoidCallback? onContactSupport;

  const ErrorRecoveryWidget({
    super.key,
    required this.error,
    required this.onRetry,
    this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorType = error['error'] as String? ?? 'unknown';
    final message = error['message'] as String? ?? 'An error occurred';
    final suggestion = error['suggestion'] as String?;
    final retryAvailable = error['retry_available'] as bool? ?? true;

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getErrorIcon(errorType),
            size: 15.w,
            color: theme.colorScheme.error,
          ),
          SizedBox(height: 2.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          if (suggestion != null) ...[
            SizedBox(height: 1.h),
            Text(
              suggestion,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onErrorContainer.withValues(
                  alpha: 0.8,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: 3.h),
          if (retryAvailable)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh, size: 5.w),
                label: Text(
                  'Retry Verification',
                  style: TextStyle(fontSize: 13.sp),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          if (onContactSupport != null) ...[
            SizedBox(height: 1.h),
            TextButton.icon(
              onPressed: onContactSupport,
              icon: Icon(Icons.support_agent, size: 5.w),
              label: Text('Contact Support', style: TextStyle(fontSize: 12.sp)),
            ),
          ],
          SizedBox(height: 2.h),
          _buildErrorDetails(context, errorType),
        ],
      ),
    );
  }

  IconData _getErrorIcon(String errorType) {
    switch (errorType) {
      case 'rsa_decryption_failed':
        return Icons.lock_open;
      case 'blockchain_timeout':
      case 'verification_timeout':
        return Icons.access_time;
      case 'vote_not_found':
        return Icons.search_off;
      case 'expired_certificate':
        return Icons.event_busy;
      case 'invalid_hash':
        return Icons.warning;
      default:
        return Icons.error_outline;
    }
  }

  Widget _buildErrorDetails(BuildContext context, String errorType) {
    final theme = Theme.of(context);
    String details = '';

    switch (errorType) {
      case 'rsa_decryption_failed':
        details = 'The encryption keys may have changed or been rotated.';
        break;
      case 'blockchain_timeout':
        details = 'The blockchain network is experiencing high traffic.';
        break;
      case 'vote_not_found':
        details =
            'The vote may not have been recorded yet or the receipt code is incorrect.';
        break;
      case 'expired_certificate':
        details = 'The verification period for this election has ended.';
        break;
      case 'invalid_hash':
        details = 'The vote data has been tampered with or corrupted.';
        break;
      default:
        details = 'An unexpected error occurred during verification.';
    }

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 5.w,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              details,
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
