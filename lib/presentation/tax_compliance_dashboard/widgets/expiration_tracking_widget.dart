import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ExpirationTrackingWidget extends StatelessWidget {
  final List<Map<String, dynamic>> expiringDocuments;
  final VoidCallback onRefresh;

  const ExpirationTrackingWidget({
    super.key,
    required this.expiringDocuments,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (expiringDocuments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 15.w, color: Colors.green),
            SizedBox(height: 2.h),
            Text(
              'All documents are valid',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'No documents expiring soon',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: expiringDocuments.length,
      itemBuilder: (context, index) {
        final doc = expiringDocuments[index];
        return _buildExpiringDocCard(doc);
      },
    );
  }

  Widget _buildExpiringDocCard(Map<String, dynamic> doc) {
    final documentType = doc['document_type'] ?? 'unknown';
    final expiresAt = doc['expires_at'] != null
        ? DateTime.parse(doc['expires_at'])
        : DateTime.now();
    final daysUntilExpiry = expiresAt.difference(DateTime.now()).inDays;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getUrgencyColor(daysUntilExpiry).withAlpha(26),
          child: Icon(
            Icons.schedule,
            color: _getUrgencyColor(daysUntilExpiry),
            size: 6.w,
          ),
        ),
        title: Text(
          _formatDocumentType(documentType),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Expires in $daysUntilExpiry days',
          style: TextStyle(
            fontSize: 12.sp,
            color: _getUrgencyColor(daysUntilExpiry),
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: _getUrgencyColor(daysUntilExpiry).withAlpha(26),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            _getUrgencyLabel(daysUntilExpiry),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: _getUrgencyColor(daysUntilExpiry),
            ),
          ),
        ),
      ),
    );
  }

  Color _getUrgencyColor(int daysUntilExpiry) {
    if (daysUntilExpiry <= 7) return Colors.red;
    if (daysUntilExpiry <= 30) return Colors.orange;
    if (daysUntilExpiry <= 60) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getUrgencyLabel(int daysUntilExpiry) {
    if (daysUntilExpiry <= 7) return 'Critical';
    if (daysUntilExpiry <= 30) return 'Urgent';
    if (daysUntilExpiry <= 60) return 'Soon';
    return 'Valid';
  }

  String _formatDocumentType(String type) {
    return type.replaceAll('_', ' ').toUpperCase();
  }
}
