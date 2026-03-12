import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PolicyManagementWidget extends StatelessWidget {
  final List<Map<String, dynamic>> policies;

  const PolicyManagementWidget({super.key, required this.policies});

  @override
  Widget build(BuildContext context) {
    final policiesByCategory = <String, List<Map<String, dynamic>>>{};

    for (final policy in policies) {
      final category = policy['policy_category'] as String;
      if (!policiesByCategory.containsKey(category)) {
        policiesByCategory[category] = [];
      }
      policiesByCategory[category]!.add(policy);
    }

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: policiesByCategory.entries.map((entry) {
        return _buildPolicyCategory(context, entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildPolicyCategory(
    BuildContext context,
    String category,
    List<Map<String, dynamic>> categoryPolicies,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ExpansionTile(
        title: Text(
          _formatCategoryName(category),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${categoryPolicies.length} policies',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
        ),
        children: categoryPolicies.map((policy) {
          return _buildPolicyCard(context, policy);
        }).toList(),
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, Map<String, dynamic> policy) {
    final policyName = policy['policy_name'] as String;
    final description = policy['description'] as String;
    final severity = policy['severity'] as String;
    final isActive = policy['is_active'] as bool;

    Color severityColor;
    switch (severity) {
      case 'critical':
        severityColor = Colors.red;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      case 'medium':
        severityColor = Colors.yellow[700]!;
        break;
      default:
        severityColor = Colors.blue;
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  policyName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withAlpha(51),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: severityColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withAlpha(51)
                          : Colors.grey.withAlpha(51),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            description,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
