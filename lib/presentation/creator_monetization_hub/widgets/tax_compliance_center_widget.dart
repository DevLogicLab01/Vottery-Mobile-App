import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TaxComplianceCenterWidget extends StatelessWidget {
  final Map<String, dynamic> complianceStatus;
  final List<Map<String, dynamic>> taxDocuments;
  final Function(Map<String, dynamic>) onDocumentUpload;

  const TaxComplianceCenterWidget({
    super.key,
    required this.complianceStatus,
    required this.taxDocuments,
    required this.onDocumentUpload,
  });

  @override
  Widget build(BuildContext context) {
    final complianceScore = complianceStatus['compliance_score'] ?? 0;
    final validDocs = complianceStatus['valid_documents'] ?? 0;
    final expiredDocs = complianceStatus['expired_documents'] ?? 0;
    final expiringSoon = complianceStatus['expiring_soon'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComplianceScoreCard(complianceScore),
          SizedBox(height: 2.h),
          _buildComplianceMetrics(validDocs, expiredDocs, expiringSoon),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax Documents',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showUploadDialog(context),
                icon: Icon(Icons.upload_file, size: 4.w),
                label: Text('Upload'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...taxDocuments.map((doc) => _buildDocumentCard(doc)),
        ],
      ),
    );
  }

  Widget _buildComplianceScoreCard(int score) {
    final color = score >= 90
        ? Colors.green
        : score >= 70
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withAlpha(204)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Icon(
              score >= 90
                  ? Icons.check_circle
                  : score >= 70
                  ? Icons.warning
                  : Icons.error,
              color: Colors.white,
              size: 8.w,
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliance Score',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceMetrics(int valid, int expired, int expiring) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Valid',
            valid,
            Colors.green,
            Icons.check_circle,
          ),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildMetricCard('Expired', expired, Colors.red, Icons.error),
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: _buildMetricCard(
            'Expiring',
            expiring,
            Colors.orange,
            Icons.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 1.h),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final docType = doc['document_type'] ?? 'Unknown';
    final status = doc['status'] ?? 'pending';
    final createdAt = doc['created_at'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: AppTheme.primaryLight, size: 6.w),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  docType,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    DateFormat(
                      'MMM dd, yyyy',
                    ).format(DateTime.parse(createdAt)),
                    style: TextStyle(
                      fontSize: 9.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 8.sp,
                color: _getStatusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'generated':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Tax Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('W-9 (US)'),
              onTap: () {
                Navigator.pop(context);
                onDocumentUpload({'type': 'W-9'});
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('W-8BEN (International)'),
              onTap: () {
                Navigator.pop(context);
                onDocumentUpload({'type': 'W-8BEN'});
              },
            ),
          ],
        ),
      ),
    );
  }
}
