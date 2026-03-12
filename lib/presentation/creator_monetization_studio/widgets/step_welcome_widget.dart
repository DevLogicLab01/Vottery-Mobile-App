import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class StepWelcomeWidget extends StatelessWidget {
  final VoidCallback onGetStarted;
  const StepWelcomeWidget({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SizedBox(height: 3.h),
          Container(
            width: 80.w,
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.monetization_on,
                  size: 64,
                  color: Colors.white,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Start Your Creator Journey',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),
                Text(
                  'Turn your elections into earnings. Join thousands of creators monetizing their influence.',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white.withAlpha(230),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          _buildEarningsPotentialCard(),
          SizedBox(height: 2.h),
          _buildBenefitsList(),
        ],
      ),
    );
  }

  Widget _buildEarningsPotentialCard() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
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
          Text(
            'Earnings Potential',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: _buildEarningTier('Bronze', '\$50-200', Colors.brown),
              ),
              Expanded(
                child: _buildEarningTier(
                  'Silver',
                  '\$200-500',
                  Colors.grey.shade600,
                ),
              ),
              Expanded(
                child: _buildEarningTier(
                  'Gold',
                  '\$500-2K',
                  const Color(0xFFFFB300),
                ),
              ),
              Expanded(
                child: _buildEarningTier(
                  'Platinum',
                  '\$2K+',
                  const Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningTier(String tier, String range, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(Icons.star, color: color, size: 20),
        ),
        SizedBox(height: 0.5.h),
        Text(
          tier,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          range,
          style: GoogleFonts.inter(fontSize: 9.sp, color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBenefitsList() {
    final benefits = [
      ('Earn from every election you create', Icons.attach_money),
      ('Access brand sponsorships & partnerships', Icons.handshake),
      ('Automated payouts via Stripe Connect', Icons.account_balance),
      ('Real-time earnings analytics dashboard', Icons.analytics),
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
            'What You Get',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 1.h),
          ...benefits.map(
            (b) => Padding(
              padding: EdgeInsets.symmetric(vertical: 0.8.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(1.5.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withAlpha(26),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Icon(b.$2, size: 16, color: const Color(0xFF6C63FF)),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      b.$1,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.black87,
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
}
