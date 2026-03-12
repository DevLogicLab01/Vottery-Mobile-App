import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../services/enhanced_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/session_video_replay_widget.dart';
import './widgets/console_log_capture_widget.dart';
import './widgets/network_request_monitoring_widget.dart';
import './widgets/custom_event_tracking_widget.dart';
import './widgets/session_player_controls_widget.dart';
import './widgets/performance_regression_widget.dart';
import './widgets/user_feedback_widget.dart';
import './widgets/analytics_dashboard_widget.dart';

class LogRocketSessionReplayMonitoringCenter extends StatefulWidget {
  const LogRocketSessionReplayMonitoringCenter({super.key});

  @override
  State<LogRocketSessionReplayMonitoringCenter> createState() =>
      _LogRocketSessionReplayMonitoringCenterState();
}

class _LogRocketSessionReplayMonitoringCenterState
    extends State<LogRocketSessionReplayMonitoringCenter>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late TabController _tabController;
  bool _isLoading = false;
  bool _autoRefreshEnabled = true;
  Timer? _refreshTimer;

  Map<String, dynamic> _sessionOverview = {};
  List<Map<String, dynamic>> _activeSessions = [];
  List<Map<String, dynamic>> _consoleLogs = [];
  List<Map<String, dynamic>> _networkRequests = [];
  List<Map<String, dynamic>> _customEvents = [];
  List<Map<String, dynamic>> _performanceRegressions = [];
  List<Map<String, dynamic>> _userFeedback = [];
  Map<String, dynamic> _analyticsData = {};

  String? _selectedSessionId;
  final List<String> _screenFilters = [
    'All Screens',
    'Vote Casting',
    'Election Creation',
    'Payment Processing',
    'Social Feed',
  ];
  String _selectedScreenFilter = 'All Screens';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMonitoringData();
    _setupAutoRefresh();
    EnhancedAnalyticsService.instance.trackScreenView(
      screenName: 'LogRocket Session Replay Monitoring Center',
      screenClass: 'LogRocketSessionReplayMonitoringCenter',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
        if (mounted) {
          _loadMonitoringData(silent: true);
        }
      });
    }
  }

  Future<void> _loadMonitoringData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _loadSessionOverview(),
        _loadActiveSessions(),
        _loadConsoleLogs(),
        _loadNetworkRequests(),
        _loadCustomEvents(),
        _loadPerformanceRegressions(),
        _loadUserFeedback(),
        _loadAnalyticsData(),
      ]);

      if (mounted) {
        setState(() {
          _sessionOverview = results[0] as Map<String, dynamic>;
          _activeSessions = results[1] as List<Map<String, dynamic>>;
          _consoleLogs = results[2] as List<Map<String, dynamic>>;
          _networkRequests = results[3] as List<Map<String, dynamic>>;
          _customEvents = results[4] as List<Map<String, dynamic>>;
          _performanceRegressions = results[5] as List<Map<String, dynamic>>;
          _userFeedback = results[6] as List<Map<String, dynamic>>;
          _analyticsData = results[7] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _loadSessionOverview() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return {
      'active_sessions': 247,
      'error_detection_rate': 98.5,
      'performance_alerts': 12,
      'avg_session_duration': '8m 32s',
      'crash_free_rate': 99.7,
      'user_satisfaction': 4.6,
    };
  }

  Future<List<Map<String, dynamic>>> _loadActiveSessions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.generate(
      20,
      (index) => {
        'session_id':
            'session_${DateTime.now().millisecondsSinceEpoch + index}',
        'user_id': 'user_${1000 + index}',
        'screen_name': _screenFilters[1 + (index % 4)],
        'duration': '${5 + (index % 15)}m ${10 + (index % 50)}s',
        'interactions': 45 + (index * 3),
        'errors': index % 5 == 0 ? 2 : 0,
        'timestamp': DateTime.now().subtract(Duration(minutes: index * 5)),
        'device': index % 2 == 0 ? 'iOS 17.2' : 'Android 14',
        'network_quality': index % 3 == 0 ? 'Poor' : 'Good',
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadConsoleLogs() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return List.generate(
      30,
      (index) => {
        'log_id': 'log_$index',
        'level': ['debug', 'info', 'warning', 'error'][index % 4],
        'message': 'Console log message ${index + 1}',
        'timestamp': DateTime.now().subtract(Duration(seconds: index * 10)),
        'session_id': 'session_${1000 + (index % 5)}',
        'screen': _screenFilters[1 + (index % 4)],
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadNetworkRequests() async {
    await Future.delayed(const Duration(milliseconds: 380));
    return List.generate(
      25,
      (index) => {
        'request_id': 'req_$index',
        'method': ['GET', 'POST', 'PUT', 'DELETE'][index % 4],
        'endpoint': '/api/v1/endpoint_${index + 1}',
        'status_code': index % 7 == 0 ? 500 : 200,
        'duration_ms': 150 + (index * 20),
        'timestamp': DateTime.now().subtract(Duration(seconds: index * 15)),
        'payload_size': '${2 + (index % 10)} KB',
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadCustomEvents() async {
    await Future.delayed(const Duration(milliseconds: 320));
    return List.generate(
      15,
      (index) => {
        'event_id': 'event_$index',
        'event_name': [
          'vote_cast',
          'payment_completed',
          'prize_distributed',
          'election_created',
        ][index % 4],
        'user_id': 'user_${1000 + index}',
        'timestamp': DateTime.now().subtract(Duration(minutes: index * 3)),
        'metadata': {
          'election_id': 'election_${100 + index}',
          'amount': index % 2 == 0 ? 50 : 100,
        },
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadPerformanceRegressions() async {
    await Future.delayed(const Duration(milliseconds: 360));
    return List.generate(
      8,
      (index) => {
        'regression_id': 'regression_$index',
        'screen_name': _screenFilters[1 + (index % 4)],
        'metric': ['load_time', 'api_latency', 'render_time'][index % 3],
        'baseline_value': 1.2 + (index * 0.1),
        'current_value': 2.5 + (index * 0.2),
        'severity': index % 3 == 0 ? 'critical' : 'warning',
        'detected_at': DateTime.now().subtract(Duration(hours: index)),
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadUserFeedback() async {
    await Future.delayed(const Duration(milliseconds: 340));
    return List.generate(
      10,
      (index) => {
        'feedback_id': 'feedback_$index',
        'user_id': 'user_${1000 + index}',
        'type': ['bug_report', 'feature_request', 'general'][index % 3],
        'message': 'User feedback message ${index + 1}',
        'session_id': 'session_${1000 + index}',
        'timestamp': DateTime.now().subtract(Duration(hours: index * 2)),
        'rating': 3 + (index % 3),
      },
    );
  }

  Future<Map<String, dynamic>> _loadAnalyticsData() async {
    await Future.delayed(const Duration(milliseconds: 390));
    return {
      'most_visited_screens': [
        {'screen': 'Vote Casting', 'visits': 15420},
        {'screen': 'Social Feed', 'visits': 12380},
        {'screen': 'Election Creation', 'visits': 8950},
      ],
      'user_journey_funnels': [
        {'step': 'Landing', 'users': 10000, 'drop_off': 0},
        {'step': 'Browse Elections', 'users': 8500, 'drop_off': 15},
        {'step': 'Vote Cast', 'users': 7200, 'drop_off': 15.3},
      ],
      'feature_adoption_rates': {
        'blockchain_verification': 78.5,
        'biometric_auth': 65.2,
        'voice_commands': 42.8,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'LogRocket Session Replay Monitoring Center',
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        appBar: CustomAppBar(
          title: 'LogRocket Session Replay',
          actions: [
            IconButton(
              icon: Icon(
                _autoRefreshEnabled ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _autoRefreshEnabled = !_autoRefreshEnabled;
                  if (_autoRefreshEnabled) {
                    _setupAutoRefresh();
                  } else {
                    _refreshTimer?.cancel();
                  }
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _loadMonitoringData(),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: ShimmerSkeletonLoader(
                  child: Column(children: const [SkeletonCard()]),
                ),
              )
            : Column(
                children: [
                  _buildOverviewHeader(),
                  _buildScreenFilter(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSessionReplayTab(),
                        _buildMonitoringTab(),
                        _buildPerformanceTab(),
                        _buildAnalyticsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewHeader() {
    return Container(
      margin: EdgeInsets.all(3.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricCard(
                'Active Sessions',
                '${_sessionOverview['active_sessions'] ?? 0}',
                Icons.people,
              ),
              _buildMetricCard(
                'Error Detection',
                '${_sessionOverview['error_detection_rate'] ?? 0}%',
                Icons.bug_report,
              ),
              _buildMetricCard(
                'Alerts',
                '${_sessionOverview['performance_alerts'] ?? 0}',
                Icons.warning_amber,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricCard(
                'Avg Duration',
                _sessionOverview['avg_session_duration'] ?? '0m',
                Icons.timer,
              ),
              _buildMetricCard(
                'Crash Free',
                '${_sessionOverview['crash_free_rate'] ?? 0}%',
                Icons.check_circle,
              ),
              _buildMetricCard(
                'Satisfaction',
                '${_sessionOverview['user_satisfaction'] ?? 0}',
                Icons.star,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.w),
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(51),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.white70),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenFilter() {
    return Container(
      height: 6.h,
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _screenFilters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedScreenFilter == _screenFilters[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedScreenFilter = _screenFilters[index];
              });
              _loadMonitoringData();
            },
            child: Container(
              margin: EdgeInsets.only(right: 2.w),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Text(
                  _screenFilters[index],
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF6366F1),
        labelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Session Replay'),
          Tab(text: 'Monitoring'),
          Tab(text: 'Performance'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildSessionReplayTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          SessionVideoReplayWidget(
            sessions: _activeSessions,
            selectedSessionId: _selectedSessionId,
            onSessionSelected: (sessionId) {
              setState(() => _selectedSessionId = sessionId);
            },
          ),
          SizedBox(height: 2.h),
          if (_selectedSessionId != null)
            SessionPlayerControlsWidget(
              sessionId: _selectedSessionId!,
              onPlayPause: () {},
              onSeek: (position) {},
            ),
        ],
      ),
    );
  }

  Widget _buildMonitoringTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          ConsoleLogCaptureWidget(logs: _consoleLogs),
          SizedBox(height: 2.h),
          NetworkRequestMonitoringWidget(requests: _networkRequests),
          SizedBox(height: 2.h),
          CustomEventTrackingWidget(events: _customEvents),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        children: [
          PerformanceRegressionWidget(regressions: _performanceRegressions),
          SizedBox(height: 2.h),
          UserFeedbackWidget(feedback: _userFeedback),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: AnalyticsDashboardWidget(analyticsData: _analyticsData),
    );
  }
}
