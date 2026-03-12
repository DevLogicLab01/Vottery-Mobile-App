import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class StepPayoutConfigWidget extends StatelessWidget {
  final TextEditingController routingController;
  final TextEditingController accountController;
  final String payoutSchedule;
  final ValueChanged<String> onScheduleChanged;

  const StepPayoutConfigWidget({
    super.key,
    required this.routingController,
    required this.accountController,
    required this.payoutSchedule,
    required this.onScheduleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payout Configuration',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Set up how you get paid',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildStripeConnectCard(),
          SizedBox(height: 2.h),
          _buildBankAccountSection(),
          SizedBox(height: 2.h),
          _buildPayoutScheduleSection(),
          SizedBox(height: 2.h),
          _buildTaxDocumentSection(),
        ],
      ),
    );
  }

  Widget _buildStripeConnectCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF635BFF).withAlpha(13),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF635BFF).withAlpha(51)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: const Color(0xFF635BFF),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stripe Connect',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Secure bank account linking via Stripe',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withAlpha(26),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'Secure',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Account Details',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildLabel('Routing Number'),
          SizedBox(height: 0.5.h),
          TextField(
            controller: routingController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('9-digit routing number'),
            style: GoogleFonts.inter(fontSize: 13.sp),
          ),
          SizedBox(height: 1.5.h),
          _buildLabel('Account Number'),
          SizedBox(height: 0.5.h),
          TextField(
            controller: accountController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: _inputDecoration('Bank account number'),
            style: GoogleFonts.inter(fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutScheduleSection() {
    final schedules = ['Weekly', 'Monthly', 'Custom'];
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payout Schedule',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          ...schedules.map(
            (s) => RadioListTile<String>(
              value: s,
              groupValue: payoutSchedule,
              onChanged: (v) => onScheduleChanged(v ?? 'Monthly'),
              title: Text(
                s,
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                s == 'Weekly'
                    ? 'Every Friday, min \$50'
                    : s == 'Monthly'
                    ? '1st of each month, min \$50'
                    : 'Set your own schedule',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.grey.shade500,
                ),
              ),
              activeColor: const Color(0xFF6C63FF),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxDocumentSection() {
    final docs = [
      'W-9 (US Resident)',
      'W-8BEN (International)',
      'EIN (Business)',
    ];
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tax Documents',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          ...docs.map(
            (doc) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: Color(0xFF6C63FF),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      doc,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Upload',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: const Color(0xFF6C63FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        fontSize: 12.sp,
        color: Colors.grey.shade400,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFF6C63FF)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
    );
  }
}
