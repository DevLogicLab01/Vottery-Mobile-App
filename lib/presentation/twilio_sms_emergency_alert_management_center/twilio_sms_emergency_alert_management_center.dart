import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/twilio_emergency_alert_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/alert_template_card_widget.dart';
import './widgets/on_call_team_card_widget.dart';
import './widgets/sms_alert_table_widget.dart';

class TwilioSmsEmergencyAlertManagementCenter extends StatefulWidget {
  const TwilioSmsEmergencyAlertManagementCenter({super.key});

  @override
  State<TwilioSmsEmergencyAlertManagementCenter> createState() =>
      _TwilioSmsEmergencyAlertManagementCenterState();
}

class _TwilioSmsEmergencyAlertManagementCenterState
    extends State<TwilioSmsEmergencyAlertManagementCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _sentAlerts = [];
  List<Map<String, dynamic>> _onCallSchedules = [];
  List<Map<String, dynamic>> _alertTemplates = [];
  Map<String, dynamic> _stats = {};

  final _twilioService = TwilioEmergencyAlertService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Load sent alerts
      final alertsResponse = await supabase
          .from('sms_alerts_log')
          .select()
          .order('sent_at', ascending: false)
          .limit(100);

      // Load on-call schedules
      final schedulesResponse = await supabase
          .from('on_call_schedules')
          .select(
            '*, user_profiles!on_call_schedules_current_on_call_user_id_fkey(id, full_name, avatar_url)',
          )
          .gte('on_call_until', DateTime.now().toIso8601String())
          .order('team_name');

      // Calculate stats
      final totalAlerts = alertsResponse.length;
      final deliveredAlerts = alertsResponse
          .where((a) => a['delivery_status'] == 'delivered')
          .length;
      final acknowledgedAlerts = alertsResponse
          .where((a) => a['acknowledged_at'] != null)
          .length;
      final deliveryRate = totalAlerts > 0
          ? (deliveredAlerts / totalAlerts * 100).toStringAsFixed(1)
          : '0.0';
      final ackRate = totalAlerts > 0
          ? (acknowledgedAlerts / totalAlerts * 100).toStringAsFixed(1)
          : '0.0';

      // Calculate average response time
      final acknowledgedWithTime = alertsResponse.where(
        (a) => a['response_time_minutes'] != null,
      );
      final avgResponseTime = acknowledgedWithTime.isNotEmpty
          ? (acknowledgedWithTime
                        .map((a) => a['response_time_minutes'] as int)
                        .reduce((a, b) => a + b) /
                    acknowledgedWithTime.length)
                .toStringAsFixed(1)
          : '0.0';

      // Load alert templates
      final templates = [
        {
          'template_id': 'fraud_critical',
          'name': 'Critical Fraud Detection',
          'category': 'fraud',
          'message':
              '🚨 CRITICAL FRAUD ALERT\nType: {pattern_name}\nConfidence: {confidence}%\nAffected: {user_count} users\nEvidence: {evidence_count} logs\nAction Required: Review immediately\nDashboard: {dashboard_url}',
          'variables': [
            'pattern_name',
            'confidence',
            'user_count',
            'evidence_count',
            'dashboard_url',
          ],
        },
        {
          'template_id': 'failover_high',
          'name': 'AI Service Failover',
          'category': 'failover',
          'message':
              '⚠️ AI SERVICE FAILOVER\nFailed: {service_name}\nBackup: {backup_service}\nReason: {failure_reason}\nExpected Duration: {duration}min\nImpact: {affected_operations}\nMonitor: {dashboard_url}',
          'variables': [
            'service_name',
            'backup_service',
            'failure_reason',
            'duration',
            'affected_operations',
            'dashboard_url',
          ],
        },
        {
          'template_id': 'security_critical',
          'name': 'Security Incident',
          'category': 'security',
          'message':
              '🔒 SECURITY INCIDENT\nType: {incident_type}\nSeverity: {severity}\nAffected Systems: {systems}\nAction: {required_action}\nDashboard: {dashboard_url}',
          'variables': [
            'incident_type',
            'severity',
            'systems',
            'required_action',
            'dashboard_url',
          ],
        },
        {
          'template_id': 'performance_high',
          'name': 'Performance Degradation',
          'category': 'performance',
          'message':
              '⚡ PERFORMANCE ALERT\nService: {service_name}\nMetric: {metric_name}\nThreshold Exceeded: {threshold}\nCurrent Value: {current_value}\nDuration: {duration}min\nDashboard: {dashboard_url}',
          'variables': [
            'service_name',
            'metric_name',
            'threshold',
            'current_value',
            'duration',
            'dashboard_url',
          ],
        },
      ];

      setState(() {
        _sentAlerts = List<Map<String, dynamic>>.from(alertsResponse);
        _onCallSchedules = List<Map<String, dynamic>>.from(schedulesResponse);
        _alertTemplates = templates;
        _stats = {
          'total_alerts': totalAlerts,
          'delivery_rate': deliveryRate,
          'acknowledgment_rate': ackRate,
          'avg_response_time': avgResponseTime,
          'on_call_teams': schedulesResponse.length,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading SMS alert data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendTestAlert() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Test Alert',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select team to receive test alert:',
              style: GoogleFonts.inter(fontSize: 14.sp),
            ),
            SizedBox(height: 2.h),
            ..._onCallSchedules.map(
              (schedule) => RadioListTile<String>(
                title: Text(
                  schedule['team_name'],
                  style: GoogleFonts.inter(fontSize: 14.sp),
                ),
                subtitle: Text(
                  'On-call: ${schedule['user_profiles']?['full_name'] ?? 'Unknown'}',
                  style: GoogleFonts.inter(fontSize: 12.sp),
                ),
                value: schedule['team_name'],
                groupValue: null,
                onChanged: (value) async {
                  Navigator.pop(context);
                  await _executeTestAlert(schedule);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeTestAlert(Map<String, dynamic> schedule) async {
    try {
      final result = await _twilioService.sendCriticalFraudAlert(
        analysisId: 'test-${DateTime.now().millisecondsSinceEpoch}',
        patternName: 'Test Alert - System Check',
        confidenceScore: 0.95,
        affectedUserCount: 0,
        evidenceCount: 0,
        dashboardUrl:
            'https://vottery2205.builtwithrocket.new/advanced-fraud-detection-center',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success']
                  ? 'Test alert sent successfully'
                  : 'Test alert failed: ${result['error']}',
            ),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        if (result['success']) {
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending test alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'TwilioSmsEmergencyAlertManagementCenter',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'SMS Emergency Alerts',
          actions: [
            IconButton(
              icon: Icon(Icons.send, size: 6.w, color: AppTheme.primaryLight),
              onPressed: _sendTestAlert,
              tooltip: 'Send Test Alert',
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              onPressed: _loadData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? ShimmerSkeletonLoader(child: SkeletonDashboard())
            : Column(
                children: [
                  // Stats Overview
                  Container(
                    padding: EdgeInsets.all(4.w),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Sent Alerts',
                          _stats['total_alerts'].toString(),
                          Icons.send,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Delivery Rate',
                          '${_stats['delivery_rate']}%',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Ack Rate',
                          '${_stats['acknowledgment_rate']}%',
                          Icons.done_all,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Avg Response',
                          '${_stats['avg_response_time']}m',
                          Icons.timer,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryLight,
                      unselectedLabelColor: AppTheme.textSecondaryLight,
                      indicatorColor: AppTheme.primaryLight,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(text: 'Alert Dashboard'),
                        Tab(text: 'On-Call Schedule'),
                        Tab(text: 'Templates'),
                      ],
                    ),
                  ),
                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // SMS Alert Dashboard
                        SmsAlertTableWidget(
                          alerts: _sentAlerts,
                          onRefresh: _loadData,
                        ),
                        // On-Call Schedule Management
                        _buildOnCallScheduleTab(),
                        // Alert Templates Library
                        _buildTemplatesTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 6.w, color: color),
        SizedBox(height: 1.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildOnCallScheduleTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Current On-Call Teams',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        if (_onCallSchedules.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Text(
                'No on-call schedules configured',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ),
          )
        else
          ..._onCallSchedules.map(
            (schedule) =>
                OnCallTeamCardWidget(schedule: schedule, onRefresh: _loadData),
          ),
      ],
    );
  }

  Widget _buildTemplatesTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Alert Message Templates',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        ..._alertTemplates.map(
          (template) => AlertTemplateCardWidget(template: template),
        ),
      ],
    );
  }
}
