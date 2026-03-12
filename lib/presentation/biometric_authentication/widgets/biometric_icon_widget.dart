import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget displaying animated biometric icon (fingerprint or face)
class BiometricIconWidget extends StatelessWidget {
  final BiometricType biometricType;
  final bool isAuthenticating;

  const BiometricIconWidget({
    super.key,
    required this.biometricType,
    this.isAuthenticating = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 35.w,
      height: 35.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isAuthenticating)
            SizedBox(
              width: 35.w,
              height: 35.w,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
          CustomIconWidget(
            iconName: biometricType == BiometricType.face
                ? 'face'
                : 'fingerprint',
            size: 80,
            color: theme.colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}
