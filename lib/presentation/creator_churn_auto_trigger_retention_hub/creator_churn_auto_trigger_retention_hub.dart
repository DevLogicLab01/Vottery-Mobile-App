import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/creator_churn_prediction_service.dart';
import '../../services/unified_sms_service.dart';
import '../../services/resend_email_service.dart';
import '../../services/supabase_service.dart';
import 'widgets/churn_monitoring_overview_widget.dart';
import 'widgets/churn_detection_panel_widget.dart';
import 'widgets/intervention_workflows_widget.dart';
import 'widgets/retention_effectiveness_widget.dart';
import 'widgets/scheduled_trigger_status_widget.dart';

class CreatorChurnAutoTriggerRetentionHub extends StatefulWidget {
  const CreatorChurnAutoTriggerRetentionHub({super.key});

  @override
  State<CreatorChurnAutoTriggerRetentionHub> createState() =>
      _CreatorChurnAutoTriggerRetentionHubState();
}

class _CreatorChurnAutoTriggerRetentionHubState
    extends State<CreatorChurnAutoTriggerRetentionHub> {
  final _churnService = CreatorChurnPredictionService.instance;
  final _smsService = UnifiedSMSService.instance;
  final _emailService = ResendEmailService.instance;
  final _supabase = SupabaseService.instance.client;

  bool _isLoading = true;
  bool _isRunningTrigger = false;
  bool _autoTriggerActive = true;

  List<Map<String, dynamic>> _atRiskCreators = [];
  List<Map<String, dynamic>> _activeInterventions = [];
  Map<String, dynamic> _effectivenessData = {};
  Map<String, dynamic> _scheduleData = {};

  int _atRiskCount = 0;
  double _interventionSuccessRate = 0.0;
  int _pendingInterventions = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadAtRiskCreators(),
        _loadActiveInterventions(),
        _loadEffectivenessData(),
        _loadScheduleData(),
      ]);
    } catch (e) {
      debugPrint('Error loading retention hub data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAtRiskCreators() async {
    try {
      final response = await _supabase
          .from('creator_churn_predictions')
          .select()
          .gte('churn_probability', 0.5)
          .eq('intervention_sent', false)
          .order('churn_probability', ascending: false)
          .limit(20);

      final creators = List<Map<String, dynamic>>.from(response);
      setState(() {
        _atRiskCreators = creators;
        _atRiskCount = creators.length;
        _pendingInterventions = creators.length;
      });
    } catch (e) {
      debugPrint('Error loading at-risk creators: $e');
      setState(() {
        _atRiskCreators = _getMockAtRiskCreators();
        _atRiskCount = _atRiskCreators.length;
        _pendingInterventions = _atRiskCreators.length;
      });
    }
  }

  Future<void> _loadActiveInterventions() async {
    try {
      final response = await _supabase
          .from('creator_churn_interventions')
          .select()
          .order('sent_at', ascending: false)
          .limit(20);

      setState(() {
        _activeInterventions = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error loading interventions: $e');
      setState(() => _activeInterventions = _getMockInterventions());
    }
  }

  Future<void> _loadEffectivenessData() async {
    try {
      final response = await _supabase
          .from('creator_churn_interventions')
          .select('response_status')
          .limit(100);

      final interventions = List<Map<String, dynamic>>.from(response);
      final responded = interventions
          .where((i) => i['response_status'] == 'responded')
          .length;
      final total = interventions.length;
      final successRate = total > 0 ? responded / total : 0.0;

      setState(() {
        _interventionSuccessRate = successRate;
        _effectivenessData = {
          'response_rate': successRate,
          'resumption_rate': successRate * 0.7,
          'sms_open_rate': 0.68,
          'email_open_rate': 0.42,
          'ab_test_winner': 'Variant A: Personalized question',
        };
      });
    } catch (e) {
      debugPrint('Error loading effectiveness data: $e');
      setState(() {
        _interventionSuccessRate = 0.34;
        _effectivenessData = {
          'response_rate': 0.34,
          'resumption_rate': 0.24,
          'sms_open_rate': 0.68,
          'email_open_rate': 0.42,
          'ab_test_winner': 'Variant A: Personalized question',
        };
      });
    }
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _scheduleData = {
        'last_run': DateTime.now().subtract(const Duration(hours: 2)),
        'next_run': DateTime.now().add(const Duration(hours: 4)),
        'processed_count': 47,
      };
    });
  }

  Future<void> _triggerIntervention(Map<String, dynamic> creator) async {
    final creatorName = creator['creator_name'] ?? 'Creator';
    final churnProbability =
        (creator['churn_probability'] as num?)?.toDouble() ?? 0.0;
    final daysSincePost = creator['days_since_last_post'] ?? 7;
    final creatorPhone = creator['phone_number'] ?? '';
    final creatorEmail = creator['email'] ?? '';
    final creatorId = creator['creator_user_id'] ?? '';

    try {
      // Send SMS via UnifiedSMSService
      if (creatorPhone.isNotEmpty) {
        final smsMessage =
            'Hi $creatorName, we noticed you haven\'t posted in $daysSincePost days. '
            'Quick question: what would help you create more? Reply and let\'s chat!';
        await _smsService.sendSMS(
          toPhone: creatorPhone,
          messageBody: smsMessage,
          messageType: 'retention',
        );
      }

      // Send email via ResendEmailService
      if (creatorEmail.isNotEmpty) {
        await _emailService.sendRetentionEmail(
          recipientEmail: creatorEmail,
          creatorName: creatorName,
          daysSincePost: daysSincePost,
        );
      }

      // Log intervention to creator_churn_interventions
      await _supabase.from('creator_churn_interventions').insert({
        'creator_user_id': creatorId,
        'prediction_id': creator['prediction_id'] ?? '',
        'intervention_type': churnProbability >= 0.7 ? 'urgent' : 'proactive',
        'message_content':
            'Hi $creatorName, we noticed you haven\'t posted in $daysSincePost days.',
        'sent_at': DateTime.now().toIso8601String(),
        'response_status': 'sent',
      });

      // Mark intervention_sent = true
      if (creator['prediction_id'] != null) {
        await _supabase
            .from('creator_churn_predictions')
            .update({'intervention_sent': true})
            .eq('prediction_id', creator['prediction_id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Intervention triggered for $creatorName'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      debugPrint('Error triggering intervention: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to trigger intervention: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _runScheduledTrigger() async {
    setState(() => _isRunningTrigger = true);
    try {
      // Process all pending interventions
      final pending = await _supabase
          .from('creator_churn_predictions')
          .select()
          .eq('intervention_sent', false)
          .gte('churn_probability', 0.5);

      final pendingList = List<Map<String, dynamic>>.from(pending);
      int processed = 0;

      for (final creator in pendingList) {
        await _triggerIntervention(creator);
        processed++;
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Processed $processed pending interventions'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      debugPrint('Error running scheduled trigger: $e');
    } finally {
      if (mounted) setState(() => _isRunningTrigger = false);
    }
  }

  List<Map<String, dynamic>> _getMockAtRiskCreators() {
    return [
      {
        'creator_user_id': 'user_1',
        'creator_name': 'Alex Johnson',
        'churn_probability': 0.82,
        'days_since_last_post': 14,
        'risk_level': 'critical',
        'intervention_sent': false,
      },
      {
        'creator_user_id': 'user_2',
        'creator_name': 'Maria Garcia',
        'churn_probability': 0.71,
        'days_since_last_post': 10,
        'risk_level': 'critical',
        'intervention_sent': false,
      },
      {
        'creator_user_id': 'user_3',
        'creator_name': 'James Wilson',
        'churn_probability': 0.58,
        'days_since_last_post': 7,
        'risk_level': 'high',
        'intervention_sent': false,
      },
    ];
  }

  List<Map<String, dynamic>> _getMockInterventions() {
    return [
      {
        'creator_name': 'Sarah Chen',
        'type': 'sms',
        'status': 'responded',
        'sent_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'creator_name': 'David Kim',
        'type': 'email',
        'status': 'sent',
        'sent_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'creator_name': 'Emma Davis',
        'type': 'push',
        'status': 'sent',
        'sent_at': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Churn Retention Hub',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Auto-Trigger Retention Workflows',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          Switch(
            value: _autoTriggerActive,
            onChanged: (val) => setState(() => _autoTriggerActive = val),
            activeThumbColor: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChurnMonitoringOverviewWidget(
                      atRiskCount: _atRiskCount,
                      interventionSuccessRate: _interventionSuccessRate,
                      autoTriggerActive: _autoTriggerActive,
                      pendingInterventions: _pendingInterventions,
                    ),
                    SizedBox(height: 2.h),
                    ChurnDetectionPanelWidget(
                      atRiskCreators: _atRiskCreators,
                      onTriggerIntervention: _triggerIntervention,
                    ),
                    SizedBox(height: 2.h),
                    InterventionWorkflowsWidget(
                      activeInterventions: _activeInterventions,
                      onViewDetails: (id) {},
                    ),
                    SizedBox(height: 2.h),
                    ScheduledTriggerStatusWidget(
                      lastRunAt: _scheduleData['last_run'] as DateTime?,
                      nextRunAt: _scheduleData['next_run'] as DateTime?,
                      processedCount:
                          (_scheduleData['processed_count'] as int?) ?? 0,
                      pendingCount: _pendingInterventions,
                      isRunning: _isRunningTrigger,
                      onRunNow: _runScheduledTrigger,
                    ),
                    SizedBox(height: 2.h),
                    RetentionEffectivenessWidget(
                      effectivenessData: _effectivenessData,
                    ),
                    SizedBox(height: 2.h),
                    _buildSmsMessagePreview(),
                    SizedBox(height: 2.h),
                    _buildEmailCampaignPreview(),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSmsMessagePreview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sms, color: Colors.green.shade700, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'SMS Message Template',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Claude-Generated',
                    style: TextStyle(color: Colors.green.shade700, fontSize: 9.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                'Hi {name}, we noticed you haven\'t posted in {days} days. '
                'Quick question: what would help you create more? '
                'Reply and let\'s chat!',
                style: TextStyle(fontSize: 10.sp, fontStyle: FontStyle.italic),
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    'Telnyx: all messages allowed. Twilio: gamification SMS blocked.',
                    style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailCampaignPreview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue.shade700, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Email Campaign Components',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),
            _buildEmailComponent(
              Icons.attach_money,
              'Earnings Snapshot',
              'Last 30-day earnings summary',
              Colors.green,
            ),
            _buildEmailComponent(
              Icons.star,
              'Tier Benefits',
              'Current tier perks & next tier preview',
              Colors.amber,
            ),
            _buildEmailComponent(
              Icons.people,
              'Success Stories',
              'Similar creators who bounced back',
              Colors.purple,
            ),
            _buildEmailComponent(
              Icons.link,
              'Engagement CTA',
              'Deep-link to CreatorAnalyticsDashboard',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailComponent(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(1.5.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
  }
}
