import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/gamification_service.dart';
import '../../services/voting_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/approval_voting_widget.dart';
import './widgets/plurality_voting_widget.dart';
import './widgets/plus_minus_voting_widget.dart';
import './widgets/ranked_choice_voting_widget.dart';
import './widgets/submission_celebration_widget.dart';
import './widgets/vp_reward_preview_widget.dart';

/// Enhanced Vote Casting screen supporting multiple voting methods:
/// - Plurality: Traditional single-choice voting
/// - Ranked Choice: Drag-to-reorder candidate list with numbered rankings
/// - Approval: Multi-select checkboxes with selection counter
/// - Plus-Minus: Thumbs up/down buttons with intensity sliders
/// Includes VP earning integration, gamified interactions, and achievement progress
class EnhancedVoteCasting extends StatefulWidget {
  const EnhancedVoteCasting({super.key});

  @override
  State<EnhancedVoteCasting> createState() => _EnhancedVoteCastingState();
}

class _EnhancedVoteCastingState extends State<EnhancedVoteCasting>
    with SingleTickerProviderStateMixin {
  // Vote data
  final Map<String, dynamic> voteData = {
    "id": "vote_enhanced_001",
    "title": "City Budget Allocation 2026",
    "description":
        "Vote on how the city should allocate the 2026 budget across different departments and initiatives. Your participation earns you VP and helps shape our community.",
    "voteType": "plurality", // plurality, ranked_choice, approval, plus_minus
    "vpReward": 10,
    "streakMultiplier": 1.5,
    "deadline": DateTime.now().add(const Duration(days: 3)),
    "options": [
      {
        "id": "opt_1",
        "title": "Education & Schools",
        "description": "Invest in educational infrastructure and programs",
        "imageUrl":
            "https://img.rocket.new/generatedImages/rocket_gen_img_1730ad428-1764655063619.png",
        "semanticLabel":
            "Modern classroom with students working at desks with natural lighting",
      },
      {
        "id": "opt_2",
        "title": "Healthcare Services",
        "description": "Expand healthcare facilities and services",
        "imageUrl":
            "https://images.unsplash.com/photo-1706958581603-dffa91fec580",
        "semanticLabel":
            "Healthcare professional in white coat with stethoscope in hospital setting",
      },
      {
        "id": "opt_3",
        "title": "Public Transportation",
        "description": "Improve public transit infrastructure",
        "imageUrl":
            "https://images.unsplash.com/photo-1678771339843-b6fb1a09ba7d",
        "semanticLabel":
            "Modern city bus on urban street with passengers boarding",
      },
      {
        "id": "opt_4",
        "title": "Parks & Recreation",
        "description": "Develop green spaces and recreational facilities",
        "imageUrl":
            "https://images.unsplash.com/photo-1673800913127-53e0e9ecb5e5",
        "semanticLabel":
            "Lush green park with walking paths and families enjoying outdoor activities",
      },
    ],
  };

  // State management
  String? selectedOptionId;
  List<String> rankedChoices = [];
  Set<String> approvedOptions = {};
  Map<String, int> plusMinusScores = {};
  bool isSubmitting = false;
  bool showCelebration = false;
  Map<String, dynamic>? vpEarned;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Add this method
  Future<void> _loadElectionDetails() async {
    // Reload or refresh election details if needed
    setState(() {});
  }

  bool get canSubmit {
    switch (voteData["voteType"]) {
      case "plurality":
        return selectedOptionId != null;
      case "ranked_choice":
        return rankedChoices.isNotEmpty;
      case "approval":
        return approvedOptions.isNotEmpty;
      case "plus_minus":
        return plusMinusScores.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (showCelebration && vpEarned != null) {
      return SubmissionCelebrationWidget(
        vpEarned: vpEarned!,
        onContinue: () {
          Navigator.pop(context);
        },
      );
    }

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedVoteCasting',
      onRetry: _loadElectionDetails,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Cast Your Vote',
          variant: CustomAppBarVariant.withBack,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'stars',
                    color: theme.colorScheme.tertiary,
                    size: 20,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '+${(voteData["vpReward"] * voteData["streakMultiplier"]).round()} VP',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),

                    // Vote Info Header
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vote Type Indicator
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconWidget(
                                  iconName: _getVoteTypeIcon(),
                                  color: theme.colorScheme.primary,
                                  size: 16,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  _getVoteTypeLabel(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 2.h),

                          // Title
                          Text(
                            voteData["title"],
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),

                          SizedBox(height: 1.h),

                          // Description
                          Text(
                            voteData["description"],
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),

                          SizedBox(height: 2.h),

                          // VP Reward Preview
                          VPRewardPreviewWidget(
                            baseVP: voteData["vpReward"],
                            streakMultiplier: voteData["streakMultiplier"],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Voting Interface (based on vote type)
                    _buildVotingInterface(theme),

                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ),

            // Submit Button
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: canSubmit && !isSubmitting ? _submitVote : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : Text(
                        'Submit Vote',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingInterface(ThemeData theme) {
    switch (voteData["voteType"]) {
      case "plurality":
        return PluralityVotingWidget(
          options: List<Map<String, dynamic>>.from(voteData["options"]),
          selectedOptionId: selectedOptionId,
          onOptionSelected: (optionId) {
            setState(() => selectedOptionId = optionId);
          },
        );

      case "ranked_choice":
        return RankedChoiceVotingWidget(
          options: List<Map<String, dynamic>>.from(voteData["options"]),
          rankedChoices: rankedChoices,
          onRankingChanged: (newRanking) {
            setState(() => rankedChoices = newRanking);
          },
        );

      case "approval":
        return ApprovalVotingWidget(
          options: List<Map<String, dynamic>>.from(voteData["options"]),
          approvedOptions: approvedOptions,
          onApprovalChanged: (optionId, approved) {
            setState(() {
              if (approved) {
                approvedOptions.add(optionId);
              } else {
                approvedOptions.remove(optionId);
              }
            });
          },
        );

      case "plus_minus":
        return PlusMinusVotingWidget(
          options: List<Map<String, dynamic>>.from(voteData["options"]),
          scores: plusMinusScores,
          onScoreChanged: (optionId, score) {
            setState(() => plusMinusScores[optionId] = score);
          },
        );

      default:
        return Container();
    }
  }

  String _getVoteTypeIcon() {
    switch (voteData["voteType"]) {
      case "plurality":
        return 'radio_button_checked';
      case "ranked_choice":
        return 'format_list_numbered';
      case "approval":
        return 'check_box';
      case "plus_minus":
        return 'thumbs_up_down';
      default:
        return 'how_to_vote';
    }
  }

  String _getVoteTypeLabel() {
    switch (voteData["voteType"]) {
      case "plurality":
        return 'Plurality Voting';
      case "ranked_choice":
        return 'Ranked Choice';
      case "approval":
        return 'Approval Voting';
      case "plus_minus":
        return 'Plus-Minus Voting';
      default:
        return 'Vote';
    }
  }

  Future<void> _submitVote() async {
    setState(() => isSubmitting = true);

    try {
      // Prepare vote data based on type
      Map<String, dynamic> voteSubmission = {'election_id': voteData['id']};

      switch (voteData["voteType"]) {
        case "plurality":
          voteSubmission['selected_option_id'] = selectedOptionId;
          break;
        case "ranked_choice":
          voteSubmission['ranked_choices'] = rankedChoices;
          break;
        case "approval":
          voteSubmission['selected_options'] = approvedOptions.toList();
          break;
        case "plus_minus":
          voteSubmission['vote_scores'] = plusMinusScores;
          break;
      }

      // Submit vote and capture cryptographic receipt
      final result = await VotingService.instance.castVoteWithReceipt(
        electionId: voteData['id'],
        selectedOptionId: voteSubmission['selected_option_id'],
        rankedChoices: voteSubmission['ranked_choices'],
        selectedOptions: voteSubmission['selected_options'],
        voteScores: voteSubmission['vote_scores'],
      );

      if (result.success) {
        // Get VP and streak info
        final vpBalance = await VPService.instance.getVPBalance();
        final streak = await GamificationService.instance.getUserStreak();

        setState(() {
          vpEarned = {
            'vp_amount': (voteData["vpReward"] * voteData["streakMultiplier"])
                .round(),
            'streak_days': streak?['current_streak'] ?? 0,
            'streak_bonus': streak?['bonus_awarded'] ?? false,
            'total_vp': vpBalance?['available_vp'] ?? 0,
          };

          // Attach a short vote receipt snippet for verification parity with Web
          final receipt = result.receipt;
          final voteHash = (receipt?['voteHash'] as String?) ?? '';
          if (voteHash.isNotEmpty) {
            final shortCode =
                voteHash.length > 12 ? '${voteHash.substring(0, 12)}…' : voteHash;
            vpEarned?['vote_receipt'] = shortCode;
          }

          showCelebration = true;
        });

        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Submit vote error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit vote. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }
}
