import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/mcq_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import './widgets/export_options_widget.dart';
import './widgets/moderation_dashboard_widget.dart';
import './widgets/response_analytics_widget.dart';
import './widgets/text_question_config_widget.dart';
import './widgets/text_response_viewer_widget.dart';

class OpenEndedAnswerQuestionsBuilder extends StatefulWidget {
  const OpenEndedAnswerQuestionsBuilder({super.key});

  @override
  State<OpenEndedAnswerQuestionsBuilder> createState() =>
      _OpenEndedAnswerQuestionsBuilderState();
}

class _OpenEndedAnswerQuestionsBuilderState
    extends State<OpenEndedAnswerQuestionsBuilder>
    with SingleTickerProviderStateMixin {
  final MCQService _mcqService = MCQService.instance;
  final AuthService _auth = AuthService.instance;

  late TabController _tabController;
  bool _isLoading = false;
  String? _selectedElectionId;
  List<Map<String, dynamic>> _elections = [];
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadElections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadElections() async {
    setState(() => _isLoading = true);
    try {
      // Load user's elections (simplified - would use election service)
      setState(() {
        _elections = [];
      });
    } catch (e) {
      debugPrint('Load elections error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAnalytics() async {
    if (_selectedElectionId == null) return;

    setState(() => _isLoading = true);
    try {
      final analytics = await _mcqService.getFreeTextAnalytics(
        electionId: _selectedElectionId!,
      );
      setState(() => _analytics = analytics);
    } catch (e) {
      debugPrint('Load analytics error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'Open-Ended Answer Questions',
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(title: 'Open-Ended Answer Questions'),
        body: Column(
          children: [
            _buildElectionSelector(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        TextQuestionConfigWidget(
                          electionId: _selectedElectionId,
                          onConfigUpdated: _loadAnalytics,
                        ),
                        ResponseAnalyticsWidget(
                          electionId: _selectedElectionId,
                          analytics: _analytics,
                        ),
                        TextResponseViewerWidget(
                          electionId: _selectedElectionId,
                        ),
                        ExportOptionsWidget(electionId: _selectedElectionId),
                        ModerationDashboardWidget(
                          electionId: _selectedElectionId,
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
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Election',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedElectionId,
                hint: Text('Choose an election'),
                isExpanded: true,
                items: _elections.map((election) {
                  return DropdownMenuItem<String>(
                    value: election['id'],
                    child: Text(
                      election['title'] ?? 'Untitled Election',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedElectionId = value);
                  _loadAnalytics();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.accentLight,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'Configuration'),
          Tab(text: 'Analytics'),
          Tab(text: 'Responses'),
          Tab(text: 'Export'),
          Tab(text: 'Moderation'),
        ],
      ),
    );
  }
}
