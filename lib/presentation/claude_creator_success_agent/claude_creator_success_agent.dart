import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/claude_agent_service.dart';
import '../../widgets/custom_app_bar.dart';

class ClaudeCreatorSuccessAgent extends StatefulWidget {
  const ClaudeCreatorSuccessAgent({super.key});

  @override
  State<ClaudeCreatorSuccessAgent> createState() =>
      _ClaudeCreatorSuccessAgentState();
}

class _ClaudeCreatorSuccessAgentState extends State<ClaudeCreatorSuccessAgent> {
  bool _loading = false;
  Map<String, dynamic> _metrics = const {};
  List<Map<String, dynamic>> _actions = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final metrics = await ClaudeAgentService.instance.getAutonomousActionMetrics();
      final actions = await ClaudeAgentService.instance.getAutonomousActions(
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _actions = actions;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load Claude creator success metrics.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatPercentFromRatioOrPercent(dynamic value) {
    final numeric = (value as num?)?.toDouble() ?? 0.0;
    final ratio = numeric <= 1 ? numeric : numeric / 100.0;
    final normalized = ratio.clamp(0.0, 1.0);
    return '${(normalized * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Claude Creator Success Agent',
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Text(
                _error!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_metrics['auth_required'] == true)
            Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Text(
                'Sign in required to view creator success metrics.',
                style: TextStyle(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          _MetricTile(
            label: 'Total Autonomous Actions',
            value: (_metrics['total_actions'] ?? 0).toString(),
          ),
          _MetricTile(
            label: 'Automation Rate',
            value: _formatPercentFromRatioOrPercent(_metrics['automation_rate']),
          ),
          _MetricTile(
            label: 'Average Confidence',
            value: _formatPercentFromRatioOrPercent(
              _metrics['average_confidence'],
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Recent Interventions',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          if (_actions.isEmpty)
            Text(
              'No intervention actions found yet.',
              style: TextStyle(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ..._actions.take(10).map(
                (a) => Card(
                  child: ListTile(
                    title: Text((a['action_type'] ?? 'action').toString()),
                    subtitle: Text((a['action_taken'] ?? '').toString()),
                    trailing: Text(
                      _formatPercentFromRatioOrPercent(a['confidence_score']),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
