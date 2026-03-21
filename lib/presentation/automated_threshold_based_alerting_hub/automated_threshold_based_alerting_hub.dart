import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/alert_rules_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/rule_builder_widget.dart';
import './widgets/active_alert_card_widget.dart';
import './widgets/alert_history_card_widget.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/emergency_controls_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class AutomatedThresholdBasedAlertingHub extends StatefulWidget {
  const AutomatedThresholdBasedAlertingHub({super.key});

  @override
  State<AutomatedThresholdBasedAlertingHub> createState() =>
      _AutomatedThresholdBasedAlertingHubState();
}

class _AutomatedThresholdBasedAlertingHubState
    extends State<AutomatedThresholdBasedAlertingHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _activeAlerts = [];
  List<Map<String, dynamic>> _alertRules = [];
  List<Map<String, dynamic>> _alertHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
      final results = await Future.wait([
        AlertRulesService.instance.getAlertStatistics(),
        AlertRulesService.instance.getActiveAlerts(),
        AlertRulesService.instance.getAlertRules(status: 'active'),
        AlertRulesService.instance.getAlertHistory(limit: 50),
      ]);

      if (mounted) {
        setState(() {
          _statistics = results[0] as Map<String, dynamic>;
          _activeAlerts = results[1] as List<Map<String, dynamic>>;
          _alertRules = results[2] as List<Map<String, dynamic>>;
          _alertHistory = results[3] as List<Map<String, dynamic>>;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'AutomatedThresholdBasedAlertingHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Alert Management',
            variant: CustomAppBarVariant.withBack,
            actions: [
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
                  : _activeAlerts.isEmpty
                  ? NoDataEmptyState(
                      title: 'No Active Alerts',
                      description:
                          'Configure alert rules to monitor system thresholds.',
                      onRefresh: _loadData,
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRuleBuilderTab(),
                        _buildActiveAlertsTab(),
                        _buildCrossSystemTriggersTab(),
                        _buildAutomatedResponseTab(),
                        _buildPerformanceMetricsTab(),
                        _buildRuleTestingTab(),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => _showCreateRuleDialog(),
                icon: Icon(Icons.add),
                label: Text('New Rule'),
              )
            : null,
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildStatusCard(
            theme,
            'Active Rules',
            '${_statistics['total_active_rules'] ?? 0}',
            Icons.rule,
            Colors.blue,
          ),
          SizedBox(width: 3.w),
          _buildStatusCard(
            theme,
            'Triggered',
            '${_statistics['total_active_alerts'] ?? 0}',
            Icons.notifications_active,
            Colors.orange,
          ),
          SizedBox(width: 3.w),
          _buildStatusCard(
            theme,
            'Critical',
            '${_statistics['critical_alerts'] ?? 0}',
            Icons.warning,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 0.5.h),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Rule Builder'),
          Tab(text: 'Active Alerts'),
          Tab(text: 'Cross-System'),
          Tab(text: 'Auto Response'),
          Tab(text: 'Metrics'),
          Tab(text: 'Rule Testing'),
        ],
      ),
    );
  }

  Widget _buildRuleBuilderTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        EmergencyControlsWidget(
          onSuspendAll: () async {
            for (final rule in _alertRules) {
              await AlertRulesService.instance.suspendRule(rule['id']);
            }
            _loadData();
          },
          onMuteAll: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('All alerts muted for 1 hour')),
            );
          },
        ),
        SizedBox(height: 2.h),
        Text('Active Rules', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 1.h),
        if (_alertRules.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Text(
                'No active rules. Create your first alert rule.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ..._alertRules.map(
            (rule) => RuleBuilderWidget(
              rule: rule,
              onEdit: () => _showEditRuleDialog(rule),
              onDelete: () async {
                await AlertRulesService.instance.deleteAlertRule(rule['id']);
                _loadData();
              },
              onToggle: () async {
                final newStatus = rule['status'] == 'active'
                    ? 'paused'
                    : 'active';
                await AlertRulesService.instance.updateAlertRule(
                  ruleId: rule['id'],
                  status: newStatus,
                );
                _loadData();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActiveAlertsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        if (_activeAlerts.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48.sp,
                    color: Colors.green,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No active alerts',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          )
        else
          ..._activeAlerts.map(
            (alert) => ActiveAlertCardWidget(
              alert: alert,
              onAcknowledge: () async {
                await AlertRulesService.instance.acknowledgeAlert(
                  alertId: alert['id'],
                );
                _loadData();
              },
              onResolve: () => _showResolveDialog(alert),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertHistoryTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        if (_alertHistory.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Text(
                'No alert history available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ..._alertHistory.map((alert) => AlertHistoryCardWidget(alert: alert)),
      ],
    );
  }

  Widget _buildCrossSystemTriggersTab() {
    final groupedByMetric = <String, int>{};
    for (final rule in _alertRules) {
      final metric = rule['metric_type']?.toString() ?? 'unknown';
      groupedByMetric[metric] = (groupedByMetric[metric] ?? 0) + 1;
    }
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Cross-System Trigger Matrix',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 1.h),
        if (groupedByMetric.isEmpty)
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Text(
              'No active trigger definitions yet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ...groupedByMetric.entries.map(
          (entry) => Card(
            child: ListTile(
              leading: const Icon(Icons.hub),
              title: Text(entry.key.replaceAll('_', ' ')),
              subtitle: Text('Linked rules: ${entry.value}'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutomatedResponseTab() {
    final criticalAlerts = _activeAlerts
        .where((a) => a['severity']?.toString() == 'critical')
        .toList();
    final highAlerts = _activeAlerts
        .where((a) => a['severity']?.toString() == 'high')
        .toList();

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Automated Response Workflows',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 1.h),
        _responsePolicyCard(
          title: 'Critical Alerts',
          description:
              'Immediate escalation, stakeholder notification, and incident bridge activation.',
          count: criticalAlerts.length,
          color: Colors.red,
        ),
        _responsePolicyCard(
          title: 'High Alerts',
          description:
              'Assign owner, trigger remediation checklist, and monitor SLA risk.',
          count: highAlerts.length,
          color: Colors.orange,
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.play_circle_fill),
            title: const Text('Run simulated response action'),
            subtitle: const Text('Tests escalation and notification pathways'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Automated response simulation queued')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _responsePolicyCard({
    required String title,
    required String description,
    required int count,
    required Color color,
  }) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
          color: color.withAlpha(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title ($count)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetricsTab() {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        PerformanceMetricsWidget(
          statistics: _statistics,
          alertHistory: _alertHistory,
        ),
      ],
    );
  }

  Widget _buildRuleTestingTab() {
    final testCandidates = _alertRules.take(10).toList();
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text('Rule Testing Framework', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 1.h),
        if (testCandidates.isEmpty)
          Padding(
            padding: EdgeInsets.all(8.w),
            child: const Text('No rules available for testing'),
          ),
        ...testCandidates.map(
          (rule) => Card(
            child: ListTile(
              leading: const Icon(Icons.science),
              title: Text(rule['rule_name']?.toString() ?? 'Unnamed rule'),
              subtitle: Text(
                'Severity: ${rule['severity'] ?? 'n/a'} • Metric: ${rule['metric_type'] ?? 'n/a'}',
              ),
              trailing: TextButton(
                onPressed: () async {
                  await AlertRulesService.instance.triggerAlert(
                    ruleId: rule['id'].toString(),
                    severity: rule['severity']?.toString() ?? 'medium',
                    metricType: rule['metric_type']?.toString() ?? 'unknown',
                    currentValue:
                        (rule['threshold_value'] as num? ?? 0).toDouble() + 1,
                    thresholdValue:
                        (rule['threshold_value'] as num? ?? 0).toDouble(),
                    message:
                        'Rule test execution for ${rule['rule_name'] ?? 'alert rule'}',
                    notificationChannels: List<String>.from(
                      rule['notification_channels'] ?? const ['email'],
                    ),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Test alert triggered for ${rule['rule_name'] ?? 'rule'}',
                      ),
                    ),
                  );
                  _loadData();
                },
                child: const Text('Run Test'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateRuleDialog() {
    showDialog(
      context: context,
      builder: (context) => _RuleDialog(
        onSave: (data) async {
          await AlertRulesService.instance.createAlertRule(
            ruleName: data['rule_name'],
            description: data['description'],
            metricType: data['metric_type'],
            thresholdValue: data['threshold_value'],
            comparisonOperator: data['comparison_operator'],
            severity: data['severity'],
            notificationChannels: data['notification_channels'],
            conditions: List<Map<String, dynamic>>.from(
              data['conditions'] ?? const <Map<String, dynamic>>[],
            ),
          );
          _loadData();
        },
      ),
    );
  }

  void _showEditRuleDialog(Map<String, dynamic> rule) {
    showDialog(
      context: context,
      builder: (context) => _RuleDialog(
        rule: rule,
        onSave: (data) async {
          await AlertRulesService.instance.updateAlertRule(
            ruleId: rule['id'],
            ruleName: data['rule_name'],
            description: data['description'],
            metricType: data['metric_type'],
            thresholdValue: data['threshold_value'],
            comparisonOperator: data['comparison_operator'],
            severity: data['severity'],
            notificationChannels: data['notification_channels'],
            conditions: List<Map<String, dynamic>>.from(
              data['conditions'] ?? const <Map<String, dynamic>>[],
            ),
          );
          _loadData();
        },
      ),
    );
  }

  void _showResolveDialog(Map<String, dynamic> alert) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Resolve Alert'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Resolution Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AlertRulesService.instance.resolveAlert(
                alertId: alert['id'],
                resolutionNotes: controller.text,
              );
              Navigator.pop(context);
              _loadData();
            },
            child: Text('Resolve'),
          ),
        ],
      ),
    );
  }
}

class _RuleDialog extends StatefulWidget {
  final Map<String, dynamic>? rule;
  final Function(Map<String, dynamic>) onSave;

  const _RuleDialog({this.rule, required this.onSave});

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _thresholdController;
  String _metricType = 'fraud_score';
  String _comparisonOperator = 'greater_than';
  String _logicOperator = 'AND';
  String _severity = 'medium';
  final List<String> _channels = ['email'];
  final List<String> _availableChannels = ['email', 'sms', 'push'];
  final List<Map<String, dynamic>> _conditions = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.rule?['rule_name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.rule?['description'] ?? '',
    );
    _thresholdController = TextEditingController(
      text: widget.rule?['threshold_value']?.toString() ?? '',
    );

    if (widget.rule != null) {
      _metricType = widget.rule!['metric_type'] ?? 'fraud_score';
      _comparisonOperator =
          widget.rule!['comparison_operator'] ?? 'greater_than';
      _severity = widget.rule!['severity'] ?? 'medium';
      final channels = widget.rule!['notification_channels'];
      if (channels is List && channels.isNotEmpty) {
        _channels
          ..clear()
          ..addAll(channels.map((c) => c.toString()));
      }
      final ruleConditions = widget.rule!['conditions'];
      if (ruleConditions is List && ruleConditions.isNotEmpty) {
        _conditions.addAll(ruleConditions.map((c) {
          final map = Map<String, dynamic>.from(c as Map);
          return {
            'metric_name': map['metric_name']?.toString() ?? _metricType,
            'comparison_operator':
                map['comparison_operator']?.toString() ?? 'greater_than',
            'threshold_value': (map['threshold_value'] as num?)?.toDouble() ?? 0,
            'time_window_minutes':
                (map['time_window_minutes'] as num?)?.toInt() ?? 5,
            'logic_operator': map['logic_operator']?.toString() ?? 'AND',
            'condition_group': (map['condition_group'] as num?)?.toInt() ?? 1,
          };
        }));
        _logicOperator = _conditions.first['logic_operator']?.toString() ?? 'AND';
      }
    }
    if (_conditions.isEmpty) {
      _conditions.add({
        'metric_name': _metricType,
        'comparison_operator': _comparisonOperator,
        'threshold_value': double.tryParse(_thresholdController.text) ?? 0,
        'time_window_minutes': 5,
        'logic_operator': _logicOperator,
        'condition_group': 1,
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule == null ? 'Create Alert Rule' : 'Edit Rule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Rule Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _metricType,
              decoration: InputDecoration(
                labelText: 'Metric Type',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'fraud_score',
                  child: Text('Fraud Score'),
                ),
                DropdownMenuItem(
                  value: 'payment_failure_rate',
                  child: Text('Payment Failure Rate'),
                ),
                DropdownMenuItem(
                  value: 'campaign_ctr',
                  child: Text('Campaign CTR'),
                ),
              ],
              onChanged: (value) => setState(() => _metricType = value!),
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _comparisonOperator,
              decoration: InputDecoration(
                labelText: 'Comparison Operator',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'greater_than', child: Text('Greater Than')),
                DropdownMenuItem(value: 'less_than', child: Text('Less Than')),
                DropdownMenuItem(value: 'equals', child: Text('Equals')),
                DropdownMenuItem(value: 'not_equals', child: Text('Not Equals')),
              ],
              onChanged: (value) =>
                  setState(() => _comparisonOperator = value ?? 'greater_than'),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _thresholdController,
              decoration: InputDecoration(
                labelText: 'Threshold Value',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 2.h),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: (value) => setState(() => _severity = value!),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _logicOperator,
                    decoration: InputDecoration(
                      labelText: 'Condition Logic',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'AND', child: Text('AND')),
                      DropdownMenuItem(value: 'OR', child: Text('OR')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _logicOperator = value;
                        for (final condition in _conditions) {
                          condition['logic_operator'] = _logicOperator;
                        }
                      });
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _conditions.add({
                        'metric_name': _metricType,
                        'comparison_operator': _comparisonOperator,
                        'threshold_value':
                            double.tryParse(_thresholdController.text) ?? 0,
                        'time_window_minutes': 5,
                        'logic_operator': _logicOperator,
                        'condition_group': 1,
                      });
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Condition'),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            ..._conditions.asMap().entries.map((entry) {
              final index = entry.key;
              final condition = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: condition['metric_name']?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Metric',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => condition['metric_name'] = value,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    SizedBox(
                      width: 24.w,
                      child: TextFormField(
                        initialValue: condition['threshold_value']?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Value',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => condition['threshold_value'] =
                            double.tryParse(value) ?? 0,
                      ),
                    ),
                    IconButton(
                      onPressed: _conditions.length <= 1
                          ? null
                          : () => setState(() => _conditions.removeAt(index)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
            SizedBox(height: 1.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Notification Channels',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(height: 0.6.h),
            Wrap(
              spacing: 2.w,
              children: _availableChannels.map((channel) {
                final selected = _channels.contains(channel);
                return FilterChip(
                  label: Text(channel.toUpperCase()),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        if (!_channels.contains(channel)) _channels.add(channel);
                      } else {
                        _channels.remove(channel);
                      }
                      if (_channels.isEmpty) _channels.add('email');
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave({
              'rule_name': _nameController.text,
              'description': _descriptionController.text,
              'metric_type': _metricType,
              'threshold_value':
                  double.tryParse(_thresholdController.text) ?? 0,
              'comparison_operator': _comparisonOperator,
              'severity': _severity,
              'notification_channels': _channels,
              'conditions': _conditions
                  .map((condition) => {
                        ...condition,
                        'logic_operator': _logicOperator,
                        'comparison_operator':
                            condition['comparison_operator'] ?? _comparisonOperator,
                        'condition_group': condition['condition_group'] ?? 1,
                      })
                  .toList(),
            });
            Navigator.pop(context);
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
