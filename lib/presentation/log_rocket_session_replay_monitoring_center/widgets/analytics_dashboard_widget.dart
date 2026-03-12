import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class AnalyticsDashboardWidget extends StatelessWidget {
  final Map<String, dynamic> analyticsData;

  const AnalyticsDashboardWidget({super.key, required this.analyticsData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMostVisitedScreens(),
        SizedBox(height: 2.h),
        _buildUserJourneyFunnels(),
        SizedBox(height: 2.h),
        _buildFeatureAdoptionRates(),
      ],
    );
  }

  Widget _buildMostVisitedScreens() {
    final screens =
        analyticsData['most_visited_screens'] as List<Map<String, dynamic>>? ??
        [];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: const Color(0xFF10B981),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Most Visited Screens',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...screens.map((screen) => _buildScreenVisitBar(screen)),
        ],
      ),
    );
  }

  Widget _buildScreenVisitBar(Map<String, dynamic> screen) {
    final visits = screen['visits'] as int;
    final maxVisits = 20000;
    final percentage = (visits / maxVisits * 100).clamp(0, 100);

    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                screen['screen'] as String,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '${visits.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} visits',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Stack(
            children: [
              Container(
                height: 1.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 1.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserJourneyFunnels() {
    final funnels =
        analyticsData['user_journey_funnels'] as List<Map<String, dynamic>>? ??
        [];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                color: const Color(0xFF6366F1),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'User Journey Funnels',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...funnels.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == funnels.length - 1;
            return _buildFunnelStep(step, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildFunnelStep(Map<String, dynamic> step, bool isLast) {
    final users = step['users'] as int;
    final dropOff = step['drop_off'] as num;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['step'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${users.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} users',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              if (dropOff > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '-${dropOff.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!isLast)
          Container(
            margin: EdgeInsets.symmetric(vertical: 1.h),
            child: Icon(
              Icons.arrow_downward,
              color: Colors.grey[400],
              size: 16.sp,
            ),
          ),
      ],
    );
  }

  Widget _buildFeatureAdoptionRates() {
    final features =
        analyticsData['feature_adoption_rates'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
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
          Row(
            children: [
              Icon(
                Icons.auto_graph,
                color: const Color(0xFF8B5CF6),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Feature Adoption Rates',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...features.entries.map(
            (entry) =>
                _buildFeatureAdoptionCard(entry.key, entry.value as double),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureAdoptionCard(String feature, double rate) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((word) => word[0].toUpperCase() + word.substring(1))
                      .join(' '),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 0.5.h),
                Stack(
                  children: [
                    Container(
                      height: 0.8.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: rate / 100,
                      child: Container(
                        height: 0.8.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            '${rate.toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B5CF6),
            ),
          ),
        ],
      ),
    );
  }
}
