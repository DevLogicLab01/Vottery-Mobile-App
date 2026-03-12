import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:async';
import '../../services/sentry_alert_integration_service.dart';
import '../../services/sentry_integration_service.dart';
import '../../services/alert_rules_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import './widgets/sentry_integration_panel_widget.dart';
import './widgets/alert_rule_configuration_widget.dart';
import './widgets/incident_response_dashboard_widget.dart';
import './widgets/alert_grouping_system_widget.dart';
import './widgets/sentry_alert_card_widget.dart';
import './widgets/threshold_configuration_widget.dart';

class EnhancedSentryAutomatedAlertingHub extends StatefulWidget {
  const EnhancedSentryAutomatedAlertingHub({super.key});

  @override
  State<EnhancedSentryAutomatedAlertingHub> createState() =>
      _EnhancedSentryAutomatedAlertingHubState();
}

class _EnhancedSentryAutomatedAlertingHubState
    extends State<EnhancedSentryAutomatedAlertingHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isMonitoringActive = false;

  Map<String, dynamic> _errorRateStats = {};
  Map<String, dynamic> _alertConfig = {};
  List<Map<String, dynamic>> _activeAlerts = [];
  List<Map<String, dynamic>> _recentIncidents = [];
  final Map<String, int> _alertCounts = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
    _startAutoRefresh();
    _checkMonitoringStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }

  void _checkMonitoringStatus() {
    // Check if monitoring is active
    setState(() {
      _isMonitoringActive = true; // Monitoring starts automatically
    });
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SentryIntegrationService.instance.getErrorRateStatistics(),
        SentryAlertIntegrationService.instance.getAlertConfiguration(),
        AlertRulesService.instance.getActiveAlerts(),
        SentryIntegrationService.instance.getRecentErrorIncidents(limit: 20),
      ]);

      if (mounted) {
        setState(() {
          _errorRateStats = results[0] as Map<String, dynamic>;
          _alertConfig = results[1] as Map<String, dynamic>;
          _activeAlerts = results[2] as List<Map<String, dynamic>>;
          _recentIncidents = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  void _toggleMonitoring() {
    if (_isMonitoringActive) {
      SentryAlertIntegrationService.instance.stopMonitoring();
      setState(() => _isMonitoringActive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sentry monitoring stopped')),
      );
    } else {
      SentryAlertIntegrationService.instance.startMonitoring();
      setState(() => _isMonitoringActive = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sentry monitoring started')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'EnhancedSentryAutomatedAlertingHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Sentry Alert Management',
            variant: CustomAppBarVariant.withBack,
            actions: [
              IconButton(
                icon: Icon(
                  _isMonitoringActive ? Icons.pause_circle : Icons.play_circle,
                  color: _isMonitoringActive ? Colors.green : Colors.grey,
                ),
                onPressed: _toggleMonitoring,
                tooltip: _isMonitoringActive
                    ? 'Stop Monitoring'
                    : 'Start Monitoring',
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                onPressed: _loadData,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildStatusHeader(theme),
            _buildTabBar(theme),
            Expanded(
              child: _isLoading
                  ? const SkeletonDashboard()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSentryIntegrationTab(),
                        _buildAlertRuleConfigurationTab(),
                        _buildIncidentResponseTab(),
                        _buildAlertGroupingTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    final errorRate = _errorRateStats['error_rate'] as double? ?? 0.0;
    final totalIncidents = _errorRateStats['total_incidents'] as int? ?? 0;
    final criticalCount = _errorRateStats['critical_count'] as int? ?? 0;
    final openCount = _errorRateStats['open_count'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _isMonitoringActive ? Icons.check_circle : Icons.warning_amber,
                color: _isMonitoringActive ? Colors.green : Colors.orange,
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                _isMonitoringActive ? 'Monitoring Active' : 'Monitoring Paused',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _isMonitoringActive ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Error Rate',
                  '${errorRate.toStringAsFixed(1)}/min',
                  Icons.error_outline,
                  errorRate > 10 ? Colors.red : Colors.blue,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Total Incidents',
                  '$totalIncidents',
                  Icons.warning,
                  Colors.orange,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Critical',
                  '$criticalCount',
                  Icons.priority_high,
                  Colors.red,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  theme,
                  'Open Alerts',
                  '$openCount',
                  Icons.notifications_active,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withAlpha(153),
        indicatorColor: theme.colorScheme.primary,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Integration'),
          Tab(text: 'Rules'),
          Tab(text: 'Incidents'),
          Tab(text: 'Grouping'),
        ],
      ),
    );
  }

  Widget _buildSentryIntegrationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SentryIntegrationPanelWidget(
            errorRateStats: _errorRateStats,
            alertConfig: _alertConfig,
            onRefresh: _loadData,
          ),
          SizedBox(height: 2.h),
          ThresholdConfigurationWidget(
            alertConfig: _alertConfig,
            onConfigUpdate: (config) async {
              await SentryAlertIntegrationService.instance
                  .configureAlertThresholds(
                    criticalErrorsPerMinute:
                        config['critical_errors_per_minute'] as int?,
                    aiServiceFailuresPerHour:
                        config['ai_service_failures_per_hour'] as int?,
                    crashesPerDay: config['crashes_per_day'] as int?,
                    maxAlertsPerErrorTypePerHour:
                        config['max_alerts_per_error_type_per_hour'] as int?,
                  );
              await _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertRuleConfigurationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: AlertRuleConfigurationWidget(
        alertConfig: _alertConfig,
        onRuleCreated: _loadData,
      ),
    );
  }

  Widget _buildIncidentResponseTab() {
    return _activeAlerts.isEmpty
        ? NoDataEmptyState(
            title: 'No Active Incidents',
            description:
                'All systems operating normally. Alerts will appear here when thresholds are exceeded.',
            onRefresh: _loadData,
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              children: [
                IncidentResponseDashboardWidget(
                  activeAlerts: _activeAlerts,
                  recentIncidents: _recentIncidents,
                  onAcknowledge: (alertId, status) async {
                    await SentryAlertIntegrationService.instance
                        .acknowledgeAlert(
                          alertId: alertId,
                          acknowledgedBy: 'current_user',
                          status: status,
                        );
                    await _loadData();
                  },
                ),
                SizedBox(height: 2.h),
                ..._activeAlerts.map(
                  (alert) => Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: SentryAlertCardWidget(
                      alert: alert,
                      onAcknowledge: (status) async {
                        await SentryAlertIntegrationService.instance
                            .acknowledgeAlert(
                              alertId: alert['id'],
                              acknowledgedBy: 'current_user',
                              status: status,
                            );
                        await _loadData();
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildAlertGroupingTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: AlertGroupingSystemWidget(
        alertCounts: _alertCounts,
        maxAlertsPerHour:
            _alertConfig['max_alerts_per_error_type_per_hour'] as int? ?? 3,
      ),
    );
  }
}
