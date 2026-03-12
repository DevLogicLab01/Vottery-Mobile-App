import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../../core/app_export.dart';
import '../../services/ga4_analytics_service.dart';
import '../../services/gamification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/achievement_rewards_widget.dart';
import './widgets/tutorial_progress_tracker_widget.dart';
import './widgets/tutorial_replay_widget.dart';

class InteractiveTutorialOverlaySystem extends StatefulWidget {
  const InteractiveTutorialOverlaySystem({super.key});

  @override
  State<InteractiveTutorialOverlaySystem> createState() =>
      _InteractiveTutorialOverlaySystemState();
}

class _InteractiveTutorialOverlaySystemState
    extends State<InteractiveTutorialOverlaySystem> {
  final GA4AnalyticsService _analytics = GA4AnalyticsService.instance;
  final GamificationService _gamification = GamificationService.instance;

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  final GlobalKey _electionCreationKey = GlobalKey();
  final GlobalKey _votingProcessKey = GlobalKey();
  final GlobalKey _gamificationKey = GlobalKey();
  final GlobalKey _monetizationKey = GlobalKey();

  final Map<String, bool> _moduleCompletion = {
    'election_creation': false,
    'voting_process': false,
    'gamification_mechanics': false,
    'creator_monetization': false,
  };

  int _vpEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTutorial();
    });
  }

  Future<void> _loadProgress() async {
    // Load saved tutorial progress
    setState(() {
      _vpEarned = _moduleCompletion.values.where((v) => v).length * 50;
    });
  }

  void _initTutorial() {
    targets = [
      TargetFocus(
        identify: "election_creation",
        keyTarget: _electionCreationKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 8.0,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                'Create Elections',
                'Learn how to create engaging elections with multiple voting types, MCQs, and video requirements',
                Icons.how_to_vote,
                Colors.blue,
                controller,
                1,
                4,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "voting_process",
        keyTarget: _votingProcessKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 8.0,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                'Voting Process',
                'Discover how to cast votes using plurality, ranked choice, approval, or plus-minus voting methods',
                Icons.how_to_reg,
                Colors.green,
                controller,
                2,
                4,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "gamification",
        keyTarget: _gamificationKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 8.0,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                'Gamification Mechanics',
                'Earn Vottery Points (VP) for voting, completing quests, and participating in gamified elections',
                Icons.stars,
                Colors.amber,
                controller,
                3,
                4,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "monetization",
        keyTarget: _monetizationKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 8.0,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                'Creator Monetization',
                'Monetize your elections through participation fees, brand partnerships, and marketplace services',
                Icons.attach_money,
                Colors.purple,
                controller,
                4,
                4,
              );
            },
          ),
        ],
      ),
    ];
  }

  void _showTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        _completeTutorial();
      },
      onClickTarget: (target) {
        _trackModuleViewed(target.identify);
      },
      onSkip: () {
        _analytics.trackScreenView(screenName: 'tutorial_skipped');
        return true;
      },
    );

    tutorialCoachMark.show(context: context);
  }

  Future<void> _completeTutorial() async {
    setState(() {
      _moduleCompletion.updateAll((key, value) => true);
      _vpEarned = 200; // 50 VP per module
    });

    // Award XP instead of VP using the correct method
    await _gamification.addXP(200, 'tutorial_completion');

    await _analytics.trackScreenView(screenName: 'tutorial_completed');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tutorial completed! You earned 200 VP'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _trackModuleViewed(String moduleId) {
    setState(() {
      _moduleCompletion[moduleId] = true;
    });

    _analytics.trackScreenView(screenName: 'tutorial_module_$moduleId');
  }

  @override
  Widget build(BuildContext context) {
    final completionPercentage =
        (_moduleCompletion.values.where((v) => v).length /
                _moduleCompletion.length *
                100)
            .toInt();

    return ErrorBoundaryWrapper(
      screenName: 'InteractiveTutorialOverlaySystem',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('Interactive Tutorial'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Tutorial Help'),
                    content: const Text(
                      'Follow the guided tour to learn about core platform features. Complete all modules to earn 200 VP!',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TutorialProgressTrackerWidget(
                completionPercentage: completionPercentage,
                moduleCompletion: _moduleCompletion,
              ),
              SizedBox(height: 3.h),
              Text(
                'Tutorial Modules',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              _buildModuleCard(
                'Election Creation Wizard',
                'Learn how to create engaging elections',
                _electionCreationKey,
                'election_creation',
                Icons.how_to_vote,
                Colors.blue,
              ),
              SizedBox(height: 2.h),
              _buildModuleCard(
                'Voting Process Tutorial',
                'Master different voting methods',
                _votingProcessKey,
                'voting_process',
                Icons.how_to_reg,
                Colors.green,
              ),
              SizedBox(height: 2.h),
              _buildModuleCard(
                'Gamification Mechanics',
                'Understand VP economy and rewards',
                _gamificationKey,
                'gamification_mechanics',
                Icons.stars,
                Colors.amber,
              ),
              SizedBox(height: 2.h),
              _buildModuleCard(
                'Creator Monetization',
                'Explore revenue opportunities',
                _monetizationKey,
                'creator_monetization',
                Icons.attach_money,
                Colors.purple,
              ),
              SizedBox(height: 3.h),
              AchievementRewardsWidget(vpEarned: _vpEarned),
              SizedBox(height: 2.h),
              TutorialReplayWidget(onReplay: _showTutorial),
              SizedBox(height: 3.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showTutorial,
                  icon: Icon(Icons.play_arrow, size: 20.sp),
                  label: Text(
                    'Start Tutorial',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC629),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    String title,
    String description,
    GlobalKey key,
    String moduleId,
    IconData icon,
    Color color,
  ) {
    final isCompleted = _moduleCompletion[moduleId] ?? false;

    return Card(
      key: key,
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialContent(
    String title,
    String description,
    IconData icon,
    Color color,
    TutorialCoachMarkController controller,
    int currentStep,
    int totalSteps,
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: color, size: 24.sp),
              ),
              SizedBox(width: 3.w),
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
          SizedBox(height: 2.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $currentStep of $totalSteps',
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
              Row(
                children: [
                  if (currentStep > 1)
                    TextButton(
                      onPressed: () => controller.previous(),
                      child: Text(
                        'Previous',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  SizedBox(width: 2.w),
                  ElevatedButton(
                    onPressed: () => controller.next(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      currentStep == totalSteps ? 'Finish' : 'Next',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
