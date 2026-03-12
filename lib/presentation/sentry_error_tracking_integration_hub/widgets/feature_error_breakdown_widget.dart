import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class FeatureErrorBreakdownWidget extends StatelessWidget {
  final Map<String, int> featureErrorCounts;
  final List<String> features;

  const FeatureErrorBreakdownWidget({
    super.key,
    required this.featureErrorCounts,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Errors by Feature',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Last 7 days',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurface.withAlpha(153),
              ),
            ),
            SizedBox(height: 2.h),
            ...features.map((feature) {
              final count = featureErrorCounts[feature] ?? 0;
              return _buildFeatureRow(context, feature, count);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String feature, int count) {
    final theme = Theme.of(context);
    final maxCount = featureErrorCounts.values.isEmpty
        ? 1
        : featureErrorCounts.values.reduce((a, b) => a > b ? a : b);
    final percentage = maxCount > 0 ? (count / maxCount) : 0.0;

    Color featureColor;
    switch (feature) {
      case 'voting':
        featureColor = Colors.blue;
        break;
      case 'gamification':
        featureColor = Colors.purple;
        break;
      case 'payments':
        featureColor = Colors.green;
        break;
      case 'social':
        featureColor = Colors.orange;
        break;
      case 'ai_services':
        featureColor = Colors.red;
        break;
      default:
        featureColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feature.replaceAll('_', ' ').toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                count.toString(),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: featureColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: theme.colorScheme.onSurface.withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(featureColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}
