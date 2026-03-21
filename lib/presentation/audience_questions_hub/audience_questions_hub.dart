import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/audience_questions_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/question_card_widget.dart';
import './widgets/question_submission_widget.dart';
import './widgets/moderation_panel_widget.dart';
import './widgets/live_answers_widget.dart';

/// Audience Questions Hub - Comprehensive voter-submitted Q&A functionality
class AudienceQuestionsHub extends StatefulWidget {
  final String? electionId;

  const AudienceQuestionsHub({super.key, this.electionId});

  @override
  State<AudienceQuestionsHub> createState() => _AudienceQuestionsHubState();
}

class _AudienceQuestionsHubState extends State<AudienceQuestionsHub>
    with SingleTickerProviderStateMixin {
  final AudienceQuestionsService _questionsService =
      AudienceQuestionsService.instance;
  final AuthService _auth = AuthService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  String? _selectedElectionId;
  List<Map<String, dynamic>> _popularQuestions = [];
  List<Map<String, dynamic>> _myQuestions = [];
  int _pendingCount = 0;
  int _totalQuestions = 0;
  late bool _isCreator;
  RealtimeChannel? _questionsChannel;

  @override
  void initState() {
    super.initState();
    _selectedElectionId = widget.electionId;
    final role = (_auth.currentUser?.userMetadata?['role'] as String? ?? '')
        .toLowerCase();
    _isCreator = role == 'creator' || role == 'admin';
    _tabController = TabController(length: _isCreator ? 5 : 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _questionsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    if (_selectedElectionId != null) {
      await _loadQuestions();
      await _loadMyQuestions();
      _subscribeToQuestions();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadQuestions() async {
    if (_selectedElectionId == null) return;

    final questions = await _questionsService.getQuestions(
      electionId: _selectedElectionId!,
      sortBy: 'votes',
      statusFilter: 'approved',
    );

    final pending = await _questionsService.getPendingQuestionsCount(
      electionId: _selectedElectionId!,
    );

    setState(() {
      _popularQuestions = questions;
      _totalQuestions = questions.length;
      _pendingCount = pending;
    });
  }

  Future<void> _loadMyQuestions() async {
    final myQuestions = await _questionsService.getMyQuestions();
    setState(() => _myQuestions = myQuestions);
  }

  void _subscribeToQuestions() {
    if (_selectedElectionId == null) return;

    _questionsChannel = _questionsService.subscribeToQuestions(
      electionId: _selectedElectionId!,
      onQuestionAdded: (question) {
        _loadQuestions();
      },
      onQuestionUpdated: (question) {
        _loadQuestions();
      },
    );
  }

  Future<void> _handleVote(String questionId, String voteType) async {
    final currentVote = await _questionsService.getUserVote(
      questionId: questionId,
    );

    if (currentVote == voteType) {
      await _questionsService.removeVote(questionId: questionId);
    } else {
      await _questionsService.voteQuestion(
        questionId: questionId,
        voteType: voteType,
      );
    }

    await _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'AudienceQuestionsHub',
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: CustomAppBar(
          title: 'Audience Questions',
          actions: [
            if (_pendingCount > 0)
              Container(
                margin: EdgeInsets.only(right: 4.w),
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '$_pendingCount pending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState()
            : _selectedElectionId == null
            ? _buildNoElectionState()
            : Column(
                children: [
                  _buildHeader(theme),
                  _buildTabBar(theme),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        QuestionSubmissionWidget(
                          electionId: _selectedElectionId!,
                          onQuestionSubmitted: () {
                            _loadQuestions();
                            _loadMyQuestions();
                          },
                        ),
                        _buildPopularQuestionsTab(),
                        _buildMyQuestionsTab(),
                        LiveAnswersWidget(electionId: _selectedElectionId!),
                        if (_isCreator)
                          ModerationPanelWidget(
                            electionId: _selectedElectionId!,
                            onModerated: () {
                              _loadQuestions();
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            theme,
            'Total Questions',
            _totalQuestions.toString(),
            Icons.question_answer,
          ),
          _buildStatItem(
            theme,
            'Pending',
            _pendingCount.toString(),
            Icons.pending,
          ),
          _buildStatItem(
            theme,
            'Live Q&A',
            'Active',
            Icons.live_tv,
            color: AppTheme.accentLight,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? theme.colorScheme.primary, size: 20.sp),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(
          alpha: 0.6,
        ),
        indicatorColor: theme.colorScheme.primary,
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        tabs: [
          const Tab(text: 'Submit Question'),
          const Tab(text: 'Popular Questions'),
          const Tab(text: 'My Questions'),
          const Tab(text: 'Live Answers'),
          if (_isCreator) const Tab(text: 'Moderation'),
        ],
      ),
    );
  }

  Widget _buildPopularQuestionsTab() {
    if (_popularQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 48.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'No questions yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadQuestions,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _popularQuestions.length,
        itemBuilder: (context, index) {
          final question = _popularQuestions[index];
          return QuestionCardWidget(
            question: question,
            onVote: (voteType) => _handleVote(question['id'], voteType),
          );
        },
      ),
    );
  }

  Widget _buildMyQuestionsTab() {
    if (_myQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              'You have not submitted any questions',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyQuestions,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _myQuestions.length,
        itemBuilder: (context, index) {
          final question = _myQuestions[index];
          return QuestionCardWidget(
            question: question,
            showStatus: true,
            onVote: null,
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: SkeletonCard(height: 15.h),
      ),
    );
  }

  Widget _buildNoElectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.how_to_vote_outlined,
            size: 48.sp,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 2.h),
          Text(
            'No election selected',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
