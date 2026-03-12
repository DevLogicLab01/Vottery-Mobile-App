import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SubscriptionTiersComparisonWidget extends StatelessWidget {
  final String currentPlan;

  const SubscriptionTiersComparisonWidget({
    super.key,
    required this.currentPlan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Comparison',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  theme.colorScheme.primaryContainer,
                ),
                columns: [
                  DataColumn(
                    label: Text(
                      'Feature',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: _buildPlanHeader('Basic', currentPlan, theme),
                  ),
                  DataColumn(
                    label: _buildPlanHeader('Pro', currentPlan, theme),
                  ),
                  DataColumn(
                    label: _buildPlanHeader('Elite', currentPlan, theme),
                  ),
                ],
                rows: [
                  _buildRow('VP Multiplier', '2x', '3x', '5x', theme),
                  _buildRow(
                    'Monthly Price',
                    '\$9.99',
                    '\$24.99',
                    '\$49.99',
                    theme,
                  ),
                  _buildCheckRow('Ad-free', false, true, true, theme),
                  _buildCheckRow('Priority Support', false, true, true, theme),
                  _buildCheckRow('Custom Themes', false, false, true, theme),
                  _buildRow(
                    'Benefits',
                    'Standard',
                    'Enhanced',
                    'Premium',
                    theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanHeader(String plan, String currentPlan, ThemeData theme) {
    final isCurrent = plan.toLowerCase() == currentPlan.toLowerCase();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          plan,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: isCurrent
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        if (isCurrent)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.2.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'Current',
              style: TextStyle(
                fontSize: 8.sp,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
      ],
    );
  }

  DataRow _buildRow(
    String feature,
    String basic,
    String pro,
    String elite,
    ThemeData theme,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(feature, style: TextStyle(fontSize: 11.sp))),
        DataCell(
          Text(
            basic,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
        ),
        DataCell(
          Text(
            pro,
            style: TextStyle(fontSize: 11.sp, color: Colors.blue.shade600),
          ),
        ),
        DataCell(
          Text(
            elite,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF7B2FF7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  DataRow _buildCheckRow(
    String feature,
    bool basic,
    bool pro,
    bool elite,
    ThemeData theme,
  ) {
    return DataRow(
      cells: [
        DataCell(Text(feature, style: TextStyle(fontSize: 11.sp))),
        DataCell(_checkIcon(basic)),
        DataCell(_checkIcon(pro)),
        DataCell(_checkIcon(elite)),
      ],
    );
  }

  Widget _checkIcon(bool included) {
    return Icon(
      included ? Icons.check_circle : Icons.cancel,
      color: included ? Colors.green : Colors.grey.shade400,
      size: 20,
    );
  }
}
