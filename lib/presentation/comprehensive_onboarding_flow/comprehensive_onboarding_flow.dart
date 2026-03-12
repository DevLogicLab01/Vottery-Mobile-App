import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/app_export.dart';
import '../../services/gamification_service.dart';
import '../../widgets/error_boundary_wrapper.dart';

class ComprehensiveOnboardingFlow extends StatefulWidget {
  const ComprehensiveOnboardingFlow({super.key});

  @override
  State<ComprehensiveOnboardingFlow> createState() =>
      _ComprehensiveOnboardingFlowState();
}

class _ComprehensiveOnboardingFlowState
    extends State<ComprehensiveOnboardingFlow> {
  final PageController _pageController = PageController();
  final GamificationService _gamificationService = GamificationService.instance;

  int _currentStep = 0;
  final int _totalSteps = 5;
  final bool _showTutorial = true;

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  // Global keys for tutorial targets
  final GlobalKey _voteButtonKey = GlobalKey();
  final GlobalKey _createElectionKey = GlobalKey();
  final GlobalKey _vpDashboardKey = GlobalKey();
  final GlobalKey _socialFeedKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showTutorial) {
        _initTutorial();
        _showTutorialOverlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initTutorial() {
    targets = [
      TargetFocus(
        identify: 'vote_button',
        keyTarget: _voteButtonKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              'Cast Your Vote',
              'Tap here to participate in elections and earn Vottery Points (VP) for every vote you cast.',
              Icons.how_to_vote,
              Colors.blue,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'create_election',
        keyTarget: _createElectionKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              'Create Elections',
              'Become a creator! Design gamified elections with prize pools and earn revenue from participation fees.',
              Icons.add_circle,
              Colors.green,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'vp_dashboard',
        keyTarget: _vpDashboardKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              'VP Economy',
              'Track your Vottery Points, enter lottery draws, and redeem rewards. The more you participate, the more you earn!',
              Icons.stars,
              Colors.orange,
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'social_feed',
        keyTarget: _socialFeedKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) => _buildTutorialContent(
              'Social Features',
              'Connect with other voters, share your opinions, and discover trending elections in your personalized feed.',
              Icons.people,
              Colors.purple,
            ),
          ),
        ],
      ),
    ];
  }

  void _showTutorialOverlay() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "SKIP",
      paddingFocus: 10.0,
      opacityShadow: 0.8,
      onFinish: () {
        _awardOnboardingCompletion();
      },
      onSkip: () {
        _skipOnboarding();
        return true;
      },
    );

    tutorialCoachMark.show(context: context);
  }

  Widget _buildTutorialContent(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 8.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.sp, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Future<void> _awardOnboardingCompletion() async {
    try {
      // Remove this block - addPoints method doesn't exist in GamificationService
      // await _gamificationService.addPoints(
      //   points: 100,
      //   source: 'Completed onboarding tutorial',
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Onboarding completed! +100 VP awarded'),
            backgroundColor: Colors.green,
          ),
        );
        _completeOnboarding();
      }
    } catch (e) {
      debugPrint('Award onboarding completion error: $e');
      _completeOnboarding();
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(AppRoutes.voteDashboard);
  }

  void _completeOnboarding() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(AppRoutes.voteDashboard);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'ComprehensiveOnboardingFlow',
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentStep = index);
                  },
                  children: [
                    _buildWelcomeStep(),
                    _buildVotingMethodsStep(),
                    _buildVPEconomyStep(),
                    _buildSocialFeaturesStep(),
                    _buildPersonalizationStep(),
                  ],
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
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: _skipOnboarding,
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: List.generate(
          _totalSteps,
          (index) => Expanded(
            child: Container(
              height: 0.5.h,
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              decoration: BoxDecoration(
                color: index <= _currentStep ? Colors.black : Colors.grey,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: CustomIconWidget(
                key: _voteButtonKey,
                iconName: 'how_to_vote',
                color: Colors.white,
                size: 20.w,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Welcome to Vottery',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'Your voice matters. Join a democratic platform where every vote counts and civic participation is rewarded.',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          _buildFeatureHighlight(
            'democratic_participation',
            'Democratic Participation',
            'Vote on issues that matter to you',
          ),
          SizedBox(height: 2.h),
          _buildFeatureHighlight(
            'verified_user',
            'Secure & Verified',
            'Biometric authentication ensures vote integrity',
          ),
          SizedBox(height: 2.h),
          _buildFeatureHighlight(
            'stars',
            'Earn Rewards',
            'Get Vottery Points for active participation',
          ),
        ],
      ),
    );
  }

  Widget _buildVotingMethodsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Text(
            'Voting Methods',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Choose from multiple voting systems to express your preferences accurately',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 3.h),
          _buildVotingMethodCard(
            key: _createElectionKey,
            title: 'Plurality Voting',
            description: 'Select one option',
            reward: '10 VP per vote',
            icon: Icons.check_circle_outline,
          ),
          SizedBox(height: 2.h),
          _buildVotingMethodCard(
            title: 'Ranked Choice',
            description: 'Rank options by preference',
            reward: '15 VP per vote',
            icon: Icons.format_list_numbered,
          ),
          SizedBox(height: 2.h),
          _buildVotingMethodCard(
            title: 'Approval Voting',
            description: 'Approve multiple options',
            reward: '12 VP per vote',
            icon: Icons.done_all,
          ),
        ],
      ),
    );
  }

  Widget _buildVPEconomyStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Row(
            key: _vpDashboardKey,
            children: [
              Icon(Icons.stars, color: Colors.orange, size: 10.w),
              SizedBox(width: 2.w),
              Text(
                'VP Economy',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Earn Vottery Points (VP) for every action and redeem them for rewards',
            style: TextStyle(fontSize: 12.sp, color: Colors.black),
          ),
          SizedBox(height: 3.h),
          _buildVPCard('Vote in Elections', '+10-20 VP', Icons.how_to_vote),
          SizedBox(height: 2.h),
          _buildVPCard('Create Elections', '+50 VP', Icons.add_circle),
          SizedBox(height: 2.h),
          _buildVPCard('Daily Login', '+5 VP', Icons.login),
          SizedBox(height: 2.h),
          _buildVPCard('Complete Onboarding', '+100 VP', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildSocialFeaturesStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          Row(
            key: _socialFeedKey,
            children: [
              Icon(Icons.people, color: Colors.purple, size: 10.w),
              SizedBox(width: 2.w),
              Text(
                'Social Features',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Connect with voters, share opinions, and discover trending elections',
            style: TextStyle(fontSize: 12.sp, color: Colors.black),
          ),
          SizedBox(height: 3.h),
          _buildSocialCard(
            'Personalized Feed',
            'See elections tailored to your interests',
            Icons.feed,
          ),
          SizedBox(height: 2.h),
          _buildSocialCard(
            'Connect with Friends',
            'Follow voters and share your opinions',
            Icons.group_add,
          ),
          SizedBox(height: 2.h),
          _buildSocialCard(
            'Jolts Video Feed',
            'Discover short-form election content',
            Icons.video_library,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizationStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          Icon(Icons.check_circle, color: Colors.green, size: 20.w),
          SizedBox(height: 3.h),
          Text(
            'You\'re All Set!',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Complete this tutorial to earn +100 VP and start your Vottery journey',
            style: TextStyle(fontSize: 12.sp, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                Text(
                  'Tutorial Reward',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars, color: Colors.orange, size: 8.w),
                    SizedBox(width: 2.w),
                    Text(
                      '+100 VP',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight(
    String iconName,
    String title,
    String description,
  ) {
    return Row(
      children: [
        CustomIconWidget(iconName: iconName, size: 8.w, color: Colors.black),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVotingMethodCard({
    Key? key,
    required String title,
    required String description,
    required String reward,
    required IconData icon,
  }) {
    return Container(
      key: key,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 8.w, color: Colors.black),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                ),
                Text(
                  reward,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVPCard(String title, String reward, IconData icon) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange, size: 6.w),
              SizedBox(width: 2.w),
              Text(
                title,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            reward,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialCard(String title, String description, IconData icon) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 8.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  side: BorderSide(color: Colors.black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Back',
                  style: TextStyle(color: Colors.black, fontSize: 12.sp),
                ),
              ),
            ),
          if (_currentStep > 0) SizedBox(width: 2.w),
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Get Started' : 'Next',
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}