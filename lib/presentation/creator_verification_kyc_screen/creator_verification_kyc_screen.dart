import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/creator_verification_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/bank_account_step_widget.dart';
import './widgets/compliance_screening_step_widget.dart';
import './widgets/identity_document_step_widget.dart';
import './widgets/personal_info_step_widget.dart';
import './widgets/tax_documentation_step_widget.dart';
import './widgets/verification_step_indicator_widget.dart';

class CreatorVerificationKycScreen extends StatefulWidget {
  const CreatorVerificationKycScreen({super.key});

  @override
  State<CreatorVerificationKycScreen> createState() =>
      _CreatorVerificationKycScreenState();
}

class _CreatorVerificationKycScreenState
    extends State<CreatorVerificationKycScreen> {
  final CreatorVerificationService _verificationService =
      CreatorVerificationService.instance;
  final PageController _pageController = PageController();

  int _currentStep = 0;
  bool _isLoading = true;
  Map<String, bool> _completedSteps = {};
  Map<String, dynamic>? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVerificationStatus() async {
    setState(() => _isLoading = true);

    final status = await _verificationService.getVerificationStatus();
    final progress = await _verificationService.getVerificationProgress();

    setState(() {
      _verificationStatus = status;
      _completedSteps = progress;
      _isLoading = false;

      // Navigate to first incomplete step
      if (progress['step1_personal_info'] == false) {
        _currentStep = 0;
      } else if (progress['step2_identity_document'] == false) {
        _currentStep = 1;
      } else if (progress['step3_bank_account'] == false) {
        _currentStep = 2;
      } else if (progress['step4_tax_documentation'] == false) {
        _currentStep = 3;
      } else if (progress['step5_submitted'] == false) {
        _currentStep = 4;
      }

      _pageController.jumpToPage(_currentStep);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorVerificationKYC',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Creator Verification',
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Verification Status Banner
                  if (_verificationStatus?['verification_status'] != 'pending')
                    _buildStatusBanner(
                      _verificationStatus!['verification_status']!,
                    ),

                  // Step Indicator
                  VerificationStepIndicatorWidget(
                    currentStep: _currentStep,
                    completedSteps: _completedSteps,
                  ),

                  // Step Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentStep = index);
                      },
                      children: [
                        PersonalInfoStepWidget(
                          onNext: () => _goToNextStep(),
                          initialData: _verificationStatus,
                        ),
                        IdentityDocumentStepWidget(
                          onNext: () => _goToNextStep(),
                        ),
                        BankAccountStepWidget(
                          onNext: () => _goToNextStep(),
                          initialData: _verificationStatus,
                        ),
                        TaxDocumentationStepWidget(
                          onNext: () => _goToNextStep(),
                          initialData: _verificationStatus,
                        ),
                        ComplianceScreeningStepWidget(
                          verificationStatus: _verificationStatus,
                          onSubmit: () => _submitForReview(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    switch (status) {
      case 'under_review':
        backgroundColor = AppTheme.warningLight.withAlpha(26);
        textColor = AppTheme.warningLight;
        icon = Icons.hourglass_empty;
        message = 'Your verification is under review';
        break;
      case 'approved':
        backgroundColor = AppTheme.accentLight.withAlpha(26);
        textColor = AppTheme.accentLight;
        icon = Icons.check_circle;
        message = 'Verification approved! You can now receive payouts';
        break;
      case 'rejected':
        backgroundColor = AppTheme.errorLight.withAlpha(26);
        textColor = AppTheme.errorLight;
        icon = Icons.error;
        message =
            'Verification rejected: ${_verificationStatus?['rejection_reason'] ?? 'Please review and resubmit'}';
        break;
      case 'expired':
        backgroundColor = AppTheme.errorLight.withAlpha(26);
        textColor = AppTheme.errorLight;
        icon = Icons.warning;
        message = 'Verification expired. Please renew your verification';
        break;
      default:
        return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToNextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _loadVerificationStatus();
    }
  }

  Future<void> _submitForReview() async {
    final success = await _verificationService.submitForComplianceScreening();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification submitted for review'),
          backgroundColor: AppTheme.accentLight,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit verification'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }
}
