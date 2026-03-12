import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/audience_questions_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/moderation_queue_widget.dart';
import './widgets/live_qa_dashboard_widget.dart';
import './widgets/question_analytics_widget.dart';
import './widgets/moderation_history_widget.dart';
import './widgets/qa_status_overview_widget.dart';

/// Creator Q&A Management Center - Comprehensive question moderation and live answering interface
class CreatorQAManagementCenter extends StatefulWidget {
  final String? electionId;

  const CreatorQAManagementCenter({super.key, this.electionId});

  @override
  State<CreatorQAManagementCenter> createState() =>
      _CreatorQAManagementCenterState();
}

class _CreatorQAManagementCenterState extends State<CreatorQAManagementCenter>
    with SingleTickerProviderStateMixin {
  final AudienceQuestionsService _questionsService =
      AudienceQuestionsService.instance;
  final AuthService _auth = AuthService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  String? _selectedElectionId;
  int _pendingCount = 0;
  int _moderationQueueLength = 0;
  bool _liveSessionActive = false;
  Map<String, dynamic> _qaStats = {};
  RealtimeChannel? _questionsChannel;

  @override
  void initState() {
    super.initState();
    _selectedElectionId = widget.electionId;
    _tabController = TabController(length: 4, vsync: this);
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
      await _loadQAStats();
      _subscribeToQuestions();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadQAStats() async {
    if (_selectedElectionId == null) return;

    final pending = await _questionsService.getPendingQuestionsCount(
      electionId: _selectedElectionId!,
    );

    // Remove this block - getFlaggedQuestionsCount method doesn't exist
    // final flagged = await _questionsService.getFlaggedQuestionsCount(
    //   electionId: _selectedElectionId!,
    // );

    setState(() {
      _pendingCount = pending;
      _moderationQueueLength =
          pending; // Change to just pending without flagged
      _qaStats = {
        'pending': pending,
        'flagged': 0, // Set flagged to 0 as the method doesn't exist
        'total': pending, // Change to just pending
      };
    });
  }

  void _subscribeToQuestions() {
    if (_selectedElectionId == null) return;

    _questionsChannel = _questionsService.subscribeToQuestions(
      electionId: _selectedElectionId!,
      onQuestionAdded: (question) {
        if (mounted) {
          _loadQAStats();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New question submitted'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onQuestionUpdated: (question) {
        if (mounted) {
          _loadQAStats();
        }
      },
      // Remove onQuestionDeleted parameter - it doesn't exist in subscribeToQuestions
    );
  }

  void _toggleLiveSession() {
    setState(() {
      _liveSessionActive = !_liveSessionActive;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _liveSessionActive
              ? 'Live Q&A session started'
              : 'Live Q&A session ended',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName:
          'Creator Q&A Management Center', // Add required screenName parameter
      child: Scaffold(
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor, // Use Theme instead of AppTheme.backgroundColor
        appBar: CustomAppBar(
          title: 'Creator Q&A Management',
          actions: [
            IconButton(
              icon: Icon(
                _liveSessionActive ? Icons.stop_circle : Icons.play_circle,
                color: _liveSessionActive ? Colors.red : Colors.green,
              ),
              onPressed: _toggleLiveSession,
              tooltip: _liveSessionActive
                  ? 'Stop Live Session'
                  : 'Start Live Session',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadQAStats,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _selectedElectionId == null
            ? _buildElectionSelector()
            : Column(
                children: [
                  QAStatusOverviewWidget(
                    pendingCount: _pendingCount,
                    moderationQueueLength: _moderationQueueLength,
                    liveSessionActive: _liveSessionActive,
                    stats: _qaStats,
                  ),
                  SizedBox(height: 2.h),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme
                        .primaryLight, // Use AppTheme.primaryLight instead of primaryColor
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppTheme
                        .primaryLight, // Use AppTheme.primaryLight instead of primaryColor
                    tabs: const [
                      Tab(text: 'Moderation Queue'),
                      Tab(text: 'Live Q&A'),
                      Tab(text: 'Analytics'),
                      Tab(text: 'History'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ModerationQueueWidget(
                          electionId: _selectedElectionId!,
                          onModerationComplete: _loadQAStats,
                        ),
                        LiveQADashboardWidget(
                          electionId: _selectedElectionId!,
                          isLiveSessionActive: _liveSessionActive,
                        ),
                        QuestionAnalyticsWidget(
                          electionId: _selectedElectionId!,
                        ),
                        ModerationHistoryWidget(
                          electionId: _selectedElectionId!,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildElectionSelector() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.question_answer, size: 64, color: Colors.grey[400]),
          SizedBox(height: 2.h),
          Text(
            'Select an election to manage Q&A',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
