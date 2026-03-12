import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Sign out button widget with confirmation dialog.
/// Implements security-focused design with clear visual hierarchy.
class SignOutButtonWidget extends StatelessWidget {
  final VoidCallback onSignOut;

  const SignOutButtonWidget({super.key, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: ElevatedButton(
        onPressed: onSignOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'logout',
              color: theme.colorScheme.onError,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              'Sign Out',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onError,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
