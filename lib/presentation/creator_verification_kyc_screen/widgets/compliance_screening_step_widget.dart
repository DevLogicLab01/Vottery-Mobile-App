import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ComplianceScreeningStepWidget extends StatelessWidget {
  final Map<String, dynamic>? verificationStatus;
  final VoidCallback onSubmit;

  const ComplianceScreeningStepWidget({
    super.key,
    this.verificationStatus,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final status = verificationStatus?['verification_status'] ?? 'pending';
    final isAlreadySubmitted = status == 'under_review' || status == 'approved';

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 5: Review & Submit',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Review your information and submit for compliance screening',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          _buildInfoSection('Personal Information', [
            _buildInfoRow(
              'Full Name',
              verificationStatus?['full_name'] ?? 'Not provided',
            ),
            _buildInfoRow(
              'Date of Birth',
              verificationStatus?['date_of_birth'] ?? 'Not provided',
            ),
            _buildInfoRow(
              'Address',
              '${verificationStatus?['address_line1'] ?? ''}, ${verificationStatus?['city'] ?? ''}, ${verificationStatus?['state'] ?? ''}',
            ),
            _buildInfoRow(
              'Phone',
              verificationStatus?['phone'] ?? 'Not provided',
            ),
          ]),
          SizedBox(height: 2.h),
          _buildInfoSection('Bank Account', [
            _buildInfoRow(
              'Account Number',
              verificationStatus?['bank_account_number'] != null
                  ? '****${verificationStatus!['bank_account_number'].toString().substring(verificationStatus!['bank_account_number'].toString().length - 4)}'
                  : 'Not provided',
            ),
            _buildInfoRow(
              'Routing Number',
              verificationStatus?['bank_routing_number'] ?? 'Not provided',
            ),
          ]),
          SizedBox(height: 2.h),
          _buildInfoSection('Tax Information', [
            _buildInfoRow(
              'Tax ID',
              verificationStatus?['tax_id'] != null
                  ? '***-**-****'
                  : 'Not provided',
            ),
            _buildInfoRow(
              'Tax Document Type',
              verificationStatus?['tax_document_type'] ?? 'Not provided',
            ),
          ]),
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withAlpha(26),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: AppTheme.primaryLight, size: 5.w),
                    SizedBox(width: 2.w),
                    Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.h),
                Text(
                  '• Your information will be reviewed by our compliance team\n'
                  '• Verification typically takes 2-3 business days\n'
                  '• You will receive an email notification with the results\n'
                  '• Once approved, you can start receiving payouts',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAlreadySubmitted ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                backgroundColor: AppTheme.accentLight,
              ),
              child: Text(
                isAlreadySubmitted ? 'Already Submitted' : 'Submit for Review',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8.0),
      ),
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
          SizedBox(height: 1.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryLight,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
