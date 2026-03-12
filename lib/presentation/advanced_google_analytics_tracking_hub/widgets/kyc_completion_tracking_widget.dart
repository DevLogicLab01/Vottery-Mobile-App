import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class KycCompletionTrackingWidget extends StatelessWidget {
  const KycCompletionTrackingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'KYC Completion Tracking',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildStepCard('kyc_step_1_started', 342),
        _buildStepCard('kyc_step_2_identity_upload', 298),
        _buildStepCard('kyc_step_3_address_verification', 267),
        _buildStepCard('kyc_step_4_bank_details', 245),
        _buildStepCard('kyc_step_5_tax_documents', 223),
        _buildStepCard('kyc_approved', 198),
        _buildStepCard('kyc_rejected', 25),
      ],
    );
  }

  Widget _buildStepCard(String step, int count) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(step, style: GoogleFonts.inter(fontSize: 12.sp)),
          Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
