import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class OpportunityCardWidget extends StatelessWidget {
  final Map<String, dynamic> opportunity;
  final VoidCallback onImplement;
  final VoidCallback onDismiss;

  const OpportunityCardWidget({
    super.key,
    required this.opportunity,
    required this.onImplement,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priority = opportunity['priority'] ?? 'medium';
    final estimatedImpact = opportunity['estimated_impact_usd'] as num? ?? 0;
    final confidence = opportunity['confidence'] as num? ?? 0.5;
    final timeframe = opportunity['timeframe'] ?? 'short';

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getPriorityColor(priority).withAlpha(77),
          width: 2,
        ),
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
          // Header
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _getPriorityColor(priority).withAlpha(26),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  _getTimeframeIcon(timeframe),
                  size: 5.w,
                  color: theme.textTheme.bodySmall?.color,
                ),
                SizedBox(width: 1.w),
                Text(
                  _getTimeframeText(timeframe),
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  opportunity['title'] ?? 'Optimization Opportunity',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1.h),
                Text(
                  opportunity['description'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),

                // Impact & Confidence
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        theme,
                        'Estimated Impact',
                        '+\$${estimatedImpact.toStringAsFixed(0)}/month',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: _buildMetricCard(
                        theme,
                        'Confidence',
                        '${(confidence * 100).toStringAsFixed(0)}%',
                        Icons.verified,
                        AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Confidence Gauge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence Level',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: LinearProgressIndicator(
                        value: confidence.toDouble(),
                        minHeight: 1.h,
                        backgroundColor: theme.dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getConfidenceColor(confidence.toDouble()),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onImplement,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 1.5.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Implement Now',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    OutlinedButton(
                      onPressed: onDismiss,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.5.h,
                        ),
                        side: BorderSide(color: theme.dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Dismiss',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 6.w),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTimeframeIcon(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'immediate':
        return Icons.flash_on;
      case 'short':
        return Icons.schedule;
      case 'medium':
        return Icons.calendar_today;
      case 'long':
        return Icons.calendar_month;
      default:
        return Icons.schedule;
    }
  }

  String _getTimeframeText(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'immediate':
        return 'Now';
      case 'short':
        return '1-2 weeks';
      case 'medium':
        return '1 month';
      case 'long':
        return '3+ months';
      default:
        return 'Soon';
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
