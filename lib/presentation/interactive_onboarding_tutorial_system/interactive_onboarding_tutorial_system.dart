import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/gamification_service.dart';
import '../../services/supabase_service.dart';
import '../../services/claude_service.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Interactive Onboarding Tutorial System
/// 5-step interactive tutorial introducing quests, voting, analytics,
/// biometric features, and location based functionality with achievement rewards
class InteractiveOnboardingTutorialSystem extends StatefulWidget {
  const InteractiveOnboardingTutorialSystem({super.key});

  @override
  State<InteractiveOnboardingTutorialSystem> createState() =>
      _InteractiveOnboardingTutorialSystemState();
}

class _InteractiveOnboardingTutorialSystemState
    extends State<InteractiveOnboardingTutorialSystem>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final GamificationService _gamificationService = GamificationService.instance;
  final ClaudeService _claudeService = ClaudeService.instance;
  final Map<int, String> _stepGuidance = {};

  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isCompleting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    _loadStepGuidance(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      HapticFeedback.mediumImpact();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
      _loadStepGuidance(_currentStep);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  void _skipTutorial() {
    HapticFeedback.lightImpact();
    _markOnboardingCompleted(skipped: true);
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isCompleting = true);
    HapticFeedback.heavyImpact();

    try {
      // Award achievement and VP
      await _markOnboardingCompleted(skipped: false);

      if (mounted) {
        // Show completion celebration
        await _showCompletionDialog();

        // Navigate to main app
        Navigator.pushReplacementNamed(context, AppRoutes.socialMediaHomeFeed);
      }
    } catch (e) {
      debugPrint('Complete onboarding error: $e');
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _markOnboardingCompleted({required bool skipped}) async {
    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Update user profile
      await SupabaseService.instance.client
          .from('user_profiles')
          .update({
            'onboarding_completed': true,
            'onboarding_skipped': skipped,
            'onboarding_completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Award VP and badge if completed (not skipped)
      if (!skipped) {
        // Award 100 VP bonus
        await SupabaseService.instance.client.from('vp_transactions').insert({
          'user_id': userId,
          'amount': 100,
          'transaction_type': 'earned',
          'source': 'onboarding_completion',
          'description': 'Completed onboarding tutorial',
        });

        // Award achievement badge
        await SupabaseService.instance.client.from('user_achievements').insert({
          'user_id': userId,
          'achievement_type': 'onboarding_master',
          'achievement_name': 'Onboarding Master',
          'achievement_description':
              'Completed the interactive onboarding tutorial',
          'vp_reward': 100,
        });
      }
    } catch (e) {
      debugPrint('Mark onboarding completed error: $e');
    }
  }

  Future<void> _showCompletionDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti animation placeholder
            Icon(Icons.celebration, size: 20.w, color: AppTheme.vibrantYellow),
            SizedBox(height: 2.h),
            Text(
              '🎉 Congratulations!',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'You\'ve completed the onboarding tutorial!',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.accentLight.withAlpha(26),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.stars,
                        color: AppTheme.vibrantYellow,
                        size: 6.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '+100 VP',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.vibrantYellow,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '🏆 Onboarding Master Badge',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Get Started',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'InteractiveOnboardingTutorialSystem',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() => _currentStep = index);
                      _loadStepGuidance(index);
                    },
                    children: [
                      _buildQuestsStep(),
                      _buildVotingStep(),
                      _buildAnalyticsStep(),
                      _buildBiometricStep(),
                      _buildLocationStep(),
                    ],
                  ),
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Welcome to Vottery',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          TextButton(
            onPressed: _skipTutorial,
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          Row(
            children: List.generate(
              _totalSteps,
              (index) => Expanded(
                child: Container(
                  height: 0.5.h,
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? AppTheme.primaryLight
                        : AppTheme.textSecondaryLight.withAlpha(51),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestsStep() {
    return _buildStepContent(
      icon: Icons.emoji_events,
      iconColor: AppTheme.vibrantYellow,
      title: 'Quests System',
      description:
          'Complete daily quests and challenges to earn Vottery Points (VP) and climb the leaderboard!',
      features: [
        'Daily Check-in Quest: +50 VP',
        'Track Your Voting Streak: +100 VP',
        'Complete 5 Elections: +200 VP',
      ],
      exampleWidget: _buildQuestExampleCard(),
    );
  }

  Widget _buildVotingStep() {
    return _buildStepContent(
      icon: Icons.how_to_vote,
      iconColor: Colors.blue,
      title: 'Collaborative Voting',
      description:
          'Your vote matters! Participate in elections with real-time results and blockchain verification.',
      features: [
        'Multiple voting methods: Plurality, Ranked Choice, Approval',
        'Real-time vote counting',
        'Blockchain-verified receipts',
      ],
      exampleWidget: _buildVotingExampleCard(),
    );
  }

  Widget _buildAnalyticsStep() {
    return _buildStepContent(
      icon: Icons.analytics,
      iconColor: Colors.purple,
      title: 'Engagement Analytics',
      description:
          'Track your voting power, quest progress, and leaderboard ranking in real-time.',
      features: [
        'Your Voting Power: Track VP balance',
        'Quest Completion: Monitor progress',
        'Leaderboard Rank: Compete globally',
      ],
      exampleWidget: _buildAnalyticsExampleCard(),
    );
  }

  Widget _buildBiometricStep() {
    return _buildStepContent(
      icon: Icons.fingerprint,
      iconColor: Colors.green,
      title: 'Biometric Voting',
      description:
          'Secure your vote with fingerprint or face ID authentication for maximum security.',
      features: [
        'Fingerprint authentication',
        'Face ID support',
        'Blockchain encryption',
      ],
      exampleWidget: _buildBiometricExampleCard(),
    );
  }

  Widget _buildLocationStep() {
    return _buildStepContent(
      icon: Icons.location_on,
      iconColor: Colors.red,
      title: 'Location-Based Features',
      description:
          'Discover nearby elections, local trending topics, and geo-tagged events in your area.',
      features: [
        'Nearby elections within 50km',
        'Local trending topics',
        'Geo-tagged community events',
      ],
      exampleWidget: _buildLocationExampleCard(),
    );
  }

  Widget _buildStepContent({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> features,
    required Widget exampleWidget,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          Icon(icon, size: 20.w, color: iconColor),
          SizedBox(height: 3.h),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppTheme.textSecondaryLight,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ...features.map((feature) => _buildFeatureItem(feature)),
          if ((_stepGuidance[_currentStep] ?? '').isNotEmpty) ...[
            SizedBox(height: 1.5.h),
            _buildAiGuidanceCard(_stepGuidance[_currentStep]!),
          ],
          SizedBox(height: 3.h),
          exampleWidget,
        ],
      ),
    );
  }

  Widget _buildAiGuidanceCard(String guidance) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(18),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: AppTheme.primaryLight.withAlpha(77)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: AppTheme.primaryLight, size: 5.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              guidance,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textPrimaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadStepGuidance(int step) async {
    if (_stepGuidance.containsKey(step)) return;
    final titles = [
      'Quests System',
      'Collaborative Voting',
      'Engagement Analytics',
      'Biometric Voting',
      'Location-Based Features',
    ];
    final title = titles[step.clamp(0, titles.length - 1)];

    try {
      final guidance = await _claudeService.callClaudeAPI('''
You are an onboarding coach for a civic app.
Generate one short, practical guidance tip for this tutorial step: "$title".
Constraints:
- max 180 characters
- plain text only
- actionable next step
''');
      if (!mounted) return;
      setState(() {
        _stepGuidance[step] = guidance.trim().isEmpty
            ? 'Use this step to understand core actions, then continue to the next screen.'
            : guidance.trim();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stepGuidance[step] =
            'Use this step to understand core actions, then continue to the next screen.';
      });
    }
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.accentLight, size: 5.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              feature,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestExampleCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.vibrantYellow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppTheme.vibrantYellow,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Daily Check-in Quest',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Visit the app daily to maintain your streak',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.vibrantYellow.withAlpha(26),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '+100 VP',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.vibrantYellow,
                  ),
                ),
              ),
              Text(
                'Progress: 3/7 days',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVotingExampleCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sample Election',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildVoteOption('Yes', 45, Colors.green),
          SizedBox(height: 1.h),
          _buildVoteOption('No', 35, Colors.red),
          SizedBox(height: 1.h),
          _buildVoteOption('Abstain', 20, Colors.grey),
          SizedBox(height: 2.h),
          Row(
            children: [
              Icon(Icons.verified, color: Colors.blue, size: 4.w),
              SizedBox(width: 2.w),
              Text(
                'Blockchain Verified',
                style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteOption(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: color.withAlpha(51),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildAnalyticsExampleCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.purple),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAnalyticsStat('1,250 VP', 'Voting Power'),
              _buildAnalyticsStat('5/10', 'Quests'),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAnalyticsStat('3 days', 'Streak'),
              _buildAnalyticsStat('#127', 'Rank'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricExampleCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        children: [
          Icon(Icons.fingerprint, size: 15.w, color: Colors.green),
          SizedBox(height: 2.h),
          Text(
            'Secure Your Vote',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 4.w, color: Colors.green),
              SizedBox(width: 2.w),
              Text(
                'End-to-end Encryption',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationExampleCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                'Nearby Elections',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildLocationItem('Community Park Renovation', '2.5 km'),
          SizedBox(height: 1.h),
          _buildLocationItem('Local School Board Election', '5.8 km'),
          SizedBox(height: 1.h),
          _buildLocationItem('City Budget Allocation', '12.3 km'),
        ],
      ),
    );
  }

  Widget _buildLocationItem(String title, String distance) {
    return Row(
      children: [
        Icon(Icons.circle, size: 2.w, color: AppTheme.primaryLight),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(title, style: GoogleFonts.inter(fontSize: 12.sp)),
        ),
        Text(
          distance,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryLight,
                  side: BorderSide(color: AppTheme.primaryLight),
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 3.w),
          Expanded(
            flex: _currentStep == 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isCompleting ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: _isCompleting
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _currentStep == _totalSteps - 1 ? 'Complete' : 'Next',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}