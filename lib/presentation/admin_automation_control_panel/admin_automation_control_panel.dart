import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../services/admin_automation_rules_service.dart';
import './widgets/rule_card_widget.dart';
import './widgets/create_rule_dialog_widget.dart';

class AdminAutomationControlPanel extends StatefulWidget {
  const AdminAutomationControlPanel({super.key});

  @override
  State<AdminAutomationControlPanel> createState() =>
      _AdminAutomationControlPanelState();
}

class _AdminAutomationControlPanelState
    extends State<AdminAutomationControlPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<AutomationRule> _rules = [];
  List<AutomationExecutionLog> _executionLogs = [];

  int get _activeRules => _rules.where((r) => r.isEnabled).length;
  int get _scheduledRules => _rules.where((r) => r.schedule.isNotEmpty).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        AdminAutomationRulesService.getAutomationRules(),
        AdminAutomationRulesService.getExecutionHistory(),
      ]);
      if (mounted) {
        setState(() {
          _rules = results[0] as List<AutomationRule>;
          _executionLogs = results[1] as List<AutomationExecutionLog>;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleRule(String ruleId, bool enabled) async {
    await AdminAutomationRulesService.toggleRule(ruleId, enabled);
    await _loadData();
  }

  Future<void> _executeNow(AutomationRule rule) async {
    await AdminAutomationRulesService.executeRuleNow(rule);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${rule.ruleName}" executed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
    await _loadData();
  }

  Future<void> _deleteRule(String ruleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Rule',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this rule?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AdminAutomationRulesService.deleteRule(ruleId);
      await _loadData();
    }
  }

  Future<void> _setOverride(String ruleId) async {
    Duration? selectedDuration;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Override Duration',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('1 Hour', style: GoogleFonts.inter()),
              onTap: () {
                selectedDuration = const Duration(hours: 1);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('6 Hours', style: GoogleFonts.inter()),
              onTap: () {
                selectedDuration = const Duration(hours: 6);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text('24 Hours', style: GoogleFonts.inter()),
              onTap: () {
                selectedDuration = const Duration(hours: 24);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
    if (selectedDuration != null) {
      await AdminAutomationRulesService.setOverride(ruleId, selectedDuration!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Override set successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      await _loadData();
    }
  }

  Future<void> _emergencyStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 18.sp),
            SizedBox(width: 2.w),
            Text(
              'Emergency Stop',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'This will immediately disable ALL automation rules. Are you sure?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'STOP ALL',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AdminAutomationRulesService.emergencyStopAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('EMERGENCY STOP: All automations disabled'),
            backgroundColor: Colors.red,
          ),
        );
      }
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Text(
          'Automation Control Panel',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle, color: Colors.red),
            onPressed: _emergencyStop,
            tooltip: 'Emergency Stop All',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Rules', icon: Icon(Icons.rule, size: 16)),
            Tab(text: 'History', icon: Icon(Icons.history, size: 16)),
            Tab(text: 'Overrides', icon: Icon(Icons.pause_circle, size: 16)),
            Tab(text: 'Settings', icon: Icon(Icons.settings, size: 16)),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) =>
                    CreateAutomationRuleDialog(onCreated: _loadData),
              ),
              backgroundColor: const Color(0xFF1A1A2E),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatusOverview(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRulesTab(),
                      _buildHistoryTab(),
                      _buildOverridesTab(),
                      _buildSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusOverview() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      color: Colors.white,
      child: Row(
        children: [
          _buildStatChip('Active Rules', _activeRules.toString(), Colors.green),
          SizedBox(width: 2.w),
          _buildStatChip('Scheduled', _scheduledRules.toString(), Colors.blue),
          SizedBox(width: 2.w),
          _buildStatChip(
            'Total Rules',
            _rules.length.toString(),
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesTab() {
    if (_rules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rule, size: 40.sp, color: Colors.grey.shade400),
            SizedBox(height: 2.h),
            Text(
              'No automation rules',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
            ),
            SizedBox(height: 1.h),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) =>
                    CreateAutomationRuleDialog(onCreated: _loadData),
              ),
              icon: const Icon(Icons.add),
              label: Text('Create Rule', style: GoogleFonts.inter()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: _rules.length,
      itemBuilder: (context, index) {
        final rule = _rules[index];
        return RuleCardWidget(
          rule: rule,
          onToggle: (enabled) => _toggleRule(rule.ruleId, enabled),
          onEdit: () {},
          onDelete: () => _deleteRule(rule.ruleId),
          onExecuteNow: () => _executeNow(rule),
          onOverride: () => _setOverride(rule.ruleId),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_executionLogs.isEmpty) {
      return Center(
        child: Text(
          'No execution history',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: Colors.grey.shade500,
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
          columns: [
            DataColumn(
              label: Text(
                'Rule',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Executed At',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Conditions',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Affected',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          rows: _executionLogs
              .map(
                (log) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        log.ruleName,
                        style: GoogleFonts.inter(fontSize: 10.sp),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatDateTime(log.executedAt),
                        style: GoogleFonts.inter(fontSize: 10.sp),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.5.w,
                          vertical: 0.2.h,
                        ),
                        decoration: BoxDecoration(
                          color: log.status == 'success'
                              ? Colors.green.shade100
                              : log.status == 'skipped'
                              ? Colors.grey.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          log.status.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9.sp,
                            color: log.status == 'success'
                                ? Colors.green.shade700
                                : log.status == 'skipped'
                                ? Colors.grey.shade600
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Icon(
                        log.conditionsMet ? Icons.check_circle : Icons.cancel,
                        color: log.conditionsMet ? Colors.green : Colors.red,
                        size: 14.sp,
                      ),
                    ),
                    DataCell(
                      Text(
                        log.affectedCount.toString(),
                        style: GoogleFonts.inter(fontSize: 10.sp),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildOverridesTab() {
    final overriddenRules = _rules
        .where(
          (r) =>
              r.overrideUntil != null &&
              r.overrideUntil!.isAfter(DateTime.now()),
        )
        .toList();
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emergency,
                    color: Colors.red.shade700,
                    size: 18.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Emergency Controls',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.5.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _emergencyStop,
                  icon: Icon(Icons.stop_circle, size: 16.sp),
                  label: Text(
                    'EMERGENCY STOP ALL AUTOMATIONS',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Override Duration Controls',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 1.h),
        ..._rules.map(
          (rule) => Card(
            margin: EdgeInsets.only(bottom: 1.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              leading: Icon(
                rule.overrideUntil != null &&
                        rule.overrideUntil!.isAfter(DateTime.now())
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color:
                    rule.overrideUntil != null &&
                        rule.overrideUntil!.isAfter(DateTime.now())
                    ? Colors.orange
                    : Colors.green,
              ),
              title: Text(
                rule.ruleName,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle:
                  rule.overrideUntil != null &&
                      rule.overrideUntil!.isAfter(DateTime.now())
                  ? Text(
                      'Override until: ${_formatDateTime(rule.overrideUntil!)}',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.orange.shade700,
                      ),
                    )
                  : Text(
                      'Active',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.green.shade700,
                      ),
                    ),
              trailing: TextButton(
                onPressed: () => _setOverride(rule.ruleId),
                child: Text(
                  'Override',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (overriddenRules.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              child: Text(
                'No active overrides',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        _buildSettingCard(
          icon: Icons.timer,
          title: 'Execution Interval',
          subtitle: 'Check rules every 1 minute',
          color: Colors.blue,
        ),
        _buildSettingCard(
          icon: Icons.notifications_active,
          title: 'Admin Alerts',
          subtitle: 'Send alerts on rule execution failures',
          color: Colors.orange,
        ),
        _buildSettingCard(
          icon: Icons.history,
          title: 'Log Retention',
          subtitle: 'Keep execution logs for 90 days',
          color: Colors.purple,
        ),
        _buildSettingCard(
          icon: Icons.security,
          title: 'Audit Trail',
          subtitle: 'All executions logged for compliance',
          color: Colors.green,
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scheduled Execution Engine',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'The engine monitors automation_rules every 1 minute, evaluating cron schedules and executing actions when conditions are met. All executions are logged to automation_execution_log for audit compliance.',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, color: color, size: 16.sp),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
