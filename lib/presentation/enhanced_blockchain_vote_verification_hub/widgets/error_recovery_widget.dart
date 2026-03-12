import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/blockchain_error_service.dart';

class ErrorRecoveryWidget extends StatelessWidget {
  final BlockchainErrorType errorType;
  final VoidCallback onRetry;

  const ErrorRecoveryWidget({
    super.key,
    required this.errorType,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorService = BlockchainErrorService.instance;
    final suggestions = errorService.getRecoverySuggestions(errorType);

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Recovery Suggestions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            ...suggestions.map(
              (suggestion) => Padding(
                padding: EdgeInsets.symmetric(vertical: 0.5.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: theme.colorScheme.primary,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
