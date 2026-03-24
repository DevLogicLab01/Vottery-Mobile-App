import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/batch1_route_allowlist.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_theme.dart';

class KYCVerificationWorkflowWidget extends StatefulWidget {
  final Map<String, dynamic>? verificationStatus;
  final VoidCallback onVerificationUpdate;

  const KYCVerificationWorkflowWidget({
    super.key,
    required this.verificationStatus,
    required this.onVerificationUpdate,
  });

  @override
  State<KYCVerificationWorkflowWidget> createState() =>
      _KYCVerificationWorkflowWidgetState();
}

class _KYCVerificationWorkflowWidgetState
    extends State<KYCVerificationWorkflowWidget> {
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _determineCurrentStep();
  }

  void _determineCurrentStep() {
    if (widget.verificationStatus == null) {
      _currentStep = 0;
    } else {
      final status = widget.verificationStatus!['verification_status'];
      if (status == 'approved') {
        _currentStep = 4;
      } else if (status == 'under_review') {
        _currentStep = 3;
      } else {
        _currentStep = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVerified =
        widget.verificationStatus?['verification_status'] == 'approved';
    final isPending =
        widget.verificationStatus?['verification_status'] == 'under_review';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'KYC Verification',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              _buildStatusBadge(isVerified, isPending),
            ],
          ),
          SizedBox(height: 2.h),
          if (!isVerified) _buildStepIndicator(),
          if (!isVerified) SizedBox(height: 2.h),
          if (isVerified)
            _buildVerifiedCard()
          else if (isPending)
            _buildPendingCard()
          else
            _buildStartVerificationCard(),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isVerified, bool isPending) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (isVerified) {
      badgeColor = AppTheme.accentLight;
      badgeText = 'Verified';
      badgeIcon = Icons.check_circle;
    } else if (isPending) {
      badgeColor = AppTheme.warningLight;
      badgeText = 'Pending Review';
      badgeIcon = Icons.pending;
    } else {
      badgeColor = Colors.orange;
      badgeText = 'Unverified';
      badgeIcon = Icons.warning;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(badgeIcon, color: badgeColor, size: 14.sp),
          SizedBox(width: 1.w),
          Text(
            badgeText,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [
      'Personal Info',
      'ID Verification',
      'Selfie Verification',
      'Address Proof',
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = index < _currentStep;
        final isCurrent = index == _currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2.0,
                        color: isCompleted
                            ? AppTheme.accentLight
                            : Colors.grey.shade300,
                      ),
                    ),
                  Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppTheme.accentLight
                          : isCurrent
                          ? AppTheme.primaryLight
                          : Colors.grey.shade300,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(Icons.check, color: Colors.white, size: 4.w)
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2.0,
                        color: isCompleted
                            ? AppTheme.accentLight
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                steps[index],
                style: GoogleFonts.inter(
                  fontSize: 9.sp,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  color: isCurrent
                      ? AppTheme.primaryLight
                      : AppTheme.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVerifiedCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.accentLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.accentLight, width: 2.0),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.accentLight, size: 32.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Complete',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'You can now redeem cash and crypto',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.warningLight.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.warningLight, width: 2.0),
      ),
      child: Row(
        children: [
          Icon(Icons.pending, color: AppTheme.warningLight, size: 32.sp),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Under Review',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  'We\'re reviewing your documents. This usually takes 1-2 business days.',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartVerificationCard() {
    if (!Batch1RouteAllowlist.isAllowed(AppRoutes.creatorVerificationKycScreen)) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Text(
          'Complete KYC verification to unlock cash and crypto redemptions',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: AppTheme.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.creatorVerificationKycScreen,
              ).then((_) => widget.onVerificationUpdate());
            },
            child: Text('Start Verification'),
          ),
        ),
      ],
    );
  }
}
