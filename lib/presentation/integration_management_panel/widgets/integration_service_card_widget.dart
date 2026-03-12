import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class IntegrationServiceCardWidget extends StatelessWidget {
  final Map<String, dynamic> integration;
  final Map<String, dynamic>? analytics;
  final Function({
    required String integrationId,
    required String integrationName,
    required bool currentStatus,
  })
  onToggle;
  final Function(Map<String, dynamic> integration) onBudgetConfig;
  final Function(Map<String, dynamic> integration) onViewDetails;

  const IntegrationServiceCardWidget({
    super.key,
    required this.integration,
    this.analytics,
    required this.onToggle,
    required this.onBudgetConfig,
    required this.onViewDetails,
  });

  bool _shouldShowBudgetAlert(double currentUsage, double budgetCap) {
    if (budgetCap == 0) return false;
    return (currentUsage / budgetCap) * 100 >= 80;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = integration['is_enabled'] as bool;
    final integrationName = integration['integration_name'] as String;
    final weeklyBudgetCap =
        (integration['weekly_budget_cap'] as num?)?.toDouble() ?? 0.0;
    final monthlyBudgetCap =
        (integration['monthly_budget_cap'] as num?)?.toDouble() ?? 0.0;
    final currentWeeklyUsage =
        (integration['current_weekly_usage'] as num?)?.toDouble() ?? 0.0;
    final currentMonthlyUsage =
        (integration['current_monthly_usage'] as num?)?.toDouble() ?? 0.0;
    final uptimePercentage =
        (integration['uptime_percentage'] as num?)?.toDouble() ?? 0.0;

    final showWeeklyAlert = _shouldShowBudgetAlert(
      currentWeeklyUsage,
      weeklyBudgetCap,
    );
    final showMonthlyAlert = _shouldShowBudgetAlert(
      currentMonthlyUsage,
      monthlyBudgetCap,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      integrationName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isEnabled ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          isEnabled ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${uptimePercentage.toStringAsFixed(2)}% uptime',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (_) => onToggle(
                  integrationId: integration['id'] as String,
                  integrationName: integrationName,
                  currentStatus: isEnabled,
                ),
                activeThumbColor: Colors.green,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildBudgetInfo(
                  'Weekly',
                  currentWeeklyUsage,
                  weeklyBudgetCap,
                  showWeeklyAlert,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildBudgetInfo(
                  'Monthly',
                  currentMonthlyUsage,
                  monthlyBudgetCap,
                  showMonthlyAlert,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onBudgetConfig(integration),
                  icon: Icon(Icons.settings, size: 14.sp),
                  label: Text('Budget', style: TextStyle(fontSize: 11.sp)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onViewDetails(integration),
                  icon: Icon(Icons.analytics, size: 14.sp),
                  label: Text('Details', style: TextStyle(fontSize: 11.sp)),
                  style: ElevatedButton.styleFrom(
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

  Widget _buildBudgetInfo(
    String label,
    double currentUsage,
    double budgetCap,
    bool showAlert,
  ) {
    final percentage = budgetCap > 0 ? (currentUsage / budgetCap) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: showAlert ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: showAlert ? Colors.red.shade700 : Colors.grey[700],
                ),
              ),
              if (showAlert)
                Icon(Icons.warning, size: 12.sp, color: Colors.red.shade700),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            '\$${currentUsage.toStringAsFixed(2)} / \$${budgetCap.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: showAlert ? Colors.red.shade700 : Colors.grey[800],
            ),
          ),
          SizedBox(height: 0.5.h),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(
              showAlert ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
