import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class VariableManagementWidget extends StatelessWidget {
  const VariableManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final variables = [
      {
        'name': '{system_name}',
        'type': 'string',
        'description': 'Name of the affected system or service',
        'example': 'Payment Gateway',
      },
      {
        'name': '{user_id}',
        'type': 'string',
        'description': 'User identifier or account ID',
        'example': 'user_12345',
      },
      {
        'name': '{confidence}',
        'type': 'percentage',
        'description': 'Fraud detection confidence score',
        'example': '95',
      },
      {
        'name': '{amount}',
        'type': 'currency',
        'description': 'Transaction or monetary amount',
        'example': '\$1,234.56',
      },
      {
        'name': '{percentage}',
        'type': 'percentage',
        'description': 'Generic percentage value',
        'example': '45.2',
      },
      {
        'name': '{metric_name}',
        'type': 'string',
        'description': 'Performance metric identifier',
        'example': 'API Response Time',
      },
      {
        'name': '{current_value}',
        'type': 'string',
        'description': 'Current metric value',
        'example': '2500ms',
      },
      {
        'name': '{baseline_value}',
        'type': 'string',
        'description': 'Expected or baseline metric value',
        'example': '500ms',
      },
      {
        'name': '{eta_minutes}',
        'type': 'number',
        'description': 'Estimated time to resolution in minutes',
        'example': '30',
      },
      {
        'name': '{dashboard_url}',
        'type': 'string',
        'description': 'URL to relevant dashboard or investigation page',
        'example': 'https://app.example.com/investigate',
      },
    ];

    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: variables.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final variable = variables[index];
        return _buildVariableCard(theme, variable);
      },
    );
  }

  Widget _buildVariableCard(ThemeData theme, Map<String, dynamic> variable) {
    final typeColor = _getTypeColor(variable['type'] as String);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  variable['name'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  variable['type'] as String,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            variable['description'] as String,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[700]),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Example: ',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  variable['example'] as String,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[800],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'string':
        return Colors.blue;
      case 'number':
        return Colors.green;
      case 'currency':
        return Colors.orange;
      case 'percentage':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
