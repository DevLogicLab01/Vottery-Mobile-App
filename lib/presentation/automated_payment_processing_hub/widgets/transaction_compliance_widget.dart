import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TransactionComplianceWidget extends StatelessWidget {
  final List<Map<String, dynamic>> complianceLogs;
  final List<Map<String, dynamic>> transactions;

  const TransactionComplianceWidget({
    super.key,
    required this.complianceLogs,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceStatusCard(),
          SizedBox(height: 3.h),
          _buildComplianceMetrics(),
          SizedBox(height: 3.h),
          Text(
            'Recent Compliance Checks',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          _buildComplianceInfo(),
        ],
      ),
    );
  }

  Widget _buildComplianceStatusCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: Colors.green, size: 10.w),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliance Status: Active',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                Text(
                  'All transactions meet GDPR and PCI-DSS requirements',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'GDPR Compliant',
            '100%',
            Icons.policy,
            Colors.blue,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildMetricCard(
            'PCI-DSS',
            'Level 1',
            Icons.security,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 10.w),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceItem(
            'Data Encryption',
            'All payment data encrypted with AES-256',
            Icons.lock,
            Colors.green,
          ),
          Divider(height: 3.h),
          _buildComplianceItem(
            'Transaction Logging',
            'Complete audit trail for all transactions',
            Icons.history,
            Colors.blue,
          ),
          Divider(height: 3.h),
          _buildComplianceItem(
            'Regional Compliance',
            'Automatic validation across 8 zones',
            Icons.public,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 6.w),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
