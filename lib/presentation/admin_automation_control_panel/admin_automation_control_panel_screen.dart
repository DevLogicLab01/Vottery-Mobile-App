import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/admin_automation_engine_service.dart';
import '../../theme/app_theme.dart';
import './widgets/automation_rule_card_widget.dart';
import './widgets/execution_history_widget.dart';
import './widgets/override_control_panel_widget.dart';

class AdminAutomationControlPanelScreen extends StatefulWidget {
  const AdminAutomationControlPanelScreen({super.key});

  @override
  State<AdminAutomationControlPanelScreen> createState() =>
      _AdminAutomationControlPanelScreenState();
}

class _AdminAutomationControlPanelScreenState
    extends State<AdminAutomationControlPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AutomationRule> _rules = [];
  bool _loading = true;
  bool _engineRunning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    AdminAutomationEngineService.stopScheduledEngine();
    super.dispose();
  }

  Future<void> _loadRules() async {
    final rules = await AdminAutomationEngineService.getAutomationRules();
    if (mounted) {
      setState(() {
        _rules = rules;
        _loading = false;
      });
    }
  }

  Future<void> _toggleRule(int index) async {
    final rule = _rules[index];
    final newEnabled = !rule.isEnabled;
    await AdminAutomationEngineService.toggleRule(rule.ruleId, newEnabled);
    if (mounted) {
      setState(() {
        _rules[index] = AutomationRule(
          ruleId: rule.ruleId,
          type: rule.type,
          ruleName: rule.ruleName,
          conditions: rule.conditions,
          actions: rule.actions,
          schedule: rule.schedule,
          isEnabled: newEnabled,
          lastExecuted: rule.lastExecuted,
          overrideUntil: rule.overrideUntil,
        );
      });
    }
  }

  Future<void> _executeNow(int index) async {
    final rule = _rules[index];
    await AdminAutomationEngineService.executeRuleNow(rule);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${rule.ruleName} executed successfully',
            style: GoogleFonts.inter(fontSize: 11.sp),
          ),
        ),
      );
    }
  }

  Future<void> _setOverride(String ruleId, Duration duration) async {
    await AdminAutomationEngineService.setOverride(ruleId, duration);
    await _loadRules();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Override set for ${duration.inHours}h',
            style: GoogleFonts.inter(fontSize: 11.sp),
          ),
        ),
      );
    }
  }

  Future<void> _emergencyStop() async {
    await AdminAutomationEngineService.emergencyStopAll();
    await _loadRules();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All automations stopped'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.smart_toy, size: 22),
            SizedBox(width: 2.w),
            Text(
              'Admin Automation Control',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 2.w),
            child: Row(
              children: [
                Text(
                  _engineRunning ? 'Engine ON' : 'Engine OFF',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(width: 1.w),
                Switch(
                  value: _engineRunning,
                  onChanged: (val) {
                    setState(() => _engineRunning = val);
                    if (val) {
                      AdminAutomationEngineService.startScheduledEngine();
                    } else {
                      AdminAutomationEngineService.stopScheduledEngine();
                    }
                  },
                  activeThumbColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          labelStyle: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.rule, size: 16), text: 'Rules'),
            Tab(icon: Icon(Icons.history, size: 16), text: 'History'),
            Tab(icon: Icon(Icons.pause_circle, size: 16), text: 'Overrides'),
            Tab(icon: Icon(Icons.settings, size: 16), text: 'Settings'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Rules Tab
                SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(),
                      SizedBox(height: 2.h),
                      Text(
                        'Automation Rules (${_rules.length})',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ..._rules.asMap().entries.map(
                        (e) => AutomationRuleCardWidget(
                          rule: e.value,
                          onToggle: () => _toggleRule(e.key),
                          onExecuteNow: () => _executeNow(e.key),
                          onOverride: (duration) =>
                              _setOverride(e.value.ruleId, duration),
                        ),
                      ),
                    ],
                  ),
                ),
                // History Tab
                const SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: ExecutionHistoryWidget(),
                ),
                // Overrides Tab
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: OverrideControlPanelWidget(
                    rules: _rules,
                    onOverride: _setOverride,
                    onEmergencyStop: _emergencyStop,
                  ),
                ),
                // Settings Tab
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildStatsRow() {
    final enabled = _rules.where((r) => r.isEnabled).length;
    final overridden = _rules.where((r) => r.isOverridden).length;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Rules',
            '${_rules.length}',
            Colors.blue,
            Icons.rule,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatCard(
            'Active',
            '$enabled',
            Colors.green,
            Icons.play_circle,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildStatCard(
            'Overridden',
            '$overridden',
            Colors.amber,
            Icons.pause_circle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 0.5.h),
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
            style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engine Settings',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.blue),
                  title: Text(
                    'Check Interval',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Every 1 minute',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.notifications,
                    color: Colors.orange,
                  ),
                  title: Text(
                    'Admin Alerts',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Notify on execution failures',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Switch(value: true, onChanged: (_) {}),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.purple),
                  title: Text(
                    'Log Retention',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Keep 90 days of execution history',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Rule Types',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          ...AutomationRuleType.values.map(
            (type) => Card(
              margin: EdgeInsets.only(bottom: 0.5.h),
              child: ListTile(
                leading: Icon(_typeIcon(type), color: _typeColor(type)),
                title: Text(
                  _typeName(type),
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _typeDescription(type),
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(AutomationRuleType type) {
    switch (type) {
      case AutomationRuleType.festivalMode:
        return Icons.celebration;
      case AutomationRuleType.fraudProneRegionPause:
        return Icons.block;
      case AutomationRuleType.retentionCampaign:
        return Icons.people;
      case AutomationRuleType.dynamicPricing:
        return Icons.attach_money;
      case AutomationRuleType.maintenanceMode:
        return Icons.build;
    }
  }

  Color _typeColor(AutomationRuleType type) {
    switch (type) {
      case AutomationRuleType.festivalMode:
        return Colors.purple;
      case AutomationRuleType.fraudProneRegionPause:
        return Colors.red;
      case AutomationRuleType.retentionCampaign:
        return Colors.blue;
      case AutomationRuleType.dynamicPricing:
        return Colors.green;
      case AutomationRuleType.maintenanceMode:
        return Colors.orange;
    }
  }

  String _typeName(AutomationRuleType type) {
    switch (type) {
      case AutomationRuleType.festivalMode:
        return 'Festival Mode';
      case AutomationRuleType.fraudProneRegionPause:
        return 'Fraud-Prone Region Pause';
      case AutomationRuleType.retentionCampaign:
        return 'Retention Campaign';
      case AutomationRuleType.dynamicPricing:
        return 'Dynamic Pricing';
      case AutomationRuleType.maintenanceMode:
        return 'Maintenance Mode';
    }
  }

  String _typeDescription(AutomationRuleType type) {
    switch (type) {
      case AutomationRuleType.festivalMode:
        return 'Activate VP multipliers, badges, banners for festivals';
      case AutomationRuleType.fraudProneRegionPause:
        return 'Pause elections in high-fraud purchasing power zones';
      case AutomationRuleType.retentionCampaign:
        return 'Re-engage inactive users with VP bonuses and notifications';
      case AutomationRuleType.dynamicPricing:
        return 'Adjust subscription pricing based on zone conversion rates';
      case AutomationRuleType.maintenanceMode:
        return 'Schedule maintenance windows with user notifications';
    }
  }
}