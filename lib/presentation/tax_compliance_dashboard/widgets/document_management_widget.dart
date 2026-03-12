import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DocumentManagementWidget extends StatelessWidget {
  final List<Map<String, dynamic>> documents;
  final VoidCallback onRefresh;

  const DocumentManagementWidget({
    super.key,
    required this.documents,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No tax documents yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            ElevatedButton(
              onPressed: onRefresh,
              child: Text('Generate Document'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return _buildDocumentCard(doc);
      },
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final documentType = doc['document_type'] ?? 'unknown';
    final status = doc['status'] ?? 'pending';
    final taxYear = doc['tax_year'] ?? DateTime.now().year;
    final jurisdiction = doc['jurisdiction_code'] ?? 'N/A';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withAlpha(26),
          child: Icon(
            _getDocumentIcon(documentType),
            color: _getStatusColor(status),
            size: 6.w,
          ),
        ),
        title: Text(
          _formatDocumentType(documentType),
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Tax Year: $taxYear • $jurisdiction',
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withAlpha(26),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            _formatStatus(status),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(status),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'form_1099_nec':
      case 'form_1099_k':
        return Icons.receipt_long;
      case 'form_w8ben':
      case 'form_w9':
        return Icons.assignment;
      case 'vat_return':
      case 'gst_return':
        return Icons.account_balance;
      default:
        return Icons.description;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'generated':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      case 'submitted':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDocumentType(String type) {
    return type.replaceAll('_', ' ').toUpperCase();
  }

  String _formatStatus(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }
}
