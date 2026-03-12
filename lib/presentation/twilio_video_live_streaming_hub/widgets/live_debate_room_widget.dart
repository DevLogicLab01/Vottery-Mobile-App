import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class LiveDebateRoomWidget extends StatelessWidget {
  final List<Map<String, dynamic>> debates;

  const LiveDebateRoomWidget({super.key, required this.debates});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Active Debate Rooms',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        ...debates.map((debate) => _buildDebateCard(context, debate)),
      ],
    );
  }

  Widget _buildDebateCard(BuildContext context, Map<String, dynamic> debate) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.errorLight.withAlpha(77), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.errorLight,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 2.w,
                      height: 2.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'LIVE',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Icon(
                Icons.remove_red_eye,
                size: 4.w,
                color: AppTheme.textSecondaryLight,
              ),
              SizedBox(width: 1.w),
              Text(
                '${debate['viewers']} viewers',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            debate['title'] ?? 'Debate',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Hosted by ${debate['host'] ?? 'Unknown'}',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: () => _joinDebate(context, debate),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              minimumSize: Size(double.infinity, 5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: Text(
              'Join Debate',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _joinDebate(BuildContext context, Map<String, dynamic> debate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join Debate'),
        content: Text(
          'LiveKit video room integration ready. Connecting to ${debate['title']}...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement LiveKit room join
            },
            child: Text('Join'),
          ),
        ],
      ),
    );
  }
}
