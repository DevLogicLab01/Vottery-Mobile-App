import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/prediction_service.dart';
import '../../services/auth_service.dart';
import '../../services/voting_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../enhanced_vote_casting/widgets/plurality_voting_widget.dart';
import '../enhanced_vote_casting/widgets/ranked_choice_voting_widget.dart';
import '../enhanced_vote_casting/widgets/approval_voting_widget.dart';
import '../enhanced_vote_casting/widgets/plus_minus_voting_widget.dart';
import './widgets/prediction_bottom_sheet_widget.dart';
import './widgets/live_prediction_tracker_widget.dart';

/// Enhanced Vote Casting with Prediction Integration
/// Integrates comprehensive prediction functionality across all voting methods
/// with gamified prediction mechanics and live tracking.
class EnhancedVoteCastingWithPredictionIntegration extends StatefulWidget {
  const EnhancedVoteCastingWithPredictionIntegration({super.key});

  @override
  State<EnhancedVoteCastingWithPredictionIntegration> createState() =>
      _EnhancedVoteCastingWithPredictionIntegrationState();
}

class _EnhancedVoteCastingWithPredictionIntegrationState
    extends State<EnhancedVoteCastingWithPredictionIntegration>
    with SingleTickerProviderStateMixin {
  final PredictionService _predictionService = PredictionService.instance;
  final AuthService _authService = AuthService.instance;
  final VotingService _votingService = VotingService.instance;

  late TabController _tabController;

  // Election data (from route arguments or mock)
  late String _electionId;
  late String _electionTitle;
  late String _electionType;
  late List<Map<String, dynamic>> _options;

  // Voting state
  String? _selectedOptionId;
  List<String> _rankedChoices = [];
  Set<String> _approvedOptions = {};
  Map<String, int> _plusMinusScores = {};

  // Prediction state
  Map<String, double>? _lockedPrediction;
  bool _predictionSubmitted = false;
  bool _isSubmittingVote = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeElectionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeElectionData() {
    // Default mock data - in production, this comes from route arguments
    _electionId = 'election_demo_001';
    _electionTitle = 'Community Budget Allocation 2026';
    _electionType = 'plurality';
    _options = [
      {
        'id': 'opt_a',
        'title': 'Infrastructure & Roads',
        'description': 'Invest in road repairs and public infrastructure',
      },
      {
        'id': 'opt_b',
        'title': 'Education & Schools',
        'description': 'Expand school programs and teacher salaries',
      },
      {
         'id': 'opt_c',
        'title': 'Healthcare Services',
        'description': 'Improve local healthcare facilities',
      },
      {
        'id': 'opt_d',
        'title': 'Green Energy',
        'description': 'Renewable energy and sustainability projects',
      },
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      setState(() {
        _electionId = args['election_id'] as String? ?? _electionId;
        _electionTitle = args['election_title'] as String? ?? _electionTitle;
        _electionType = args['election_type'] as String? ?? _electionType;
        if (args['options'] != null) {
          _options = List<Map<String, dynamic>>.from(
            args['options'] as List,
          );
        }
      });
    }
  }

  void _openPredictionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) =>
            PredictionBottomSheetWidget(
          electionId: _electionId,
          electionType: _electionType,
          options: _options,
          onSubmitPrediction: (predictions) {
            setState(() {
              _lockedPrediction = predictions;
              _predictionSubmitted = true;
            });
            _savePredictionToService(predictions);
          },
        ),
      ),
    );
  }

  Future<void> _savePredictionToService(
    Map<String, double> predictions,
  ) async {
    try {
      await _predictionService.enterPredictionPool(
        poolId: _electionId,
        predictedOutcome: predictions.map(
          (k, v) => MapEntry(k, v),
        ),
        confidenceLevel: predictions.values.isNotEmpty
            ? predictions.values.reduce((a, b) => a > b ? a : b) / 100.0
            : 0.5,
      );
    } catch (e) {
      debugPrint('Save prediction error: $e');
    }
  }

  Future<void> _submitVote() async {
    setState(() => _isSubmittingVote = true);
    try {
      final result = await _votingService.castVoteWithReceipt(
        electionId: _electionId,
        selectedOptionId: _electionType == 'plurality' ? _selectedOptionId : null,
        rankedChoices: _electionType == 'ranked_choice' ? _rankedChoices : null,
        selectedOptions:
            _electionType == 'approval' ? _approvedOptions.toList() : null,
        voteScores: _electionType == 'plus_minus' ? _plusMinusScores : null,
      );

      if (!mounted) return;
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vote submitted successfully! +10 VP earned'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to submit vote'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vote submission failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingVote = false);
      }
    }
  }

  bool get _canSubmitVote {
    switch (_electionType) {
      case 'plurality':
        return _selectedOptionId != null;
      case 'ranked_choice':
        return _rankedChoices.isNotEmpty;
      case 'approval':
        return _approvedOptions.isNotEmpty;
      case 'plus_minus':
        return _plusMinusScores.values.any((s) => s != 0);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedVoteCastingWithPredictionIntegration',
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Vote & Predict',
          subtitle: _electionTitle,
          actions: [
            IconButton(
              onPressed: _openPredictionBottomSheet,
              icon: const Icon(Icons.trending_up),
              tooltip: 'Predict Outcome',
            ),
          ],
        ),
        body: Column(
          children: [
            // Election type tabs
            Container(
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                onTap: (index) {
                  final types = [
                    'plurality',
                    'ranked_choice',
                    'approval',
                    'plus_minus',
                  ];
                  setState(() {
                    _electionType = types[index];
                    // Reset voting state on type change
                    _selectedOptionId = null;
                    _rankedChoices = [];
                    _approvedOptions = {};
                    _plusMinusScores = {};
                  });
                },
                tabs: const [
                  Tab(text: 'Plurality'),
                  Tab(text: 'Ranked Choice'),
                  Tab(text: 'Approval'),
                  Tab(text: 'Plus-Minus'),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),

                    // Election info card
                    _buildElectionInfoCard(context),

                    SizedBox(height: 2.h),

                    // Voting widget based on type
                    _buildVotingWidget(context),

                    SizedBox(height: 3.h),

                    // Live prediction tracker (shown after prediction submitted)
                    if (_predictionSubmitted && _lockedPrediction != null) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: LivePredictionTrackerWidget(
                          electionId: _electionId,
                          userPredictions: _lockedPrediction!,
                          options: _options,
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],

                    // Prediction status banner
                    if (_predictionSubmitted)
                      _buildPredictionStatusBanner(context),

                    SizedBox(height: 2.h),

                    // Submit vote button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              (_canSubmitVote && !_isSubmittingVote)
                              ? _submitVote
                              : null,
                          icon: _isSubmittingVote
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.how_to_vote),
                          label: Text(
                            _isSubmittingVote ? 'Submitting...' : 'Submit Vote',
                            style: TextStyle(fontSize: 15.sp),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 1.8.h),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openPredictionBottomSheet,
          icon: const Icon(Icons.trending_up),
          label: const Text('Predict'),
          backgroundColor: _predictionSubmitted
              ? theme.colorScheme.secondary
              : theme.colorScheme.primary,
          foregroundColor: _predictionSubmitted
              ? theme.colorScheme.onSecondary
              : theme.colorScheme.onPrimary,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildElectionInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _electionTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.3.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        _electionType.replaceAll('_', ' ').toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${_options.length} options',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // VP reward indicator
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 24),
                Text(
                  '+10 VP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingWidget(BuildContext context) {
    switch (_electionType) {
      case 'plurality':
        return PluralityVotingWidget(
          options: _options,
          selectedOptionId: _selectedOptionId,
          onOptionSelected: (id) => setState(() => _selectedOptionId = id),
        );
      case 'ranked_choice':
        return RankedChoiceVotingWidget(
          options: _options,
          rankedChoices: _rankedChoices,
          onRankingChanged: (ranks) => setState(() => _rankedChoices = ranks),
        );
      case 'approval':
        return ApprovalVotingWidget(
          options: _options,
          approvedOptions: _approvedOptions,
          onApprovalChanged: (id, approved) {
            setState(() {
              if (approved) {
                _approvedOptions.add(id);
              } else {
                _approvedOptions.remove(id);
              }
            });
          },
        );
      case 'plus_minus':
        return PlusMinusVotingWidget(
          options: _options,
          scores: _plusMinusScores,
          onScoreChanged: (id, score) =>
              setState(() => _plusMinusScores[id] = score),
        );
      default:
        return PluralityVotingWidget(
          options: _options,
          selectedOptionId: _selectedOptionId,
          onOptionSelected: (id) => setState(() => _selectedOptionId = id),
        );
    }
  }

  Widget _buildPredictionStatusBanner(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: theme.colorScheme.onTertiaryContainer,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Prediction locked! Track your accuracy in real-time above.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _openPredictionBottomSheet,
            child: Text(
              'Update',
              style: TextStyle(
                color: theme.colorScheme.onTertiaryContainer,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}