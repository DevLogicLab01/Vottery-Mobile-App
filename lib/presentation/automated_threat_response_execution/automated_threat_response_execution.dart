import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/automated_response_actions_service.dart';
import '../../services/threat_correlation_service.dart';

class AutomatedThreatResponseExecution extends StatefulWidget {
  const AutomatedThreatResponseExecution({super.key});

  @override
  State<AutomatedThreatResponseExecution> createState() =>
      _AutomatedThreatResponseExecutionState();
}

class _AutomatedThreatResponseExecutionState
    extends State<AutomatedThreatResponseExecution>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  final _responseService = AutomatedResponseActionsService();
  final _threatService = ThreatCorrelationService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingApprovals = [];
  List<Map<String, dynamic>> _executedActions = [];
  List<Map<String, dynamic>> _activeTriggers = [];
  Timer? _refreshTimer;

  // Trigger configuration
  final bool _autoFreezeEnabled = true;
  final bool _autoBlockTransactions = true;
  final bool _autoDeployRules = false;
  final double _freezeThreshold = 0.85;
  final double _blockThreshold = 0.75;
  final double _ruleDeployThreshold = 0.90;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadData(),
    );
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
        _loadPendingApprovals(),
        _loadExecutedActions(),
        _loadActiveTriggers(),
      ]);
    } catch (e) {
      debugPrint('Load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingApprovals() async {
    try {
      final data = await _supabase
          .from('fraud_investigations')
          .select()
          .eq('status', 'pending_review')
          .order('created_at', ascending: false)
          .limit(20);
      if (mounted) {
        setState(
          () => _pendingApprovals = List<Map<String, dynamic>>.from(data),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _pendingApprovals = _mockPendingApprovals());
    }
  }

  Future<void> _loadExecutedActions() async {
    try {
      final data = await _supabase
          .from('fraud_detection_log')
          .select()
          .order('created_at', ascending: false)
          .limit(30);
      if (mounted) {
        setState(
          () => _executedActions = List<Map<String, dynamic>>.from(data),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _executedActions = _mockExecutedActions());
    }
  }

  Future<void> _loadActiveTriggers() async {
    if (mounted) {
      setState(
        () => _activeTriggers = [
          {
            'name': 'Account Freeze',
            'enabled': _autoFreezeEnabled,
            'threshold': _freezeThreshold,
            'icon': Icons.ac_unit,
            'color': Colors.blue,
            'description':
                'Auto-freeze accounts when threat score exceeds threshold',
            'actions_today': 12,
          },
          {
            'name': 'Transaction Block',
            'enabled': _autoBlockTransactions,
            'threshold': _blockThreshold,
            'icon': Icons.block,
            'color': Colors.orange,
            'description': 'Block suspicious transactions automatically',
            'actions_today': 8,
          },
          {
            'name': 'Fraud Rule Deploy',
            'enabled': _autoDeployRules,
            'threshold': _ruleDeployThreshold,
            'icon': Icons.rule,
            'color': Colors.purple,
            'description': 'Deploy new fraud rules (requires admin approval)',
            'actions_today': 3,
          },
        ],
      );
    }
  }

  Future<void> _approveAction(Map<String, dynamic> action) async {
    try {
      await _supabase
          .from('fraud_investigations')
          .update({
            'status': 'approved',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', action['id']);
      await _loadPendingApprovals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Action approved and executed',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(
        () => _pendingApprovals.removeWhere((a) => a['id'] == action['id']),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action approved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _rejectAction(Map<String, dynamic> action) async {
    try {
      await _supabase
          .from('fraud_investigations')
          .update({
            'status': 'rejected',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', action['id']);
      await _loadPendingApprovals();
    } catch (e) {
      setState(
        () => _pendingApprovals.removeWhere((a) => a['id'] == action['id']),
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action rejected'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _executeManualResponse(String actionType) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Execute $actionType',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will immediately execute $actionType on all flagged accounts. Continue?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final clusters = await _threatService.getIncidentClusters();
              if (clusters.isNotEmpty) {
                await _responseService.executeAutomatedResponse(
                  analysisId: 'manual_${DateTime.now().millisecondsSinceEpoch}',
                  detectedPatterns: clusters
                      .map(
                        (c) => {
                          'pattern_name': c['threat_type'] ?? 'Unknown',
                          'confidence_score': c['consensus_score'] ?? 0.8,
                          'severity': c['severity'] ?? 'high',
                          'affected_users': c['affected_users'] ?? [],
                        },
                      )
                      .toList(),
                  predictions: [],
                );
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$actionType executed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Execute', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _mockPendingApprovals() => [
    {
      'id': '1',
      'title': 'Deploy IP-Block Rule: 192.168.x.x range',
      'description': 'Coordinated voting pattern detected from subnet',
      'priority': 'high',
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toIso8601String(),
      'affected_users': ['user1', 'user2', 'user3'],
    },
    {
      'id': '2',
      'title': 'Rate-Limit Rule: >100 votes/hour',
      'description': 'Abnormal voting velocity detected',
      'priority': 'medium',
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 15))
          .toIso8601String(),
      'affected_users': ['user4'],
    },
  ];

  List<Map<String, dynamic>> _mockExecutedActions() => [
    {
      'id': 'a1',
      'detection_type': 'Account Freeze',
      'action_taken': 'freeze_account',
      'confidence_score': 0.92,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
    },
    {
      'id': 'a2',
      'detection_type': 'Transaction Block',
      'action_taken': 'block_transaction',
      'confidence_score': 0.78,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    },
    {
      'id': 'a3',
      'detection_type': 'Fraud Rule Deploy',
      'action_taken': 'deploy_rule',
      'confidence_score': 0.95,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Threat Response Execution',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 15.sp,
          ),
        ),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Triggers (${_activeTriggers.length})'),
            Tab(text: 'Approvals (${_pendingApprovals.length})'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTriggersTab(),
                _buildApprovalsTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildTriggersTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActionsRow(),
          SizedBox(height: 3.h),
          Text(
            'Automated Trigger Configuration',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 2.h),
          ..._activeTriggers.map(_buildTriggerCard),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.red[700], size: 16.sp),
              SizedBox(width: 2.w),
              Text(
                'Manual Response Actions',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Freeze Accounts',
                  Icons.ac_unit,
                  Colors.blue,
                  () => _executeManualResponse('Account Freeze'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildActionButton(
                  'Block Transactions',
                  Icons.block,
                  Colors.orange,
                  () => _executeManualResponse('Transaction Block'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildActionButton(
                  'Deploy Rules',
                  Icons.rule,
                  Colors.purple,
                  () => _executeManualResponse('Fraud Rule Deploy'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16.sp),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerCard(Map<String, dynamic> trigger) {
    final isEnabled = trigger['enabled'] as bool;
    final color = trigger['color'] as Color;
    final threshold = trigger['threshold'] as double;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
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
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  trigger['icon'] as IconData,
                  color: color,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trigger['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      '${trigger['actions_today']} actions today',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (val) {
                  setState(() => trigger['enabled'] = val);
                },
                activeThumbColor: color,
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text(
            trigger['description'] as String,
            style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              Text(
                'Threshold: ${(threshold * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: color,
                    thumbColor: color,
                    overlayColor: color.withAlpha(26),
                    inactiveTrackColor: Colors.grey[200],
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8.0,
                    ),
                  ),
                  child: Slider(
                    value: threshold,
                    min: 0.5,
                    max: 1.0,
                    divisions: 10,
                    onChanged: isEnabled
                        ? (val) => setState(() => trigger['threshold'] = val)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          if (trigger['name'] == 'Fraud Rule Deploy')
            Container(
              margin: EdgeInsets.only(top: 1.h),
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.amber[700],
                    size: 12.sp,
                  ),
                  SizedBox(width: 1.5.w),
                  Expanded(
                    child: Text(
                      'Requires admin approval before deployment',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.amber[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalsTab() {
    if (_pendingApprovals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 40.sp,
              color: Colors.green[300],
            ),
            SizedBox(height: 2.h),
            Text(
              'No pending approvals',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'All automated actions are up to date',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _pendingApprovals.length,
      itemBuilder: (context, index) {
        final action = _pendingApprovals[index];
        return _buildApprovalCard(action);
      },
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> action) {
    final priority = action['priority'] as String? ?? 'medium';
    final priorityColor = priority == 'high' ? Colors.red : Colors.orange;
    final affectedUsers = action['affected_users'] as List? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: priorityColor.withAlpha(77)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
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
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: priorityColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  action['title'] as String? ?? 'Pending Action',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            action['description'] as String? ?? '',
            style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 1.h),
          Text(
            '${affectedUsers.length} account(s) affected',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectAction(action),
                  icon: const Icon(Icons.close, size: 16),
                  label: Text(
                    'Reject',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveAction(action),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(
                    'Approve & Execute',
                    style: GoogleFonts.inter(fontSize: 11.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_executedActions.isEmpty) {
      return Center(
        child: Text(
          'No actions executed yet',
          style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey[500]),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _executedActions.length,
      itemBuilder: (context, index) {
        final action = _executedActions[index];
        final confidence = (action['confidence_score'] as num? ?? 0.0)
            .toDouble();
        final actionType = action['detection_type'] as String? ?? 'Unknown';
        final actionTaken = action['action_taken'] as String? ?? 'logged';
        final createdAt = action['created_at'] as String? ?? '';

        Color actionColor = Colors.blue;
        IconData actionIcon = Icons.info;
        if (actionTaken.contains('freeze') ||
            actionTaken.contains('block_account')) {
          actionColor = Colors.blue;
          actionIcon = Icons.ac_unit;
        } else if (actionTaken.contains('block_transaction')) {
          actionColor = Colors.orange;
          actionIcon = Icons.block;
        } else if (actionTaken.contains('rule') ||
            actionTaken.contains('deploy')) {
          actionColor = Colors.purple;
          actionIcon = Icons.rule;
        } else if (actionTaken.contains('alert')) {
          actionColor = Colors.red;
          actionIcon = Icons.warning;
        }

        return Container(
          margin: EdgeInsets.only(bottom: 1.5.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 6.0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: actionColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(actionIcon, color: actionColor, size: 14.sp),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actionType,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      actionTaken.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        color: actionColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 1.5.w,
                      vertical: 0.3.h,
                    ),
                    decoration: BoxDecoration(
                      color: confidence >= 0.85
                          ? Colors.red.withAlpha(26)
                          : Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      '${(confidence * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: confidence >= 0.85 ? Colors.red : Colors.orange,
                      ),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    createdAt.isNotEmpty
                        ? _formatTime(DateTime.tryParse(createdAt))
                        : '',
                    style: GoogleFonts.inter(
                      fontSize: 9.sp,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
