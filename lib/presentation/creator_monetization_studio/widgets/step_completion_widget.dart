import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class StepCompletionWidget extends StatelessWidget {
  final VoidCallback onLaunchDashboard;
  const StepCompletionWidget({super.key, required this.onLaunchDashboard});

  @override
  Widget build(BuildContext context) {
    final nextActions = [
      ('Create Your First Election', Icons.add_circle_outline),
      ('Set Up Marketplace Service', Icons.store_outlined),
      ('Join Creator Community', Icons.group_outlined),
      ('Explore Sponsorships', Icons.handshake_outlined),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          SizedBox(height: 3.h),
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              children: [
                const Icon(Icons.celebration, size: 64, color: Colors.white),
                SizedBox(height: 2.h),
                Text(
                  'You\'re All Set!',
                  style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Your creator monetization studio is ready. Start earning from your elections today!',
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
          Container(
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
                  'Next Steps',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 1.h),
                ...nextActions.map(
                  (action) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 0.8.h),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withAlpha(26),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Icon(
                            action.$2,
                            size: 18,
                            color: const Color(0xFF6C63FF),
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            action.$1,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onLaunchDashboard,
              icon: const Icon(Icons.dashboard, size: 20),
              label: Text(
                'Go to Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
