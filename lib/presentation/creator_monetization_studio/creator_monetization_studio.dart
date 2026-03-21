import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import './widgets/step_completion_widget.dart';
import './widgets/step_earnings_preview_widget.dart';
import './widgets/step_payout_config_widget.dart';
import './widgets/step_profile_setup_widget.dart';
import './widgets/step_sponsorship_widget.dart';
import './widgets/step_tier_selection_widget.dart';
import './widgets/step_welcome_widget.dart';

class CreatorMonetizationStudio extends StatefulWidget {
  const CreatorMonetizationStudio({super.key});

  @override
  State<CreatorMonetizationStudio> createState() =>
      _CreatorMonetizationStudioState();
}

class _CreatorMonetizationStudioState extends State<CreatorMonetizationStudio> {
  final _supabase = Supabase.instance.client;
  int _currentStep = 0;
  static const int _totalSteps = 7;

  // Step 2 data
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final Set<String> _selectedCategories = {};

  // Step 3 data
  double _electionsPerMonth = 5;

  // Step 4 data
  final _routingController = TextEditingController();
  final _accountController = TextEditingController();
  String _payoutSchedule = 'Monthly';

  // Step 5 data
  String _selectedTier = 'Bronze';

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _routingController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('creator_onboarding_progress').upsert({
          'creator_user_id': user.id,
          'current_step': _currentStep + 1,
          'profile_completed': _currentStep >= 1,
          'payout_configured': _currentStep >= 3,
          'tier_selected': _currentStep >= 4,
          'onboarding_status': _currentStep >= 6 ? 'completed' : 'in_progress',
        }, onConflict: 'creator_user_id');
      }
    } catch (_) {}
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Progress saved!')));
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _skipToDashboard() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.creatorAnalyticsDashboard,
      (route) => false,
    );
  }

  double _calculateProjectedEarnings() {
    final tierMultiplier =
        {
          'Bronze': 1.0,
          'Silver': 1.5,
          'Gold': 2.5,
          'Platinum': 4.0,
        }[_selectedTier] ??
        1.0;
    return _electionsPerMonth * 50 * tierMultiplier;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: _prevStep,
              )
            : null,
        title: Text(
          'Creator Monetization Studio',
          style: GoogleFonts.inter(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (_currentStep < _totalSteps - 1)
            TextButton(
              onPressed: _skipToDashboard,
              child: Text(
                'Skip',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF6C63FF),
                    ),
                  )
                : const Icon(Icons.save_outlined, color: Colors.black87),
            onPressed: _saveProgress,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}% Complete',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF6C63FF),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          // Step content
          Expanded(child: _buildCurrentStep()),
          // Navigation buttons
          if (_currentStep < _totalSteps - 1)
            Container(
              color: Colors.white,
              padding: EdgeInsets.all(4.w),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Text(
                    _currentStep == 0 ? 'Get Started' : 'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return StepWelcomeWidget(onGetStarted: _nextStep);
      case 1:
        return StepProfileSetupWidget(
          nameController: _nameController,
          bioController: _bioController,
          selectedCategories: _selectedCategories,
          onCategoryToggle: (cat) {
            setState(() {
              if (_selectedCategories.contains(cat)) {
                _selectedCategories.remove(cat);
              } else {
                _selectedCategories.add(cat);
              }
            });
          },
        );
      case 2:
        return StepEarningsPreviewWidget(
          electionsPerMonth: _electionsPerMonth,
          selectedTier: _selectedTier,
          projectedEarnings: _calculateProjectedEarnings(),
          onSliderChanged: (v) => setState(() => _electionsPerMonth = v),
        );
      case 3:
        return StepPayoutConfigWidget(
          routingController: _routingController,
          accountController: _accountController,
          payoutSchedule: _payoutSchedule,
          onScheduleChanged: (v) => setState(() => _payoutSchedule = v),
        );
      case 4:
        return StepTierSelectionWidget(
          selectedTier: _selectedTier,
          onTierSelected: (t) => setState(() => _selectedTier = t),
        );
      case 5:
        return StepSponsorshipWidget(selectedTier: _selectedTier);
      case 6:
        return StepCompletionWidget(onLaunchDashboard: _skipToDashboard);
      default:
        return const SizedBox.shrink();
    }
  }
}