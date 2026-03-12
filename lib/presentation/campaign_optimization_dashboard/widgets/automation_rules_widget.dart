import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AutomationRulesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> rules;
  final Function(String, bool) onToggle;
  final Function(String) onDelete;
  final VoidCallback onRefresh;

  const AutomationRulesWidget({
    super.key,
    required this.rules,
    required this.onToggle,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Automated Campaign Rules',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateRuleDialog(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: Text(
                  'New Rule',
                  style: TextStyle(fontSize: 13.sp, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (rules.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 60.sp, color: Colors.purple),
                  SizedBox(height: 2.h),
                  Text(
                    'No Automation Rules',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Create rules to automate campaign management',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return _buildRuleCard(context, rule);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRuleCard(BuildContext context, Map<String, dynamic> rule) {
    final ruleName = rule['rule_name'] ?? 'Unnamed Rule';
    final ruleType = rule['rule_type'] ?? 'budget_adjustment';
    final isActive = rule['is_active'] ?? false;
    final priority = rule['priority'] ?? 1;
    final executionCount = rule['execution_count'] ?? 0;
    final triggerConditions = rule['trigger_conditions'] ?? {};

    String typeLabel = _getRuleTypeLabel(ruleType);
    IconData typeIcon = _getRuleTypeIcon(ruleType);
    Color typeColor = _getRuleTypeColor(ruleType);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruleName,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        typeLabel,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isActive,
                  onChanged: (value) => onToggle(rule['id'], value),
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trigger Conditions:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  ...triggerConditions.entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(top: 0.5.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 14.sp,
                            color: Colors.grey,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              '${entry.key}: ${entry.value}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    'Priority',
                    priority.toString(),
                    Icons.priority_high,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildInfoBox(
                    'Executions',
                    executionCount.toString(),
                    Icons.play_circle,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildInfoBox(
                    'Status',
                    isActive ? 'Active' : 'Paused',
                    isActive ? Icons.check_circle : Icons.pause_circle,
                    isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showDeleteConfirmation(context, rule['id']),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text('Delete', style: TextStyle(fontSize: 13.sp)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRuleDetails(context, rule),
                    icon: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'Details',
                      style: TextStyle(fontSize: 13.sp, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showCreateRuleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Automation Rule'),
        content: Text(
          'Automation rule creation interface coming soon. This will allow you to set custom triggers and actions for automated campaign management.',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRuleDetails(BuildContext context, Map<String, dynamic> rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rule['rule_name'] ?? 'Rule Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${_getRuleTypeLabel(rule['rule_type'])}'),
              SizedBox(height: 1.h),
              Text('Priority: ${rule['priority']}'),
              SizedBox(height: 1.h),
              Text('Executions: ${rule['execution_count']}'),
              SizedBox(height: 1.h),
              Text('Status: ${rule['is_active'] ? 'Active' : 'Paused'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String ruleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: const Text(
          'Are you sure you want to delete this automation rule?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(ruleId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getRuleTypeLabel(String type) {
    switch (type) {
      case 'budget_adjustment':
        return 'Budget Adjustment';
      case 'pause_campaign':
        return 'Pause Campaign';
      case 'increase_bid':
        return 'Increase Bid';
      case 'decrease_bid':
        return 'Decrease Bid';
      case 'rotate_creative':
        return 'Rotate Creative';
      case 'expand_audience':
        return 'Expand Audience';
      case 'send_alert':
        return 'Send Alert';
      default:
        return 'Automation Rule';
    }
  }

  IconData _getRuleTypeIcon(String type) {
    switch (type) {
      case 'budget_adjustment':
        return Icons.attach_money;
      case 'pause_campaign':
        return Icons.pause_circle;
      case 'increase_bid':
        return Icons.arrow_upward;
      case 'decrease_bid':
        return Icons.arrow_downward;
      case 'rotate_creative':
        return Icons.rotate_right;
      case 'expand_audience':
        return Icons.group_add;
      case 'send_alert':
        return Icons.notifications;
      default:
        return Icons.auto_awesome;
    }
  }

  Color _getRuleTypeColor(String type) {
    switch (type) {
      case 'budget_adjustment':
        return Colors.green;
      case 'pause_campaign':
        return Colors.red;
      case 'increase_bid':
        return Colors.blue;
      case 'decrease_bid':
        return Colors.orange;
      case 'rotate_creative':
        return Colors.purple;
      case 'expand_audience':
        return Colors.teal;
      case 'send_alert':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
