import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../core/app_export.dart';
import '../../services/mcq_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/question_builder_widget.dart';
import './widgets/injection_queue_widget.dart';
import './widgets/live_broadcast_panel_widget.dart';
import './widgets/response_analytics_widget.dart';

class LiveQuestionInjectionControlCenter extends StatefulWidget {
  const LiveQuestionInjectionControlCenter({super.key});

  @override
  State<LiveQuestionInjectionControlCenter> createState() =>
      _LiveQuestionInjectionControlCenterState();
}

class _LiveQuestionInjectionControlCenterState
    extends State<LiveQuestionInjectionControlCenter>
    with SingleTickerProviderStateMixin {
  final MCQService _mcqService = MCQService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  String? _selectedElectionId;
  List<Map<String, dynamic>> _injectionQueue = [];
  Map<String, dynamic> _liveSessionStatus = {};
  int _activeVotersCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // Simulate loading election data
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _selectedElectionId = 'election_001';
      _activeVotersCount = 247;
      _liveSessionStatus = {
        'status': 'active',
        'active_voters': 247,
        'pending_injections': 3,
        'total_injected': 12,
      };
      _isLoading = false;
    });

    _loadInjectionQueue();
  }

  Future<void> _loadInjectionQueue() async {
    if (_selectedElectionId == null) return;

    final queue = await _mcqService.getLiveQuestionInjectionQueue(
      _selectedElectionId!,
    );
    setState(() => _injectionQueue = queue);
  }

  Future<void> _broadcastQuestion(String injectionId) async {
    if (_selectedElectionId == null) return;

    final result = await _mcqService.broadcastLiveQuestion(
      injectionId: injectionId,
      electionId: _selectedElectionId!,
    );

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Question broadcasted to ${result['active_voters_count']} active voters',
          ),
          backgroundColor: AppTheme.accentLight,
        ),
      );
      _loadInjectionQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'LiveQuestionInjectionControlCenter',
      onRetry: _loadInitialData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Live Question Injection',
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadInitialData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildLiveSessionHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        QuestionBuilderWidget(
                          electionId: _selectedElectionId ?? '',
                          onQuestionCreated: _loadInjectionQueue,
                        ),
                        InjectionQueueWidget(
                          injectionQueue: _injectionQueue,
                          onBroadcast: _broadcastQuestion,
                          onDelete: (id) async {
                            await _mcqService.deleteLiveQuestionInjection(id);
                            _loadInjectionQueue();
                          },
                          onEdit: (id, updates) async {
                            await _mcqService.updateLiveQuestionInjection(
                              injectionId: id,
                              updates: updates,
                            );
                            _loadInjectionQueue();
                          },
                        ),
                        LiveBroadcastPanelWidget(
                          electionId: _selectedElectionId ?? '',
                          activeVotersCount: _activeVotersCount,
                        ),
                        ResponseAnalyticsWidget(
                          electionId: _selectedElectionId ?? '',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLiveSessionHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3.w,
                height: 3.w,
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'LIVE SESSION',
                style: google_fonts.GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentLight,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight.withAlpha(26),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 4.w, color: AppTheme.accentLight),
                    SizedBox(width: 1.w),
                    Text(
                      '$_activeVotersCount Active',
                      style: google_fonts.GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildStatusMetric(
                'Pending',
                _liveSessionStatus['pending_injections']?.toString() ?? '0',
                Icons.schedule,
                Colors.orange,
              ),
              SizedBox(width: 4.w),
              _buildStatusMetric(
                'Injected',
                _liveSessionStatus['total_injected']?.toString() ?? '0',
                Icons.check_circle,
                Colors.green,
              ),
              SizedBox(width: 4.w),
              _buildStatusMetric(
                'Engagement',
                '87%',
                Icons.trending_up,
                AppTheme.primaryLight,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 5.w, color: color),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: google_fonts.GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: google_fonts.GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Question Builder'),
          Tab(text: 'Injection Queue'),
          Tab(text: 'Live Broadcast'),
          Tab(text: 'Response Analytics'),
        ],
      ),
    );
  }
}
