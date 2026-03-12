import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/advertiser_registration_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/company_info_step_widget.dart';
import './widgets/identity_verification_step_widget.dart';
import './widgets/financial_info_step_widget.dart';
import './widgets/compliance_screening_step_widget.dart';
import './widgets/payment_setup_step_widget.dart';
import './widgets/digital_contracts_step_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';

class BrandAdvertiserRegistrationPortal extends StatefulWidget {
  const BrandAdvertiserRegistrationPortal({super.key});

  @override
  State<BrandAdvertiserRegistrationPortal> createState() =>
      _BrandAdvertiserRegistrationPortalState();
}

class _BrandAdvertiserRegistrationPortalState
    extends State<BrandAdvertiserRegistrationPortal> {
  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _registration;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadRegistration();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistration() async {
    setState(() => _isLoading = true);

    try {
      final registration = await AdvertiserRegistrationService.instance
          .getRegistration();

      if (mounted) {
        setState(() {
          _registration = registration;
          _currentStep = registration?['current_step'] ?? 1;
          _isLoading = false;
        });

        if (_currentStep > 1) {
          _pageController.jumpToPage(_currentStep - 1);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading registration: $e')),
        );
      }
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < 6) {
      setState(() => _isSaving = true);

      try {
        if (_registration != null) {
          await AdvertiserRegistrationService.instance.updateRegistrationStep(
            registrationId: _registration!['id'],
            currentStep: _currentStep + 1,
          );
        }

        setState(() {
          _currentStep++;
          _isSaving = false;
        });

        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving progress: $e')));
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ErrorBoundaryWrapper(
      screenName: 'BrandAdvertiserRegistrationPortal',
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Advertiser Registration',
            variant: CustomAppBarVariant.withBack,
          ),
        ),
        body: Column(
          children: [
            _buildProgressIndicator(theme),
            _buildStepHeader(theme),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  CompanyInfoStepWidget(
                    registration: _registration,
                    onNext: (data) => _saveAndNext(data),
                  ),
                  IdentityVerificationStepWidget(
                    registration: _registration,
                    onNext: (data) => _saveAndNext(data),
                    onBack: _previousStep,
                  ),
                  FinancialInfoStepWidget(
                    registration: _registration,
                    onNext: (data) => _saveAndNext(data),
                    onBack: _previousStep,
                  ),
                  ComplianceScreeningStepWidget(
                    registration: _registration,
                    onNext: (data) => _saveAndNext(data),
                    onBack: _previousStep,
                  ),
                  PaymentSetupStepWidget(
                    registration: _registration,
                    onNext: (data) => _saveAndNext(data),
                    onBack: _previousStep,
                  ),
                  DigitalContractsStepWidget(
                    registration: _registration,
                    onSubmit: _submitRegistration,
                    onBack: _previousStep,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $_currentStep of 6',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: List.generate(
              6,
              (index) => Expanded(
                child: Container(
                  height: 0.5.h,
                  margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                  decoration: BoxDecoration(
                    color: index < _currentStep
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(ThemeData theme) {
    final stepTitles = [
      'Company Information',
      'Identity Verification',
      'Financial Information',
      'Compliance Screening',
      'Payment Setup',
      'Digital Contracts',
    ];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStepIcon(_currentStep),
              color: theme.colorScheme.onPrimaryContainer,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stepTitles[_currentStep - 1],
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getStepDescription(_currentStep),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 1:
        return Icons.business;
      case 2:
        return Icons.verified_user;
      case 3:
        return Icons.account_balance;
      case 4:
        return Icons.security;
      case 5:
        return Icons.payment;
      case 6:
        return Icons.description;
      default:
        return Icons.info;
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 1:
        return 'Business details and industry classification';
      case 2:
        return 'Document upload and beneficial ownership';
      case 3:
        return 'Bank account and credit assessment';
      case 4:
        return 'AML checks and risk assessment';
      case 5:
        return 'Stripe integration and billing preferences';
      case 6:
        return 'Terms acceptance and e-signature';
      default:
        return '';
    }
  }

  Future<void> _saveAndNext(Map<String, dynamic> data) async {
    setState(() => _isSaving = true);

    try {
      if (_registration == null && _currentStep == 1) {
        final newRegistration = await AdvertiserRegistrationService.instance
            .createRegistration(
              companyName: data['company_name'],
              companyEmail: data['company_email'],
              industryClassification: data['industry_classification'],
              companyWebsite: data['company_website'],
              companyPhone: data['company_phone'],
            );

        setState(() => _registration = newRegistration);
      }

      await _nextStep();
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving data: $e')));
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSaving = true);

    try {
      if (_registration != null) {
        await AdvertiserRegistrationService.instance.submitRegistration(
          _registration!['id'],
        );

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Text('Registration Submitted'),
              content: Text(
                'Your advertiser registration has been submitted successfully. Our team will review your application and contact you within 2-3 business days.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text('Done'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting registration: $e')),
      );
    }
  }
}
