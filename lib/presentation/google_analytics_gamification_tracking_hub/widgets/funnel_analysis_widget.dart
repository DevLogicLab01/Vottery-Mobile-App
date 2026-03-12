import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FunnelAnalysisWidget extends StatelessWidget {
  final Map<String, dynamic> trackingData;

  const FunnelAnalysisWidget({super.key, required this.trackingData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gamification Onboarding Funnel',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Tracking user progression through gamification features',
            style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          _buildFunnelStage(
            1,
            'First VP Earned',
            100,
            100,
            'Users who earned their first VP',
            Colors.blue,
            theme,
          ),
          _buildFunnelConnector(theme),
          _buildFunnelStage(
            2,
            'First Badge Unlocked',
            75,
            75,
            'Users who unlocked their first badge',
            Colors.purple,
            theme,
          ),
          _buildFunnelConnector(theme),
          _buildFunnelStage(
            3,
            'First Redemption',
            50,
            50,
            'Users who redeemed VP in rewards shop',
            Colors.orange,
            theme,
          ),
          _buildFunnelConnector(theme),
          _buildFunnelStage(
            4,
            'Repeat User',
            35,
            35,
            'Users with 7+ days of activity',
            Colors.green,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelStage(
    int stageNumber,
    String title,
    int percentage,
    int userCount,
    String description,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    stageNumber.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$percentage%',
                    style: GoogleFonts.inter(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    '$userCount users',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 1.5.h,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelConnector(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_downward, color: Colors.grey[400], size: 24.sp),
        ],
      ),
    );
  }
}
