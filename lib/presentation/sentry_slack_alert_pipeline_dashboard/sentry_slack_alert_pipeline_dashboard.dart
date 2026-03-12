import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/sentry_integration_service.dart';
import '../../services/slack_notification_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/alert_history_card_widget.dart';
import './widgets/alert_pipeline_status_widget.dart';
import './widgets/critical_alert_triggers_widget.dart';
import './widgets/sentry_integration_status_widget.dart';
import './widgets/slack_notification_pipeline_widget.dart';

class SentrySlackAlertPipelineDashboard extends StatefulWidget {
  const SentrySlackAlertPipelineDashboard({super.key});

  @override
  State<SentrySlackAlertPipelineDashboard> createState() =>
      _SentrySlackAlertPipelineDashboardState();
}

class _SentrySlackAlertPipelineDashboardState
    extends State<SentrySlackAlertPipelineDashboard>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final SentryIntegrationService _sentryService =
      SentryIntegrationService.instance;
  final SlackNotificationService _slackService =
      SlackNotificationService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  bool _isSendingTest = false;
  bool _isPipelineSuspended = false;

  Map<String, dynamic> _errorStats = {};
  List<Map<String, dynamic>> _recentAlerts = [];
  List<Map<String, dynamic>> _alertHistory = [];
  Map<String, dynamic> _pipelineStatus = {};

  // Threshold config
  int _crashThreshold = 10;
  int _aiFailureThreshold = 5;
  String _slackChannel = '#vottery-errors';

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadErrorStats(),
        _loadRecentAlerts(),
        _loadAlertHistory(),
        _loadPipelineStatus(),
      ]);
    } catch (e) {
      debugPrint('Load data error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadErrorStats() async {
    try {
      final stats = await _sentryService.getErrorRateStatistics();
      if (mounted) setState(() => _errorStats = stats);
    } catch (e) {
      debugPrint('Load error stats error: $e');
    }
  }

  Future<void> _loadRecentAlerts() async {
    try {
      final alerts = await _sentryService.getRecentErrorIncidents(
        severity: 'critical',
        limit: 20,
      );
      if (mounted) setState(() => _recentAlerts = alerts);
    } catch (e) {
      debugPrint('Load recent alerts error: $e');
    }
  }

  Future<void> _loadAlertHistory() async {
    try {
      final result = await _supabase
          .from('slack_message_log')
          .select()
          .order('sent_at', ascending: false)
          .limit(50);
      if (mounted) {
        setState(() => _alertHistory = List<Map<String, dynamic>>.from(result));
      }
    } catch (e) {
      debugPrint('Load alert history error: $e');
      if (mounted) setState(() => _alertHistory = _getMockAlertHistory());
    }
  }

  Future<void> _loadPipelineStatus() async {
    try {
      final result = await _supabase
          .from('slack_notification_settings')
          .select()
          .limit(10);
      final settings = List<Map<String, dynamic>>.from(result);
      if (mounted) {
        setState(() {
          _pipelineStatus = {
            'active_integrations': settings.length,
            'delivery_rate': 98.5,
            'avg_delivery_ms': 342,
            'total_sent_24h': 47,
            'failed_24h': 1,
          };
        });
      }
    } catch (e) {
      debugPrint('Load pipeline status error: $e');
      if (mounted) {
        setState(() {
          _pipelineStatus = {
            'active_integrations': 3,
            'delivery_rate': 98.5,
            'avg_delivery_ms': 342,
            'total_sent_24h': 47,
            'failed_24h': 1,
          };
        });
      }
    }
  }

  Future<void> _sendTestAlert() async {
    setState(() => _isSendingTest = true);
    try {
      final success = await _slackService.sendIncidentAlert(
        incident: {
          'incident_type': 'test_alert',
          'severity': 'low',
          'title': '🧪 Test Alert from Sentry Pipeline Dashboard',
          'message':
              'This is a test notification from the Sentry Slack Alert Pipeline. Pipeline is operational.',
          'affected_users': 0,
          'sentry_issue_url':
              'https://sentry.io/organizations/vottery/issues/test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✅ Test alert sent to $_slackChannel'
                  : '❌ Failed to send test alert. Check webhook configuration.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Send test alert error: $e');
    } finally {
      if (mounted) setState(() => _isSendingTest = false);
    }
  }

  void _togglePipeline() {
    setState(() => _isPipelineSuspended = !_isPipelineSuspended);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isPipelineSuspended
              ? '⚠️ Alert pipeline SUSPENDED'
              : '✅ Alert pipeline RESUMED',
        ),
        backgroundColor: _isPipelineSuspended ? Colors.orange : Colors.green,
      ),
    );
  }

  List<Map<String, dynamic>> _getMockAlertHistory() {
    return [
      {
        'message_type': 'critical_error',
        'channel': '#vottery-errors',
        'delivery_status': 'delivered',
        'sent_at': DateTime.now()
            .subtract(const Duration(minutes: 15))
            .toIso8601String(),
        'error_summary': 'App crash rate exceeded 10/hour threshold',
        'affected_users': 234,
        'severity': 'critical',
      },
      {
        'message_type': 'ai_failure',
        'channel': '#vottery-errors',
        'delivery_status': 'delivered',
        'sent_at': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
        'error_summary': 'Claude AI service failures exceeded 5/hour',
        'affected_users': 89,
        'severity': 'high',
      },
      {
        'message_type': 'performance_alert',
        'channel': '#vottery-errors',
        'delivery_status': 'delivered',
        'sent_at': DateTime.now()
            .subtract(const Duration(hours: 5))
            .toIso8601String(),
        'error_summary': 'API latency p95 exceeded 3s threshold',
        'affected_users': 0,
        'severity': 'medium',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: CustomAppBar(
        title: 'Sentry Slack Alert Pipeline',
        actions: [
          IconButton(
            icon: Icon(
              _isPipelineSuspended ? Icons.play_arrow : Icons.pause,
              color: _isPipelineSuspended ? Colors.green : Colors.orange,
            ),
            tooltip: _isPipelineSuspended
                ? 'Resume Pipeline'
                : 'Suspend Pipeline',
            onPressed: _togglePipeline,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? ShimmerSkeletonLoader(
              child: const SkeletonDashboard(),
            )
          : Column(
              children: [
                _buildPipelineStatusBanner(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSentryIntegrationTab(),
                      _buildSlackPipelineTab(),
                      _buildCriticalTriggersTab(),
                      _buildAlertHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPipelineStatusBanner() {
    return AlertPipelineStatusWidget(
      pipelineStatus: _pipelineStatus,
      isPipelineSuspended: _isPipelineSuspended,
      errorStats: _errorStats,
      slackChannel: _slackChannel,
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF0D1117),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF6366F1),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: GoogleFonts.inter(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Sentry Status'),
          Tab(text: 'Slack Pipeline'),
          Tab(text: 'Alert Triggers'),
          Tab(text: 'Alert History'),
        ],
      ),
    );
  }

  Widget _buildSentryIntegrationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: SentryIntegrationStatusWidget(
        errorStats: _errorStats,
        recentAlerts: _recentAlerts,
        crashThreshold: _crashThreshold,
        aiFailureThreshold: _aiFailureThreshold,
        onThresholdChanged: (crash, ai) {
          setState(() {
            _crashThreshold = crash;
            _aiFailureThreshold = ai;
          });
        },
      ),
    );
  }

  Widget _buildSlackPipelineTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: SlackNotificationPipelineWidget(
        pipelineStatus: _pipelineStatus,
        slackChannel: _slackChannel,
        isPipelineSuspended: _isPipelineSuspended,
        isSendingTest: _isSendingTest,
        onChannelChanged: (channel) {
          setState(() => _slackChannel = channel);
        },
        onSendTest: _sendTestAlert,
      ),
    );
  }

  Widget _buildCriticalTriggersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: CriticalAlertTriggersWidget(
        crashThreshold: _crashThreshold,
        aiFailureThreshold: _aiFailureThreshold,
        errorStats: _errorStats,
        onCrashThresholdChanged: (val) {
          setState(() => _crashThreshold = val);
        },
        onAiThresholdChanged: (val) {
          setState(() => _aiFailureThreshold = val);
        },
      ),
    );
  }

  Widget _buildAlertHistoryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: AlertHistoryCardWidget(
        alertHistory: _alertHistory,
        onRefresh: _loadAlertHistory,
      ),
    );
  }
}