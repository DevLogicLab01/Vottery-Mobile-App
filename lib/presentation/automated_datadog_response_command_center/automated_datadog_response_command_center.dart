import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../services/automated_response_actions_service.dart';
import './widgets/threshold_status_card_widget.dart';
import './widgets/automated_action_card_widget.dart';
import './widgets/one_click_remediation_panel_widget.dart';

class AutomatedDatadogResponseCommandCenter extends StatefulWidget {
  const AutomatedDatadogResponseCommandCenter({super.key});

  @override
  State<AutomatedDatadogResponseCommandCenter> createState() =>
      _AutomatedDatadogResponseCommandCenterState();
}

class _AutomatedDatadogResponseCommandCenterState
    extends State<AutomatedDatadogResponseCommandCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _actionsService = AutomatedResponseActionsService();
  bool _monitorActive = true;

  final List<Map<String, dynamic>> _thresholds = [
    {
      'metric': 'query_latency_p95',
      'label': 'Query Latency P95',
      'current': 87.3,
      'threshold': 100.0,
      'unit': 'ms',
      'breached': false,
      'consecutive': 0,
    },
    {
      'metric': 'error_rate',
      'label': 'Error Rate',
      'current': 3.2,
      'threshold': 5.0,
      'unit': '%',
      'breached': false,
      'consecutive': 0,
    },
    {
      'metric': 'db_pool',
      'label': 'DB Connection Pool',
      'current': 76.5,
      'threshold': 80.0,
      'unit': '%',
      'breached': false,
      'consecutive': 0,
    },
  ];

  final List<Map<String, dynamic>> _actions = [
    {
      'name': 'Auto-Scale DB Connections',
      'description': 'Increase pool size by 1.5x (max 200)',
      'trigger': 'query_latency_p95 > 100ms OR pool > 80%',
      'status': 'active',
      'lastExecuted': 'Never',
    },
    {
      'name': 'Pause High-Risk Elections',
      'description': 'Pause elections with risk_score > 0.7',
      'trigger': 'connection_pool_exhaustion',
      'status': 'active',
      'lastExecuted': 'Never',
    },
    {
      'name': 'Activate Circuit Breakers',
      'description': 'Rate-limit API endpoints with 503 responses',
      'trigger': 'error_rate > 5%',
      'status': 'active',
      'lastExecuted': 'Never',
    },
    {
      'name': 'PagerDuty Alert',
      'description': 'High-severity alert to on-call engineer',
      'trigger': 'Any threshold breach',
      'status': 'active',
      'lastExecuted': 'Never',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _executeAction(String actionName) async {
    try {
      if (actionName.contains('Scale')) {
        await _actionsService.autoScaleDatabaseConnections();
      } else if (actionName.contains('Pause')) {
        await _actionsService.pauseHighRiskElections();
      } else if (actionName.contains('Circuit')) {
        await _actionsService.activateCircuitBreakers('api_gateway');
      }
      if (mounted) {
        setState(() {
          final idx = _actions.indexWhere((a) => a['name'] == actionName);
          if (idx >= 0) {
            _actions[idx]['status'] = 'triggered';
            _actions[idx]['lastExecuted'] = 'Just now';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $actionName executed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Action failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Datadog Response Center',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Monitor', style: GoogleFonts.inter(fontSize: 11.sp)),
                Switch(
                  value: _monitorActive,
                  onChanged: (v) => setState(() => _monitorActive = v),
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11.sp),
          tabs: const [
            Tab(text: 'Thresholds'),
            Tab(text: 'Actions'),
            Tab(text: 'Remediation'),
          ],
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThresholdsTab(),
          _buildActionsTab(),
          _buildRemediationTab(),
        ],
      ),
    );
  }

  Widget _buildThresholdsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDatadogStatusHeader(),
          SizedBox(height: 2.h),
          Text(
            'Threshold Monitor (30s polling)',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          ..._thresholds.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ThresholdStatusCardWidget(
                metricName: t['label'] as String,
                currentValue: (t['current'] as num).toDouble(),
                threshold: (t['threshold'] as num).toDouble(),
                unit: t['unit'] as String,
                isBreached: t['breached'] as bool,
                consecutiveBreaches: t['consecutive'] as int,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automated Response Actions',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          ..._actions.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AutomatedActionCardWidget(
                actionName: a['name'] as String,
                description: a['description'] as String,
                trigger: a['trigger'] as String,
                status: a['status'] as String,
                lastExecuted: a['lastExecuted'] as String,
                onExecute: () => _executeAction(a['name'] as String),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemediationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OneClickRemediationPanelWidget(
            onRollback: () async {
              await _actionsService.activateCircuitBreakers('api_gateway');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔄 Rollback candidate marked'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            onScaleUp: () async {
              await _actionsService.autoScaleDatabaseConnections();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Database connections scaled'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            onPauseElections: () async {
              await _actionsService.pauseHighRiskElections();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⏸️ High-risk elections paused'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
          ),
          SizedBox(height: 2.h),
          _buildNotificationIntegrations(),
        ],
      ),
    );
  }

  Widget _buildDatadogStatusHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(
                Icons.monitor_heart,
                color: Colors.purple[600],
                size: 24,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datadog APM Integration',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _monitorActive
                        ? '✅ Polling every 30 seconds'
                        : '⏸️ Monitor paused',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: _monitorActive
                          ? Colors.green[600]
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _monitorActive ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIntegrations() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Integrations',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.5.h),
            _buildIntegrationRow(
              Icons.chat,
              'Slack',
              '#production-incidents',
              Colors.green,
            ),
            _buildIntegrationRow(
              Icons.sms,
              'Twilio SMS',
              'On-call engineer',
              Colors.blue,
            ),
            _buildIntegrationRow(
              Icons.notifications_active,
              'PagerDuty',
              'High severity alert',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationRow(
    IconData icon,
    String service,
    String target,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service,
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  target,
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
