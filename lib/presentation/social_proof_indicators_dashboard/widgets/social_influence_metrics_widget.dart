import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class SocialInfluenceMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const SocialInfluenceMetricsWidget({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, AppTheme.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            'Social Score',
            '${metrics['social_influence_score']?.toStringAsFixed(1) ?? '0'}',
            Icons.trending_up,
          ),
          _buildMetricItem(
            'Active Friends',
            '${metrics['active_friends'] ?? 0}/${metrics['total_friends'] ?? 0}',
            Icons.people,
          ),
          _buildMetricItem(
            'Conversions',
            '${metrics['friend_driven_conversions'] ?? 0}',
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 6.w),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: Colors.white.withAlpha(204),
          ),
        ),
      ],
    );
  }
}
