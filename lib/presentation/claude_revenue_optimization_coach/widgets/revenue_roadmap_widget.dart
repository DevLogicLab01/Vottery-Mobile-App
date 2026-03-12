import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class RevenueRoadmapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> roadmapSteps;
  final VoidCallback onRefresh;

  const RevenueRoadmapWidget({
    super.key,
    required this.roadmapSteps,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (roadmapSteps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 20.w,
              color: theme.textTheme.bodySmall?.color,
            ),
            SizedBox(height: 2.h),
            Text(
              'No roadmap available yet',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    final totalPotential = roadmapSteps.fold<double>(
      0,
      (sum, step) => sum + (step['impact_amount'] as num? ?? 0),
    );

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          _buildTotalPotentialCard(theme, totalPotential),
          SizedBox(height: 3.h),
          Text(
            'Your Optimization Roadmap',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          ...roadmapSteps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == roadmapSteps.length - 1;
            return _buildRoadmapStep(theme, step, index + 1, isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildTotalPotentialCard(ThemeData theme, double totalPotential) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withAlpha(179)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.rocket_launch, color: Colors.white, size: 12.w),
          SizedBox(height: 1.h),
          Text(
            'Total Revenue Potential',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.white.withAlpha(230),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '+\$${totalPotential.toStringAsFixed(0)}',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'per month',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: Colors.white.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapStep(
    ThemeData theme,
    Map<String, dynamic> step,
    int stepNumber,
    bool isLast,
  ) {
    final status = step['status'] ?? 'pending';
    final title = step['title'] ?? 'Optimization Step';
    final description = step['description'] ?? '';
    final eta = step['eta'] ?? 'TBD';
    final impact = step['impact_amount'] as num? ?? 0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(status).withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(child: _getStatusIcon(status)),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: theme.dividerColor)),
            ],
          ),
          SizedBox(width: 3.w),

          // Step content
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 3.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: _getStatusColor(status).withAlpha(77),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withAlpha(26),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'Step $stepNumber',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(26),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '+\$${impact.toStringAsFixed(0)}/mo',
                          style: GoogleFonts.inter(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 0.5.h),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 4.w,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'ETA: $eta',
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Icon(Icons.check, color: Colors.white, size: 20);
      case 'in_progress':
        return const Icon(Icons.play_arrow, color: Colors.white, size: 20);
      case 'pending':
        return const Icon(Icons.circle, color: Colors.white, size: 12);
      default:
        return const Icon(Icons.circle, color: Colors.white, size: 12);
    }
  }
}
