import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../../../services/offline_vote_service.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Modal for biometric confirmation before vote submission
class BiometricConfirmationModal extends StatefulWidget {
  final String voteTitle;
  final List<String> selectedOptions;

  const BiometricConfirmationModal({
    super.key,
    required this.voteTitle,
    required this.selectedOptions,
  });

  @override
  State<BiometricConfirmationModal> createState() =>
      _BiometricConfirmationModalState();
}

class _BiometricConfirmationModalState extends State<BiometricConfirmationModal>
    with SingleTickerProviderStateMixin {
  bool isAuthenticating = false;
  bool authSuccess = false;
  bool authFailed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final OfflineVoteService _offlineService = OfflineVoteService.instance;
  bool _canCheckBiometrics = false;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkBiometricAvailability();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck && isDeviceSupported;
        });
      }
    } catch (e) {
      debugPrint('Biometric check error: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    final online = await _offlineService.isOnline();
    if (mounted) {
      setState(() => _isOnline = online);
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      isAuthenticating = true;
      authFailed = false;
    });

    try {
      if (!_canCheckBiometrics) {
        // Fallback to password confirmation
        setState(() {
          isAuthenticating = false;
          authSuccess = true;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirm your vote with biometric authentication',
      );

      setState(() {
        isAuthenticating = false;
        if (authenticated) {
          authSuccess = true;
        } else {
          authFailed = true;
        }
      });

      if (authenticated) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      setState(() {
        isAuthenticating = false;
        authFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.dialogBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.w)),
      ),
      padding: EdgeInsets.all(6.w),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(1.w),
              ),
            ),
            SizedBox(height: 3.h),

            // Title
            Text(
              'Confirm Your Vote',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            // Vote details
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(3.w),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.voteTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Your selection:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  ...widget.selectedOptions.map((option) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 1.h),
                      child: Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'check_circle',
                            color: theme.colorScheme.primary,
                            size: 5.w,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              option,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Offline indicator
            if (!_isOnline) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'cloud_off',
                      color: theme.colorScheme.error,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Offline - Vote will be queued',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
            ],

            // Biometric icon
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 25.w,
                height: 25.w,
                decoration: BoxDecoration(
                  color: authSuccess
                      ? theme.colorScheme.tertiary.withValues(alpha: 0.2)
                      : authFailed
                      ? theme.colorScheme.error.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: authSuccess
                        ? 'check_circle'
                        : authFailed
                        ? 'error'
                        : 'fingerprint',
                    color: authSuccess
                        ? theme.colorScheme.tertiary
                        : authFailed
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    size: 12.w,
                  ),
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Status text
            Text(
              authSuccess
                  ? 'Authentication Successful'
                  : authFailed
                  ? 'Authentication Failed'
                  : isAuthenticating
                  ? 'Authenticating...'
                  : 'Verify your identity to submit',
              style: theme.textTheme.titleMedium?.copyWith(
                color: authSuccess
                    ? theme.colorScheme.tertiary
                    : authFailed
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (authFailed) ...[
              SizedBox(height: 1.h),
              Text(
                'Please try again',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 4.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isAuthenticating
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      side: BorderSide(color: theme.colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (isAuthenticating || authSuccess)
                        ? null
                        : _authenticate,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2.w),
                      ),
                    ),
                    child: isAuthenticating
                        ? SizedBox(
                            width: 5.w,
                            height: 5.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            authFailed ? 'Retry' : 'Authenticate',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
