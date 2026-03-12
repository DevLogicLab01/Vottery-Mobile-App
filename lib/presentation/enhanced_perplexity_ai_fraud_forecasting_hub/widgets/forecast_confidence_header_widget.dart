import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ForecastConfidenceHeaderWidget extends StatelessWidget {
  final double confidenceScore;
  final String threatLevel;
  final double modelAccuracy;

  const ForecastConfidenceHeaderWidget({
    super.key,
    required this.confidenceScore,
    required this.threatLevel,
    required this.modelAccuracy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final threatColor = _getThreatColor(threatLevel);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              context,
              'Confidence',
              '${(confidenceScore * 100).toStringAsFixed(0)}%',
              'analytics',
              Colors.blue,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildMetricCard(
              context,
              'Threat Level',
              threatLevel.toUpperCase(),
              'warning',
              threatColor,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: _buildMetricCard(
              context,
              'Accuracy',
              '${(modelAccuracy * 100).toStringAsFixed(0)}%',
              'verified',
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    String iconName,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          CustomIconWidget(iconName: iconName, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getThreatColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
        return Colors.red.shade900;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
