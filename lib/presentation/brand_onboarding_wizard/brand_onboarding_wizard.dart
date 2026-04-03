import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/brand_onboarding_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';
import './widgets/company_registration_step_widget.dart';
import './widgets/brand_verification_step_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';

class BrandOnboardingWizard extends StatefulWidget {
  const BrandOnboardingWizard({super.key});

  @override
  State<BrandOnboardingWizard> createState() => _BrandOnboardingWizardState();
}

class _BrandOnboardingWizardState extends State<BrandOnboardingWizard> {
  final BrandOnboardingService _onboardingService =
      BrandOnboardingService.instance;
  final PageController _pageController = PageController();

  int _currentStep = 1;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _onboardingData;

  @override
  void initState() {
    super.initState();
    _loadOnboardingProgress();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadOnboardingProgress() async {
    setState(() => _isLoading = true);

    try {
      final progress = await _onboardingService.getOnboardingProgress();

      if (mounted) {
        setState(() {
          _onboardingData = progress;
          _currentStep = progress?['current_step'] ?? 1;
          _isLoading = false;
        });

        if (_currentStep > 1) {
          _pageController.jumpToPage(_currentStep - 1);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading progress: $e')));
      }
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
        _isSaving = false;
      });

      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding
      Navigator.pushReplacementNamed(context, AppRoutes.advertiserPortalScreen);
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
    return ErrorBoundaryWrapper(
      screenName: 'BrandOnboardingWizard',
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: 'Brand Onboarding'),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildProgressIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        CompanyRegistrationStepWidget(
                          onboardingData: _onboardingData,
                          onNext: _nextStep,
                        ),
                        BrandVerificationStepWidget(
                          onboardingData: _onboardingData,
                          onNext: _nextStep,
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

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(26),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $_currentStep of 5',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${(_currentStep / 5 * 100).round()}% Complete',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: List.generate(5, (index) {
              final stepNumber = index + 1;
              final isCompleted = stepNumber < _currentStep;
              final isCurrent = stepNumber == _currentStep;

              return Expanded(
                child: Container(
                  height: 0.8.h,
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepLabel('Company', 1),
              _buildStepLabel('Verify', 2),
              _buildStepLabel('Payment', 3),
              _buildStepLabel('Targeting', 4),
              _buildStepLabel('Budget', 5),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String label, int step) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;

    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10.sp,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive || isCompleted
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
