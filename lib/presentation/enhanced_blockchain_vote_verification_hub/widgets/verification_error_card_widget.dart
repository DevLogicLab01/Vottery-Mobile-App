import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/blockchain_error_service.dart';

class VerificationErrorCardWidget extends StatelessWidget {
  final Map<String, dynamic> errorResult;

  const VerificationErrorCardWidget({super.key, required this.errorResult});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorType =
        errorResult['errorType'] as BlockchainErrorType? ??
        BlockchainErrorType.unknown;
    final errorMessage =
        errorResult['errorMessage'] as String? ?? 'Unknown error';

    Color errorColor;
    IconData errorIcon;

    switch (errorType) {
      case BlockchainErrorType.rsaDecryptionFailure:
        errorColor = Colors.orange;
        errorIcon = Icons.lock_open;
        break;
      case BlockchainErrorType.blockchainTimeout:
        errorColor = Colors.blue;
        errorIcon = Icons.access_time;
        break;
      case BlockchainErrorType.invalidHash:
        errorColor = Colors.red;
        errorIcon = Icons.warning;
        break;
      case BlockchainErrorType.networkError:
        errorColor = Colors.purple;
        errorIcon = Icons.wifi_off;
        break;
      case BlockchainErrorType.verificationFailed:
        errorColor = Colors.deepOrange;
        errorIcon = Icons.error_outline;
        break;
      case BlockchainErrorType.expiredCertificate:
        errorColor = Colors.brown;
        errorIcon = Icons.event_busy;
        break;
      default:
        errorColor = Colors.grey;
        errorIcon = Icons.help_outline;
    }

    return Card(
      elevation: 3,
      color: errorColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: errorColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(errorIcon, color: errorColor, size: 8.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Verification Error',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: errorColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Text(
              errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (errorResult['technicalDetails'] != null) ...[
              SizedBox(height: 1.h),
              ExpansionTile(
                title: Text(
                  'Technical Details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(2.w),
                    child: Text(
                      errorResult['technicalDetails'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 9.sp,
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
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
  }
}
