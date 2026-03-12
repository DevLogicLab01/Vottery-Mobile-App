import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class CurrentPlanCardWidget extends StatelessWidget {
  final Map<String, dynamic>? subscription;
  final String currentPlan;
  final int vpMultiplier;

  const CurrentPlanCardWidget({
    super.key,
    required this.subscription,
    required this.currentPlan,
    required this.vpMultiplier,
  });

  Color _planColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'elite':
        return const Color(0xFF7B2FF7);
      case 'pro':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _planIcon(String plan) {
    switch (plan.toLowerCase()) {
      case 'elite':
        return Icons.workspace_premium;
      case 'pro':
        return Icons.star;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = subscription?['status'] as String? ?? 'inactive';
    final startDate = subscription?['subscription_start_date'] as String?;
    final nextBilling = subscription?['next_billing_date'] as String?;
    final planColor = _planColor(currentPlan);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [planColor, planColor.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_planIcon(currentPlan), color: Colors.white, size: 32),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    '$currentPlan Plan',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFFFFD700), size: 24),
                SizedBox(width: 2.w),
                Text(
                  'VP Multiplier: ${vpMultiplier}x',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (startDate != null) ...[
              SizedBox(height: 1.h),
              Text(
                'Member since: ${_formatDate(startDate)}',
                style: TextStyle(fontSize: 11.sp, color: Colors.white70),
              ),
            ],
            if (nextBilling != null) ...[
              SizedBox(height: 0.5.h),
              Text(
                'Next billing: ${_formatDate(nextBilling)}',
                style: TextStyle(fontSize: 11.sp, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'active':
        color = Colors.green;
        label = 'ACTIVE';
        break;
      case 'past_due':
        color = Colors.orange;
        label = 'PAST DUE';
        break;
      case 'canceled':
        color = Colors.red;
        label = 'CANCELED';
        break;
      default:
        color = Colors.grey;
        label = 'INACTIVE';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day}/${date.month}/${date.year}';
  }
}
